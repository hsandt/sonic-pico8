require("bustedhelper")
require("math")
local itest_dsl = require("engine/test/itest_dsl")
local dsl_itest, command = itest_dsl.dsl_itest, itest_dsl.command
local integrationtest = require("engine/test/integrationtest")
local itest_manager, time_trigger, integration_test = integrationtest.itest_manager, integrationtest.time_trigger, integrationtest.integration_test
local flow = require("engine/application/flow")
local gameapp = require("game/application/gameapp")
local gamestate = require("game/application/gamestate")
local stage = require("game/ingame/stage")
local pc_data = require("game/data/playercharacter_data")


describe('itest_dsl', function ()

  after_each(function ()
    itest_dsl:init()
  end)

  describe('command', function ()

    describe('_init', function ()
      it('should create a new dsl itest', function ()
        local cmd = command(itest_dsl_command_types.move, {horizontal_dirs.left})
        assert.is_not_nil(cmd)
        assert.are_same({itest_dsl_command_types.move, {horizontal_dirs.left}}, {cmd.type, cmd.args})
      end)
    end)

  end)

  describe('dsl_itest', function ()

    describe('_init', function ()
      it('should create a new dsl itest', function ()
        local dsli = dsl_itest()
        assert.is_not_nil(dsli)
        assert.are_same({nil, nil, {}}, {dsli.gamestate_type, dsli.stage, dsli.commands})
      end)
    end)

  end)

  describe('register', function ()

    setup(function ()
      -- mock parse
      stub(itest_dsl, "parse", function (dsli_source)
        return dsli_source.."_parsed"
      end)
      -- mock create_itest
      stub(itest_dsl, "create_itest", function (name, dsli)
        return name..": "..dsli.."_itest"
      end)
    end)

    teardown(function ()
      itest_dsl.parse:revert()
      itest_dsl.create_itest:revert()
    end)

    after_each(function ()
      itest_manager:init()
    end)

    it('should parse, create and register an itest by name and source', function ()
      itest_dsl.register("my test", "dsl_source")
      assert.are_equal(1, #itest_manager.itests)
      assert.are_equal("my test: dsl_source_parsed_itest", itest_manager.itests[1])
    end)

  end)

  describe('parse', function ()

    it('should parse the itest source written in domain-specific language into a dsl itest', function ()
      local dsli_source = "@stage test1 \
\
                                        \
spawn 12 45                             \
wait 1                                  \
move left                               \
wait 2                                  \
expect pc_pos 10 45                     \
"
      local dsli = itest_dsl.parse(dsli_source)
      assert.is_not_nil(dsli)
      assert.are_same(
        {
          'stage',
          "test1",
          {
            command(itest_dsl_command_types.spawn,  { vector(12, 45) }             ),
            command(itest_dsl_command_types.wait,   { 1 }                          ),
            command(itest_dsl_command_types.move,   { horizontal_dirs.left }       ),
            command(itest_dsl_command_types.wait,   { 2 }                          ),
            command(itest_dsl_command_types.expect, {itest_dsl_value_types.pc_pos, vector(10, 45)}),
          }
        },
        {
          dsli.gamestate_type,
          dsli.stage,
          dsli.commands
        })
    end)

  end)

  describe('create_itest', function ()

    it('should create an itest with a name and a dsl itest', function ()
      local dsli = dsl_itest()
      dsli.gamestate_type = 'stage'
      dsli.stage = "test1"
      dsli.commands = {
        command(itest_dsl_command_types.spawn,  { vector(12, 45) }             ),
        command(itest_dsl_command_types.wait,   { 10 }                          ),
        command(itest_dsl_command_types.wait,   { 1 }                          ),
        command(itest_dsl_command_types.move,   { horizontal_dirs.left }       ),
        command(itest_dsl_command_types.wait,   { 2 }                          ),
        command(itest_dsl_command_types.expect, {itest_dsl_value_types.pc_pos, vector(10, 45)}),
      }

      local test = itest_dsl.create_itest("test 1", dsli)

      -- interface
      assert.is_not_nil(test)
      assert.are_equal(4, #test.action_sequence)
      assert.are_same({
          "test 1",
          {'stage'},
          time_trigger(0, true),  -- spawn immediately
          scripted_action(time_trigger(10, true), nil),  -- empty action after 10 frames
          time_trigger(1, true),  -- start moving after 1 frame
          scripted_action(time_trigger(2, true), nil)    -- empty action after 2 frames
        },
        {
          test.name,
          test.active_gamestates,
          test.action_sequence[1].trigger,
          test.action_sequence[2],
          test.action_sequence[3].trigger,
          test.action_sequence[4]
        })

      -- we could not directly test if generated functions are correct
      --  they were generated from parameters passed dynamically,
      --  so it's impossible to find the references back (except for dummy)
      -- instead, we call the functions one by one and see if we get
      --  the expected result
      -- note that most actions depend on the previous one, so we exceptionally
      --  assert multiple times in chain in a single utest

      -- simulate the itest runner behavior by initializing gameapp to inject active gamestates
      gameapp.init(test.active_gamestates)

      -- verify setup callback behavior
      test.setup()
      assert.are_equal(gamestate.types.stage, flow.curr_state.type)

      -- verify spawn callback behavior
      test.action_sequence[1].callback()
      assert.is_not_nil(stage.state.player_char)
      assert.are_equal(vector(12, 45 - pc_data.center_height_standing), stage.state.player_char.position)

      -- verify move callback behavior
      test.action_sequence[3].callback()
      assert.are_equal(vector(-1, 0), stage.state.player_char.move_intention)

      -- we have not passed time so the character cannot have reached expected position
      assert.is_false(test.final_assertion())

      -- but if we cheat and warp him on the spot, final assertion will work
      stage.state.player_char.position = vector(10, 45)
      assert.is_true(test.final_assertion())
    end)

  end)

  describe('_evaluate', function ()

    it('should assert if an unknown gameplay value type is passed', function ()
      assert.has_error(function ()
        itest_dsl._evaluate(-1)
      end, "unknown gameplay value: -1")
    end)

  end)

  describe('_final_assert', function ()

    setup(function ()
      -- mock _evaluate (we won't care about the 1st argument thx to this)
      stub(itest_dsl, "_evaluate", function (gameplay_value_type)
        return 27
      end)
    end)

    teardown(function ()
      itest_dsl._evaluate:revert()
    end)

    it('should set the final assertion as returning true when the gameplay value is expected', function ()
      itest_dsl._itest = integration_test('test', {})
      itest_dsl:_final_assert(nil, 27)
      assert.is_true(itest_dsl._itest.final_assertion())
    end)

    it('should set the final assertion as returning false when the gameplay value is not expected', function ()
      itest_dsl._itest = integration_test('test', {})
      itest_dsl:_final_assert(nil, 28)
      assert.is_false(itest_dsl._itest.final_assertion())
    end)

  end)

  describe('_evaluate', function ()

    -- add gameplay value types tests here

    it('should assert if an unknown gameplay value type is passed', function ()
      assert.has_error(function ()
        itest_dsl._evaluate(-1)
      end, "unknown gameplay value: -1")
    end)

  end)

end)

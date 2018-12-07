require("bustedhelper")
require("math")
local itest_dsl = require("engine/test/itest_dsl")
local dsl_itest, command_types, values, command = itest_dsl.dsl_itest, itest_dsl.command_types, itest_dsl.values, itest_dsl.command
local integrationtest = require("engine/test/integrationtest")
local time_trigger = integrationtest.time_trigger
local flow = require("engine/application/flow")
local gamestate = require("game/application/gamestate")
local stage = require("game/ingame/stage")

describe('itest_dsl', function ()

  describe('dsl_itest', function ()

    describe('_init', function ()
      it('should create a new dsl itest', function ()
        local dsli = dsl_itest()
        assert.is_not_nil(dsli)
      end)
    end)

  end)

  describe('parse', function ()

    it('should parse the itest source written in domain-specific language into a dsl itest', function ()
      local dsli_source = "@stage test1 \
spawn 12 45                             \
move left                               \
wait 2                                  \
expect pc.pos 10 45                     \
"
      local dsli = itest_dsl.parse(dsli_source)
      assert.is_not_nil(dsli)
      assert.are_same(
        {
          'stage',
          "test1",
          {
            command(command_types.spawn,  { vector(12, 45) }             ),
            command(command_types.move,   { horizontal_dirs.left }       ),
            command(command_types.wait,   { 2 }                          ),
            command(command_types.expect, {values.pc_pos, vector(10, 45)}),
          }
        },
        {
          dsli.gamestate,
          dsli.stage,
          dsli.commands
        })
    end)

  end)

  describe('create_itest', function ()

    it('should create an itest with a name and a dsl itest', function ()
      local dsli = dsl_itest()
      dsli.gamestate = 'stage'
      dsli.stage = "test1"
      dsli.commands = {
        command(command_types.spawn,  { vector(12, 45) }             ),
        command(command_types.move,   { horizontal_dirs.left }       ),
        command(command_types.wait,   { 2 }                          ),
        command(command_types.expect, {values.pc_pos, vector(10, 45)}),
      }

      local test = itest_dsl.create_itest("test 1", dsli)
      assert.is_not_nil(test)

      assert.are_same({
          "test 1",
          {'stage'},
          {
            time_trigger(0, true),  -- spawn immediately
            time_trigger(0, true),  -- start moving immediately
            scripted_action(time_trigger(2, true), dummy)  -- empty action after 2 frames
          }
        },
        {
          test.name,
          test.active_gamestates,
          test.action_sequence[0].trigger,
          test.action_sequence[1].trigger,
          test.action_sequence[2]
        })

      -- we could not directly test if generated functions are correct
      --  they were generated from parameters passed dynamically,
      --  so it's impossible to find the references back (except for dummy)
      -- instead, we call the functions one by one and see if we get
      --  the expected result
      -- note that most actions depend on the previous one, so we exceptionally
      --  assert multiple times in chain in a single utest

      test.setup()
      assert.are_equal(gamestate.types.stage, stage.curr_state.type)

      test.action_sequence[1]()
      assert.is_not_nil(stage.player_char)
      assert.are_equal(vector(12, 45), stage.player_char.position)

      test.action_sequence[2]()
      assert.are_equal(vector(-1, 0), stage.player_char.move_intention)

      -- we have not passed time so the character cannot have reached expected position
      assert.is_false(test.final_assertion())

      -- but if we cheat and warp him on the spot, final assertion will work
      stage.player_char.position = vector(10, 45)
      assert.is_true(test.final_assertion())
    end)

  end)

end)

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
local tilemap = require("engine/data/tilemap")
local pc_data = require("game/data/playercharacter_data")


describe('itest_dsl', function ()

  setup(function ()
    -- stub setup_map_data which can have side effects on tile flags
    --  as we don't need those anyway, just the tile ids themselves
    stub(_G, "setup_map_data")
  end)

  teardown(function ()
    setup_map_data:revert()
  end)

  after_each(function ()
    itest_dsl:init()
    flow:init()
    stage.state:init()
    pico8:clear_map()
    setup_map_data:clear()
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
        assert.are_same({nil, nil, nil}, {dsli.gamestate_type, dsli.stage_name, dsli.commands})
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

    -- bugfix history:
    -- + spot tilemap not being set, although parse_gamestate_definition worked, so the error is in the glue code
    it('should parse the itest source written in domain-specific language into a dsl itest', function ()
      local dsli_source = [[@stage #
..##
##..

warp 12 45
wait 1
move left
wait 2
expect pc_bottom_pos 10 45
]]
      local dsli = itest_dsl.parse(dsli_source)

      -- interface
      assert.is_not_nil(dsli)
      assert.are_same(
        {
          'stage',
          '#',
          tilemap({
            { 0,  0, 64, 64},
            {64, 64,  0,  0}
          }),
          {
            command(itest_dsl_command_types.warp,  { vector(12, 45) }             ),
            command(itest_dsl_command_types.wait,   { 1 }                          ),
            command(itest_dsl_command_types.move,   { horizontal_dirs.left }       ),
            command(itest_dsl_command_types.wait,   { 2 }                          ),
            command(itest_dsl_command_types.expect, {itest_dsl_gp_value_types.pc_bottom_pos, vector(10, 45)}),
          }
        },
        {
          dsli.gamestate_type,
          dsli.stage_name,
          dsli.tilemap,
          dsli.commands
        })

      -- implementation
      -- todo: check call to parse_gamestate_definition and parse_action_sequence
      --  to avoid test redundancy
    end)

  end)


  describe('parse_gamestate_definition', function ()

    it('should return gamestate name, nil, nil and 3 for a non-stage gamestate and no extra line', function ()
      local dsli_lines = {"@titlemenu"}
      local gamestate_type, stage_name, tm, next_line_index = itest_dsl.parse_gamestate_definition(dsli_lines)
      assert.are_same(
        {
          'titlemenu',
          nil,
          nil,
          3
        },
        {
          gamestate_type,
          stage_name,
          tm,
          next_line_index
        })
    end)

    it('should return \'stage\', the stage name, nil and 4 for a pre-defined stage definition after 1 blank line', function ()
      local dsli_lines = {
        "@stage test1",
        "",
        "",
        "???"
      }
      local gamestate_type, stage_name, tm, next_line_index = itest_dsl.parse_gamestate_definition(dsli_lines)
      assert.are_same(
        {
          'stage',
          "test1",
          nil,
          3
        },
        {
          gamestate_type,
          stage_name,
          tm,
          next_line_index
        })
    end)

    it('should return \'stage\', \'#\', tilemap data and 6 for a custom stage definition finishing at line 5 (including blank line)', function ()
      local dsli_lines = {
        "@stage #",
        "....",
        "##..",
        "..##",
        "",
        "???"
      }
      local gamestate_type, stage_name, tm, next_line_index = itest_dsl.parse_gamestate_definition(dsli_lines)
      assert.are_same(
        {
          'stage',
          '#',
          tilemap({
            { 0,  0,  0,  0},
            {64, 64,  0,  0},
            { 0,  0, 64, 64}
          }),
          6
        },
        {
          gamestate_type,
          stage_name,
          tm,
          next_line_index
        })
    end)

  end)

  describe('parse_tilemap', function ()

    it('should return a tilemap data with tiles corresponding to the tile symbols in the string', function ()
      local tilemap_text = {
        "????",
        "....",
        "##..",
        "..##"
      }
      local tm, next_line_index = itest_dsl.parse_tilemap(tilemap_text)
      assert.are_same(
        {
          tilemap({
            { 0,  0,  0,  0},
            {64, 64,  0,  0},
            { 0,  0, 64, 64}
          }),
          6
        },
        {tm, next_line_index})
    end)

    it('should assert if there as fewer than 2 lines', function ()
      local tilemap_text = {
        "?"
      }
      assert.has_error(function ()
        itest_dsl.parse_tilemap(tilemap_text)
      end, "only 1 line(s), need at least 2")
    end)

    it('should assert if line 2 has width 0', function ()
      local tilemap_text = {
        "?",
        "",
        "?"
      }
      assert.has_error(function ()
        itest_dsl.parse_tilemap(tilemap_text)
      end)
    end)

    it('should assert if line width is inconsistent', function ()
      local tilemap_text = {
        "",
        "....",
        "..."
      }
      assert.has_error(function ()
        itest_dsl.parse_tilemap(tilemap_text)
      end, "inconsistent line length: 3 vs 4")
    end)

    it('should assert if unknown tile symbol is found', function ()
      local tilemap_text = {
        "",
        "?"
      }
      assert.has_error(function ()
        itest_dsl.parse_tilemap(tilemap_text)
      end, "unknown tile symbol: ?")
    end)

  end)

  describe('parse_action_sequence', function ()

    it('should return ', function ()
      local dsli_lines = {
        "???",
        "???",
        "???",
        "",
        "warp 12 45",
        "wait 1",
        "move left",
        "wait 2",
        "expect pc_bottom_pos 10 45"
      }
      local commands = itest_dsl.parse_action_sequence(dsli_lines, 5)
      assert.are_same(
          {
            command(itest_dsl_command_types.warp,  { vector(12, 45) }             ),
            command(itest_dsl_command_types.wait,   { 1 }                          ),
            command(itest_dsl_command_types.move,   { horizontal_dirs.left }       ),
            command(itest_dsl_command_types.wait,   { 2 }                          ),
            command(itest_dsl_command_types.expect, {itest_dsl_gp_value_types.pc_bottom_pos, vector(10, 45)}),
          },
          commands)
    end)

  end)

  describe('create_itest', function ()

    it('should create an itest with a name and a dsl itest', function ()
      local dsli = dsl_itest()
      dsli.gamestate_type = 'stage'
      dsli.stage_name = "test1"
      dsli.tilemap = nil
      dsli.commands = {
        command(itest_dsl_command_types.warp,  { vector(12, 45) }             ),
        command(itest_dsl_command_types.wait,   { 10 }                          ),
        command(itest_dsl_command_types.wait,   { 1 }                          ),
        command(itest_dsl_command_types.move,   { horizontal_dirs.left }       ),
        command(itest_dsl_command_types.wait,   { 2 }                          ),
        command(itest_dsl_command_types.expect, {itest_dsl_gp_value_types.pc_bottom_pos, vector(10, 45)}),
      }

      local test = itest_dsl.create_itest("test 1", dsli)

      -- interface
      assert.is_not_nil(test)
      assert.are_equal(4, #test.action_sequence)
      assert.are_same({
          "test 1",
          {'stage'},
          time_trigger(0, true),  -- warp immediately
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

      -- verify warp callback behavior
      test.action_sequence[1].callback()
      assert.is_not_nil(stage.state.player_char)
      assert.are_equal(vector(12, 45 - pc_data.center_height_standing), stage.state.player_char.position)

      -- verify move callback behavior
      test.action_sequence[3].callback()
      assert.are_equal(vector(-1, 0), stage.state.player_char.move_intention)

      -- we have not passed time so the character cannot have reached expected position
      assert.is_false(test.final_assertion())

      -- but if we cheat and warp him on the spot, final assertion will work
      stage.state.player_char:set_bottom_center(vector(10, 45))
      assert.is_true(test.final_assertion())
    end)

    describe('(spying tilemap load)', function ()

      setup(function ()
        spy.on(tilemap, "load")
      end)

      teardown(function ()
        tilemap.load:revert()
      end)

      it('should call setup_map_data and load on the tilemap if custom stage definition', function ()
        local dsli = dsl_itest()
        dsli.gamestate_type = 'stage'
        dsli.stage_name = "#"
        dsli.tilemap = tilemap({})
        dsli.commands = {}

        local test = itest_dsl.create_itest("test 1", dsli)

        gameapp.init(test.active_gamestates)
        test.setup()

        -- interface
        assert.are_equal(control_modes.puppet, stage.state.player_char.control_mode)

        -- implementation
        assert.spy(setup_map_data).was_called(1)
        assert.spy(setup_map_data).was_called_with()
        assert.spy(tilemap.load).was_called(1)
        assert.spy(tilemap.load).was_called_with(match.ref(dsli.tilemap))
      end)

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

    it('should set the final assertion as returning true, message when the gameplay value is expected', function ()
      itest_dsl._itest = integration_test('test', {})
      itest_dsl:_final_assert(itest_dsl_gp_value_types.pc_bottom_pos, 27)
      local message = "Passed gameplay value 'player character bottom position':\n27\nExpected:\n27"
      assert.are_same({true, message}, {itest_dsl._itest.final_assertion()})
    end)

    it('should set the final assertion as returning false, message when the gameplay value is not expected', function ()
      itest_dsl._itest = integration_test('test', {})
      itest_dsl:_final_assert(itest_dsl_gp_value_types.pc_bottom_pos, 28)
      local message = "Passed gameplay value 'player character bottom position':\n27\nExpected:\n28"
      assert.are_same({false, message}, {itest_dsl._itest.final_assertion()})
    end)

    it('should assert when the passed gameplay value type is invalid', function ()
      itest_dsl._itest = integration_test('test', {})
      assert.has_error(function ()
        itest_dsl:_final_assert(-1, 20)
      end)
    end)

  end)

  describe('_evaluate', function ()

    -- add gameplay value types tests here

    it('should return the player character bottom position for ', function ()
      stage.state:warp_player_char()
      stage.state.player_char:set_bottom_center(vector(2, 8))

      assert.are_equal(vector(2, 8), itest_dsl._evaluate(itest_dsl_gp_value_types.pc_bottom_pos))
    end)

    it('should assert if an unknown gameplay value type is passed', function ()
      assert.has_error(function ()
        itest_dsl._evaluate(-1)
      end, "unknown gameplay value: -1")
    end)

  end)

end)

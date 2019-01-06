require("bustedhelper")
require("engine/core/helper")
require("engine/core/math")
local itest_dsl = require("engine/test/itest_dsl")
local gameplay_value_data, generate_function_table = get_members(itest_dsl, "gameplay_value_data", "generate_function_table")
local parse_number, parse_vector, parse_horizontal_dir, parse_motion_state, parse_expect = get_members(itest_dsl, "parse_number", "parse_vector", "parse_horizontal_dir", "parse_motion_state", "parse_expect")
local execute_warp, execute_move, execute_wait = get_members(itest_dsl, "execute_warp", "execute_move", "execute_wait")
local eval_pc_bottom_pos, eval_pc_velocity, eval_pc_ground_spd, eval_pc_motion_state = get_members(itest_dsl, "eval_pc_bottom_pos", "eval_pc_velocity", "eval_pc_ground_spd", "eval_pc_motion_state")
local command, expectation = get_members(itest_dsl, "command", "expectation")
local dsl_itest, itest_dsl_parser = get_members(itest_dsl, "dsl_itest", "itest_dsl_parser")
local integrationtest = require("engine/test/integrationtest")
local itest_manager, time_trigger, integration_test = get_members(integrationtest, "itest_manager", "time_trigger", "integration_test")
local flow = require("engine/application/flow")
local gameapp = require("game/application/gameapp")
local gamestate = require("game/application/gamestate")
local stage = require("game/ingame/stage")
local tilemap = require("engine/data/tilemap")
local player_char = require("game/ingame/playercharacter")
local pc_data = require("game/data/playercharacter_data")


describe('itest_dsl', function ()

  describe('gameplay_value_data', function ()

    describe('_init', function ()
      it('should create gameplay value data', function ()
        local data = gameplay_value_data("position", parsable_types.vector)
        assert.is_not_nil(data)
        assert.are_same({"position", parsable_types.vector}, {data.name, data.parsable_type})
      end)
    end)

  end)

  describe('generate_function_table', function ()

    it('should assert when the number of arguments is wrong', function ()
      local enum_types = {a = 10, b = 20}
      local module = {
        use_a = function() end,
        use_b = function() end
      }
      local function_table = generate_function_table(module, enum_types, "use_")
      assert.are_same({[10] = module.use_a, [20] = module.use_b}, function_table)
    end)

  end)

  describe('parse_number', function ()

    it('should assert when the number of arguments is wrong', function ()
      assert.has_error(function ()
        parse_number({"too", "many"})
      end, "parse_number: got 2 args, expected 1")
    end)

    it('should return the single string argument as number', function ()
      assert.are_equal(5, parse_number({"5"}))
    end)

  end)

  describe('parse_vector', function ()

    it('should assert when the number of arguments is wrong', function ()
      assert.has_error(function ()
        parse_vector({"too few"})
      end, "parse_vector: got 1 args, expected 2")
    end)

    it('should return the 2 coordinate string arguments as vector', function ()
      assert.are_equal(vector(2, -3.5), parse_vector({"2", "-3.5"}))
    end)

  end)

  describe('parse_horizontal_dir', function ()

    it('should assert when the number of arguments is wrong', function ()
      assert.has_error(function ()
        parse_horizontal_dir({"too", "many"})
      end, "parse_horizontal_dir: got 2 args, expected 1")
    end)

    it('should return the single argument as horizontal direction', function ()
      assert.are_equal(horizontal_dirs.right, parse_horizontal_dir({"right"}))
    end)

  end)

  describe('parse_motion_state', function ()

    it('should assert when the number of arguments is wrong', function ()
      assert.has_error(function ()
        parse_motion_state({"too", "many"})
      end, "parse_motion_state: got 2 args, expected 1")
    end)

    it('should return the single argument as motion state', function ()
      assert.are_equal(motion_states.airborne, parse_motion_state({"airborne"}))
    end)

  end)

  describe('parse_expect', function ()

    it('should assert when the number of arguments is wrong', function ()
      assert.has_error(function ()
        parse_expect({"too few"})
      end, "parse_expect: got 1 args, expected at least 2")
    end)

    it('should return the gameplay value type and the expected value, itself recursively parsed', function ()
      assert.are_same({gp_value_types.pc_bottom_pos, vector(1, 3)},
        {parse_expect({"pc_bottom_pos", "1", "3"})})
    end)

  end)

  describe('execute_', function ()

    before_each(function ()
      -- some executions require the player character
      stage.state.player_char = player_char()
    end)

    after_each(function ()
      -- clean up dummy player character
      stage.state:init()
    end)

    describe('execute_warp', function ()

      setup(function ()
        spy.on(player_char, "warp_bottom_to")
      end)

      teardown(function ()
        player_char.warp_bottom_to:revert()
      end)

      it('should call warp_bottom_to on the current player character', function ()
        execute_warp({vector(1, 3)})

        assert.spy(player_char.warp_bottom_to).was_called(1)
        assert.spy(player_char.warp_bottom_to).was_called_with(match.ref(stage.state.player_char), vector(1, 3))
      end)

    end)

    describe('execute_move', function ()

      it('should set the move intention of the current player character to the directional unit vector matching his horizontal direction', function ()
        execute_move({horizontal_dirs.right})
        assert.are_equal(vector(1, 0), stage.state.player_char.move_intention)
      end)

    end)

  end)

  describe('eval_', function ()

    before_each(function ()
      -- some evaluators require the player character
      stage.state.player_char = player_char()
    end)

    after_each(function ()
      -- clean up dummy player character
      stage.state:init()
    end)

    describe('eval_pc_bottom_pos', function ()

      it('should return the bottom position of the current player character', function ()
        stage.state.player_char:set_bottom_center(vector(12, 47))
        assert.are_equal(vector(12, 47), eval_pc_bottom_pos())
      end)

    end)

    describe('eval_pc_velocity', function ()

      it('should return the velocity the current player character', function ()
        stage.state.player_char.velocity = vector(1, -4)
        assert.are_equal(vector(1, -4), eval_pc_velocity())
      end)

    end)

    describe('eval_pc_ground_spd', function ()

      it('should return the ground speed current player character', function ()
        stage.state.player_char.ground_speed = 3.5
        assert.are_equal(3.5, eval_pc_ground_spd())
      end)

    end)

    describe('eval_pc_motion_state', function ()

      it('should return the ground speed current player character', function ()
        stage.state.player_char.motion_state = motion_states.airborne
        assert.are_equal(motion_states.airborne, eval_pc_motion_state())
      end)

    end)

  end)


  describe('command', function ()

    describe('_init', function ()
      it('should create a new dsl itest', function ()
        local cmd = command(command_types.move, {horizontal_dirs.left})
        assert.is_not_nil(cmd)
        assert.are_same({command_types.move, {horizontal_dirs.left}}, {cmd.type, cmd.args})
      end)
    end)

  end)

  describe('expectation', function ()

    describe('_init', function ()
      it('should create a new dsl itest', function ()
        local exp = expectation(gp_value_types.pc_bottom_pos, 24)
        assert.is_not_nil(exp)
        assert.are_same({gp_value_types.pc_bottom_pos, 24}, {exp.gp_value_type, exp.expected_value})
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

  describe('itest_dsl_parser', function ()

    setup(function ()
      -- spying should be enough, but we stub so it's easier to call these functions
      --  without calling the symmetrical one (e.g. teardown may fail with nil reference
      --  if setup is not called first)
      stub(_G, "setup_map_data")
      stub(_G, "teardown_map_data")
    end)

    teardown(function ()
      setup_map_data:revert()
      teardown_map_data:revert()
    end)

    after_each(function ()
      itest_dsl_parser:init()
      flow:init()
      stage.state:init()
      pico8:clear_map()
      setup_map_data:clear()
      teardown_map_data:clear()
    end)

    describe('init', function ()
      assert.are_same({
          nil,
          nil,
          {}
        },
        {
          itest_dsl_parser._itest,
          itest_dsl_parser._last_time_trigger,
          itest_dsl_parser._final_expectations
        })
    end)

    describe('register', function ()

      setup(function ()
        -- mock parse
        stub(itest_dsl_parser, "parse", function (dsli_source)
          return dsli_source.."_parsed"
        end)
        -- mock create_itest
        stub(itest_dsl_parser, "create_itest", function (name, dsli)
          return name..": "..dsli.."_itest"
        end)
      end)

      teardown(function ()
        itest_dsl_parser.parse:revert()
        itest_dsl_parser.create_itest:revert()
      end)

      after_each(function ()
        itest_manager:init()
      end)

      it('should parse, create and register an itest by name and source', function ()
        itest_dsl_parser.register("my test", "dsl_source")
        assert.are_equal(1, #itest_manager.itests)
        assert.are_equal("my test: dsl_source_parsed_itest", itest_manager.itests[1])
      end)

    end)

    describe('parse', function ()

      setup(function ()
        stub(itest_dsl_parser, "parse_gamestate_definition", function (lines)
          local tile_id = tonum(lines[3])
          return lines[1],
            lines[2],
            tilemap({
              { 0,      tile_id},
              {tile_id,       0}
            }),
            5
        end)
        stub(itest_dsl_parser, "parse_action_sequence", function (lines, next_line_index)
          return {
            command(command_types[lines[next_line_index]],   { vector(1, 2) }                                      ),
            command(command_types[lines[next_line_index+1]], {gp_value_types.pc_bottom_pos, vector(3, 4)})
          }
        end)
      end)

      teardown(function ()
        itest_dsl_parser.parse_gamestate_definition:revert()
        itest_dsl_parser.parse_action_sequence:revert()
      end)

      -- bugfix history:
      -- + spot tilemap not being set, although parse_gamestate_definition worked, so the error is in the glue code
      it('should parse the itest source written in domain-specific language into a dsl itest', function ()
        local dsli_source = [[
stage
#
64

warp
expect
]]

        local dsli = itest_dsl_parser.parse(dsli_source)

        -- interface
        assert.is_not_nil(dsli)
        assert.are_same(
          {
            'stage',
            '#',
            tilemap({
              { 0, 64},
              {64,  0}
            }),
            {
              command(command_types.warp,   { vector(1, 2) }                                       ),
              command(command_types.expect, {gp_value_types.pc_bottom_pos, vector(3, 4)})
            }
          },
          {
            dsli.gamestate_type,
            dsli.stage_name,
            dsli.tilemap,
            dsli.commands
          })
      end)

    end)


    describe('parse_gamestate_definition', function ()

      it('should return gamestate name, nil, nil and 3 for a non-stage gamestate and no extra line', function ()
        local dsli_lines = {"@titlemenu"}
        local gamestate_type, stage_name, tm, next_line_index = itest_dsl_parser.parse_gamestate_definition(dsli_lines)
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
        local gamestate_type, stage_name, tm, next_line_index = itest_dsl_parser.parse_gamestate_definition(dsli_lines)
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

      describe('(mocking parse_tilemap)', function ()

        setup(function ()
          stub(itest_dsl_parser, "parse_tilemap", function ()
            return tilemap({
              {70, 64},
              {64, 70}
            }), 5
          end)
        end)

        teardown(function ()
          itest_dsl_parser.parse_tilemap:revert()
        end)

        it('should return \'stage\', \'#\', tilemap data and 6 for a custom stage definition finishing at line 5 (including blank line)', function ()
          local dsli_lines = {
            "@stage #",
            "[this part is ignored, mocked parse_tilemap]",
            "[will return predefined tilemap]"
          }

          local gamestate_type, stage_name, tm, next_line_index = itest_dsl_parser.parse_gamestate_definition(dsli_lines)

          -- interface
          assert.are_same(
            {
              'stage',
              '#',
              tilemap({
                {70, 64},
                {64, 70}
              }),
              5
            },
            {
              gamestate_type,
              stage_name,
              tm,
              next_line_index
            })
        end)

      end)

    end)

    -- bugfix history:
    -- + removed "local" in "local width =" inside loop after applying trimming
    --   to lines to support "  \" multilines
    describe('parse_tilemap', function ()

      it('should return an empty tilemap data if the 2nd line is blank', function ()
        local tilemap_text = {
          "@stage # (ignored)",
          "",
          ".... (ignored)",  -- next line: 3
          ".... (ignored)"
        }
        local tm, next_line_index = itest_dsl_parser.parse_tilemap(tilemap_text)
        assert.are_same(
          {
            tilemap({}),
            3
          },
          {tm, next_line_index})
      end)

       it('should return a tilemap data with tiles corresponding to the tile symbols in the string', function ()
        local tilemap_text = {
          "@stage # (ignored)",
          "....",
          "##..",
          "..##",
          "",
          "(ignored)",  -- next line: 6
          "(ignored)"
        }
        local tm, next_line_index = itest_dsl_parser.parse_tilemap(tilemap_text)
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
          itest_dsl_parser.parse_tilemap(tilemap_text)
        end, "only 1 line(s), need at least 2")
      end)

      it('should assert if there are too many blocks', function ()
        local tilemap_text = {
          "@stage # (ignored)",
          "... ..."
        }
        assert.has_error(function ()
          itest_dsl_parser.parse_tilemap(tilemap_text)
        end, "too many blocks: 2, expected 1")
      end)

      it('should assert if line width is inconsistent', function ()
        local tilemap_text = {
          "@stage # (ignored)",
          "....",
          "..."
        }
        assert.has_error(function ()
          itest_dsl_parser.parse_tilemap(tilemap_text)
        end, "inconsistent line length: 3 vs 4")
      end)

      it('should assert if unknown tile symbol is found', function ()
        local tilemap_text = {
          "@stage # (ignored)",
          "?"
        }
        assert.has_error(function ()
          itest_dsl_parser.parse_tilemap(tilemap_text)
        end, "unknown tile symbol: ?")
      end)

    end)

    describe('parse_action_sequence', function ()

      it('should return a sequence of commands read in lines, starting at next_line_index', function ()
        local dsli_lines = {
          "???",
          "???",
          "???",
          "",
          "warp 12 45",
          "wait 1",
          "move left",
          "wait 2",
          "expect pc_bottom_pos 10 45",
          "expect pc_velocity 2 -3.5"
        }
        local commands = itest_dsl_parser.parse_action_sequence(dsli_lines, 5)
        assert.are_same(
            {
              command(command_types.warp,   { vector(12, 45) }             ),
              command(command_types.wait,   { 1 }                          ),
              command(command_types.move,   { horizontal_dirs.left }       ),
              command(command_types.wait,   { 2 }                          ),
              command(command_types.expect, {gp_value_types.pc_bottom_pos, vector(10, 45)}),
              command(command_types.expect, {gp_value_types.pc_velocity, vector(2, -3.5)}),
            },
            commands)
      end)

      it('should assert if an unknown command is found', function ()
        local dsli_lines = {
          "???",
          "???",
          "???",
          "",
          "unknown ? ?",
        }
        assert.has_error(function ()
            itest_dsl_parser.parse_action_sequence(dsli_lines, 5)
          end,
          "no command type named 'unknown'")
      end)

    end)

    describe('create_itest', function ()

      it('should create an itest with a name and a dsl itest', function ()
        local dsli = dsl_itest()
        dsli.gamestate_type = 'stage'
        dsli.stage_name = "test1"
        dsli.tilemap = nil
        dsli.commands = {
          command(command_types.warp,   { vector(12, 45) }             ),
          command(command_types.wait,   { 10 }                          ),
          command(command_types.wait,   { 1 }                          ),
          command(command_types.move,   { horizontal_dirs.left }       ),
          command(command_types.wait,   { 2 }                          ),
          command(command_types.expect, {gp_value_types.pc_bottom_pos, vector(10, 45)}),
          command(command_types.expect, {gp_value_types.pc_velocity, vector(2, -3.5)}),
        }

        local test = itest_dsl_parser.create_itest("test 1", dsli)

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
        local expected_message = "\nPassed gameplay value 'player character bottom position':\nvector(12, 45)\nExpected:\nvector(10, 45)\n"..
          "\nPassed gameplay value 'player character velocity':\nvector(0, 0)\nExpected:\nvector(2, -3.5)\n"
        assert.are_same({false, expected_message}, {test.final_assertion()})

        -- but if we cheat and warp him on the spot, final assertion will work
        stage.state.player_char:set_bottom_center(vector(10, 45))
        stage.state.player_char.velocity = vector(2, -3.5)
        assert.are_same({true, ""}, {test.final_assertion()})

        -- verify that parser state is cleaned up, ready for next parsing
        assert.are_same({
            nil,
            nil,
            {}
          },
          {
            itest_dsl_parser._itest,
            itest_dsl_parser._last_time_trigger,
            itest_dsl_parser._final_expectations
          })
      end)

      describe('(spying tilemap load)', function ()

        setup(function ()
          spy.on(tilemap, "load")
        end)

        teardown(function ()
          tilemap.load:revert()
        end)

        it('setup should call setup_map_data and load on the tilemap if custom stage definition', function ()
          local dsli = dsl_itest()
          dsli.gamestate_type = 'stage'
          dsli.stage_name = "#"
          dsli.tilemap = tilemap({})
          dsli.commands = {}

          local test = itest_dsl_parser.create_itest("test 1", dsli)

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

        it('teardown should call clear_map and teardown_map_data if custom stage definition', function ()
          local dsli = dsl_itest()
          dsli.gamestate_type = 'stage'
          dsli.stage_name = "#"
          dsli.tilemap = tilemap({})
          dsli.commands = {}

          local test = itest_dsl_parser.create_itest("test 1", dsli)

          gameapp.init(test.active_gamestates)
          test.teardown()

          -- implementation
          assert.spy(teardown_map_data).was_called(1)
          assert.spy(teardown_map_data).was_called_with()
          assert.spy(tilemap.load).was_called(1)
          assert.spy(tilemap.load).was_called_with(match.ref(dsli.tilemap))
        end)

      end)

    end)

    describe('_act', function ()

      local function f() end

      before_each(function ()
        itest_dsl_parser._itest = integration_test("test 1", {})
      end)

      after_each(function ()
        itest_manager:init()
      end)

      it('should add an action after an existing time trigger, and clear the last time trigger', function ()
        itest_dsl_parser._last_time_trigger = time_trigger(3, true)
        itest_dsl_parser:_act(f)
        assert.are_equal(1, #itest_dsl_parser._itest.action_sequence)
        local action = itest_dsl_parser._itest.action_sequence[1]
        assert.are_same({time_trigger(3, true), f,
            nil},
          {action.trigger, action.callback,
            itest_dsl_parser._last_time_trigger})
      end)

    end)

    describe('_wait', function ()

      before_each(function ()
        itest_dsl_parser._itest = integration_test('test', {})
      end)

      it('should set the current time_trigger of the parser to one with the passed interval, in frames', function ()
        itest_dsl_parser:_wait(12)
        assert.are_equal(time_trigger(12, true), itest_dsl_parser._last_time_trigger)
      end)

      it('should add a dummy action with any previous time trigger, then set the last time trigger to the new one', function ()
        itest_dsl_parser._last_time_trigger = time_trigger(4, true)
        itest_dsl_parser:_wait(8)
        assert.are_equal(1, #itest_dsl_parser._itest.action_sequence)
        local action = itest_dsl_parser._itest.action_sequence[1]
        assert.are_same({time_trigger(4, true), nil}, {action.trigger, action.callback})
        assert.are_equal(time_trigger(8, true), itest_dsl_parser._last_time_trigger)
      end)

    end)

    describe('_define_final_assertion', function ()

      setup(function ()
        -- mock evaluators
        itest_dsl.evaluators[gp_value_types.pc_bottom_pos] = function ()
          return vector(27, 30)
        end
        itest_dsl.evaluators[gp_value_types.pc_velocity] = function ()
          return vector(-3, 2.5)
        end
      end)

      teardown(function ()
        -- reset evaluators
        itest_dsl.evaluators = generate_function_table(itest_dsl, gp_value_types, "eval_")
      end)

      before_each(function ()
        itest_dsl_parser._itest = integration_test('test', {})
      end)

      it('should set the final assertion as returning true, message when the gameplay value is expected', function ()
        itest_dsl_parser._final_expectations = {
          expectation(gp_value_types.pc_bottom_pos, vector(27, 30)),
          expectation(gp_value_types.pc_velocity, vector(-3, 2.5))
        }
        itest_dsl_parser:_define_final_assertion()
        assert.are_same({true, ""}, {itest_dsl_parser._itest.final_assertion()})
      end)

      it('should set the final assertion as returning false, message when the gameplay value is not expected', function ()
        itest_dsl_parser._final_expectations = {
          expectation(gp_value_types.pc_bottom_pos, vector(27, 30)),  -- ok
          expectation(gp_value_types.pc_velocity, vector(-3, 7.5))    -- different from actual
        }
        itest_dsl_parser:_define_final_assertion()
        local expected_message = "\nPassed gameplay value 'player character velocity':\nvector(-3, 2.5)\nExpected:\nvector(-3, 7.5)\n"
        assert.are_same({false, expected_message}, {itest_dsl_parser._itest.final_assertion()})
      end)

      it('should assert when the passed gameplay value type is invalid', function ()
        itest_dsl_parser._itest = integration_test('test', {})
        assert.has_error(function ()
          itest_dsl_parser._itest.final_assertion()
        end)
      end)

    end)

  end)

end)

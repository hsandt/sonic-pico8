require("bustedhelper")
require("engine/core/helper")
require("engine/core/math")
local itest_dsl = require("engine/test/itest_dsl")
local dsl_itest, command, expectation, itest_dsl_parser = itest_dsl.dsl_itest, itest_dsl.command, itest_dsl.expectation, itest_dsl.itest_dsl_parser
local integrationtest = require("engine/test/integrationtest")
local itest_manager, time_trigger, integration_test = integrationtest.itest_manager, integrationtest.time_trigger, integrationtest.integration_test
local flow = require("engine/application/flow")
local gameapp = require("game/application/gameapp")
local gamestate = require("game/application/gamestate")
local stage = require("game/ingame/stage")
local tilemap = require("engine/data/tilemap")
local player_char = require("game/ingame/playercharacter")
local pc_data = require("game/data/playercharacter_data")


describe('itest_dsl', function ()

  describe('command', function ()

    describe('_init', function ()
      it('should create a new dsl itest', function ()
        local cmd = command(itest_dsl_command_types.move, {horizontal_dirs.left})
        assert.is_not_nil(cmd)
        assert.are_same({itest_dsl_command_types.move, {horizontal_dirs.left}}, {cmd.type, cmd.args})
      end)
    end)

  end)

  describe('expectation', function ()

    describe('_init', function ()
      it('should create a new dsl itest', function ()
        local exp = expectation(itest_dsl_gp_value_types.pc_bottom_pos, 24)
        assert.is_not_nil(exp)
        assert.are_same({itest_dsl_gp_value_types.pc_bottom_pos, 24}, {exp.gp_value_type, exp.expected_value})
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
            command(itest_dsl_command_types[lines[next_line_index]],   { vector(1, 2) }                                      ),
            command(itest_dsl_command_types[lines[next_line_index+1]], {itest_dsl_gp_value_types.pc_bottom_pos, vector(3, 4)})
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
              command(itest_dsl_command_types.warp,   { vector(1, 2) }                                       ),
              command(itest_dsl_command_types.expect, {itest_dsl_gp_value_types.pc_bottom_pos, vector(3, 4)})
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
          "expect pc_bottom_pos 10 45",
          "expect pc_velocity 2 -3.5"
        }
        local commands = itest_dsl_parser.parse_action_sequence(dsli_lines, 5)
        assert.are_same(
            {
              command(itest_dsl_command_types.warp,  { vector(12, 45) }             ),
              command(itest_dsl_command_types.wait,   { 1 }                          ),
              command(itest_dsl_command_types.move,   { horizontal_dirs.left }       ),
              command(itest_dsl_command_types.wait,   { 2 }                          ),
              command(itest_dsl_command_types.expect, {itest_dsl_gp_value_types.pc_bottom_pos, vector(10, 45)}),
              command(itest_dsl_command_types.expect, {itest_dsl_gp_value_types.pc_velocity, vector(2, -3.5)}),
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
          command(itest_dsl_command_types.warp,   { vector(12, 45) }             ),
          command(itest_dsl_command_types.wait,   { 10 }                          ),
          command(itest_dsl_command_types.wait,   { 1 }                          ),
          command(itest_dsl_command_types.move,   { horizontal_dirs.left }       ),
          command(itest_dsl_command_types.wait,   { 2 }                          ),
          command(itest_dsl_command_types.expect, {itest_dsl_gp_value_types.pc_bottom_pos, vector(10, 45)}),
          command(itest_dsl_command_types.expect, {itest_dsl_gp_value_types.pc_velocity, vector(2, -3.5)}),
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
        local expected_message = "Passed gameplay value 'player character bottom position':\nvector(12, 45)\nExpected:\nvector(10, 45)\n"..
          "Passed gameplay value 'player character velocity':\nvector(0, 0)\nExpected:\nvector(2, -3.5)\n"
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

    describe('_evaluate', function ()

      it('should assert if an unknown gameplay value type is passed', function ()
        assert.has_error(function ()
          itest_dsl_parser._evaluate(-1)
        end, "unknown gameplay value: -1")
      end)

    end)

    describe('_add_final_expectation', function ()

      before_each(function ()
        itest_dsl_parser._itest = integration_test('test', {})
      end)

      it('should add to the final expectation an expectation with gameplay value type and expected value', function ()
        itest_dsl_parser:_add_final_expectation(itest_dsl_gp_value_types.pc_bottom_pos, vector(27, 30))
        assert.are_equal(1, #itest_dsl_parser._final_expectations)
        assert.are_equal(expectation(itest_dsl_gp_value_types.pc_bottom_pos, vector(27, 30)), itest_dsl_parser._final_expectations[1])
      end)

      it('should add to the final expectation an expectation with gameplay value type and expected value', function ()
        itest_dsl_parser._final_expectations = {
          expectation(itest_dsl_gp_value_types.pc_bottom_pos, vector(27, 30))
        }

        itest_dsl_parser:_add_final_expectation(itest_dsl_gp_value_types.pc_velocity, vector(-5, 3))

        assert.are_equal(2, #itest_dsl_parser._final_expectations)
        assert.are_equal(expectation(itest_dsl_gp_value_types.pc_velocity, vector(-5, 3)), itest_dsl_parser._final_expectations[2])
      end)

    end)

    describe('_define_final_assertion', function ()

      setup(function ()
        -- mock _evaluate (we won't care about the 1st argument thx to this)
        stub(itest_dsl_parser, "_evaluate", function (gp_value_type)
          if gp_value_type == itest_dsl_gp_value_types.pc_bottom_pos then
            return vector(27, 30)
          else
            return vector(-3, 2.5)
          end
        end)
      end)

      teardown(function ()
        itest_dsl_parser._evaluate:revert()
      end)

      before_each(function ()
        itest_dsl_parser._itest = integration_test('test', {})
      end)

      it('should set the final assertion as returning true, message when the gameplay value is expected', function ()
        itest_dsl_parser._final_expectations = {
          expectation(itest_dsl_gp_value_types.pc_bottom_pos, vector(27, 30)),
          expectation(itest_dsl_gp_value_types.pc_velocity, vector(-3, 2.5))
        }
        itest_dsl_parser:_define_final_assertion()
        assert.are_same({true, ""}, {itest_dsl_parser._itest.final_assertion()})
      end)

      it('should set the final assertion as returning false, message when the gameplay value is not expected', function ()
        itest_dsl_parser._final_expectations = {
          expectation(itest_dsl_gp_value_types.pc_bottom_pos, vector(27, 30)),  -- ok
          expectation(itest_dsl_gp_value_types.pc_velocity, vector(-3, 7.5))    -- different from actual
        }
        itest_dsl_parser:_define_final_assertion()
        local expected_message = "Passed gameplay value 'player character velocity':\nvector(-3, 2.5)\nExpected:\nvector(-3, 7.5)\n"
        assert.are_same({false, expected_message}, {itest_dsl_parser._itest.final_assertion()})
      end)

      it('should assert when the passed gameplay value type is invalid', function ()
        itest_dsl_parser._itest = integration_test('test', {})
        assert.has_error(function ()
          itest_dsl_parser._itest.final_assertion()
        end)
      end)

    end)

    describe('_evaluate', function ()

      -- add gameplay value types tests here

      it('should return the player character bottom position for ', function ()
        -- simulate stage state on_enter by just creating pc
        stage.state.player_char = player_char()
        stage.state.player_char:spawn_bottom_at(vector(2, 8))

        assert.are_equal(vector(2, 8), itest_dsl_parser._evaluate(itest_dsl_gp_value_types.pc_bottom_pos))
      end)

      it('should assert if an unknown gameplay value type is passed', function ()
        assert.has_error(function ()
          itest_dsl_parser._evaluate(-1)
        end, "unknown gameplay value: -1")
      end)

    end)

  end)

end)

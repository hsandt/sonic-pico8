require("test/bustedhelper_ingame")
require("resources/visual_ingame_addon")

require("engine/core/seq_helper")
local flow = require("engine/application/flow")
local tilemap = require("engine/data/tilemap")
local input = require("engine/input/input")
local integration_test = require("engine/test/integration_test")
local itest_manager = require("engine/test/itest_manager")
local scripted_action = require("engine/test/scripted_action")
local time_trigger = require("engine/test/time_trigger")

local itest_dsl = require("itest/itest_dsl")
local gameplay_value_data = get_members(itest_dsl, "gameplay_value_data")
-- get_members is convenient to hide underscores with proxy refs
local eval_pc_bottom_pos, eval_pc_velocity, eval_pc_velocity_y, eval_pc_ground_spd, eval_pc_motion_state, eval_pc_slope = get_members(itest_dsl,
     "eval_pc_bottom_pos", "eval_pc_velocity", "eval_pc_velocity_y", "eval_pc_ground_spd", "eval_pc_motion_state", "eval_pc_slope")
local command,   expectation = get_members(itest_dsl,
     "command", "expectation")
local dsl_itest,   itest_dsl_parser = get_members(itest_dsl,
     "dsl_itest", "itest_dsl_parser")
local stage_state = require("ingame/stage_state")

local picosonic_app_ingame = require("application/picosonic_app_ingame")
local player_char = require("ingame/playercharacter")
local pc_data = require("data/playercharacter_data")
local tile_repr = require("test_data/tile_representation")
local tile_test_data = require("test_data/tile_test_data")

describe('itest_dsl', function ()

  -- stub very slow functions called on stage state enter
  --  so utests calling flow:change_gamestate_by_type(':stage') in before_each
  --  don't have a big overhead on start
  setup(function ()
    stub(stage_state, "spawn_objects_in_all_map_regions")
  end)

  teardown(function ()
    stage_state.spawn_objects_in_all_map_regions:revert()
  end)

  local state

  before_each(function ()
    local app = picosonic_app_ingame()
    state = stage_state()
    state.app = app

    -- some executions require the player character
    state.player_char = player_char()
  end)

  describe('gameplay_value_data', function ()

    describe('init', function ()
      it('should create gameplay value data', function ()
        local data = gameplay_value_data("position", parsable_types.vector)
        assert.is_not_nil(data)
        assert.are_same({"position", parsable_types.vector}, {data.name, data.parsable_type})
      end)
    end)

  end)

  describe('parse_', function ()

    describe('parse_none', function ()

      it('should assert when the number of arguments is wrong', function ()
        assert.has_error(function ()
          itest_dsl.parse_none({"too many"})
        end, "parse_none: got 1 args, expected 0")
      end)

      it('should return nil', function ()
        assert.is_nil(itest_dsl.parse_none({}))
      end)

    end)

    describe('parse_number', function ()

      it('should assert when the number of arguments is wrong', function ()
        assert.has_error(function ()
          itest_dsl.parse_number({"too", "many"})
        end, "parse_number: got 2 args, expected 1")
      end)

      it('should return the single string argument as number', function ()
        assert.are_equal(5, itest_dsl.parse_number({"5"}))
      end)

    end)

    describe('parse_vector', function ()

      it('should assert when the number of arguments is wrong', function ()
        assert.has_error(function ()
          itest_dsl.parse_vector({"too few"})
        end, "parse_vector: got 1 args, expected 2")
      end)

      it('should return the 2 coordinate string arguments as vector', function ()
        assert.are_same(vector(2, -3.5), itest_dsl.parse_vector({"2", "-3.5"}))
      end)

    end)

    describe('parse_horizontal_dir', function ()

      it('should assert when the number of arguments is wrong', function ()
        assert.has_error(function ()
          itest_dsl.parse_horizontal_dir({"too", "many"})
        end, "parse_horizontal_dir: got 2 args, expected 1")
      end)

      it('should return the single argument as horizontal direction', function ()
        assert.are_equal(horizontal_dirs.right, itest_dsl.parse_horizontal_dir({"right"}))
      end)

    end)

    describe('parse_control_mode', function ()

      it('should assert when the number of arguments is wrong', function ()
        assert.has_error(function ()
          itest_dsl.parse_control_mode({"too", "many"})
        end, "parse_control_mode: got 2 args, expected 1")
      end)

      it('should return the single argument as control mode', function ()
        assert.are_equal(control_modes.ai, itest_dsl.parse_control_mode({"ai"}))
      end)

    end)

    describe('parse_motion_mode', function ()

      it('should assert when the number of arguments is wrong', function ()
        assert.has_error(function ()
          itest_dsl.parse_motion_mode({"too", "many"})
        end, "parse_motion_mode: got 2 args, expected 1")
      end)

      it('should return the single argument as motion mode', function ()
        assert.are_equal(motion_modes.debug, itest_dsl.parse_motion_mode({"debug"}))
      end)

    end)

    describe('parse_button_id', function ()

      it('should assert when the number of arguments is wrong', function ()
        assert.has_error(function ()
          itest_dsl.parse_button_id({"too", "many"})
        end, "parse_button_id: got 2 args, expected 1")
      end)

      it('should return the single argument as motion mode', function ()
        assert.are_equal(button_ids.o, itest_dsl.parse_button_id({"o"}))
      end)

    end)

    describe('parse_motion_state', function ()

      it('should assert when the number of arguments is wrong', function ()
        assert.has_error(function ()
          itest_dsl.parse_motion_state({"too", "many"})
        end, "parse_motion_state: got 2 args, expected 1")
      end)

      it('should return the single argument as motion state', function ()
        assert.are_equal(motion_states.falling, itest_dsl.parse_motion_state({"falling"}))
      end)

    end)

    describe('parse_gp_value', function ()

      it('should assert when the number of arguments is wrong', function ()
        assert.has_error(function ()
          itest_dsl.parse_gp_value({"too few"})
        end, "parse_gp_value: got 1 args, expected at least 2")
      end)

      it('should return the gameplay value type string and the expected value, itself recursively parsed', function ()
        assert.are_same({"pc_bottom_pos", vector(1, 3)},
          {itest_dsl.parse_gp_value({"pc_bottom_pos", "1", "3"})})
      end)

    end)

  end)

  describe('execute_', function ()

    before_each(function ()
      flow:add_gamestate(state)
      flow:change_gamestate_by_type(':stage')
    end)

    after_each(function ()
      flow:init()
    end)

    describe('execute_warp', function ()

      setup(function ()
        spy.on(player_char, "warp_bottom_to")
      end)

      teardown(function ()
        player_char.warp_bottom_to:revert()
      end)

      it('should call warp_bottom_to on the current player character', function ()
        itest_dsl.execute_warp({vector(1, 3)})

        assert.spy(player_char.warp_bottom_to).was_called(1)
        assert.spy(player_char.warp_bottom_to).was_called_with(match.ref(state.player_char), vector(1, 3))
      end)

    end)

    describe('"execute_set', function ()

      it('should set pc velocity to (1, -3)', function ()
        itest_dsl.execute_set({"pc_velocity", vector(1, -3)})
        assert.are_same(vector(1, -3), state.player_char.velocity)
      end)

      it('should fail with unsupported gp_value_type for setting', function ()
        assert.has_error(function ()
          itest_dsl.execute_set({"pc_slope", -2})
        end, "setter for pc_slope is not defined")
      end)

    end)

    describe('execute_set_control_mode', function ()

      it('should set the control mode', function ()
        itest_dsl.execute_set_control_mode({control_modes.puppet})
        assert.are_equal(control_modes.puppet, state.player_char.control_mode)
      end)

    end)

    describe('execute_set_motion_mode', function ()

      setup(function ()
        stub(player_char, "set_motion_mode")
      end)

      teardown(function ()
        player_char.set_motion_mode:revert()
      end)

      it('should set the motion mode', function ()
        itest_dsl.execute_set_motion_mode({motion_modes.debug})
        assert.spy(player_char.set_motion_mode).was_called(1)
        assert.spy(player_char.set_motion_mode).was_called_with(match.ref(state.player_char), motion_modes.debug)
      end)

    end)

    describe('execute_move', function ()

      it('should set the move intention of the current player character to the directional unit vector matching his horizontal direction', function ()
        itest_dsl.execute_move({horizontal_dirs.right})
        assert.are_same(vector(1, 0), state.player_char.move_intention)
      end)

    end)

    describe('execute_stop', function ()

      it('should set the move intention of the current player character to vector zero', function ()
        state.player_char.move_intention = vector(99, -99)
        itest_dsl.execute_stop({})
        assert.are_same(vector.zero(), state.player_char.move_intention)
      end)

    end)

    describe('execute_jump', function ()

      it('should set the jump intention and hold jump intention to true', function ()
        itest_dsl.execute_jump({})
        assert.are_same({true, true},
          {state.player_char.jump_intention, state.player_char.hold_jump_intention})
      end)

    end)

    describe('execute_stop_jump', function ()

      it('should set the hold jump intention to false', function ()
        state.player_char.hold_jump_intention = true
        itest_dsl.execute_stop_jump({})
        assert.is_false(state.player_char.hold_jump_intention)
      end)

    end)

    describe('execute_press', function ()

      it('should set the simulated button down state to true', function ()
        input.simulated_buttons_down[0][button_ids.x] = false
        itest_dsl.execute_press({button_ids.x})
        assert.is_true(input.simulated_buttons_down[0][button_ids.x])
      end)

    end)

    describe('execute_release', function ()

      it('should set the simulated button down state to true', function ()
        input.simulated_buttons_down[0][button_ids.up] = true
        itest_dsl.execute_release({button_ids.up})
        assert.is_false(input.simulated_buttons_down[0][button_ids.up])
      end)

    end)

  end)

  describe('eval_', function ()

    before_each(function ()
      flow:add_gamestate(state)
      flow:change_gamestate_by_type(':stage')
    end)

    describe('eval_pc_bottom_pos', function ()

      it('should return the bottom position of the current player character', function ()
        state.player_char:set_bottom_center(vector(12, 47))
        assert.are_same(vector(12, 47), eval_pc_bottom_pos())
      end)

    end)

    describe('eval_pc_velocity', function ()

      it('should return the velocity of the current player character', function ()
        state.player_char.velocity = vector(1, -4)
        assert.are_same(vector(1, -4), eval_pc_velocity())
      end)

    end)

    describe('eval_pc_velocity_y', function ()

      it('should return the velocity y of the current player character', function ()
        state.player_char.velocity = vector(1, -4)
        assert.are_equal(-4, eval_pc_velocity_y())
      end)

    end)

    describe('eval_pc_ground_spd', function ()

      it('should return the ground speed of the current player character', function ()
        state.player_char.ground_speed = 3.5
        assert.are_equal(3.5, eval_pc_ground_spd())
      end)

    end)

    describe('eval_pc_motion_state', function ()

      it('should return the motion state of the current player character', function ()
        state.player_char.motion_state = motion_states.air_spin
        assert.are_equal(motion_states.air_spin, eval_pc_motion_state())
      end)

    end)

    describe('eval_pc_slope', function ()

      it('should return the slope angle of the current player character', function ()
        state.player_char.slope_angle = -0.125
        assert.are_equal(-0.125, eval_pc_slope())
      end)

    end)

  end)


  describe('_set_', function ()

    before_each(function ()
      flow:add_gamestate(state)
      flow:change_gamestate_by_type(':stage')
    end)

    describe('set_pc_velocity', function ()

      it('should set the velocity of the current player character', function ()
        itest_dsl.set_pc_velocity(vector(1, -4))
        assert.are_same(vector(1, -4), state.player_char.velocity)
      end)

    end)

    describe('set_pc_velocity_y', function ()

      it('should set the velocity of the current player character', function ()
        state.player_char.velocity = vector(1, 10)
        itest_dsl.set_pc_velocity_y(-4)
        assert.are_same(vector(1, -4), state.player_char.velocity)
      end)

    end)

    describe('set_pc_ground_spd', function ()

      it('should set the ground of speed current player character', function ()
        itest_dsl.set_pc_ground_spd(3.5)
        assert.are_equal(3.5, state.player_char.ground_speed)
      end)

    end)

  end)


  describe('command', function ()

    describe('init', function ()
      it('should create a new dsl itest', function ()
        local cmd = command(command_types.move, {horizontal_dirs.left})
        assert.is_not_nil(cmd)
        assert.are_same({command_types.move, {horizontal_dirs.left}}, {cmd.type, cmd.args})
      end)
    end)

  end)

  describe('expectation', function ()

    describe('init', function ()
      it('should create a new dsl itest', function ()
        local exp = expectation("pc_bottom_pos", 24)
        assert.is_not_nil(exp)
        assert.are_same({"pc_bottom_pos", 24}, {exp.gp_value_type_str, exp.expected_value})
      end)
    end)

  end)

  describe('dsl_itest', function ()

    describe('init', function ()
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
      stub(tile_test_data, "setup")
      stub(tile_test_data, "teardown")
    end)

    teardown(function ()
      tile_test_data.setup:revert()
      tile_test_data.teardown:revert()
    end)

    after_each(function ()
      itest_dsl_parser:init()
      flow:init()
      pico8:clear_map()
      tile_test_data.setup:clear()
      tile_test_data.teardown:clear()
    end)

    describe('init', function ()
      assert.are_same({
          nil,
          nil,
          {}
        },
        {
          itest_dsl_parser.itest,
          itest_dsl_parser.last_time_trigger,
          itest_dsl_parser.final_expectations
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
@stage
#
32

warp
expect
]]

        local dsli = itest_dsl_parser.parse(dsli_source)

        -- interface
        assert.is_not_nil(dsli)
        assert.is_true(are_same_with_message(
          {
            -- no ':stage' here, it's still interpret as plain text at this point
            '@stage',
            '#',
            tilemap({
              { 0, 32},
              {32,  0}
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
          }))
      end)

    end)


    describe('parse_gamestate_definition', function ()

      it('should return gamestate name, nil, nil and 3 for a non-stage gamestate and no extra line', function ()
        local dsli_lines = {"@titlemenu"}
        local gamestate_type, stage_name, tm, next_line_index = itest_dsl_parser.parse_gamestate_definition(dsli_lines)
        assert.are_same(
          {
            ':titlemenu',
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
            ':stage',
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
              {70, 32},
              {32, 70}
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
          assert.is_true(are_same_with_message(
            {
              ':stage',
              '#',
              tilemap({
                {70, 32},
                {32, 70}
              }),
              5
            },
            {
              gamestate_type,
              stage_name,
              tm,
              next_line_index
            }))
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
        assert.is_true(are_same_with_message(
          {
            tilemap({}),
            3
          },
          {tm, next_line_index}))
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
        local full = tile_repr.full_tile_id
        assert.is_true(are_same_with_message(
          {
            tilemap({
              {   0,    0,    0,    0},
              {full, full,    0,    0},
              {   0,    0, full, full}
            }),
            6
          },
          {tm, next_line_index}))
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
        assert.is_true(are_same_with_message(
            {
              command(command_types.warp,   { vector(12, 45) }             ),
              command(command_types.wait,   { 1 }                          ),
              command(command_types.move,   { horizontal_dirs.left }       ),
              command(command_types.wait,   { 2 }                          ),
              command(command_types.expect, {"pc_bottom_pos", vector(10, 45)}),
              command(command_types.expect, {"pc_velocity", vector(2, -3.5)}),
            },
            commands))
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
        dsli.gamestate_type = ':stage'
        dsli.stage_name = "test1"
        dsli.tilemap = nil
        dsli.commands = {
          command(command_types.warp,   { vector(12, 45) }             ),
          command(command_types.wait,   { 10 }                          ),
          command(command_types.wait,   { 1 }                          ),
          command(command_types.move,   { horizontal_dirs.left }       ),
          command(command_types.wait,   { 2 }                          ),
          command(command_types.expect, {"pc_bottom_pos", vector(10, 45)}),
          command(command_types.expect, {"pc_velocity", vector(2, -3.5)}),
        }

        local test = itest_dsl_parser.create_itest("test 1", dsli)

        -- interface
        assert.is_not_nil(test)
        assert.are_equal(4, #test.action_sequence)
        assert.are_same({
            "test 1",
            {':stage'},
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

        -- we only need stage state for stage itests
        -- however, if character reaches goal we may go to another state
        -- and since we removed dummies, we may have issues
        -- if it happens, just create a dummy next state with the right type
        -- and add it here
        flow:add_gamestate(state)

        -- verify setup callback behavior
        test.setup()
        assert.are_equal(':stage', flow.curr_state.type)

        -- verify warp callback behavior
        test.action_sequence[1].callback()
        assert.is_not_nil(state.player_char)
        assert.are_same(vector(12, 45 - pc_data.center_height_standing), state.player_char.position)

        -- verify move callback behavior
        test.action_sequence[3].callback()
        assert.are_same(vector(-1, 0), state.player_char.move_intention)

        -- we have not passed time so the character cannot have reached expected position
        -- OLD note: we are testing as busted, so we get the almost_eq messages
        -- since we added quadrants, even integer coordinates receive float transformation,
        --  hence the .0 on passed position
        -- (since we removed .0 and . in front of numbers as much as possible to reduce compressed chars count,
        --  and so float operation was detected, in this particular case we won't have the float points anymore)
        -- local expected_message = "\nFor gameplay value 'player character bottom position':\nExpected objects to be almost equal with eps: 0.015625.\n"..
        --   "Passed in:\nvector(12.0, 45.0)\nExpected:\nvector(10, 45)\n"..
        --   "\nFor gameplay value 'player character velocity':\nExpected objects to be almost equal with eps: 0.015625.\n"..
        --   "Passed in:\nvector(0, 0)\nExpected:\nvector(2, -3.5)\n"
        -- shorter version in assertions.lua
        local expected_message = "\nFor gameplay value 'player character bottom position':\nExpected ~~ with eps: 0.015625.\n"..
          "Passed in:\nvector(12, 45)\nExpected:\nvector(10, 45)\n"..
          "\nFor gameplay value 'player character velocity':\nExpected ~~ with eps: 0.015625.\n"..
          "Passed in:\nvector(0, 0)\nExpected:\nvector(2, -3.5)\n"
        assert.are_same({false, expected_message}, {test.final_assertion()})

        -- but if we cheat and warp him on the spot, final assertion will work
        state.player_char:set_bottom_center(vector(10, 45))
        state.player_char.velocity = vector(2, -3.5)
        assert.are_same({true, ""}, {test.final_assertion()})

        -- verify that parser state is cleaned up, ready for next parsing
        assert.are_same({
            nil,
            nil,
            {}
          },
          {
            itest_dsl_parser.itest,
            itest_dsl_parser.last_time_trigger,
            itest_dsl_parser.final_expectations
          })
      end)

      describe('(spying tilemap load)', function ()

        setup(function ()
          stub(tilemap, "load")
          stub(tilemap, "clear_map")
        end)

        teardown(function ()
          tilemap.load:revert()
          tilemap.clear_map:revert()
        end)

        after_each(function ()
          tilemap.load:clear()
          tilemap.clear_map:clear()
        end)

        it('setup should call tile_test_data.setup and load on the tilemap if custom stage definition', function ()
          local dsli = dsl_itest()
          dsli.gamestate_type = ':stage'
          dsli.stage_name = "#"
          dsli.tilemap = tilemap({})
          dsli.commands = {}

          local test = itest_dsl_parser.create_itest("test 1", dsli)

          -- see comment in previous test
          flow:add_gamestate(state)

          test.setup()

          -- interface
          assert.are_equal(control_modes.puppet, state.player_char.control_mode)

          -- implementation
          local s_data = assert.spy(tile_test_data.setup)
          s_data.was_called(1)
          s_data.was_called_with()
          local s_load = assert.spy(tilemap.load)
          s_load.was_called(1)
          s_load.was_called_with(match.ref(dsli.tilemap))
        end)

        it('teardown should call clear_map and tile_test_data.teardown if custom stage definition', function ()
          local dsli = dsl_itest()
          dsli.gamestate_type = ':stage'
          dsli.stage_name = "#"
          dsli.tilemap = tilemap({})
          dsli.commands = {}

          local test = itest_dsl_parser.create_itest("test 1", dsli)

          -- see comment in previous test
          flow:add_gamestate(state)

          test.teardown()

          -- implementation
          local s_clear = assert.spy(tilemap.clear_map)
          s_clear.was_called(1)
          s_clear.was_called_with()
          local s_teardown = assert.spy(tile_test_data.teardown)
          s_teardown.was_called(1)
          s_teardown.was_called_with()
        end)

      end)

    end)

    describe('act', function ()

      local function f() end

      before_each(function ()
        itest_dsl_parser.itest = integration_test("test 1", {})
      end)

      after_each(function ()
        itest_manager:init()
      end)

      it('should add an action after an existing time trigger, and clear the last time trigger', function ()
        itest_dsl_parser.last_time_trigger = time_trigger(3, true)
        itest_dsl_parser:act(f)
        assert.are_equal(1, #itest_dsl_parser.itest.action_sequence)
        local action = itest_dsl_parser.itest.action_sequence[1]
        assert.are_same({time_trigger(3, true), f,
            nil},
          {action.trigger, action.callback,
            itest_dsl_parser.last_time_trigger})
      end)

    end)

    describe('wait', function ()

      before_each(function ()
        itest_dsl_parser.itest = integration_test('test', {})
      end)

      it('should set the current time_trigger of the parser to one with the passed interval, in frames', function ()
        itest_dsl_parser:wait(12)
        assert.are_same(time_trigger(12, true), itest_dsl_parser.last_time_trigger)
      end)

      it('should add a dummy action with any previous time trigger, then set the last time trigger to the new one', function ()
        itest_dsl_parser.last_time_trigger = time_trigger(4, true)
        itest_dsl_parser:wait(8)
        assert.are_equal(1, #itest_dsl_parser.itest.action_sequence)
        local action = itest_dsl_parser.itest.action_sequence[1]
        assert.are_same({time_trigger(4, true), nil}, {action.trigger, action.callback})
        assert.are_same(time_trigger(8, true), itest_dsl_parser.last_time_trigger)
      end)

    end)

    describe('define_final_assertion', function ()

      local original_evaluators

      setup(function ()
        -- unfortunately, we decided to keep evaluators local, and our itest_dsl.evaluators
        --  is not what is used in the methods, it's only a reference to the local one
        -- so reassigning that reference wouldn't mock them for real, we need to change
        --  the table content by index
        -- but to revert this change we need to backup the evaluators (at least
        --  the two ones we will mock)
        -- if we were using itest_dsl.evaluators for real in define_final_assertion,
        --  we could just backup the *reference* to evaluators and mock itest_dsl.evaluators
        --  by reassigning it to a mockup table
        original_evaluators = copy_seq(itest_dsl.evaluators)

        -- now change the *content* of the evaluators table
        itest_dsl.evaluators[gp_value_types.pc_bottom_pos] = function ()
          return vector(27, 30)
        end
        itest_dsl.evaluators[gp_value_types.pc_velocity] = function ()
          return vector(-3, 2.5)
        end
      end)

      teardown(function ()
        -- reset evaluators content from the backup
        itest_dsl.evaluators[gp_value_types.pc_bottom_pos] = original_evaluators[gp_value_types.pc_bottom_pos]
        itest_dsl.evaluators[gp_value_types.pc_velocity] = original_evaluators[gp_value_types.pc_velocity]
      end)

      before_each(function ()
        itest_dsl_parser.itest = integration_test('test', {})
      end)

      it('should set the final assertion as returning true, message when the gameplay value is expected', function ()
        itest_dsl_parser.final_expectations = {
          expectation("pc_bottom_pos", vector(27, 30)),
          expectation("pc_velocity", vector(-3, 2.5))
        }
        itest_dsl_parser:define_final_assertion()
        assert.are_same({true, ""}, {itest_dsl_parser.itest.final_assertion()})
      end)

      it('should set the final assertion as returning false, message when the gameplay value is not expected', function ()
        itest_dsl_parser.final_expectations = {
          expectation("pc_bottom_pos", vector(27, 30)),  -- ok
          expectation("pc_velocity", vector(-3, 7.5))    -- different from actual
        }
        itest_dsl_parser:define_final_assertion()
        -- local expected_message = "\nFor gameplay value 'player character velocity':\nExpected objects to be almost equal with eps: 0.015625.\n"..
        -- "Passed in:\nvector(-3, 2.5)\nExpected:\nvector(-3, 7.5)\n"
        -- short version in assertions.lua
        local expected_message = "\nFor gameplay value 'player character velocity':\nExpected ~~ with eps: 0.015625.\n"..
        "Passed in:\nvector(-3, 2.5)\nExpected:\nvector(-3, 7.5)\n"
        assert.are_same({false, expected_message}, {itest_dsl_parser.itest.final_assertion()})
      end)

      it('should assert when the passed gameplay value type is invalid', function ()
        itest_dsl_parser.itest = integration_test('test', {})
        assert.has_error(function ()
          itest_dsl_parser.itest.final_assertion()
        end)
      end)

    end)

  end)

end)

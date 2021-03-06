require("test/bustedhelper_ingame")
require("resources/visual_ingame_addon")

local player_char = require("ingame/playercharacter")

local flow = require("engine/application/flow")
local location_rect = require("engine/core/location_rect")
local input = require("engine/input/input")
local animated_sprite = require("engine/render/animated_sprite")

local pc_data = require("data/playercharacter_data")
local emerald = require("ingame/emerald")
local stage_state = require("ingame/stage_state")
local motion = require("platformer/motion")
local ground_query_info = motion.ground_query_info
local world = require("platformer/world")
local audio = require("resources/audio")
local visual = require("resources/visual_common")
local tile_repr = require("test_data/tile_representation")
local tile_test_data = require("test_data/tile_test_data")

describe('player_char', function ()

  -- static methods

  describe('compute_max_pixel_distance', function ()

    it('(2, 0) => 0', function ()
      assert.are_equal(0, player_char.compute_max_pixel_distance(2, 0))
    end)

    it('(2, 1.5) => 1', function ()
      assert.are_equal(1, player_char.compute_max_pixel_distance(2, 1.5))
    end)

    it('(2, 3) => 3', function ()
      assert.are_equal(3, player_char.compute_max_pixel_distance(2, 3))
    end)

    it('(2.2, 1.7) => 1', function ()
      assert.are_equal(1, player_char.compute_max_pixel_distance(2.2, 1.7))
    end)

    it('(2.2, 1.8) => 2', function ()
      assert.are_equal(2, player_char.compute_max_pixel_distance(2.2, 1.8))
    end)

    -- bugfix history:
    -- / I completely forgot the left case, which is important to test flooring asymmetry
    --   I thought it was hiding bugs, but I realize my asymmetrical design was actually fine

    it('(2, -0.1) => 1', function ()
      assert.are_equal(1, player_char.compute_max_pixel_distance(2, -0.1))
    end)

    it('(2, -1) => 1', function ()
      assert.are_equal(1, player_char.compute_max_pixel_distance(2, -1))
    end)

    it('(2, -1.1) => 2', function ()
      assert.are_equal(2, player_char.compute_max_pixel_distance(2, -1.1))
    end)

    it('(2.2, -0.2) => 0', function ()
      assert.are_equal(0, player_char.compute_max_pixel_distance(2.2, -0.2))
    end)

    it('(2.2, -0.3) => 1', function ()
      assert.are_equal(1, player_char.compute_max_pixel_distance(2.2, -0.3))
    end)

    it('(2.2, -1.2) => 1', function ()
      assert.are_equal(1, player_char.compute_max_pixel_distance(2.2, -1.2))
    end)

    it('(2.2, -1.3) => 2', function ()
      assert.are_equal(2, player_char.compute_max_pixel_distance(2.2, -1.3))
    end)

  end)


  -- methods

  describe('init', function ()

    setup(function ()
      stub(player_char, "setup")
    end)

    teardown(function ()
      player_char.setup:revert()
    end)

    after_each(function ()
      player_char.setup:clear()
    end)

    it('should create a player character and setup all the state vars', function ()
      local pc = player_char()
      assert.is_not_nil(pc)

      -- implementation
      assert.spy(player_char.setup).was_called(1)
      assert.spy(player_char.setup).was_called_with(match.ref(pc))
    end)

    it('should create a player character storing values from playercharacter_data', function ()
      local pc = player_char()
      assert.is_not_nil(pc)
      assert.are_same(
        {
          pc_data.debug_move_max_speed,
          pc_data.debug_move_accel,
          pc_data.debug_move_decel,
          pc_data.debug_move_friction,
          -- setup will modify anim_spr state, but we stubbed it so it's still
          --  has the value on init now
          animated_sprite(pc_data.sonic_animated_sprite_data_table),
          0,  -- cheat
        },
        {
          pc.debug_move_max_speed,
          pc.debug_move_accel,
          pc.debug_move_decel,
          pc.debug_move_friction,
          pc.anim_spr,
          pc.last_emerald_warp_nb,  -- cheat
        }
      )
    end)
  end)

  describe('setup', function ()

    setup(function ()
      spy.on(animated_sprite, "play")
    end)

    teardown(function ()
      animated_sprite.play:revert()
    end)

    it('should reset the character state vars', function ()
      local pc = player_char()
      assert.is_not_nil(pc)
      assert.are_same(
        {
          control_modes.human,
          motion_modes.platformer,  -- cheat
          motion_states.standing,
          directions.down,
          horizontal_dirs.right,
          1,
          0,

          location(-1, -1),
          vector(-1, -1),
          0,
          0,
          vector.zero(),
          vector.zero(),
          0,
          0,

          vector.zero(),
          false,
          false,
          false,
          false,
          false,

          0,
          0,
          false,
          0,

          {},  -- debug_character
        },
        {
          pc.control_mode,
          pc.motion_mode,  -- cheat
          pc.motion_state,
          pc.quadrant,
          pc.orientation,
          pc.active_loop_layer,
          pc.ignore_launch_ramp_timer,

          pc.ground_tile_location,
          pc.position,
          pc.ground_speed,
          pc.horizontal_control_lock_timer,
          pc.velocity,
          pc.debug_velocity,
          pc.slope_angle,
          pc.ascending_slope_time,

          pc.move_intention,
          pc.jump_intention,
          pc.hold_jump_intention,
          pc.should_jump,
          pc.has_jumped_this_frame,
          pc.can_interrupt_jump,

          pc.anim_run_speed,
          pc.continuous_sprite_angle,
          pc.should_play_spring_jump,
          pc.brake_anim_phase,

          pc.debug_rays,  -- debug_character
        }
      )
      assert.spy(animated_sprite.play).was_called(1)
      assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "idle")
    end)

  end)

  describe('(with player character)', function ()
    local pc

    before_each(function ()
      -- normally we add and enter gamestate properly to initialize stage,
      --  but enough here, we just need to provide access to stage via flow for
      --  things like loop layer checks
      local curr_stage_state = stage_state()
      curr_stage_state.loaded_map_region_coords = vector(0, 0)
      flow.curr_state = curr_stage_state

      -- recreate player character for each test (setup spies will need to refer to player_char,
      --  not the instance)
      pc = player_char()
    end)

    describe('is_grounded', function ()

      it('should return true when character is standing on the ground', function ()
        pc.motion_state = motion_states.standing
        assert.is_true(pc:is_grounded())
      end)

      it('should return true when character is rolling on the ground', function ()
        pc.motion_state = motion_states.rolling
        assert.is_true(pc:is_grounded())
      end)

      it('should return false when character is falling', function ()
        pc.motion_state = motion_states.falling
        assert.is_false(pc:is_grounded())
      end)

      it('should return false when character is in air spin', function ()
        pc.motion_state = motion_states.air_spin
        assert.is_false(pc:is_grounded())
      end)

    end)

    describe('is_compact', function ()

      it('should return false when character is standing on the ground', function ()
        pc.motion_state = motion_states.standing
        assert.is_false(pc:is_compact())
      end)

      it('should return true when character is rolling on the ground', function ()
        pc.motion_state = motion_states.rolling
        assert.is_true(pc:is_compact())
      end)

      it('should return false when character is falling', function ()
        pc.motion_state = motion_states.falling
        assert.is_false(pc:is_compact())
      end)

      it('should return true when character is in air spin', function ()
        pc.motion_state = motion_states.air_spin
        assert.is_true(pc:is_compact())
      end)

    end)

    describe('get_center_height', function ()

      it('should return center height standing when standing', function ()
        assert.are_equal(pc_data.center_height_standing, pc:get_center_height())
      end)

      it('should return center height compact when compact', function ()
        pc.motion_state = motion_states.air_spin
        assert.are_equal(pc_data.center_height_compact, pc:get_center_height())
      end)

    end)

    describe('get_full_height', function ()

      it('should return full height standing when standing', function ()
        assert.are_equal(pc_data.full_height_standing, pc:get_full_height())
      end)

      it('should return full height compact when compact', function ()
        pc.motion_state = motion_states.air_spin
        assert.are_equal(pc_data.full_height_compact, pc:get_full_height())
      end)

    end)

    describe('get_quadrant_right', function ()

      it('should return vector(1, 0) when quadrant is down', function ()
        pc.quadrant = directions.down
        assert.are_same(vector(1, 0), pc:get_quadrant_right())
      end)

      it('should return vector(-1, 0) when quadrant is up', function ()
        pc.quadrant = directions.up
        assert.are_same(vector(-1, 0), pc:get_quadrant_right())
      end)

      it('should return vector(0, -1) when quadrant is right', function ()
        pc.quadrant = directions.right
        assert.are_same(vector(0, -1), pc:get_quadrant_right())
      end)

      it('should return vector(0, 1) when quadrant is left', function ()
        pc.quadrant = directions.left
        assert.are_same(vector(0, 1), pc:get_quadrant_right())
      end)

    end)

    describe('get_quadrant_down', function ()

      it('should return vector(0, 1) when quadrant is down', function ()
        pc.quadrant = directions.down
        assert.are_same(vector(0, 1), pc:get_quadrant_down())
      end)

      it('should return vector(0, -1) when quadrant is up', function ()
        pc.quadrant = directions.up
        assert.are_same(vector(0, -1), pc:get_quadrant_down())
      end)

      it('should return vector(1, 0) when quadrant is right', function ()
        pc.quadrant = directions.right
        assert.are_same(vector(1, 0), pc:get_quadrant_down())
      end)

      it('should return vector(-1, 0) when quadrant is left', function ()
        pc.quadrant = directions.left
        assert.are_same(vector(-1, 0), pc:get_quadrant_down())
      end)

    end)

    describe('quadrant_rotated', function ()

      it('should return same vector content when quadrant is down', function ()
        pc.quadrant = directions.down
        assert.are_same(vector(1, -2), pc:quadrant_rotated(vector(1, -2)))
      end)

      -- busted implementation is exact and should pass without almost_eq,
      --  but they are useful when testing the pico8 implementation

      it('should return vector rotated by 0.25 when quadrant is right', function ()
        pc.quadrant = directions.right
        assert.is_true(almost_eq_with_message(vector(-2, -1), pc:quadrant_rotated(vector(1, -2))))
      end)

      it('should return vector rotated by 0.5 when quadrant is up', function ()
        pc.quadrant = directions.up
        assert.is_true(almost_eq_with_message(vector(-1, 2), pc:quadrant_rotated(vector(1, -2))))
      end)

      it('should return vector rotated by 0.75 when quadrant is left', function ()
        pc.quadrant = directions.left
        assert.is_true(almost_eq_with_message(vector(2, 1), pc:quadrant_rotated(vector(1, -2))))
      end)

    end)

    describe('spawn_at', function ()

      setup(function ()
        stub(player_char, "setup")
        stub(player_char, "warp_to")
      end)

      teardown(function ()
        player_char.setup:revert()
        player_char.warp_to:revert()
      end)

      before_each(function ()
        -- setup is called on construction, so clear just after that
        player_char.setup:clear()
      end)

      it('should call _setup and warp_to', function ()
        player_char.setup:clear()
        pc:spawn_at(vector(56, 12))

        -- implementation
        assert.spy(player_char.setup).was_called(1)
        assert.spy(player_char.setup).was_called_with(match.ref(pc))
        assert.spy(player_char.warp_to).was_called(1)
        assert.spy(player_char.warp_to).was_called_with(match.ref(pc), vector(56, 12))
      end)

    end)

    describe('warp_to', function ()

      setup(function ()
        stub(player_char, "enter_motion_state")
      end)

      teardown(function ()
        player_char.enter_motion_state:revert()
      end)

      after_each(function ()
        player_char.enter_motion_state:clear()
      end)

      it('should set the character\'s position', function ()
        pc:warp_to(vector(56, 12))
        assert.are_same(vector(56, 12), pc.position)
      end)

      describe('(check_escape_from_ground returns false)', function ()

        local check_escape_from_ground_mock

        setup(function ()
          check_escape_from_ground_mock = stub(player_char, "check_escape_from_ground", function (self)
            return false
          end)
        end)

        teardown(function ()
          check_escape_from_ground_mock:revert()
        end)

        it('should call check_escape_from_ground and enter_motion_state(motion_states.falling)', function ()
          pc:spawn_at(vector(56, 12))

          -- implementation
          assert.spy(check_escape_from_ground_mock).was_called(1)
          assert.spy(check_escape_from_ground_mock).was_called_with(match.ref(pc))
        end)

      end)

      describe('(check_escape_from_ground returns true)', function ()

        local check_escape_from_ground_mock

        setup(function ()
          check_escape_from_ground_mock = stub(player_char, "check_escape_from_ground", function (self)
            return true
          end)
        end)

        teardown(function ()
          check_escape_from_ground_mock:revert()
        end)

        it('should call check_escape_from_ground', function ()
          pc:spawn_at(vector(56, 12))

          -- implementation
          assert.spy(check_escape_from_ground_mock).was_called(1)
          assert.spy(check_escape_from_ground_mock).was_called_with(match.ref(pc))
        end)

      end)

    end)

    describe('warp_bottom_to', function ()

      setup(function ()
        spy.on(player_char, "warp_to")
        stub(player_char, "get_center_height", function ()
          return 11
        end)
      end)

      teardown(function ()
        player_char.warp_to:revert()
        player_char.get_center_height:revert()
      end)

      it('should call warp_to with the position offset by -(character center height)', function ()
        pc:warp_bottom_to(vector(56, 12))
        assert.spy(player_char.warp_to).was_called(1)
        assert.spy(player_char.warp_to).was_called_with(match.ref(pc), vector(56, 12 - 11))
      end)

    end)

    describe('warp_to_emerald_by', function ()

      setup(function ()
        spy.on(player_char, "warp_to")
      end)

      teardown(function ()
        player_char.warp_to:revert()
      end)

      it('should do nothing if no emeralds have been spawned', function ()
        pc:warp_to_emerald_by(1)

        assert.spy(player_char.warp_to).was_not_called()
      end)

      describe('(with emeralds spawned)', function ()

        before_each(function ()
          player_char.warp_to:clear()

          flow.curr_state.spawned_emerald_locations = {
            location(1, 1),
            location(2, 2),
          }
        end)

        it('should call warp_to with the center position of the previous emerald', function ()
          pc.last_emerald_warp_nb = 2

          -- warp to previous one, so index 1
          pc:warp_to_emerald_by(-1)

          assert.spy(player_char.warp_to).was_called(1)
          assert.spy(player_char.warp_to).was_called_with(match.ref(pc), vector(12, 12))
        end)

        it('should call warp_to with the center position of the previous emerald (looped)', function ()
          pc.last_emerald_warp_nb = 1

          -- warp to previous one looped, so index 2
          pc:warp_to_emerald_by(-1)

          assert.spy(player_char.warp_to).was_called(1)
          assert.spy(player_char.warp_to).was_called_with(match.ref(pc), vector(20, 20))
        end)

        it('should call warp_to with the center position of the previous emerald (looped on start from 0)', function ()
          pc.last_emerald_warp_nb = 0

          -- warp to previous one looped, so index 2
          pc:warp_to_emerald_by(-1)

          assert.spy(player_char.warp_to).was_called(1)
          assert.spy(player_char.warp_to).was_called_with(match.ref(pc), vector(20, 20))
        end)

        it('should call warp_to with the center position of the next emerald', function ()
          pc.last_emerald_warp_nb = 1

          -- warp to next one looped, so index 2
          pc:warp_to_emerald_by(1)

          assert.spy(player_char.warp_to).was_called(1)
          assert.spy(player_char.warp_to).was_called_with(match.ref(pc), vector(20, 20))
        end)

        it('should call warp_to with the center position of the next emerald (looped)', function ()
          pc.last_emerald_warp_nb = 2

          -- warp to next one looped, so index 1
          pc:warp_to_emerald_by(1)

          assert.spy(player_char.warp_to).was_called(1)
          assert.spy(player_char.warp_to).was_called_with(match.ref(pc), vector(12, 12))
        end)

      end)

    end)

    describe('get_bottom_center', function ()

      setup(function ()
        stub(player_char, "get_center_height", function ()
          return 11
        end)
      end)

      teardown(function ()
        player_char.get_center_height:revert()
      end)

      it('(10, 0) => (10, center_height)', function ()
        pc.position = vector(10, 0)
        assert.are_same(vector(10, 11), pc:get_bottom_center())
      end)

      it('(10, 0) quadrant left => (10 - center_height, 0)', function ()
        pc.position = vector(10, 0)
        pc.quadrant = directions.left
        assert.are_same(vector(-1, 0), pc:get_bottom_center())
      end)

    end)

    describe('set_bottom_center', function ()

      setup(function ()
        stub(player_char, "get_center_height", function ()
          return 11
        end)
      end)

      teardown(function ()
        player_char.get_center_height:revert()
      end)

      it('set_bottom_center (10, center_height) => (10, 0)', function ()
        pc:set_bottom_center(vector(10, 11))
        assert.are_same(vector(10, 0), pc.position)
      end)

      it('set_bottom_center (10 + center_height, 0) quadrant right => (10, 0)', function ()
        pc.quadrant = directions.right
        pc:set_bottom_center(vector(10 + 11, 0))
        assert.are_same(vector(10, 0), pc.position)
      end)

    end)

    describe('set_slope_angle_with_quadrant', function ()

      -- slope angle

      it('should set slope_angle to passed angle even if nil', function ()
        pc.slope_angle = 0.5
        pc:set_slope_angle_with_quadrant(nil)
        assert.is_nil(pc.slope_angle)
      end)

      it('should set slope_angle to passed angle (not nil)', function ()
        pc.slope_angle = 0.5
        pc:set_slope_angle_with_quadrant(0.25)
        assert.are_equal(0.25, pc.slope_angle)
      end)

      -- sprite angle

      it('should not set sprite_angle if passed angle is nil', function ()
        pc.continuous_sprite_angle = 0.25
        pc:set_slope_angle_with_quadrant(nil)
        assert.are_equal(0.25, pc.continuous_sprite_angle)
      end)

      it('should set sprite_angle to angle if not nil', function ()
        pc.continuous_sprite_angle = 0.25
        pc:set_slope_angle_with_quadrant(0.75)
        assert.are_equal(0.75, pc.continuous_sprite_angle)
      end)

      it('should set sprite_angle to 0 when passing force_upward_sprite: true', function ()
        pc.continuous_sprite_angle = 0.25
        pc:set_slope_angle_with_quadrant(0.75, true)
        assert.are_equal(0, pc.continuous_sprite_angle)
      end)

      -- below also tests world.angle_to_quadrant implementation,
      --  because tests were written before function extraction

      it('should set quadrant to down for slope_angle: nil', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(nil)
        assert.are_equal(directions.down, pc.quadrant)
      end)

      it('should set quadrant to down for slope_angle: 1-0.125', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(1-0.125)
        assert.are_equal(directions.down, pc.quadrant)
      end)

      it('should set quadrant to down for slope_angle: 0', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(0)
        assert.are_equal(directions.down, pc.quadrant)
      end)

      it('should set quadrant to down for slope_angle: 0.125', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(0.125)
        assert.are_equal(directions.down, pc.quadrant)
      end)

      it('should set quadrant to right for slope_angle: 0.25-0.124', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(0.25-0.124)
        assert.are_equal(directions.right, pc.quadrant)
      end)

      it('should set quadrant to right for slope_angle: 0.25+0.124', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(0.25+0.124)
        assert.are_equal(directions.right, pc.quadrant)
      end)

      it('should set quadrant to up for slope_angle: 0.5-0.125', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(0.5-0.125)
        assert.are_equal(directions.up, pc.quadrant)
      end)

      it('should set quadrant to up for slope_angle: 0.5+0.125', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(0.5+0.125)
        assert.are_equal(directions.up, pc.quadrant)
      end)

      it('should set quadrant to left for slope_angle: 0.75-0.124', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(0.75-0.124)
        assert.are_equal(directions.left, pc.quadrant)
      end)

      it('should set quadrant to left for slope_angle: 0.75+0.124', function ()
        pc.quadrant = nil
        pc:set_slope_angle_with_quadrant(0.75+0.124)
        assert.are_equal(directions.left, pc.quadrant)
      end)

    end)

    describe('update', function ()

      setup(function ()
        stub(player_char, "handle_input")
        stub(player_char, "update_motion")
        stub(player_char, "update_anim")
        stub(animated_sprite, "update")
      end)

      teardown(function ()
        player_char.handle_input:revert()
        player_char.update_motion:revert()
        player_char.update_anim:revert()
        animated_sprite.update:revert()
      end)

      after_each(function ()
        player_char.handle_input:clear()
        player_char.update_motion:clear()
        player_char.update_anim:clear()
        animated_sprite.update:clear()
      end)

      it('should call _handle_input, _update_motion, _update_anim and update animated sprite', function ()
        pc:update()

        -- implementation
        assert.spy(pc.handle_input).was_called(1)
        assert.spy(pc.handle_input).was_called_with(match.ref(pc))
        assert.spy(pc.update_motion).was_called(1)
        assert.spy(pc.update_motion).was_called_with(match.ref(pc))
        assert.spy(pc.update_anim).was_called(1)
        assert.spy(pc.update_anim).was_called_with(match.ref(pc))
        assert.spy(animated_sprite.update).was_called(1)
        assert.spy(animated_sprite.update).was_called_with(match.ref(pc.anim_spr))
      end)

    end)


    describe('handle_input', function ()

      setup(function ()
        stub(player_char, "toggle_debug_motion")
      end)

      teardown(function ()
        player_char.toggle_debug_motion:revert()
      end)

      after_each(function ()
        input:init()

        player_char.toggle_debug_motion:clear()
      end)

      describe('(when player character control mode is not human)', function ()

        before_each(function ()
          pc.control_mode = control_modes.ai  -- or puppet
        end)

        it('should ignore inputs, and reset all intentions to 0/false', function ()
          pc.move_intention = vector(-1, 1)
          pc.jump_intention = true
          pc.hold_jump_intention = true
          input.players_btn_states[0][button_ids.left] = btn_states.pressed
          input.players_btn_states[0][button_ids.up] = btn_states.pressed

          pc:handle_input()

          assert.are_same({vector.zero(), false, false}, {pc.move_intention, pc.jump_intention, pc.hold_jump_intention})
        end)

      end)

      -- control mode is human by default

      it('(when input left in down) it should update the player character\'s move intention by (-1, 0)', function ()
        input.players_btn_states[0][button_ids.left] = btn_states.pressed
        pc:handle_input()
        assert.are_same(vector(-1, 0), pc.move_intention)
      end)

      it('(when input right in down) it should update the player character\'s move intention by (1, 0)', function ()
        input.players_btn_states[0][button_ids.right] = btn_states.just_pressed
        pc:handle_input()
        assert.are_same(vector(1, 0), pc.move_intention)
      end)

      it('(when input left and right are down) it should update the player character\'s move intention by (-1, 0)', function ()
        input.players_btn_states[0][button_ids.left] = btn_states.pressed
        input.players_btn_states[0][button_ids.right] = btn_states.just_pressed
        pc:handle_input()
        assert.are_same(vector(-1, 0), pc.move_intention)
      end)

      it('(when input left is down but horizontal control lock is active) it should not update the player character\'s move intention, and decrement the timer', function ()
        pc.horizontal_control_lock_timer = 3
        input.players_btn_states[0][button_ids.left] = btn_states.pressed
        input.players_btn_states[0][button_ids.right] = btn_states.just_pressed

        pc:handle_input()

        assert.are_same(vector(0, 0), pc.move_intention)
        assert.are_equal(2, pc.horizontal_control_lock_timer)
      end)

      it('(when input left is down with horizontal control lock active, but airborne) it should still update the player character\'s move intention, and also decrement the timer (unlike original game)', function ()
        pc.motion_state = motion_states.air_spin
        pc.horizontal_control_lock_timer = 3
        input.players_btn_states[0][button_ids.left] = btn_states.pressed
        input.players_btn_states[0][button_ids.right] = btn_states.just_pressed

        pc:handle_input()

        assert.are_same(vector(-1, 0), pc.move_intention)
        assert.are_equal(2, pc.horizontal_control_lock_timer)
      end)

       it('(when input up in down) it should update the player character\'s move intention by (-1, 0)', function ()
        input.players_btn_states[0][button_ids.up] = btn_states.pressed
        pc:handle_input()
        assert.are_same(vector(0, -1), pc.move_intention)
      end)

      it('(when input down in down) it should update the player character\'s move intention by (0, 1)', function ()
        input.players_btn_states[0][button_ids.down] = btn_states.pressed
        pc:handle_input()
        assert.are_same(vector(0, 1), pc.move_intention)
      end)

      it('(when input up and down are down) it should update the player character\'s move intention by (0, -1)', function ()
        input.players_btn_states[0][button_ids.up] = btn_states.just_pressed
        input.players_btn_states[0][button_ids.down] = btn_states.pressed
        pc:handle_input()
        assert.are_same(vector(0, -1), pc.move_intention)
      end)

      it('(when input left and up are down) it should update the player character\'s move intention by (-1, -1)', function ()
        input.players_btn_states[0][button_ids.left] = btn_states.just_pressed
        input.players_btn_states[0][button_ids.up] = btn_states.just_pressed
        pc:handle_input()
        assert.are_same(vector(-1, -1), pc.move_intention)
      end)

      it('(when input left and down are down) it should update the player character\'s move intention by (-1, 1)', function ()
        input.players_btn_states[0][button_ids.left] = btn_states.just_pressed
        input.players_btn_states[0][button_ids.down] = btn_states.just_pressed
        pc:handle_input()
        assert.are_same(vector(-1, 1), pc.move_intention)
      end)

      it('(when input right and up are down) it should update the player character\'s move intention by (1, -1)', function ()
        input.players_btn_states[0][button_ids.right] = btn_states.just_pressed
        input.players_btn_states[0][button_ids.up] = btn_states.just_pressed
        pc:handle_input()
        assert.are_same(vector(1, -1), pc.move_intention)
      end)

      it('(when input right and down are down) it should update the player character\'s move intention by (1, 1)', function ()
        input.players_btn_states[0][button_ids.right] = btn_states.just_pressed
        input.players_btn_states[0][button_ids.down] = btn_states.just_pressed
        pc:handle_input()
        assert.are_same(vector(1, 1), pc.move_intention)
      end)

      it('(when input o is released) it should update the player character\'s jump intention to false, hold jump intention to false', function ()
        pc:handle_input()
        assert.are_same({false, false}, {pc.jump_intention, pc.hold_jump_intention})
      end)

      it('(when input o is just pressed) it should update the player character\'s jump intention to true, hold jump intention to true', function ()
        input.players_btn_states[0][button_ids.o] = btn_states.just_pressed
        pc:handle_input()
        assert.are_same({true, true}, {pc.jump_intention, pc.hold_jump_intention})
      end)

      it('(when input o is pressed) it should update the player character\'s jump intention to false, hold jump intention to true', function ()
        input.players_btn_states[0][button_ids.o] = btn_states.pressed
        pc:handle_input()
        assert.are_same({false, true}, {pc.jump_intention, pc.hold_jump_intention})
      end)

      it('(when input x is pressed) it should call _toggle_debug_motion', function ()
        input.players_btn_states[0][button_ids.x] = btn_states.just_pressed

        pc:handle_input()

        -- implementation
        assert.spy(player_char.toggle_debug_motion).was_called(1)
        assert.spy(player_char.toggle_debug_motion).was_called_with(match.ref(pc))
      end)

    end)

    describe('force_move_right', function ()

      it('should set control mode to puppet with intention to move to the right', function ()
        pc.control_mode = control_modes.human

        pc:force_move_right()

        assert.are_same({control_modes.puppet, vector(1, 0), false, false},
          {pc.control_mode, pc.move_intention, pc.jump_intention, pc.hold_jump_intention})
      end)

    end)

    describe('toggle_debug_motion', function ()

      setup(function ()
        stub(player_char, "set_motion_mode")
      end)

      teardown(function ()
        player_char.set_motion_mode:revert()
      end)

      after_each(function ()
        input:init()

        player_char.set_motion_mode:clear()
      end)

      it('(motion mode is debug) it should toggle motion mode to platformer', function ()
        pc.motion_mode = motion_modes.platformer

        pc:toggle_debug_motion()

        -- implementation
        assert.spy(player_char.set_motion_mode).was_called(1)
        assert.spy(player_char.set_motion_mode).was_called_with(match.ref(pc), 2)
      end)

    end)

     describe('set_motion_mode', function ()

      setup(function ()
        -- don't stub, we need to check if the motion mode actually changed after toggle > spawn_at
        spy.on(player_char, "spawn_at")
      end)

      teardown(function ()
        player_char.spawn_at:revert()
      end)

      after_each(function ()
        input:init()

        player_char.spawn_at:clear()
      end)

      it('(to debug) should set motion mode to debug a and reset debug velocity', function ()
        pc.motion_mode = motion_modes.platformer
        pc.debug_velocity = vector(1, 2)

        pc:toggle_debug_motion()

        assert.are_equal(motion_modes.debug, pc.motion_mode)
        assert.are_same(vector.zero(), pc.debug_velocity)
      end)

      it('(to platformer) should set motion mode to platformer and respawn as current position', function ()
        local previous_position = pc.position  -- in case we change it during the spawn
        pc.motion_mode = motion_modes.debug

        pc:toggle_debug_motion()

        assert.are_equal(motion_modes.platformer, pc.motion_mode)

        assert.spy(pc.spawn_at).was_called(1)
        assert.spy(pc.spawn_at).was_called_with(match.ref(pc), previous_position)
      end)

    end)

    describe('update_motion', function ()

      setup(function ()
        player_char.update_collision_timer = stub(player_char, "update_collision_timer")
        player_char.update_platformer_motion = stub(player_char, "update_platformer_motion")
        player_char.update_debug = stub(player_char, "update_debug")
      end)

      teardown(function ()
        player_char.update_collision_timer:revert()
        player_char.update_platformer_motion:revert()
        player_char.update_debug:revert()
      end)

      after_each(function ()
        player_char.update_collision_timer:clear()
        player_char.update_platformer_motion:clear()
        player_char.update_debug:clear()
      end)

      it('should call update_collision_timer', function ()
        pc:update_motion()
        assert.spy(player_char.update_collision_timer).was_called()
        assert.spy(player_char.update_collision_timer).was_called_with(match.ref(pc))
      end)

      describe('(when motion mode is platformer)', function ()

        it('should call _update_platformer_motion', function ()
          pc:update_motion()
          assert.spy(player_char.update_platformer_motion).was_called(1)
          assert.spy(player_char.update_platformer_motion).was_called_with(match.ref(pc))
          assert.spy(player_char.update_debug).was_not_called()
        end)

      end)

      describe('(when motion mode is debug)', function ()

        before_each(function ()
          pc.motion_mode = motion_modes.debug
        end)

        -- bugfix history
        -- .
        -- * the test revealed a missing return, as _update_platformer_motion was called but shouldn't
        it('should call _update_debug', function ()
          pc:update_motion()
          assert.spy(player_char.update_platformer_motion).was_not_called()
          assert.spy(player_char.update_debug).was_called(1)
          assert.spy(player_char.update_debug).was_called_with(match.ref(pc))
        end)

      end)

    end)

    describe('(with mock tiles data setup)', function ()

      setup(function ()
        tile_test_data.setup()
      end)

      teardown(function ()
        tile_test_data.teardown()
      end)

      after_each(function ()
        pico8:clear_map()
      end)

      describe('set_ground_tile_location', function ()

        before_each(function ()
          -- add tiles usually placed at loop entrance/exit triggers
          -- but new system doesn't flag triggers, so remember to define loop areas manually
          -- ZR
          mock_mset(0, 0, tile_repr.visual_loop_toptopleft)
          mock_mset(1, 0, tile_repr.visual_loop_toptopright)

          -- customize loop areas locally. We are redefining a table so that won't affect
          --  the original data table in stage_data.lua. To simplify we don't redefine everything,
          --  but if we need to for the tests we'll just add the missing members
          flow.curr_state.curr_stage_data = {
            loop_exit_areas = {location_rect(-1, 0, 0, 2)},
            loop_entrance_areas = {location_rect(1, 0, 3, 4)}
          }
        end)

        it('should preserve ground tile location if current value is passed', function ()
          pc.ground_tile_location = location(0, 0)
          pc:set_ground_tile_location(location(0, 0))
          assert.are_same(location(0, 0), pc.ground_tile_location)
        end)

        it('should set ground tile location if different value is passed', function ()
          pc.ground_tile_location = location(0, 0)
          pc:set_ground_tile_location(location(1, 0))
          assert.are_same(location(1, 0), pc.ground_tile_location)
        end)

        it('should *not* set active_loop_layer if loop_entrance_trigger tile is detected, but didn\'t change', function ()
          pc.active_loop_layer = -1
          pc.ground_tile_location = location(0, 0)

          pc:set_ground_tile_location(location(0, 0))

          assert.are_equal(-1, pc.active_loop_layer)
        end)

        it('should set active_loop_layer to 1 if loop_entrance_trigger tile is detected and new', function ()
          -- just to check value change
          pc.active_loop_layer = -1
          pc.ground_tile_location = location(-1, 0)

          pc:set_ground_tile_location(location(1, 0))

          assert.are_equal(1, pc.active_loop_layer)
        end)

        it('should set active_loop_layer to 2 if loop_exit_trigger tile is detected and new', function ()
          -- just to check value change
          pc.active_loop_layer = -1
          pc.ground_tile_location = location(-1, 0)

          pc:set_ground_tile_location(location(0, 0))

          assert.are_equal(2, pc.active_loop_layer)
        end)

      end)

      describe('compute_ground_sensors_query_info', function ()

        -- interface tests are mostly redundant with compute_closest_query_info
        -- so we prefer implementation tests, checking that it calls the later with both sensor positions

        -- since adding ceiling adherence, this method really just calls compute_sensors_query_info,
        --  but it was simpler to keep existing tests than testing compute_sensors_query_info in isolation
        --  as we'd still need to create and pass a dummy callback
        -- we do however stub compute_closest_ground_query_info

        describe('with stubs', function ()

          local get_ground_sensor_position_from_mock
          local compute_signed_distance_to_closest_ground_mock

          local get_prioritized_dir_mock

          setup(function ()
            get_ground_sensor_position_from_mock = stub(player_char, "get_ground_sensor_position_from", function (self, center_position, i)
              return i == horizontal_dirs.left and vector(-1, center_position.y) or vector(1, center_position.y)
            end)

            compute_signed_distance_to_closest_ground_mock = stub(player_char, "compute_closest_ground_query_info", function (self, sensor_position)
              if sensor_position == vector(-1, 0) then
                return motion.ground_query_info(location(-1, 0), -4, 0.25)
              elseif sensor_position == vector(1, 0) then
                return motion.ground_query_info(location(0, 0), 5, -0.125)
              elseif sensor_position == vector(-1, 1) then
                return motion.ground_query_info(location(-1, 0), 7, -0.25)
              elseif sensor_position == vector(1, 1) then
                return motion.ground_query_info(location(0, 0), 6, 0.25)
              elseif sensor_position == vector(-1, 2) then
                return motion.ground_query_info(location(-1, 0), 3, 0)
              else  -- sensor_position == vector(1, 2)
                return motion.ground_query_info(location(0, 0), 3, 0.125)
              end
            end)
          end)

          teardown(function ()
            get_ground_sensor_position_from_mock:revert()
            compute_signed_distance_to_closest_ground_mock:revert()
          end)

          after_each(function ()
            get_ground_sensor_position_from_mock:clear()
            compute_signed_distance_to_closest_ground_mock:clear()
          end)

          it('should return ground_query_info with signed distance to closest ground from left sensor if the lowest', function ()
            -- -4 vs 5 => -4
            assert.are_same(motion.ground_query_info(location(-1, 0), -4, 0.25), pc:compute_ground_sensors_query_info(vector(0, 0)))
          end)

          it('should return ground_query_info with signed distance to closest ground from right sensor if the lowest', function ()
            -- 7 vs 6 => 6
            assert.are_same(motion.ground_query_info(location(0, 0), 6, 0.25), pc:compute_ground_sensors_query_info(vector(0, 1)))
          end)

          describe('(prioritized direction is left)', function ()

            setup(function ()
              get_prioritized_dir_mock = stub(player_char, "get_prioritized_dir", function (self)
                return horizontal_dirs.left
              end)
            end)

            teardown(function ()
              get_prioritized_dir_mock:revert()
            end)

            it('should return the signed distance to left ground if both sensors are at the same level', function ()
              -- 3 vs 3 => 3 left
              assert.are_same(motion.ground_query_info(location(-1, 0), 3, 0), pc:compute_ground_sensors_query_info(vector(0, 2)))
            end)

          end)

          describe('(prioritized direction is right)', function ()

            local get_prioritized_dir_mock

            setup(function ()
              get_prioritized_dir_mock = stub(player_char, "get_prioritized_dir", function (self)
                return horizontal_dirs.right
              end)
            end)

            teardown(function ()
              get_prioritized_dir_mock:revert()
            end)

            it('should return the signed distance to right ground if both sensors are at the same level', function ()
              -- 3 vs 3 => 3 right
              assert.are_same(motion.ground_query_info(location(0, 0), 3, 0.125), pc:compute_ground_sensors_query_info(vector(0, 2)))
            end)

          end)

        end)

      end)

      -- we should probably test compute_ceiling_sensors_query_info here, but since this one is a new function,
      --  we could just assert.spy the call for compute_sensors_query_info which is less interesting,
      --  while doing end-to-end test would mostly be a copy of compute_ground_sensors_query_info utests above
      --  but adapted for ceiling (which is already tested for compute_closest_ceiling_query_info)
      -- but feel free to add such tests if you still find issues with ceiling detection

      describe('get_prioritized_dir', function ()

        it('should return left when character is moving on ground toward left', function ()
          pc.ground_speed = -4
          assert.are_equal(horizontal_dirs.left, pc:get_prioritized_dir())
        end)

        it('should return right when character is moving on ground toward left', function ()
          pc.ground_speed = 4
          assert.are_equal(horizontal_dirs.right, pc:get_prioritized_dir())
        end)

        it('should return left when character is moving airborne toward left', function ()
          pc.motion_state = motion_states.falling  -- or any airborne state
          pc.velocity.x = -4
          assert.are_equal(horizontal_dirs.left, pc:get_prioritized_dir())
        end)

        it('should return right when character is moving airborne toward right', function ()
          pc.motion_state = motion_states.falling  -- or any airborne state
          pc.velocity.x = 4
          assert.are_equal(horizontal_dirs.right, pc:get_prioritized_dir())
        end)

        it('should return left when character is not moving and facing left', function ()
          pc.orientation = horizontal_dirs.left
          assert.are_equal(horizontal_dirs.left, pc:get_prioritized_dir())
        end)

        it('should return right when character is not moving and facing right', function ()
          pc.orientation = horizontal_dirs.right
          assert.are_equal(horizontal_dirs.right, pc:get_prioritized_dir())
        end)

      end)

      describe('get_ground_sensor_position_from', function ()

        setup(function ()
          stub(player_char, "get_center_height", function ()
            return 11
          end)
        end)

        teardown(function ()
          player_char.get_center_height:revert()
        end)

        it('should return the position down-left of the character center when horizontal dir is left', function ()
          assert.are_same(vector(7, 10 + 11), pc:get_ground_sensor_position_from(vector(10, 10), horizontal_dirs.left))
        end)

        it('should return the position down-left of the x-floored character center when horizontal dir is left', function ()
          assert.are_same(vector(7, 10 + 11), pc:get_ground_sensor_position_from(vector(10.9, 10), horizontal_dirs.left))
        end)

        it('should return the position down-left of the character center when horizontal dir is right', function ()
          assert.are_same(vector(12, 10 + 11), pc:get_ground_sensor_position_from(vector(10, 10), horizontal_dirs.right))
        end)

        it('should return the position down-left of the x-floored character center when horizontal dir is right', function ()
          assert.are_same(vector(12, 10 + 11), pc:get_ground_sensor_position_from(vector(10.9, 10), horizontal_dirs.right))
        end)

        -- for other quadrants, just check the more complex case of coords with fractions

        it('(right wall) should return the position q-down-left of the x-floored character center when horizontal dir is left', function ()
          pc.quadrant = directions.right
          assert.are_same(vector(10 + 11, 12), pc:get_ground_sensor_position_from(vector(10, 10.9), horizontal_dirs.left))
        end)

        it('(right wall) should return the position q-down-left of the x-floored character center when horizontal dir is right', function ()
          pc.quadrant = directions.right
          assert.are_same(vector(10 + 11, 7), pc:get_ground_sensor_position_from(vector(10, 10.9), horizontal_dirs.right))
        end)

        it('(ceiling) should return the position q-down-left of the x-floored character center when horizontal dir is left', function ()
          pc.quadrant = directions.up
          assert.are_same(vector(12, 10 - 11), pc:get_ground_sensor_position_from(vector(10.9, 10), horizontal_dirs.left))
        end)

        it('(ceiling) should return the position q-down-left of the x-floored character center when horizontal dir is right', function ()
          pc.quadrant = directions.up
          assert.are_same(vector(7, 10 - 11), pc:get_ground_sensor_position_from(vector(10.9, 10), horizontal_dirs.right))
        end)

        it('(left wall) should return the position q-down-left of the x-floored character center when horizontal dir is left', function ()
          pc.quadrant = directions.left
          assert.are_same(vector(10 - 11, 7), pc:get_ground_sensor_position_from(vector(10, 10.9), horizontal_dirs.left))
        end)

        it('(left wall) should return the position q-down-left of the x-floored character center when horizontal dir is right', function ()
          pc.quadrant = directions.left
          assert.are_same(vector(10 -11, 12), pc:get_ground_sensor_position_from(vector(10, 10.9), horizontal_dirs.right))
        end)

      end)

      describe('compute_closest_ground_query_info', function ()

        describe('with full flat tile', function ()

          before_each(function ()
            -- create a full tile at (1, 1), i.e. (8, 8) to (15, 15) px
            mock_mset(1, 1, tile_repr.full_tile_id)
          end)

          -- on the sides

          it('should return ground_query_info(nil, max_ground_snap_height+1, nil) if just at ground height but slightly on the left', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height+1, nil), pc:compute_closest_ground_query_info(vector(7, 8)))
          end)

          it('should return ground_query_info(nil, max_ground_snap_height+1, nil) if just at ground height but slightly on the right', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height+1, nil), pc:compute_closest_ground_query_info(vector(16, 8)))
          end)

          -- above

          it('should return ground_query_info(nil, max_ground_snap_height+1, nil) if above the tile by max_ground_snap_height+2)', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height+1, nil), pc:compute_closest_ground_query_info(vector(12, 8 - (pc_data.max_ground_snap_height + 2))))
          end)

          it('should return ground_query_info(location(1, 1), max_ground_snap_height, 0) if above the tile by max_ground_snap_height', function ()
            assert.are_same(ground_query_info(location(1, 1), pc_data.max_ground_snap_height, 0), pc:compute_closest_ground_query_info(vector(12, 8 - pc_data.max_ground_snap_height)))
          end)

          it('should return ground_query_info(location(1, 1), , 0.0625, 0) if just a above the tile by 0.0625 (<= max_ground_snap_height)', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 0), pc:compute_closest_ground_query_info(vector(12, 8 - 0.0625)))
          end)

          -- on top

          it('should return ground_query_info(location(1, 1), 0, 0) if just at the top of the topleft-most pixel of the tile', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 0), pc:compute_closest_ground_query_info(vector(8, 8)))
          end)

          it('should return ground_query_info(location(1, 1), 0, 0) if just at the top of tile, in the middle', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 0), pc:compute_closest_ground_query_info(vector(12, 8)))
          end)

          it('should return ground_query_info(location(1, 1), 0, 0) if just at the top of the right-most pixel', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 0), pc:compute_closest_ground_query_info(vector(15, 8)))
          end)

          -- just below the top

          it('should return ground_query_info(location(1, 1), -0.0625, 0) if 0.0625 inside the top-left pixel', function ()
            assert.are_same(ground_query_info(location(1, 1), -0.0625, 0), pc:compute_closest_ground_query_info(vector(8, 8 + 0.0625)))
          end)

          it('should return ground_query_info(location(1, 1), -0.0625, 0) if 0.0625 inside the top-right pixel', function ()
            assert.are_same(ground_query_info(location(1, 1), -0.0625, 0), pc:compute_closest_ground_query_info(vector(15, 8 + 0.0625)))
          end)

          -- going deeper

          it('should return ground_query_info(location(1, 1), -1.5, 0) if 1.5 (<= max_ground_escape_height) inside vertically', function ()
            assert.are_same(ground_query_info(location(1, 1), -1.5, 0), pc:compute_closest_ground_query_info(vector(12, 8 + 1.5)))
          end)

          it('should return ground_query_info(location(1, 1), -max_ground_escape_height, 0) if max_ground_escape_height inside', function ()
            assert.are_same(ground_query_info(location(1, 1), -pc_data.max_ground_escape_height, 0), pc:compute_closest_ground_query_info(vector(15, 8 + pc_data.max_ground_escape_height)))
          end)

          it('should return ground_query_info(nil, -max_ground_escape_height - 1, 0) if max_ground_escape_height + 2 inside', function ()
            assert.are_same(ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(15, 8 + pc_data.max_ground_escape_height + 2)))
          end)

          -- beyond the tile, still detecting it until step up is reached, including the +1 up to detect a wall (step up too high)

          it('should return ground_query_info(nil, - max_ground_escape_height - 1, 0) if max_ground_escape_height below the bottom', function ()
            -- we really check 1 extra px above max_ground_escape_height, so even that far from the ground above we still see it as a step too high, not ceiling
            assert.are_same(ground_query_info(nil, - pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(15, 16 + pc_data.max_ground_escape_height)))
          end)

          it('should return ground_query_info(nil, -max_ground_escape_height - 1, 0) (clamped) if max_ground_escape_height - 1 below the bottom', function ()
            assert.are_same(ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(15, 16 + pc_data.max_ground_escape_height - 1)))
          end)

          -- step up distance reached, character considered in the air

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if max_ground_escape_height + 1 below the bottom', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(15, 16 + pc_data.max_ground_escape_height + 1)))
          end)

          -- other quadrants (only the trickiest cases)

          -- right wall

          it('(right wall) should return ground_query_info(nil, max_ground_snap_height + 1, nil) if too far from the wall', function ()
            pc.quadrant = directions.right

            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(0, 12)))
          end)

          it('(right wall) should return ground_query_info(location(1, 1), 2, 0.25) if 2 pixels from the wall', function ()
            pc.quadrant = directions.right

            assert.are_same(ground_query_info(location(1, 1), 2, 0.25), pc:compute_closest_ground_query_info(vector(6, 12)))
          end)

          it('(right wall) should return ground_query_info(location(1, 1), -2, 0.25) if 2 pixels inside the wall', function ()
            pc.quadrant = directions.right

            assert.are_same(ground_query_info(location(1, 1), -2, 0.25), pc:compute_closest_ground_query_info(vector(10, 12)))
          end)

          it('(right wall) should return ground_query_info(nil, -max_ground_escape_height - 1, 0) if too far inside the wall', function ()
            pc.quadrant = directions.right

            assert.are_same(ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(14, 12)))
          end)

          -- ceiling

          it('(ceiling) should return ground_query_info(nil, max_ground_snap_height + 1, nil) if too far from the wall', function ()
            pc.quadrant = directions.up

            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(12, 24)))
          end)

          it('(ceiling) should return ground_query_info(location(1, 1), 2, 0.5) if 2 pixels from the wall', function ()
            pc.quadrant = directions.up

            assert.are_same(ground_query_info(location(1, 1), 2, 0.5), pc:compute_closest_ground_query_info(vector(12, 18)))
          end)

          it('(ceiling) should return ground_query_info(location(1, 1), -2, 0.5) if 2 pixels inside the wall', function ()
            pc.quadrant = directions.up

            assert.are_same(ground_query_info(location(1, 1), -2, 0.5), pc:compute_closest_ground_query_info(vector(12, 14)))
          end)

          it('(ceiling) should return ground_query_info(nil, -max_ground_escape_height - 1, 0) if too far inside the wall', function ()
            pc.quadrant = directions.up

            assert.are_same(ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(12, 8)))
          end)

          -- left wall

          it('(left wall) should return ground_query_info(nil, max_ground_snap_height + 1, nil) if too far from the wall', function ()
            pc.quadrant = directions.left

            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(24, 12)))
          end)

          it('(left wall) should return ground_query_info(location(1, 1), 2, 0.75) if 2 pixels from the wall', function ()
            pc.quadrant = directions.left

            assert.are_same(ground_query_info(location(1, 1), 2, 0.75), pc:compute_closest_ground_query_info(vector(18, 12)))
          end)

          it('(left wall) should return ground_query_info(location(1, 1), -2, 0.75) if 2 pixels inside the wall', function ()
            pc.quadrant = directions.left

            assert.are_same(ground_query_info(location(1, 1), -2, 0.75), pc:compute_closest_ground_query_info(vector(14, 12)))
          end)

          it('(left wall) should return ground_query_info(nil, -max_ground_escape_height - 1, 0) if too far inside the wall', function ()
            pc.quadrant = directions.left

            assert.are_same(ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(10, 12)))
          end)

          -- #debug_character below

          it('(#debug_character) should add debug ray (no hit, no_collider_callback) for later draw (for query info ground_query_info(nil, max_ground_snap_height+1, nil) as above tile by max_ground_snap_height+2)', function ()
            pc.quadrant = directions.down
            pc:compute_closest_ground_query_info(vector(12, 8 - (pc_data.max_ground_snap_height + 2)))

            assert.are_same({{
              start = vector(12, 8 - (pc_data.max_ground_snap_height + 2)),
              direction = vector(0, 1),  -- unit down
              distance = pc_data.max_ground_escape_height + 1,
              hit = false
            }}, pc.debug_rays)
          end)

          it('(#debug_character) should add debug ray (hit, inside) for later draw (for query info ground_query_info(location(1, 1), 2, 0.25) as 2px from the right wall)', function ()
            pc.quadrant = directions.right
            pc:compute_closest_ground_query_info(vector(6, 12))

            assert.are_same({{
              start = vector(6, 12),
              direction = vector(1, 0),  -- unit right
              distance = 2,
              hit = true
            }}, pc.debug_rays)
          end)

        end)

        describe('with one-way tile', function ()

          before_each(function ()
            mock_mset(1, 1, tile_repr.oneway_platform_left)
          end)

          -- QUADRANT DOWN

          -- above

          it('should return ground_query_info(location(1, 1), max_ground_snap_height, 0) if above the tile by max_ground_snap_height', function ()
            assert.are_same(ground_query_info(location(1, 1), pc_data.max_ground_snap_height, 0), pc:compute_closest_ground_query_info(vector(12, 8 - pc_data.max_ground_snap_height)))
          end)

          -- on top

          it('should return ground_query_info(location(1, 1), 0, 0) if just at the top of tile, in the middle', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 0), pc:compute_closest_ground_query_info(vector(12, 8)))
          end)

          -- just below the top by up to 1px (still recognize ground to allow step up on low one-way slopes)

          it('should return ground_query_info(location(1, 1), -0.0625, 0) if 0.0625 inside the top-left pixel', function ()
            assert.are_same(ground_query_info(location(1, 1), -0.0625, 0), pc:compute_closest_ground_query_info(vector(8, 8 + 0.0625)))
          end)

          it('should return ground_query_info(location(1, 1), -1, 0) if 1 (<= max_ground_escape_height) inside vertically', function ()
            assert.are_same(ground_query_info(location(1, 1), -1, 0), pc:compute_closest_ground_query_info(vector(12, 8 + 1)))
          end)

          -- below the top by more than 1px (ignoring it)

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if 1.1 (<= max_ground_escape_height) inside vertically', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(12, 8 + 1.1)))
          end)

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if 3 (<= max_ground_escape_height) inside vertically', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(12, 8 + 3)))
          end)

          -- below by more than step up distance (still ignoring it)

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if max_ground_escape_height + 1 below the bottom', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(15, 16 + pc_data.max_ground_escape_height + 1)))
          end)

          -- QUADRANT RIGHT (always ignore)

          it('(right wall) should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) if 2 pixels from the left (not relevant)', function ()
            pc.quadrant = directions.right

            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(6, 12)))
          end)

          -- QUADRANT UP (always ignore)

          it('(ceiling) should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) if 2 pixels below the surface', function ()
            pc.quadrant = directions.up

            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(12, 10)))
          end)

          -- QUADRANT LEFT (always ignore)

          it('(left wall) should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) if 2 pixels from the surface right (not relevant)', function ()
            pc.quadrant = directions.left

            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(18, 12)))
          end)

        end)

        describe('with 2 full flat tiles', function ()

          before_each(function ()
            mock_mset(0, 0, tile_repr.full_tile_id)
            mock_mset(0, 1, tile_repr.full_tile_id)
          end)

          -- test below verifies that I check 1 extra px above max_ground_escape_height (see snap_zone_qtop definition)
          --  even if it reaches another tile, so I don't think it's over and escape
          --  the current tile because current column is just at max_ground_escape_height,
          --  only to land inside the tile above

          it('should return ground_query_info(nil, -max_ground_escape_height - 1, 0) if max_ground_escape_height + 1 inside, including max_ground_escape_height in current tile', function ()
            assert.are_same(ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(4, 8 + pc_data.max_ground_escape_height)))
          end)

        end)

        describe('with half flat tile', function ()

          before_each(function ()
            -- create a half-tile at (1, 1), top-left at (8, 12), top-right at (15, 16) included
            mock_mset(1, 1, tile_repr.half_tile_id)
          end)

          -- just above

          it('should return 0.0625, 0 if just a little above the tile', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 0), pc:compute_closest_ground_query_info(vector(12, 12 - 0.0625)))
          end)

          -- on top

          it('+ should return ground_query_info(nil, max_ground_snap_height + 1, nil) if just touching the left of the tile at the ground\'s height', function ()
            -- right ground sensor @ (7.5, 12)
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(7, 12)))
          end)

          it('should return 0, 0 if just at the top of the topleft-most pixel of the tile', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 0), pc:compute_closest_ground_query_info(vector(8, 12)))
          end)

          it('should return 0, 0 if just at the top of tile, in the middle', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 0), pc:compute_closest_ground_query_info(vector(12, 12)))
          end)

          it('should return 0, 0 if just at the top of the right-most pixel', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 0), pc:compute_closest_ground_query_info(vector(15, 12)))
          end)

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if in the air on the right of the tile', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(16, 12)))
          end)

          -- just inside the top

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if just on the left of the topleft pixel, y at 0.0625 below the top', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(7, 12 + 0.0625)))
          end)

          it('should return -0.0625, 0 if 0.0625 inside the topleft pixel', function ()
            assert.are_same(ground_query_info(location(1, 1), -0.0625, 0), pc:compute_closest_ground_query_info(vector(8, 12 + 0.0625)))
          end)

          it('should return -0.0625, 0 if 0.0625 inside the topright pixel', function ()
            assert.are_same(ground_query_info(location(1, 1), -0.0625, 0), pc:compute_closest_ground_query_info(vector(15, 12 + 0.0625)))
          end)

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if just on the right of the topright pixel, y at 0.0625 below the top', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(16, 12 + 0.0625)))
          end)

          -- just inside the bottom

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if just on the left of the topleft pixel, y at 0.0625 above the bottom', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(7, 16 - 0.0625)))
          end)

          it('should return -(4 - 0.0625), 0 if 0.0625 inside the topleft pixel', function ()
            assert.are_same(ground_query_info(location(1, 1), -(4 - 0.0625), 0), pc:compute_closest_ground_query_info(vector(8, 16 - 0.0625)))
          end)

          it('should return -(4 - 0.0625), 0 if 0.0625 inside the topright pixel', function ()
            assert.are_same(ground_query_info(location(1, 1), -(4 - 0.0625), 0), pc:compute_closest_ground_query_info(vector(15, 16 - 0.0625)))
          end)

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if just on the right of the topright pixel, y at 0.0625 above the bottom', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(16, 16 - 0.0625)))
          end)

          -- beyond the tile, still detecting it until step up is reached, including the +1 up to detect a wall (step up too high)

          it('should return ground_query_info(nil, -max_ground_escape_height - 1, 0) if max_ground_escape_height - 1 below the bottom', function ()
            assert.are_same(ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(15, 16 + pc_data.max_ground_escape_height - 1)))
          end)

          it('should return ground_query_info(nil, -max_ground_escape_height - 1, 0) if max_ground_escape_height below the bottom', function ()
            assert.are_same(ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(15, 16 + pc_data.max_ground_escape_height)))
          end)

          -- step up distance reached, character considered in the air

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if max_ground_snap_height + 1 below the bottom', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_escape_height + 1, nil), pc:compute_closest_ground_query_info(vector(15, 16 + pc_data.max_ground_escape_height + 1)))
          end)

        end)

        describe('with ascending slope 45', function ()

          before_each(function ()
            -- create an ascending slope at (1, 1), i.e. (8, 15) to (15, 8) px
            mock_mset(1, 1, tile_repr.asc_slope_45_id)
          end)

          it('should return ground_query_info(location(1, 1), 0.0625, 45/360) if just above slope column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 45/360), pc:compute_closest_ground_query_info(vector(8, 15 - 0.0625)))
          end)

          it('should return ground_query_info(location(1, 1), 0, 45/360) if at the top of column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 45/360), pc:compute_closest_ground_query_info(vector(8, 15)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) if 7px above column 0, i.e. at top-most pixel of the ascending slope tile', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(8, 8)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) if 8px above column 0, i.e. at bottom-most pixel of tile just above the ascending slope tile', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(8, 7)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) if 15px above column 0, i.e. at top-most pixel of tile just above the ascending slope tile', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(8, 0)))
          end)

          it('should return ground_query_info(location(1, 1), 0.0625, 45/360) if just above slope column 4', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 45/360), pc:compute_closest_ground_query_info(vector(12, 11 - 0.0625)))
          end)

          it('should return ground_query_info(location(1, 1), 0, 45/360) if at the top of column 4', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 45/360), pc:compute_closest_ground_query_info(vector(12, 11)))
          end)

          it('should return ground_query_info(location(1, 1), -2, 45/360) if 2px below column 4', function ()
            assert.are_same(ground_query_info(location(1, 1), -2, 45/360), pc:compute_closest_ground_query_info(vector(12, 13)))
          end)

          it('should return ground_query_info(location(1, 1), 0.0625, 45/360) if right sensor is just above slope column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 45/360), pc:compute_closest_ground_query_info(vector(15, 8 - 0.0625)))
          end)

          it('should return ground_query_info(location(1, 1), 0, 45/360) if right sensor is at the top of column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 45/360), pc:compute_closest_ground_query_info(vector(15, 8)))
          end)

          it('should return ground_query_info(location(1, 1), -3, 45/360) if 3px below column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), -3, 45/360), pc:compute_closest_ground_query_info(vector(15, 11)))
          end)

          it('. should return ground_query_info(location(1, 1), 0.0625, 45/360) if just above slope column 3', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 45/360), pc:compute_closest_ground_query_info(vector(11, 12 - 0.0625)))
          end)

          it('. should return ground_query_info(location(1, 1), 0, 45/360) if at the top of column 3', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 45/360), pc:compute_closest_ground_query_info(vector(11, 12)))
          end)

          -- beyond the tile, still detecting it until step up is reached, including the +1 up to detect a wall (step up too high)

          it('should return ground_query_info(location(1, 1), -4, 45/360) if 4 (<= max_ground_escape_height) below the 2nd column top', function ()
            assert.are_same(ground_query_info(location(1, 1), -4, 45/360), pc:compute_closest_ground_query_info(vector(9, 16 + 2)))
          end)

          it('should return ground_query_info(location(1, 1), -(max_ground_escape_height - 1), 45/360) if max_ground_escape_height - 1 below the top of column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), -(pc_data.max_ground_escape_height - 1), 45/360), pc:compute_closest_ground_query_info(vector(8, 15 + pc_data.max_ground_escape_height - 1)))
          end)

          it('should return ground_query_info(location(1, 1), -max_ground_escape_height, 45/360) if max_ground_escape_height below the top of column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), -pc_data.max_ground_escape_height, 45/360), pc:compute_closest_ground_query_info(vector(8, 15 + pc_data.max_ground_escape_height)))
          end)

          -- step up distance reached, character considered in the air

          it('should return ground_query_info(nil, -max_ground_escape_height - 1, 0) if max_ground_escape_height + 1 below the top of column 0 but only max_ground_snap_height below the bottom of column 0 (of the tile)', function ()
            assert.are_same(ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0), pc:compute_closest_ground_query_info(vector(8, 15 + pc_data.max_ground_escape_height + 1)))
          end)

        end)

        describe('with descending slope 45', function ()

          before_each(function ()
            -- create a descending slope at (1, 1), i.e. (8, 8) to (15, 15) px
            mock_mset(1, 1, tile_repr.desc_slope_45_id)
          end)

          it('should return ground_query_info(location(1, 1), 0.0625, 1-45/360) if right sensors are just a little above column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 1-45/360), pc:compute_closest_ground_query_info(vector(8, 8 - 0.0625)))
          end)

          it('should return ground_query_info(location(1, 1), 0, 1-45/360) if right sensors is at the top of column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 1-45/360), pc:compute_closest_ground_query_info(vector(8, 8)))
          end)

          it('should return ground_query_info(location(1, 1), -1, 1-45/360) if right sensors is below column 0 by 1px', function ()
            assert.are_same(ground_query_info(location(1, 1), -1, 1-45/360), pc:compute_closest_ground_query_info(vector(8, 9)))
          end)

          it('should return ground_query_info(location(1, 1), 1, 1-45/360) if 1px above slope column 1', function ()
            assert.are_same(ground_query_info(location(1, 1), 1, 1-45/360), pc:compute_closest_ground_query_info(vector(9, 8)))
          end)

          it('should return ground_query_info(location(1, 1), 0, 1-45/360) if at the top of column 1', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 1-45/360), pc:compute_closest_ground_query_info(vector(9, 9)))
          end)

          it('should return ground_query_info(location(1, 1), -2, 1-45/360) if 2px below column 1', function ()
            assert.are_same(ground_query_info(location(1, 1), -2, 1-45/360), pc:compute_closest_ground_query_info(vector(9, 11)))
          end)

          it('should return ground_query_info(location(1, 1), 0.0625, 1-45/360) if just above slope column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 1-45/360), pc:compute_closest_ground_query_info(vector(8, 8 - 0.0625)))
          end)

          it('should return ground_query_info(location(1, 1), 0, 1-45/360) if at the top of column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 1-45/360), pc:compute_closest_ground_query_info(vector(8, 8)))
          end)

          it('should return ground_query_info(location(1, 1), -3, 1-45/360) if 3px below column 0', function ()
            assert.are_same(ground_query_info(location(1, 1), -3, 1-45/360), pc:compute_closest_ground_query_info(vector(8, 11)))
          end)

          it('. should returground_query_info(location(1, 1), 0.0625, 1-45/360) if just above slope column 3', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 1-45/360), pc:compute_closest_ground_query_info(vector(11, 11 - 0.0625)))
          end)

          it('. should returground_query_info(location(1, 1), 0, 1-45/360) if at the top of column 3', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 1-45/360), pc:compute_closest_ground_query_info(vector(11, 11)))
          end)

          it('should return ground_query_info(location(1, 1), -4, 1-45/360) if 4px below column 3', function ()
            assert.are_same(ground_query_info(location(1, 1), -4, 1-45/360), pc:compute_closest_ground_query_info(vector(11, 15)))
          end)

          it('should return ground_query_info(location(1, 1), 0.0625, 1-45/360) if just above slope column 7', function ()
            assert.are_same(ground_query_info(location(1, 1), 0.0625, 1-45/360), pc:compute_closest_ground_query_info(vector(15, 15 - 0.0625)))
          end)

          it('should return ground_query_info(location(1, 1), 0, 1-45/360) at the top of column 7', function ()
            assert.are_same(ground_query_info(location(1, 1), 0, 1-45/360), pc:compute_closest_ground_query_info(vector(15, 15)))
          end)

        end)

        describe('with ascending slope 22.5 offset by 2', function ()

          before_each(function ()
            -- create an ascending slope 22.5 at (1, 1), i.e. (8, 14) to (15, 11) px
            mock_mset(1, 1, tile_repr.asc_slope_22_id)
          end)

          it('should return -4, 22.5/360 if below column 7 by 4px)', function ()
            assert.are_same(ground_query_info(location(1, 1), -4, 22.5/360), pc:compute_closest_ground_query_info(vector(14, 15)))
          end)

        end)

        -- this test case was added because we noticed that all slopes behaved like full tiles in PICO-8
        -- so we created the half-tile itest which demonstrated the issue, and even in busted
        --  where character fell 1 px above ground instead of 4 px, but still
        -- fixing this should solve the itest for busted, even if not necessarily for PICO-8

        describe('with half-tile', function ()

          before_each(function ()
            -- .
            -- =
            mock_mset(0, 1, tile_repr.half_tile_id)
          end)

          it('should return ground_query_info(location(0, 1), 1, 0) when 1px above the half-tile', function ()
            assert.are_same(ground_query_info(location(0, 1), 1, 0), pc:compute_closest_ground_query_info(vector(4, 11)))
          end)

          it('should return ground_query_info(location(0, 1), 0, 0) when just on top of half-tile', function ()
            assert.are_same(ground_query_info(location(0, 1), 0, 0), pc:compute_closest_ground_query_info(vector(4, 12)))
          end)

        end)

        describe('with quarter-tile', function ()

          before_each(function ()
            -- create a quarter-tile at (1, 1), i.e. (12, 12) to (15, 15) px
            -- note that the quarter-tile is made of 2 subtiles of slope 0, hence overall slope is considered 0, not an average slope between min and max height
            mock_mset(1, 1, tile_repr.bottom_right_quarter_tile_id)
          end)

          it('should return ground_query_info(nil, max_ground_snap_height + 1, nil) if just at the bottom of the tile, on the left part, so in the air (and not 0 just because it is at height 0)', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(11, 16)))
          end)

          it('should return -2, 0 if below tile by 2px', function ()
            assert.are_same(ground_query_info(location(1, 1), -2, 0), pc:compute_closest_ground_query_info(vector(14, 14)))
          end)

        end)

        describe('with low tile stacked on full tile', function ()

          before_each(function ()
            -- create a low-tile at (1, 1) and full tile at (1, 2) for a total (8, 14) to (15, 23) px

            -- 00000000  8
            -- 00000000
            -- 00000000
            -- 00000000
            -- 00000000
            -- 00000000
            -- 11111111
            -- 11111111
            -- 11111111  16
            -- 11111111
            -- 11111111
            -- 11111111
            -- 11111111
            -- 11111111
            -- 11111111
            -- 11111111  23

            mock_mset(1, 1, tile_repr.flat_low_tile_id)
            mock_mset(1, 2, tile_repr.full_tile_id)
          end)

          it('should return -4, 0 if below top by 4px, with character crossing 2 tiles', function ()
            -- interface
            assert.are_same(ground_query_info(location(1, 1), -4, 0), pc:compute_closest_ground_query_info(vector(12, 18)))
          end)

        end)

        describe('with bottom/side loop tile', function ()

          before_each(function ()
            -- place loop tiles, but remember the loop areas give them meaning
            mock_mset(0, 0, tile_repr.visual_loop_bottomleft)
            mock_mset(1, 0, tile_repr.visual_loop_bottomright)

            -- customize loop areas locally. We are redefining a table so that won't affect
            --  the original data table in stage_data.lua. To simplify we don't redefine everything,
            --  but if we need to for the tests we'll just add the missing members
            flow.curr_state.curr_stage_data = {
              -- a bit tight honestly because I placed to corners too close to each other, but
              --  can get away with narrow rectangles; as long as the trigger corners are not at
              --  the bottom
              loop_exit_areas = {location_rect(0, -3, 0, 0)},
              loop_entrance_areas = {location_rect(1, -3, 1, 0)}
            }
          end)

          it('(entrance active) position on exit should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) as if there were nothing', function ()
            pc.active_loop_layer = 1
            -- interface
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(4, 4)))
          end)

          it('(entrance active) position on entrance should return actual ground_query_info() as entrance is solid', function ()
            pc.active_loop_layer = 1
            -- interface
            assert.are_same(ground_query_info(location(1, 0), -2, atan2(8, -5)), pc:compute_closest_ground_query_info(vector(12, 4)))
          end)

          it('(exit active) position on exit should return actual ground_query_info() as exit is solid', function ()
            pc.active_loop_layer = 2
            -- interface
            -- slight dissymetry due to pixel coord being considered at the top left... so we are 2px inside the step at 3, not 4
            assert.are_same(ground_query_info(location(0, 0), -2, atan2(8, 5)), pc:compute_closest_ground_query_info(vector(3, 4)))
          end)

          it('(exit active) position on entrance should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) as if there were nothing', function ()
            pc.active_loop_layer = 2
            -- interface
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(12, 4)))
          end)

        end)

        describe('with ramp tile', function ()

          before_each(function ()
            mock_mset(0, 0, visual.launch_ramp_last_tile_id)
          end)

          it('(not ignoring ramp) position on ramp should return actual ground_query_info() as it would be detected', function ()
            pc.ignore_launch_ramp_timer = 0
            -- same shape as tile_repr.visual_loop_bottomright, so expect same signed distance
            assert.are_same(ground_query_info(location(0, 0), 0, atan2(8, -5)), pc:compute_closest_ground_query_info(vector(4, 2)))
          end)

          it('(ignoring ramp) position below ramp by more than 1px should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) because it is one-way', function ()
            pc.ignore_launch_ramp_timer = 0
            -- same shape as tile_repr.visual_loop_bottomright, so expect same signed distance
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(4, 4)))
          end)

          it('(ignoring ramp) position on entrance should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) as if there were nothing', function ()
            pc.ignore_launch_ramp_timer = 1
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ground_query_info(vector(4, 4)))
          end)

        end)

      end)

      describe('check_escape_from_ground', function ()

        setup(function ()
          spy.on(player_char, "set_slope_angle_with_quadrant")  -- spy not stub in case the resulting slope_angle/quadrant matters
          -- trigger check inside set_ground_tile_location will fail as it needs context
          -- (tile_test_data + mset), so we prefer stubbing as we don't check ground_tile_location directly
          spy.on(player_char, "set_ground_tile_location")
          spy.on(player_char, "enter_motion_state")
        end)

        teardown(function ()
          player_char.set_slope_angle_with_quadrant:revert()
          player_char.set_ground_tile_location:revert()
          player_char.enter_motion_state:revert()
        end)

        after_each(function ()
          player_char.set_slope_angle_with_quadrant:clear()
          player_char.set_ground_tile_location:clear()
          player_char.enter_motion_state:clear()
        end)

        describe('with full flat tile', function ()

          before_each(function ()
            -- create a full tile at (1, 1), i.e. (8, 8) to (15, 15) px
            mock_mset(1, 1, tile_repr.full_tile_id)
          end)

          it('should reset state vars to airborne convention when character is not touching ground at all, and enter state falling', function ()
            pc:set_bottom_center(vector(12, 6))
            pc:check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 6), nil}, {pc:get_bottom_center(), pc.ground_tile_location})

            assert.spy(player_char.enter_motion_state).was_called(1)
            assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.falling)
          end)

          it('should do nothing when character is just on top of the ground, update slope to 0 and enter state standing', function ()
            pc:set_bottom_center(vector(12, 8))
            pc:check_escape_from_ground()

            -- interface
            assert.are_same(vector(12, 8), pc:get_bottom_center())

            assert.spy(player_char.set_ground_tile_location).was_called(1)
            assert.spy(player_char.set_ground_tile_location).was_called_with(match.ref(pc), location(1, 1))
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 0)

            assert.spy(player_char.enter_motion_state).was_called(1)
            assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.standing)
          end)

          it('should move the character upward just enough to escape ground if character is inside ground, update slope to 0 and enter state standing', function ()
            pc:set_bottom_center(vector(12, 9))
            pc:check_escape_from_ground()

            -- interface
            assert.are_same(vector(12, 8), pc:get_bottom_center())

            assert.spy(player_char.set_ground_tile_location).was_called(1)
            assert.spy(player_char.set_ground_tile_location).was_called_with(match.ref(pc), location(1, 1))
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 0)

            assert.spy(player_char.enter_motion_state).was_called(1)
            assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.standing)
          end)

          it('should move the character q-upward (to the left on right wall) just enough to escape ground if character is inside q-ground, update slope to 0 and enter state standing', function ()
            pc.quadrant = directions.right
            pc:set_bottom_center(vector(9, 12))
            pc:check_escape_from_ground()

            -- interface
            assert.are_same(vector(8, 12), pc:get_bottom_center())

            assert.spy(player_char.set_ground_tile_location).was_called(1)
            assert.spy(player_char.set_ground_tile_location).was_called_with(match.ref(pc), location(1, 1))
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 0.25)

            assert.spy(player_char.enter_motion_state).was_called(1)
            assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.standing)
          end)

          it('should reset state vars to too deep convention when character is too deep inside the ground and enter state falling', function ()
            pc:set_bottom_center(vector(12, 13))
            pc:check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 13), nil}, {pc:get_bottom_center(), pc.ground_tile_location})

            -- when nil, we don't use the set callback for ground tile location
            assert.spy(player_char.set_ground_tile_location).was_not_called()
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 0)

            assert.spy(player_char.enter_motion_state).was_called(1)
            assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.standing)
          end)

        end)

        -- note that 45 deg slope is considered quadrant down by world.angle_to_quadrant
        --  therefore our tests will work as on flat ground
        -- otherwise we'd need to adjust the expected get_bottom_center which is affected by quadrant

        describe('with descending slope 45', function ()

          before_each(function ()
            -- create a descending slope at (1, 1), i.e. (8, 8) to (15, 15) px
            mock_mset(1, 1, tile_repr.desc_slope_45_id)
          end)

          it('should reset state vars to airborne convention when character is not touching ground at all, and return false', function ()
            pc:set_bottom_center(vector(15, 10))
            pc:check_escape_from_ground()

            -- interface
            assert.are_same(vector(15, 10), pc:get_bottom_center())

            assert.spy(player_char.set_ground_tile_location).was_not_called()
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), nil)
          end)

          it('should do nothing when character is just on top of the ground, update slope to 1-45/360 and return true', function ()
            pc:set_bottom_center(vector(15, 12))
            pc:check_escape_from_ground()

            -- interface
            assert.are_same(vector(15, 12), pc:get_bottom_center())

            assert.spy(player_char.set_ground_tile_location).was_called(1)
            assert.spy(player_char.set_ground_tile_location).was_called_with(match.ref(pc), location(1, 1))
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 1-45/360)
          end)

          it('should move the character upward just enough to escape ground if character is inside ground, update slope to 1-45/360 and return true', function ()
            pc:set_bottom_center(vector(15, 13))
            pc:check_escape_from_ground()

            -- interface
            assert.are_same(vector(15, 12), pc:get_bottom_center())

            assert.spy(player_char.set_ground_tile_location).was_called(1)
            assert.spy(player_char.set_ground_tile_location).was_called_with(match.ref(pc), location(1, 1))
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 1-45/360)
          end)

          it('should reset state vars to too deep convention when character is too deep inside the ground, and return true', function ()
            pc:set_bottom_center(vector(11, 13))
            pc:check_escape_from_ground()

            -- interface
            assert.are_same(vector(11, 13), pc:get_bottom_center())

            assert.spy(player_char.set_ground_tile_location).was_not_called()
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 0)
          end)

        end)

      end)  -- check_escape_from_ground

      describe('enter_motion_state', function ()

        setup(function ()
          spy.on(player_char, "set_slope_angle_with_quadrant")  -- spy not stub in case the resulting slope_angle/quadrant matters
        end)

        teardown(function ()
          player_char.set_slope_angle_with_quadrant:revert()
        end)

        after_each(function ()
          player_char.set_slope_angle_with_quadrant:clear()
        end)

        it('should enter passed state: falling, reset ground-specific state vars, no animation change', function ()
          -- character starts standing
          pc:enter_motion_state(motion_states.falling)

          assert.are_same({
              motion_states.falling,
              0,
              false
            },
            {
              pc.motion_state,
              pc.ground_speed,
              pc.should_jump
            })
        end)

        it('(standing -> falling) should set enter_motion_state to nil', function ()
          pc.ground_tile_location = location(0, 1)
          pc:enter_motion_state(motion_states.falling)
          assert.is_nil(pc.ground_tile_location)
        end)

        it('(standing -> falling) should call set_slope_angle_with_quadrant(nil)', function ()
          -- character starts standing
          pc:enter_motion_state(motion_states.falling)

          assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
          assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), nil)
        end)

        it('should enter passed state: air_spin, reset ground-specific state vars, play spin animation', function ()
          pc.ground_speed = 10
          pc.should_jump = true
          pc.should_play_spring_jump = true
          pc.brake_anim_phase = 1

          -- character starts standing
          pc:enter_motion_state(motion_states.air_spin)

          assert.are_same({
              motion_states.air_spin,
              0,
              false,
              false,
              0,
            },
            {
              pc.motion_state,
              pc.ground_speed,
              pc.should_jump,
              pc.should_play_spring_jump,
              pc.brake_anim_phase,
            })
        end)

        it('(standing -> air_spin) should set enter_motion_state to nil', function ()
          pc.ground_tile_location = location(0, 1)
          pc:enter_motion_state(motion_states.falling)
          assert.is_nil(pc.ground_tile_location)
        end)

        it('(standing -> air_spin) should call set_slope_angle_with_quadrant(nil)', function ()
          -- character starts standing
          pc:enter_motion_state(motion_states.air_spin)

          assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
          assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), nil, true)
        end)

        -- bugfix history: .
        it('should enter passed state: standing, reset has_jumped_this_frame, can_interrupt_jump and should_play_spring_jump', function ()
          pc.ground_speed = 10
          pc.should_jump = true
          pc.should_play_spring_jump = true

          pc.motion_state = motion_states.falling

          pc:enter_motion_state(motion_states.standing)

          assert.are_same({
              motion_states.standing,
              false,
              false,
              false
            },
            {
              pc.motion_state,
              pc.has_jumped_this_frame,
              pc.can_interrupt_jump,
              pc.should_play_spring_jump
            })
        end)

        it('should enter passed state: rolling, reset has_jumped_this_frame, can_interrupt_jump and should_play_spring_jump', function ()
          pc.ground_speed = 10
          pc.should_jump = true
          pc.should_play_spring_jump = true
          pc.brake_anim_phase = 1

          pc.motion_state = motion_states.falling

          pc:enter_motion_state(motion_states.rolling)

          assert.are_same({
              motion_states.rolling,
              false,
              false,
              false,
              0,
            },
            {
              pc.motion_state,
              pc.has_jumped_this_frame,
              pc.can_interrupt_jump,
              pc.should_play_spring_jump,
              pc.brake_anim_phase,
            })
        end)

        it('(falling -> standing, velocity X = 0 on flat ground) should set ground speed to 0', function ()
          pc.motion_state = motion_states.falling
          pc.velocity.x = 0
          pc.velocity.y = 5

          pc:enter_motion_state(motion_states.standing)

          assert.are_equal(0, pc.ground_speed)
        end)

        it('(falling -> standing, velocity X = 2 on flat ground) should transfer velocity X completely to ground speed', function ()
          pc.motion_state = motion_states.falling
          pc.velocity.x = 2
          pc.velocity.y = 5

          pc:enter_motion_state(motion_states.standing)

          assert.are_equal(2, pc.ground_speed)
        end)

        it('(falling -> standing, velocity X = 5 (over max) on flat ground) should transfer velocity X *unclamped* to ground speed', function ()
          pc.motion_state = motion_states.falling
          pc.velocity.x = pc_data.max_running_ground_speed + 2
          pc.velocity.y = 5

          pc:enter_motion_state(motion_states.standing)

          assert.are_equal(pc_data.max_running_ground_speed + 2, pc.ground_speed)
        end)

        it('(falling -> standing, velocity (sqrt(3)/2, 0.5) tangent to slope 30 deg desc) should transfer velocity norm (1) completely to ground speed', function ()
          pc.motion_state = motion_states.falling
          pc.velocity.x = sqrt(3)/2
          pc.velocity.y = 0.5
          pc.slope_angle = 1-1/12  -- 30 deg/360 deg

          pc:enter_motion_state(motion_states.standing)

          -- should be OK in PICO-8, but with floating precision we need almost
          -- (angle of -1/12 was fine, but 1-1/12 offsets a little)
          assert.is_true(almost_eq_with_message(1, pc.ground_speed))
        end)

        it('(falling -> standing, velocity (-4, 4) orthogonally to slope 45 deg desc) should set ground speed to 0', function ()
          pc.motion_state = motion_states.falling
          pc.velocity.x = -4
          pc.velocity.y = 4
          pc.slope_angle = 1-0.125  -- 45 deg/360 deg

          pc:enter_motion_state(motion_states.standing)

          assert.is_true(almost_eq_with_message(0, pc.ground_speed))
        end)

        it('(falling -> standing, velocity (-4, 5) on slope 45 deg desc) should transfer just the tangent velocity (1/sqrt(2)) to ground speed', function ()
          pc.motion_state = motion_states.falling
          pc.velocity.x = -4
          pc.velocity.y = 5
          pc.slope_angle = 1-0.125  -- -45 deg/360 deg

          pc:enter_motion_state(motion_states.standing)

          assert.is_true(almost_eq_with_message(1/sqrt(2), pc.ground_speed))
        end)

        it('should adjust center position down when becoming compact', function ()
          pc.position = vector(10, 20)

          -- character starts standing
          pc:enter_motion_state(motion_states.air_spin)

          assert.are_equal(20 + pc_data.center_height_standing - pc_data.center_height_compact, pc.position.y)
        end)

        it('should adjust center position up when standing up', function ()
          pc.motion_state = motion_states.air_spin
          pc.position = vector(10, 20)

          -- character starts standing
          pc:enter_motion_state(motion_states.standing)

          assert.are_equal(20 - pc_data.center_height_standing + pc_data.center_height_compact, pc.position.y)
        end)

        it('should adjust center position qdown = left when becoming compact on left wall', function ()
          pc.position = vector(10, 20)
          pc.quadrant = directions.left

          -- character starts standing
          pc:enter_motion_state(motion_states.air_spin)

          assert.are_same(vector(10 - pc_data.center_height_standing + pc_data.center_height_compact, 20), pc.position)
        end)

        it('should adjust center position qup = up when landing and standing up on floor', function ()
          pc.motion_state = motion_states.air_spin
          pc.position = vector(10, 20)

          -- character starts standing
          pc:enter_motion_state(motion_states.standing)

          assert.are_same(vector(10, 20 - pc_data.center_height_standing + pc_data.center_height_compact), pc.position)
        end)

      end)

      describe('update_collision_timer', function ()

        it('should do nothing when timer is 0 (or negative)', function ()
          pc.ignore_launch_ramp_timer = 0

          pc:update_collision_timer()

          assert.are_equal(0, pc.ignore_launch_ramp_timer)
        end)

        it('should decrease timer by 1/60 s when timer is positive', function ()
          pc.ignore_launch_ramp_timer = 1

          pc:update_collision_timer()

          assert.are_equal(0, pc.ignore_launch_ramp_timer)
        end)

      end)

      describe('update_platformer_motion', function ()

        setup(function ()
          stub(player_char, "check_roll_start")
          stub(player_char, "check_roll_end")
          stub(player_char, "check_spring")
          stub(player_char, "check_launch_ramp")
          stub(player_char, "check_emerald")
          stub(player_char, "check_loop_external_triggers")
        end)

        teardown(function ()
          player_char.check_roll_start:revert()
          player_char.check_roll_end:revert()
          player_char.check_spring:revert()
          player_char.check_launch_ramp:revert()
          player_char.check_emerald:revert()
          player_char.check_loop_external_triggers:revert()
        end)

        after_each(function ()
          player_char.check_roll_start:clear()
          player_char.check_roll_end:clear()
          player_char.check_spring:clear()
          player_char.check_launch_ramp:clear()
          player_char.check_emerald:clear()
          player_char.check_loop_external_triggers:clear()
        end)

        it('(#debug_character) should clear debug rays from previous frame', function ()
          pc.debug_rays = {"dummy"}

          pc:update_platformer_motion()

          assert.are_same({}, pc.debug_rays)
        end)

        describe('(check_jump stubbed)', function ()

          setup(function ()
            stub(player_char, "check_jump")
          end)

          teardown(function ()
            player_char.check_jump:revert()
          end)

          after_each(function ()
            player_char.check_jump:clear()
          end)

          it('(when motion state is standing on ground) should call check_jump', function ()
            pc.motion_state = motion_states.standing
            pc:update_platformer_motion()
            assert.spy(player_char.check_jump).was_called(1)
            assert.spy(player_char.check_jump).was_called_with(match.ref(pc))
          end)

          it('(when motion state is rolling on ground) should call check_jump', function ()
            pc.motion_state = motion_states.rolling
            pc:update_platformer_motion()
            assert.spy(player_char.check_jump).was_called(1)
            assert.spy(player_char.check_jump).was_called_with(match.ref(pc))
          end)

          it('(when motion state is airborne) should call check_jump', function ()
            pc.motion_state = motion_states.falling  -- or any airborne state
            pc:update_platformer_motion()
            assert.spy(player_char.check_jump).was_not_called()
          end)

          it('should call check_spring (after motion)', function ()
            pc.motion_state = motion_states.falling  -- or any airborne state
            pc:update_platformer_motion()
            assert.spy(player_char.check_spring).was_called()
            assert.spy(player_char.check_spring).was_called_with(match.ref(pc))
          end)

          it('should call check_launch_ramp (after motion)', function ()
            pc.motion_state = motion_states.falling  -- or any airborne state
            pc:update_platformer_motion()
            assert.spy(player_char.check_launch_ramp).was_called()
            assert.spy(player_char.check_launch_ramp).was_called_with(match.ref(pc))
          end)

          it('should call check_emerald (after motion)', function ()
            pc.motion_state = motion_states.falling  -- or any airborne state
            pc:update_platformer_motion()
            assert.spy(player_char.check_emerald).was_called()
            assert.spy(player_char.check_emerald).was_called_with(match.ref(pc))
          end)

          it('should call check_loop_external_triggers (after motion)', function ()
            pc.motion_state = motion_states.falling  -- or any airborne state
            pc:update_platformer_motion()
            assert.spy(player_char.check_loop_external_triggers).was_called()
            assert.spy(player_char.check_loop_external_triggers).was_called_with(match.ref(pc))
          end)

        end)

        describe('(update_platformer_motion_grounded sets motion state to air_spin)', function ()

          local update_platformer_motion_grounded_mock
          local update_platformer_motion_airborne_stub

          setup(function ()
            -- mock the worst case possible for update_platformer_motion_grounded,
            --  changing the state to air_spin to make sure the airborne branch is not entered afterward (else instead of 2 if blocks)
            update_platformer_motion_grounded_mock = stub(player_char, "update_platformer_motion_grounded", function (self)
              self.motion_state = motion_states.air_spin
            end)
            update_platformer_motion_airborne_stub = stub(player_char, "update_platformer_motion_airborne")
          end)

          teardown(function ()
            update_platformer_motion_grounded_mock:revert()
            update_platformer_motion_airborne_stub:revert()
          end)

          after_each(function ()
            update_platformer_motion_grounded_mock:clear()
            update_platformer_motion_airborne_stub:clear()
          end)

          describe('(check_jump does nothing)', function ()

            local check_jump_stub

            setup(function ()
              check_jump_stub = stub(player_char, "check_jump")
            end)

            teardown(function ()
              check_jump_stub:revert()
            end)

            after_each(function ()
              check_jump_stub:clear()
            end)

            describe('(when character is standing)', function ()

              it('should call check_roll_start', function ()
                pc.motion_state = motion_states.standing

                pc:update_platformer_motion()

                assert.spy(player_char.check_roll_start).was_called(1)
                assert.spy(player_char.check_roll_start).was_called_with(match.ref(pc))
              end)

              it('should call update_platformer_motion_grounded', function ()
                pc.motion_state = motion_states.standing

                pc:update_platformer_motion()

                assert.spy(update_platformer_motion_grounded_mock).was_called(1)
                assert.spy(update_platformer_motion_grounded_mock).was_called_with(match.ref(pc))
                assert.spy(update_platformer_motion_airborne_stub).was_not_called()
              end)

            end)

            describe('(when character is rolling)', function ()

              it('should call check_roll_start', function ()
                pc.motion_state = motion_states.rolling

                pc:update_platformer_motion()

                assert.spy(player_char.check_roll_end).was_called(1)
                assert.spy(player_char.check_roll_end).was_called_with(match.ref(pc))
              end)

              it('should call update_platformer_motion_grounded', function ()
                pc.motion_state = motion_states.rolling

                pc:update_platformer_motion()

                assert.spy(update_platformer_motion_grounded_mock).was_called(1)
                assert.spy(update_platformer_motion_grounded_mock).was_called_with(match.ref(pc))
                assert.spy(update_platformer_motion_airborne_stub).was_not_called()
              end)

            end)

            describe('(when character is in air_spin)', function ()

              it('should call update_platformer_motion_airborne', function ()
                pc.motion_state = motion_states.air_spin

                pc:update_platformer_motion()

                assert.spy(update_platformer_motion_airborne_stub).was_called(1)
                assert.spy(update_platformer_motion_airborne_stub).was_called_with(match.ref(pc))
                assert.spy(update_platformer_motion_grounded_mock).was_not_called()
              end)

            end)

          end)

          describe('(check_jump enters air_spin motion state)', function ()

            local check_jump_mock

            setup(function ()
              check_jump_mock = stub(player_char, "check_jump", function ()
                pc.motion_state = motion_states.air_spin
              end)
            end)

            teardown(function ()
              check_jump_mock:revert()
            end)

            after_each(function ()
              check_jump_mock:clear()
            end)

            describe('(when character is standing first)', function ()

              it('should not call check_roll_start since check_jump will enter air_spin first', function ()
                pc.motion_state = motion_states.standing

                pc:update_platformer_motion()

                assert.spy(player_char.check_roll_start).was_not_called()
              end)

              it('should call update_platformer_motion_airborne since check_jump will enter air_spin first', function ()
                pc.motion_state = motion_states.standing

                pc:update_platformer_motion()

                assert.spy(update_platformer_motion_airborne_stub).was_called(1)
                assert.spy(update_platformer_motion_airborne_stub).was_called_with(match.ref(pc))
                assert.spy(update_platformer_motion_grounded_mock).was_not_called()
              end)

            end)

            describe('(when character is rolling first)', function ()

              it('should not call check_roll_end since check_jump will enter air_spin first', function ()
                pc.motion_state = motion_states.rolling

                pc:update_platformer_motion()

                assert.spy(player_char.check_roll_end).was_not_called()
              end)

              it('should call update_platformer_motion_airborne since check_jump will enter air_spin first', function ()
                pc.motion_state = motion_states.rolling

                pc:update_platformer_motion()

                assert.spy(update_platformer_motion_airborne_stub).was_called(1)
                assert.spy(update_platformer_motion_airborne_stub).was_called_with(match.ref(pc))
                assert.spy(update_platformer_motion_grounded_mock).was_not_called()
              end)

            end)

            -- we don't need to test (when character is airborne) since in this context check_jump
            -- always trigger a jump, which is impossible from the air (as double jump is not implemented)

          end)

        end)

      end)  -- _update_platformer_motion

      describe('check_roll_start', function ()

        setup(function ()
          stub(player_char, "enter_motion_state")
          stub(player_char, "play_low_priority_sfx")
        end)

        teardown(function ()
          player_char.enter_motion_state:revert()
          player_char.play_low_priority_sfx:revert()
        end)

        after_each(function ()
          player_char.enter_motion_state:clear()
          player_char.play_low_priority_sfx:clear()
        end)

        before_each(function ()
          -- assumption
          pc.motion_state = motion_states.standing
        end)

        it('should not start rolling if input down is pressed but abs ground speed (positive) is not enough', function ()
          pc.ground_speed = pc_data.roll_min_ground_speed - 0.01
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)
          pc.move_intention.y = 1

          pc:check_roll_start()

          assert.spy(player_char.enter_motion_state).was_not_called()
        end)

        it('should not start rolling if input down is pressed but abs ground speed (negative) is not enough', function ()
          pc.ground_speed = -pc_data.roll_min_ground_speed + 0.01
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)
          pc.move_intention.y = 1

          pc:check_roll_start()

          assert.spy(player_char.enter_motion_state).was_not_called()
        end)

        it('should not start rolling if input down is pressed and abs ground speed (positive) is enough, but input x is also pressed', function ()
          pc.ground_speed = pc_data.roll_min_ground_speed
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)
          pc.move_intention = vector(-1, 1)

          pc:check_roll_start()

          assert.spy(player_char.enter_motion_state).was_not_called()
        end)

        it('should not start rolling if abs ground speed (positive) is high enough but input down is not pressed', function ()
          pc.ground_speed = pc_data.roll_min_ground_speed
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)
          pc.move_intention.y = 0

          pc:check_roll_start()

          assert.spy(player_char.enter_motion_state).was_not_called()
        end)

        it('should not start rolling if abs ground speed (negative) is high enough but input down is not pressed', function ()
          pc.ground_speed = -pc_data.roll_min_ground_speed
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)
          pc.move_intention.y = 0

          pc:check_roll_start()

          assert.spy(player_char.enter_motion_state).was_not_called()
        end)

        it('should start rolling if input down is pressed and abs ground speed (positive) is enough', function ()
          pc.ground_speed = pc_data.roll_min_ground_speed
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)
          pc.move_intention.y = 1

          pc:check_roll_start()

          assert.spy(player_char.enter_motion_state).was_called(1)
          assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.rolling)
        end)

        it('should start rolling if input down is pressed and abs ground speed (negative) is enough', function ()
          pc.ground_speed = -pc_data.roll_min_ground_speed
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)
          pc.move_intention.y = 1

          pc:check_roll_start()

          assert.spy(player_char.enter_motion_state).was_called(1)
          assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.rolling)
        end)

        it('should play low priority sfx when conditions to start rolling are met', function ()
          pc.ground_speed = pc_data.roll_min_ground_speed
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)
          pc.move_intention.y = 1

          pc:check_roll_start()

          assert.spy(player_char.play_low_priority_sfx).was_called(1)
          assert.spy(player_char.play_low_priority_sfx).was_called_with(match.ref(pc), audio.sfx_ids.roll)
        end)

      end)

      describe('check_roll_end', function ()

        setup(function ()
          stub(player_char, "enter_motion_state")
        end)

        teardown(function ()
          player_char.enter_motion_state:revert()
        end)

        after_each(function ()
          player_char.enter_motion_state:clear()
        end)

        before_each(function ()
          -- assumption
          pc.motion_state = motion_states.rolling
        end)

        it('should not end rolling if abs ground speed (positive) is high enough', function ()
          pc.ground_speed = pc_data.continue_roll_min_ground_speed
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)

          pc:check_roll_end()

          -- interface
          assert.spy(player_char.enter_motion_state).was_not_called()
        end)

        it('should not end rolling if abs ground speed (negative) is high enough', function ()
          pc.ground_speed = -pc_data.continue_roll_min_ground_speed
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)

          pc:check_roll_end()

          -- interface
          assert.spy(player_char.enter_motion_state).was_not_called()
        end)

        it('should end rolling if abs ground speed (positive) is not enough', function ()
          pc.ground_speed = pc_data.continue_roll_min_ground_speed - 0.01
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)

          pc:check_roll_end()

          -- interface
          assert.spy(player_char.enter_motion_state).was_called(1)
          assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.standing)
        end)

        it('should end rolling if abs ground speed (negative) is not enough', function ()
          pc.ground_speed = -pc_data.continue_roll_min_ground_speed + 0.01
          -- we don't set velocity, but on flat ground it would be vector(pc.ground_speed, 0)

          pc:check_roll_end()

          -- interface
          assert.spy(player_char.enter_motion_state).was_called(1)
          assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.standing)
        end)

      end)

      -- bugfix history:
      --  ^ use fractional speed to check that fractional moves are supported
      describe('update_platformer_motion_grounded (when _update_velocity sets ground_speed to 2.5)', function ()

        local update_ground_speed_mock
        local enter_motion_state_stub
        local check_jump_intention_stub
        local compute_ground_motion_result_mock

        -- allows to modify the mock _update_ground_speed without restubbing it for every test section
        local new_ground_speed = -2.5  -- use fractional speed to check that fractions are preserved

        setup(function ()
          -- trigger check inside set_ground_tile_location will fail as it needs context
          -- (tile_test_data + mset), so we prefer stubbing as we don't check ground_tile_location directly
          stub(player_char, "set_ground_tile_location")
          spy.on(player_char, "set_slope_angle_with_quadrant")  -- spy not stub in case the resulting slope_angle/quadrant matters

          update_ground_speed_mock = stub(player_char, "update_ground_speed", function (self)
            self.ground_speed = new_ground_speed
          end)
          enter_motion_state_stub = stub(player_char, "enter_motion_state")
          check_jump_intention_stub = stub(player_char, "check_jump_intention")
        end)

        teardown(function ()
          player_char.set_slope_angle_with_quadrant:revert()

          update_ground_speed_mock:revert()
          enter_motion_state_stub:revert()
          player_char.set_ground_tile_location:revert()
          check_jump_intention_stub:revert()
        end)

        after_each(function ()
          player_char.set_slope_angle_with_quadrant:clear()

          update_ground_speed_mock:clear()
          enter_motion_state_stub:clear()
          player_char.set_ground_tile_location:clear()
          check_jump_intention_stub:clear()
        end)

        it('should call _update_ground_speed', function ()
          pc:update_platformer_motion_grounded()

          -- implementation
          assert.spy(update_ground_speed_mock).was_called(1)
          assert.spy(update_ground_speed_mock).was_called_with(match.ref(pc))
        end)

        describe('(when _compute_ground_motion_result returns a motion result with position vector(3, 4), slope_angle: 0.25, is_blocked: false, is_falling: false)', function ()

          setup(function ()
            compute_ground_motion_result_mock = stub(player_char, "compute_ground_motion_result", function (self)
              return motion.ground_motion_result(
                location(0, 1),
                vector(3, 4),
                0.25,
                false,
                false
              )
            end)
          end)

          teardown(function ()
            compute_ground_motion_result_mock:revert()
          end)

          after_each(function ()
            compute_ground_motion_result_mock:clear()
          end)

          it('should keep updated ground speed and set velocity frame according to ground speed (not blocked)', function ()
            pc:update_platformer_motion_grounded()
            -- interface: relying on _update_ground_speed implementation
            assert.are_same({-2.5, vector(-2.5, 0)}, {pc.ground_speed, pc.velocity})
          end)

          it('should keep updated ground speed and set velocity frame according to ground speed and slope if not flat (not blocked)', function ()
            pc.slope_angle = 1/6  -- cos = 1/2, sin = -sqrt(3)/2, but use the formula directly to support floating errors
            pc:update_platformer_motion_grounded()
            -- interface: relying on _update_ground_speed implementation
            assert.are_same({-2.5, vector(-2.5*cos(1/6), 2.5*sqrt(3)/2)}, {pc.ground_speed, pc.velocity})
          end)

          it('should set the position to vector(3, 4)', function ()
            pc:update_platformer_motion_grounded()
            assert.are_same(vector(3, 4), pc.position)
          end)

          it('should call player_char.set_ground_tile_location with location(0, 1)', function ()
            pc:update_platformer_motion_grounded()
            assert.spy(player_char.set_ground_tile_location).was_called(1)
            assert.spy(player_char.set_ground_tile_location).was_called_with(match.ref(pc), location(0, 1))
          end)

          it('should call set_slope_angle_with_quadrant with 0.25', function ()
            pc.slope_angle = 1-0.25
            pc:update_platformer_motion_grounded()
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 0.25)
          end)

          it('should call check_jump_intention, not enter_motion_state (not falling)', function ()
            pc:update_platformer_motion_grounded()

            -- implementation
            assert.spy(check_jump_intention_stub).was_called(1)
            assert.spy(check_jump_intention_stub).was_called_with(match.ref(pc))
            assert.spy(enter_motion_state_stub).was_not_called()
          end)

          it('should set the run animation playback speed to abs(ground speed) (non-zero)', function ()
            -- mock is setting ground speed to -2.5
            pc:update_platformer_motion_grounded()

            assert.are_equal(2.5, pc.anim_run_speed)
          end)

          describe('(walking on ceiling or wall-ceiling)', function ()

            before_each(function ()
              -- must be > 0.25 and < 0.75
              -- for full testing we should test 0.25, 0.75 and 0.74 too,
              --  but that will be enough
              -- the normal tests being done on ground where slope angle is 0 or very low (1-1/6)
              pc.slope_angle = 0.26
              pc.quadrant = directions.right
            end)

            describe('(_update_ground_speed sets ground speed to -pc_data.ceiling_adherence_min_ground_speed / 2)', function ()

              setup(function ()
                -- something lower than pc_data.ceiling_adherence_min_ground_speed in abs value
                new_ground_speed = -pc_data.ceiling_adherence_min_ground_speed / 2
              end)

              teardown(function ()
                -- pretty hacky way to restore the original stub of _update_ground_speed for further tests below
                new_ground_speed = -2.5
              end)

              it('should enter falling state thanks to Falling and Sliding Off condition', function ()
                pc:update_platformer_motion_grounded()

                assert.spy(enter_motion_state_stub).was_called(1)
                assert.spy(enter_motion_state_stub).was_called_with(match.ref(pc), motion_states.falling)
              end)

              it('(when rolling) should enter air_spin state thanks to Falling and Sliding Off condition', function ()
                pc.motion_state = motion_states.rolling

                pc:update_platformer_motion_grounded()

                assert.spy(enter_motion_state_stub).was_called(1)
                assert.spy(enter_motion_state_stub).was_called_with(match.ref(pc), motion_states.air_spin)
              end)

            end)

            describe('(_update_ground_speed sets ground speed to -pc_data.ceiling_adherence_min_ground_speed)', function ()

              setup(function ()
                -- exactly pc_data.ceiling_adherence_min_ground_speed in abs value to test exact comparison
                new_ground_speed = -pc_data.ceiling_adherence_min_ground_speed
              end)

              teardown(function ()
                -- pretty hacky way to restore the original stub of _update_ground_speed for further tests below
                new_ground_speed = -2.5
              end)

              it('should not enter falling (nor air_spin) state, escaping Falling and Sliding Off condition', function ()
                pc:update_platformer_motion_grounded()

                assert.spy(enter_motion_state_stub).was_not_called()
              end)

            end)

          end)

        end)

        describe('(when _compute_ground_motion_result returns a motion result with position vector(3, 4), slope_angle: 0.5, is_blocked: true, is_falling: false)', function ()

          local compute_ground_motion_result_mock

          setup(function ()
            compute_ground_motion_result_mock = stub(player_char, "compute_ground_motion_result", function (self)
              return motion.ground_motion_result(
                location(0, 1),
                vector(3, 4),
                0.5,
                true,
                false
              )
            end)
          end)

          teardown(function ()
            compute_ground_motion_result_mock:revert()
          end)

          after_each(function ()
            compute_ground_motion_result_mock:clear()
          end)

          it('should reset ground speed and velocity frame to zero (blocked)', function ()
            pc:update_platformer_motion_grounded()
            assert.are_same({0, vector.zero()}, {pc.ground_speed, pc.velocity})
          end)

          it('should call check_jump_intention, not enter_motion_state (not falling)', function ()
            pc:update_platformer_motion_grounded()

            -- implementation
            assert.spy(check_jump_intention_stub).was_called(1)
            assert.spy(check_jump_intention_stub).was_called_with(match.ref(pc))
            assert.spy(enter_motion_state_stub).was_not_called()
          end)

          it('should set the position to vector(3, 4)', function ()
            pc:update_platformer_motion_grounded()
            assert.are_same(vector(3, 4), pc.position)
          end)

          it('should call player_char.set_ground_tile_location with location(0, 1)', function ()
            pc:update_platformer_motion_grounded()
            assert.spy(player_char.set_ground_tile_location).was_called(1)
            assert.spy(player_char.set_ground_tile_location).was_called_with(match.ref(pc), location(0, 1))
          end)

          it('should call set_slope_angle_with_quadrant with 0.5', function ()
            pc.slope_angle = 1-0.24
            pc.quadrant = directions.left
            pc:update_platformer_motion_grounded()
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 0.5)
          end)

          it('should set the run animation playback speed to abs(ground speed) = 0', function ()
            pc:update_platformer_motion_grounded()

            assert.are_equal(0, pc.anim_run_speed)
          end)

          it('(on ceiling/wall-ceiling) should enter falling state and set horizontal control lock timer thanks to Falling and Sliding Off condition combined with block setting ground speed to 0', function ()
            pc.slope_angle = 0.25
            pc.quadrant = directions.right

            pc:update_platformer_motion_grounded()

            assert.spy(enter_motion_state_stub).was_called(1)
            assert.spy(enter_motion_state_stub).was_called_with(match.ref(pc), motion_states.falling)

            assert.are_equal(pc_data.fall_off_horizontal_control_lock_duration, pc.horizontal_control_lock_timer)
          end)

          it('(rolling on ceiling/wall-ceiling) should enter air_spin state and set horizontal control lock timer thanks to Falling and Sliding Off condition combined with block setting ground speed to 0', function ()
            pc.motion_state = motion_states.rolling
            pc.slope_angle = 0.25
            pc.quadrant = directions.right

            pc:update_platformer_motion_grounded()

            assert.spy(enter_motion_state_stub).was_called(1)
            assert.spy(enter_motion_state_stub).was_called_with(match.ref(pc), motion_states.air_spin)

            assert.are_equal(pc_data.fall_off_horizontal_control_lock_duration, pc.horizontal_control_lock_timer)
          end)

          it('(on slope less than 90 degrees) should not enter falling state but still set horizontal control lock timer', function ()
            pc.slope_angle = 1-0.24
            pc.quadrant = directions.right

            pc:update_platformer_motion_grounded()

            assert.spy(enter_motion_state_stub).was_not_called()

            assert.are_equal(pc_data.fall_off_horizontal_control_lock_duration, pc.horizontal_control_lock_timer)
          end)

        end)

        describe('(when _compute_ground_motion_result returns a motion result with position vector(3, 4), slope_angle: nil, is_blocked: false, is_falling: true)', function ()

          local compute_ground_motion_result_mock

          setup(function ()
            compute_ground_motion_result_mock = stub(player_char, "compute_ground_motion_result", function (self)
              return motion.ground_motion_result(
                nil,
                vector(3, 4),
                nil,
                false,
                true
              )
            end)
          end)

          teardown(function ()
            compute_ground_motion_result_mock:revert()
          end)

          after_each(function ()
            compute_ground_motion_result_mock:clear()
          end)

          it('should keep updated ground speed and set velocity frame according to ground speed (not blocked)', function ()
            pc:update_platformer_motion_grounded()
            -- interface: relying on _update_ground_speed implementation
            assert.are_same({-2.5, vector(-2.5, 0)}, {pc.ground_speed, pc.velocity})
          end)

          it('should keep updated ground speed and set velocity frame according to ground speed and slope if not flat (not blocked)', function ()
            pc.slope_angle = 1/6  -- cos = 1/2, sin = -sqrt(3)/2, but use the formula directly to support floating errors
            pc:update_platformer_motion_grounded()
            -- interface: relying on _update_ground_speed implementation
            assert.are_same({-2.5, vector(-2.5*cos(1/6), 2.5*sqrt(3)/2)}, {pc.ground_speed, pc.velocity})
          end)

          it('should call enter_motion_state with falling state, not call check_jump_intention (falling)', function ()
            pc:update_platformer_motion_grounded()

            -- implementation
            assert.spy(enter_motion_state_stub).was_called(1)
            assert.spy(enter_motion_state_stub).was_called_with(match.ref(pc), motion_states.falling)
            assert.spy(check_jump_intention_stub).was_not_called()
          end)

          it('(when rolling) should call enter_motion_state with air_spin state, not call check_jump_intention (falling)', function ()
            pc.motion_state = motion_states.rolling

            pc:update_platformer_motion_grounded()

            -- implementation
            assert.spy(enter_motion_state_stub).was_called(1)
            assert.spy(enter_motion_state_stub).was_called_with(match.ref(pc), motion_states.air_spin)
            assert.spy(check_jump_intention_stub).was_not_called()
          end)

          it('should set the position to vector(3, 4)', function ()
            pc:update_platformer_motion_grounded()
            assert.are_same(vector(3, 4), pc.position)
          end)

          -- we don't test that ground_tile_location is set to nil
          --  because we stubbed enter_motion_state which should do it,
          --  but if it was spied we could test it

          it('should not call set_slope_angle_with_quadrant (actually called inside enter_motion_state)', function ()
            pc.slope_angle = 0
            pc:update_platformer_motion_grounded()
            -- this only works because enter_motion_state is stubbed
            -- if it was spied, it would still call set_slope_angle_with_quadrant inside
            assert.spy(player_char.set_slope_angle_with_quadrant).was_not_called()
          end)

        end)

        describe('(when _compute_ground_motion_result returns a motion result with position vector(3, 4), slope_angle: nil, is_blocked: true, is_falling: true)', function ()

          local compute_ground_motion_result_mock

          setup(function ()
            compute_ground_motion_result_mock = stub(player_char, "compute_ground_motion_result", function (self)
              return motion.ground_motion_result(
                nil,
                vector(3, 4),
                nil,
                true,
                true
              )
            end)
          end)

          teardown(function ()
            compute_ground_motion_result_mock:revert()
          end)

          after_each(function ()
            compute_ground_motion_result_mock:clear()
          end)

          it('should reset ground speed and velocity frame to zero (blocked)', function ()
            pc:update_platformer_motion_grounded()
            assert.are_same({0, vector.zero()}, {pc.ground_speed, pc.velocity})
          end)

          it('should call enter_motion_state with falling state, not call check_jump_intention (falling)', function ()
            pc:update_platformer_motion_grounded()

            -- implementation
            assert.spy(enter_motion_state_stub).was_called(1)
            assert.spy(enter_motion_state_stub).was_called_with(match.ref(pc), motion_states.falling)
            assert.spy(check_jump_intention_stub).was_not_called()
          end)

          it('(when rolling) should call enter_motion_state with air_spin state, not call check_jump_intention (falling)', function ()
            pc.motion_state = motion_states.rolling

            pc:update_platformer_motion_grounded()

            -- implementation
            assert.spy(enter_motion_state_stub).was_called(1)
            assert.spy(enter_motion_state_stub).was_called_with(match.ref(pc), motion_states.air_spin)
            assert.spy(check_jump_intention_stub).was_not_called()
          end)

          it('should set the position to vector(3, 4)', function ()
            pc:update_platformer_motion_grounded()
            assert.are_same(vector(3, 4), pc.position)
          end)

          it('should not call set_slope_angle_with_quadrant (actually called inside enter_motion_state)', function ()
            pc.slope_angle = 0
            pc:update_platformer_motion_grounded()
            -- this only works because enter_motion_state is stubbed
            -- if it was spied, it would still call set_slope_angle_with_quadrant inside
            assert.spy(player_char.set_slope_angle_with_quadrant).was_not_called()
          end)

        end)

        describe('(when _compute_ground_motion_result returns a motion result with position vector(*2.5*, 4), slope_angle: 0, is_blocked: false, is_falling: false)', function ()

          local compute_ground_motion_result_mock

          setup(function ()
            stub(player_char, "compute_ground_motion_result", function (self)
              return motion.ground_motion_result(
                location(-1, 0),
                vector(2.5, 4),  -- flr(2.5) must be < pc_data.ground_sensor_extent_x
                0,
                false,
                false
              )
            end)
          end)

          teardown(function ()
            player_char.compute_ground_motion_result:revert()
          end)

          after_each(function ()
            player_char.compute_ground_motion_result:clear()
          end)

          it('should clamp character position X to stage left boundary (including half-width offset)', function ()
            pc:update_platformer_motion_grounded()

            -- in practice, clamped to 3
            assert.are_same(ceil(pc_data.ground_sensor_extent_x), pc.position.x)
          end)

          it('should clamp the ground speed to -0.1', function ()
            -- note that we didn't set move intention
            -- so character will decel to -2.5 this frame, but enough to test clamping
            pc.ground_speed = -3

            pc:update_platformer_motion_grounded()

            assert.are_equal(-0.1, pc.ground_speed)
          end)

        end)

      end)  -- update_platformer_motion_grounded

      describe('update_ground_speed', function ()

        setup(function ()
          -- the only reason we spy and not stub is to test the interface in the first test below
          spy.on(player_char, "update_ground_speed_by_slope")
          spy.on(player_char, "update_ground_run_speed_by_intention")
          spy.on(player_char, "update_ground_roll_speed_by_intention")
          spy.on(player_char, "clamp_ground_speed")
        end)

        teardown(function ()
          player_char.update_ground_speed_by_slope:revert()
          player_char.update_ground_run_speed_by_intention:revert()
          player_char.update_ground_roll_speed_by_intention:revert()
          player_char.clamp_ground_speed:revert()
        end)

        after_each(function ()
          player_char.update_ground_speed_by_slope:clear()
          player_char.update_ground_run_speed_by_intention:clear()
          player_char.update_ground_roll_speed_by_intention:clear()
          player_char.clamp_ground_speed:clear()
        end)

        -- usually we'd only test the interface (calls)
        -- but since we cannot easily test the call order with spies,
        --  we do a mini itest to check the resulting velocity,
        --  which will prove that slope factor is applied before intention

        it('(standing) should apply descending slope factor, then oppose it with strong decel when moving in the ascending direction of 45-degree slope from ground speed 0', function ()
          -- interface: check overall behavior (mini integration test)
          pc.ground_speed = 0
          pc.slope_angle = 1/8  -- 45 deg ascending

          pc.move_intention.x = 1
          pc:update_ground_speed()
          -- Note that we have fixed the classic Sonic exploit of decelerating faster when accelerating backward from ground speed 0,
          --  so the speed will still be clamped to ground accel on this frame, and not become
          --  - pc_data.slope_accel_factor_frame2 * sin(-1/8) + pc_data.ground_decel_frame2
          assert.are_equal(pc_data.ground_accel_frame2, pc.ground_speed)
        end)

        it('(standing) should update ground speed based on slope, then intention', function ()
          pc.ground_speed = 2.5

          pc:update_ground_speed()

          assert.spy(player_char.update_ground_speed_by_slope).was_called(1)
          assert.spy(player_char.update_ground_speed_by_slope).was_called_with(match.ref(pc))
          assert.spy(player_char.update_ground_run_speed_by_intention).was_called(1)
          assert.spy(player_char.update_ground_run_speed_by_intention).was_called_with(match.ref(pc))
          assert.spy(player_char.clamp_ground_speed).was_called(1)
          assert.spy(player_char.clamp_ground_speed).was_called_with(match.ref(pc), 2.5)
        end)

        it('(rolling) should call update_ground_roll_speed_by_intention (instead of _run_)', function ()
          pc.motion_state = motion_states.rolling

          pc:update_ground_speed()

          assert.spy(player_char.update_ground_speed_by_slope).was_called(1)
          assert.spy(player_char.update_ground_speed_by_slope).was_called_with(match.ref(pc))
          assert.spy(player_char.update_ground_roll_speed_by_intention).was_called(1)
          assert.spy(player_char.update_ground_roll_speed_by_intention).was_called_with(match.ref(pc))
          assert.spy(player_char.clamp_ground_speed).was_not_called()
        end)

      end)  -- _update_ground_speed

      describe('update_ground_speed_by_slope', function ()

        it('should preserve ground speed on flat ground', function ()
          pc.ground_speed = 2
          pc.slope_angle = 0
          pc.ascending_slope_time = 77

          pc:update_ground_speed_by_slope(1.8)

          assert.are_equal(2, pc.ground_speed)

          assert.are_same({
              2,
              0
            },
            {
              pc.ground_speed,
              pc.ascending_slope_time
            })
        end)

        -- Original feature (not in SPG): Progressive Ascending Steep Slope Factor

        it('should accelerate toward left on a steep ascending slope, with very reduced slope factor at the beginning of the climb, and increase ascending slope time', function ()
          pc.ground_speed = 2
          pc.slope_angle = 0.125  -- sin(0.125) = -sqrt(2)/2
          pc.ascending_slope_time = 0

          pc:update_ground_speed_by_slope(1.8)

          assert.are_same({
              2 - delta_time60 / pc_data.progressive_ascending_slope_duration * pc_data.slope_accel_factor_frame2 * sqrt(2)/2,
              delta_time60
            },
            {
              pc.ground_speed,
              pc.ascending_slope_time
            })
        end)

        it('should accelerate toward left on a steep ascending slope, with reduced slope factor before ascending slope duration, and increase ascending slope time', function ()
          pc.ground_speed = 2
          pc.slope_angle = 0.125  -- sin(0.125) = -sqrt(2)/2
          pc.ascending_slope_time = 0.1

          pc:update_ground_speed_by_slope(1.8)

          assert.are_same({
              2 - (0.1 + delta_time60) / pc_data.progressive_ascending_slope_duration * pc_data.slope_accel_factor_frame2 * sqrt(2)/2,
              0.1 + delta_time60
            },
            {
              pc.ground_speed,
              pc.ascending_slope_time
            })
        end)

        it('should accelerate toward left on a steep ascending slope, with full slope factor after ascending slope duration, and clamp time to that duration', function ()
          pc.ground_speed = 2
          pc.slope_angle = 0.125  -- sin(0.125) = -sqrt(2)/2
          pc.ascending_slope_time = pc_data.progressive_ascending_slope_duration

          pc:update_ground_speed_by_slope(1.8)

          assert.are_same({
              2 - pc_data.slope_accel_factor_frame2 * sqrt(2)/2,
              pc_data.progressive_ascending_slope_duration
            },
            {
              pc.ground_speed,
              pc.ascending_slope_time
            })
        end)

        it('should accelerate toward right on a non-steep ascending slope, and reset any ascending slope time', function ()
          pc.ground_speed = 2
          pc.slope_angle = 0.0625
          pc.ascending_slope_time = 77

          pc:update_ground_speed_by_slope(1.8)

          assert.are_same({
              2 - pc_data.slope_accel_factor_frame2 * sin(-0.0625),  -- note that the sin is positive
              0
            },
            {
              pc.ground_speed,
              pc.ascending_slope_time
            })
        end)

        it('should accelerate toward right on an descending slope, with full slope factor, and reset any ascending slope time', function ()
          pc.ground_speed = 2
          pc.slope_angle = 1-0.125  -- sin(-0.125) = sqrt(2)/2
          pc.ascending_slope_time = 77

          pc:update_ground_speed_by_slope(1.8)

          assert.are_same({
              2 + pc_data.slope_accel_factor_frame2 * sqrt(2)/2,
              0
            },
            {
              pc.ground_speed,
              pc.ascending_slope_time
            })
        end)

      end)  -- _update_ground_speed_by_slope

      describe('update_ground_run_speed_by_intention', function ()

        setup(function ()
          stub(player_char, "play_low_priority_sfx")
        end)

        teardown(function ()
          player_char.play_low_priority_sfx:revert()
        end)

        after_each(function ()
          player_char.play_low_priority_sfx:clear()
        end)

        it('should accelerate and set direction based on new speed when character is facing left, has ground speed 0 and move intention x > 0', function ()
          pc.orientation = horizontal_dirs.left
          pc.move_intention.x = 1
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, pc_data.ground_accel_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        it('should accelerate and set orientation + reset brake_anim_phase when character is facing left, has ground speed > 0 and move intention x > 0', function ()
          pc.orientation = horizontal_dirs.left  -- rare to oppose ground speed sense, but possible when running backward e.g. after landing on a steep ascending slope and walking backward
          pc.brake_anim_phase = 1
          pc.ground_speed = 1.5
          pc.move_intention.x = 1
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 0, 1.5 + pc_data.ground_accel_frame2},
            {pc.orientation, pc.brake_anim_phase, pc.ground_speed})
        end)

        it('should accelerate and preserve direction when character is facing left, has ground speed < 0 and move intention x < 0', function ()
          pc.orientation = horizontal_dirs.left  -- rare to oppose ground speed sense, but possible when running backward e.g. after hitting a spring after landing on a steep ascending slope and walking backward
          pc.ground_speed = -1.5
          pc.move_intention.x = -1
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.left, -1.5 - pc_data.ground_accel_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        it('should decelerate keeping same sign and direction when character is facing right, has high ground speed > ground accel * 1 frame and move intention x < 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 1.5
          pc.move_intention.x = -1
          pc:update_ground_run_speed_by_intention()
          -- ground_decel_frame2 = 0.25, subtract it from ground_speed
          assert.are_same({horizontal_dirs.right, 1.25},
            {pc.orientation, pc.ground_speed})
        end)

        -- Original feature (not in SPG): Reduced Deceleration on Steep Descending Slope

        it('should decelerate with decel descending slope factor, keeping same sign and direction when character is on steep descending slope facing right, has high ground speed > ground accel * 1 frame and move intention x < 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 1.5
          pc.move_intention.x = -1
          pc.slope_angle = 1-0.125
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 1.5 - pc_data.ground_decel_descending_slope_factor * pc_data.ground_decel_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        it('should decelerate without decel descending slope factor, keeping same sign and direction when character is on non-steep descending slope facing right, has high ground speed > ground accel * 1 frame and move intention x < 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 1.5
          pc.move_intention.x = -1
          pc.slope_angle = 1-0.0625
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 1.5 - pc_data.ground_decel_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        -- End Original feature

        it('should decelerate and stop exactly at speed 0, when character has ground speed = ground decel * 1 frame and move intention x < 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = pc_data.ground_decel_frame2
          pc.move_intention.x = -1
          pc:update_ground_run_speed_by_intention()
          assert.are_equal(0, pc.ground_speed)
        end)

        -- test orientation and brake anim phase together as they are related to visuals

        it('should set orientation to move intention dir (here, *change orientation*) and preserve brake_anim_phase when character decelerates exactly to 0 but no brake anim started', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = pc_data.ground_decel_frame2
          pc.move_intention.x = -1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.left, 0}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should set orientation to move intention dir (here, *change orientation*) and advance brake_anim_phase to 2 when character decelerates exactly to 0 but and brake_start is playing', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = pc_data.ground_decel_frame2
          pc.move_intention.x = -1
          pc.brake_anim_phase = 1

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.left, 2}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should preserve orientation and brake anim phase when quadrant down and abs ground speed is too low', function ()
          pc.quadrant = directions.down
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = pc_data.brake_anim_min_speed_frame - 0.01
          pc.move_intention.x = -1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 0}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should preserve orientation and brake anim phase when quadrant right and abs ground speed is high enough', function ()
          pc.quadrant = directions.right
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = pc_data.brake_anim_min_speed_frame
          pc.move_intention.x = -1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 0}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should set orientation to ground speed dir (here, no change) and brake anim phase to 1 then play brake low priority sfx when quadrant down and abs ground speed is high enough', function ()
          pc.quadrant = directions.down
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = pc_data.brake_anim_min_speed_frame
          pc.move_intention.x = -1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 1}, {pc.orientation, pc.brake_anim_phase})

          assert.spy(player_char.play_low_priority_sfx).was_called(1)
          assert.spy(player_char.play_low_priority_sfx).was_called_with(match.ref(pc), audio.sfx_ids.brake)
        end)

        -- bugfix history:
        -- _ missing tests that check the change of sign of ground speed
        it('should decelerate and start moving to the left when character is facing right, '..
          'has low ground speed > 0 but < ground accel * 1 frame and move intention x < 0 '..
          'but the ground speed is high enough so that the new speed wouldn\'t be over the max ground speed', function ()
          pc.orientation = horizontal_dirs.right
          pc.brake_anim_phase = true
          -- start with speed >= -ground_accel_frame2 + ground_decel_frame2 but still < ground_decel_frame2
          pc.ground_speed = 0.24
          pc.move_intention.x = -1
          pc:update_ground_run_speed_by_intention()
          assert.is_true(almost_eq_with_message(-0.01, pc.ground_speed, 1e-16))
        end)

        it('should decelerate and start moving to the left, and clamp to the max ground speed in the opposite sign '..
          'when character is facing right, has low ground speed > 0 and move intention x < 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.should_play_brake_start_anim = true
          -- start with speed < -ground_accel_frame2 + ground_decel_frame2
          pc.ground_speed = 0.12
          pc.move_intention.x = -1
          pc:update_ground_run_speed_by_intention()
          assert.are_equal(-pc_data.ground_accel_frame2, pc.ground_speed)
        end)

        it('should should set orientation to move intention dir (here, change orientation) and preserve brake_anim_phase when character decelerates to opposite sign but no brake anim started', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = pc_data.ground_decel_frame2 - pc_data.ground_accel_frame2
          pc.move_intention.x = -1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.left, 0}, {pc.orientation, pc.brake_anim_phase})
          assert.are_equal(0, pc.brake_anim_phase)
        end)

        it('should should set orientation to move intention dir (here, change orientation) and advance brake_anim_phase to 2 when character decelerates to opposite sign but and brake_start is playing', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = pc_data.ground_decel_frame2 - pc_data.ground_accel_frame2
          pc.move_intention.x = -1
          pc.brake_anim_phase = 1

          pc:update_ground_run_speed_by_intention()

          assert.are_equal(2, pc.brake_anim_phase)
        end)

        -- tests below seem symmetrical, but as a twist we have the character running backward (e.g. after a reverse jump)
        -- so he's facing the opposite direction of the run, so we can test direction update

        -- in addition, character faces ground speed dir again when brake_start anim is played,
        --  which can only be tested when running backward

        it('should decelerate keeping same sign when character is facing right, has mid ground speed < 0 but not abs higher than brake_anim_min_speed_frame and move intention x > 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -1.5
          pc.move_intention.x = 1
          pc:update_ground_run_speed_by_intention()
          assert.are_equal(-1.25, pc.ground_speed)
        end)

        it('should when character has ground speed = ground decel * 1 frame and move intention x < 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -pc_data.ground_decel_frame2
          pc.move_intention.x = 1
          pc:update_ground_run_speed_by_intention()
          assert.are_equal(0, pc.ground_speed)
        end)

        it('should decelerate and stop exactly at speed 0 when character has ground speed = ground decel * 1 frame and move intention x < 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -pc_data.ground_decel_frame2
          pc.move_intention.x = 1
          pc:update_ground_run_speed_by_intention()
          assert.are_equal(0, pc.ground_speed)
        end)

        it('should set orientation to move intention dir (here, no change) and preserve brake_anim_phase when character decelerates to 0 but no brake anim started', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -pc_data.ground_decel_frame2
          pc.move_intention.x = 1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 0}, {pc.orientation, pc.brake_anim_phase})
          assert.are_equal(0, pc.brake_anim_phase)
        end)

        it('should set orientation to move intention dir (here, no change) and advance brake_anim_phase to 2 when character decelerates to 0 and brake_start is playing', function ()
          -- in practice, this case doesn't happen, because if you were running backward and started brake anim
          --  by decelerating in the orientation dir, you must have changed dir to the ground speed dir when the brake anim
          --  started so the brake sprite could make sense, so we should be oriented left at this point
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -pc_data.ground_decel_frame2
          pc.move_intention.x = 1
          pc.brake_anim_phase = 1

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 2}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should decelerate and change sign when character has low ground speed < 0 and move intention x > 0 '..
          'but the ground speed is high enough so that the new speed wouldn\'t be over the max ground speed', function ()
          pc.orientation = horizontal_dirs.right
          -- start with speed <= ground_accel_frame2 - ground_decel_frame2
          pc.ground_speed = -0.24
          pc.move_intention.x = 1
          pc:update_ground_run_speed_by_intention()
          assert.are_equal(horizontal_dirs.right, pc.orientation)
          assert.is_true(almost_eq_with_message(0.01, pc.ground_speed, 1e-16))
        end)

        it('should decelerate and clamp to the max ground speed in the opposite sign '..
          'when character has low ground speed < 0 and move intention x > 0', function ()
          pc.orientation = horizontal_dirs.right
          -- start with speed > ground_accel_frame2 - ground_decel_frame2
          pc.ground_speed = -0.12
          pc.move_intention.x = 1
          pc:update_ground_run_speed_by_intention()
          assert.are_equal(pc_data.ground_accel_frame2, pc.ground_speed)
        end)

        it('should set orientation to move intention dir (here, no change) and preserve brake_anim_phase when character decelerates to opposite sign but no brake anim started', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -pc_data.ground_decel_frame2 + pc_data.ground_accel_frame2
          pc.move_intention.x = 1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 0}, {pc.orientation, pc.brake_anim_phase})
          assert.are_equal(0, pc.brake_anim_phase)
        end)

        it('should set orientation to move intention dir (here, no change) and advance brake_anim_phase to 2 when character decelerates to opposite sign and brake_start is playing', function ()
          -- in practice, this case doesn't happen, because if you were running backward and started brake anim
          --  by decelerating in the orientation dir, you must have changed dir to the ground speed dir when the brake anim
          --  started so the brake sprite could make sense, so we should be oriented left at this point
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -pc_data.ground_decel_frame2 + pc_data.ground_accel_frame2
          pc.move_intention.x = 1
          pc.brake_anim_phase = 1

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 2}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should preserve orientation and brake anim phase when quadrant down and abs ground speed is too low', function ()
          pc.quadrant = directions.down
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -pc_data.brake_anim_min_speed_frame + 0.01
          pc.move_intention.x = 1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 0}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should preserve orientation and brake anim phase when quadrant right and abs ground speed is high enough', function ()
          pc.quadrant = directions.right
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -pc_data.brake_anim_min_speed_frame
          pc.move_intention.x = 1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 0}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should set orientation to ground speed dir (here, change direction) and brake anim phase to 1 then play brake sfx when quadrant down and abs ground speed is high enough', function ()
          pc.quadrant = directions.down
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -pc_data.brake_anim_min_speed_frame
          pc.move_intention.x = 1
          pc.brake_anim_phase = 0

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.left, 1}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should apply friction and preserve direction when character has ground speed > 0 and move intention x is 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 1.5
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 1.5 - pc_data.ground_friction_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        it('should apply friction when character has ground speed > 0, move intention x is 0 and character is descending a low slope', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 1.5
          pc.slope_angle = 0.0625
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 1.5 - pc_data.ground_friction_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        it('should apply friction when character has ground speed > 0, move intention x is 0 and character is ascending a steep slope', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 1.5
          pc.slope_angle = 0.125
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 1.5 - pc_data.ground_friction_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        -- Original feature (not in SPG): No Friction on Steep Descending Slope

        it('should not apply friction when character has ground speed > 0, move intention x is 0 and character is descending a steep slope', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 1.5
          pc.slope_angle = 1-0.125
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 1.5},
            {pc.orientation, pc.ground_speed})
        end)

        -- End Original feature

        -- bugfix history: missing tests that check the change of sign of ground speed
        it('should apply friction and preserve direction but stop at 0 without changing ground speed sign when character has low ground speed > 0 and move intention x is 0', function ()
          pc.orientation = horizontal_dirs.right
          -- must be < friction
          pc.ground_speed = 0.01
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 0},
            {pc.orientation, pc.ground_speed})
        end)

        it('should reset brake_anim_phase from 1 to 0 when character has ground speed > 0, move intention x is 0 and animation has finished', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 0.01
          pc.brake_anim_phase = 1
          pc.anim_spr.playing = false

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 0}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should *not* reset brake_anim_phase from 1 to 0 when character has ground speed > 0 and move intention x is 0, but animation is still playing', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 0.01
          pc.brake_anim_phase = 2
          pc.anim_spr.playing = true

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 2}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should *not* reset brake_anim_phase from 2 to 0 when character has ground speed > 0 and move intention x is 0, even if animation has finished', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 0.01
          pc.brake_anim_phase = 2
          pc.anim_spr.playing = false

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 2}, {pc.orientation, pc.brake_anim_phase})
        end)

        -- tests below seem symmetrical, but the character is actually running backward

        it('should apply friction and preserve direction when character has ground speed < 0 and move intention x is 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -1.5
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, -1.5 + pc_data.ground_friction_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        -- bugfix history: missing tests that check the change of sign of ground speed
        it(' should apply friction but stop at 0 without changing ground speed sign when character has low ground speed < 0 and move intention x is 0', function ()
          pc.orientation = horizontal_dirs.right
          -- must be < friction in abs
          pc.ground_speed = -0.01
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 0},
            {pc.orientation, pc.ground_speed})
        end)

        -- in principle we should also check brake anim phases backward running + friction
        -- but there's not much extra change, even orientation simply doesn't change on friction

        it('should not change ground speed nor direction when ground speed is 0 and move intention x is 0', function ()
          pc.orientation = horizontal_dirs.left
          pc:update_ground_run_speed_by_intention()
          assert.are_same({horizontal_dirs.left, 0},
            {pc.orientation, pc.ground_speed})
        end)

        it('should preserve orientation and reset brake_anim_phase from 1 to 0 when character has ground speed 0, move intention x is 0 and animation has finished', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 0
          pc.brake_anim_phase = 1
          pc.anim_spr.playing = false

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 0}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should preserve orientation and *not* reset brake_anim_phase from 1 to 0 when character has ground speed 0 and move intention x is 0, but animation is still playing', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 0
          pc.brake_anim_phase = 2
          pc.anim_spr.playing = true

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 2}, {pc.orientation, pc.brake_anim_phase})
        end)

        it('should preserve orientation and *not* reset brake_anim_phase from 2 to 0 when character has ground speed 0 and move intention x is 0, even if animation has finished', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 0
          pc.brake_anim_phase = 2
          pc.anim_spr.playing = false

          pc:update_ground_run_speed_by_intention()

          assert.are_same({horizontal_dirs.right, 2}, {pc.orientation, pc.brake_anim_phase})
        end)

      end)  -- update_ground_run_speed_by_intention

      describe('update_ground_roll_speed_by_intention', function ()

        -- really, rolling applies friction at anytime, active deceleration or not
        -- so our tests are really split between two cases: just friction and decel + friction

        it('should apply friction only when ground speed > 0 and move intention x is 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 1.5
          pc.move_intention.x = 0
          pc:update_ground_roll_speed_by_intention()
          assert.are_equal(1.5 - pc_data.ground_roll_friction_frame2, pc.ground_speed)
        end)

        it('should apply friction only and *not* acceleration when ground speed > 0 and move intention x > 0', function ()
          pc.orientation = horizontal_dirs.left
          pc.ground_speed = -1.5
          pc.move_intention.x = -1
          pc:update_ground_roll_speed_by_intention()
          assert.are_equal(-1.5 + pc_data.ground_roll_friction_frame2, pc.ground_speed)
        end)

        it('should set orientation forward when ground speed > 0 and move intention x > 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -1.5
          pc.move_intention.x = -1
          pc:update_ground_roll_speed_by_intention()
          assert.are_equal(horizontal_dirs.left, pc.orientation)
        end)

        -- in general we do not need to check what happens when applying so much friction/deceleration that we are going to change sign,
        --  simply because when going below continue_roll_min_ground_speed Sonic will stand up at the end of the update
        --  (not here yet though), so it's unlikely he manages to change speed sign while still rolling by decelerating
        --  since he would have to lose 0.25 px/frame in a single frame, while roll decel is 0.0625
        -- however, because update_ground_speed_by_slope is called before, it's possibly in theory with a strong gravity and steep slope...
        --  so we just check that the safety check that blocks the speed at 0 is working
        -- in practice, it simply won't happen because even on a straight wall where gravity is applied at 100%, it's still lower than 0.25

        it('should decelerate and stop exactly at speed 0, preserving direction, when character has ground speed < friction in abs move intention x has opposite sign', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = pc_data.ground_roll_friction_frame2 / 2
          pc.move_intention.x = 0
          pc:update_ground_roll_speed_by_intention()
          assert.are_equal(0, pc.ground_speed)
        end)

        it('should decelerate *with friction added* keeping orientation when ground speed > 0 and move intention x < 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = 1.5
          pc.move_intention.x = -1
          pc:update_ground_roll_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 1.5 - pc_data.ground_roll_decel_frame2 - pc_data.ground_roll_friction_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        it('should decelerate *with friction added* keeping orientation when ground speed < 0 and move intention x > 0', function ()
          pc.orientation = horizontal_dirs.left
          pc.ground_speed = -1.5
          pc.move_intention.x = 1
          pc:update_ground_roll_speed_by_intention()
          assert.are_same({horizontal_dirs.left, -1.5 + pc_data.ground_roll_decel_frame2 + pc_data.ground_roll_friction_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        -- same remark as above, check clamping just for safety

        it('should decelerate and stop exactly at speed 0, preserving direction, when character has ground speed < (roll decel + friction) in abs and move intention x has opposite sign', function ()
          pc.orientation = horizontal_dirs.left
          pc.ground_speed = - (pc_data.ground_roll_friction_frame2 + pc_data.ground_roll_decel_frame2) / 2
          pc.move_intention.x = 1
          pc:update_ground_roll_speed_by_intention()
          assert.are_equal(0, pc.ground_speed)
        end)

        -- we do not check what happens when friction is applied so much that we are going to change sign,
        --  for the same reason as above for decel

        -- tests below seem symmetrical, but the character is actually running backward

        it('should apply friction and preserve direction when character has ground speed < 0 and move intention x is 0', function ()
          pc.orientation = horizontal_dirs.right
          pc.ground_speed = -1.5
          pc:update_ground_roll_speed_by_intention()
          assert.are_same({horizontal_dirs.right, -1.5 + pc_data.ground_roll_friction_frame2},
            {pc.orientation, pc.ground_speed})
        end)

        it(' should apply friction but stop at 0 without changing ground speed sign when character has low ground speed < 0 and move intention x is 0', function ()
          pc.orientation = horizontal_dirs.right
          -- must be < ground_roll_friction_frame2 in abs
          pc.ground_speed = -0.01
          pc:update_ground_roll_speed_by_intention()
          assert.are_same({horizontal_dirs.right, 0},
            {pc.orientation, pc.ground_speed})
        end)

      end)  -- update_ground_roll_speed_by_intention

      describe('clamp_ground_speed', function ()

        it('should preserve ground speed when it is not over max running speed in absolute value', function ()
          pc.ground_speed = pc_data.max_running_ground_speed - 0.1
          pc:clamp_ground_speed(0)
          assert.are_equal(pc_data.max_running_ground_speed - 0.1, pc.ground_speed)
        end)

        it('should clamp ground speed to signed max speed if over max running speed in absolute value, and previous speed was 0', function ()
          pc.ground_speed = pc_data.max_running_ground_speed + 1
          pc:clamp_ground_speed(0)
          assert.are_equal(pc_data.max_running_ground_speed, pc.ground_speed)
        end)

        it('should clamp ground speed to signed max speed if over max running speed in absolute value, and previous speed was also max running speed', function ()
          pc.ground_speed = pc_data.max_running_ground_speed + 1
          pc:clamp_ground_speed(pc_data.max_running_ground_speed)
          assert.are_equal(pc_data.max_running_ground_speed, pc.ground_speed)
        end)

        it('should clamp ground speed to previous speed in absolute value if previous speed was higher than max running speed in abs', function ()
          pc.ground_speed = pc_data.max_running_ground_speed + 2
          pc:clamp_ground_speed(pc_data.max_running_ground_speed + 1)
          assert.are_equal(pc_data.max_running_ground_speed + 1, pc.ground_speed)
        end)

        it('should allow decreasing ground speed in absolute value if previous speed was higher than max running speed in abs', function ()
          pc.ground_speed = pc_data.max_running_ground_speed + 5
          pc:clamp_ground_speed(pc_data.max_running_ground_speed + 10)
          assert.are_equal(pc_data.max_running_ground_speed + 5, pc.ground_speed)
        end)

      end)

      describe('compute_ground_motion_result', function ()

        describe('(when ground_speed is 0)', function ()

          -- bugfix history:
          --  + method was returning a tuple instead of a table
          it('should return the current ground tile location, position and slope, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 1)
            pc.position = vector(3, 4)
            pc.slope_angle = 0.125

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(3, 4),
                0.125,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('should preserve position subpixels if any', function ()
            pc.ground_tile_location = location(0, 1)
            pc.position = vector(3.5, 4)
            pc.slope_angle = 0.125

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(3.5, 4),
                0.125,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(wall right) should return the current position and slope, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 1)
            pc.position = vector(3, 4.5)
            pc.quadrant = directions.right
            pc.slope_angle = 0.25

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(3, 4.5),
                0.25,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(ceiling) should return the current position and slope, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 1)
            pc.position = vector(3, 4.5)
            pc.quadrant = directions.up
            pc.slope_angle = 0.5

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(3, 4.5),
                0.5,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(wall left) should return the current position and slope, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 1)
            pc.position = vector(3, 4.5)
            pc.quadrant = directions.left
            pc.slope_angle = 0.75

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(3, 4.5),
                0.75,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

        end)

        describe('(when _next_ground_step moves motion_result.position by 1px in the quadrant_horizontal_dir without blocking nor falling)', function ()

          local next_ground_step_mock

          setup(function ()
            next_ground_step_mock = stub(player_char, "next_ground_step", function (self, quadrant_horizontal_dir, motion_result)
              local step_vec = self:quadrant_rotated(horizontal_dir_vectors[quadrant_horizontal_dir])
              motion_result.position = motion_result.position + step_vec
              -- to simplify, we say the new tile location is where the new position is
              --  to be exact, it should be at the location of sensor closest to ground,
              --  which may be in a different location that center position, but easier for testing
              motion_result.tile_location = motion_result.position:to_location()
              motion_result.slope_angle = (world.quadrant_to_right_angle(self.quadrant) - 0.01) % 1
            end)
          end)

          teardown(function ()
            next_ground_step_mock:revert()
          end)

          -- bugfix history:
          -- +  failed because case where we add subpixels without reaching next full pixel didn't set slope_angle
          -- ?? failed I tried to fix it (see above), but actually subpixels should not be taken into account for ground slope detection
          it('(vector(3, 4) at speed 0.5) should return vector(3.5, 4), slope: 0, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.ground_speed = 0.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 0
            -- but as there is no blocking, the remaining subpixels will still be added

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(3.5, 4),
                0,                  -- character has not moved by a full pixel, so visible position and slope remains the same
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          -- bugfix history:
          -- ?? same reason as test above
          it('(vector(3, 4) at speed 1 on slope cos 0.5) should return vector(3.5, 4), is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.slope_angle = 1-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = 1  -- * slope cos = 0.5

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(3.5, 4),
                1-1/6,               -- character has not moved by a full pixel, so visible position and slope remains the same
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(3.5, 4) at speed 0.5) should return vector(0.5, 4), is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3.5, 4)
            pc.ground_speed = 0.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 1

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(4, 4),
                1-0.01,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(3, 4) at speed -2.5) should return vector(0.5, 4), is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.ground_speed = -2.5

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(0.5, 4),
                1-0.01,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(right wall, vector(3, 4) at speed 2 (going up) on slope cos 0.5) should return vector(3, 3), is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.quadrant = directions.right
            pc.slope_angle = 0.25-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = 2  -- * slope cos = 1

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(3, 3),
                0.25-0.01,               -- character has not moved by a full pixel, so visible position and slope remains the same
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(ceiling, vector(3, 4) at speed 2 (going up) on slope cos 0.5) should return vector(2, 4), is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.quadrant = directions.up
            pc.slope_angle = 0.5-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = 2  -- * slope cos = 1

            -- unfortunately native Lua has small calculation errors
            -- so we must check for almost equal on result position x
            local result = pc:compute_ground_motion_result()
            assert.is_true(almost_eq_with_message(2, result.position.x))

            -- then set that position to expected value and check the rest
            -- with an are_equal to cover all members
            result.position.x = 2
            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(2, 4),
                0.5-0.01,
                false,
                false
              ),
              result
            )
          end)

          it('(left wall, vector(3, 4) at speed 2 (going down) on slope cos 0.5) should return vector(3, 5), is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.quadrant = directions.left
            pc.slope_angle = 0.75-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = 2  -- * slope cos = 1

            -- unfortunately native Lua has small calculation errors
            -- so we must check for almost equal on result position y
            local result = pc:compute_ground_motion_result()
            assert.is_true(almost_eq_with_message(5, result.position.y))

            -- then set that position to expected value and check the rest
            -- with an are_equal to cover all members
            result.position.y = 5
            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(3, 5),
                0.75-0.01,
                false,
                false
              ),
              result
            )
          end)

        end)

        describe('(when _next_ground_step moves motion_result.position by 1px in the quadrant_quadrant_horizontal_dir, but blocks when motion_result.position.x < -4 (moving left) or x >= 5 (moving right) or y < -4 (moving up) or y >= 5 (moving down))', function ()

          local next_ground_step_mock

          setup(function ()
            next_ground_step_mock = stub(player_char, "next_ground_step", function (self, quadrant_horizontal_dir, motion_result)

              local step_vec = self:quadrant_rotated(horizontal_dir_vectors[quadrant_horizontal_dir])
              -- x/y < -4 <=> x/y <= -5 for an integer as passed to step functions,
              --   but we want to make clear that flooring is asymmetrical
              --   and that for floating coordinates, -4.01 is already hitting the left wall
              if motion_result.position.x < -4 and step_vec.x < 0 or motion_result.position.x >= 5 and step_vec.x > 0 or
                  motion_result.position.y < -4 and step_vec.y < 0 or motion_result.position.y >= 5 and step_vec.y > 0 then
                motion_result.is_blocked = true
              else
                motion_result.position = motion_result.position + step_vec
                -- to simplify, we say the new tile location is where the new position is
                motion_result.tile_location = motion_result.position:to_location()
                motion_result.slope_angle = (world.quadrant_to_right_angle(self.quadrant) + 0.01) % 1
              end
            end)
          end)

          teardown(function ()
            next_ground_step_mock:revert()
          end)

          it('(vector(3.5, 4) at speed 1.5) should return vector(5, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3.5, 4)
            pc.ground_speed = 1.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 2

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(5, 4),
                0.01,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(-3.5, 4) at speed -1.5) should return vector(-5, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(-1, 0)
            pc.position = vector(-3.5, 4)
            pc.ground_speed = -1.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 2

            assert.are_same(motion.ground_motion_result(
                location(-1, 0),
                vector(-5, 4),
                0.01,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          -- bugfix history: + the test revealed that is_blocked should be false when just touching a wall on arrival
          --  so I added a check to only check a wall on an extra column farther if there are subpixels left in motion
          it('(vector(4.5, 4) at speed 0.5) should return vector(5, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(4.5, 4)
            pc.ground_speed = 0.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 1

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(5, 4),
                0.01,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          -- the negative motion equivalent is not symmetrical due to flooring
          it('(vector(-4, 4) at speed -0.1) should return vector(-5, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(-1, 0)
            pc.position = vector(-4, 4)
            pc.ground_speed = -1
            -- we assume _compute_max_pixel_distance is correct, so it should return 1

            assert.are_same(motion.ground_motion_result(
                location(-1, 0),
                vector(-5, 4),
                0.01,
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          -- bugfix history: < replaced self.ground_speed with distance_x in are_subpixels_left evaluation
          it('(vector(4.5, 4) at speed 1 on slope cos 0.5) should return vector(5, 4), is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            -- this is the same as the test above (we just reach the wall edge without being blocked),
            -- but we make sure that are_subpixels_left check takes the slope factor into account
            pc.position = vector(4.5, 4)
            pc.slope_angle = 1-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = 1    -- * slope cos = -0.5

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(5, 4),
                0.01,  -- new slope angle, no relation with initial one
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          -- the negative motion equivalent is not symmetrical due to flooring
          -- in particular, to update the slope angle, we need to change of full pixel
          it('(vector(-4, 4) at speed -2 on slope cos 0.5) should return vector(-5, 4), is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(-1, 0)
            pc.position = vector(-4, 4)
            pc.slope_angle = 1-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = -2   -- * slope cos = -1

            assert.are_same(motion.ground_motion_result(
                location(-1, 0),
                vector(-5, 4),
                0.01,  -- new slope angle, no relation with initial one
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(4, 4) at speed 1.5) should return vector(5, 4), slope before blocked, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(4, 4)
            pc.ground_speed = 1.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 1
            -- the character will just touch the wall but because it has some extra subpixels
            --  going "into" the wall, we floor them and consider character as blocked
            --  (unlike Classic Sonic that would simply ignore subpixels)

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(5, 4),
                0.01,
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(-4, 4) at speed -1.5) should return vector(-5, 4), slope before blocked, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(-1, 0)
            pc.position = vector(-4, 4)
            pc.ground_speed = -1.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 1
            -- the character will just touch the wall but because it has some extra subpixels
            --  going "into" the wall, we floor them and consider character as blocked
            --  (unlike Classic Sonic that would simply ignore subpixels)

            assert.are_same(motion.ground_motion_result(
                location(-1, 0),
                vector(-5, 4),
                0.01,
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          -- bugfix history:
          -- ?? same reason as test far above where "character has not moved by a full pixel" so slope should not change
          it('(vector(4, 4) at speed 1.5 on slope cos 0.5) should return vector(4.75, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(4, 4)
            pc.slope_angle = 1-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = 1.5  -- * slope cos = 0.75
            -- this time, due to the slope cos, charaacter doesn't reach the wall and is not blocked

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(4.75, 4),
                1-1/6,               -- character has not moved by a full pixel, so visible position and slope remains the same
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(-4.1, 4) at speed -1.5 on slope cos 0.5) should return vector(-4.85, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            -- start under -4 so we don't change full pixel and preserve slope angle
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(-4.1, 4)
            pc.slope_angle = 1-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = -1.5  -- * slope cos = -0.75

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(-4.85, 4),
                1-1/6,               -- character has not moved by a full pixel, so visible position and slope remains the same
                false,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(4, 4) at speed 3 on slope cos 0.5) should return vector(5, 4), slope before blocked, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(4, 4)
            pc.slope_angle = 1-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = 3  -- * slope cos = 1.5
            -- but here, even with the slope cos, charaacter will hit wall

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(5, 4),
                0.01,
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(-4, 4) at speed 3 on slope cos 0.5) should return vector(-5, 4), slope before blocked, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(-1, 0)
            pc.position = vector(-4, 4)
            pc.slope_angle = 1-1/6  -- cos(-pi/3) = 1/2
            pc.ground_speed = -3  -- * slope cos = -1.5

            assert.are_same(motion.ground_motion_result(
                location(-1, 0),
                vector(-5, 4),
                0.01,
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          -- bugfix history:
          -- + it failed until I added the subpixels check at the end of the method
          --   (also fixed in v1: subpixel cut when max_column_distance is 0 and blocked on next column)
          it('(vector(5, 4) at speed 0.5) should return vector(5, 4), slope before moving, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(5, 4)
            pc.ground_speed = 0.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 0
            -- the character is already touching the wall, so any motion, even of just a few subpixels,
            --  is considered blocked

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(5, 4),
                0,  -- character couldn't move at all, so we preserved the initial slope angle
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(-5, 4) at speed 0.5) should return vector(-5, 4), slope before moving, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(-5, 4)
            pc.ground_speed = -0.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 0
            -- the character is already touching the wall, so any motion, even of just a few subpixels,
            --  is considered blocked

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(-5, 4),
                0,  -- character couldn't move at all, so we preserved the initial slope angle
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(5.5, 4) at speed 0.5) should return vector(5, 4), slope before moving, is_blocked: true, is_falling: false', function ()
            -- this is possible e.g. if character walked along 1.5 from x=4
            -- to reduce computation we didn't check an extra column for a wall
            --  at that time, but starting next frame we will, effectively clamping
            --  the character to x=5
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(5.5, 4)
            pc.ground_speed = 0.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 1
            -- but we will be blocked by the wall anyway

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(5, 4),  -- this works on the *right* thanks to subpixel cut working "inside" a wall
                0,  -- character couldn't move and went back, so we preserved the initial slope angle
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(-5.5, 4) at speed -0.5) should return vector(-6, 4), slope before moving, is_blocked: false, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(-5.5, 4)
            pc.ground_speed = -0.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 1
            -- but we will be blocked by the wall anyway

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(-6, 4),  -- we are already inside the wall, floored to -6
                0,  -- character only snap to floored x, so we preserved the slope angle
                false,  -- no wall detected from inside!
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(-5.5, 4) at speed -1) should return vector(-6, 4), slope before moving, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(-5.5, 4)
            pc.ground_speed = -1
            -- we assume _compute_max_pixel_distance is correct, so it should return 1
            -- but we will be blocked by the wall anyway

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(-6, 4),  -- we are already inside the wall, floored to -6
                0,  -- character only snap to floored x, so we preserved the slope angle
                true,  -- wall detected from inside if moving 1 full pixel toward the next column on the left
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(3, 4) at speed 3) should return vector(5, 4), slope before blocked, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.ground_speed = 3.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- but because of the blocking, we stop at x=5 instead of 6.5

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(5, 4),
                0.01,
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(-3, 4) at speed -3) should return vector(-5, 4), slope before blocked, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(-1, 0)
            pc.position = vector(-3, 4)
            pc.ground_speed = -3.5
            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- but because of the blocking, we stop at x=-5 instead of -6.5

            assert.are_same(motion.ground_motion_result(
                location(-1, 0),
                vector(-5, 4),
                0.01,
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(right wall, vector(3, -3) at speed 3 (moving up)) should return vector(3, -5), slope before blocked, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(0, -1)
            pc.position = vector(3, -3)
            pc.ground_speed = 3.5
            pc.quadrant = directions.right
            pc.slope_angle = 0.25

            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- but because of the blocking, we stop at y=-5 instead of -6.5

            assert.are_same(motion.ground_motion_result(
                location(0, -1),
                vector(3, -5),
                0.25 + 0.01,
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(ceiling, vector(-3, 3) at speed 3 (moving left)) should return vector(-5, 3), slope before blocked, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(-1, 0)
            pc.position = vector(-3, 3)
            pc.ground_speed = 3.5
            pc.quadrant = directions.up
            pc.slope_angle = 0.5

            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- but because of the blocking, we stop at x=-5 instead of -6.5

            assert.are_same(motion.ground_motion_result(
                location(-1, 0),
                vector(-5, 3),
                0.5 + 0.01,
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(left wall, vector(3, 3) at speed 3 (moving down)) should return vector(3, 5), slope before blocked, is_blocked: true, is_falling: false', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 3)
            pc.ground_speed = 3.5
            pc.quadrant = directions.left
            pc.slope_angle = 0.75

            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- but because of the blocking, we stop at y=5 instead of 6.5

            assert.are_same(motion.ground_motion_result(
                location(0, 0),
                vector(3, 5),
                0.75 + 0.01,
                true,
                false
              ),
              pc:compute_ground_motion_result()
            )
          end)

        end)

        -- bugfix history: the mock was wrong (was using updated position instead of original_position)
        describe('. (when _next_ground_step moves motion_result.position by 1px in the quadrant_horizontal_dir on x/y < 7, falls on 5 <= x/y < 7 and blocks on x/y >= 7 with x/y matching step direction)', function ()

          local next_ground_step_mock

          setup(function ()
            next_ground_step_mock = stub(player_char, "next_ground_step", function (self, quadrant_horizontal_dir, motion_result)
              local step_vec = self:quadrant_rotated(horizontal_dir_vectors[quadrant_horizontal_dir])
              local original_position = motion_result.position
              -- quadrant_rotated busted implementation has perfect precision, so don't worry about checking ~= 0
              if step_vec.x ~= 0 then
                if original_position.x < 7 then
                  motion_result.position = original_position + step_vec
                  motion_result.slope_angle = 0.25
                end
                if original_position.x >= 5 then
                  if original_position.x < 7 then
                    motion_result.is_falling = true
                    motion_result.slope_angle = nil  -- mimic actual implementation
                  else
                    motion_result.is_blocked = true
                  end
                end
              else  -- moving on y (quadrant is left or right)
                if original_position.y < 7 then
                  motion_result.position = original_position + step_vec
                  motion_result.slope_angle = 0.25
                end
                if original_position.y >= 5 then
                  if original_position.y < 7 then
                    motion_result.is_falling = true
                    motion_result.slope_angle = nil  -- mimic actual implementation
                  else
                    motion_result.is_blocked = true
                  end
                end
              end

              if motion_result.is_falling then
                -- falling, no tile should be set (or we'll assert in ground_motion_result:init!)
                motion_result.tile_location = nil
              else
                -- to simplify, we say the new tile location is where the new position is
                -- normally we only *modify* tile_location when there is actually some motion
                --  but result is the same as long as the initial tile location matched the position
                motion_result.tile_location = motion_result.position:to_location()
              end
            end)
          end)

          teardown(function ()
            next_ground_step_mock:revert()
          end)

          it('(vector(3, 4) at speed 3) should return nil, vector(6, 4), slope_angle: nil, is_blocked: false, is_falling: true', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.ground_speed = 3
            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- we are falling but not blocked, so we continue running in the air until x=6

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(6, 4),
                nil,
                false,
                true
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(vector(3, 4) at speed 5) should return nil, vector(7, 4), slope_angle: nil, is_blocked: true, is_falling: true', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.ground_speed = 5
            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- we are falling then blocked on 7

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(7, 4),
                nil,
                true,
                true
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(right wall, vector(4, 3) at speed -3 (moving down)) should return nil, vector(4, 6), slope_angle: nil, is_blocked: false, is_falling: true', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(4, 3)
            pc.ground_speed = -3
            pc.quadrant = directions.right
            pc.slope_angle = 0.25

            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- we are falling but not blocked, so we continue running in the air until y=6

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(4, 6),
                nil,
                false,
                true
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(right wall, vector(4, 3) at speed -5 (moving down)) should return nil, vector(7, 4), slope_angle: nil, is_blocked: true, is_falling: true', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(4, 3)
            pc.ground_speed = -5
            pc.quadrant = directions.right
            pc.slope_angle = 0.25

            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- we are falling then blocked on 7

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(4, 7),
                nil,
                true,
                true
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(ceiling, vector(3, 4) at speed -3 (moving right)) should return nil, vector(4, 6), slope_angle: nil, is_blocked: false, is_falling: true', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.ground_speed = -3
            pc.quadrant = directions.up
            pc.slope_angle = 0.5

            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- we are falling but not blocked, so we continue running in the air until x=6

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(6, 4),
                nil,
                false,
                true
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(ceiling, vector(3, 4) at speed -5 (moving right)) should return nil, vector(7, 4), slope_angle: nil, is_blocked: true, is_falling: true', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(3, 4)
            pc.ground_speed = -5
            pc.quadrant = directions.up
            pc.slope_angle = 0.5

            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- we are falling then blocked on 7

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(7, 4),
                nil,
                true,
                true
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(left wall, vector(4, 3) at speed 3 (moving down)) should return nil, vector(4, 6), slope_angle: nil, is_blocked: false, is_falling: true', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(4, 3)
            pc.ground_speed = 3
            pc.quadrant = directions.left
            pc.slope_angle = 0.75

            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- we are falling but not blocked, so we continue running in the air until y=6

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(4, 6),
                nil,
                false,
                true
              ),
              pc:compute_ground_motion_result()
            )
          end)

          it('(left wall, vector(4, 3) at speed 5 (moving down)) should return nil, vector(7, 4), slope_angle: nil, is_blocked: true, is_falling: true', function ()
            pc.ground_tile_location = location(0, 0)
            pc.position = vector(4, 3)
            pc.ground_speed = 5
            pc.quadrant = directions.left
            pc.slope_angle = 0.75

            -- we assume _compute_max_pixel_distance is correct, so it should return 3
            -- we are falling then blocked on 7

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(4, 7),
                nil,
                true,
                true
              ),
              pc:compute_ground_motion_result()
            )
          end)

        end)

      end)  -- _compute_ground_motion_result

      describe('next_ground_step', function ()

        -- for these utests, we assume that _compute_ground_sensors_query_info and
        --  _is_blocked_by_ceiling are correct,
        --  so rather than mocking them, so we setup simple tiles to walk on

        describe('(with flat ground)', function ()

          before_each(function ()
            -- .
            -- #
            mock_mset(0, 1, tile_repr.full_tile_id)  -- full tile
          end)

          -- in the tests below, we can use pc_data.center_height_standing directly instead
          --  of pc:get_center_height()
          --  because the character is not compact (e.g. no air spin)

          it('when stepping left with the right sensor still on the ground, decrement x', function ()
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(-1, 8 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step flat
            pc:next_ground_step(horizontal_dirs.left, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(-2, 8 - pc_data.center_height_standing),
                0,
                false,
                false
              ),
              motion_result
            )
          end)

          it('when stepping right with the left sensor still on the ground, increment x', function ()
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(9, 8 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step flat
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(10, 8 - pc_data.center_height_standing),
                0,
                false,
                false
              ),
              motion_result
            )
          end)

          it('when stepping left leaving the ground, decrement x and fall', function ()
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(-2, 8 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step fall
            pc:next_ground_step(horizontal_dirs.left, motion_result)

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(-3, 8 - pc_data.center_height_standing),
                nil,
                false,
                true
              ),
              motion_result
            )
          end)

          it('when stepping right leaving the ground, increment x and fall', function ()
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(10, 8 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step fall
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(11, 8 - pc_data.center_height_standing),
                nil,
                false,
                true
              ),
              motion_result
            )
          end)

          -- this behaviour changed with #132, we don't step down after falling when just touching ground
          it('when stepping right after fall but just touching ground, increment x but do not cancel fall', function ()
            local motion_result = motion.ground_motion_result(
              nil,
              vector(-3, 8 - pc_data.center_height_standing),
              nil,
              false,
              true
            )

            -- step land (very rare)
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(-2, 8 - pc_data.center_height_standing),
                nil,
                false,
                true  -- still falling
              ),
              motion_result
            )
          end)

          -- we still wanted to test the case where character lands back on ground (what happened
          --  above before #132 fix), but we need to place another tile just high enough so step
          --  gets at least 1px inside ground... a bit cumbersome, so we cheat and assume character
          --  is 1px lower from the start (although impossible as it should have left ground),
          --  so character steps up
          it('when stepping right back on the ground, increment x and cancel fall', function ()
            local motion_result = motion.ground_motion_result(
              nil,
              vector(-3, 9 - pc_data.center_height_standing),
              nil,
              false,
              true
            )

            -- step land (very rare)
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(-2, 8 - pc_data.center_height_standing),  -- go up 1px to step up ground again
                0,
                false,
                false  -- landed back after a step falling
              ),
              motion_result
            )
          end)

          -- for other quadrants we only test the most common cases

          it('(right wall) when stepping q-right (up) with the q-left sensor still on the ground, DEcrement y', function ()
            pc.quadrant = directions.right
            pc.slope_angle = 0.25

            -- remember to place the character on the left of the tile at (0, 1) as if walking on its left side
            -- this means the center offset should be subtracted from X this time
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(0 - pc_data.center_height_standing, 12),
              0,
              false,
              false
            )

            -- step flat
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(0 - pc_data.center_height_standing, 11),
                0.25,
                false,
                false
              ),
              motion_result
            )
          end)

          it('(right wall) when stepping q-right (up) with the q-left sensor leaving the ground, DEcrement y and fall', function ()
            pc.quadrant = directions.right
            pc.slope_angle = 0.25

            -- remember to place the character on the left of the tile at (0, 1) as if walking on its left side
            -- this means the center offset should be subtracted from X this time
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(0 - pc_data.center_height_standing, 6),
              0,
              false,
              false
            )

            -- step fall
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(0 - pc_data.center_height_standing, 5),
                nil,
                false,
                true
              ),
              motion_result
            )
          end)

          it('(ceiling) when stepping q-right (left) with the q-left sensor still on the ground, DEcrement x', function ()
            pc.quadrant = directions.up
            pc.slope_angle = 0.25

            -- remember to place the character on the left of the tile at (0, 1) as if walking on its left side
            -- this means the center offset should be subtracted from X this time
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(-1, 16 + pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step flat
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(-2, 16 + pc_data.center_height_standing),
                0.5,
                false,
                false
              ),
              motion_result
            )
          end)

          it('(ceiling) when stepping q-right (left) with the q-left sensor leaving the ground, DEcrement x and fall', function ()
            pc.quadrant = directions.up
            pc.slope_angle = 0.25

            -- remember to place the character on the left of the tile at (0, 1) as if walking on its left side
            -- this means the center offset should be subtracted from X this time
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(-2, 16 + pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step fall
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(-3, 16 + pc_data.center_height_standing),
                nil,
                false,
                true
              ),
              motion_result
            )
          end)

          it('(left wall) when stepping q-right (down) with the q-left sensor still on the ground, INcrement y', function ()
            pc.quadrant = directions.left
            pc.slope_angle = 0.75

            -- remember to place the character on the left of the tile at (0, 1) as if walking on its left side
            -- this means the center offset should be subtracted from X this time
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(8 + pc_data.center_height_standing, 15),
              0.75,
              false,
              false
            )

            -- step flat
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(8 + pc_data.center_height_standing, 16),
                0.75,
                false,
                false
              ),
              motion_result
            )
          end)

          it('(left wall) when stepping q-right (down) with the q-left sensor leaving the ground, INcrement y and fall', function ()
            pc.quadrant = directions.left
            pc.slope_angle = 0.75

            -- remember to place the character on the left of the tile at (0, 1) as if walking on its left side
            -- this means the center offset should be subtracted from X this time
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(0 - pc_data.center_height_standing, 16),
              0,
              false,
              false
            )

            -- step fall
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(0 - pc_data.center_height_standing, 17),
                nil,
                false,
                true
              ),
              motion_result
            )
          end)

        end)

        describe('(with walls)', function ()

          before_each(function ()
            -- # #
            -- ###
            mock_mset(0, 0, tile_repr.full_tile_id)  -- full tile (left wall)
            mock_mset(0, 1, tile_repr.full_tile_id)  -- full tile
            mock_mset(1, 1, tile_repr.full_tile_id)  -- full tile
            mock_mset(2, 0, tile_repr.full_tile_id)  -- full tile
            mock_mset(2, 1, tile_repr.full_tile_id)  -- full tile (right wall)
          end)

          it('when stepping left and hitting the wall, preserve x and block', function ()
            local motion_result = motion.ground_motion_result(
              location(1, 1),
              vector(11, 8 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step block
            pc:next_ground_step(horizontal_dirs.left, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(1, 1),
                vector(11, 8 - pc_data.center_height_standing),
                0,
                true,
                false
              ),
              motion_result
            )
          end)

          it('when stepping right and hitting the wall, preserve x and block', function ()
            local motion_result = motion.ground_motion_result(
              location(1, 1),
              vector(13, 8 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step block
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(1, 1),
                vector(13, 8 - pc_data.center_height_standing),
                0,
                true,
                false
              ),
              motion_result
            )
          end)

        end)

        describe('(with wall without ground below)', function ()

          before_each(function ()
            --  #
            -- #
            mock_mset(0, 1, tile_repr.full_tile_id)  -- full tile (ground)
            mock_mset(1, 0, tile_repr.full_tile_id)  -- full tile (wall without ground below)
          end)

          -- it will fail until compute_closest_ground_query_info
          --  detects upper-level tiles as suggested in the note
          it('when stepping right on the ground and hitting the non-supported wall, preserve x and block', function ()
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(5, 8 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step block
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(5, 8 - pc_data.center_height_standing),
                0,
                true,
                false
              ),
              motion_result
            )
          end)

        end)

        describe('(with head wall)', function ()

          before_each(function ()
            --  #
            -- =
            mock_mset(0, 1, tile_repr.half_tile_id)  -- bottom half-tile
            mock_mset(1, 0, tile_repr.full_tile_id)  -- full tile (head wall)
          end)

          -- it will fail until compute_closest_ground_query_info
          --  detects upper-level tiles as suggested in the note
          it('when stepping right on the half-tile and hitting the head wall, preserve x and block', function ()
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(5, 12 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step block
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(0, 1),
                vector(5, 12 - pc_data.center_height_standing),
                0,
                true,
                false
              ),
              motion_result
            )
          end)

        end)

        -- added to test fix #132 BUG MOTION/VISUAL running from flat to steep descending slope causes glitch
        describe('(with steepest curve then flat ground)', function ()

          before_each(function ()
            -- ..
            -- i#
            mock_mset(0, 1, tile_repr.visual_loop_bottomright_steepest)
            mock_mset(1, 1, tile_repr.full_tile_id)
          end)

          -- case: step fall due to angle
          it('when stepping from flat ground onto very steep descending ground, angle diff is enough to still fall', function ()
            local motion_result = motion.ground_motion_result(
              location(1, 1),
              vector(6, 8 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step to left "onto" curve (actually above)
            pc:next_ground_step(horizontal_dirs.left, motion_result)

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(5, 8 - pc_data.center_height_standing),
                nil,
                false,
                true  -- now falling
              ),
              motion_result
            )
          end)

        end)

        -- added after fixing #132 as I noticed my angle comparison was incorrect when one angle was above 0, and the other just below 0 (~0.9)
        -- it was fixed by using the new compute_signed_angle_between
        describe('(with steepest curve then flat ground)', function ()

          before_each(function ()
            -- >-
            mock_mset(0, 0, tile_repr.desc_slope_2px_id)
            mock_mset(1, 0, tile_repr.flat_high_tile_id)
          end)

          -- case: no step fall as angle difference is small
          it('when stepping from low descending ground onto flat ground, angle diff is not enough to fall', function ()
            local motion_result = motion.ground_motion_result(
              location(0, 0),
              -- > tile last column has height 6, so gap of 2
              vector(10, 2 - pc_data.center_height_standing),
              atan2(8, 2),
              false,
              false
            )

            -- step to right onto flat high tile
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(1, 0),
                vector(11, 2 - pc_data.center_height_standing),
                0,
                false,
                false  -- still grounded
              ),
              motion_result
            )
          end)

        end)

        -- bugfix history:
        -- = itest of player running on flat ground when ascending a slope showed that when removing supporting ground,
        --   character would be blocked at the bottom of the slope, so I isolated just that part into a utest
        describe('(with non-supported ascending slope)', function ()

          before_each(function ()
            --  /
            -- #
            mock_mset(0, 1, tile_repr.full_tile_id)  -- full tile (ground)
            mock_mset(1, 0, tile_repr.asc_slope_45_id)  -- ascending slope 45
          end)

          it('when stepping right from the bottom of the ascending slope, increment x and adjust y', function ()
            local motion_result = motion.ground_motion_result(
              location(0, 1),
              vector(5, 8 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            -- step down
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(1, 0),
                vector(6, 7 - pc_data.center_height_standing),
                45/360,
                false,
                false
              ),
              motion_result
            )
          end)

        end)

        describe('(with ascending slope and wall)', function ()

          before_each(function ()
            -- # #
            -- #/#
            mock_mset(0, 0, tile_repr.full_tile_id)  -- full tile (high wall, needed to block motion to the left as right sensor makes the character quite high on the slope)
            mock_mset(0, 1, tile_repr.full_tile_id)  -- full tile (wall)
            mock_mset(1, 1, tile_repr.asc_slope_45_id)  -- ascending slope 45
            mock_mset(2, 0, tile_repr.full_tile_id)  -- full tile (wall)
          end)

          it('when stepping left on the ascending slope without leaving the ground, decrement x and adjust y', function ()
            local motion_result = motion.ground_motion_result(
              location(1, 1),
              vector(12, 9 - pc_data.center_height_standing),
              45/360,
              false,
              false
            )

            -- step down
            pc:next_ground_step(horizontal_dirs.left, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(1, 1),
                vector(11, 10 - pc_data.center_height_standing),
                45/360,
                false,
                false
              ),
              motion_result
            )
          end)

          -- case: after step fall, we are close to ground again but not inside yet
          -- This variant was added after testing case #132: initial utest passed, but during
          --  actual gameplay, the character sometimes relanded immediately on the slope after taking off,
          --  defeating the feature.
          -- But for the unit test we don't need such a complex scenario, any ground will do.
          it('when already falling from previous step, do not step down', function ()
            local motion_result = motion.ground_motion_result(
              nil,  -- no ground
              vector(12, 9 - pc_data.center_height_standing),
              nil,  -- no ground, so no angle
              false,
              true  -- previously falling
            )

            -- step down
            pc:next_ground_step(horizontal_dirs.left, motion_result)

            assert.are_same(motion.ground_motion_result(
                nil,
                vector(11, 9 - pc_data.center_height_standing),  -- don't step down, so keep Y
                nil,
                false,
                true  -- still falling
              ),
              motion_result
            )
          end)

          it('when stepping right on the ascending slope without leaving the ground, decrement x and adjust y', function ()
            local motion_result = motion.ground_motion_result(
              location(1, 1),
              vector(12, 9 - pc_data.center_height_standing),
              45/360,
              false,
              false
            )

            -- step up
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(1, 1),
                vector(13, 8 - pc_data.center_height_standing),
                45/360,
                false,
                false
              ),
              motion_result
            )
          end)

          it('when stepping right on the ascending slope and hitting the right wall, preserve x and y and block', function ()
            local motion_result = motion.ground_motion_result(
              location(1, 1),
              vector(13, 10 - pc_data.center_height_standing),
              -45/360,
              false,
              false
            )

            -- step up blocked
            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(1, 1),
                vector(13, 10 - pc_data.center_height_standing),
                -45/360,
                true,
                false
              ),
              motion_result
            )
          end)

          it('when stepping left on the ascending slope and hitting the left wall, preserve x and y and block', function ()
            local motion_result = motion.ground_motion_result(
              location(1, 1),
              vector(11, 10 - pc_data.center_height_standing),
              -45/360,
              false,
              false
            )

            -- step down blocked
            pc:next_ground_step(horizontal_dirs.left, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(1, 1),
                vector(11, 10 - pc_data.center_height_standing),
                -45/360,
                true,
                false
              ),
              motion_result
            )
          end)

        end)

        describe('(with two tiles in a row)', function ()

          before_each(function ()
            -- ##
            mock_mset(0, 0, tile_repr.full_tile_id)
            mock_mset(1, 0, tile_repr.full_tile_id)
          end)

          it('when stepping right on a new tile, increment x and update tile location to new tile', function ()
            local motion_result = motion.ground_motion_result(
              location(0, 0),
              vector(5, 0 - pc_data.center_height_standing),
              0,
              false,
              false
            )

            pc:next_ground_step(horizontal_dirs.right, motion_result)

            assert.are_same(motion.ground_motion_result(
                location(1, 0),
                vector(6, 0 - pc_data.center_height_standing),
                0,
                false,
                false
              ),
              motion_result
            )
          end)

        end)

      end)  -- _next_ground_step

      describe('is_blocked_by_ceiling_at', function ()

        local get_ground_sensor_position_from_mock
        local compute_closest_ceiling_query_info_mock

        setup(function ()
          get_ground_sensor_position_from_mock = stub(player_char, "get_ground_sensor_position_from", function (self, center_position, i)
            return i == horizontal_dirs.left and vector(-1, center_position.y) or vector(1, center_position.y)
          end)

          compute_closest_ceiling_query_info_mock = stub(player_char, "compute_closest_ceiling_query_info", function (self, sensor_position)
            -- simulate ceiling detection by encoding information in x and y
            -- no particular realism in the returned values
            -- remember that 0 <=> touching <=> not blocked
            local signed_distance
            if sensor_position.y == 1 then
              signed_distance = pc_data.max_ground_snap_height + 1 -- to test no collider found, not even touch
            elseif sensor_position.y == 2 then
              signed_distance = sensor_position.x < 0 and -1 or 0  -- left sensor detects inside ceiling, right only touch
            elseif sensor_position.y == 3 then
              signed_distance = sensor_position.x < 0 and 0 or -1  -- right sensor detects inside ceiling, left only touch
            else
              signed_distance = sensor_position.x < 0 and -1 or -1 -- both sensors detect inside ceiling
            end
            if signed_distance <= 0 then
              return ground_query_info(location(0, 0), signed_distance, 0.5)
            else
              return ground_query_info(nil, signed_distance, nil)
            end
          end)
        end)

        teardown(function ()
          get_ground_sensor_position_from_mock:revert()
          compute_closest_ceiling_query_info_mock:revert()
        end)

        it('should return false when both sensors detect no near ceiling', function ()
          assert.is_false(pc:is_blocked_by_ceiling_at(vector(0, 1)))
        end)

        it('should return true when left sensor detects near ceiling', function ()
          assert.is_true(pc:is_blocked_by_ceiling_at(vector(0, 2)))
        end)

        it('should return true when right sensor detects no near ceiling', function ()
          assert.is_true(pc:is_blocked_by_ceiling_at(vector(0, 3)))
        end)

        it('should return true when both sensors detect near ceiling', function ()
          assert.is_true(pc:is_blocked_by_ceiling_at(vector(0, 4)))
        end)

      end)  -- _is_blocked_by_ceiling_at

      describe('compute_closest_ceiling_query_info', function ()

        setup(function ()
          stub(player_char, "get_full_height", function ()
            return 16
          end)
        end)

        teardown(function ()
          player_char.get_full_height:revert()
        end)

        describe('no tiles)', function ()

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) everywhere', function ()
            assert.are_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(4, 5)))
          end)

        end)

        describe('(1 full tile)', function ()

          before_each(function ()
            -- .#
            mock_mset(1, 0, tile_repr.full_tile_id)  -- full tile (act like a full ceiling if position is at bottom)
          end)

          it('should return ground_query_info(location(1, 0), - character height - 0.1, 0.5) for sensor position just above the bottom-center of the tile', function ()
            -- with new implementation, we check tile even at foot level
            -- remember that we are detection ceiling so quadrant is up, and angle is 0.5 (180 deg)
            assert.are_same(ground_query_info(location(1, 0), -16.1, 0.5), pc:compute_closest_ceiling_query_info(vector(12, 7.9)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for sensor position on the left of the tile', function ()
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(7, 8)))
          end)

          -- bugfix history:
          --  ? i thought that by design, function should return true but realized it was not consistent
          --  ? actually I was right, since if the character moves inside the 2nd of a diagonal tile pattern,
          --    it *must* be blocked. when character has a foot on the lower tile, it is considered to be
          --    in this lower tile
          it('should return ground_query_info(location(1, 0), -character height, 0.5) for sensor position at the bottom-left of the tile', function ()
            assert.is_same(ground_query_info(location(1, 0), -16, 0.5), pc:compute_closest_ceiling_query_info(vector(8, 8)))
          end)

          it('should return ground_query_info(location(1, 0), -character height, 0.5) for sensor position on the bottom-right of the tile', function ()
            assert.is_same(ground_query_info(location(1, 0), -16, 0.5), pc:compute_closest_ceiling_query_info(vector(15, 8)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for sensor position on the right of the tile', function ()
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(16, 8)))
          end)

          it('should return ground_query_info(location(1, 0), -1, 0.5) for sensor position below the tile, at character height - 1px', function ()
            assert.is_same(ground_query_info(location(1, 0), -1, 0.5), pc:compute_closest_ceiling_query_info(vector(12, 8 + 16 - 1)))
          end)

          -- bugfix history:
          --  < i realized that values of full_height_standing < 8 would fail the test
          --    so i moved the height_distance >= pc_data.full_height_standing check above
          --    the ground_array_height check (computing height_distance from tile bottom instead of top)
          --    to pass it in this case too
          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for sensor position below the tile, at character height', function ()
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(12, 8 + 16)))
          end)

        end)

        describe('(1 half-tile)', function ()

          before_each(function ()
            -- =
            mock_mset(0, 0, tile_repr.half_tile_id)
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for sensor position in the middle of the tile', function ()
            -- we now start checking ceiling a few pixels q-above character feet
            --  and ignore reverse full height on same tile as sensor, so slope not detected as ceiling
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(4, 6)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for sensor position at the bottom of the tile', function ()
            -- here we don't detect a ceiling because y = 8 is considered belonging to
            --  tile j = 1, but we define ignore_reverse = start_tile_loc == curr_tile_loc
            --  not ignore_reverse = curr_tile_loc == curr_tile_loc
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(4, 8)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for sensor position 2 px below tile (so that 4px above is inside tile)', function ()
            -- this test makes sure that we ignore reverse full height for start tile
            --  *not* sensor tile, which is different when sensor is less than 4px of the neighboring tile
            --  in iteration direction
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(4, 10)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for quadrant left, offset sensor position (head) 1 px q-outside tile', function ()
            pc.quadrant = directions.left
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(-17, 4)))
          end)

          it('should return ground_query_info(location(0, 0), 0, 0.25) for quadrant left, offset sensor position (head) just touching left of tile', function ()
            pc.quadrant = directions.left
            assert.is_same(ground_query_info(location(0, 0), 0, 0.25), pc:compute_closest_ceiling_query_info(vector(-16, 4)))
          end)

          it('should return ground_query_info(location(0, 0), - 1, 0.25) for quadrant left, offset sensor position (head) 1 px reverse-q(right)-inside tile', function ()
            pc.quadrant = directions.left
            assert.is_same(ground_query_info(location(0, 0), -1, 0.25), pc:compute_closest_ceiling_query_info(vector(-15, 4)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for quadrant right, when 4 px to the left is outside tile', function ()
            pc.quadrant = directions.right
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(4, 4)))
          end)

          it('should return ground_query_info(location(0, 0), -character height - 2, 0.5) for quadrant right, offset sensor position (head) 2 px reverse-q(left)-inside tile', function ()
            -- this test makes sure that we do *not* ignore reverse full height for initial tile if
            --  that are full horizontal rectangle (see world.compute_qcolumn_height_at)
            --  since slope_angle_to_interiors has a bias 0 -> right so onceiling check,
            --  we check on left which is reverse of tile interior_h
            --  (if bias was for left, then the test above would check this instead)
            pc.quadrant = directions.right
            -- note that we also detect ceiling on (5, 4) although it is symmetrical to the (3, 4)
            --  test for quadrant left, due to the fact that pixel x = 0 is considered still in tile i = 0
            -- we can fix the disymmetry with some .5 pixel extent in qy in both ground distance and ceiling check
            --  (as in the qx direction with ground sensor extent) but we don't mind since Classic Sonic itself
            --  has an odd size collider in reality
            assert.is_same(ground_query_info(location(0, 0), -18, 0.75), pc:compute_closest_ceiling_query_info(vector(6, 4)))
          end)

        end)

        describe('(1 ascending slope 45)', function ()

          before_each(function ()
            -- /
            mock_mset(0, 0, tile_repr.asc_slope_45_id)
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for sensor position on the left of the tile', function ()
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(0, 7)))
          end)

          it('should return ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil) for sensor position at the bottom-left of the tile', function ()
            -- we now start checking ceiling a few pixels q-above character feet, so slope not detected as ceiling
            assert.is_same(ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil), pc:compute_closest_ceiling_query_info(vector(0, 8)))
          end)

        end)

      end)  -- _compute_closest_ceiling_query_info

      describe('check_jump_intention', function ()

        it('should do nothing when jump_intention is false', function ()
          pc:check_jump_intention()
          assert.are_same({false, false}, {pc.jump_intention, pc.should_jump})
        end)

        it('should consume jump_intention and set should_jump to true if jump_intention is true', function ()
          pc.jump_intention = true
          pc:check_jump_intention()
          assert.are_same({false, true}, {pc.jump_intention, pc.should_jump})
        end)

      end)

      describe('check_jump', function ()

        setup(function ()
          stub(player_char, "play_low_priority_sfx")
        end)

        teardown(function ()
          player_char.play_low_priority_sfx:revert()
        end)

        after_each(function ()
          player_char.play_low_priority_sfx:clear()
        end)

        it('should not set jump members and return false when should_jump is false', function ()
          pc.velocity = vector(4.1, -1)
          local result = pc:check_jump()

          -- interface
          assert.are_same({false, vector(4.1, -1), motion_states.standing, false, false}, {result, pc.velocity, pc.motion_state, pc.has_jumped_this_frame, pc.can_interrupt_jump})
        end)

        it('should consume should_jump, add initial var jump velocity, update motion state, set has_jumped_this_frame amd can_interrupt_jump flags and return true when should_jump is true', function ()
          pc.velocity = vector(4.1, -1)
          pc.should_jump = true
          local result = pc:check_jump()

          -- interface
          assert.are_same({true, vector(4.1, -4.25), motion_states.air_spin, true, true}, {result, pc.velocity, pc.motion_state, pc.has_jumped_this_frame, pc.can_interrupt_jump})
        end)

        it('should add impulse along ground normal when slope_angle is not 0 (and we should jump)', function ()
          pc.velocity = vector(2, -2)
          pc.should_jump = true
          pc.slope_angle = 0.125

          pc:check_jump()

          assert.is_true(almost_eq_with_message(2 - pc_data.initial_var_jump_speed_frame / sqrt(2), pc.velocity.x))
          assert.is_true(almost_eq_with_message(-2 - pc_data.initial_var_jump_speed_frame / sqrt(2), pc.velocity.y))
        end)

        it('should play jump low priority sfx when character should jump', function ()
          pc.should_jump = true

          pc:check_jump()

          assert.spy(player_char.play_low_priority_sfx).was_called(1)
          assert.spy(player_char.play_low_priority_sfx).was_called_with(match.ref(pc), audio.sfx_ids.jump)
        end)

      end)

      describe('update_platformer_motion_airborne', function ()

        setup(function ()
          spy.on(player_char, "enter_motion_state")
          spy.on(player_char, "check_hold_jump")
          -- trigger check inside set_ground_tile_location will fail as it needs context
          -- (tile_test_data + mset), so we prefer stubbing as we don't check ground_tile_location directly
          stub(player_char, "set_ground_tile_location")
          spy.on(player_char, "set_slope_angle_with_quadrant")
        end)

        teardown(function ()
          player_char.enter_motion_state:revert()
          player_char.check_hold_jump:revert()
          player_char.set_ground_tile_location:revert()
          player_char.set_slope_angle_with_quadrant:revert()
        end)

        before_each(function ()
          -- optional, just to enter an airborne state and be in a meaningful state in this context
          pc:enter_motion_state(motion_states.falling)
          -- clear spy just after this instead of after_each to avoid messing the call count
          player_char.enter_motion_state:clear()
          player_char.check_hold_jump:clear()
          player_char.set_ground_tile_location:clear()
          player_char.set_slope_angle_with_quadrant:clear()
        end)

        describe('(when _compute_air_motion_result returns a motion result with position vector(2, 8), is_blocked_by_ceiling: false, is_blocked_by_wall: false, is_landing: false)', function ()

          setup(function ()
            compute_air_motion_result_mock = stub(player_char, "compute_air_motion_result", function (self)
              return motion.air_motion_result(
                nil,
                vector(4, 8),  -- make sure it's far enough from stage left edge to avoid soft clamping
                false,
                false,
                false,
                nil
              )
            end)
          end)

          teardown(function ()
            compute_air_motion_result_mock:revert()
          end)

          after_each(function ()
            compute_air_motion_result_mock:clear()
          end)

          it('should set velocity y to -jump_interrupt_speed_frame on first frame of hop if velocity.y is not already greater, and clear has_jumped_this_frame flag', function ()
            pc.motion_state = motion_states.air_spin
            pc.velocity.y = -3  -- must be < -pc_data.jump_interrupt_speed_frame (-2)
            pc.has_jumped_this_frame = true
            pc.can_interrupt_jump = true
            pc.hold_jump_intention = false

            pc:update_platformer_motion_airborne()

            -- call check
            assert.spy(player_char.check_hold_jump).was_called(1)
            assert.spy(player_char.check_hold_jump).was_called_with(match.ref(pc))

            -- result check
            assert.are_same({-pc_data.jump_interrupt_speed_frame, false}, {pc.velocity.y, pc.has_jumped_this_frame})
          end)

          it('should preserve velocity y completely on first frame of hop if velocity.y is already greater, and clear has_jumped_this_frame flag', function ()
            -- this can happen when character is running down a steep slope, and hops with a normal close to horizontal
            pc.motion_state = motion_states.air_spin
            pc.velocity.y = -1  -- must be >= -pc_data.jump_interrupt_speed_frame (-2)
            pc.has_jumped_this_frame = true
            pc.can_interrupt_jump = true
            pc.hold_jump_intention = false

            pc:update_platformer_motion_airborne()

            -- call check (but will do nothing)
            assert.spy(player_char.check_hold_jump).was_called(1)
            assert.spy(player_char.check_hold_jump).was_called_with(match.ref(pc))

            -- result check
            assert.are_same({-1, false}, {pc.velocity.y, pc.has_jumped_this_frame})
          end)

          it('should preserve (supposedly initial jump) velocity y on first frame of jump (not hop) and clear has_jumped_this_frame flag', function ()
            pc.motion_state = motion_states.air_spin
            pc.velocity.y = -3
            pc.has_jumped_this_frame = true
            pc.can_interrupt_jump = true
            pc.hold_jump_intention = true

            pc:update_platformer_motion_airborne()

            -- call check (but will do nothing)
            assert.spy(player_char.check_hold_jump).was_called(1)
            assert.spy(player_char.check_hold_jump).was_called_with(match.ref(pc))

            -- result check
            assert.are_same({-3, false}, {pc.velocity.y, pc.has_jumped_this_frame})
          end)

          it('should apply gravity to velocity y when not on first frame of jump and not interrupting jump', function ()
            pc.motion_state = motion_states.air_spin
            pc.velocity.y = -1
            pc.has_jumped_this_frame = false
            pc.can_interrupt_jump = true
            pc.hold_jump_intention = true

            pc:update_platformer_motion_airborne()

            -- call check (but will do nothing)
            assert.spy(player_char.check_hold_jump).was_called(1)
            assert.spy(player_char.check_hold_jump).was_called_with(match.ref(pc))

            -- result check
            assert.are_same({-1 + pc_data.gravity_frame2, false}, {pc.velocity.y, pc.has_jumped_this_frame})
          end)

          it('should set to speed y to interrupt speed (no gravity added) when interrupting actual jump', function ()
            pc.motion_state = motion_states.air_spin
            pc.velocity.y = -3  -- must be < -pc_data.jump_interrupt_speed_frame (-2)
            pc.has_jumped_this_frame = false
            pc.can_interrupt_jump = true
            pc.hold_jump_intention = false

            pc:update_platformer_motion_airborne()

            -- call check
            assert.spy(player_char.check_hold_jump).was_called(1)
            assert.spy(player_char.check_hold_jump).was_called_with(match.ref(pc))

            -- result check
            -- note that gravity is applied *before* interrupt jump, so we don't see it in the final velocity.y
            assert.are_same({-pc_data.jump_interrupt_speed_frame, false}, {pc.velocity.y, pc.has_jumped_this_frame})
          end)

          it('should NOT check for speed interrupt at all when running falling (not air_spin)', function ()
            pc.motion_state = motion_states.falling
            pc.velocity.y = -3  -- must be < -pc_data.jump_interrupt_speed_frame (-2)
            pc.has_jumped_this_frame = false
            pc.can_interrupt_jump = true
            pc.hold_jump_intention = false

            pc:update_platformer_motion_airborne()

            -- call check
            assert.spy(player_char.check_hold_jump).was_not_called()

            -- result check
            assert.are_same({-3 + pc_data.gravity_frame2, false}, {pc.velocity.y, pc.has_jumped_this_frame})
          end)

          -- unfortunately it's hard to stub clamp_air_velocity_x properly
          --  so we test the content of clamp_air_velocity_x below, which is redundant with its
          --  own utests
          -- it is *possible* to stub clamp_air_velocity_x completely and test that pure air accel x is applied,
          --  and that clamp_air_velocity_x is called with previous velocity x,
          --  although semantically a bit weird as the latter affects velocity.x

          it('should apply air accel x', function ()
            pc.velocity.x = 2
            pc.move_intention.x = -1

            pc:update_platformer_motion_airborne()

            assert.are_equal(2 - pc_data.air_accel_x_frame2, pc.velocity.x)
          end)

          it('should apply air accel x but clamp at max air velocity x in abs if not already beyond', function ()
            pc.velocity.x = -pc_data.max_air_velocity_x
            pc.move_intention.x = -1

            pc:update_platformer_motion_airborne()

            assert.are_equal(- pc_data.max_air_velocity_x, pc.velocity.x)
          end)

          it('should apply air accel x but clamp at previous air velocity x in abs if already beyond', function ()
            pc.velocity.x = -pc_data.max_air_velocity_x - 1
            pc.move_intention.x = -1

            pc:update_platformer_motion_airborne()

            assert.are_equal(- pc_data.max_air_velocity_x - 1, pc.velocity.x)
          end)

          it('should apply air accel x and allow decreasing air velocity x in abs if already beyond', function ()
            pc.velocity.x = -pc_data.max_air_velocity_x - 10
            pc.move_intention.x = 1

            pc:update_platformer_motion_airborne()

            assert.are_equal(- pc_data.max_air_velocity_x - 10 + pc_data.air_accel_x_frame2, pc.velocity.x)
          end)

          it('should set horizontal direction to intended motion direction: left', function ()
            pc.orientation = horizontal_dirs.right
            pc.velocity.x = 4
            pc.move_intention.x = -1

            pc:update_platformer_motion_airborne()

            assert.are_equal(horizontal_dirs.left, pc.orientation)
          end)

          it('should set horizontal direction to intended motion direction: right', function ()
            pc.orientation = horizontal_dirs.left
            pc.velocity.x = 4
            pc.move_intention.x = 1

            pc:update_platformer_motion_airborne()

            assert.are_equal(horizontal_dirs.right, pc.orientation)
          end)

          it('should clamp velocity Y if beyond limit (positive)', function ()
            pc.velocity.y = 1000

            pc:update_platformer_motion_airborne()

            assert.are_equal(pc_data.max_air_velocity_y, pc.velocity.y)
          end)

          -- bugfix history:
          -- .
          it('should update position with air motion result position', function ()
            pc.position = vector(0, 0)  -- doesn't matter, since we mock _compute_air_motion_result

            pc:update_platformer_motion_airborne()

            assert.are_same(vector(4, 8), pc.position)
          end)

          it('should preserve velocity.y', function ()
            -- set those flags to true to make computations more simple:
            -- velocity.y will not affected by gravity nor interrupt jump
            pc.has_jumped_this_frame = true
            pc.hold_jump_intention = true
            pc.velocity = vector(10, -10)

            pc:update_platformer_motion_airborne()

            assert.are_equal(-10, pc.velocity.y)
          end)

        end)  -- compute_air_motion_result_mock (vector(2, 8), false, false, false)

        describe('(when _compute_air_motion_result returns a motion result with is_blocked_by_wall: false, is_blocked_by_ceiling: true) '..
            '(when apply_air_drag multiplies velocity x by 0.9 no matter what)', function ()

          setup(function ()
            stub(player_char, "compute_air_motion_result", function (self)
              return motion.air_motion_result(
                nil,
                vector(4, 8),
                false, -- not the focus, but verified
                true,  -- focus in this test
                false,
                nil
              )
            end)
            stub(player_char, "apply_air_drag", function (self)
              self.velocity.x = 0.9 * self.velocity.x
            end)
          end)

          teardown(function ()
            player_char.compute_air_motion_result:revert()
            player_char.apply_air_drag:revert()
          end)

          after_each(function ()
            player_char.compute_air_motion_result:clear()
            player_char.apply_air_drag:clear()
          end)

          it('should set velocity.y to 0', function ()
            -- set those flags to true to make computations more simple:
            -- velocity.y will not affected by gravity nor interrupt jump
            pc.has_jumped_this_frame = true
            pc.hold_jump_intention = true
            pc.velocity = vector(10, -10)

            pc:update_platformer_motion_airborne()

            assert.are_equal(0, pc.velocity.y)
          end)

          it('should apply air drag, then preserve velocity.x on hit ceiling', function ()
            pc.velocity = vector(10, -10)

            pc:update_platformer_motion_airborne()

            -- spy test (should always be called anyway, but only this test really demonstrates X velocity)
            assert.spy(player_char.apply_air_drag).was_called(1)
            assert.spy(player_char.apply_air_drag).was_called_with(match.ref(pc))

            -- value test
            assert.are_equal(9, pc.velocity.x)
          end)

        end)  -- compute_air_motion_result_mock (is_blocked_by_ceiling: true)

        describe('(when _compute_air_motion_result returns a motion result with is_blocked_by_wall: true, is_blocked_by_ceiling: false)', function ()

          setup(function ()
            compute_air_motion_result_mock = stub(player_char, "compute_air_motion_result", function (self)
              return motion.air_motion_result(
                nil,
                vector(4, 8),
                true,  -- focus in this test
                false, -- not the focus, but verified
                false,
                nil
              )
            end)
          end)

          teardown(function ()
            compute_air_motion_result_mock:revert()
          end)

          after_each(function ()
            compute_air_motion_result_mock:clear()
          end)

          it('should preserve velocity.y', function ()
            -- set those flags to true to make computations more simple:
            -- velocity.y will not affected by gravity nor interrupt jump
            pc.has_jumped_this_frame = true
            pc.hold_jump_intention = true
            pc.velocity = vector(10, -10)

            pc:update_platformer_motion_airborne()

            assert.are_equal(-10, pc.velocity.y)
          end)

          it('should set velocity.x to 0', function ()
            pc.velocity = vector(10, -10)

            pc:update_platformer_motion_airborne()

            assert.are_equal(0, pc.velocity.x)
          end)

        end)

        describe('(when _compute_air_motion_result returns a motion result with is_landing: true, slope_angle: 0.5)', function ()

          setup(function ()
            compute_air_motion_result_mock = stub(player_char, "compute_air_motion_result", function (self)
              return motion.air_motion_result(
                location(0, 1),
                vector(4, 8),
                false,
                false,
                true,  -- focus in this test
                0.5
              )
            end)
          end)

          teardown(function ()
            compute_air_motion_result_mock:revert()
          end)

          after_each(function ()
            compute_air_motion_result_mock:clear()
          end)

          it('should call player_char.set_ground_tile_location with location(0, 1)', function ()
            pc:update_platformer_motion_airborne()
            assert.spy(player_char.set_ground_tile_location).was_called(1)
            assert.spy(player_char.set_ground_tile_location).was_called_with(match.ref(pc), location(0, 1))
          end)

          it('should enter standing state and set_slope_angle_with_quadrant: 0.5', function ()
            pc.slope_angle = 0

            pc:update_platformer_motion_airborne()

            -- implementation
            assert.spy(pc.enter_motion_state).was_called(1)
            assert.spy(pc.enter_motion_state).was_called_with(match.ref(pc), motion_states.standing)

            assert.spy(player_char.set_slope_angle_with_quadrant).was_called(1)
            assert.spy(player_char.set_slope_angle_with_quadrant).was_called_with(match.ref(pc), 0.5)
          end)

        end)  -- compute_air_motion_result_mock (is_blocked_by_wall: true)

        describe('(when _compute_ground_motion_result returns a motion result with position vector(*2.5*, 4), slope_angle: 0, is_blocked: false, is_falling: false)', function ()

          local compute_ground_motion_result_mock

          setup(function ()
            stub(player_char, "compute_air_motion_result", function (self)
              return motion.air_motion_result(
                nil,
                vector(2.5, 0),  -- flr(2.5) must be < pc_data.ground_sensor_extent_x
                false,
                false,
                false,
                0.5
              )
            end)
          end)

          teardown(function ()
            player_char.compute_air_motion_result:revert()
          end)

          after_each(function ()
            player_char.compute_air_motion_result:clear()
          end)

          it('should clamp character position X to stage left boundary (including half-width offset)', function ()
            pc:update_platformer_motion_airborne()

            -- in practice, clamped to 3
            assert.are_equal(ceil(pc_data.ground_sensor_extent_x), pc.position.x)
          end)

          it('should clamp the ground speed to -0.1', function ()
            pc.velocity.x = -10

            pc:update_platformer_motion_airborne()

            assert.are_equal(0, pc.velocity.x)
          end)

        end)

      end)  -- update_platformer_motion_airborne

      describe('check_spring', function ()

        setup(function ()
          stub(player_char, "trigger_spring")
        end)

        teardown(function ()
          player_char.trigger_spring:revert()
        end)

        after_each(function ()
          player_char.trigger_spring:clear()
        end)

        describe('(check_player_char_in_spring_trigger_area finds no spring)', function ()

          setup(function ()
            stub(stage_state, "check_player_char_in_spring_trigger_area", function (self)
              return nil
            end)
            stub(player_char, "trigger_spring")
          end)

          teardown(function ()
            stage_state.check_player_char_in_spring_trigger_area:revert()
            player_char.trigger_spring:revert()
          end)

          after_each(function ()
            stage_state.check_player_char_in_spring_trigger_area:clear()
            player_char.trigger_spring:clear()
          end)

          it('should call trigger_spring when ground tile location points to a spring tile (left)', function ()
            pc:check_spring()
            assert.spy(player_char.trigger_spring).was_not_called()
          end)

        end)

        describe('(check_player_char_in_spring_trigger_area finds spring)', function ()

          local mock_spring = {"mock spring"}

          setup(function ()
            stub(stage_state, "check_player_char_in_spring_trigger_area", function (self)
              return mock_spring
            end)
            stub(player_char, "trigger_spring")
          end)

          teardown(function ()
            stage_state.check_player_char_in_spring_trigger_area:revert()
            player_char.trigger_spring:revert()
          end)

          after_each(function ()
            stage_state.check_player_char_in_spring_trigger_area:clear()
            player_char.trigger_spring:clear()
          end)

          it('should call trigger_spring when ground tile location points to a spring tile (left)', function ()
            pc:check_spring()
            assert.spy(player_char.trigger_spring).was_called(1)
            assert.spy(player_char.trigger_spring).was_called_with(match.ref(pc), match.ref(mock_spring))
          end)

        end)

      end)

      describe('check_launch_ramp', function ()

        setup(function ()
          stub(player_char, "trigger_launch_ramp_effect")
        end)

        teardown(function ()
          player_char.trigger_launch_ramp_effect:revert()
        end)

        before_each(function ()
          mock_mset(2, 0, visual.launch_ramp_last_tile_id)
        end)

        it('should not call trigger_launch_ramp_effect when ground tile location points to a launch_ramp tile but ground speed is too low', function ()
          pc.ground_tile_location = location(2, 0)
          pc.ground_speed = pc_data.launch_ramp_min_ground_speed - 0.1

          pc:check_launch_ramp()

          assert.spy(player_char.trigger_launch_ramp_effect).was_not_called()
        end)

        it('should call trigger_launch_ramp_effect when ground tile location points to a launch_ramp tile and ground speed is high enough', function ()
          pc.ground_tile_location = location(2, 0)
          pc.ground_speed = pc_data.launch_ramp_min_ground_speed

          pc:check_launch_ramp()

          assert.spy(player_char.trigger_launch_ramp_effect).was_called(1)
          assert.spy(player_char.trigger_launch_ramp_effect).was_called_with(match.ref(pc))
        end)

      end)

      describe('check_emerald', function ()

        local mock_is_in_emerald_pick_area
        local mock_emerald = emerald(3, location(1, 2))

        setup(function ()
          stub(stage_state, "character_pick_emerald")
          stub(stage_state, "check_emerald_pick_area", function (self, _pos)
            return mock_is_in_emerald_pick_area and mock_emerald or nil
          end)
        end)

        teardown(function ()
          stage_state.character_pick_emerald:revert()
          stage_state.check_emerald_pick_area:revert()
        end)

        before_each(function ()
          mock_mset(2, 0, visual.sprite_data_t.emerald.id_loc:to_sprite_id())
        end)

        after_each(function ()
          mock_is_in_emerald_pick_area = nil

          stage_state.character_pick_emerald:clear()
        end)

        describe('(not in emerald pick area)', function ()

          setup(function ()
            mock_is_in_emerald_pick_area = false
          end)

          teardown(function ()
            mock_is_in_emerald_pick_area = nil
          end)

          it('should not call pick_emerald when check_emerald_pick_area returns false on current position', function ()
            mock_is_in_emerald_pick_area = false
            pc:check_emerald()
            assert.spy(stage_state.character_pick_emerald).was_not_called()
          end)

          it('should call pick_emerald when check_emerald_pick_area returns true on current position', function ()
            mock_is_in_emerald_pick_area = true
            pc:check_emerald()
            assert.spy(stage_state.character_pick_emerald).was_called(1)
            assert.spy(stage_state.character_pick_emerald).was_called_with(match.ref(flow.curr_state), match.ref(mock_emerald))
          end)

        end)

      end)

      describe('check_loop_external_triggers', function ()

        setup(function ()
          stub(stage_state, "check_loop_external_triggers", function (self, pos, _previous_active_layer)
            -- simulate some very broad triggers
            -- don't care about previous_active_layer, we are already doing proper checks for that
            --  in stage_state:check_loop_external_triggers utests
            if pos.y > 10 then
              return nil
            end
            if pos.x < 0 then
              return 1
            elseif pos.x > 5 then
              return 2
            end
          end)
        end)

        teardown(function ()
          stage_state.check_loop_external_triggers:revert()
        end)

        it('should set active loop layer to 1 when detecting external entrance trigger', function ()
          pc.active_loop_layer = -1
          pc.position = vector(-1, 0)
          pc:check_loop_external_triggers()
          assert.are_equal(1, pc.active_loop_layer)
        end)

        it('should set active loop layer to 2 when detecting external exit trigger', function ()
          pc.active_loop_layer = -1
          pc.position = vector(6, 0)
          pc:check_loop_external_triggers()
          assert.are_equal(2, pc.active_loop_layer)
        end)

        it('should not set active loop layer when not detecting any external loop trigger', function ()
          pc.active_loop_layer = -1
          pc.position = vector(0, 15)
          pc:check_loop_external_triggers()
          -- invalid value of course, just to show that nothing was set
          assert.are_equal(-1, pc.active_loop_layer)
        end)

      end)

    end)  -- (with mock tiles data setup)

    describe('check_hold_jump', function ()

      before_each(function ()
        -- optional, just to enter air_spin state and be in a meaningful state in this context
        pc:enter_motion_state(motion_states.air_spin)
      end)

      it('should interrupt the jump when still possible and hold_jump_intention is false', function ()
        pc.velocity.y = -3
        pc.can_interrupt_jump = true

        pc:check_hold_jump()

        assert.are_same({false, -pc_data.jump_interrupt_speed_frame}, {pc.can_interrupt_jump, pc.velocity.y})
      end)

      it('should not change velocity but still set the interrupt flag when it\'s too late to interrupt jump and hold_jump_intention is false', function ()
        pc.velocity.y = -1
        pc.can_interrupt_jump = true

        pc:check_hold_jump()

        assert.are_same({false, -1}, {pc.can_interrupt_jump, pc.velocity.y})
      end)

      it('should not try to interrupt jump if already done', function ()
        pc.velocity.y = -3
        pc.can_interrupt_jump = false

        pc:check_hold_jump()

        assert.are_same({false, -3}, {pc.can_interrupt_jump, pc.velocity.y})
      end)

      it('should not try to interrupt jump if still holding jump input', function ()
        pc.velocity.y = -3
        pc.can_interrupt_jump = true
        pc.hold_jump_intention = true

        pc:check_hold_jump()

        assert.are_same({true, -3}, {pc.can_interrupt_jump, pc.velocity.y})
      end)

    end)

    describe('apply_air_drag', function ()

      it('(when velocity is 0.25 0) should do nothing', function ()
        -- abs(vel.x) >= pc_data.air_drag_min_velocity_x but vel.y >= 0
        pc.velocity = vector(0.25, 0)

        pc:apply_air_drag()

        assert.are_same(vector(0.25, 0), pc.velocity)
      end)

      it('(when velocity is 0.25 7) should do nothing', function ()
        -- abs(vel.x) >= pc_data.air_drag_min_velocity_x but vel.y >= 0
        pc.velocity = vector(0.25, 7)

        pc:apply_air_drag()

        assert.are_same(vector(0.25, 7), pc.velocity)
      end)

      it('(when velocity is 0.1 -7) should do nothing', function ()
        -- vel.y is OK but abs(vel.x) < pc_data.air_drag_min_velocity_x
        pc.velocity = vector(0.1, -7)

        pc:apply_air_drag()

        assert.are_same(vector(0.1, -7), pc.velocity)
      end)

      it('(when velocity is 0.25 -7) should do nothing', function ()
        -- both velocity coords match the conditions, apply drag factor
        pc.velocity = vector(0.25, -7)

        pc:apply_air_drag()

        -- velocity x should be = 0.2421875
        assert.are_same(vector(0.25 * pc_data.air_drag_factor_per_frame, -7), pc.velocity)
      end)

      it('(when velocity is 0.25 -8) should do nothing', function ()
        -- abs(vel.x) >= pc_data.air_drag_min_velocity_x but vel.y <= - pc_data.air_drag_max_abs_velocity_y
        pc.velocity = vector(0.25, -8)

        pc:apply_air_drag()

        assert.are_same(vector(0.25, -8), pc.velocity)
      end)

    end)

    describe('clamp_air_velocity_x', function ()

      it('should preserve velocity x when it is not over max speed in absolute value (positive)', function ()
        pc.motion_state = motion_states.falling  -- to avoid assert
        pc.velocity.x = pc_data.max_air_velocity_x - 0.01

        pc:clamp_air_velocity_x(0)

        assert.are_equal(pc_data.max_air_velocity_x - 0.01, pc.velocity.x)
      end)

      it('should clamp at previous air velocity x in abs if already beyond', function ()
        pc.motion_state = motion_states.air_spin  -- to avoid assert
        pc.velocity.x = -pc_data.max_air_velocity_x - 1

        pc:clamp_air_velocity_x(-pc_data.max_air_velocity_x - 1)

        assert.are_equal(- pc_data.max_air_velocity_x - 1, pc.velocity.x)
      end)

      it('should allow decreasing air velocity x in abs if already beyond', function ()
        pc.motion_state = motion_states.air_spin  -- to avoid assert
        pc.velocity.x = -pc_data.max_air_velocity_x - 10

        pc:clamp_air_velocity_x(-pc_data.max_air_velocity_x - 9)

        assert.are_equal(-pc_data.max_air_velocity_x - 9, pc.velocity.x)
      end)

    end)

    describe('compute_air_motion_result', function ()

      it('(when velocity is zero) should return air_motion_result with initial position and no hits', function ()
        pc.position = vector(4, 8)
        assert.are_same(motion.air_motion_result(
            nil,
            vector(4, 8),
            false,
            false,
            false,
            nil
          ), pc:compute_air_motion_result())
      end)

      describe('(when _advance_in_air_along returns an air_motion_result with full motion done along x, half motion done with hit ceiling along y)', function ()

        setup(function ()
          advance_in_air_along_mock = stub(player_char, "advance_in_air_along", function (self, ref_motion_result, velocity, coord)
            if coord == "x" then
              local motion = vector(velocity.x, 0)
              ref_motion_result.position = ref_motion_result.position + motion
            else  -- coord == "y"
              -- to make sure we are calling _advance_in_air_along on x before y, we add a check here:
              --  if we have already moved from initial pos.y = 8 (see test below), block any motion along y
              if ref_motion_result.position.y == 8 then
                local motion = vector(0, velocity.y / 2)
                ref_motion_result.position = ref_motion_result.position + motion
              end
              ref_motion_result.is_blocked_by_ceiling = true
            end
          end)
        end)

        teardown(function ()
          advance_in_air_along_mock:revert()
        end)

        after_each(function ()
          advance_in_air_along_mock:clear()
        end)

        it('(when velocity is zero) should return air_motion_result with initial position and no hits', function ()
          pc.position = vector(4.5, 8)
          pc.velocity = vector(5, -12)

          -- character should advance of (5, -6) resulting in pos (9.5, 2)

          -- interface: check that the final result is correct
          assert.are_same(motion.air_motion_result(
              nil,
              vector(9.5, 2),
              false,
              true,  -- hit ceiling
              false,
              nil
            ), pc:compute_air_motion_result())
        end)

      end)

    end)

    describe('advance_in_air_along', function ()

      describe('(when next_air_step moves motion_result.position.x/y by 1px in the given direction, ' ..
        'unless moving along x from x >= 5, where it is blocking by wall)', function ()

        local next_air_step_mock

        setup(function ()
          next_air_step_mock = stub(player_char, "next_air_step", function (self, direction, motion_result)
            if coord == "y" or motion_result.position.x < 5 then
              local step_vec = dir_vectors[direction]
              motion_result.position = motion_result.position + step_vec
            else
              motion_result.is_blocked_by_wall = true
            end
          end)
        end)

        teardown(function ()
          next_air_step_mock:revert()
        end)

        after_each(function ()
          next_air_step_mock:clear()
        end)

        -- bugfix history:
        -- = the itest 'platformer air wall block' showed that the subpixel check
        --   was using the integer max_pixel_distance instead of the float velocity:get()
        --   and this revealed a bug of no motion on x at all when velocity.x is < 1 and x starts integer
        it('(vector(0, 10) at speed 0.5 along x) should move to vector(0.7, 10) without being blocked', function ()
          local motion_result = motion.air_motion_result(
            nil,
            vector(0, 10),
            false,
            false,
            false,
            nil
          )

          -- we assume _compute_max_pixel_distance is correct
          pc:advance_in_air_along(motion_result, vector(0.5, 99), "x")

          assert.are_same(motion.air_motion_result(
              nil,
              vector(0.5, 10),
              false,
              false,
              false,
              nil
            ), motion_result
          )
        end)

        it('(vector(0.2, 10) at speed 0.5 along x) should move to vector(0.7, 10) without being blocked', function ()
          local motion_result = motion.air_motion_result(
            nil,
            vector(0.2, 10),
            false,
            false,
            false,
            nil
          )

          -- we assume _compute_max_pixel_distance is correct
          pc:advance_in_air_along(motion_result, vector(0.5, 99), "x")

          assert.are_same(motion.air_motion_result(
              nil,
              vector(0.7, 10),
              false,
              false,
              false,
              nil
            ), motion_result
          )
        end)

        it('(vector(0.5, 10) at speed 0.5 along x) should move to vector(1, 10) without being blocked', function ()
          local motion_result = motion.air_motion_result(
            nil,
            vector(0.5, 10),
            false,
            false,
            false,
            nil
          )

          -- we assume _compute_max_pixel_distance is correct
          pc:advance_in_air_along(motion_result, vector(0.5, 99), "x")

          assert.are_same(motion.air_motion_result(
              nil,
              vector(1, 10),
              false,
              false,
              false,
              nil
            ), motion_result
          )
        end)

        it('(vector(0.4, 10) at speed 2.7 along x) should move to vector(3.1, 10)', function ()
          local motion_result = motion.air_motion_result(
            nil,
            vector(0.4, 10),
            false,
            false,
            false,
            nil
          )

          -- we assume _compute_max_pixel_distance is correct
          pc:advance_in_air_along(motion_result, vector(2.7, 99), "x")

          assert.are_same(motion.air_motion_result(
              nil,
              vector(3.1, 10),
              false,
              false,
              false,
              nil
            ), motion_result
          )
        end)

        it('(vector(2.5, 10) at speed 2.7 along x) should move to vector(5, 10) and blocked by wall', function ()
          local motion_result = motion.air_motion_result(
            nil,
            vector(2.5, 10),
            false,
            false,
            false,
            nil
          )

          -- we assume _compute_max_pixel_distance is correct
          pc:advance_in_air_along(motion_result, vector(2.7, 99), "x")

          assert.are_same(motion.air_motion_result(
              nil,
              vector(5, 10),
              true,
              false,
              false,
              nil
            ), motion_result
          )
        end)

        it('(vector(2.5, 7.3) at speed -4.4 along y) should move to vector(2.5, 2.9) without being blocked', function ()
          local motion_result = motion.air_motion_result(
            nil,
            vector(2.5, 7.3),
            false,
            false,
            false,
            nil
          )

          -- we assume _compute_max_pixel_distance is correct
          pc:advance_in_air_along(motion_result, vector(99, -4.4), "y")

          assert.is_true(almost_eq_with_message(vector(2.5, 2.9), motion_result.position))
          assert.are_same({
              false,
              false,
              false
            }, {
            motion_result.is_blocked_by_wall,
            motion_result.is_blocked_by_ceiling,
            motion_result.is_landing
            })
        end)

      end)

    end)

    describe('next_air_step', function ()
      it('(in the air) direction up should move 1px up without being blocked', function ()
        local motion_result = motion.air_motion_result(
            nil,
          vector(2, 7),
          false,
          false,
          false,
          nil
        )

        pc:next_air_step(directions.up, motion_result)

        assert.are_same(motion.air_motion_result(
            nil,
            vector(2, 6),
            false,
            false,
            false,
            nil
          ),
          motion_result
        )
      end)

      it('(in the air) direction down should move 1px down without being blocked', function ()
        local motion_result = motion.air_motion_result(
          nil,
          vector(2, 7),
          false,
          false,
          false,
          nil
        )

        pc:next_air_step(directions.down, motion_result)

        assert.are_same(motion.air_motion_result(
            nil,
            vector(2, 8),
            false,
            false,
            false,
            nil
          ),
          motion_result
        )
      end)

      it('(in the air) direction left should move 1px left without being blocked', function ()
        local motion_result = motion.air_motion_result(
          nil,
          vector(2, 7),
          false,
          false,
          false,
          nil
        )

        pc:next_air_step(directions.left, motion_result)

        assert.are_same(motion.air_motion_result(
            nil,
            vector(1, 7),
            false,
            false,
            false,
            nil
          ),
          motion_result
        )
      end)

      it('(in the air) direction right should move 1px right without being blocked', function ()
        local motion_result = motion.air_motion_result(
          nil,
          vector(2, 7),
          false,
          false,
          false,
          nil
        )

        pc:next_air_step(directions.right, motion_result)

        assert.are_same(motion.air_motion_result(
            nil,
            vector(3, 7),
            false,
            false,
            false,
            nil
          ),
          motion_result
        )
      end)

      describe('(with mock tiles data setup)', function ()

        setup(function ()
          tile_test_data.setup()
        end)

        teardown(function ()
          tile_test_data.teardown()
        end)

        after_each(function ()
          pico8:clear_map()
        end)

        -- for these utests, we assume that _compute_ground_sensors_query_info and
        --  _is_blocked_by_ceiling are correct,
        --  so rather than mocking them, so we setup simple tiles to walk on

        describe('(with flat ground)', function ()

          before_each(function ()
            -- #
            mock_mset(0, 0, tile_repr.full_tile_id)  -- full tile
          end)

          -- in the tests below, we can use pc_data.full/center_height_standing directly instead
          --  of pc:get_full/center_height()
          --  because the character is not compact (e.g. no air spin)

          it('direction up into ceiling should not move, and flag is_blocked_by_ceiling', function ()
            -- we need an upward velocity for ceiling check if not faster on x than y
            pc.velocity.x = 0
            pc.velocity.y = -3

            local motion_result = motion.air_motion_result(
              nil,
              vector(4, 8 + pc_data.full_height_standing - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.up, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(4, 8 + pc_data.full_height_standing - pc_data.center_height_standing),
                false,
                true,
                false,
                nil
              ),
              motion_result
            )
          end)

          -- added to identify #122 BUG MOTION jump-through-ceiling-diagonal
          --  trying to reduce itest "platformer air ceiling corner block" to a utest
          -- fixed by re-adding condition direction == directions.up which I removed
          --  when I switched to the sheer velocity check (which in the end is much more rare)
          it('direction up into ceiling should not move, and flag is_blocked_by_ceiling, even if already is_blocked_by_wall', function ()
            -- we need an upward velocity for ceiling check if not faster on x than y
            pc.velocity.x = 0
            pc.velocity.y = -3

            local motion_result = motion.air_motion_result(
              nil,
              vector(4, 8 + pc_data.full_height_standing - pc_data.center_height_standing),
              true,  -- is_blocked_by_wall
              false,
              false,
              nil
            )

            pc:next_air_step(directions.up, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(4, 8 + pc_data.full_height_standing - pc_data.center_height_standing),
                true,  -- is_blocked_by_wall
                true,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('direction down into ground should not move, and flag is_landing with slope_angle 0', function ()
            pc.velocity.x = 0
            pc.velocity.y = 3

            local motion_result = motion.air_motion_result(
              nil,
              vector(4, 0 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.down, motion_result)

            assert.are_same(motion.air_motion_result(
                location(0, 0),
                vector(4, 0 - pc_data.center_height_standing),
                false,
                false,
                true,
                0
              ),
              motion_result
            )
          end)

          it('direction left exactly onto ground should step left, but flag NOT is_landing with slop_angle nil', function ()
            -- we wait next frame to actually land, else character will stay 1 px above ground

            pc.velocity.x = -3
            pc.velocity.y = 0

            local motion_result = motion.air_motion_result(
              nil,
              vector(11, 0 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.left, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(10, 0 - pc_data.center_height_standing),
                false,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('direction right exactly onto ground should step right, and flag NOT is_landing with slop_angle nil', function ()
            -- we wait next frame to actually land, else character will stay 1 px above ground

            pc.velocity.x = 3
            pc.velocity.y = 0

            local motion_result = motion.air_motion_result(
              nil,
              vector(-3, 0 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.right, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(-2, 0 - pc_data.center_height_standing),
                false,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('direction left into ground not deeper than max_ground_escape_height should step left and up, and flag is_landing with slop_angle 0', function ()
            pc.velocity.x = -3
            pc.velocity.y = 0

            local motion_result = motion.air_motion_result(
              nil,
              vector(11, 1 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.left, motion_result)

            assert.are_same(motion.air_motion_result(
                location(0, 0),
                vector(10, 0 - pc_data.center_height_standing),
                false,
                false,
                true,
                0
              ),
              motion_result
            )
          end)

          it('direction right into ground not deeper than max_ground_escape_height should step right and up, and flag is_landing with slop_angle 0', function ()
            pc.velocity.x = 3
            pc.velocity.y = 0

            local motion_result = motion.air_motion_result(
              nil,
              vector(-3, 1 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.right, motion_result)

            assert.are_same(motion.air_motion_result(
                location(0, 0),
                vector(-2, 0 - pc_data.center_height_standing),
                false,
                false,
                true,
                0
              ),
              motion_result
            )
          end)

          -- extra tests for sheer horizontally velocity check

          it('(at upward velocity, sheer angle) direction right into ground not deeper than max_ground_escape_height should step right and up, and flag is_landing with slop_angle 0', function ()
            pc.velocity.x = 3
            pc.velocity.y = -1

            local motion_result = motion.air_motion_result(
              nil,
              vector(-3, 1 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.right, motion_result)

            assert.are_same(motion.air_motion_result(
                location(0, 0),
                vector(-2, 0 - pc_data.center_height_standing),
                false,
                false,
                true,
                0
              ),
              motion_result
            )
          end)

          it('(at upward velocity, high angle) direction right into ground not deeper than max_ground_escape_height should ignore the floor completely (even during right step)', function ()
            pc.velocity.x = 3
            pc.velocity.y = -3

            local motion_result = motion.air_motion_result(
              nil,
              vector(-3, 1 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.right, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(-2, 1 - pc_data.center_height_standing),
                false,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('direction left into wall deeper than max_ground_escape_height should not move, and flag is_blocked_by_wall', function ()
            pc.velocity.x = -3
            pc.velocity.y = 0

            local motion_result = motion.air_motion_result(
              nil,
              vector(11, pc_data.max_ground_escape_height + 1 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.left, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(11, pc_data.max_ground_escape_height + 1 - pc_data.center_height_standing),
                true,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('direction right into wall deeper than max_ground_escape_height should not move, and flag is_blocked_by_wall', function ()
            pc.velocity.x = 3
            pc.velocity.y = 0

            local motion_result = motion.air_motion_result(
              nil,
              vector(-3, pc_data.max_ground_escape_height + 1 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.right, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(-3, pc_data.max_ground_escape_height + 1 - pc_data.center_height_standing),
                true,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          -- ceiling tests below also try sheer vs high angle (but no separate test with velocity.y 0 and not 0)

          it('direction left into wall via ceiling downward and faster on x than y should not move, and flag is_blocked_by_wall', function ()
            -- important
            pc.velocity.x = -3
            pc.velocity.y = 2

            local motion_result = motion.air_motion_result(
              nil,
              vector(11, 7 + pc_data.full_height_standing - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.left, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(11, 7 + pc_data.full_height_standing - pc_data.center_height_standing),
                true,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('direction left into wall via ceiling downward and slower on x than y should 1px left without being blocked', function ()
            -- important
            pc.velocity.x = -2
            pc.velocity.y = 3

            local motion_result = motion.air_motion_result(
              nil,
              vector(11, 7 + pc_data.full_height_standing - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.left, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(10, 7 + pc_data.full_height_standing - pc_data.center_height_standing),
                false,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('direction right into wall via ceiling downward and faster on x than y should not move, and flag is_blocked_by_wall', function ()
            -- important
            pc.velocity.x = 3
            pc.velocity.y = 2

            local motion_result = motion.air_motion_result(
              nil,
              vector(-3, 7 + pc_data.full_height_standing - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.right, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(-3, 7 + pc_data.full_height_standing - pc_data.center_height_standing),
                true,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('direction right into wall via ceiling downward and slower on x than y should 1px right without being blocked', function ()
            -- important
            pc.velocity.x = 2
            pc.velocity.y = 3

            local motion_result = motion.air_motion_result(
              nil,
              vector(-3, 7 + pc_data.full_height_standing - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.right, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(-2, 7 + pc_data.full_height_standing - pc_data.center_height_standing),
                false,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('(after landing in previous step) direction right onto new ground should move, set flag to NOT landing and update slope_angle to nil', function ()
            -- we wait next frame to actually land, else character will stay 1 px above ground
            -- this test specifically, however, is to check that is_landing: true and slope_angle: 0.5
            --  are reset when arrive just above ground, as it's not considered landing
            -- (if you change signed_distance_to_closest_ground >= 0 to ... > 0)
            --  in next_air_step it won't pass

            pc.velocity.x = 1
            pc.velocity.y = 0

            local motion_result = motion.air_motion_result(
              location(0, 0),
              vector(-3, 0 - pc_data.center_height_standing),
              false,
              false,
              true,
              0.5
            )

            pc:next_air_step(directions.right, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(-2, 0 - pc_data.center_height_standing),
                false,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

          it('(after landing in previous step) direction left into the air should move and unset is_landing', function ()
            pc.velocity.x = -1
            pc.velocity.y = 0

            local motion_result = motion.air_motion_result(
              location(0, 0),
              vector(-2, 0 - pc_data.center_height_standing),
              false,
              false,
              true,
              0
            )

            pc:next_air_step(directions.left, motion_result)

            assert.are_same(motion.air_motion_result(
                nil,
                vector(-3, 0 - pc_data.center_height_standing),
                false,
                false,
                false,
                nil
              ),
              motion_result
            )
          end)

        end)  -- (with flat ground)

        describe('(with steep curve top)', function ()

          before_each(function ()
            -- i
            mock_mset(0, 0, tile_repr.visual_loop_bottomright_steepest)
          end)

          -- added to identify #129 BUG MOTION curve_run_up_fall_in_wall
          --  and accompany itest "fall on curve top"
          -- it was fixed by WALL LANDING ADJUSTMENT OFFSET
          it('direction down into steep curve should move, flag is_landing with slope_angle atan2(3, -8) but above all adjust position X to the left so feet just stand on the slope', function ()
            pc.velocity.x = 0
            pc.velocity.y = 3

            local motion_result = motion.air_motion_result(
              nil,
              -- used to be 0 -, now it's 1 - since we removed the top pixel of the steepest slope
              -- when fixing #132 (see corresponding utest)
              vector(5, 1 - pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.down, motion_result)

            assert.are_same(motion.air_motion_result(
                location(0, 0),
                -- kinda arbitrary offset of 6, but based on character data
                vector(-1, 1 - pc_data.center_height_standing),
                false,
                false,
                true,
                atan2(3, -8)
              ),
              motion_result
            )
          end)

        end)

        -- testing landing on ceiling aka ceiling adherence catch
        describe('(with ceiling top-left and top-right 45-deg corners)', function ()

          before_each(function ()
            -- 45
            mock_mset(0, 0, tile_repr.visual_topleft_45)
            mock_mset(1, 0, tile_repr.visual_topright_45)
          end)

          it('direction up into top-left corner should land on (adhere to) ceiling', function ()
            pc.velocity.x = 0
            pc.velocity.y = -3

            local motion_result = motion.air_motion_result(
              nil,
              -- column 4 in topleft tile should have downward column of height 6
              vector(4, 6 + pc_data.center_height_standing),
              false,
              false,
              false,
              nil
            )

            pc:next_air_step(directions.down, motion_result)

            assert.are_same(motion.air_motion_result(
                location(0, 0),
                vector(4, 6 + pc_data.center_height_standing),
                false,
                false,
                true,  -- is_landing
                atan2(-8, 8)
              ),
              motion_result
            )
          end)

        end)

      end)  -- (with mock tiles data setup)

    end)  -- next_air_step

    describe('trigger_spring', function ()

      local mock_spring_up = { direction = directions.up, extend = spy.new(function () end) }
      local mock_spring_left = { direction = directions.left, extend = spy.new(function () end) }
      local mock_spring_right = { direction = directions.right, extend = spy.new(function () end) }

      setup(function ()
        stub(stage_state, "extend_spring")
        spy.on(player_char, "enter_motion_state")
        stub(player_char, "play_low_priority_sfx")
      end)

      teardown(function ()
        stage_state.extend_spring:revert()
        player_char.enter_motion_state:revert()
        player_char.play_low_priority_sfx:revert()
      end)

      after_each(function ()
        stage_state.extend_spring:clear()
        player_char.enter_motion_state:clear()
        player_char.play_low_priority_sfx:clear()
        mock_spring_up.extend:clear()
        mock_spring_left.extend:clear()
        mock_spring_right.extend:clear()
      end)

      it('(spring up) should set upward velocity on character', function ()
        pc:trigger_spring(mock_spring_up)
        assert.are_same(vector(0, - pc_data.spring_jump_speed_frame), pc.velocity)
      end)

      it('(spring up) should enter motion state: falling', function ()
        pc:trigger_spring(mock_spring_up)
        assert.spy(player_char.enter_motion_state).was_called(1)
        assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.falling)
      end)

      it('(spring up) should set should_play_spring_jump to true', function ()
        pc:trigger_spring(mock_spring_up)
        assert.is_true(pc.should_play_spring_jump)
      end)

      it('(spring left) should set orientation to left', function ()
        pc.orientation = horizontal_dirs.right
        pc:trigger_spring(mock_spring_left)
        assert.are_equal(horizontal_dirs.left, pc.orientation)
      end)

      it('(spring left) should set horizontal control lock timer', function ()
        pc.horizontal_control_lock_timer = 0
        pc:trigger_spring(mock_spring_left)
        assert.are_equal(pc_data.spring_horizontal_control_lock_duration, pc.horizontal_control_lock_timer)
      end)

      it('(spring left, pc grounded) should set ground speed on character', function ()
        pc.motion_state = motion_states.rolling
        pc:trigger_spring(mock_spring_left)
        assert.are_equal(- pc_data.spring_jump_speed_frame, pc.ground_speed)
      end)

      it('(spring right, pc grounded) should set ground speed on character', function ()
        pc.motion_state = motion_states.rolling
        pc:trigger_spring(mock_spring_right)
        assert.are_equal(pc_data.spring_jump_speed_frame, pc.ground_speed)
      end)

      it('(spring left, pc airborne) should set air speed x on character', function ()
        pc.motion_state = motion_states.air_spin
        pc:trigger_spring(mock_spring_left)
        assert.are_equal(- pc_data.spring_jump_speed_frame, pc.velocity.x)
      end)

      it('(spring right, pc airborne) should set air speed x on character', function ()
        pc.motion_state = motion_states.air_spin
        pc:trigger_spring(mock_spring_right)
        assert.are_equal(pc_data.spring_jump_speed_frame, pc.velocity.x)
      end)

      it('should call extend on passed spring object', function ()
        pc:trigger_spring(mock_spring_up)
        assert.spy(mock_spring_up.extend).was_called(1)
        assert.spy(mock_spring_up.extend).was_called_with(match.ref(mock_spring_up))
      end)

      it('should play low priority spring jump sfx', function ()
        pc:trigger_spring(mock_spring_up)

        assert.spy(player_char.play_low_priority_sfx).was_called(1)
        assert.spy(player_char.play_low_priority_sfx).was_called_with(match.ref(pc), audio.sfx_ids.spring_jump)
      end)

    end)

    describe('trigger_launch_ramp_effect', function ()

      setup(function ()
        spy.on(player_char, "enter_motion_state")
      end)

      teardown(function ()
        player_char.enter_motion_state:revert()
      end)

      after_each(function ()
        player_char.enter_motion_state:clear()
      end)

      it('should velocity to (ground_speed * multiplier) along launch_ramp_velocity_angle', function ()
        pc.ground_speed = 2

        pc:trigger_launch_ramp_effect()

        assert.are_same((2 * pc_data.launch_ramp_speed_multiplier) * vector(
          cos(pc_data.launch_ramp_velocity_angle),
          sin(pc_data.launch_ramp_velocity_angle)
        ), pc.velocity)
      end)

      it('should velocity to (ground_speed * multiplier), clamped to launch_ramp_speed_max_launch_speed, along launch_ramp_velocity_angle', function ()
        -- something that, when multiplied by multiplier, will get over data max
        pc.ground_speed = (pc_data.launch_ramp_speed_max_launch_speed + 1) / pc_data.launch_ramp_speed_multiplier

        pc:trigger_launch_ramp_effect()

        assert.are_same(pc_data.launch_ramp_speed_max_launch_speed * vector(
          cos(pc_data.launch_ramp_velocity_angle),
          sin(pc_data.launch_ramp_velocity_angle)
        ), pc.velocity)
      end)

      it('should enter motion state: falling', function ()
        pc.ground_speed = 2

        pc:trigger_launch_ramp_effect()

        assert.spy(player_char.enter_motion_state).was_called(1)
        assert.spy(player_char.enter_motion_state).was_called_with(match.ref(pc), motion_states.falling)
      end)

      it('should set should_play_spring_jump to true', function ()
        pc.ground_speed = 2

        pc:trigger_launch_ramp_effect()

        assert.is_true(pc.should_play_spring_jump)
      end)

      it('should set ignore_launch_ramp_timer to ignore_launch_ramp_duration', function ()
        pc.ground_speed = 2

        pc:trigger_launch_ramp_effect()

        assert.are_equal(pc_data.ignore_launch_ramp_duration, pc.ignore_launch_ramp_timer)
      end)

    end)

    describe('update_debug', function ()

      local update_velocity_debug_stub

      setup(function ()
        stub(player_char, "warp_to_emerald_by")
        update_velocity_debug_mock = stub(player_char, "update_velocity_debug", function (self)
          self.debug_velocity = vector(4, -3)
        end)
        move_stub = stub(player_char, "move")
      end)

      teardown(function ()
        player_char.warp_to_emerald_by:revert()
        update_velocity_debug_mock:revert()
        move_stub:revert()
      end)

      before_each(function ()
        flow.curr_state.curr_stage_data = {
          tile_width = 20,
          tile_height = 10,
        }
      end)

      after_each(function ()
        player_char.warp_to_emerald_by:clear()
        update_velocity_debug_mock:clear()
        move_stub:clear()

        input:init()
      end)

      it('(still holding x) should not call anything if not pressing left/right', function ()
        input.players_btn_states[0][button_ids.x] = btn_states.pressed

        pc:update_debug()

        assert.spy(player_char.warp_to_emerald_by).was_not_called()
        assert.spy(update_velocity_debug_mock).was_not_called()
      end)

      it('(still holding x) should call warp_to_emerald_by(-1) ie previous if pressing left', function ()
        input.players_btn_states[0][button_ids.x] = btn_states.pressed
        input.players_btn_states[0][button_ids.left] = btn_states.just_pressed

        pc:update_debug()

        assert.spy(player_char.warp_to_emerald_by).was_called(1)
        assert.spy(player_char.warp_to_emerald_by).was_called_with(match.ref(pc), -1)
        assert.spy(update_velocity_debug_mock).was_not_called()
      end)

      it('(still holding x) should call warp_to_emerald_by(1) ie next if pressing right', function ()
        input.players_btn_states[0][button_ids.x] = btn_states.pressed
        input.players_btn_states[0][button_ids.right] = btn_states.just_pressed

        pc:update_debug()

        assert.spy(player_char.warp_to_emerald_by).was_called(1)
        assert.spy(player_char.warp_to_emerald_by).was_called_with(match.ref(pc), 1)
        assert.spy(update_velocity_debug_mock).was_not_called()
      end)

      it('(not holding x) should call update_velocity_debug, then move using the new velocity', function ()
        pc.position = vector(10, 20)
        pc:update_debug()
        assert.spy(update_velocity_debug_mock).was_called(1)
        assert.spy(update_velocity_debug_mock).was_called_with(match.ref(pc))
        assert.are_same(vector(10, 20) + vector(4, -3), pc.position)
      end)

      it('(not holding x) should call update_velocity_debug, then move using the new velocity and clamp to level edges', function ()
        pc.position = vector(20 * 8 - 9, 2)
        pc:update_debug()
        assert.spy(update_velocity_debug_mock).was_called(1)
        assert.spy(update_velocity_debug_mock).was_called_with(match.ref(pc))
        assert.are_same(vector(20 * 8 - 8, 0), pc.position)
      end)

    end)

    describe('update_velocity_debug', function ()

      local update_velocity_component_debug_stub

      setup(function ()
        update_velocity_component_debug_stub = stub(player_char, "update_velocity_component_debug")
      end)

      teardown(function ()
        update_velocity_component_debug_stub:revert()
      end)

      it('should call _update_velocity_component_debug on each component', function ()
        pc:update_velocity_debug()
        assert.spy(update_velocity_component_debug_stub).was_called(2)
        assert.spy(update_velocity_component_debug_stub).was_called_with(match.ref(pc), "x")
        assert.spy(update_velocity_component_debug_stub).was_called_with(match.ref(pc), "y")
      end)

    end)

    describe('update_velocity_component_debug', function ()

      it('should change nothing when debug speed and move intention in x is 0', function ()
        pc.debug_velocity.x = 0
        pc.move_intention.x = 0

        pc:update_velocity_component_debug("x")

        assert.are_equal(0, pc.debug_velocity.x)
      end)

      it('should accelerate on x when vx = 0 and input x ~= 0', function ()
        pc.debug_velocity.x = 0
        pc.move_intention.x = -1

        pc:update_velocity_component_debug("x")

        assert.are_equal(- pc.debug_move_accel, pc.debug_velocity.x)
      end)

      it('should accelerate on positive x when vx > 0 and input x > 0', function ()
        pc.debug_velocity = vector(2, 0)
        pc.move_intention = vector(1, 0)

        pc:update_velocity_component_debug("x")

        assert.are_equal(2 + pc.debug_move_accel, pc.debug_velocity.x)
      end)

      it('should accelerate on negative x when vx < 0 and input x < 0', function ()
        pc.debug_velocity = vector(-2, 0)
        pc.move_intention = vector(-1, 0)

        pc:update_velocity_component_debug("x")

        assert.are_equal(-2 - pc.debug_move_accel, pc.debug_velocity.x)
      end)

      it('should decelerate on x with friction when there is no input on x', function ()
        pc.debug_velocity.x = -2
        pc.move_intention.x = 0

        pc:update_velocity_component_debug("x")

        assert.are_equal(-2 + pc.debug_move_friction, pc.debug_velocity.x)
      end)

      it('should decelerate on x even faster when vx > 0 and input x < 0', function ()
        pc.debug_velocity.x = 2
        pc.move_intention.x = -1

        pc:update_velocity_component_debug("x")

        assert.are_equal(2 - pc.debug_move_decel, pc.debug_velocity.x)
      end)

      -- no need to redo all the tests with y, since we checked vector:get/set
      --  to work with X and Y symmetrically
      -- just test a simple case to see if it doesn't crash

      it('should accelerate on y when vy = 0 and input y ~= 0', function ()
        pc.debug_velocity.y = 0
        pc.move_intention.y = -1

        pc:update_velocity_component_debug("y")

        assert.are_equal(- pc.debug_move_accel, pc.debug_velocity.y)
      end)

      -- kind of itest to combine both X and Y

      it('should accelerate/decelerate with friction on xy when there is input from 0 on x, no input on y', function ()
        pc.debug_velocity = vector(0, 2)
        pc.move_intention = vector(-1, 0)

        pc:update_velocity_component_debug("x")
        pc:update_velocity_component_debug("y")

        assert.are_same(vector(- pc.debug_move_accel, 2 - pc.debug_move_friction), pc.debug_velocity)
      end)

      describe('(when player is pressing double debug speed input)', function ()

        before_each(function ()
          input.players_btn_states[0][button_ids.o] = btn_states.pressed
        end)

        after_each(function ()
          input:init()
        end)

        it('should change nothing when debug speed and move intention in x is 0', function ()
          pc.debug_velocity.x = 0
          pc.move_intention.x = 0

          pc:update_velocity_component_debug("x")

          assert.are_equal(0, pc.debug_velocity.x)
        end)

        it('should accelerate on x with 2x final speed when vx = 0 and input x ~= 0', function ()
          pc.debug_velocity.x = 0
          pc.move_intention.x = -1

          pc:update_velocity_component_debug("x")

          assert.are_equal(- 2 * pc.debug_move_accel, pc.debug_velocity.x)
        end)

      end)

    end)

    describe('update_anim', function ()

      setup(function ()
        spy.on(player_char, "check_play_anim")
        spy.on(player_char, "check_update_sprite_angle")
      end)

      teardown(function ()
        player_char.check_play_anim:revert()
        player_char.check_update_sprite_angle:revert()
      end)

      it('should call _check_play_anim and _check_update_sprite_angle', function ()
        pc:update_anim()

        assert.spy(player_char.check_play_anim).was_called(1)
        assert.spy(player_char.check_play_anim).was_called_with(match.ref(pc))
        assert.spy(player_char.check_update_sprite_angle).was_called(1)
        assert.spy(player_char.check_update_sprite_angle).was_called_with(match.ref(pc))
      end)

    end)

    describe('check_play_anim', function ()

      setup(function ()
        -- spy.on would help testing more deeply, but we prefer utests independent
        --  from other modules nor animation data
        stub(animated_sprite, "play")
      end)

      teardown(function ()
        animated_sprite.play:revert()
      end)

      -- since pc is init in before_each and init calls _setup
      --   which calls pc.anim_spr:play, we must clear call count just after that
      before_each(function ()
        animated_sprite.play:clear()
      end)

      it('should play brake start animation (and preserve brake_anim_phase) when brake_anim_phase: 1 and return immediately', function ()
        -- works in any state; in practice, only standing and falling can have it
        --  as other states will reset the flag
        pc.motion_state = motion_states.falling
        pc.brake_anim_phase = 1

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "brake_start")

        assert.are_equal(1, pc.brake_anim_phase)
      end)

      it('should play brake reverse animation (and preserve brake_anim_phase) when brake_anim_phase: 2 and return immediately if anim is still playing', function ()
        -- works in any state; in practice, only standing and falling can have it
        --  as other states will reset the flag
        pc.motion_state = motion_states.falling
        pc.brake_anim_phase = 2

        -- this will simulate that the animation is already playing (or starts playing with the next call)
        --  without having to stub check_play_anim, or even more complicated to spy.on it but set
        --  manually current_anim_key to "brake" to preserve playing, or something else to start playing
        pc.anim_spr.playing = true

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "brake_reverse")

        assert.are_equal(2, pc.brake_anim_phase)
      end)

      it('should try to play brake animation one last time and reset brake_anim_phase, then fallback to general case when brake_anim_phase: 2 but animation has stopped playing', function ()
        -- works in any state; in practice, only standing and falling can have it
        --  as other states will reset the flag
        pc.motion_state = motion_states.standing
        pc.brake_anim_phase = 2

        -- this is the default, but to make it clear the the animation has stopped playing
        -- as we stub check_play_anim, we don't have to set anim_spr.current_anim_key to
        --  "brake" just to prevent playing being set again
        pc.anim_spr.playing = false

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(2)
        -- tentative play -> not playing anymore
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "brake_reverse")
        -- fallback based on motion_state
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "idle")

        assert.are_equal(0, pc.brake_anim_phase)
      end)

      it('should play idle anim when standing and ground speed is 0', function ()
        pc.motion_state = motion_states.standing
        pc.ground_speed = 0

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "idle")
      end)

      it('should play walk anim with walk_anim_min_play_speed when standing and ground speed is lower than anim_run_speed in abs (clamping)', function ()
        pc.motion_state = motion_states.standing
        pc.ground_speed = -pc_data.walk_anim_min_play_speed / 2  -- it's very low, much lower than walk_anim_min_play_speed
        pc.anim_run_speed = abs(pc.ground_speed)

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "walk", false, pc_data.walk_anim_min_play_speed)
      end)

      it('should play walk anim with last anim_run_speed when standing and ground speed is low', function ()
        pc.motion_state = motion_states.standing
        pc.ground_speed = -(pc_data.run_cycle_min_speed_frame - 0.1) -- -2.9
        pc.anim_run_speed = abs(pc.ground_speed)                     -- 2.9

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "walk", false, 2.9)
      end)

      it('should play run anim with last anim_run_speed when standing and ground speed is high', function ()
        pc.motion_state = motion_states.standing
        pc.ground_speed = -pc_data.run_cycle_min_speed_frame         -- -3.0
        pc.anim_run_speed = abs(pc.ground_speed)                     -- 3.0, much higher than walk_anim_min_play_speed

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "run", false, 3.0)
      end)

      it('should play spring_jump when "falling upward" with should_play_spring_jump: true', function ()
        pc.motion_state = motion_states.falling
        pc.should_play_spring_jump = true

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "spring_jump")
      end)

      it('(low anim speed) should stop spring_jump anim and play walk anim at walk_anim_min_play_speed when falling with should_play_spring_jump: true but velocity.y > 0 (falling down again) and anim run speed is lower than anim_run_speed in abs (clamping)', function ()
        pc.motion_state = motion_states.falling
        pc.velocity.y = 1
        pc.anim_run_speed = pc_data.walk_anim_min_play_speed / 2  -- it's very low, much lower than walk_anim_min_play_speed
        pc.should_play_spring_jump = true

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "walk", false, pc_data.walk_anim_min_play_speed)
      end)

      it('(low anim speed) should stop spring_jump anim and play walk anim when falling with should_play_spring_jump: true but velocity.y > 0 (falling down again)', function ()
        pc.motion_state = motion_states.falling
        pc.velocity.y = 1
        pc.anim_run_speed = pc_data.run_cycle_min_speed_frame - 0.1  -- 2.9
        pc.should_play_spring_jump = true

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "walk", false, 2.9)
      end)

      it('(high anim speed) should stop spring_jump anim and play run anim when falling with should_play_spring_jump: true but velocity.y > 0 (falling down again)', function ()
        pc.motion_state = motion_states.falling
        pc.velocity.y = 1
        pc.anim_run_speed = pc_data.run_cycle_min_speed_frame  -- 3.0
        pc.should_play_spring_jump = true

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "run", false, 3.0)
      end)

      it('(low anim speed) should play walk anim with last anim_run_speed when falling and should_play_spring_jump is false', function ()
        pc.anim_run_speed = pc_data.run_cycle_min_speed_frame - 0.1  -- 2.9
        pc.motion_state = motion_states.falling

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "walk", false, 2.9)
      end)

      it('(high anim speed)should play run anim with last anim_run_speed when falling and should_play_spring_jump is false', function ()
        pc.anim_run_speed = pc_data.run_cycle_min_speed_frame  -- 3.0
        pc.motion_state = motion_states.falling

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "run", false, 3.0)
      end)

      it('(air spin with anim_run_speed below air_spin_anim_min_play_speed) should play spin anim at air_spin_anim_min_play_speed', function ()
        pc.anim_run_speed = pc_data.air_spin_anim_min_play_speed / 2
        pc.motion_state = motion_states.air_spin

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "spin", false, pc_data.air_spin_anim_min_play_speed)
      end)

      it('(air spin with anim_run_speed above air_spin_anim_min_play_speed) should play spin_fast anim at anim_run_speed', function ()
        pc.anim_run_speed = pc_data.air_spin_anim_min_play_speed + 1
        pc.motion_state = motion_states.air_spin

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "spin", false, pc_data.air_spin_anim_min_play_speed + 1)
      end)

      -- rolling uses the same animation as air_spin but with a different minimum, so we check this threshold instead

      it('(rolling with anim_run_speed below rolling_spin_anim_min_play_speed) should play spin_fast anim at rolling_spin_anim_min_play_speed', function ()
        pc.anim_run_speed = pc_data.rolling_spin_anim_min_play_speed / 2
        pc.motion_state = motion_states.rolling

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "spin", false, pc_data.rolling_spin_anim_min_play_speed)
      end)

      it('(rolling with anim_run_speed above rolling_spin_anim_min_play_speed) should play spin_fast anim at rolling_spin_anim_min_play_speed', function ()
        pc.anim_run_speed = pc_data.rolling_spin_anim_min_play_speed + 1
        pc.motion_state = motion_states.rolling

        pc:check_play_anim()

        assert.spy(animated_sprite.play).was_called(1)
        assert.spy(animated_sprite.play).was_called_with(match.ref(pc.anim_spr), "spin", false, pc_data.rolling_spin_anim_min_play_speed + 1)
      end)

    end)

    describe('check_update_sprite_angle', function ()

      it('should preserve sprite angle when motion state is not falling', function ()
        pc.motion_state = motion_states.standing
        pc.continuous_sprite_angle = 0.5

        pc:check_update_sprite_angle()

        assert.are_equal(0.5, pc.continuous_sprite_angle)
      end)

      it('should preserve sprite angle when sprite angle is 0', function ()
        pc.motion_state = motion_states.falling
        pc.continuous_sprite_angle = 0

        pc:check_update_sprite_angle()

        assert.are_equal(0, pc.continuous_sprite_angle)
      end)

      -- sprite angle should always move toward 0 via shortest path
      -- angle = 0.5 is an edge case and we don't mind either choice, so we don't test it

      it('should move sprite angle toward 0 (via the right arc) by pc_data.sprite_angle_airborne_reset_speed_frame when sprite angle is not 0', function ()
        pc.motion_state = motion_states.falling
        pc.continuous_sprite_angle = 0.25

        pc:check_update_sprite_angle()

        assert(pc_data.sprite_angle_airborne_reset_speed_frame < 0.25, "pc_data.sprite_angle_airborne_reset_speed_frame >= 0.25, we are testing another case where we are going to clamp")
        -- moving clockwise, so - angle
        assert.are_equal(0.25 - pc_data.sprite_angle_airborne_reset_speed_frame, pc.continuous_sprite_angle)
      end)

      it('should move sprite angle toward 0 (via the left arc) by pc_data.sprite_angle_airborne_reset_speed_frame when sprite angle is not 0', function ()
        pc.motion_state = motion_states.falling
        pc.continuous_sprite_angle = 0.75

        pc:check_update_sprite_angle()

        assert(pc_data.sprite_angle_airborne_reset_speed_frame < 0.25, "pc_data.sprite_angle_airborne_reset_speed_frame >= 0.25, we are testing another case where we are going to clamp")
        -- moving counter-clockwise, so + angle
        assert.are_equal(0.75 + pc_data.sprite_angle_airborne_reset_speed_frame, pc.continuous_sprite_angle)
      end)

      it('should set sprite angle to 0 due to clamping when sprite angle is a bit counter-clockwise of 0, lower than pc_data.sprite_angle_airborne_reset_speed_frame', function ()
        pc.motion_state = motion_states.falling
        pc.continuous_sprite_angle = pc_data.sprite_angle_airborne_reset_speed_frame / 2

        pc:check_update_sprite_angle()

        assert(pc_data.sprite_angle_airborne_reset_speed_frame < 0.25, "pc_data.sprite_angle_airborne_reset_speed_frame >= 0.25, we are testing another case where we are going to clamp")
        -- moving clockwise, but it doesn't matter as we reach 0
        assert.are_equal(0, pc.continuous_sprite_angle)
      end)

      it('should set sprite angle to 0 due to clamping when sprite angle is a bit clockwise of 0, lower than pc_data.sprite_angle_airborne_reset_speed_frame', function ()
        pc.motion_state = motion_states.falling
        pc.continuous_sprite_angle = 1 - pc_data.sprite_angle_airborne_reset_speed_frame / 2

        pc:check_update_sprite_angle()

        assert(pc_data.sprite_angle_airborne_reset_speed_frame < 0.25, "pc_data.sprite_angle_airborne_reset_speed_frame >= 0.25, we are testing another case where we are going to clamp")
        -- moving counter-clockwise, but it doesn't matter as we reach 0
        assert.are_equal(0, pc.continuous_sprite_angle)
      end)

    end)

    describe('reload_rotated_sprites', function ()

      setup(function ()
        stub(_G, "memcpy")
      end)

      teardown(function ()
        memcpy:revert()
      end)

      after_each(function ()
        memcpy:clear()
      end)

      it('should copy non-rotated sprites in general memory back to spritesheet', function ()
        pc:reload_rotated_sprites()

        assert.spy(memcpy).was_called(32)
        -- too many calls to check them all, but test at least the first ones of each
        -- to verify addr_offset is correct
        assert.spy(memcpy).was_called_with(0x1008, 0x5300, 0x30)
        assert.spy(memcpy).was_called_with(0x1048, 0x5330, 0x30)
        assert.spy(memcpy).was_called_with(0x1400, 0x5600, 0x20)
        assert.spy(memcpy).was_called_with(0x1440, 0x5620, 0x20)
      end)

      it('should copy rotated sprites in general memory back to spritesheet', function ()
        pc:reload_rotated_sprites(true)

        assert.spy(memcpy).was_called(32)
        -- too many calls to check them all, but test at least the first ones of each
        -- to verify addr_offset is correct
        assert.spy(memcpy).was_called_with(0x1008, 0x5800, 0x30)
        assert.spy(memcpy).was_called_with(0x1048, 0x5830, 0x30)
        assert.spy(memcpy).was_called_with(0x1400, 0x5b00, 0x20)
        assert.spy(memcpy).was_called_with(0x1440, 0x5b20, 0x20)
      end)

    end)

    describe('render', function ()

      setup(function ()
        stub(animated_sprite, "render")
        stub(player_char, "reload_rotated_sprites")
      end)

      teardown(function ()
        animated_sprite.render:revert()
        player_char.reload_rotated_sprites:revert()
      end)

      after_each(function ()
        animated_sprite.render:clear()
        player_char.reload_rotated_sprites:clear()
      end)

      describe('(brake_start)', function ()

        before_each(function ()
          pc.anim_spr.current_anim_key = "brake_start"
        end)

        it('(when character is facing left, any angle) should only call render on sonic sprite data: idle with the character\'s position floored, flipped x, angle 0', function ()
          pc.position = vector(12.5, 8.2)
          pc.orientation = horizontal_dirs.left
          pc.continuous_sprite_angle = 0.25

          pc:render()

          assert.spy(player_char.reload_rotated_sprites).was_not_called()

          assert.spy(animated_sprite.render).was_called(1)
          -- sprite is already rotated by 45, so the additional angle is 0
          assert.spy(animated_sprite.render).was_called_with(match.ref(pc.anim_spr), vector(12, 8), true, false, 0)
        end)

        it('(when character is facing right, any angle) should only call render on sonic sprite data: idle with the character\'s position floored, not flipped x, angle 0', function ()
          pc.position = vector(12.5, 8.2)
          pc.orientation = horizontal_dirs.right
          pc.continuous_sprite_angle = 0.75

          pc:render()

          assert.spy(player_char.reload_rotated_sprites).was_not_called()

          assert.spy(animated_sprite.render).was_called(1)
          -- note that we don't apply modulo and count on render to detect that 1 == 0 [1], so we effectively pass 1
          assert.spy(animated_sprite.render).was_called_with(match.ref(pc.anim_spr), vector(12, 8), false, false, 0)
        end)

      end)

      describe('(walk)', function ()

        before_each(function ()
          pc.anim_spr.current_anim_key = "walk"
        end)

        it('(when character is facing left, closer to cardinal angle) should reload non-rotated sprites and call render on sonic sprite data: idle with the character\'s position floored, flipped x, current slope angle rounded to closest 45-degree step', function ()
          pc.position = vector(12.5, 8.2)
          pc.orientation = horizontal_dirs.left
          pc.continuous_sprite_angle = 0.25 - 0.0624  -- closer to 0.25 than 0.125

          pc:render()

          assert.spy(player_char.reload_rotated_sprites).was_called(1)
          assert.spy(player_char.reload_rotated_sprites).was_called_with(match.ref(pc))

          assert.spy(animated_sprite.render).was_called(1)
          assert.spy(animated_sprite.render).was_called_with(match.ref(pc.anim_spr), vector(12, 8), true, false, 0.25)
        end)

        it('(when character is facing left, closer to diagonal angle) should reload 45-degree rotated sprites and call render on sonic sprite data: idle with the character\'s position floored, flipped x, current slope angle rounded to closest 45-degree step MINUS 45 deg', function ()
          pc.position = vector(12.5, 8.2)
          pc.orientation = horizontal_dirs.left
          pc.continuous_sprite_angle = 0.0626  -- closer to 0.125 than 0

          pc:render()

          assert.spy(player_char.reload_rotated_sprites).was_called(1)
          assert.spy(player_char.reload_rotated_sprites).was_called_with(match.ref(pc), true)

          assert.spy(animated_sprite.render).was_called(1)
          -- sprite is already rotated by 45, so the additional angle is 0
          assert.spy(animated_sprite.render).was_called_with(match.ref(pc.anim_spr), vector(12, 8), true, false, 0.25)
        end)

        it('(when character is facing right, closer to cardinal angle) should reload non-rotated sprites and call render on sonic sprite data: idle with the character\'s position floored, not flipped x, current slope angle rounded to closest 45-degree step', function ()
          pc.position = vector(12.5, 8.2)
          pc.orientation = horizontal_dirs.right
          pc.continuous_sprite_angle = 1 - 0.0624  -- closer to 1 (i.e. 0 modulo 1) than 0.875

          pc:render()

          assert.spy(player_char.reload_rotated_sprites).was_called(1)
          assert.spy(player_char.reload_rotated_sprites).was_called_with(match.ref(pc))

          assert.spy(animated_sprite.render).was_called(1)
          -- note that we don't apply modulo and count on render to detect that 1 == 0 [1], so we effectively pass 1
          assert.spy(animated_sprite.render).was_called_with(match.ref(pc.anim_spr), vector(12, 8), false, false, 1)
        end)

        it('(when character is facing right, closer to diagonal angle) should reload 45-degree rotated sprites and call render on sonic sprite data: idle with the character\'s position floored, not flipped x, current slope angle rounded to closest 45-degree step MINUS 45 deg', function ()
          pc.position = vector(12.5, 8.2)
          pc.orientation = horizontal_dirs.right
          pc.continuous_sprite_angle = 0.875 + 0.0624  -- closer to 0.875 than 1 (0 modulo 1)

          pc:render()

          assert.spy(player_char.reload_rotated_sprites).was_called(1)
          assert.spy(player_char.reload_rotated_sprites).was_called_with(match.ref(pc), true)

          assert.spy(animated_sprite.render).was_called(1)
          -- sprite is already rotated by 45, so the additional angle is only 0.75
          assert.spy(animated_sprite.render).was_called_with(match.ref(pc.anim_spr), vector(12, 8), false, false, 0.75)
        end)

      end)

    end)

    describe('play_low_priority_sfx', function ()

      local channel3_sfx = -1

      setup(function ()
        stub(_G, "stat", function (n)
          return channel3_sfx
        end)
        stub(_G, "sfx")
      end)

      teardown(function ()
        stat:revert()
        sfx:revert()
      end)

      after_each(function ()
        stat:clear()
        sfx:clear()
        channel3_sfx = -1
      end)

      it('should play sfx when nothing in played on target channel', function ()
        pc:play_low_priority_sfx(5)
        assert.spy(sfx).was_called(1)
        assert.spy(sfx).was_called_with(5)
      end)

      it('should play sfx when another low-prio sfx is played target channel', function ()
        channel3_sfx = audio.sfx_ids.jump

        pc:play_low_priority_sfx(5)
        assert.spy(sfx).was_called(1)
        assert.spy(sfx).was_called_with(5)
      end)

      it('should not play sfx when jingle is played on target channel', function ()
        channel3_sfx = audio.sfx_ids.pick_emerald

        pc:play_low_priority_sfx(5)
        assert.spy(sfx).was_not_called()
      end)

    end)

  end)

end)

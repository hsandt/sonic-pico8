require("bustedhelper")
require("engine/core/math")
local player_character = require("game/ingame/playercharacter")
local collision = require("engine/physics/collision")
local playercharacter_data = require("game/data/playercharacter_data")
local tile_test_data = require("game/test_data/tile_test_data")

describe('player_character', function ()

  -- static method
  describe('_compute_max_column_distance', function ()

    it('(2, 0) => 0', function ()
      assert.are_equal(0, player_character._compute_max_column_distance(2, 0))
    end)

    it('(2, 1.5) => 1', function ()
      assert.are_equal(1, player_character._compute_max_column_distance(2, 1.5))
    end)

    it('(2, 3) => 3', function ()
      assert.are_equal(3, player_character._compute_max_column_distance(2, 3))
    end)

    it('(2.2, 1.7) => 1', function ()
      assert.are_equal(1, player_character._compute_max_column_distance(2.2, 1.7))
    end)

    it('(2.2, 1.8) => 2', function ()
      assert.are_equal(2, player_character._compute_max_column_distance(2.2, 1.8))
    end)

  end)

  describe('_init', function ()

    setup(function ()
      spy.on(player_character, "_setup")
    end)

    teardown(function ()
      player_character._setup:revert()
    end)

    after_each(function ()
      player_character._setup:clear()
    end)

    it('should create a player character and setup all the state vars', function ()
      local player_char = player_character()
      assert.is_not_nil(player_char)

      -- implementation
      assert.spy(player_character._setup).was_called(1)
      assert.spy(player_character._setup).was_called_with(match.ref(player_char))
    end)

    it('should create a player character with control mode: human, motion mode: platformer, motion state: grounded', function ()
      local player_char = player_character()
      assert.is_not_nil(player_char)
      assert.are_same({control_modes.human, motion_modes.platformer, motion_states.grounded},
        {player_char.control_mode, player_char.motion_mode, player_char.motion_state})
    end)

    it('should create a player character storing values from playercharacter_data', function ()
      local player_char = player_character()
      assert.is_not_nil(player_char)
      assert.are_same(
        {
          playercharacter_data.sonic_sprite_data,
          playercharacter_data.debug_move_max_speed,
          playercharacter_data.debug_move_accel,
          playercharacter_data.debug_move_decel
        },
        {
          player_char.spr_data,
          player_char.debug_move_max_speed,
          player_char.debug_move_accel,
          player_char.debug_move_decel
        }
      )
    end)
  end)

  describe('_setup', function ()

    it('should reset the character state vars', function ()
      local player_char = player_character()
      assert.is_not_nil(player_char)
      assert.are_same(
        {
          vector.zero(),
          0,
          vector.zero(),
          vector.zero(),
          0,
          vector.zero(),
          false,
          false,
          false,
          false,
          "idle"
        },
        {
          player_char.position,
          player_char.ground_speed_frame,
          player_char.velocity_frame,
          player_char.debug_velocity,
          player_char.slope_angle,
          player_char.move_intention,
          player_char.jump_intention,
          player_char.hold_jump_intention,
          player_char.should_jump,
          player_char.has_interrupted_jump,
          player_char.current_sprite
        }
      )
    end)

  end)

  describe('(with player character, speed 60, debug accel 480)', function ()
    local player_char

    before_each(function ()
      -- recreate player character for each test (setup spies will need to refer to player_char, not the instance)
      player_char = player_character()
      player_char.debug_move_max_speed = 60.
      player_char.debug_move_accel = 480.
      player_char.debug_move_decel = 480.
    end)

    describe('spawn_at', function ()

      local enter_motion_state_stub

      setup(function ()
        enter_motion_state_stub = stub(player_character, "_enter_motion_state")
      end)

      teardown(function ()
        enter_motion_state_stub:revert()
      end)

      after_each(function ()
        enter_motion_state_stub:clear()
      end)

      it('should set the character\'s position', function ()
        player_char:spawn_at(vector(56, 12))
        assert.are_equal(vector(56, 12), player_char.position)
      end)

      describe('(_check_escape_from_ground returns false)', function ()

        local check_escape_from_ground_mock

        setup(function ()
          check_escape_from_ground_mock = stub(player_character, "_check_escape_from_ground", function (self)
            return false
          end)
        end)

        teardown(function ()
          check_escape_from_ground_mock:revert()
        end)

        it('should call _check_escape_from_ground and _enter_motion_state(motion_states.airborne)', function ()
          player_char:spawn_at(vector(56, 12))

          -- implementation
          assert.spy(check_escape_from_ground_mock).was_called(1)
          assert.spy(check_escape_from_ground_mock).was_called_with(match.ref(player_char))
          assert.spy(enter_motion_state_stub).was_called(1)
          assert.spy(enter_motion_state_stub).was_called_with(match.ref(player_char), motion_states.airborne)
        end)

      end)

      describe('(_check_escape_from_ground returns true)', function ()

        local check_escape_from_ground_mock

        setup(function ()
          check_escape_from_ground_mock = stub(player_character, "_check_escape_from_ground", function (self)
            return true
          end)
        end)

        teardown(function ()
          check_escape_from_ground_mock:revert()
        end)

        it('should call _check_escape_from_ground and _enter_motion_state(motion_states.airborne)', function ()
          player_char:spawn_at(vector(56, 12))

          -- implementation
          assert.spy(check_escape_from_ground_mock).was_called(1)
          assert.spy(check_escape_from_ground_mock).was_called_with(match.ref(player_char))
          assert.spy(enter_motion_state_stub).was_not_called()
        end)

      end)

    end)

    describe('get_bottom_center', function ()
      it('(10 0 3) => at (10 6)', function ()
        player_char.position = vector(10, 0)
        assert.are_equal(vector(10, 0 + playercharacter_data.center_height_standing), player_char:get_bottom_center())
      end)
    end)

    describe('+ set_bottom_center', function ()
      it('set_bottom_center (10 6) => at (10 0)', function ()
        player_char:set_bottom_center(vector(10, 0 + playercharacter_data.center_height_standing))
        assert.are_equal(vector(10, 0), player_char.position)
      end)
    end)

    describe('move_by', function ()
      it('at (4 -4) move_by (-5 4) => at (-1 0)', function ()
        player_char.position = vector(4, -4)
        player_char:move_by(vector(-5, 4))
        assert.are_equal(vector(-1, 0), player_char.position)
      end)
    end)

    describe('update', function ()

      local update_platformer_motion_stub
      local update_debug_stub

      setup(function ()
        update_platformer_motion_stub = stub(player_character, "_update_platformer_motion")
        update_debug_stub = stub(player_character, "_update_debug")
      end)

      teardown(function ()
        update_platformer_motion_stub:revert()
        update_debug_stub:revert()
      end)

      after_each(function ()
        update_platformer_motion_stub:clear()
        update_debug_stub:clear()
      end)

      describe('(when motion mode is platformer)', function ()

        it('should call _update_platformer_motion', function ()
          player_char:update()
          assert.spy(update_platformer_motion_stub).was_called(1)
          assert.spy(update_platformer_motion_stub).was_called_with(match.ref(player_char))
          assert.spy(update_debug_stub).was_not_called()
        end)

      end)

      describe('(when motion mode is debug)', function ()

        before_each(function ()
          player_char.motion_mode = motion_modes.debug
        end)

        it('. should call _update_debug', function ()
          player_char:update()
          assert.spy(update_platformer_motion_stub).was_not_called()
          assert.spy(update_debug_stub).was_called(1)
          assert.spy(update_debug_stub).was_called_with(match.ref(player_char))
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

      describe('_compute_ground_sensors_signed_distance', function ()

        -- interface tests are mostly redundant with _compute_signed_distance_to_closest_ground
        -- so we prefer implementation tests, checking that it calls the later with both sensor positions

        describe('with stubs', function ()

          local get_ground_sensor_position_from_mock
          local compute_signed_distance_to_closest_ground_mock

          local get_prioritized_dir_mock

          setup(function ()
            get_ground_sensor_position_from_mock = stub(player_character, "_get_ground_sensor_position_from", function (self, center_position, i)
              return i == horizontal_directions.left and vector(-1, center_position.y) or vector(1, center_position.y)
            end)

            compute_signed_distance_to_closest_ground_mock = stub(player_character, "_compute_signed_distance_to_closest_ground", function (self, sensor_position)
              if sensor_position == vector(-1, 0) then
                return -4, 0.25
              elseif sensor_position == vector(1, 0) then
                return 5, -0.125
              elseif sensor_position == vector(-1, 1) then
                return 7, -0.25
              elseif sensor_position == vector(1, 1) then
                return 6, 0.25
              elseif sensor_position == vector(-1, 2) then
                return 3, 0
              else  -- sensor_position == vector(1, 2)
                return 3, 0.125
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

          it('should return the signed distance to closest ground from left sensor if the lowest', function ()
            -- -4 vs 5 => -4
            assert.are_same({-4, 0.25}, {player_char:_compute_ground_sensors_signed_distance(vector(0, 0))})
          end)

          it('should return the signed distance to closest ground from right sensor if the lowest', function ()
            -- 7 vs 6 => 6
            assert.are_same({6, 0.25}, {player_char:_compute_ground_sensors_signed_distance(vector(0, 1))})
          end)

          describe('(prioritized direction is left)', function ()

            setup(function ()
              get_prioritized_dir_mock = stub(player_character, "_get_prioritized_dir", function (self)
                return horizontal_directions.left
              end)
            end)

            teardown(function ()
              get_prioritized_dir_mock:revert()
            end)

            it('should return the signed distance to left ground if both sensors are at the same level, but left is prioritized', function ()
              -- 3 vs 3 => 3 left
              assert.are_same({3, 0}, {player_char:_compute_ground_sensors_signed_distance(vector(0, 2))})
            end)

          end)

          describe('(prioritized direction is right)', function ()

            local get_prioritized_dir_mock

            setup(function ()
              get_prioritized_dir_mock = stub(player_character, "_get_prioritized_dir", function (self)
                return horizontal_directions.right
              end)
            end)

            teardown(function ()
              get_prioritized_dir_mock:revert()
            end)

            it('should return the signed distance to right ground if both sensors are at the same level, but left is prioritized', function ()
              -- 3 vs 3 => 3 right
              assert.are_same({3, 0.125}, {player_char:_compute_ground_sensors_signed_distance(vector(0, 2))})
            end)

          end)

        end)

      end)

      describe('_get_prioritized_dir', function ()

        it('should return left when character is moving on ground toward left', function ()
          player_char.ground_speed_frame = -4
          assert.are_equal(horizontal_directions.left, player_char:_get_prioritized_dir())
        end)

        it('should return right when character is moving on ground toward left', function ()
          player_char.ground_speed_frame = 4
          assert.are_equal(horizontal_directions.right, player_char:_get_prioritized_dir())
        end)

        it('should return left when character is moving airborne toward left', function ()
          player_char.motion_state = motion_states.airborne
          player_char.velocity_frame.x = -4
          assert.are_equal(horizontal_directions.left, player_char:_get_prioritized_dir())
        end)

        it('should return right when character is moving airborne toward right', function ()
          player_char.motion_state = motion_states.airborne
          player_char.velocity_frame.x = 4
          assert.are_equal(horizontal_directions.right, player_char:_get_prioritized_dir())
        end)

        it('should return left when character is not moving and facing left', function ()
          player_char.horizontal_dir = horizontal_directions.left
          assert.are_equal(horizontal_directions.left, player_char:_get_prioritized_dir())
        end)

        it('should return right when character is not moving and facing right', function ()
          player_char.horizontal_dir = horizontal_directions.right
          assert.are_equal(horizontal_directions.right, player_char:_get_prioritized_dir())
        end)

      end)

      describe('_get_ground_sensor_position_from', function ()

        it('* should return the position down-left of the character center when horizontal dir is left', function ()
          assert.are_equal(vector(7, 10 + playercharacter_data.center_height_standing), player_char:_get_ground_sensor_position_from(vector(10, 10), horizontal_directions.left))
        end)

        it('should return the position down-left of the x-floored character center when horizontal dir is left', function ()
          assert.are_equal(vector(7, 10 + playercharacter_data.center_height_standing), player_char:_get_ground_sensor_position_from(vector(10.9, 10), horizontal_directions.left))
        end)

        it('* should return the position down-left of the character center when horizontal dir is right', function ()
          assert.are_equal(vector(12, 10 + playercharacter_data.center_height_standing), player_char:_get_ground_sensor_position_from(vector(10, 10), horizontal_directions.right))
        end)

        it('should return the position down-left of the x-floored character center when horizontal dir is right', function ()
          assert.are_equal(vector(12, 10 + playercharacter_data.center_height_standing), player_char:_get_ground_sensor_position_from(vector(10.9, 10), horizontal_directions.right))
        end)

      end)

      describe('_compute_signed_distance_to_closest_ground', function ()

        describe('with full flat tile', function ()

          before_each(function ()
            -- create a full tile at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 64)
          end)

          -- just above

          it('should return tile_size+1, nil if above the tile by 10>tile_size (clamped to tile_size)', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 8 - 10))})
          end)

          it('should return 0.0625, 0 if just a above the tile by 0.0625', function ()
            assert.are_same({0.0625, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 8 - 0.0625))})
          end)

          -- on top

          it('+ should return tile_size+1, nil if just at ground height but slightly on the left', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(7, 8))})
          end)

          it('should return 0, 0 if just at the top of the topleft-most pixel of the tile', function ()
            assert.are_same({0, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 8))})
          end)

          it('should return 0, 0 if just at the top of tile, in the middle', function ()
            assert.are_same({0, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 8))})
          end)

          it('should return 0, 0 if just at the top of the right-most pixel', function ()
            assert.are_same({0, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 8))})
          end)

          it('should return tile_size+1, nil if just at ground height but slightly on the right', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(16, 8))})
          end)

          -- just inside the top

          it('should return tile_size+1, nil if just on the left of the top-left pixel, y at 0.0625 below the top', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(7, 8 + 0.0625))})
          end)

          it('should return -0.0625, 0 if 0.0625 inside the top-left pixel', function ()
            assert.are_same({-0.0625, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 8 + 0.0625))})
          end)

          it('should return -0.0625, 0 if 0.0625 inside the top-right pixel', function ()
            assert.are_same({-0.0625, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 8 + 0.0625))})
          end)

          it('should return tile_size+1. nil if just on the right of the top-right pixel, y at 0.0625 below the top', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(16, 8 + 0.0625))})
          end)

          -- just inside the bottom

          it('should return tile_size+1, nil if just on the left of the bottom-left pixel, y at 0.0625 above the bottom', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(7, 16 - 0.0625))})
          end)

          it('should return -(8 - 0.0625), 0 if 0.0625 inside the bottom-left pixel', function ()
            assert.are_same({-(8 - 0.0625), 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 16 - 0.0625))})
          end)

          it('should return -(8 - 0.0625), 0 if 0.0625 inside the bottom-right pixel', function ()
            assert.are_same({-(8 - 0.0625), 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 16 - 0.0625))})
          end)

          it('should return tile_size+1, nil if on the right of the bottom-right pixel, y at 0.0625 above the bottom', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(16, 16 - 0.0625))})
          end)

        end)

        describe('with half flat tile', function ()

          before_each(function ()
            -- create a half-tile at (1, 1), top-left at (8, 12), top-right at (15, 16) included
            mset(1, 1, 70)
          end)

          -- just above

          it('should return 0.0625, 0 if just a little above the tile', function ()
            assert.are_same({0.0625, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 12 - 0.0625))})
          end)

          -- on top

          it('+ should return tile_size+1, nil if just touching the left of the tile at the ground\'s height', function ()
            -- right ground sensor @ (7.5, 12)
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(7, 12))})
          end)

          it('should return 0, 0 if just at the top of the topleft-most pixel of the tile', function ()
            assert.are_same({0, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 12))})
          end)

          it('should return 0, 0 if just at the top of tile, in the middle', function ()
            assert.are_same({0, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 12))})
          end)

          it('should return 0, 0 if just at the top of the right-most pixel', function ()
            assert.are_same({0, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 12))})
          end)

          it('should return tile_size+1, nil if in the air on the right of the tile', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(16, 12))})
          end)

          -- just inside the top

          it('should return tile_size+1, nil if just on the left of the topleft pixel, y at 0.0625 below the top', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(7, 12 + 0.0625))})
          end)

          it('should return -0.0625, 0 if 0.0625 inside the topleft pixel', function ()
            assert.are_same({-0.0625, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 12 + 0.0625))})
          end)

          it('should return -0.0625, 0 if 0.0625 inside the topright pixel', function ()
            assert.are_same({-0.0625, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 12 + 0.0625))})
          end)

          it('should return tile_size+1, nil if just on the right of the topright pixel, y at 0.0625 below the top', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(16, 12 + 0.0625))})
          end)

          -- just inside the bottom

          it('should return tile_size+1, nil if just on the left of the topleft pixel, y at 0.0625 above the bottom', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(7, 16 - 0.0625))})
          end)

          it('should return -(4 - 0.0625), 0 if 0.0625 inside the topleft pixel', function ()
            assert.are_same({-(4 - 0.0625), 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 16 - 0.0625))})
          end)

          it('should return -(4 - 0.0625), 0 if 0.0625 inside the topright pixel', function ()
            assert.are_same({-(4 - 0.0625), 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 16 - 0.0625))})
          end)

          it('should return tile_size+1, nil if just on the right of the topright pixel, y at 0.0625 above the bottom', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(16, 16 - 0.0625))})
          end)

        end)

        describe('with ascending slope 45', function ()

          before_each(function ()
            -- create an ascending slope at (1, 1), i.e. (8, 15) to (15, 8) px
            mset(1, 1, 65)
          end)

          it('should return 0.0625, -45/360 if just above slope column 0', function ()
            assert.are_same({0.0625, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 15 - 0.0625))})
          end)

          it('should return 0, -45/360 if at the top of column 0', function ()
            assert.are_same({0, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 15))})
          end)

          it('. should return 0.0625, -45/360 if just above slope column 4', function ()
            assert.are_same({0.0625, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 11 - 0.0625))})
          end)

          it('. should return 0, -45/360 if at the top of column 4', function ()
            assert.are_same({0, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 11))})
          end)

          it('should return -2, -45/360 if 2px below column 4', function ()
            assert.are_same({-2, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 13))})
          end)

          it('should return 0.0625, -45/360 if right sensor is just above slope column 0', function ()
            assert.are_same({0.0625, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 8 - 0.0625))})
          end)

          it('should return 0, -45/360 if right sensor is at the top of column 0', function ()
            assert.are_same({0, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 8))})
          end)

          it('should return -3, -45/360 if 3px below column 0', function ()
            assert.are_same({-3, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 11))})
          end)

          it('. should return 0.0625, -45/360 if just above slope column 3', function ()
            assert.are_same({0.0625, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(11, 12 - 0.0625))})
          end)

          it('. should return 0, -45/360 if at the top of column 3', function ()
            assert.are_same({0, -45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(11, 12))})
          end)

        end)

        describe('with descending slope 45', function ()

          before_each(function ()
            -- create a descending slope at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 66)
          end)

          it('. should return 0.0625, 45/360 if right sensors are just a little above column 0', function ()
            assert.are_same({0.0625, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 8 - 0.0625))})
          end)

          it('should return 0, 45/360 if right sensors is at the top of column 0', function ()
            assert.are_same({0, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 8))})
          end)

          it('should return -1, 45/360 if right sensors is below column 0 by 1px', function ()
            assert.are_same({-1, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 9))})
          end)

          it('should return 1, 45/360 if 1px above slope column 1', function ()
            assert.are_same({1, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(9, 8))})
          end)

          it('should return 0, 45/360 if at the top of column 1', function ()
            assert.are_same({0, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(9, 9))})
          end)

          it('should return -2, 45/360 if 2px below column 1', function ()
            assert.are_same({-2, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(9, 11))})
          end)

          it('should return 0.0625, 45/360 if just above slope column 0', function ()
            assert.are_same({0.0625, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 8 - 0.0625))})
          end)

          it('should return 0, 45/360 if at the top of column 0', function ()
            assert.are_same({0, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 8))})
          end)

          it('should return -3, 45/360 if 3px below column 0', function ()
            assert.are_same({-3, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(8, 11))})
          end)

          it('. should return 0.0625, 45/360 if just above slope column 3', function ()
            assert.are_same({0.0625, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(11, 11 - 0.0625))})
          end)

          it('. should return 0, 45/360 if at the top of column 3', function ()
            assert.are_same({0, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(11, 11))})
          end)

          it('should return -4, 45/360 if 4px below column 3', function ()
            assert.are_same({-4, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(11, 15))})
          end)

          it('should return 0.0625, 45/360 if just above slope column 7', function ()
            assert.are_same({0.0625, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 15 - 0.0625))})
          end)

          it('should return 0 if, 45/360 at the top of column 7', function ()
            assert.are_same({0, 45/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(15, 15))})
          end)

        end)

        describe('with ascending slope 22.5 offset by 2', function ()

          before_each(function ()
            -- create an ascending slope 22.5 at (1, 1), i.e. (8, 14) to (15, 11) px
            mset(1, 1, 67)
          end)

          it('should return -4, -22.5/360 if below column 7 by 4px)', function ()
            assert.are_same({-4, -22.5/360}, {player_char:_compute_signed_distance_to_closest_ground(vector(14, 15))})
          end)

        end)

        describe('with quarter-tile', function ()

          before_each(function ()
            -- create a quarter-tile at (1, 1), i.e. (12, 12) to (15, 15) px
            -- note that the quarter-tile is made of 2 subtiles of slope 0, hence overall slope is considered 0, not an average slope between min and max height
            mset(1, 1, 71)
          end)

          it('should return tile_size+1, nil if just at the bottom of the tile, on the left part, so in the air (and not 0 just because it is at height 0)', function ()
            assert.are_same({tile_size+1, nil}, {player_char:_compute_signed_distance_to_closest_ground(vector(11, 16))})
          end)

          it('should return -2, 0 if below tile by 2px', function ()
            assert.are_same({-2, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(14, 14))})
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

            mset(1, 1, 72)
            mset(1, 2, 64)
          end)

          it('should return -4, 0 if below top by 4px, with character crossing 2 tiles', function ()
            -- interface
            assert.are_same({-4, 0}, {player_char:_compute_signed_distance_to_closest_ground(vector(12, 18))})
          end)

        end)

      end)

      describe('_compute_stacked_column_height_above', function ()

        describe('with 2 full flat tiles', function ()

          before_each(function ()
            mset(0, 0, 64)  -- full tile
            mset(0, 1, 64)  -- full tile
          end)

          it('should return 16 above tile (0, 2) for any column index', function ()
            assert.are_same({16, 0}, {player_char._compute_stacked_column_height_above(location(0, 2), 4, 20)})
          end)

          it('should return upper_limit+1 above tile (0, 2) for any column index if upper_limit<16', function ()
            assert.are_same({9, nil}, {player_char._compute_stacked_column_height_above(location(0, 2), 4, 8)})
          end)

        end)

        describe('with full flat tile + quarter-tile', function ()

          before_each(function ()
            mset(0, 0, 71)  -- bottom-right quarter-tile
            mset(0, 1, 64)  -- full tile
          end)

          it('should return 8 above tile (0, 2) for column index 0, 1, 2, 3', function ()
            assert.are_same({8, 0}, {player_char._compute_stacked_column_height_above(location(0, 2), 3, 20)})
          end)

          it('should return 12 above tile (0, 2) for column index 4, 5, 6, 7', function ()
            assert.are_same({12, 0}, {player_char._compute_stacked_column_height_above(location(0, 2), 4, 20)})
          end)

          it('should return upper_limit+1 above tile (0, 2) for column index 4, 5, 6, 7 if upper_limit<12', function ()
            assert.are_same({5, nil}, {player_char._compute_stacked_column_height_above(location(0, 2), 4, 4)})
          end)

        end)

      end)

      describe('_compute_stacked_empty_column_height_below', function ()

        it('should return upper_limit+1 when there is no tile below at all', function ()
          assert.are_same({21, nil}, {player_char._compute_stacked_empty_column_height_below(location(0, 0), 4, 20)})
        end)

        describe('with full flat tile', function ()

          before_each(function ()
            mset(0, 3, 64)  -- full tile
          end)

          it('should return 8 below tile (0, 1) for any column index', function ()
            assert.are_same({8, 0}, {player_char._compute_stacked_empty_column_height_below(location(0, 1), 4, 20)})
          end)

          it('should return 16 below tile (0, 0) for any column index', function ()
            assert.are_same({16, 0}, {player_char._compute_stacked_empty_column_height_below(location(0, 0), 4, 20)})
          end)

        end)

        describe('with quarter-tile', function ()

          before_each(function ()
            mset(0, 3, 71)  -- bottom-right quarter-tile
          end)

          it('should return upper_limit+1 below tile (0, 2) for column index 0, 1, 2, 3', function ()
            assert.are_same({21, nil}, {player_char._compute_stacked_empty_column_height_below(location(0, 2), 3, 20)})
          end)

          it('should return 4 below tile (0, 2) for column index 4, 5, 6, 7', function ()
            assert.are_same({4, 0}, {player_char._compute_stacked_empty_column_height_below(location(0, 2), 4, 20)})
          end)

          it('should return 4 below tile (0, 0) for column index 4, 5, 6, 7', function ()
            assert.are_same({20, 0}, {player_char._compute_stacked_empty_column_height_below(location(0, 0), 4, 20)})
          end)

        end)

      end)

      describe('_check_escape_from_ground', function ()

        describe('with full flat tile', function ()

          before_each(function ()
            -- create a full tile at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 64)
          end)

          it('should do nothing when character is not touching ground at all, and return false', function ()
            player_char:set_bottom_center(vector(12, 6))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 6), 0, false}, {player_char:get_bottom_center(), player_char.slope_angle, result})
          end)

          it('should do nothing when character is just on top of the ground, update slope to 0 and return true', function ()
            player_char:set_bottom_center(vector(12, 8))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 8), 0, true}, {player_char:get_bottom_center(), player_char.slope_angle, result})
          end)

          it('should move the character upward just enough to escape ground if character is inside ground, update slope to 0 and return true', function ()
            player_char:set_bottom_center(vector(12, 9))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 8), 0, true}, {player_char:get_bottom_center(), player_char.slope_angle, result})
          end)

          it('should do nothing when character is too deep inside the ground and return true', function ()
            player_char:set_bottom_center(vector(12, 13))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 13), 0, true}, {player_char:get_bottom_center(), player_char.slope_angle, result})
          end)

        end)

        describe('with descending slope 45', function ()

          before_each(function ()
            -- create a descending slope at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 66)
          end)

          it('should do nothing when character is not touching ground at all, and return false', function ()
            player_char:set_bottom_center(vector(15, 10))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(15, 10), 0, false}, {player_char:get_bottom_center(), player_char.slope_angle, result})
          end)

          it('should do nothing when character is just on top of the ground, update slope to 45/360 and return true', function ()
            player_char:set_bottom_center(vector(15, 12))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(15, 12), 45/360, true}, {player_char:get_bottom_center(), player_char.slope_angle, result})
          end)

          it('should move the character upward just enough to escape ground if character is inside ground, update slope to 45/360 and return true', function ()
            player_char:set_bottom_center(vector(15, 13))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(15, 12), 45/360, true}, {player_char:get_bottom_center(), player_char.slope_angle, result})
          end)

          it('should do nothing when character is too deep inside the ground, and return true', function ()
            player_char:set_bottom_center(vector(11, 13))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(11, 13), 0, true}, {player_char:get_bottom_center(), player_char.slope_angle, result})
          end)

        end)

      end)  -- _check_escape_from_ground

      describe('_enter_motion_state', function ()

        it('should enter passed state: airborne and reset ground-specific state vars', function ()
          -- character starts grounded
          player_char:_enter_motion_state(motion_states.airborne)
          assert.are_same({
              motion_states.airborne,
              0,
              false,
              "spin"
            },
            {
              player_char.motion_state,
              player_char.ground_speed_frame,
              player_char.should_jump,
              player_char.current_sprite
            })
        end)

        it('. should enter passed state: grounded and reset speed y and has_interrupted_jump', function ()
          player_char.motion_state = motion_states.airborne

          player_char:_enter_motion_state(motion_states.grounded)
          assert.are_same({
              motion_states.grounded,
              0,
              false,
              "idle"
            },
            {
              player_char.motion_state,
              player_char.velocity_frame.y,
              player_char.has_interrupted_jump,
              player_char.current_sprite
            })
        end)

      end)

      describe('_update_platformer_motion', function ()

        describe('(_check_jump stubbed)', function ()

          local check_jump_stub

          setup(function ()
            check_jump_stub = stub(player_character, "_check_jump")
          end)

          teardown(function ()
            check_jump_stub:revert()
          end)

          after_each(function ()
            check_jump_stub:clear()
          end)

          it('(when motion state is grounded) should call _check_jump', function ()
            player_char.motion_state = motion_states.grounded
            player_char:_update_platformer_motion()
            assert.spy(check_jump_stub).was_called(1)
            assert.spy(check_jump_stub).was_called_with(match.ref(player_char))
          end)

          it('(when motion state is airborne) should call _check_jump', function ()
            player_char.motion_state = motion_states.airborne
            player_char:_update_platformer_motion()
            assert.spy(check_jump_stub).was_not_called()
          end)

        end)

        describe('(_update_platformer_motion_grounded sets motion state to airborne)', function ()

          local update_platformer_motion_grounded_mock
          local update_platformer_motion_airborne_stub

          setup(function ()
            -- mock the worst case possible for _update_platformer_motion_grounded,
            --  changing the state to airborne to make sure the airborne branch is not entered afterward
            update_platformer_motion_grounded_mock = stub(player_character, "_update_platformer_motion_grounded", function (self)
              self.motion_state = motion_states.airborne
            end)
            update_platformer_motion_airborne_stub = stub(player_character, "_update_platformer_motion_airborne")
          end)

          teardown(function ()
            update_platformer_motion_grounded_mock:revert()
            update_platformer_motion_airborne_stub:revert()
          end)

          after_each(function ()
            update_platformer_motion_grounded_mock:clear()
            update_platformer_motion_airborne_stub:clear()
          end)

          describe('(_check_jump does nothing)', function ()

            local check_jump_stub

            setup(function ()
              check_jump_stub = stub(player_character, "_check_jump")
            end)

            teardown(function ()
              check_jump_stub:revert()
            end)

            after_each(function ()
              check_jump_stub:clear()
            end)

            describe('(when character is grounded)', function ()

              it('^ should call _update_platformer_motion_grounded', function ()
                player_char.motion_state = motion_states.grounded

                player_char:_update_platformer_motion()

                assert.spy(update_platformer_motion_grounded_mock).was_called(1)
                assert.spy(update_platformer_motion_grounded_mock).was_called_with(match.ref(player_char))
                assert.spy(update_platformer_motion_airborne_stub).was_not_called()
              end)

            end)

            describe('(when character is airborne)', function ()

              it('^ should call _update_platformer_motion_airborne', function ()
                player_char.motion_state = motion_states.airborne

                player_char:_update_platformer_motion()

                assert.spy(update_platformer_motion_airborne_stub).was_called(1)
                assert.spy(update_platformer_motion_airborne_stub).was_called_with(match.ref(player_char))
                assert.spy(update_platformer_motion_grounded_mock).was_not_called()
              end)

            end)

          end)

          describe('(_check_jump enters airborne motion state)', function ()

            local check_jump_mock

            setup(function ()
              check_jump_mock = stub(player_character, "_check_jump", function ()
                player_char.motion_state = motion_states.airborne
              end)
            end)

            teardown(function ()
              check_jump_mock:revert()
            end)

            after_each(function ()
              check_jump_mock:clear()
            end)

            describe('(when character is grounded)', function ()

              it('^ should call _update_platformer_motion_airborne since _check_jump will enter airborne first', function ()
                player_char.motion_state = motion_states.grounded

                player_char:_update_platformer_motion()

                assert.spy(update_platformer_motion_airborne_stub).was_called(1)
                assert.spy(update_platformer_motion_airborne_stub).was_called_with(match.ref(player_char))
                assert.spy(update_platformer_motion_grounded_mock).was_not_called()
              end)

            end)

            describe('(when character is airborne)', function ()

              it('^ should call _update_platformer_motion_airborne', function ()
                player_char.motion_state = motion_states.airborne

                player_char:_update_platformer_motion()

                assert.spy(update_platformer_motion_airborne_stub).was_called(1)
                assert.spy(update_platformer_motion_airborne_stub).was_called_with(match.ref(player_char))
                assert.spy(update_platformer_motion_grounded_mock).was_not_called()
              end)

            end)

          end)

        end)

      end)

      -- bugfix history:
      --  ^ use fractional speed to check that fractional moves are supported
      describe('_update_platformer_motion_grounded (when _update_velocity sets ground_speed_frame to 2.5)', function ()

        local update_ground_speed_mock
        local enter_motion_state_stub
        local check_jump_intention_stub
        local compute_ground_motion_result_mock

        setup(function ()
          update_ground_speed_mock = stub(player_character, "_update_ground_speed", function (self)
            self.ground_speed_frame = -2.5  -- use fractional speed to check that fractions are preserved
          end)
          enter_motion_state_stub = stub(player_character, "_enter_motion_state")
          check_jump_intention_stub = stub(player_character, "_check_jump_intention")
        end)

        teardown(function ()
          update_ground_speed_mock:revert()
          enter_motion_state_stub:revert()
          check_jump_intention_stub:revert()
        end)

        after_each(function ()
          update_ground_speed_mock:clear()
          enter_motion_state_stub:clear()
          check_jump_intention_stub:clear()
        end)

        it('should call _update_ground_speed', function ()
          player_char:_update_platformer_motion_grounded()

          -- implementation
          assert.spy(update_ground_speed_mock).was_called(1)
          assert.spy(update_ground_speed_mock).was_called_with(match.ref(player_char))
        end)

        describe('(when _compute_ground_motion_result returns a motion result with position vector(3, 4), is_blocked: false, is_falling: false)', function ()

          setup(function ()
            compute_ground_motion_result_mock = stub(player_character, "_compute_ground_motion_result", function (self)
              return collision.ground_motion_result(
                vector(3, 4),
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

          it('should set the position to vector(3, 4)', function ()
            player_char:_update_platformer_motion_grounded()
            assert.are_equal(vector(3, 4), player_char.position)
          end)

          it('should keep updated ground speed and set velocity frame according to ground speed (not blocked)', function ()
            player_char:_update_platformer_motion_grounded()
            assert.are_same({-2.5, vector(-2.5, 0)}, {player_char.ground_speed_frame, player_char.velocity_frame})
          end)

          it('should keep updated ground speed and set velocity frame according to ground speed and slope if not flat (not blocked)', function ()
            player_char.slope_angle = -1/6  -- cos = 1/2, sin = -sqrt(3)/2, but use the formula directly to support floating errors
            player_char:_update_platformer_motion_grounded()
            assert.are_same({-2.5, vector(-2.5*cos(1/6), 2.5*sqrt(3)/2)}, {player_char.ground_speed_frame, player_char.velocity_frame})
          end)

          it('should call _check_jump_intention, not _enter_motion_state (not falling)', function ()
            player_char:_update_platformer_motion_grounded()

            -- implementation
            assert.spy(check_jump_intention_stub).was_called(1)
            assert.spy(check_jump_intention_stub).was_called_with(match.ref(player_char))
            assert.spy(enter_motion_state_stub).was_not_called()
          end)

        end)

        describe('(when _compute_ground_motion_result returns a motion result with position vector(3, 4))', function ()

          local compute_ground_motion_result_mock

          setup(function ()
            compute_ground_motion_result_mock = stub(player_character, "_compute_ground_motion_result", function (self)
              return collision.ground_motion_result(
                vector(3, 4),
                -0.25,
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

          it('should set the position to vector(3, 4)', function ()
            player_char:_update_platformer_motion_grounded()
            assert.are_equal(vector(3, 4), player_char.position)
          end)

          it('should set the slope angle to -0.25', function ()
            player_char:_update_platformer_motion_grounded()
            assert.are_equal(-0.25, player_char.slope_angle)
          end)

          it('should reset ground speed and velocity frame to zero (blocked)', function ()
            player_char:_update_platformer_motion_grounded()
            assert.are_same({0, vector.zero()}, {player_char.ground_speed_frame, player_char.velocity_frame})
          end)

          it('should call _enter_motion_state with airborne state, not call _check_jump_intention (falling)', function ()
            player_char:_update_platformer_motion_grounded()

            -- implementation
            assert.spy(enter_motion_state_stub).was_called(1)
            assert.spy(enter_motion_state_stub).was_called_with(match.ref(player_char), motion_states.airborne)
            assert.spy(check_jump_intention_stub).was_not_called()
          end)

        end)

      end)

      describe('_update_ground_speed', function ()

        setup(function ()
          spy.on(player_character, "_update_ground_speed_by_slope")
          spy.on(player_character, "_update_ground_speed_by_intention")
          spy.on(player_character, "_clamp_ground_speed")
        end)

        teardown(function ()
          player_character._update_ground_speed_by_slope:revert()
          player_character._update_ground_speed_by_intention:revert()
          player_character._clamp_ground_speed:revert()
        end)

        after_each(function ()
          player_character._update_ground_speed_by_slope:clear()
          player_character._update_ground_speed_by_intention:clear()
          player_character._clamp_ground_speed:clear()
        end)

        it('should counter the ground speed in the opposite direction of motion when moving upward a 45-degree slope', function ()
          player_char:_update_ground_speed()

          -- interface
          player_char.ground_speed_frame = 0
          player_char.slope_angle = -1/8  -- 45 deg ascending
          player_char.move_intention.x = 1
          player_char:_update_ground_speed()
          assert.are_equal(playercharacter_data.ground_accel_frame2 - playercharacter_data.slope_accel_factor_frame2 * sin(-1/8), player_char.ground_speed_frame)
        end)

        it('should update ground speed based on slope, then intention', function ()
          player_char:_update_ground_speed()

          -- implementation
          assert.spy(player_character._update_ground_speed_by_slope).was_called(1)
          assert.spy(player_character._update_ground_speed_by_slope).was_called_with(match.ref(player_char))
          assert.spy(player_character._update_ground_speed_by_intention).was_called(1)
          assert.spy(player_character._update_ground_speed_by_intention).was_called_with(match.ref(player_char))
          assert.spy(player_character._clamp_ground_speed).was_called(1)
          assert.spy(player_character._clamp_ground_speed).was_called_with(match.ref(player_char))
        end)
      end)

      describe('_update_ground_speed_by_slope', function ()

        it('should preserve ground speed on flat ground', function ()
          player_char.ground_speed_frame = 2
          player_char.slope_angle = 0
          player_char:_update_ground_speed_by_slope()
          assert.are_equal(2, player_char.ground_speed_frame)
        end)

        it('should accelerate toward left on an ascending slope', function ()
          player_char.ground_speed_frame = 2
          player_char.slope_angle = -0.125  -- sin(0.125) = sqrt(2)/2
          player_char:_update_ground_speed_by_slope()
          assert.are_equal(2 - playercharacter_data.slope_accel_factor_frame2 * sqrt(2)/2, player_char.ground_speed_frame)
        end)

        it('should accelerate toward right on an descending slope', function ()
          player_char.ground_speed_frame = 2
          player_char.slope_angle = 0.125  -- sin(0.125) = sqrt(2)/2
          player_char:_update_ground_speed_by_slope()
          assert.are_equal(2 + playercharacter_data.slope_accel_factor_frame2 * sqrt(2)/2, player_char.ground_speed_frame)
        end)

      end)

      describe('_update_ground_speed_by_intention', function ()

        it('should accelerate when character has ground speed 0 and move intention x is not 0', function ()
          player_char.move_intention.x = 1
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should accelerate when character has ground speed > 0 and move intention x > 0', function ()
          player_char.ground_speed_frame = 1.5
          player_char.move_intention.x = 1
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(1.5 + playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should accelerate when character has ground speed < 0 and move intention x < 0', function ()
          player_char.ground_speed_frame = -1.5
          player_char.move_intention.x = -1
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(-1.5 - playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should decelerate keeping same sign when character has high ground speed > 0 and move intention x < 0', function ()
          player_char.ground_speed_frame = 1.5
          player_char.move_intention.x = -1
          player_char:_update_ground_speed_by_intention()
          -- ground_decel_frame2 = 0.25, subtract it from ground_speed_frame
          assert.are_equal(1.25, player_char.ground_speed_frame)
        end)

        -- bugfix history: missing tests that check the change of sign of ground speed
        it('_ should decelerate and change sign when character has low ground speed > 0 and move intention x < 0 '..
          'but the ground speed is high enough so that the new speed wouldn\'t be over the max ground speed', function ()
          -- start with speed >= -ground_accel_frame2 + ground_decel_frame2
          player_char.ground_speed_frame = 0.24
          player_char.move_intention.x = -1
          player_char:_update_ground_speed_by_intention()
          assert.is_true(almost_eq_with_message(-0.01, player_char.ground_speed_frame, 1e-16))
        end)

        it('should decelerate and clamp to the max ground speed in the opposite sign '..
          'when character has low ground speed > 0 and move intention x < 0', function ()
          -- start with speed < -ground_accel_frame2 + ground_decel_frame2
          player_char.ground_speed_frame = 0.12
          player_char.move_intention.x = -1
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(-playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should decelerate keeping same sign when character has high ground speed < 0 and move intention x > 0', function ()
          player_char.ground_speed_frame = -1.5
          player_char.move_intention.x = 1
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(-1.25, player_char.ground_speed_frame)
        end)

        -- bugfix history: missing tests that check the change of sign of ground speed
        it('_ should decelerate and change sign when character has low ground speed < 0 and move intention x > 0 '..
          'but the ground speed is high enough so that the new speed wouldn\'t be over the max ground speed', function ()
          -- start with speed <= ground_accel_frame2 - ground_decel_frame2
          player_char.ground_speed_frame = -0.24
          player_char.move_intention.x = 1
          player_char:_update_ground_speed_by_intention()
          assert.is_true(almost_eq_with_message(0.01, player_char.ground_speed_frame, 1e-16))
        end)

        it('should decelerate and clamp to the max ground speed in the opposite sign '..
          'when character has low ground speed < 0 and move intention x > 0', function ()
          -- start with speed > ground_accel_frame2 - ground_decel_frame2
          player_char.ground_speed_frame = -0.12
          player_char.move_intention.x = 1
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should apply friction when character has ground speed > 0 and move intention x is 0', function ()
          player_char.ground_speed_frame = 1.5
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(1.5 - playercharacter_data.ground_friction_frame2, player_char.ground_speed_frame)
        end)

        -- bugfix history: missing tests that check the change of sign of ground speed
        it('_ should apply friction but stop at 0 without changing ground speed sign when character has low ground speed > 0 and move intention x is 0', function ()
          -- must be < friction
          player_char.ground_speed_frame = 0.01
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(0, player_char.ground_speed_frame)
        end)

        it('should apply friction when character has ground speed < 0 and move intention x is 0', function ()
          player_char.ground_speed_frame = -1.5
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(-1.5 + playercharacter_data.ground_friction_frame2, player_char.ground_speed_frame)
        end)

        -- bugfix history: missing tests that check the change of sign of ground speed
        it('_ should apply friction but stop at 0 without changing ground speed sign when character has low ground speed < 0 and move intention x is 0', function ()
          -- must be < friction in abs
          player_char.ground_speed_frame = -0.01
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(0, player_char.ground_speed_frame)
        end)

        it('should not change ground speed when ground speed is 0 and move intention x is 0', function ()
          player_char:_update_ground_speed_by_intention()
          assert.are_equal(0, player_char.ground_speed_frame)
        end)

      end)

      describe('_clamp_ground_speed', function ()

        it('should preserve ground speed when it is not over max speed in absolute value', function ()
          player_char.ground_speed_frame = playercharacter_data.max_ground_speed_frame / 2
          player_char:_clamp_ground_speed()
          assert.are_equal(playercharacter_data.max_ground_speed_frame / 2, player_char.ground_speed_frame)
        end)

        it('should clamp ground speed to signed max speed if over max speed in absolute value', function ()
          player_char.ground_speed_frame = playercharacter_data.max_ground_speed_frame + 1
          player_char:_clamp_ground_speed()
          assert.are_equal(playercharacter_data.max_ground_speed_frame, player_char.ground_speed_frame)
        end)

      end)

      describe('_compute_ground_motion_result', function ()

        describe('(when ground_speed_frame is 0)', function ()

          -- bugfix history: method was returning a tuple instead of a table
          it('+ should return the current position and slope, is_blocked: false, is_falling: false', function ()
            player_char.position = vector(3, 4)
            player_char.slope_angle = 0.125

            assert.are_equal(collision.ground_motion_result(
                vector(3, 4),
                0.125,
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          it('should preserve position subpixels if any', function ()
            player_char.position = vector(3.5, 4)
            player_char.slope_angle = 0.125

            assert.are_equal(collision.ground_motion_result(
                vector(3.5, 4),
                0.125,
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)
        end)

        describe('(when _next_ground_step moves motion_result.position.x by 1px in the horizontal_dir without blocking nor falling)', function ()

          local next_ground_step_mock

          setup(function ()
            next_ground_step_mock = stub(player_character, "_next_ground_step", function (self, horizontal_dir, motion_result)
              local step_vec = horizontal_direction_vectors[horizontal_dir]
              motion_result.position = motion_result.position + step_vec
              motion_result.slope_angle = -0.125
            end)
          end)

          teardown(function ()
            next_ground_step_mock:revert()
          end)

          -- bugfix history:
          -- +  failed because case where we add subpixels without reaching next full pixel didn't set slope_angle
          -- ?? failed I tried to fix it (see above), but actually subpixels should not be taken into account for ground slope detection
          it('(vector(3, 4) at speed 0.5) should return vector(3.5, 4), slope: 0, is_blocked: false, is_falling: false', function ()
            player_char.position = vector(3, 4)
            player_char.ground_speed_frame = 0.5
            -- we assume _compute_max_column_distance is correct, so it should return 0
            -- but as there is no blocking, the remaining subpixels will still be added

            assert.are_equal(collision.ground_motion_result(
                vector(3.5, 4),
                0,                  -- character has not moved by a full pixel, so visible position and slope remains the same
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          -- bugfix history:
          -- ?? same reason as test above
          it('(vector(3, 4) at speed 1 on slope cos 0.5) should return vector(3.5, 4), is_blocked: false, is_falling: false', function ()
            player_char.position = vector(3, 4)
            player_char.slope_angle = -1/6  -- cos(-pi/3) = 1/2
            player_char.ground_speed_frame = 1  -- * slope cos = 0.5

            assert.are_equal(collision.ground_motion_result(
                vector(3.5, 4),
                -1/6,               -- character has not moved by a full pixel, so visible position and slope remains the same
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          it('(vector(3.5, 4) at speed 0.5) should return vector(0.5, 4), is_blocked: false, is_falling: false', function ()
            player_char.position = vector(3.5, 4)
            player_char.ground_speed_frame = 0.5
            -- we assume _compute_max_column_distance is correct, so it should return 1

            assert.are_equal(collision.ground_motion_result(
                vector(4, 4),
                -0.125,
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          it('(vector(3, 4) at speed -2.5) should return vector(0.5, 4), is_blocked: false, is_falling: false', function ()
            player_char.position = vector(3, 4)
            player_char.ground_speed_frame = -2.5

            assert.are_equal(collision.ground_motion_result(
                vector(0.5, 4),
                -0.125,
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

        end)

        describe('(when _next_ground_step moves motion_result.position.x by 1px in the horizontal_dir, but blocks when motion_result.position.x >= 5)', function ()

          local next_ground_step_mock

          setup(function ()
            next_ground_step_mock = stub(player_character, "_next_ground_step", function (self, horizontal_dir, motion_result)
              local step_vec = horizontal_direction_vectors[horizontal_dir]
              if motion_result.position.x < 5 then
                motion_result.position = motion_result.position + step_vec
                motion_result.slope_angle = 0.125
              else
                motion_result.is_blocked = true
              end
            end)
          end)

          teardown(function ()
            next_ground_step_mock:revert()
          end)

          it('(vector(3.5, 4) at speed 1.5) should return vector(5, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            player_char.position = vector(3.5, 4)
            player_char.ground_speed_frame = 1.5
            -- we assume _compute_max_column_distance is correct, so it should return 2

            assert.are_equal(collision.ground_motion_result(
                vector(5, 4),
                0.125,
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          -- bugfix history: + the test revealed that is_blocked should be false when just touching a wall on arrival
          --  so I added a check to only check a wall on an extra column farther if there are subpixels left in motion
          it('(vector(4.5, 4) at speed 0.5) should return vector(5, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            player_char.position = vector(4.5, 4)
            player_char.ground_speed_frame = 0.5
            -- we assume _compute_max_column_distance is correct, so it should return 2

            assert.are_equal(collision.ground_motion_result(
                vector(5, 4),
                0.125,
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          -- bugfix history: < replaced self.ground_speed_frame with distance_x in are_subpixels_left evaluation
          it('(vector(4.5, 4) at speed 1 on slope cos 0.5) should return vector(5, 4), is_blocked: false, is_falling: false', function ()
            -- this is the same as the test above (we just reach the wall edge without being blocked),
            -- but we make sure that are_subpixels_left check takes the slope factor into account
            player_char.position = vector(4.5, 4)
            player_char.slope_angle = -1/6  -- cos(-pi/3) = 1/2
            player_char.ground_speed_frame = 1

            assert.are_equal(collision.ground_motion_result(
                vector(5, 4),
                0.125,  -- new slope angle, no relation with initial one
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          it('(vector(4, 4) at speed 1.5) should return vector(5, 4), slope before blocked, is_blocked: true, is_falling: false', function ()
            player_char.position = vector(4, 4)
            player_char.ground_speed_frame = 1.5
            -- we assume _compute_max_column_distance is correct, so it should return 1
            -- the character will just touch the wall but because it has some extra subpixels
            --  going "into" the wall, we floor them and consider character as blocked
            --  (unlike Classic Sonic that would simply ignore subpixels)

            assert.are_equal(collision.ground_motion_result(
                vector(5, 4),
                0.125,
                true,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          -- bugfix history:
          -- ?? same reason as test far above where "character has not moved by a full pixel" so slope should not change
          it('(vector(4, 4) at speed 1.5 on slope cos 0.5) should return vector(4.75, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            player_char.position = vector(4, 4)
            player_char.slope_angle = -1/6  -- cos(-pi/3) = 1/2
            player_char.ground_speed_frame = 1.5  -- * slope cos = 0.75
            -- this time, due to the slope cos, charaacter doesn't reach the wall and is not blocked

            assert.are_equal(collision.ground_motion_result(
                vector(4.75, 4),
                -1/6,               -- character has not moved by a full pixel, so visible position and slope remains the same
                false,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          it('(vector(4, 4) at speed 3 on slope cos 0.5) should return vector(5, 4), slope before blocked, is_blocked: true, is_falling: false', function ()
            player_char.position = vector(4, 4)
            player_char.slope_angle = -1/6  -- cos(-pi/3) = 1/2
            player_char.ground_speed_frame = 3  -- * slope cos = 1.5
            -- but here, even with the slope cos, charaacter will hit wall

            assert.are_equal(collision.ground_motion_result(
                vector(5, 4),
                0.125,
                true,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          -- bugfix history: it failed until I added the subpixels check at the end of the method
          --  (also fixed in v1: subpixel cut when max_column_distance is 0 and blocked on next column)
          it('+ (vector(5, 4) at speed 0.5) should return vector(5, 4), slope before moving, is_blocked: false, is_falling: false', function ()
            player_char.position = vector(5, 4)
            player_char.ground_speed_frame = 0.5
            -- we assume _compute_max_column_distance is correct, so it should return 0
            -- the character is already touching the wall, so any motion, even of just a few subpixels,
            --  is considered blocked

            assert.are_equal(collision.ground_motion_result(
                vector(5, 4),
                0,  -- character couldn't move at all, so we preserved the initial slope angle
                true,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          it('(vector(5.5, 4) at speed 0.5) should return vector(5, 4), slope before moving, is_blocked: false, is_falling: false', function ()
            -- this is possible e.g. if character walked along 1.5 from x=4
            -- to reduce computation we didn't check an extra column for a wall
            --  at that time, but starting next frame we will, effectively clamping
            --  the character to x=5
            player_char.position = vector(5.5, 4)
            player_char.ground_speed_frame = 0.5
            -- we assume _compute_max_column_distance is correct, so it should return 1
            -- but we will be blocked by the wall anyway

            assert.are_equal(collision.ground_motion_result(
                vector(5, 4),
                0,  -- character couldn't move at all, so we preserved the initial slope angle
                true,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          it('(vector(3, 4) at speed 3) should return vector(5, 4), slope before blocked, is_blocked: false, is_falling: false', function ()
            player_char.position = vector(3, 4)
            player_char.ground_speed_frame = 3.5
            -- we assume _compute_max_column_distance is correct, so it should return 3
            -- but because of the blocking, we stop at x=5 instead of 6.5

            assert.are_equal(collision.ground_motion_result(
                vector(5, 4),
                0.125,
                true,
                false
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

        end)

        -- bugfix history: the mock was wrong (was using updated position instead of original_position)
        describe('. (when _next_ground_step moves motion_result.position.x by 1px in the horizontal_dir on x < 7, falls on 5 <= x < 7 and blocks on x >= 7)', function ()

          local next_ground_step_mock

          setup(function ()
            next_ground_step_mock = stub(player_character, "_next_ground_step", function (self, horizontal_dir, motion_result)
              local step_vec = horizontal_direction_vectors[horizontal_dir]
              local original_position = motion_result.position
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
            end)
          end)

          teardown(function ()
            next_ground_step_mock:revert()
          end)

          it('(vector(3, 4) at speed 3) should return vector(6, 4), slope_angle: nil, is_blocked: false, is_falling: false', function ()
            player_char.position = vector(3, 4)
            player_char.ground_speed_frame = 3
            -- we assume _compute_max_column_distance is correct, so it should return 3
            -- we are falling but not blocked, so we continue running in the air until x=6

            assert.are_equal(collision.ground_motion_result(
                vector(6, 4),
                nil,
                false,
                true
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

          it('(vector(3, 4) at speed 3) should return vector(7, 4), slope_angle: nil, is_blocked: false, is_falling: false', function ()
            player_char.position = vector(3, 4)
            player_char.ground_speed_frame = 5
            -- we assume _compute_max_column_distance is correct, so it should return 3
            -- we are falling then blocked on 7

            assert.are_equal(collision.ground_motion_result(
                vector(7, 4),
                nil,
                true,
                true
              ),
              player_char:_compute_ground_motion_result()
            )
          end)

        end)

      end)

      describe('_next_ground_step', function ()

        -- for these utests, we assume that _compute_ground_sensors_signed_distance and
        --  _is_blocked_by_ceiling are correct,
        --  so rather than mocking them, so we setup simple tiles to walk on

        describe('(with flat ground)', function ()

          before_each(function ()
            mset(0, 1, 64)  -- full tile
          end)

          it('when stepping left with the right sensor still on the ground, decrement x', function ()
            local motion_result = collision.ground_motion_result(
              vector(-1, 8 - playercharacter_data.center_height_standing),
              0,
              false,
              false
            )

            -- step flat
            player_char:_next_ground_step(horizontal_directions.left, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(-2, 8 - playercharacter_data.center_height_standing),
                0,
                false,
                false
              ),
              motion_result
            )
          end)

          it('when stepping right with the left sensor still on the ground, increment x', function ()
            local motion_result = collision.ground_motion_result(
              vector(9, 8 - playercharacter_data.center_height_standing),
              0,
              false,
              false
            )

            -- step flat
            player_char:_next_ground_step(horizontal_directions.right, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(10, 8 - playercharacter_data.center_height_standing),
                0,
                false,
                false
              ),
              motion_result
            )
          end)

          it('when stepping left leaving the ground, decrement x and fall', function ()
            local motion_result = collision.ground_motion_result(
              vector(-2, 8 - playercharacter_data.center_height_standing),
              0,
              false,
              false
            )

            -- step fall
            player_char:_next_ground_step(horizontal_directions.left, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(-3, 8 - playercharacter_data.center_height_standing),
                nil,
                false,
                true
              ),
              motion_result
            )
          end)

          it('when stepping right leaving the ground, increment x and fall', function ()
            local motion_result = collision.ground_motion_result(
              vector(10, 8 - playercharacter_data.center_height_standing),
              0,
              false,
              false
            )

            -- step fall
            player_char:_next_ground_step(horizontal_directions.right, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(11, 8 - playercharacter_data.center_height_standing),
                nil,
                false,
                true
              ),
              motion_result
            )
          end)

          it('when stepping right back on the ground, increment x and cancel fall', function ()
            local motion_result = collision.ground_motion_result(
              vector(-3, 8 - playercharacter_data.center_height_standing),
              nil,
              false,
              true
            )

            -- step land (very rare)
            player_char:_next_ground_step(horizontal_directions.right, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(-2, 8 - playercharacter_data.center_height_standing),
                0,
                false,
                false
              ),
              motion_result
            )
          end)

        end)

        describe('(with walls)', function ()

          before_each(function ()
            -- X X
            -- XXX
            mset(0, 0, 64)  -- full tile (left wall)
            mset(0, 1, 64)  -- full tile
            mset(1, 1, 64)  -- full tile
            mset(2, 0, 64)  -- full tile
            mset(2, 1, 64)  -- full tile (right wall)
          end)

          it('when stepping left and hitting the wall, preserve x and block', function ()
            local motion_result = collision.ground_motion_result(
              vector(3, 8 - playercharacter_data.center_height_standing),
              0,
              false,
              false
            )

            -- step block
            player_char:_next_ground_step(horizontal_directions.left, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(3, 8 - playercharacter_data.center_height_standing),
                0,
                true,
                false
              ),
              motion_result
            )
          end)

          it('when stepping right and hitting the wall, preserve x and block', function ()
            local motion_result = collision.ground_motion_result(
              vector(5, 8 - playercharacter_data.center_height_standing),
              0,
              false,
              false
            )

            -- step block
            player_char:_next_ground_step(horizontal_directions.right, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(5, 8 - playercharacter_data.center_height_standing),
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
            --  X
            -- X
            mset(0, 1, 64)  -- full tile (ground)
            mset(1, 0, 64)  -- full tile (wall without ground below)
          end)

          -- it will fail until _compute_signed_distance_to_closest_ground
          --  detects upper-level tiles as suggested in the note
          it('when stepping right on the ground and hitting the non-supported wall, preserve x and block', function ()
            local motion_result = collision.ground_motion_result(
              vector(5, 8 - playercharacter_data.center_height_standing),
              0,
              false,
              false
            )

            -- step block
            player_char:_next_ground_step(horizontal_directions.right, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(5, 8 - playercharacter_data.center_height_standing),
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
            --  X
            -- =
            mset(0, 1, 70)  -- bottom half-tile
            mset(1, 0, 64)  -- full tile (head wall)
          end)

          -- it will fail until _compute_signed_distance_to_closest_ground
          --  detects upper-level tiles as suggested in the note
          it('when stepping right on the half-tile and hitting the head wall, preserve x and block', function ()
            local motion_result = collision.ground_motion_result(
              vector(5, 12 - playercharacter_data.center_height_standing),
              0,
              false,
              false
            )

            -- step block
            player_char:_next_ground_step(horizontal_directions.right, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(5, 12 - playercharacter_data.center_height_standing),
                0,
                true,
                false
              ),
              motion_result
            )
          end)

        end)

        -- bugfix history:
        -- = itest of player running on flat ground when ascending a slope showed that when removing supporting ground,
        --   character would be blocked at the bottom of the slope, so I isolated just that part into a utest
        describe('#solo (with non-supported ascending slope)', function ()

          before_each(function ()
            --  /
            -- X
            mset(0, 1, 64)  -- full tile (ground)
            mset(1, 0, 65)  -- ascending slope 45
          end)

          it('when stepping right from the bottom of the ascending slope, increment x and adjust y', function ()
            local motion_result = collision.ground_motion_result(
              vector(5, 8 - playercharacter_data.center_height_standing),
              0,
              false,
              false
            )

            -- step down
            player_char:_next_ground_step(horizontal_directions.right, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(6, 7 - playercharacter_data.center_height_standing),
                -45/360,
                false,
                false
              ),
              motion_result
            )
          end)

        end)

        describe('(with ascending slope and wall)', function ()

          before_each(function ()
            -- X X
            -- X/X
            mset(0, 0, 64)  -- full tile (high wall, needed to block motion to the left as right sensor makes the character quite high on the slope)
            mset(0, 1, 64)  -- full tile (wall)
            mset(1, 1, 65)  -- ascending slope 45
            mset(2, 0, 64)  -- full tile (wall)
          end)

          it('when stepping left on the ascending slope without leaving the ground, decrement x and adjust y', function ()
            local motion_result = collision.ground_motion_result(
              vector(12, 9 - playercharacter_data.center_height_standing),
              -45/360,
              false,
              false
            )

            -- step down
            player_char:_next_ground_step(horizontal_directions.left, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(11, 10 - playercharacter_data.center_height_standing),
                -45/360,
                false,
                false
              ),
              motion_result
            )
          end)

          it('when stepping right on the ascending slope without leaving the ground, decrement x and adjust y', function ()
            local motion_result = collision.ground_motion_result(
              vector(12, 9 - playercharacter_data.center_height_standing),
              -45/360,
              false,
              false
            )

            -- step up
            player_char:_next_ground_step(horizontal_directions.right, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(13, 8 - playercharacter_data.center_height_standing),
                -45/360,
                false,
                false
              ),
              motion_result
            )
          end)

          it('when stepping right on the ascending slope and hitting the right wall, preserve x and y and block', function ()
            local motion_result = collision.ground_motion_result(
              vector(13, 10 - playercharacter_data.center_height_standing),
              -45/360,
              false,
              false
            )

            -- step up blocked
            player_char:_next_ground_step(horizontal_directions.right, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(13, 10 - playercharacter_data.center_height_standing),
                -45/360,
                true,
                false
              ),
              motion_result
            )
          end)

          it('when stepping left on the ascending slope and hitting the left wall, preserve x and y and block', function ()
            local motion_result = collision.ground_motion_result(
              vector(11, 10 - playercharacter_data.center_height_standing),
              -45/360,
              false,
              false
            )

            -- step down blocked
            player_char:_next_ground_step(horizontal_directions.left, motion_result)

            assert.are_equal(collision.ground_motion_result(
                vector(11, 10 - playercharacter_data.center_height_standing),
                -45/360,
                true,
                false
              ),
              motion_result
            )
          end)

        end)

      end)

      describe('_is_blocked_by_ceiling_at', function ()

        local get_ground_sensor_position_from_mock
        local is_column_blocked_by_ceiling_at_mock

        setup(function ()
          get_ground_sensor_position_from_mock = stub(player_character, "_get_ground_sensor_position_from", function (self, center_position, i)
            return i == horizontal_directions.left and vector(-1, center_position.y) or vector(1, center_position.y)
          end)

          is_column_blocked_by_ceiling_at_mock = stub(player_character, "_is_column_blocked_by_ceiling_at", function (sensor_position)
            -- simulate ceiling detection by encoding information in x and y
            if sensor_position.y == 1 then
              return sensor_position.x < 0 and false or false
            elseif sensor_position.y == 2 then
              return sensor_position.x < 0 and true or false  -- left sensor detects ceiling
            elseif sensor_position.y == 3 then
              return sensor_position.x < 0 and false or true  -- right sensor detects ceiling
            else
              return sensor_position.x < 0 and true or true  -- both sensors detect ceiling
            end
          end)
        end)

        teardown(function ()
          get_ground_sensor_position_from_mock:revert()
          is_column_blocked_by_ceiling_at_mock:revert()
        end)

        it('should return false when both sensors detect no near ceiling', function ()
          assert.is_false(player_char:_is_blocked_by_ceiling_at(vector(0, 1)))
        end)

        it('should return true when left sensor detects near ceiling', function ()
          assert.is_true(player_char:_is_blocked_by_ceiling_at(vector(0, 2)))
        end)

        it('should return true when right sensor detects no near ceiling', function ()
          assert.is_true(player_char:_is_blocked_by_ceiling_at(vector(0, 3)))
        end)

        it('should return true when both sensors detect near ceiling', function ()
          assert.is_true(player_char:_is_blocked_by_ceiling_at(vector(0, 4)))
        end)

      end)

      describe('_is_column_blocked_by_ceiling_at', function ()

        describe('(no tiles)', function ()

          it('should return false anywhere', function ()
            assert.is_false(player_char._is_column_blocked_by_ceiling_at(vector(4, 5)))
          end)

        end)

        describe('(1 full tile)', function ()

          before_each(function ()
            -- X
            mset(1, 0, 64)  -- full tile (act like a full ceiling if position is at bottom)
          end)

          it('should return false for sensor position just above the bottom of the tile', function ()
            -- here, the current tile is the full tile, and we only check tiles above, so we detect nothing
            assert.is_false(player_char._is_column_blocked_by_ceiling_at(vector(8, 7.9)))
          end)

          it('should return false for sensor position on the left of the tile', function ()
            assert.is_false(player_char._is_column_blocked_by_ceiling_at(vector(7, 8)))
          end)

          it('should return true for sensor position at the bottom-left of the tile', function ()
            assert.is_true(player_char._is_column_blocked_by_ceiling_at(vector(8, 8)))
          end)

          it('should return true for sensor position on the bottom-right of the tile', function ()
            assert.is_true(player_char._is_column_blocked_by_ceiling_at(vector(15, 8)))
          end)

          it('should return false for sensor position on the right of the tile', function ()
            assert.is_false(player_char._is_column_blocked_by_ceiling_at(vector(16, 8)))
          end)

          it('should return true for sensor position below the tile, at character height - 1px', function ()
            assert.is_true(player_char._is_column_blocked_by_ceiling_at(vector(12, 8 + playercharacter_data.full_height_standing - 1)))
          end)

          it('should return false for sensor position below the tile, at character height', function ()
            assert.is_false(player_char._is_column_blocked_by_ceiling_at(vector(12, 8 + playercharacter_data.full_height_standing)))
          end)

        end)

      end)

      describe('_check_jump_intention', function ()

        it('should do nothing when jump_intention is false', function ()
          player_char:_check_jump_intention()
          assert.are_same({false, false}, {player_char.jump_intention, player_char.should_jump})
        end)

        it('should *not* consume jump_intention and set should_jump to true if jump_intention is true', function ()
          player_char.jump_intention = true
          player_char:_check_jump_intention()
          assert.are_same({true, true}, {player_char.jump_intention, player_char.should_jump})
        end)

      end)

      describe('_check_jump', function ()

        it('should return false when should_jump is false', function ()
          player_char.velocity_frame = vector(4.1, -1)
          local result = player_char:_check_jump()

          -- interface
          assert.are_same({false, vector(4.1, -1), motion_states.grounded}, {result, player_char.velocity_frame, player_char.motion_state})
        end)

        it('should consume should_jump, add initial hop velocity, update motion state and return false when should_jump is true and hold_jump_intention is false', function ()
          player_char.velocity_frame = vector(4.1, -1)
          player_char.should_jump = true
          local result = player_char:_check_jump()

          -- interface
          assert.are_same({true, vector(4.1, -3), motion_states.airborne}, {result, player_char.velocity_frame, player_char.motion_state})
        end)

        it('should consume should_jump, add initial var jump velocity, update motion state and return false when should_jump is true and hold_jump_intention is true', function ()
          player_char.velocity_frame = vector(4.1, -1)
          player_char.should_jump = true
          player_char.hold_jump_intention = true
          local result = player_char:_check_jump()

          -- interface
          assert.are_same({true, vector(4.1, -4.25), motion_states.airborne}, {result, player_char.velocity_frame, player_char.motion_state})
        end)

      end)

      describe('_update_platformer_motion_airborne', function ()

        local check_hold_jump_stub
        local enter_motion_state_stub

        setup(function ()
          check_hold_jump_stub = stub(player_character, "_check_hold_jump")
          enter_motion_state_stub = stub(player_character, "_enter_motion_state")
        end)

        teardown(function ()
          check_hold_jump_stub:revert()
          enter_motion_state_stub:revert()
        end)

        after_each(function ()
          check_hold_jump_stub:clear()
          enter_motion_state_stub:clear()
        end)

        it('. should apply gravity to speed y', function ()
          player_char:_update_platformer_motion_airborne()
          assert.are_equal(playercharacter_data.gravity_frame2, player_char.velocity_frame.y)
        end)

        it('should apply accel x', function ()
          player_char.velocity_frame.x = 4
          player_char.move_intention.x = -1

          player_char:_update_platformer_motion_airborne()

          assert.are_equal(4 - playercharacter_data.air_accel_x_frame2, player_char.velocity_frame.x)
        end)

        it('. should update position with new speed y', function ()
          player_char.position = vector(4, -4)
          player_char:_update_platformer_motion_airborne()
          assert.are_equal(vector(4, -4 + playercharacter_data.gravity_frame2), player_char.position)
        end)

        it('should call _check_hold_jump', function ()
          player_char:_update_platformer_motion_airborne()

          -- implementation
          assert.spy(check_hold_jump_stub).was_called(1)
          assert.spy(check_hold_jump_stub).was_called_with(match.ref(player_char))
        end)

        describe('(_check_escape_from_ground returns false, so has not landed)', function ()

          local check_escape_from_ground_mock

          setup(function ()
            check_escape_from_ground_mock = stub(player_character, "_check_escape_from_ground", function ()
              return false
            end)
          end)

          teardown(function ()
            check_escape_from_ground_mock:revert()
          end)

          it('should not enter grounded state', function ()
            player_char:_update_platformer_motion_airborne()

            -- implementation
            assert.spy(enter_motion_state_stub).was_not_called()
          end)

        end)

        describe('(_check_escape_from_ground returns true, so has landed)', function ()

          local check_escape_from_ground_mock

          setup(function ()
            check_escape_from_ground_mock = stub(player_character, "_check_escape_from_ground", function ()
              return true
            end)
          end)

          teardown(function ()
            check_escape_from_ground_mock:revert()
          end)

          it('should enter grounded state', function ()
            player_char:_update_platformer_motion_airborne()

            -- implementation
            assert.spy(enter_motion_state_stub).was_called(1)
            assert.spy(enter_motion_state_stub).was_called_with(match.ref(player_char), motion_states.grounded)
          end)

        end)

      end)  -- _update_platformer_motion_airborne

    end)  -- (with mock tiles data setup)

    describe('_check_hold_jump', function ()

      before_each(function ()
        -- optional, just to enter airborne state and be in a meaningful state
        player_char:_enter_motion_state(motion_states.airborne)
      end)

      it('should interrupt the jump when still possible and hold_jump_intention is false', function ()
        player_char.velocity_frame.y = -3

        player_char:_check_hold_jump()

        assert.are_same({true, -playercharacter_data.jump_interrupt_speed_frame}, {player_char.has_interrupted_jump, player_char.velocity_frame.y})
      end)

      it('should not change velocity but still set the interrupt flat when it\'s too late to interrupt jump and hold_jump_intention is false', function ()
        player_char.velocity_frame.y = -1

        player_char:_check_hold_jump()

        assert.are_same({true, -1}, {player_char.has_interrupted_jump, player_char.velocity_frame.y})
      end)

      it('should not try to interrupt jump if already done', function ()
        player_char.velocity_frame.y = -3
        player_char.has_interrupted_jump = true

        player_char:_check_hold_jump()

        assert.are_same({true, -3}, {player_char.has_interrupted_jump, player_char.velocity_frame.y})
      end)

      it('should not try to interrupt jump if still holding jump input', function ()
        player_char.velocity_frame.y = -3
        player_char.hold_jump_intention = true

        player_char:_check_hold_jump()

        assert.are_same({false, -3}, {player_char.has_interrupted_jump, player_char.velocity_frame.y})
      end)

    end)

    describe('_update_debug', function ()

      local update_velocity_debug_stub

      setup(function ()
        update_velocity_debug_mock = stub(player_character, "_update_velocity_debug", function (self)
          self.debug_velocity = vector(4, -3)
        end)
        move_stub = stub(player_character, "move")
      end)

      teardown(function ()
        update_velocity_debug_mock:revert()
        move_stub:revert()
      end)

      it('should call _update_velocity_debug, then move using the new velocity', function ()
        player_char.position = vector(1, 2)
        player_char:_update_debug()
        assert.spy(update_velocity_debug_mock).was_called(1)
        assert.spy(update_velocity_debug_mock).was_called_with(match.ref(player_char))
        assert.are_equal(vector(1, 2) + vector(4, -3) * delta_time, player_char.position)
      end)

    end)

    describe('_update_velocity_debug', function ()

      local update_velocity_component_debug_stub

      setup(function ()
        update_velocity_component_debug_stub = stub(player_character, "_update_velocity_component_debug")
      end)

      teardown(function ()
        update_velocity_component_debug_stub:revert()
      end)

      it('should call _update_velocity_component_debug on each component', function ()
        player_char:_update_velocity_debug()
        assert.spy(update_velocity_component_debug_stub).was_called(2)
        assert.spy(update_velocity_component_debug_stub).was_called_with(match.ref(player_char), "x")
        assert.spy(update_velocity_component_debug_stub).was_called_with(match.ref(player_char), "y")
      end)

    end)

    describe('_update_velocity_component_debug', function ()

      it('should accelerate when there is some input', function ()
        player_char.move_intention = vector(-1, 1)
        player_char:_update_velocity_component_debug("x")
        assert.is_true(almost_eq_with_message(
          vector(- player_char.debug_move_accel * delta_time, 0),
          player_char.debug_velocity))
        player_char:_update_velocity_component_debug("y")
        assert.is_true(almost_eq_with_message(
          vector(- player_char.debug_move_accel * delta_time, player_char.debug_move_accel * delta_time),
          player_char.debug_velocity))
      end)

    end)

    -- integration test as utest kept here for the moment, but prefer itests for this
    describe('_update_velocity_debug and move', function ()

      before_each(function ()
        player_char.position = vector(4, -4)
      end)

      after_each(function ()
        player_char.move_intention = vector(-1, 1)
      end)

      it('when move intention is (-1, 1), update 1 frame => at (3.867 -3.867)', function ()
        player_char.move_intention = vector(-1, 1)
        player_char:_update_velocity_debug()
        player_char:move_by(player_char.debug_velocity * delta_time)
        assert.is_true(almost_eq_with_message(vector(3.8667, -3.8667), player_char.position))
      end)

      it('when move intention is (-1, 1), update 11 frame => at (−2.73 2.73)', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move_by(player_char.debug_velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector(-2.73, 2.73), player_char.position))
        assert.is_true(almost_eq_with_message(vector(-60, 60), player_char.debug_velocity))  -- at max speed
      end)

      it('when move intention is (0, 0) after 11 frames, update 16 frames more => character should have decelerated', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move_by(player_char.debug_velocity * delta_time)
        end
        player_char.move_intention = vector.zero()
        for i=1,5 do
          player_char:_update_velocity_debug()
          player_char:move_by(player_char.debug_velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector(-20, 20), player_char.debug_velocity, 0.01))
      end)

      it('when move intention is (0, 0) after 11 frames, update 19 frames more => character should have stopped', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move_by(player_char.debug_velocity * delta_time)
        end
        player_char.move_intention = vector.zero()
        for i=1,8 do
          player_char:_update_velocity_debug()
          player_char:move_by(player_char.debug_velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector.zero(), player_char.debug_velocity))
      end)

    end)

    describe('render', function ()

      local spr_data_render_stub

      setup(function ()
        spr_data_render_stub = stub(playercharacter_data.sonic_sprite_data["idle"], "render")
      end)

      teardown(function ()
        spr_data_render_stub:revert()
      end)

      after_each(function ()
        spr_data_render_stub:clear()
      end)

      it('should call render on sonic sprite data: idle with the character\'s position', function ()
        player_char:render()
        assert.spy(spr_data_render_stub).was_called(1)
        assert.spy(spr_data_render_stub).was_called_with(match.ref(playercharacter_data.sonic_sprite_data["idle"]), player_char.position)
      end)
    end)

  end)

end)

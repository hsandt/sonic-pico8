require("bustedhelper")
require("engine/core/math")
local player_character = require("game/ingame/playercharacter")
local playercharacter_data = require("game/data/playercharacter_data")
local tile_test_data = require("game/test_data/tile_test_data")

describe('player_character', function ()

  describe('_init', function ()

    it('should create a player character at the origin with zero velocity and move_intention', function ()
      local player_char = player_character()
      assert.is_not_nil(player_char)
      assert.are_same(
        {
          vector.zero(),
          0,
          vector.zero(),
          vector.zero(),
          vector.zero(),
          false,
          false,
          false,
          false
        },
        {
          player_char.position,
          player_char.ground_speed_frame,
          player_char.velocity_frame,
          player_char.debug_velocity,
          player_char.move_intention,
          player_char.jump_intention,
          player_char.hold_jump_intention,
          player_char.should_jump,
          player_char.has_interrupted_jump
        })
    end)

    it('should create a player character with control mode: human, motion mode: platformer, motion state: grounded', function ()
      local player_char = player_character()
      assert.is_not_nil(player_char)
      assert.are_same({control_modes.human, motion_modes.platformer, motion_states.grounded},
        {player_char.control_mode, player_char.motion_mode, player_char.motion_state})
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

    describe('_tostring', function ()
      it('should return "[player_character at {self.position}]"', function ()
        player_char.position = vector(4, -4)
        assert.are_equal("[player_character at vector(4, -4)]", player_char:_tostring())
      end)
    end)

    describe('spawn_at', function ()

      local _check_escape_from_ground_and_update_motion_state_stub

      setup(function ()
        _check_escape_from_ground_and_update_motion_state_stub = stub(player_character, "_check_escape_from_ground_and_update_motion_state")
      end)

      teardown(function ()
        _check_escape_from_ground_and_update_motion_state_stub:revert()
      end)

      after_each(function ()
        _check_escape_from_ground_and_update_motion_state_stub:clear()
      end)

      it('should set the character\'s position', function ()
        player_char:spawn_at(vector(56, 12))
        assert.are_equal(vector(56, 12), player_char.position)
      end)

      it('should call _check_escape_from_ground_and_update_motion_state', function ()
        player_char:spawn_at(vector(56, 12))

        -- implementation
        assert.spy(_check_escape_from_ground_and_update_motion_state_stub).was_called(1)
        assert.spy(_check_escape_from_ground_and_update_motion_state_stub).was_called_with(match.ref(player_char))

      end)

    end)

    describe('move', function ()
      it('at (4 -4) move (-5 4) => at (-1 0)', function ()
        player_char.position = vector(4, -4)
        player_char:move(vector(-5, 4))
        assert.are_equal(vector(-1, 0), player_char.position)
      end)
    end)

    describe('get_bottom_center', function ()
      it('(10 0 3) => at (10 6)', function ()
        player_char.position = vector(10, 0)
        assert.are_equal(vector(10, 6), player_char:get_bottom_center())
      end)
    end)

    describe('+ set_bottom_center', function ()
      it('set_bottom_center (10 6) => at (10 0)', function ()
        player_char:set_bottom_center(vector(10, 6))
        assert.are_equal(vector(10, 0), player_char.position)
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

      describe('_compute_signed_distance_to_closest_ground', function ()

        describe('with full flat tile', function ()

          before_each(function ()
            -- create a full tile at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 64)
          end)

          -- just above

          it('should return tile_size+1 if both sensors are above the tile by 10>tile_size (clamped to tile_size)', function ()
            player_char:set_bottom_center(vector(12, 8 - 10))
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0.0625 if both sensors are just a above the tile by 0.0625', function ()
            player_char:set_bottom_center(vector(12, 8 - 0.0625))
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- on top

          it('should return tile_size+1 if both sensors are completely in the air on the left of the tile, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(4, 8))  -- right ground sensor @ (6.5, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('+ should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(5, 8))  -- right ground sensor @ (7.5, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('+ should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 8))  -- right ground sensor @ (8 - 0.0625, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('+ should return 0 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just at the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just at the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 8))  -- right ground sensor @ (8, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is in the air on the left of the tile and right sensor is at the top of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it in x', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 8))  -- left ground sensor @ (8 - 0.0625, 8), right ground sensor @ (13 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if both sensors are just at the top of tile, with left sensor just at the top of the topleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 8))  -- left ground sensor @ (8, 8), right ground sensor @ (13, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if both sensors are just at the top of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 8))  -- left ground sensor @ (9.5, 8), right ground sensor @ (14.5, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if both sensors are just at the top of tile and right sensor just at the top of the right-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 8))  -- left ground sensor @ (11 - 0.0625, 8), right ground sensor @ (16 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is at the top of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 8))  -- left ground sensor @ (11, 8), right ground sensor @ (16, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is just at the top of the right-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 8))  -- left ground sensor @ (15.5, 8), right ground sensor @ (20.5, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is just at the top of the right-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 8))  -- left ground sensor @ (16 - 0.0625, 8), right ground sensor @ (21 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('+ should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just at the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 8))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(19, 8))  -- left ground sensor @ (16.5, 8), right ground sensor @ (21.5, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if both sensors are completely in the air on the right of the tile, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(20, 8))  -- left ground sensor @ (17.5, 8), right ground sensor @ (22.5, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- just inside the top

          it('should return tile_size+1 if both sensors are completely in the air on the left of the tile, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(4, 8 + 0.0625))  -- right ground sensor @ (6.5, 8 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(5, 8 + 0.0625))  -- right ground sensor @ (7.5, 8 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 8 + 0.0625))  -- right ground sensor @ (8 - 0.0625, 8 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return -0.0625 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just below the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just below the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 8 + 0.0625))  -- right ground sensor @ (8, 8 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if left sensor is in the air on the left of the tile and right sensor is just inside the top of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 8 + 0.0625))  -- left ground sensor @ (8 - 0.0625, 8 + 0.0625), right ground sensor @ (13 - 0.0625, 8 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if both sensors are just inside the top of tile, with left sensor just inside the top of the topleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 8 + 0.0625))  -- left ground sensor @ (8, 8 + 0.0625), right ground sensor @ (13, 8 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if both sensors are just inside the top of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 8 + 0.0625))  -- left ground sensor @ (9.5, 8 + 0.0625), right ground sensor @ (14.5, 8 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if both sensors are just inside the top of tile and right sensor just inside the top of the topright-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 8 + 0.0625))  -- left ground sensor @ (11 - 0.0625, 8 + 0.0625), right ground sensor @ (16 - 0.0625, 8 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if left sensor is just inside the top of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 8 + 0.0625))  -- left ground sensor @ (11, 8 + 0.0625), right ground sensor @ (16, 8)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if left sensor is just inside the top of the topright-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 8 + 0.0625))  -- left ground sensor @ (15.5, 8 + 0.0625), right ground sensor @ (20.5, 8)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if left sensor is just inside the top of the topright-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 8 + 0.0625))  -- left ground sensor @ (16 - 0.0625, 8 + 0.0625), right ground sensor @ (21 - 0.0625, 8 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just below the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 8 + 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 8 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(19, 8 + 0.0625))  -- left ground sensor @ (16.5, 8 + 0.0625), right ground sensor @ (21.5, 8 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if both sensors are completely in the air on the right of the tile, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(20, 8 + 0.0625))  -- left ground sensor @ (17.5, 8 + 0.0625), right ground sensor @ (22.5, 8 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- just inside the bottom

          it('should return tile_size+1 if both sensors are completely in the air on the left of the tile, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(4, 16 - 0.0625))  -- right ground sensor @ (6.5, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(5, 16 - 0.0625))  -- right ground sensor @ (7.5, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 16 - 0.0625))  -- right ground sensor @ (8 - 0.0625, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return -(8 - 0.0625) if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just above the bottom of the bottomleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just above the bottom\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 16 - 0.0625))  -- right ground sensor @ (8, 16 - 0.0625)
            assert.are_equal(-(8 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(8 - 0.0625) if left sensor is in the air on the left of the tile and right sensor is just inside the bottom of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (8 - 0.0625, 16 - 0.0625), right ground sensor @ (13 - 0.0625, 16 - 0.0625)
            assert.are_equal(-(8 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(8 - 0.0625) if both sensors are just inside the bottom of tile, with left sensor just inside the bottom of the bottomleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 16 - 0.0625))  -- left ground sensor @ (8, 16 - 0.0625), right ground sensor @ (13, 16 - 0.0625)
            assert.are_equal(-(8 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(8 - 0.0625) if both sensors are just inside the bottom of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 16 - 0.0625))  -- left ground sensor @ (9.5, 16 - 0.0625), right ground sensor @ (14.5, 16 - 0.0625)
            assert.are_equal(-(8 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(8 - 0.0625) if both sensors are just inside the bottom of tile and right sensor just inside the bottom of the bottomright-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (11 - 0.0625, 16 - 0.0625), right ground sensor @ (16 - 0.0625, 16 - 0.0625)
            assert.are_equal(-(8 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(8 - 0.0625) if left sensor is just inside the bottom of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 16 - 0.0625))  -- left ground sensor @ (11, 16 - 0.0625), right ground sensor @ (16, 8)
            assert.are_equal(-(8 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(8 - 0.0625) if left sensor is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 16 - 0.0625))  -- left ground sensor @ (15.5, 16 - 0.0625), right ground sensor @ (20.5, 8)
            assert.are_equal(-(8 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(8 - 0.0625) if left sensor is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (16 - 0.0625, 16 - 0.0625), right ground sensor @ (21 - 0.0625, 16 - 0.0625)
            assert.are_equal(-(8 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just above the bottom\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 16 - 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(19, 16 - 0.0625))  -- left ground sensor @ (16.5, 16 - 0.0625), right ground sensor @ (21.5, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if both sensors are completely in the air on the right of the tile, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(20, 16 - 0.0625))  -- left ground sensor @ (17.5, 16 - 0.0625), right ground sensor @ (22.5, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- just at the bottom, so character is inside tile but sensors above air

          it('should return tile_size+1 if both sensors are just at the bottom of the tile, above air', function ()
            player_char:set_bottom_center(vector(12, 16))
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

        end)

        describe('with half flat tile', function ()

          before_each(function ()
            -- create a half-tile at (0, 1), top-left at (0, 12), top-right at (7, 12) included
            mset(1, 1, 70)
          end)

          -- just above

          it('should return 0.0625 if both sensors are just a little above the tile', function ()
            player_char:set_bottom_center(vector(12, 12 - 0.0625))
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- on top

          it('should return tile_size+1 if both sensors are completely in the air on the left of the tile, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(4, 12))  -- right ground sensor @ (6.5, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(5, 12))  -- right ground sensor @ (7.5, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 12))  -- right ground sensor @ (8 - 0.0625, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return true if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just at the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just at the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 12))  -- right ground sensor @ (8, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is in the air on the left of the tile and right sensor is at the top of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 12))  -- left ground sensor @ (8 - 0.0625, 8), right ground sensor @ (13 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if both sensors are just at the top of tile, with left sensor just at the top of the topleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 12))  -- left ground sensor @ (8, 8), right ground sensor @ (13, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if both sensors are just at the top of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 12))  -- left ground sensor @ (9.5, 8), right ground sensor @ (14.5, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if both sensors are just at the top of tile and right sensor just at the top of the right-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 12))  -- left ground sensor @ (11 - 0.0625, 8), right ground sensor @ (16 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is at the top of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 12))  -- left ground sensor @ (11, 8), right ground sensor @ (16, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is just at the top of the right-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 12))  -- left ground sensor @ (15.5, 8), right ground sensor @ (20.5, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is just at the top of the right-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 12))  -- left ground sensor @ (16 - 0.0625, 8), right ground sensor @ (21 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just at the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 12))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(19, 12))  -- left ground sensor @ (16.5, 8), right ground sensor @ (21.5, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if both sensors are completely in the air on the right of the tile, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(20, 12))  -- left ground sensor @ (17.5, 8), right ground sensor @ (22.5, 8)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- just inside the top

          it('should return tile_size+1 if both sensors are completely in the air on the left of the tile, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(4, 12 + 0.0625))  -- right ground sensor @ (6.5, 12 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(5, 12 + 0.0625))  -- right ground sensor @ (7.5, 12 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 12 + 0.0625))  -- right ground sensor @ (8 - 0.0625, 12 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just below the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just below the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 12 + 0.0625))  -- right ground sensor @ (8, 12 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if left sensor is in the air on the left of the tile and right sensor is just inside the top of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 12 + 0.0625))  -- left ground sensor @ (8 - 0.0625, 12 + 0.0625), right ground sensor @ (13 - 0.0625, 12 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if both sensors are just inside the top of tile, with left sensor just inside the top of the topleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 12 + 0.0625))  -- left ground sensor @ (8, 12 + 0.0625), right ground sensor @ (13, 12 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if both sensors are just inside the top of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 12 + 0.0625))  -- left ground sensor @ (9.5, 12 + 0.0625), right ground sensor @ (14.5, 12 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if both sensors are just inside the top of tile and right sensor just inside the top of the topright-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 12 + 0.0625))  -- left ground sensor @ (11 - 0.0625, 12 + 0.0625), right ground sensor @ (16 - 0.0625, 12 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if left sensor is just inside the top of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 12 + 0.0625))  -- left ground sensor @ (11, 12 + 0.0625), right ground sensor @ (16, 8)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if left sensor is just inside the top of the topright-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 12 + 0.0625))  -- left ground sensor @ (15.5, 12 + 0.0625), right ground sensor @ (20.5, 8)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -0.0625 if left sensor is just inside the top of the topright-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 12 + 0.0625))  -- left ground sensor @ (16 - 0.0625, 12 + 0.0625), right ground sensor @ (21 - 0.0625, 12 + 0.0625)
            assert.are_equal(-0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just below the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 12 + 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 12 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(19, 12 + 0.0625))  -- left ground sensor @ (16.5, 12 + 0.0625), right ground sensor @ (21.5, 12 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if both sensors are completely in the air on the right of the tile, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(20, 12 + 0.0625))  -- left ground sensor @ (17.5, 12 + 0.0625), right ground sensor @ (22.5, 12 + 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- just inside the bottom

          it('should return tile_size+1 if both sensors are completely in the air on the left of the tile, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(4, 16 - 0.0625))  -- right ground sensor @ (6.5, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(5, 16 - 0.0625))  -- right ground sensor @ (7.5, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return tile_size+1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 16 - 0.0625))  -- right ground sensor @ (8 - 0.0625, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return -(4 - 0.0625) if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just above the bottom of the bottomleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just above the bottom\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 16 - 0.0625))  -- right ground sensor @ (8, 16 - 0.0625)
            assert.are_equal(-(4 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(4 - 0.0625) if left sensor is in the air on the left of the tile and right sensor is just inside the bottom of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (8 - 0.0625, 16 - 0.0625), right ground sensor @ (13 - 0.0625, 16 - 0.0625)
            assert.are_equal(-(4 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(4 - 0.0625) if both sensors are just inside the bottom of tile, with left sensor just inside the bottom of the bottomleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 16 - 0.0625))  -- left ground sensor @ (8, 16 - 0.0625), right ground sensor @ (13, 16 - 0.0625)
            assert.are_equal(-(4 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(4 - 0.0625) if both sensors are just inside the bottom of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 16 - 0.0625))  -- left ground sensor @ (9.5, 16 - 0.0625), right ground sensor @ (14.5, 16 - 0.0625)
            assert.are_equal(-(4 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(4 - 0.0625) if both sensors are just inside the bottom of tile and right sensor just inside the bottom of the bottomright-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (11 - 0.0625, 16 - 0.0625), right ground sensor @ (16 - 0.0625, 16 - 0.0625)
            assert.are_equal(-(4 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(4 - 0.0625) if left sensor is just inside the bottom of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 16 - 0.0625))  -- left ground sensor @ (11, 16 - 0.0625), right ground sensor @ (16, 8)
            assert.are_equal(-(4 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(4 - 0.0625) if left sensor is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 16 - 0.0625))  -- left ground sensor @ (15.5, 16 - 0.0625), right ground sensor @ (20.5, 8)
            assert.are_equal(-(4 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -(4 - 0.0625) if left sensor is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (16 - 0.0625, 16 - 0.0625), right ground sensor @ (21 - 0.0625, 16 - 0.0625)
            assert.are_equal(-(4 - 0.0625), player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('#mute R should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just above the bottom\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 16 - 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(19, 16 - 0.0625))  -- left ground sensor @ (16.5, 16 - 0.0625), right ground sensor @ (21.5, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return tile_size+1 if both sensors are completely in the air on the right of the tile, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(20, 16 - 0.0625))  -- left ground sensor @ (17.5, 16 - 0.0625), right ground sensor @ (22.5, 16 - 0.0625)
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- just at the bottom, so character is inside tile but sensors above air

          it('should return tile_size+1 if both sensors are just at the bottom of the tile, above air', function ()
            player_char:set_bottom_center(vector(12, 16))
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

        end)

        describe('with ascending slope 45', function ()

          before_each(function ()
            -- create an ascending slope at (1, 1), i.e. (8, 15) to (15, 8) px
            mset(1, 1, 65)
          end)

          -- right sensor at column 0, left sensor in the air

          it('should return 0.0625 if right sensor is just above slope column 0', function ()
            player_char:set_bottom_center(vector(6, 15 - 0.0625))  -- right ground sensor @ (8.5, 15 - 0.0625)
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if right sensor is at the top of column 0', function ()
            player_char:set_bottom_center(vector(6, 15))  -- right ground sensor @ (8.5, 15)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- right sensor at column 4, left sensor in the air

          it('. should return 0.0625 if right sensor is just above slope column 4', function ()
            player_char:set_bottom_center(vector(10, 11 - 0.0625))  -- right ground sensor @ (12.5, 11 - 0.0625)
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('. should return 0 if right sensor is at the top of column 4', function ()
            player_char:set_bottom_center(vector(10, 11))  -- right ground sensor @ (12.5, 11)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -2 if right sensor is below column 4 by 2px', function ()
            player_char:set_bottom_center(vector(10, 13))  -- right ground sensor @ (12.5, 13)
            assert.are_equal(-2, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- right sensor at column 7, left sensor at column 5

          it('should return 0.0625 if right sensor is just above slope column 0', function ()
            player_char:set_bottom_center(vector(18, 8 - 0.0625))  -- right ground sensor @ (15.5, 8 - 0.0625)
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if right sensor is at the top of column 0', function ()
            player_char:set_bottom_center(vector(18, 8))  -- right ground sensor @ (15.5, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -3 if right sensor is below column 0 by 3px', function ()
            player_char:set_bottom_center(vector(18, 11))  -- right ground sensor @ (15.5, 11)
            assert.are_equal(-3, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- left sensor at column 3, right sensor in the air (just behind column 7)

          it('. should return 0.0625 if left sensor is just above slope column 3 (this is a known bug mentioned in Sonic Physics Guide: when Sonic reaches the top of a slope/hill, he goes down again due to the lack of mid-leg sensor)', function ()
            player_char:set_bottom_center(vector(14, 12 - 0.0625))  -- left ground sensor @ (11.5, 12 - 0.0625)
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('. should return 0 if left sensor is at the top of column 3', function ()
            player_char:set_bottom_center(vector(14, 12))  -- left ground sensor @ (11.5, 12)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

        end)

        describe('with descending slope 45', function ()

          before_each(function ()
            -- create a descending slope at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 66)
          end)

          -- right sensor at column 0

          it('. should return 0.0625 if right sensors are just a little above column 0', function ()
            player_char:set_bottom_center(vector(6, 8 - 0.0625))  -- right ground sensor @ (8.5, 8 - 0.0625)
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if right sensors is at the top of column 0', function ()
            player_char:set_bottom_center(vector(6, 8))  -- right ground sensor @ (8.5, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -1 if right sensors is below column 0 by 1px', function ()
            player_char:set_bottom_center(vector(6, 9))  -- right ground sensor @ (8.5, 9)
            assert.are_equal(-1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- right sensor at column 1, bottom segment over column 0

          it('should return 1 if right sensor is 1px above slope column 1 (this is a known bug mentioned in Sonic Physics Guide: when Sonic reaches the top of a slope/hill, he goes down again due to the lack of mid-leg sensor)', function ()
            player_char:set_bottom_center(vector(7, 8))  -- right ground sensor @ (9.5, 8)
            assert.are_equal(1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if right sensor is at the top of column 1', function ()
            player_char:set_bottom_center(vector(7, 9))  -- right ground sensor @ (9.5, 9)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -2 if right sensor is below column 1 by 2px', function ()
            player_char:set_bottom_center(vector(7, 11))  -- right ground sensor @ (9.5, 11)
            assert.are_equal(-2, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- left sensor at column 0, right sensor at column 5

          it('should return 0.0625 if left sensor is just above slope column 0', function ()
            player_char:set_bottom_center(vector(11, 8 - 0.0625))  -- left ground sensor @ (8.5, 8 - 0.0625)
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is at the top of column 0', function ()
            player_char:set_bottom_center(vector(11, 8))  -- left ground sensor @ (8.5, 8)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -3 if left sensor is below column 0 by 3px', function ()
            player_char:set_bottom_center(vector(11, 11))  -- left ground sensor @ (8.5, 11)
            assert.are_equal(-3, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- left sensor at column 3, right sensor in the air

          it('. should return 0.0625 if left sensor is just above slope column 3', function ()
            player_char:set_bottom_center(vector(14, 11 - 0.0625))  -- left ground sensor @ (11.5, 5 - 0.0625)
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('. should return 0 if left sensor is at the top of column 3', function ()
            player_char:set_bottom_center(vector(14, 11))  -- left ground sensor @ (11.5, 11)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -4 if left sensor is below column 3 by 4px', function ()
            player_char:set_bottom_center(vector(14, 15))  -- left ground sensor @ (11.5, 15)
            assert.are_equal(-4, player_char:_compute_signed_distance_to_closest_ground())
          end)

          -- left sensor at column 7, right sensor in the air

          it('should return 0.0625 if left sensor is just above slope column 7', function ()
            player_char:set_bottom_center(vector(18, 15 - 0.0625))  -- left ground sensor @ (15.5, 15 - 0.0625)
            assert.are_equal(0.0625, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return 0 if left sensor is at the top of column 7', function ()
            player_char:set_bottom_center(vector(18, 15))  -- left ground sensor @ (15.5, 15)
            assert.are_equal(0, player_char:_compute_signed_distance_to_closest_ground())
          end)

        end)

        describe('with ascending slope 22.5 offset by 2', function ()

          before_each(function ()
            -- create an ascending slope 22.5 at (1, 1), i.e. (8, 14) to (15, 11) px
            mset(1, 1, 67)
          end)

          it('should return -4 if left sensor is below column 1 by 1px and right sensor is below column 7 by 4px)', function ()
            player_char:set_bottom_center(vector(12, 15))  -- left ground sensor @ (8 + 1.5, 16 - 1), right ground sensor @ (8 + 6.5, 16 - 1)
            assert.are_equal(-4, player_char:_compute_signed_distance_to_closest_ground())
          end)

        end)

        describe('with quarter-tile', function ()

          before_each(function ()
            -- create a quarter-tile at (1, 1), i.e. (12, 12) to (15, 15) px
            mset(1, 1, 71)
          end)

          it('should return tile_size+1 if right sensor is just at the bottom of the tile, on the left part, so in the air (and not 0 just because it is at height 0)', function ()
            player_char:set_bottom_center(vector(9, 16))  -- right ground sensor @ (11.5, 16)
            -- note that it works not because we check for a column mask height of 0 manually, but because if the sensor reaches the bottom of the tile it automatically checks for the tile below
            assert.are_equal(tile_size+1, player_char:_compute_signed_distance_to_closest_ground())
          end)

          it('should return -2 if right sensor is below tile by 2px, left sensor in the air (still in the whole tile, but above column height 0)', function ()
            player_char:set_bottom_center(vector(12, 14))  -- right ground sensor @ (14.5, 14)
            assert.are_equal(-2, player_char:_compute_signed_distance_to_closest_ground())
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

          it('should return -4 if left and right sensors are below top by 4px, with character crossing 2 tiles', function ()
            player_char:set_bottom_center(vector(12, 18))

            -- interface
            assert.are_equal(-4, player_char:_compute_signed_distance_to_closest_ground())
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
            assert.are_equal(16, player_char:_compute_stacked_column_height_above(location(0, 2), 4, 20))
          end)

          it('should return upper_limit+1 above tile (0, 2) for any column index if upper_limit<16', function ()
            assert.are_equal(9, player_char:_compute_stacked_column_height_above(location(0, 2), 4, 8))
          end)

        end)

        describe('with full flat tile + quarter-tile', function ()

          before_each(function ()
            mset(0, 0, 71)  -- bottom-right quarter-tile
            mset(0, 1, 64)  -- full tile
          end)

          it('should return 8 above tile (0, 2) for column index 0, 1, 2, 3', function ()
            assert.are_equal(8, player_char:_compute_stacked_column_height_above(location(0, 2), 3, 20))
          end)

          it('should return 12 above tile (0, 2) for column index 4, 5, 6, 7', function ()
            assert.are_equal(12, player_char:_compute_stacked_column_height_above(location(0, 2), 4, 20))
          end)

          it('should return upper_limit+1 above tile (0, 2) for column index 4, 5, 6, 7 if upper_limit<12', function ()
            assert.are_equal(5, player_char:_compute_stacked_column_height_above(location(0, 2), 4, 4))
          end)

        end)

      end)

      describe('_compute_stacked_empty_column_height_below', function ()

        it('should return upper_limit+1 when there is no tile below at all', function ()
          assert.are_equal(21, player_char:_compute_stacked_empty_column_height_below(location(0, 0), 4, 20))
        end)

        describe('with full flat tile', function ()

          before_each(function ()
            mset(0, 3, 64)  -- full tile
          end)

          it('should return 8 below tile (0, 1) for any column index', function ()
            assert.are_equal(8, player_char:_compute_stacked_empty_column_height_below(location(0, 1), 4, 20))
          end)

          it('should return 16 below tile (0, 0) for any column index', function ()
            assert.are_equal(16, player_char:_compute_stacked_empty_column_height_below(location(0, 0), 4, 20))
          end)

        end)

        describe('with quarter-tile', function ()

          before_each(function ()
            mset(0, 3, 71)  -- bottom-right quarter-tile
          end)

          it('should return upper_limit+1 below tile (0, 2) for column index 0, 1, 2, 3', function ()
            assert.are_equal(21, player_char:_compute_stacked_empty_column_height_below(location(0, 2), 3, 20))
          end)

          it('should return 4 below tile (0, 2) for column index 4, 5, 6, 7', function ()
            assert.are_equal(4, player_char:_compute_stacked_empty_column_height_below(location(0, 2), 4, 20))
          end)

          it('should return 4 below tile (0, 0) for column index 4, 5, 6, 7', function ()
            assert.are_equal(20, player_char:_compute_stacked_empty_column_height_below(location(0, 0), 4, 20))
          end)

        end)

      end)

      describe('_compute_column_height_at', function ()


        it('should return 0 if tile location is outside map area', function ()
          assert.are_equal(0, player_char:_compute_column_height_at(location(-1, 2), 0))
        end)

        it('should return 0 if tile has collision flag unset', function ()
          assert.are_equal(0, player_char:_compute_column_height_at(location(1, 1), 0))
        end)

        describe('with invalid tile', function ()

          before_each(function ()
            -- create an invalid tile with a collision flag but no collision mask associated
            mset(1, 1, 1)
          end)

          it('should assert if tile has collision flag set but no collision mask id associated', function ()
            assert.has_error(function ()
              player_char:_compute_column_height_at(location(1, 1), 0)
            end,
            "sprite_id_to_collision_mask_id_locations does not contain entry for sprite id: 1, yet it has the collision flag set")
          end)

        end)

        describe('with ascending slope 22.5 offset by 2', function ()

          before_each(function ()
            -- create an ascending slope 22.5 at (1, 1), i.e. (8, 14) to (15, 11) px
            mset(1, 1, 67)
          end)

          it('should return 3 on column 3', function ()
            assert.are_equal(3, player_char:_compute_column_height_at(location(1, 1), 3))
          end)

        end)

      end)

      describe('_check_escape_from_ground_and_update_motion_state', function ()

        local check_escape_from_ground_mock
        local update_platformer_motion_state_stub

        setup(function ()
          check_escape_from_ground_mock = stub(player_character, "_check_escape_from_ground", function ()
            return true
          end)
          update_platformer_motion_state_stub = stub(player_character, "_update_platformer_motion_state")
        end)

        teardown(function ()
          check_escape_from_ground_mock:revert()
          update_platformer_motion_state_stub:revert()
        end)

        it('should call _check_escape_from_ground and call _update_platformer_motion_state with the result', function ()
          player_char:_update_platformer_motion_airborne()

          -- implementation
          assert.spy(check_escape_from_ground_mock).was_called(1)
          assert.spy(check_escape_from_ground_mock).was_called_with(match.ref(player_char))
          assert.spy(update_platformer_motion_state_stub).was_called(1)
          assert.spy(update_platformer_motion_state_stub).was_called_with(match.ref(player_char), true)
        end)

      end)

      describe('_check_escape_from_ground', function ()

        describe('with full flat tile', function ()

          before_each(function ()
            -- create a full tile at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 64)
          end)

          it('should do nothing when character is not touching ground at all', function ()
            player_char:set_bottom_center(vector(12, 6))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 6), false}, {player_char:get_bottom_center(), result})
          end)

          it('should do nothing when character is just on top of the ground', function ()
            player_char:set_bottom_center(vector(12, 8))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 8), true}, {player_char:get_bottom_center(), result})
          end)

          it('should move the character upward just enough to escape ground if character is inside ground', function ()
            player_char:set_bottom_center(vector(12, 9))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 8), true}, {player_char:get_bottom_center(), result})
          end)

          it('should do nothing when character is too deep inside the ground', function ()
            player_char:set_bottom_center(vector(12, 13))
            local result = player_char:_check_escape_from_ground()

            -- interface
            assert.are_same({vector(12, 13), true}, {player_char:get_bottom_center(), result})
          end)

        end)

        describe('with descending slope 45', function ()

          before_each(function ()
            -- create a descending slope at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 66)
          end)

          it('should do nothing when character is not touching ground at all', function ()
            player_char:set_bottom_center(vector(15, 10))
            player_char:_check_escape_from_ground()

            -- interface
            assert.are_equal(vector(15, 10), player_char:get_bottom_center())
          end)

          it('should do nothing when character is just on top of the ground', function ()
            player_char:set_bottom_center(vector(15, 12))
            player_char:_check_escape_from_ground()

            -- interface
            assert.are_equal(vector(15, 12), player_char:get_bottom_center())
          end)

          it('should move the character upward just enough to escape ground if character is inside ground', function ()
            player_char:set_bottom_center(vector(15, 13))
            player_char:_check_escape_from_ground()

            -- interface
            assert.are_equal(vector(15, 12), player_char:get_bottom_center())
          end)

          it('should do nothing when character is too deep inside the ground', function ()
            player_char:set_bottom_center(vector(11, 13))
            player_char:_check_escape_from_ground()

            -- interface
            assert.are_equal(vector(11, 13), player_char:get_bottom_center())
          end)

        end)

      end)  -- _check_escape_from_ground

      describe('_update_platformer_motion_grounded (when _update_velocity_grounded sets velocity to (2, 0))', function ()

        local update_ground_speed_stub
        local update_velocity_grounded_mock
        local check_jump_intention_stub

        setup(function ()
          update_ground_speed_stub = stub(player_character, "_update_ground_speed")
          update_velocity_grounded_mock = stub(player_character, "_update_velocity_grounded", function (self)
            self.velocity_frame = vector(2, 0)
          end)
          check_jump_intention_stub = stub(player_character, "_check_jump_intention")
        end)

        teardown(function ()
          update_ground_speed_stub:revert()
          update_velocity_grounded_mock:revert()
          check_jump_intention_stub:revert()
        end)

        after_each(function ()
          update_ground_speed_stub:clear()
          update_velocity_grounded_mock:clear()
          check_jump_intention_stub:clear()
        end)


        it('should call _update_ground_speed, _update_velocity_grounded', function ()
          player_char:_update_platformer_motion_grounded()

          -- implementation
          assert.spy(update_ground_speed_stub).was_called(1)
          assert.spy(update_ground_speed_stub).was_called_with(match.ref(player_char))
          assert.spy(update_velocity_grounded_mock).was_called(1)
          assert.spy(update_velocity_grounded_mock).was_called_with(match.ref(player_char))
        end)

        describe('(when _check_jump doesn\'t change velocity and returns false)', function ()

          setup(function ()
            check_jump_mock = stub(player_character, "_check_jump", function (self)
              return false
            end)
            spy.on(player_character, "_snap_to_ground")
          end)

          teardown(function ()
            check_jump_mock:revert()
            player_character._snap_to_ground:revert()
          end)

          after_each(function ()
            check_jump_mock:clear()
            player_character._snap_to_ground:clear()
          end)

          it('should move the character based on its velocity after update (no jump), and try to snap', function ()
            player_char:set_bottom_center(vector(3, 8))
            player_char:_update_platformer_motion_grounded()

            -- no interface test on position, we are not sure if it actually snapped or not

            -- implementation
            assert.spy(check_jump_mock).was_called(1)
            assert.spy(check_jump_mock).was_called_with(match.ref(player_char))
            assert.spy(player_character._snap_to_ground).was_called(1)
            assert.spy(player_character._snap_to_ground).was_called_with(match.ref(player_char))
          end)

          describe('(when character is grounded after trying to snap)', function ()

            before_each(function ()
              mset(0, 1, 68)  -- wavy horizontal almost full tile (to test snapping interface)
            end)

            it('should succeed snapping after move, and call _check_jump_intention', function ()
              player_char:set_bottom_center(vector(3, 8))
              player_char:_update_platformer_motion_grounded()

              -- interface
              assert.are_same({motion_states.grounded, vector(5, 9)}, {player_char.motion_state, player_char:get_bottom_center()})

              -- implementation
              assert.spy(check_jump_intention_stub).was_called(1)
              assert.spy(check_jump_intention_stub).was_called_with(match.ref(player_char))
            end)

          end)

          describe('(when character is airborne even after trying to snap)', function ()

            -- no tile at all!

            it('should fail snapping after move, and not call _check_jump_intention', function ()
              player_char:set_bottom_center(vector(3, 8))
              player_char:_update_platformer_motion_grounded()

              -- interface
              assert.are_same({motion_states.airborne, vector(5, 8)}, {player_char.motion_state, player_char:get_bottom_center()})

              -- implementation
              assert.spy(check_jump_intention_stub).was_not_called()
            end)

          end)

        end)

        describe('(when _check_jump changes velocity and returns true)', function ()

          setup(function ()
            check_jump_mock = stub(player_character, "_check_jump", function (self)
              self.velocity_frame.y = 3
              return true
            end)
            spy.on(player_character, "_snap_to_ground")
          end)

          teardown(function ()
            check_jump_mock:revert()
            player_character._snap_to_ground:revert()
          end)

          after_each(function ()
            check_jump_mock:clear()
            player_character._snap_to_ground:clear()
          end)

          it('should move the character based on its velocity after update/jump, without snapping, and not call _check_jump_intention', function ()
            player_char:set_bottom_center(vector(3, 8))
            player_char:_update_platformer_motion_grounded()

            -- interface
            assert.are_same({motion_states.grounded, vector(5, 11)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(check_jump_mock).was_called(1)
            assert.spy(check_jump_mock).was_called_with(match.ref(player_char))
            assert.spy(player_character._snap_to_ground).was_not_called()
            assert.spy(check_jump_intention_stub).was_not_called()
          end)

        end)

      end)

      describe('_update_ground_speed', function ()

        it('should accelerate when character has ground speed 0 and move intention x is not 0', function ()
          player_char.move_intention.x = 1
          player_char:_update_ground_speed()
          assert.are_equal(playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should accelerate when character has ground speed > 0 and move intention x > 0', function ()
          player_char.ground_speed_frame = 1.5
          player_char.move_intention.x = 1
          player_char:_update_ground_speed()
          assert.are_equal(1.5 + playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should accelerate when character has ground speed < 0 and move intention x < 0', function ()
          player_char.ground_speed_frame = -1.5
          player_char.move_intention.x = -1
          player_char:_update_ground_speed()
          assert.are_equal(-1.5 - playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should decelerate keeping same sign when character has high ground speed > 0 and move intention x < 0', function ()
          player_char.ground_speed_frame = 1.5
          player_char.move_intention.x = -1
          player_char:_update_ground_speed()
          -- ground_decel_frame2 = 0.25, subtract it from ground_speed_frame
          assert.are_equal(1.25, player_char.ground_speed_frame)
        end)

        -- bugfix history: missing tests that check the change of sign of ground speed
        it('_ should decelerate and change sign when character has low ground speed > 0 and move intention x < 0 '..
          'but the ground speed is high enough so that the new speed wouldn\'t be over the max ground speed', function ()
          -- start with speed >= -ground_accel_frame2 + ground_decel_frame2
          player_char.ground_speed_frame = 0.24
          player_char.move_intention.x = -1
          player_char:_update_ground_speed()
          assert.is_true(almost_eq_with_message(-0.01, player_char.ground_speed_frame, 1e-16))
        end)

        it('should decelerate and clamp to the max ground speed in the opposite sign '..
          'when character has low ground speed > 0 and move intention x < 0', function ()
          -- start with speed < -ground_accel_frame2 + ground_decel_frame2
          player_char.ground_speed_frame = 0.12
          player_char.move_intention.x = -1
          player_char:_update_ground_speed()
          assert.are_equal(-playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should decelerate keeping same sign when character has high ground speed < 0 and move intention x > 0', function ()
          player_char.ground_speed_frame = -1.5
          player_char.move_intention.x = 1
          player_char:_update_ground_speed()
          assert.are_equal(-1.25, player_char.ground_speed_frame)
        end)

        -- bugfix history: missing tests that check the change of sign of ground speed
        it('_ should decelerate and change sign when character has low ground speed < 0 and move intention x > 0 '..
          'but the ground speed is high enough so that the new speed wouldn\'t be over the max ground speed', function ()
          -- start with speed <= ground_accel_frame2 - ground_decel_frame2
          player_char.ground_speed_frame = -0.24
          player_char.move_intention.x = 1
          player_char:_update_ground_speed()
          assert.is_true(almost_eq_with_message(0.01, player_char.ground_speed_frame, 1e-16))
        end)

        it('should decelerate and clamp to the max ground speed in the opposite sign '..
          'when character has low ground speed < 0 and move intention x > 0', function ()
          -- start with speed > ground_accel_frame2 - ground_decel_frame2
          player_char.ground_speed_frame = -0.12
          player_char.move_intention.x = 1
          player_char:_update_ground_speed()
          assert.are_equal(playercharacter_data.ground_accel_frame2, player_char.ground_speed_frame)
        end)

        it('should apply friction when character has ground speed > 0 and move intention x is 0', function ()
          player_char.ground_speed_frame = 1.5
          player_char:_update_ground_speed()
          assert.are_equal(1.5 - playercharacter_data.ground_friction_frame2, player_char.ground_speed_frame)
        end)

        -- bugfix history: missing tests that check the change of sign of ground speed
        it('_ should apply friction but stop at 0 without changing ground speed sign when character has low ground speed > 0 and move intention x is 0', function ()
          -- must be < friction
          player_char.ground_speed_frame = 0.01
          player_char:_update_ground_speed()
          assert.are_equal(0, player_char.ground_speed_frame)
        end)

        it('should apply friction when character has ground speed < 0 and move intention x is 0', function ()
          player_char.ground_speed_frame = -1.5
          player_char:_update_ground_speed()
          assert.are_equal(-1.5 + playercharacter_data.ground_friction_frame2, player_char.ground_speed_frame)
        end)

        -- bugfix history: missing tests that check the change of sign of ground speed
        it('_ should apply friction but stop at 0 without changing ground speed sign when character has low ground speed < 0 and move intention x is 0', function ()
          -- must be < friction in abs
          player_char.ground_speed_frame = -0.01
          player_char:_update_ground_speed()
          assert.are_equal(0, player_char.ground_speed_frame)
        end)

        it('should not change ground speed when ground speed is 0 and move intention x is 0', function ()
          player_char:_update_ground_speed()
          assert.are_equal(0, player_char.ground_speed_frame)
        end)

      end)

      describe('_update_velocity_grounded', function ()

        it('should set the current velocity to a horizontal vector with x: signed ground speed', function ()
          player_char.ground_speed_frame = -3
          player_char:_update_velocity_grounded()
          assert.are_equal(vector(-3, 0), player_char.velocity_frame)
        end)
      end)

      describe('_check_jump_intention', function ()

        it('should do nothing when jump_intention is false', function ()
          player_char:_check_jump_intention()
          assert.are_same({false, false}, {player_char.jump_intention, player_char.should_jump})
        end)

        it('should consume jump_intention and set should_jump to true if jump_intention is true', function ()
          player_char.jump_intention = true
          player_char:_check_jump_intention()
          assert.are_same({false, true}, {player_char.jump_intention, player_char.should_jump})
        end)

      end)

      describe('_check_jump', function ()

        it('should return false when should_jump is false', function ()
          player_char.velocity_frame = vector(4, -1)
          local result = player_char:_check_jump()

          -- interface
          assert.are_same({false, vector(4, -1), motion_states.grounded}, {result, player_char.velocity_frame, player_char.motion_state})
        end)

        it('should consume should_jump, add initial hop velocity, update motion state and return false when should_jump is true and hold_jump_intention is false', function ()
          player_char.velocity_frame = vector(4, -1)
          player_char.should_jump = true
          local result = player_char:_check_jump()

          -- interface
          assert.are_same({true, vector(4, -3), motion_states.airborne}, {result, player_char.velocity_frame, player_char.motion_state})
        end)

        it('should consume should_jump, add initial var jump velocity, update motion state and return false when should_jump is true and hold_jump_intention is true', function ()
          player_char.velocity_frame = vector(4, -1)
          player_char.should_jump = true
          player_char.hold_jump_intention = true
          local result = player_char:_check_jump()

          -- interface
          assert.are_same({true, vector(4, -4.25), motion_states.airborne}, {result, player_char.velocity_frame, player_char.motion_state})
        end)

      end)

      describe('_snap_to_ground', function ()

        setup(function ()
          spy.on(player_character, "_update_platformer_motion_state")
        end)

        teardown(function ()
          player_character._update_platformer_motion_state:revert()
        end)

        after_each(function ()
          player_character._update_platformer_motion_state:clear()
        end)

        describe('(1 quarter-tile tile on top of full tile)', function ()

          before_each(function ()
            mset(0, 1, 71)  -- quarter-tile (bottom-right quarter)
            mset(0, 2, 64)  -- full tile
          end)

          it('should snap y up to quarter-tile on tile above (distance <= max_ground_escape_height)', function ()
            player_char:set_bottom_center(vector(4, 16))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(4, 12)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()
          end)

          it('should NOT snap y up to quarter-tile on tile above (distance > max_ground_escape_height)', function ()
            player_char:set_bottom_center(vector(4, 17))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(4, 17)}, {player_char.motion_state, player_char:get_bottom_center()})
            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()
          end)

        end)

        describe('(2x wavy tile)', function ()

          before_each(function ()
            mset(0, 1, 68)  -- wavy horizontal almost full tile
            mset(1, 1, 68)  -- wavy horizontal almost full tile
          end)

          it('should NOT snap y down to surface column 4 height 6 (distance > max_ground_snap_height)', function ()
            player_char:set_bottom_center(vector(1, 5))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.airborne, vector(1, 5)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_called(1)
            assert.spy(player_character._update_platformer_motion_state).was_called_with(match.ref(player_char), false)
          end)

          it('should snap y down to non-empty/full column 4 height 6 (distance <= max_ground_escape_height, only left sensor on ground)', function ()
            player_char:set_bottom_center(vector(1, 8))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(1, 10)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()
          end)

          it('should NOT snap when character is already just on the ground', function ()
            player_char:set_bottom_center(vector(1, 10))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(1, 10)}, {player_char.motion_state, player_char:get_bottom_center()})
            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()

          end)

          it('should snap y up to surface column 4 height 6 (distance <= max_ground_escape_height, only left sensor on ground)', function ()
            player_char:set_bottom_center(vector(1, 12))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(1, 10)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()
          end)

          it('should NOT snap y down to surface column 4 height 6 (distance > max_ground_escape_height)', function ()
            player_char:set_bottom_center(vector(1, 15))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(1, 15)}, {player_char.motion_state, player_char:get_bottom_center()})
            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()

          end)

          it('should snap y down to full column 2 with nothing above (right tile) at height 8 (distance <= max_ground_escape_height, right sensor on ground, left above ground)', function ()
            player_char:set_bottom_center(vector(7, 4))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(7, 8)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()
          end)

          it('should snap y up to surface full column 2 with nothing above (right tile) at height 8 (distance <= max_ground_escape_height) ground right sensor on ground, left above ground)', function ()
            player_char:set_bottom_center(vector(7, 12))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(7, 8)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()
          end)

          it('should snap y down to non-empty/full column 6 (left tile) and column 3 (right tile) at same height 7 (both sensors on ground)', function ()
            player_char:set_bottom_center(vector(8, 8))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(8, 9)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()

          end)

        end)

        describe('(high-tile below)', function ()

          before_each(function ()
            mset(0, 1, 73)  -- high-tile (3/4 filled)
          end)

          it('should snap down y to columns 2 and 7 at height 6 on the tile below the current one (distance <= max_ground_snap_height)', function ()
            player_char:set_bottom_center(vector(4, 6))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(4, 10)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()

          end)

          it('should NOT snap y to tile too far below (distance > max_ground_snap_height)', function ()
            player_char:set_bottom_center(vector(4, 5))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.airborne, vector(4, 5)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_called(1)
            assert.spy(player_character._update_platformer_motion_state).was_called_with(match.ref(player_char), false)
          end)

        end)

        describe('(low-tile)', function ()

          before_each(function ()
            mset(0, 1, 72)  -- low-tile (bottom quarter)
          end)

          it('should NOT snap to tile in same location but too low (distance > max_ground_snap_height)', function ()
            player_char:set_bottom_center(vector(4, 9))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.airborne, vector(4, 9)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_called(1)
            assert.spy(player_character._update_platformer_motion_state).was_called_with(match.ref(player_char), false)
          end)

          it('should snap down to tile in same location (distance <= max_ground_snap_height)', function ()
            player_char:set_bottom_center(vector(4, 10))
            player_char:_snap_to_ground()

            -- interface
            assert.are_same({motion_states.grounded, vector(4, 14)}, {player_char.motion_state, player_char:get_bottom_center()})

            -- implementation
            assert.spy(player_character._update_platformer_motion_state).was_not_called()
          end)

        end)

      end)

      describe('_update_platformer_motion_airborne', function ()

        local check_hold_jump_stub
        local check_escape_from_ground_and_update_motion_state_stub

        setup(function ()
          check_hold_jump_stub = stub(player_character, "_check_hold_jump")
          check_escape_from_ground_and_update_motion_state_stub = stub(player_character, "_check_escape_from_ground_and_update_motion_state")
        end)

        teardown(function ()
          check_hold_jump_stub:revert()
          check_escape_from_ground_and_update_motion_state_stub:revert()
        end)

        after_each(function ()
          check_hold_jump_stub:clear()
          check_escape_from_ground_and_update_motion_state_stub:clear()
        end)

        it('. should apply gravity to speed y', function ()
          player_char:_update_platformer_motion_airborne()
          assert.are_equal(playercharacter_data.gravity_frame2, player_char.velocity_frame.y)
        end)

        it('. should update position with new speed y', function ()
          player_char.position = vector(4, -4)
          player_char:_update_platformer_motion_airborne()
          assert.are_equal(vector(4, -4 + playercharacter_data.gravity_frame2), player_char.position)
        end)

        it('should call _check_hold_jump and _check_escape_from_ground_and_update_motion_state', function ()
          player_char:_update_platformer_motion_airborne()

          -- implementation
          assert.spy(check_hold_jump_stub).was_called(1)
          assert.spy(check_hold_jump_stub).was_called_with(match.ref(player_char))
          assert.spy(check_escape_from_ground_and_update_motion_state_stub).was_called(1)
          assert.spy(check_escape_from_ground_and_update_motion_state_stub).was_called_with(match.ref(player_char))
        end)

      end)  -- _update_platformer_motion_airborne

    end)  -- (with mock tiles data setup)

    describe('_check_hold_jump', function ()

      before_each(function ()
        -- optional, just to enter airborne state and be in a meaningful state
        player_char:_update_platformer_motion_state(false)
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

    describe('_get_ground_sensor_position', function ()

      before_each(function ()
        player_char.position = vector(10, 10)
      end)

      it('* should return the position down-left of the character center when horizontal dir is left', function ()
        assert.are_equal(vector(7.5, 16), player_char:_get_ground_sensor_position(horizontal_directions.left))
      end)

      it('* should return the position down-left of the character center when horizontal dir is right', function ()
        assert.are_equal(vector(12.5, 16), player_char:_get_ground_sensor_position(horizontal_directions.right))
      end)

    end)

    describe('_update_platformer_motion_state', function ()

      describe('(when character is grounded)', function ()

        it('should enter airborne state if no ground is sensed', function ()
          player_char:_update_platformer_motion_state(false)
          assert.are_equal(motion_states.airborne, player_char.motion_state)
        end)

        it('should preserve grounded state if some ground is sensed', function ()
          player_char:_update_platformer_motion_state(true)
          assert.are_equal(motion_states.grounded, player_char.motion_state)
        end)

      end)

      describe('(when character is airborne)', function ()

        before_each(function ()
          player_char.motion_state = motion_states.airborne
        end)

        it('should preserve airborne state if no ground is sensed', function ()
          player_char:_update_platformer_motion_state(false)
          assert.are_equal(motion_states.airborne, player_char.motion_state)
        end)

        it('. should enter grounded state and reset speed y and has_interrupted_jump if some ground is sensed', function ()
          player_char:_update_platformer_motion_state(true)
          assert.are_same({motion_states.grounded, 0, false}, {player_char.motion_state, player_char.velocity_frame.y, player_char.has_interrupted_jump})
        end)

      end)

    end)

    describe('_update_platformer_motion (_update_platformer_motion_grounded sets motion state to airborne)', function ()

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

      describe('(when character is grounded)', function ()

        it('^ should call _update_platformer_motion_grounded', function ()
          player_char:_update_platformer_motion()
          assert.spy(update_platformer_motion_grounded_mock).was_called(1)
          assert.spy(update_platformer_motion_grounded_mock).was_called_with(match.ref(player_char))
          assert.spy(update_platformer_motion_airborne_stub).was_not_called()
        end)

      end)

      describe('(when character is airborne)', function ()

        before_each(function ()
          player_char.motion_state = motion_states.airborne
        end)

        it('^ should call _update_platformer_motion_airborne', function ()
          player_char:_update_platformer_motion()
          assert.spy(update_platformer_motion_airborne_stub).was_called(1)
          assert.spy(update_platformer_motion_airborne_stub).was_called_with(match.ref(player_char))
          assert.spy(update_platformer_motion_grounded_mock).was_not_called()
        end)

      end)

    end)

    describe('_update_debug', function ()

      local update_velocity_debug_stub

      setup(function ()
        update_velocity_debug_mock = stub(player_character, "_update_velocity_debug", function (self)
          self.debug_velocity = 11
        end)
        move_stub = stub(player_character, "move")
      end)

      teardown(function ()
        update_velocity_debug_mock:revert()
        move_stub:revert()
      end)

      it('should call _update_velocity_debug, then move using the new velocity', function ()
        player_char:_update_debug()
        assert.spy(update_velocity_debug_mock).was_called(1)
        assert.spy(update_velocity_debug_mock).was_called_with(match.ref(player_char))
        assert.spy(move_stub).was_called(1)
        assert.spy(move_stub).was_called_with(match.ref(player_char), 11 * delta_time)
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
        player_char:move(player_char.debug_velocity * delta_time)
        assert.is_true(almost_eq_with_message(vector(3.8667, -3.8667), player_char.position))
      end)

      it('when move intention is (-1, 1), update 11 frame => at (−2.73 2.73)', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.debug_velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector(-2.73, 2.73), player_char.position))
        assert.is_true(almost_eq_with_message(vector(-60, 60), player_char.debug_velocity))  -- at max speed
      end)

      it('when move intention is (0, 0) after 11 frames, update 16 frames more => character should have decelerated', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.debug_velocity * delta_time)
        end
        player_char.move_intention = vector.zero()
        for i=1,5 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.debug_velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector(-20, 20), player_char.debug_velocity, 0.01))
      end)

      it('when move intention is (0, 0) after 11 frames, update 19 frames more => character should have stopped', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.debug_velocity * delta_time)
        end
        player_char.move_intention = vector.zero()
        for i=1,8 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.debug_velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector.zero(), player_char.debug_velocity))
      end)

    end)

    describe('render', function ()

      local spr_data_render_stub

      before_each(function ()
        spr_data_render_stub = stub(player_char.spr_data, "render")
      end)

      after_each(function ()
        spr_data_render_stub:revert()
      end)

      after_each(function ()
        spr_data_render_stub:clear()
      end)

      it('should call spr_data:render with the character\'s position', function ()
        player_char:render()
        assert.spy(spr_data_render_stub).was_called(1)
        assert.spy(spr_data_render_stub).was_called_with(match.ref(player_char.spr_data), player_char.position)
      end)
    end)

  end)

end)

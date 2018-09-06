require("bustedhelper")
require("engine/core/math")
local player_character = require("game/ingame/playercharacter")
local collision = require("engine/physics/collision")
local collision_data = require("game/data/collision_data")
local playercharacter_data = require("game/data/playercharacter_data")

describe('player_character', function ()

  describe('_init', function ()

    it('should create a player character at the given position', function ()
      local player_character = player_character(vector(4, -4))
      assert.is_not_nil(player_character)
      assert.are_equal(vector(4, -4), player_character.position)
    end)

    it('should create a player character with 0 velocity and move_intention', function ()
      local player_character = player_character(vector(4, -4))
      assert.is_not_nil(player_character)
      assert.are_same({vector.zero(), 0, vector.zero()},
        {player_character.debug_velocity, player_character.speed_y_per_frame, player_character.move_intention})
    end)

    it('should create a player character with control mode: human, motion mode: platformer, motion state: grounded', function ()
      local player_character = player_character(vector(4, -4))
      assert.is_not_nil(player_character)
      assert.are_same({control_modes.human, motion_modes.platformer, motion_states.grounded},
        {player_character.control_mode, player_character.motion_mode, player_character.motion_state})
    end)

  end)

  describe('(with player character at (4, -4), speed 60, debug accel 480)', function ()
    local player_char

    before_each(function ()
      -- recreate player character for each test (setup spies will need to refer to player_character, not the instance)
      player_char = player_character(vector(4, -4))
      player_char.debug_move_max_speed = 60.
      player_char.debug_move_accel = 480.
      player_char.debug_move_decel = 480.
    end)

    describe('_tostring', function ()
      it('should return "[player_character at vector(4, -4)]"', function ()
        assert.are_equal("[player_character at vector(4, -4)]", player_char:_tostring())
      end)
    end)

    describe('move', function ()
      it('at (4 -4) move (-5 4) => at (-1 0)', function ()
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

      local update_platformer_stub
      local update_debug_stub

      setup(function ()
        update_platformer_stub = stub(player_character, "_update_platformer")
        update_debug_stub = stub(player_character, "_update_debug")
      end)

      teardown(function ()
        update_platformer_stub:revert()
        update_debug_stub:revert()
      end)

      after_each(function ()
        update_platformer_stub:clear()
        update_debug_stub:clear()
      end)

      describe('(when motion mode is platformer)', function ()

        it('should call _update_platformer', function ()
          player_char:update()
          assert.spy(update_platformer_stub).was_called()
          assert.spy(update_platformer_stub).was_called_with(match.ref(player_char))
          assert.spy(update_debug_stub).was_not_called()
        end)

      end)

      describe('(when motion mode is debug)', function ()

        before_each(function ()
          player_char.motion_mode = motion_modes.debug
        end)

        it('. should call _update_debug', function ()
          player_char:update()
          assert.spy(update_debug_stub).was_called()
          assert.spy(update_debug_stub).was_called_with(match.ref(player_char))
          assert.spy(update_platformer_stub).was_not_called()
        end)

      end)

    end)

    describe('_update_platformer', function ()

      local sense_ground_mock
      local update_platformer_motion_state_stub
      local update_platformer_motion_stub

      setup(function ()
        sense_ground_mock = stub(player_character, "_intersects_with_ground", function ()
          return true
        end)
        update_platformer_motion_state_stub = stub(player_character, "_update_platformer_motion_state")
        update_platformer_motion_stub = stub(player_character, "_update_platformer_motion")
      end)

      teardown(function ()
        sense_ground_mock:revert()
        update_platformer_motion_state_stub:revert()
        update_platformer_motion_stub:revert()
      end)

      it('should call _intersects_with_ground, passing the result to _update_platformer_motion_state, then call _update_platformer_motion', function ()
        player_char:_update_platformer()
        assert.spy(sense_ground_mock).was_called()
        assert.spy(sense_ground_mock).was_called_with(match.ref(player_char))
        assert.spy(update_platformer_motion_state_stub).was_called()
        assert.spy(update_platformer_motion_state_stub).was_called_with(match.ref(player_char), true)
        assert.spy(update_platformer_motion_stub).was_called()
        assert.spy(update_platformer_motion_stub).was_called_with(match.ref(player_char))
      end)

    end)

    describe('(with mock tiles data setup)', function ()

      local height_array_init_mock

      setup(function ()
        -- initialize with clear map around locations of interest
        for i = 0, 3 do
          for j = 0, 3 do
            mset(i, j, 0)
          end
        end

        -- mock sprite flags
        fset(64, sprite_flags.collision, true)  -- full tile
        fset(65, sprite_flags.collision, true)  -- ascending slope 45
        fset(66, sprite_flags.collision, true)  -- descending slope 45
        fset(67, sprite_flags.collision, true)  -- ascending slope 22.5 offset by 2
        fset(70, sprite_flags.collision, true)  -- half-tile (bottom half)
        fset(71, sprite_flags.collision, true)  -- quarter-tile (bottom-right half)
        fset(72, sprite_flags.collision, true)  -- low-tile (bottom quarter)
        fset(1, sprite_flags.collision, true)   -- invalid tile (missing collision mask id location in sprite_id_to_collision_mask_id_locations)

        -- mock height array _init so it doesn't have to dig in sprite data, inaccessible from busted
        height_array_init_mock = stub(collision.height_array, "_init", function (self, tile_mask_id_location, slope_angle)
          if tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[64] then
            self._array = {8, 8, 8, 8, 8, 8, 8, 8}  -- full tile
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[65] then
            self._array = {1, 2, 3, 4, 5, 6, 7, 8}  -- ascending slope 45
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[66] then
            self._array = {8, 7, 6, 5, 4, 3, 2, 1}  -- descending slope 45
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[67] then
            self._array = {2, 2, 3, 3, 4, 4, 5, 5}  -- ascending slope 22.5
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[70] then
            self._array = {4, 4, 4, 4, 4, 4, 4, 4}  -- half-tile (bottom half)
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[71] then
            self._array = {0, 0, 0, 0, 4, 4, 4, 4}  -- quarter-tile (bottom half)
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[72] then
            self._array = {2, 2, 2, 2, 2, 2, 2, 2}  -- low-tile (bottom quarter)
          end
          self._slope_angle = slope_angle
        end)
      end)

      teardown(function ()
        fset(64, sprite_flags.collision, false)
        fset(65, sprite_flags.collision, false)
        fset(66, sprite_flags.collision, false)
        fset(67, sprite_flags.collision, false)
        fset(70, sprite_flags.collision, false)
        fset(71, sprite_flags.collision, false)
        fset(72, sprite_flags.collision, false)
        fset(1, sprite_flags.collision, false)

        height_array_init_mock:revert()
      end)

      after_each(function ()
        -- clear map
        for i = 0, 3 do
          for j = 0, 3 do
            mset(i, j, 0)
          end
        end
      end)

      describe('_compute_ground_penetration_height', function ()

        describe('with full flat tile', function ()

          before_each(function ()
            -- create a full tile at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 64)
          end)

          -- just above

          it('should return -1 if both sensors are just a little above the tile', function ()
            player_char:set_bottom_center(vector(12, 8 - 0.0625))
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          -- on top

          it('should return -1 if both sensors are completely in the air on the left of the tile, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(4, 8))  -- right ground sensor @ (6.5, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('+ should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(5, 8))  -- right ground sensor @ (7.5, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('+ should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 8))  -- right ground sensor @ (8 - 0.0625, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('+ should return 0 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just at the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just at the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 8))  -- right ground sensor @ (8, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is in the air on the left of the tile and right sensor is at the top of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it in x', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 8))  -- left ground sensor @ (8 - 0.0625, 8), right ground sensor @ (13 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if both sensors are just at the top of tile, with left sensor just at the top of the topleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 8))  -- left ground sensor @ (8, 8), right ground sensor @ (13, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if both sensors are just at the top of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 8))  -- left ground sensor @ (9.5, 8), right ground sensor @ (14.5, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if both sensors are just at the top of tile and right sensor just at the top of the right-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 8))  -- left ground sensor @ (11 - 0.0625, 8), right ground sensor @ (16 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is at the top of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 8))  -- left ground sensor @ (11, 8), right ground sensor @ (16, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is just at the top of the right-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 8))  -- left ground sensor @ (15.5, 8), right ground sensor @ (20.5, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is just at the top of the right-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 8))  -- left ground sensor @ (16 - 0.0625, 8), right ground sensor @ (21 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('+ should return -1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just at the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 8))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(19, 8))  -- left ground sensor @ (16.5, 8), right ground sensor @ (21.5, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if both sensors are completely in the air on the right of the tile, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(20, 8))  -- left ground sensor @ (17.5, 8), right ground sensor @ (22.5, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          -- just inside the top

          it('should return -1 if both sensors are completely in the air on the left of the tile, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(4, 8 + 0.0625))  -- right ground sensor @ (6.5, 8 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('R should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(5, 8 + 0.0625))  -- right ground sensor @ (7.5, 8 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('R should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 8 + 0.0625))  -- right ground sensor @ (8 - 0.0625, 8 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('R should return 0.0625 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just below the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just below the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 8 + 0.0625))  -- right ground sensor @ (8, 8 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if left sensor is in the air on the left of the tile and right sensor is just inside the top of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 8 + 0.0625))  -- left ground sensor @ (8 - 0.0625, 8 + 0.0625), right ground sensor @ (13 - 0.0625, 8 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if both sensors are just inside the top of tile, with left sensor just inside the top of the topleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 8 + 0.0625))  -- left ground sensor @ (8, 8 + 0.0625), right ground sensor @ (13, 8 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if both sensors are just inside the top of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 8 + 0.0625))  -- left ground sensor @ (9.5, 8 + 0.0625), right ground sensor @ (14.5, 8 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if both sensors are just inside the top of tile and right sensor just inside the top of the topright-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 8 + 0.0625))  -- left ground sensor @ (11 - 0.0625, 8 + 0.0625), right ground sensor @ (16 - 0.0625, 8 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if left sensor is just inside the top of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 8 + 0.0625))  -- left ground sensor @ (11, 8 + 0.0625), right ground sensor @ (16, 8)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if left sensor is just inside the top of the topright-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 8 + 0.0625))  -- left ground sensor @ (15.5, 8 + 0.0625), right ground sensor @ (20.5, 8)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if left sensor is just inside the top of the topright-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 8 + 0.0625))  -- left ground sensor @ (16 - 0.0625, 8 + 0.0625), right ground sensor @ (21 - 0.0625, 8 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('R should return -1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just below the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 8 + 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 8 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(19, 8 + 0.0625))  -- left ground sensor @ (16.5, 8 + 0.0625), right ground sensor @ (21.5, 8 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if both sensors are completely in the air on the right of the tile, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(20, 8 + 0.0625))  -- left ground sensor @ (17.5, 8 + 0.0625), right ground sensor @ (22.5, 8 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          -- just inside the bottom

          it('should return -1 if both sensors are completely in the air on the left of the tile, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(4, 16 - 0.0625))  -- right ground sensor @ (6.5, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('R should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(5, 16 - 0.0625))  -- right ground sensor @ (7.5, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('R should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 16 - 0.0625))  -- right ground sensor @ (8 - 0.0625, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('R should return 8 - 0.0625 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just above the bottom of the bottomleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just above the bottom\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 16 - 0.0625))  -- right ground sensor @ (8, 16 - 0.0625)
            assert.are_equal(8 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 8 - 0.0625 if left sensor is in the air on the left of the tile and right sensor is just inside the bottom of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (8 - 0.0625, 16 - 0.0625), right ground sensor @ (13 - 0.0625, 16 - 0.0625)
            assert.are_equal(8 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 8 - 0.0625 if both sensors are just inside the bottom of tile, with left sensor just inside the bottom of the bottomleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 16 - 0.0625))  -- left ground sensor @ (8, 16 - 0.0625), right ground sensor @ (13, 16 - 0.0625)
            assert.are_equal(8 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 8 - 0.0625 if both sensors are just inside the bottom of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 16 - 0.0625))  -- left ground sensor @ (9.5, 16 - 0.0625), right ground sensor @ (14.5, 16 - 0.0625)
            assert.are_equal(8 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 8 - 0.0625 if both sensors are just inside the bottom of tile and right sensor just inside the bottom of the bottomright-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (11 - 0.0625, 16 - 0.0625), right ground sensor @ (16 - 0.0625, 16 - 0.0625)
            assert.are_equal(8 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 8 - 0.0625 if left sensor is just inside the bottom of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 16 - 0.0625))  -- left ground sensor @ (11, 16 - 0.0625), right ground sensor @ (16, 8)
            assert.are_equal(8 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 8 - 0.0625 if left sensor is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 16 - 0.0625))  -- left ground sensor @ (15.5, 16 - 0.0625), right ground sensor @ (20.5, 8)
            assert.are_equal(8 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 8 - 0.0625 if left sensor is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (16 - 0.0625, 16 - 0.0625), right ground sensor @ (21 - 0.0625, 16 - 0.0625)
            assert.are_equal(8 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('R should return -1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just above the bottom\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 16 - 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(19, 16 - 0.0625))  -- left ground sensor @ (16.5, 16 - 0.0625), right ground sensor @ (21.5, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if both sensors are completely in the air on the right of the tile, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(20, 16 - 0.0625))  -- left ground sensor @ (17.5, 16 - 0.0625), right ground sensor @ (22.5, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          -- just at the bottom, so character is inside tile but sensors above air

          it('should return -1 if both sensors are just at the bottom of the tile, above air', function ()
            player_char:set_bottom_center(vector(12, 16))
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

        end)

        describe('with half flat tile', function ()

          before_each(function ()
            -- create a half-tile at (0, 1), top-left at (0, 12), top-right at (7, 12) included
            mset(1, 1, 70)
          end)

          -- just above

          it('should return -1 if both sensors are just a little above the tile', function ()
            player_char:set_bottom_center(vector(12, 12 - 0.0625))
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          -- on top

          it('should return -1 if both sensors are completely in the air on the left of the tile, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(4, 12))  -- right ground sensor @ (6.5, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(5, 12))  -- right ground sensor @ (7.5, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 12))  -- right ground sensor @ (8 - 0.0625, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return true if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just at the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just at the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 12))  -- right ground sensor @ (8, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is in the air on the left of the tile and right sensor is at the top of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 12))  -- left ground sensor @ (8 - 0.0625, 8), right ground sensor @ (13 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if both sensors are just at the top of tile, with left sensor just at the top of the topleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 12))  -- left ground sensor @ (8, 8), right ground sensor @ (13, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if both sensors are just at the top of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 12))  -- left ground sensor @ (9.5, 8), right ground sensor @ (14.5, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if both sensors are just at the top of tile and right sensor just at the top of the right-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 12))  -- left ground sensor @ (11 - 0.0625, 8), right ground sensor @ (16 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is at the top of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 12))  -- left ground sensor @ (11, 8), right ground sensor @ (16, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is just at the top of the right-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 12))  -- left ground sensor @ (15.5, 8), right ground sensor @ (20.5, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is just at the top of the right-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 12))  -- left ground sensor @ (16 - 0.0625, 8), right ground sensor @ (21 - 0.0625, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just at the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 12))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(19, 12))  -- left ground sensor @ (16.5, 8), right ground sensor @ (21.5, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if both sensors are completely in the air on the right of the tile, just at the ground\'s height', function ()
            player_char:set_bottom_center(vector(20, 12))  -- left ground sensor @ (17.5, 8), right ground sensor @ (22.5, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          -- just inside the top

          it('should return -1 if both sensors are completely in the air on the left of the tile, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(4, 12 + 0.0625))  -- right ground sensor @ (6.5, 12 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(5, 12 + 0.0625))  -- right ground sensor @ (7.5, 12 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 12 + 0.0625))  -- right ground sensor @ (8 - 0.0625, 12 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just below the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just below the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 12 + 0.0625))  -- right ground sensor @ (8, 12 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if left sensor is in the air on the left of the tile and right sensor is just inside the top of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 12 + 0.0625))  -- left ground sensor @ (8 - 0.0625, 12 + 0.0625), right ground sensor @ (13 - 0.0625, 12 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if both sensors are just inside the top of tile, with left sensor just inside the top of the topleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 12 + 0.0625))  -- left ground sensor @ (8, 12 + 0.0625), right ground sensor @ (13, 12 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if both sensors are just inside the top of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 12 + 0.0625))  -- left ground sensor @ (9.5, 12 + 0.0625), right ground sensor @ (14.5, 12 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if both sensors are just inside the top of tile and right sensor just inside the top of the topright-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 12 + 0.0625))  -- left ground sensor @ (11 - 0.0625, 12 + 0.0625), right ground sensor @ (16 - 0.0625, 12 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if left sensor is just inside the top of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 12 + 0.0625))  -- left ground sensor @ (11, 12 + 0.0625), right ground sensor @ (16, 8)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if left sensor is just inside the top of the topright-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 12 + 0.0625))  -- left ground sensor @ (15.5, 12 + 0.0625), right ground sensor @ (20.5, 8)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0.0625 if left sensor is just inside the top of the topright-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 12 + 0.0625))  -- left ground sensor @ (16 - 0.0625, 12 + 0.0625), right ground sensor @ (21 - 0.0625, 12 + 0.0625)
            assert.are_equal(0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just below the ground\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 12 + 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 12 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(19, 12 + 0.0625))  -- left ground sensor @ (16.5, 12 + 0.0625), right ground sensor @ (21.5, 12 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if both sensors are completely in the air on the right of the tile, just below the ground\'s height', function ()
            player_char:set_bottom_center(vector(20, 12 + 0.0625))  -- left ground sensor @ (17.5, 12 + 0.0625), right ground sensor @ (22.5, 12 + 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          -- just inside the bottom

          it('should return -1 if both sensors are completely in the air on the left of the tile, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(4, 16 - 0.0625))  -- right ground sensor @ (6.5, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('R should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.5px away from it, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(5, 16 - 0.0625))  -- right ground sensor @ (7.5, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('R should return -1 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just touching the left of the tile, with right ground sensor 0.0625px away from it, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(5.5 - 0.0625, 16 - 0.0625))  -- right ground sensor @ (8 - 0.0625, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('R should return 4 - 0.0625 if left sensor is in the air on the left of the tile and pixel-perfect right sensor is just above the bottom of the bottomleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just above the bottom\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(5.5, 16 - 0.0625))  -- right ground sensor @ (8, 16 - 0.0625)
            assert.are_equal(4 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 4 - 0.0625 if left sensor is in the air on the left of the tile and right sensor is just inside the bottom of tile, with left sensor touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
            player_char:set_bottom_center(vector(10.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (8 - 0.0625, 16 - 0.0625), right ground sensor @ (13 - 0.0625, 16 - 0.0625)
            assert.are_equal(4 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 4 - 0.0625 if both sensors are just inside the bottom of tile, with left sensor just inside the bottom of the bottomleft-most pixel', function ()
            player_char:set_bottom_center(vector(10.5, 16 - 0.0625))  -- left ground sensor @ (8, 16 - 0.0625), right ground sensor @ (13, 16 - 0.0625)
            assert.are_equal(4 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 4 - 0.0625 if both sensors are just inside the bottom of tile, in the middle', function ()
            player_char:set_bottom_center(vector(12, 16 - 0.0625))  -- left ground sensor @ (9.5, 16 - 0.0625), right ground sensor @ (14.5, 16 - 0.0625)
            assert.are_equal(4 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 4 - 0.0625 if both sensors are just inside the bottom of tile and right sensor just inside the bottom of the bottomright-most pixel', function ()
            player_char:set_bottom_center(vector(13.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (11 - 0.0625, 16 - 0.0625), right ground sensor @ (16 - 0.0625, 16 - 0.0625)
            assert.are_equal(4 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 4 - 0.0625 if left sensor is just inside the bottom of tile and right sensor is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
            player_char:set_bottom_center(vector(13.5, 16 - 0.0625))  -- left ground sensor @ (11, 16 - 0.0625), right ground sensor @ (16, 8)
            assert.are_equal(4 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 4 - 0.0625 if left sensor is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.5px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18, 16 - 0.0625))  -- left ground sensor @ (15.5, 16 - 0.0625), right ground sensor @ (20.5, 8)
            assert.are_equal(4 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('should return 4 - 0.0625 if left sensor is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.0625px away from the border, and right sensor is in the air', function ()
            player_char:set_bottom_center(vector(18.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (16 - 0.0625, 16 - 0.0625), right ground sensor @ (21 - 0.0625, 16 - 0.0625)
            assert.are_equal(4 - 0.0625, player_char:_compute_ground_penetration_height())
          end)

          it('R should return -1 if left sensor is just touching the right of the tile, with left ground sensor exactly on it, and right sensor is in the air, just above the bottom\'s height (rounding to upper integer at .5)', function ()
            player_char:set_bottom_center(vector(18.5, 16 - 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if left sensor is just touching the right of the tile, with left ground sensor 0.5px away from it, and right sensor is in the air, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(19, 16 - 0.0625))  -- left ground sensor @ (16.5, 16 - 0.0625), right ground sensor @ (21.5, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return -1 if both sensors are completely in the air on the right of the tile, just above the bottom\'s height', function ()
            player_char:set_bottom_center(vector(20, 16 - 0.0625))  -- left ground sensor @ (17.5, 16 - 0.0625), right ground sensor @ (22.5, 16 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          -- just at the bottom, so character is inside tile but sensors above air

          it('should return -1 if both sensors are just at the bottom of the tile, above air', function ()
            player_char:set_bottom_center(vector(12, 16))
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

        end)

        describe('with ascending slope 45', function ()

          before_each(function ()
            -- create an ascending slope at (1, 1), i.e. (8, 15) to (15, 8) px
            mset(1, 1, 65)
          end)

          -- right sensor at column 0, left sensor in the air

          it('should return -1 if right sensor is just above slope column 0', function ()
            player_char:set_bottom_center(vector(6, 15 - 0.0625))  -- right ground sensor @ (8.5, 15 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if right sensor is at the top of column 0', function ()
            player_char:set_bottom_center(vector(6, 15))  -- right ground sensor @ (8.5, 15)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          -- right sensor at column 4, left sensor in the air

          it('. should return -1 if right sensor is just above slope column 4', function ()
            player_char:set_bottom_center(vector(10, 11 - 0.0625))  -- right ground sensor @ (12.5, 11 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('. should return 0 if right sensor is at the top of column 4', function ()
            player_char:set_bottom_center(vector(10, 11))  -- right ground sensor @ (12.5, 11)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 2 if right sensor is below column 4 by 2px', function ()
            player_char:set_bottom_center(vector(10, 13))  -- right ground sensor @ (12.5, 13)
            assert.are_equal(2, player_char:_compute_ground_penetration_height())
          end)

          -- right sensor at column 7, left sensor at column 5

          it('should return -1 if right sensor is just above slope column 0', function ()
            player_char:set_bottom_center(vector(18, 8 - 0.0625))  -- right ground sensor @ (15.5, 8 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if right sensor is at the top of column 0', function ()
            player_char:set_bottom_center(vector(18, 8))  -- right ground sensor @ (15.5, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 3 if right sensor is below column 0 by 3px', function ()
            player_char:set_bottom_center(vector(18, 11))  -- right ground sensor @ (15.5, 11)
            assert.are_equal(3, player_char:_compute_ground_penetration_height())
          end)

          -- left sensor at column 3, right sensor in the air (just behind column 7)

          it('. should return -1 if left sensor is just above slope column 3 (this is a known bug mentioned in Sonic Physics Guide: when Sonic reaches the top of a slope/hill, he goes down again due to the lack of mid-leg sensor)', function ()
            player_char:set_bottom_center(vector(14, 12 - 0.0625))  -- left ground sensor @ (11.5, 12 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('. should return 0 if left sensor is at the top of column 3', function ()
            player_char:set_bottom_center(vector(14, 12))  -- left ground sensor @ (11.5, 12)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

        end)

        describe('with descending slope 45', function ()

          before_each(function ()
            -- create a descending slope at (1, 1), i.e. (8, 8) to (15, 15) px
            mset(1, 1, 66)
          end)

          -- right sensor at column 0

          it('. should return -1 if right sensors are just a little above column 0', function ()
            player_char:set_bottom_center(vector(6, 8 - 0.0625))  -- right ground sensor @ (8.5, 8 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if right sensors is at the top of column 0', function ()
            player_char:set_bottom_center(vector(6, 8))  -- right ground sensor @ (8.5, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 1 if right sensors is below column 0 by 1px', function ()
            player_char:set_bottom_center(vector(6, 9))  -- right ground sensor @ (8.5, 9)
            assert.are_equal(1, player_char:_compute_ground_penetration_height())
          end)

          -- right sensor at column 1, bottom segment over column 0

          it('should return -1 if right sensor is 1px above slope column 1 (this is a known bug mentioned in Sonic Physics Guide: when Sonic reaches the top of a slope/hill, he goes down again due to the lack of mid-leg sensor)', function ()
            player_char:set_bottom_center(vector(7, 8))  -- right ground sensor @ (9.5, 8)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if right sensor is at the top of column 1', function ()
            player_char:set_bottom_center(vector(7, 9))  -- right ground sensor @ (9.5, 9)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 2 if right sensor is below column 1 by 2px', function ()
            player_char:set_bottom_center(vector(7, 11))  -- right ground sensor @ (9.5, 11)
            assert.are_equal(2, player_char:_compute_ground_penetration_height())
          end)

          -- left sensor at column 0, right sensor at column 5

          it('should return -1 if left sensor is just above slope column 0', function ()
            player_char:set_bottom_center(vector(11, 8 - 0.0625))  -- left ground sensor @ (8.5, 8 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is at the top of column 0', function ()
            player_char:set_bottom_center(vector(11, 8))  -- left ground sensor @ (8.5, 8)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 3 if left sensor is below column 0 by 3px', function ()
            player_char:set_bottom_center(vector(11, 11))  -- left ground sensor @ (8.5, 11)
            assert.are_equal(3, player_char:_compute_ground_penetration_height())
          end)

          -- left sensor at column 3, right sensor in the air

          it('. should return -1 if left sensor is just above slope column 3', function ()
            player_char:set_bottom_center(vector(14, 11 - 0.0625))  -- left ground sensor @ (11.5, 5 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('. should return 0 if left sensor is at the top of column 3', function ()
            player_char:set_bottom_center(vector(14, 11))  -- left ground sensor @ (11.5, 11)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

          it('should return 4 if left sensor is below column 3 by 4px', function ()
            player_char:set_bottom_center(vector(14, 15))  -- left ground sensor @ (11.5, 15)
            assert.are_equal(4, player_char:_compute_ground_penetration_height())
          end)

          -- left sensor at column 7, right sensor in the air

          it('should return -1 if left sensor is just above slope column 7', function ()
            player_char:set_bottom_center(vector(18, 15 - 0.0625))  -- left ground sensor @ (15.5, 15 - 0.0625)
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return 0 if left sensor is at the top of column 7', function ()
            player_char:set_bottom_center(vector(18, 15))  -- left ground sensor @ (15.5, 15)
            assert.are_equal(0, player_char:_compute_ground_penetration_height())
          end)

        end)

        describe('with ascending slope 22.5 offset by 2', function ()

          before_each(function ()
            -- create an ascending slope 22.5 at (1, 1), i.e. (8, 14) to (15, 11) px
            mset(1, 1, 67)
          end)

          it('should return 4 if left sensor is below column 1 by 1px and right sensor is below column 7 by 4px)', function ()
            player_char:set_bottom_center(vector(12, 15))  -- left ground sensor @ (8 + 1.5, 16 - 1), right ground sensor @ (8 + 6.5, 16 - 1)
            assert.are_equal(4, player_char:_compute_ground_penetration_height())
          end)

        end)

        describe('with quarter-tile', function ()

          before_each(function ()
            -- create a quarter-tile at (1, 1), i.e. (12, 12) to (15, 15) px
            mset(1, 1, 71)
          end)

          it('should return -1 if right sensor is just at the bottom of the tile, on the left part, so in the air (and not 0 just because it is at height 0)', function ()
            player_char:set_bottom_center(vector(9, 16))  -- right ground sensor @ (11.5, 16)
            -- note that it works not because we check for a column mask height of 0 manually, but because if the sensor reaches the bottom of the tile it automatically checks for the tile below
            assert.are_equal(-1, player_char:_compute_ground_penetration_height())
          end)

          it('should return 2 if right sensor is below tile by 2px, left sensor in the air (still in the whole tile, but above column height 0)', function ()
            player_char:set_bottom_center(vector(12, 14))  -- right ground sensor @ (14.5, 14)
            assert.are_equal(2, player_char:_compute_ground_penetration_height())
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

          it('should return 4 if left and right sensors are below top by 4px, with character crossing 2 tiles', function ()
            player_char:set_bottom_center(vector(12, 18))

            -- interface
            assert.are_equal(4, player_char:_compute_ground_penetration_height())
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
            assert.are_equal(16, player_char:_compute_stacked_column_height_above(location(0, 2), 4))
          end)

        end)

        describe('with full flat tile + quarter-tile', function ()

          before_each(function ()
            mset(0, 0, 71)  -- bottom-left quarter-tile
            mset(0, 1, 64)  -- full tile
          end)

          it('should return 8 above tile (0, 2) for column index 0, 1, 2, 3', function ()
            assert.are_equal(8, player_char:_compute_stacked_column_height_above(location(0, 2), 3))
          end)

          it('should return 12 above tile (0, 2) for column index 4, 5, 6, 7', function ()
            assert.are_equal(12, player_char:_compute_stacked_column_height_above(location(0, 2), 4))
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

      describe('_intersects_with_ground', function ()

        local compute_ground_penetration_mock

        after_each(function ()
          compute_ground_penetration_mock:revert()
        end)

        it('should return true when _compute_ground_penetration_height returns a number >= 0', function ()
          compute_ground_penetration_mock = stub(player_char, "_compute_ground_penetration_height", function (self)
            return 5
          end)
          assert.is_true(player_char:_intersects_with_ground())
        end)

        it('should return false when _compute_ground_penetration_height returns a number < 0', function ()
          compute_ground_penetration_mock = stub(player_char, "_compute_ground_penetration_height", function (self)
            return -2
          end)
          assert.is_false(player_char:_intersects_with_ground())
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
            player_char:_check_escape_from_ground()

            -- interface
            assert.are_equal(vector(12, 6), player_char:get_bottom_center())
          end)

          it('should do nothing when character is just on top of the ground', function ()
            player_char:set_bottom_center(vector(12, 8))
            player_char:_check_escape_from_ground()

            -- interface
            assert.are_equal(vector(12, 8), player_char:get_bottom_center())
          end)

          it('should move the character upward just enough to escape ground if character is inside ground', function ()
            player_char:set_bottom_center(vector(12, 9))
            player_char:_check_escape_from_ground()

            -- interface
            assert.are_equal(vector(12, 8), player_char:get_bottom_center())
          end)

          it('should do nothing when character is too deep inside the ground', function ()
            player_char:set_bottom_center(vector(12, 13))
            player_char:_check_escape_from_ground()

            -- interface
            assert.are_equal(vector(12, 13), player_char:get_bottom_center())
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

        -- TODO: low slope to check both feet inside ground
        -- but not too deep either

        -- TODO: (also for compute penetration_height function)
        -- if character is inside 2 tiles with a total height < 5, he must escape
        -- by raising through both tiles (imagine 1 bottom tile of height 2)
        -- (and below the character is inside of 2)

      end)  -- _check_escape_from_ground

    end)  -- (with mock tiles data setup)

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

        it('. should enter grounded state and reset speed y if some ground is sensed', function ()
          player_char:_update_platformer_motion_state(true)
          assert.are_same({motion_states.grounded, 0}, {player_char.motion_state, player_char.speed_y_per_frame})
        end)

      end)

    end)

    describe('_update_platformer_motion', function ()

      local update_platformer_motion_grounded_stub
      local update_platformer_motion_airborne_stub

      setup(function ()
        update_platformer_motion_grounded_stub = stub(player_character, "_update_platformer_motion_grounded")
        update_platformer_motion_airborne_stub = stub(player_character, "_update_platformer_motion_airborne")
      end)

      teardown(function ()
        update_platformer_motion_grounded_stub:revert()
        update_platformer_motion_airborne_stub:revert()
      end)

      after_each(function ()
        update_platformer_motion_grounded_stub:clear()
        update_platformer_motion_airborne_stub:clear()
      end)

      describe('(when character is grounded)', function ()

        it('^ should call _update_platformer_motion_grounded', function ()
          player_char:_update_platformer_motion()
          assert.spy(update_platformer_motion_grounded_stub).was_called()
          assert.spy(update_platformer_motion_grounded_stub).was_called_with(match.ref(player_char))
          assert.spy(update_platformer_motion_airborne_stub).was_not_called()
        end)

      end)

      describe('(when character is airborne)', function ()

        before_each(function ()
          player_char.motion_state = motion_states.airborne
        end)

        it('^ should call _update_platformer_motion_airborne', function ()
          player_char:_update_platformer_motion()
          assert.spy(update_platformer_motion_airborne_stub).was_called()
          assert.spy(update_platformer_motion_airborne_stub).was_called_with(match.ref(player_char))
          assert.spy(update_platformer_motion_grounded_stub).was_not_called()
        end)

      end)

    end)

    describe('_update_platformer_motion_grounded', function ()

      pending('should ...', function ()
        player_char:_update_platformer_motion_grounded()
      end)

    end)

    describe('_update_platformer_motion_airborne', function ()

      it('. should apply gravity to speed y', function ()
        assert.are_equal(0, player_char.speed_y_per_frame)
        player_char:_update_platformer_motion_airborne()
        assert.are_equal(playercharacter_data.gravity_per_frame2, player_char.speed_y_per_frame)
      end)

      it('. should update position with new speed y', function ()
        player_char:_update_platformer_motion_airborne()
        assert.are_equal(vector(4, -4 + playercharacter_data.gravity_per_frame2), player_char.position)
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
        assert.spy(update_velocity_debug_mock).was_called()
        assert.spy(update_velocity_debug_mock).was_called_with(match.ref(player_char))
        assert.spy(move_stub).was_called()
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

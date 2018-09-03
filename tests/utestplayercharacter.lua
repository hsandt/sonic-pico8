require("bustedhelper")
require("game/ingame/playercharacter")
require("engine/core/math")
local collision = require("engine/physics/collision")
local collision_data = require("game/data/collision_data")

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
      assert.are_same({vector.zero(), vector.zero()},
        {player_character.velocity, player_character.move_intention})
    end)

    it('should create a player character with control mode: human and motion mode: platformer', function ()
      local player_character = player_character(vector(4, -4))
      assert.is_not_nil(player_character)
      assert.are_same({control_modes.human, motion_modes.platformer},
        {player_character.control_mode, player_character.motion_mode})
    end)

  end)

  describe('(with player character at (4, -4), speed 60, debug accel 480)', function ()
    local player_char

    setup(function ()
      player_char = player_character(vector(4, -4))
      player_char.debug_move_max_speed = 60.
      player_char.debug_move_accel = 480.
      player_char.debug_move_decel = 480.
    end)

    after_each(function ()
      player_char.control_mode = control_modes.human
      player_char.motion_mode = motion_modes.platformer
      player_char.position = vector(4, -4)
      player_char.velocity = vector(0, 0)
      player_char.move_intention = vector(0, 0)
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

    describe('+ set_bottom_center', function ()
      it('set_bottom_center (10 6) => at (10 3)', function ()
        player_char:set_bottom_center(vector(10, 6))
        assert.are_equal(vector(10, 3), player_char.position)
      end)
    end)

    describe('_update', function ()

      setup(function ()
        update_velocity_mock = stub(player_char, "_update_velocity", function (self)
          self.velocity = 11
        end)
        move_stub = stub(player_char, "move")
      end)

      teardown(function ()
        update_velocity_mock:revert()
        move_stub:revert()
      end)

      it('should call _update_velocity, then move using the new velocity', function ()
        player_char:update()
        assert.spy(update_velocity_mock).was_called()
        assert.spy(update_velocity_mock).was_called_with(match.ref(player_char))
        assert.spy(move_stub).was_called()
        assert.spy(move_stub).was_called_with(match.ref(player_char), 11 * delta_time)
      end)

    end)

    describe('_update_velocity', function ()

      local update_velocity_platformer_stub
      local update_velocity_debug_stub

      setup(function ()
        update_velocity_platformer_stub = stub(player_char, "_update_velocity_platformer")  -- native print
        update_velocity_debug_stub = stub(player_char, "_update_velocity_debug")  -- native print
      end)

      teardown(function ()
        update_velocity_platformer_stub:revert()
        update_velocity_debug_stub:revert()
      end)

      it('should call _update_velocity_platformer', function ()
        player_char:_update_velocity()
        assert.spy(update_velocity_platformer_stub).was_called()
        assert.spy(update_velocity_platformer_stub).was_called_with(match.ref(player_char))
      end)

      it('should call _update_velocity_debug', function ()
        player_char.motion_mode = motion_modes.debug
        player_char:_update_velocity()
        assert.spy(update_velocity_debug_stub).was_called()
        assert.spy(update_velocity_debug_stub).was_called_with(match.ref(player_char))
      end)

    end)

    describe('_update_velocity_platformer', function ()

      pending('should ...', function ()
        player_char:_update_velocity_platformer()
      end)

    end)

    describe('_sense_ground', function ()

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
        fset(70, sprite_flags.collision, true)  -- half-tile (bottom half)
        fset(71, sprite_flags.collision, true)  -- quarter-tile (bottom-right half)

        -- mock height array _init so it doesn't have to dig in sprite data, inaccessible from busted
        height_array_init_mock = stub(collision.height_array, "_init", function (self, tile_mask_id_location, slope_angle)
          if tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[64] then
            self._array = {8, 8, 8, 8, 8, 8, 8, 8}  -- full tile
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[65] then
            self._array = {1, 2, 3, 4, 5, 6, 7, 8}  -- ascending slope 45
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[66] then
            self._array = {8, 7, 6, 5, 4, 3, 2, 1}  -- descending slope 45
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[70] then
            self._array = {4, 4, 4, 4, 4, 4, 4, 4}  -- half-tile (bottom half)
          elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[71] then
            self._array = {0, 0, 0, 0, 4, 4, 4, 4}  -- half-tile (bottom half)
          end
          self._slope_angle = slope_angle
        end)
      end)

      teardown(function ()
        fset(64, sprite_flags.collision, false)
        fset(65, sprite_flags.collision, false)
        fset(66, sprite_flags.collision, false)
        fset(70, sprite_flags.collision, false)
        fset(71, sprite_flags.collision, false)

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

      describe('with full flat tile', function ()

        before_each(function ()
          -- create a full tile at (1, 1), i.e. (8, 8) to (15, 15) px
          mset(1, 1, 64)
        end)

        -- just above

        it('should return false if both feet are just a little above the tile', function ()
          player_char:set_bottom_center(vector(12, 8 - 0.0625))
          assert.is_false(player_char:_sense_ground())
        end)

        -- on top

        it('should return false if both feet are completely in the air on the left of the tile, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(4, 8))  -- right ground sensor @ (6.5, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('+ should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.5px away from it, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(5, 8))  -- right ground sensor @ (7.5, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('+ should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.0625px away from it, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(5.5 - 0.0625, 8))  -- right ground sensor @ (8 - 0.0625, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('+ should return true if left foot is in the air on the left of the tile and pixel-perfect right foot is just at the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just at the ground\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(5.5, 8))  -- right ground sensor @ (8, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is in the air on the left of the tile and right foot is at the top of tile, with left foot touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
          player_char:set_bottom_center(vector(10.5 - 0.0625, 8))  -- left ground sensor @ (8 - 0.0625, 8), right ground sensor @ (13 - 0.0625, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just at the top of tile, with left foot just at the top of the topleft-most pixel', function ()
          player_char:set_bottom_center(vector(10.5, 8))  -- left ground sensor @ (8, 8), right ground sensor @ (13, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just at the top of tile, in the middle', function ()
          player_char:set_bottom_center(vector(12, 8))  -- left ground sensor @ (9.5, 8), right ground sensor @ (14.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just at the top of tile and right foot just at the top of the right-most pixel', function ()
          player_char:set_bottom_center(vector(13.5 - 0.0625, 8))  -- left ground sensor @ (11 - 0.0625, 8), right ground sensor @ (16 - 0.0625, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is at the top of tile and right foot is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
          player_char:set_bottom_center(vector(13.5, 8))  -- left ground sensor @ (11, 8), right ground sensor @ (16, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just at the top of the right-most pixel, with left ground sensor 0.5px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18, 8))  -- left ground sensor @ (15.5, 8), right ground sensor @ (20.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just at the top of the right-most pixel, with left ground sensor 0.0625px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18.5 - 0.0625, 8))  -- left ground sensor @ (16 - 0.0625, 8), right ground sensor @ (21 - 0.0625, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('+ should return false if left foot is just touching the right of the tile, with left ground sensor exactly on it, and right foot is in the air, just at the ground\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(18.5, 8))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is just touching the right of the tile, with left ground sensor 0.5px away from it, and right foot is in the air, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(19, 8))  -- left ground sensor @ (16.5, 8), right ground sensor @ (21.5, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if both feet are completely in the air on the right of the tile, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(20, 8))  -- left ground sensor @ (17.5, 8), right ground sensor @ (22.5, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        -- just inside the top

        it('should return false if both feet are completely in the air on the left of the tile, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(4, 8 + 0.0625))  -- right ground sensor @ (6.5, 8 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('R should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.5px away from it, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(5, 8 + 0.0625))  -- right ground sensor @ (7.5, 8 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('R should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.0625px away from it, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(5.5 - 0.0625, 8 + 0.0625))  -- right ground sensor @ (8 - 0.0625, 8 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('R should return true if left foot is in the air on the left of the tile and pixel-perfect right foot is just below the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just below the ground\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(5.5, 8 + 0.0625))  -- right ground sensor @ (8, 8 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is in the air on the left of the tile and right foot is just inside the top of tile, with left foot touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
          player_char:set_bottom_center(vector(10.5 - 0.0625, 8 + 0.0625))  -- left ground sensor @ (8 - 0.0625, 8 + 0.0625), right ground sensor @ (13 - 0.0625, 8 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the top of tile, with left foot just inside the top of the topleft-most pixel', function ()
          player_char:set_bottom_center(vector(10.5, 8 + 0.0625))  -- left ground sensor @ (8, 8 + 0.0625), right ground sensor @ (13, 8 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the top of tile, in the middle', function ()
          player_char:set_bottom_center(vector(12, 8 + 0.0625))  -- left ground sensor @ (9.5, 8 + 0.0625), right ground sensor @ (14.5, 8 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the top of tile and right foot just inside the top of the topright-most pixel', function ()
          player_char:set_bottom_center(vector(13.5 - 0.0625, 8 + 0.0625))  -- left ground sensor @ (11 - 0.0625, 8 + 0.0625), right ground sensor @ (16 - 0.0625, 8 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the top of tile and right foot is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
          player_char:set_bottom_center(vector(13.5, 8 + 0.0625))  -- left ground sensor @ (11, 8 + 0.0625), right ground sensor @ (16, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the top of the topright-most pixel, with left ground sensor 0.5px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18, 8 + 0.0625))  -- left ground sensor @ (15.5, 8 + 0.0625), right ground sensor @ (20.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the top of the topright-most pixel, with left ground sensor 0.0625px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18.5 - 0.0625, 8 + 0.0625))  -- left ground sensor @ (16 - 0.0625, 8 + 0.0625), right ground sensor @ (21 - 0.0625, 8 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('R should return false if left foot is just touching the right of the tile, with left ground sensor exactly on it, and right foot is in the air, just below the ground\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(18.5, 8 + 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 8 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is just touching the right of the tile, with left ground sensor 0.5px away from it, and right foot is in the air, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(19, 8 + 0.0625))  -- left ground sensor @ (16.5, 8 + 0.0625), right ground sensor @ (21.5, 8 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if both feet are completely in the air on the right of the tile, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(20, 8 + 0.0625))  -- left ground sensor @ (17.5, 8 + 0.0625), right ground sensor @ (22.5, 8 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        -- just inside the bottom

        it('should return false if both feet are completely in the air on the left of the tile, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(4, 16 - 0.0625))  -- right ground sensor @ (6.5, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('R should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.5px away from it, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(5, 16 - 0.0625))  -- right ground sensor @ (7.5, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('R should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.0625px away from it, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(5.5 - 0.0625, 16 - 0.0625))  -- right ground sensor @ (8 - 0.0625, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('R should return true if left foot is in the air on the left of the tile and pixel-perfect right foot is just above the bottom of the bottomleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just above the bottom\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(5.5, 16 - 0.0625))  -- right ground sensor @ (8, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is in the air on the left of the tile and right foot is just inside the bottom of tile, with left foot touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
          player_char:set_bottom_center(vector(10.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (8 - 0.0625, 16 - 0.0625), right ground sensor @ (13 - 0.0625, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the bottom of tile, with left foot just inside the bottom of the bottomleft-most pixel', function ()
          player_char:set_bottom_center(vector(10.5, 16 - 0.0625))  -- left ground sensor @ (8, 16 - 0.0625), right ground sensor @ (13, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the bottom of tile, in the middle', function ()
          player_char:set_bottom_center(vector(12, 16 - 0.0625))  -- left ground sensor @ (9.5, 16 - 0.0625), right ground sensor @ (14.5, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the bottom of tile and right foot just inside the bottom of the bottomright-most pixel', function ()
          player_char:set_bottom_center(vector(13.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (11 - 0.0625, 16 - 0.0625), right ground sensor @ (16 - 0.0625, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the bottom of tile and right foot is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
          player_char:set_bottom_center(vector(13.5, 16 - 0.0625))  -- left ground sensor @ (11, 16 - 0.0625), right ground sensor @ (16, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.5px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18, 16 - 0.0625))  -- left ground sensor @ (15.5, 16 - 0.0625), right ground sensor @ (20.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.0625px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (16 - 0.0625, 16 - 0.0625), right ground sensor @ (21 - 0.0625, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('R should return false if left foot is just touching the right of the tile, with left ground sensor exactly on it, and right foot is in the air, just above the bottom\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(18.5, 16 - 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is just touching the right of the tile, with left ground sensor 0.5px away from it, and right foot is in the air, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(19, 16 - 0.0625))  -- left ground sensor @ (16.5, 16 - 0.0625), right ground sensor @ (21.5, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if both feet are completely in the air on the right of the tile, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(20, 16 - 0.0625))  -- left ground sensor @ (17.5, 16 - 0.0625), right ground sensor @ (22.5, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        -- just at the bottom, so character is inside tile but feet above air

        it('should return false if both feet are just at the bottom of the tile, above air', function ()
          player_char:set_bottom_center(vector(12, 16))
          assert.is_false(player_char:_sense_ground())
        end)

      end)

      describe('with half flat tile', function ()

        before_each(function ()
          -- create a half-tile at (0, 1), top-left at (0, 12), top-right at (7, 12) included
          mset(1, 1, 70)
        end)

        -- just above

        it('should return false if both feet are just a little above the tile', function ()
          player_char:set_bottom_center(vector(12, 12 - 0.0625))
          assert.is_false(player_char:_sense_ground())
        end)

        -- on top

        it('should return false if both feet are completely in the air on the left of the tile, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(4, 12))  -- right ground sensor @ (6.5, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.5px away from it, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(5, 12))  -- right ground sensor @ (7.5, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.0625px away from it, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(5.5 - 0.0625, 12))  -- right ground sensor @ (8 - 0.0625, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return true if left foot is in the air on the left of the tile and pixel-perfect right foot is just at the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just at the ground\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(5.5, 12))  -- right ground sensor @ (8, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is in the air on the left of the tile and right foot is at the top of tile, with left foot touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
          player_char:set_bottom_center(vector(10.5 - 0.0625, 12))  -- left ground sensor @ (8 - 0.0625, 8), right ground sensor @ (13 - 0.0625, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just at the top of tile, with left foot just at the top of the topleft-most pixel', function ()
          player_char:set_bottom_center(vector(10.5, 12))  -- left ground sensor @ (8, 8), right ground sensor @ (13, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just at the top of tile, in the middle', function ()
          player_char:set_bottom_center(vector(12, 12))  -- left ground sensor @ (9.5, 8), right ground sensor @ (14.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just at the top of tile and right foot just at the top of the right-most pixel', function ()
          player_char:set_bottom_center(vector(13.5 - 0.0625, 12))  -- left ground sensor @ (11 - 0.0625, 8), right ground sensor @ (16 - 0.0625, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is at the top of tile and right foot is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
          player_char:set_bottom_center(vector(13.5, 12))  -- left ground sensor @ (11, 8), right ground sensor @ (16, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just at the top of the right-most pixel, with left ground sensor 0.5px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18, 12))  -- left ground sensor @ (15.5, 8), right ground sensor @ (20.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just at the top of the right-most pixel, with left ground sensor 0.0625px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18.5 - 0.0625, 12))  -- left ground sensor @ (16 - 0.0625, 8), right ground sensor @ (21 - 0.0625, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return false if left foot is just touching the right of the tile, with left ground sensor exactly on it, and right foot is in the air, just at the ground\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(18.5, 12))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is just touching the right of the tile, with left ground sensor 0.5px away from it, and right foot is in the air, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(19, 12))  -- left ground sensor @ (16.5, 8), right ground sensor @ (21.5, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if both feet are completely in the air on the right of the tile, just at the ground\'s height', function ()
          player_char:set_bottom_center(vector(20, 12))  -- left ground sensor @ (17.5, 8), right ground sensor @ (22.5, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        -- just inside the top

        it('should return false if both feet are completely in the air on the left of the tile, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(4, 12 + 0.0625))  -- right ground sensor @ (6.5, 12 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.5px away from it, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(5, 12 + 0.0625))  -- right ground sensor @ (7.5, 12 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.0625px away from it, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(5.5 - 0.0625, 12 + 0.0625))  -- right ground sensor @ (8 - 0.0625, 12 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return true if left foot is in the air on the left of the tile and pixel-perfect right foot is just below the top of the topleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just below the ground\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(5.5, 12 + 0.0625))  -- right ground sensor @ (8, 12 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is in the air on the left of the tile and right foot is just inside the top of tile, with left foot touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
          player_char:set_bottom_center(vector(10.5 - 0.0625, 12 + 0.0625))  -- left ground sensor @ (8 - 0.0625, 12 + 0.0625), right ground sensor @ (13 - 0.0625, 12 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the top of tile, with left foot just inside the top of the topleft-most pixel', function ()
          player_char:set_bottom_center(vector(10.5, 12 + 0.0625))  -- left ground sensor @ (8, 12 + 0.0625), right ground sensor @ (13, 12 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the top of tile, in the middle', function ()
          player_char:set_bottom_center(vector(12, 12 + 0.0625))  -- left ground sensor @ (9.5, 12 + 0.0625), right ground sensor @ (14.5, 12 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the top of tile and right foot just inside the top of the topright-most pixel', function ()
          player_char:set_bottom_center(vector(13.5 - 0.0625, 12 + 0.0625))  -- left ground sensor @ (11 - 0.0625, 12 + 0.0625), right ground sensor @ (16 - 0.0625, 12 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the top of tile and right foot is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
          player_char:set_bottom_center(vector(13.5, 12 + 0.0625))  -- left ground sensor @ (11, 12 + 0.0625), right ground sensor @ (16, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the top of the topright-most pixel, with left ground sensor 0.5px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18, 12 + 0.0625))  -- left ground sensor @ (15.5, 12 + 0.0625), right ground sensor @ (20.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the top of the topright-most pixel, with left ground sensor 0.0625px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18.5 - 0.0625, 12 + 0.0625))  -- left ground sensor @ (16 - 0.0625, 12 + 0.0625), right ground sensor @ (21 - 0.0625, 12 + 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return false if left foot is just touching the right of the tile, with left ground sensor exactly on it, and right foot is in the air, just below the ground\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(18.5, 12 + 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 12 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is just touching the right of the tile, with left ground sensor 0.5px away from it, and right foot is in the air, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(19, 12 + 0.0625))  -- left ground sensor @ (16.5, 12 + 0.0625), right ground sensor @ (21.5, 12 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if both feet are completely in the air on the right of the tile, just below the ground\'s height', function ()
          player_char:set_bottom_center(vector(20, 12 + 0.0625))  -- left ground sensor @ (17.5, 12 + 0.0625), right ground sensor @ (22.5, 12 + 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        -- just inside the bottom

        it('should return false if both feet are completely in the air on the left of the tile, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(4, 16 - 0.0625))  -- right ground sensor @ (6.5, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('R should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.5px away from it, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(5, 16 - 0.0625))  -- right ground sensor @ (7.5, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('R should return false if left foot is in the air on the left of the tile and pixel-perfect right foot is just touching the left of the tile, with right ground sensor 0.0625px away from it, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(5.5 - 0.0625, 16 - 0.0625))  -- right ground sensor @ (8 - 0.0625, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('R should return true if left foot is in the air on the left of the tile and pixel-perfect right foot is just above the bottom of the bottomleft-most pixel of the tile, with right ground sensor exactly on the left of the tile, just above the bottom\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(5.5, 16 - 0.0625))  -- right ground sensor @ (8, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is in the air on the left of the tile and right foot is just inside the bottom of tile, with left foot touching the left of the tile, with left ground sensor 0.0625px away from it', function ()
          player_char:set_bottom_center(vector(10.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (8 - 0.0625, 16 - 0.0625), right ground sensor @ (13 - 0.0625, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the bottom of tile, with left foot just inside the bottom of the bottomleft-most pixel', function ()
          player_char:set_bottom_center(vector(10.5, 16 - 0.0625))  -- left ground sensor @ (8, 16 - 0.0625), right ground sensor @ (13, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the bottom of tile, in the middle', function ()
          player_char:set_bottom_center(vector(12, 16 - 0.0625))  -- left ground sensor @ (9.5, 16 - 0.0625), right ground sensor @ (14.5, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if both feet are just inside the bottom of tile and right foot just inside the bottom of the bottomright-most pixel', function ()
          player_char:set_bottom_center(vector(13.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (11 - 0.0625, 16 - 0.0625), right ground sensor @ (16 - 0.0625, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the bottom of tile and right foot is just touching the right of the tile, with right ground sensor exactly on the right of the tile (rounding to upper integer at .5, but doesn\'t affect final result)', function ()
          player_char:set_bottom_center(vector(13.5, 16 - 0.0625))  -- left ground sensor @ (11, 16 - 0.0625), right ground sensor @ (16, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.5px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18, 16 - 0.0625))  -- left ground sensor @ (15.5, 16 - 0.0625), right ground sensor @ (20.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        it('should return true if left foot is just inside the bottom of the bottomright-most pixel, with left ground sensor 0.0625px away from the border, and right foot is in the air', function ()
          player_char:set_bottom_center(vector(18.5 - 0.0625, 16 - 0.0625))  -- left ground sensor @ (16 - 0.0625, 16 - 0.0625), right ground sensor @ (21 - 0.0625, 16 - 0.0625)
          assert.is_true(player_char:_sense_ground())
        end)

        it('R should return false if left foot is just touching the right of the tile, with left ground sensor exactly on it, and right foot is in the air, just above the bottom\'s height (rounding to upper integer at .5)', function ()
          player_char:set_bottom_center(vector(18.5, 16 - 0.0625))  -- left ground sensor @ (16, 8), right ground sensor @ (21, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if left foot is just touching the right of the tile, with left ground sensor 0.5px away from it, and right foot is in the air, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(19, 16 - 0.0625))  -- left ground sensor @ (16.5, 16 - 0.0625), right ground sensor @ (21.5, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return false if both feet are completely in the air on the right of the tile, just above the bottom\'s height', function ()
          player_char:set_bottom_center(vector(20, 16 - 0.0625))  -- left ground sensor @ (17.5, 16 - 0.0625), right ground sensor @ (22.5, 16 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        -- just at the bottom, so character is inside tile but feet above air

        it('should return false if both feet are just at the bottom of the tile, above air', function ()
          player_char:set_bottom_center(vector(12, 16))
          assert.is_false(player_char:_sense_ground())
        end)

      end)

      describe('with descending slope 45', function ()

        before_each(function ()
          -- create a descending slope at (1, 1), i.e. (8, 8) to (15, 15) px
          mset(1, 1, 66)
        end)

        -- right foot at column 0

        it('. should return false if right feet are just a little above column 0', function ()
          player_char:set_bottom_center(vector(6, 8 - 0.0625))  -- right ground sensor @ (8.5, 8 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return true if right feet is at the top of column 0', function ()
          player_char:set_bottom_center(vector(6, 8))  -- right ground sensor @ (8.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        -- right foot at column 1, bottom segment over column 0

        it('should return false if right foot is 1px above slope column 1 (this is a known bug mentioned in Sonic Physics Guide: when Sonic reaches the top of a slope/hill, he goes down again due to the lack of mid-leg sensor)', function ()
          player_char:set_bottom_center(vector(7, 8))  -- right ground sensor @ (9.5, 8)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return true if right foot is at the top of column 1', function ()
          player_char:set_bottom_center(vector(7, 9))  -- right ground sensor @ (9.5, 9)
          assert.is_true(player_char:_sense_ground())
        end)

        -- left foot at column 0, right foot at column 5

        it('should return false if left foot is just above slope column 0', function ()
          player_char:set_bottom_center(vector(11, 8 - 0.0625))  -- left ground sensor @ (8.5, 8 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return true if left foot is at the top of column 0', function ()
          player_char:set_bottom_center(vector(11, 8))  -- left ground sensor @ (8.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        -- left foot at column 3, right foot in the air

        it('. should return false if left foot is just above slope column 3', function ()
          player_char:set_bottom_center(vector(14, 11 - 0.0625))  -- left ground sensor @ (11.5, 5 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('. should return true if left foot is at the top of column 3', function ()
          player_char:set_bottom_center(vector(14, 11))  -- left ground sensor @ (11.5, 5)
          assert.is_true(player_char:_sense_ground())
        end)

        -- left foot at column 7, right foot in the air

        it('should return false if left foot is just above slope column 7', function ()
          player_char:set_bottom_center(vector(18, 15 - 0.0625))  -- left ground sensor @ (15.5, 15 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return true if left foot is at the top of column 7', function ()
          player_char:set_bottom_center(vector(18, 15))  -- left ground sensor @ (15.5, 15)
          assert.is_true(player_char:_sense_ground())
        end)

      end)

      describe('with ascending slope 45', function ()

        before_each(function ()
          -- create an ascending slope at (1, 1), i.e. (8, 15) to (15, 8) px
          mset(1, 1, 65)
        end)

        -- right foot at column 0, left foot in the air

        it('should return false if right foot is just above slope column 0', function ()
          player_char:set_bottom_center(vector(6, 15 - 0.0625))  -- right ground sensor @ (8.5, 15 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return true if right foot is at the top of column 0', function ()
          player_char:set_bottom_center(vector(6, 15))  -- right ground sensor @ (8.5, 15)
          assert.is_true(player_char:_sense_ground())
        end)

        -- right foot at column 4, left foot in the air

        it('. should return false if right foot is just above slope column 4', function ()
          player_char:set_bottom_center(vector(10, 11 - 0.0625))  -- right ground sensor @ (12.5, 11 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('. should return true if right foot is at the top of column 4', function ()
          player_char:set_bottom_center(vector(10, 11))  -- right ground sensor @ (12.5, 11)
          assert.is_true(player_char:_sense_ground())
        end)

        -- right foot at column 7, left foot at column 5

        it('should return false if right foot is just above slope column 0', function ()
          player_char:set_bottom_center(vector(18, 8 - 0.0625))  -- right ground sensor @ (15.5, 8 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('should return true if right foot is at the top of column 0', function ()
          player_char:set_bottom_center(vector(18, 8))  -- right ground sensor @ (15.5, 8)
          assert.is_true(player_char:_sense_ground())
        end)

        -- left foot at column 3, right foot in the air (just behind column 7)

        it('. should return false if left foot is just above slope column 3 (this is a known bug mentioned in Sonic Physics Guide: when Sonic reaches the top of a slope/hill, he goes down again due to the lack of mid-leg sensor)', function ()
          player_char:set_bottom_center(vector(14, 12 - 0.0625))  -- left ground sensor @ (11.5, 12 - 0.0625)
          assert.is_false(player_char:_sense_ground())
        end)

        it('. should return true if left foot is at the top of column 3', function ()
          player_char:set_bottom_center(vector(14, 12))  -- left ground sensor @ (11.5, 12)
          assert.is_true(player_char:_sense_ground())
        end)

      end)

    end)

    describe('_get_ground_sensor_position', function ()

      before_each(function ()
        player_char.position = vector(10, 10)
      end)

      it('* should return the position down-left of the character center when horizontal dir is left', function ()
        assert.are_equal(vector(7.5, 13), player_char:_get_ground_sensor_position(horizontal_directions.left))
      end)

      it('* should return the position down-left of the character center when horizontal dir is right', function ()
        assert.are_equal(vector(12.5, 13), player_char:_get_ground_sensor_position(horizontal_directions.right))
      end)

    end)


    describe('_update_velocity_debug', function ()

      local update_velocity_component_debug_stub

      setup(function ()
        update_velocity_component_debug_stub = stub(player_char, "_update_velocity_component_debug")  -- native print
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
          player_char.velocity))
        player_char:_update_velocity_component_debug("y")
        assert.is_true(almost_eq_with_message(
          vector(- player_char.debug_move_accel * delta_time, player_char.debug_move_accel * delta_time),
          player_char.velocity))
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
        player_char:move(player_char.velocity * delta_time)
        assert.is_true(almost_eq_with_message(vector(3.8667, -3.8667), player_char.position))
      end)

      it('when move intention is (-1, 1), update 11 frame => at (−2.73 2.73)', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector(-2.73, 2.73), player_char.position))
        assert.is_true(almost_eq_with_message(vector(-60, 60), player_char.velocity))  -- at max speed
      end)

      it('when move intention is (0, 0) after 11 frames, update 16 frames more => character should have decelerated', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        player_char.move_intention = vector.zero()
        for i=1,5 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector(-20, 20), player_char.velocity, 0.01))
      end)

      it('when move intention is (0, 0) after 11 frames, update 19 frames more => character should have stopped', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        player_char.move_intention = vector.zero()
        for i=1,8 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector.zero(), player_char.velocity))
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

require("engine/test/bustedhelper")
local world = require("platformer/world")

local tile_test_data = require("test_data/tile_test_data")

describe('world (with mock tiles data setup)', function ()

  setup(function ()
    tile_test_data.setup()
  end)

  teardown(function ()
    tile_test_data.teardown()
  end)

  after_each(function ()
    pico8:clear_map()
  end)

  describe('_compute_qcolumn_height_at', function ()

    it('should return (0, nil) if tile location is outside map area (any quadrant)', function ()
      assert.are_same({0, nil}, {world._compute_qcolumn_height_at(location(-1, 2), 0, directions.down)})
    end)

    it('should return (0, nil) if tile has collision flag unset (any quadrant)', function ()
      assert.are_same({0, nil}, {world._compute_qcolumn_height_at(location(1, 1), 0, directions.right)})
    end)

    describe('with invalid tile', function ()

      before_each(function ()
        -- create an invalid tile with a collision flag but no collision mask associated
        mock_mset(1, 1, 1)
      end)

      it('should assert if tile has collision flag set but no collision mask id associated (any quadrant)', function ()
        assert.has_error(function ()
          world._compute_qcolumn_height_at(location(1, 1), 0, directions.up)
        end,
        "collision_data.tiles_collision_data does not contain entry for sprite id: 1, yet it has the collision flag set")
      end)

    end)

    describe('with ascending slope 22.5 offset by 2', function ()

      before_each(function ()
        -- create an ascending slope 22.5 at (1, 1), i.e. (8, 14) to (15, 11) px
        mock_mset(1, 1, asc_slope_22_id)
      end)

      it('should return 3 on column 3 (quadrant down)', function ()
        assert.are_same({3, 22.5 / 360}, {world._compute_qcolumn_height_at(location(1, 1), 3, directions.down)})
      end)

      it('should return 3 on column 3 (quadrant up)', function ()
        assert.are_same({3, 22.5 / 360}, {world._compute_qcolumn_height_at(location(1, 1), 3, directions.up)})
      end)

      it('should return 3 on column 3 (quadrant right)', function ()
        assert.are_same({2, 22.5 / 360}, {world._compute_qcolumn_height_at(location(1, 1), 3, directions.right)})
      end)

      it('should return 3 on column 3 (quadrant left)', function ()
        assert.are_same({2, 22.5 / 360}, {world._compute_qcolumn_height_at(location(1, 1), 3, directions.left)})
      end)

    end)

    describe('with loop top-left tile', function ()

      before_each(function ()
        mock_mset(1, 1, loop_topleft)
      end)

      it('should return 5 on column 6 (quadrant down)', function ()
        assert.are_same({6, atan2(-4, 4)}, {world._compute_qcolumn_height_at(location(1, 1), 6, directions.down)})
      end)

      it('should return 5 on column 6 (quadrant up)', function ()
        assert.are_same({6, atan2(-4, 4)}, {world._compute_qcolumn_height_at(location(1, 1), 6, directions.up)})
      end)

      it('should return 5 on column 6 (quadrant right)', function ()
        assert.are_same({6, atan2(-4, 4)}, {world._compute_qcolumn_height_at(location(1, 1), 6, directions.right)})
      end)

      it('should return 5 on column 6 (quadrant left)', function ()
        assert.are_same({6, atan2(-4, 4)}, {world._compute_qcolumn_height_at(location(1, 1), 6, directions.left)})
      end)

    end)

  end)

  describe('get_pixel_collision_info', function ()

    describe('with full flat tile', function ()

      before_each(function ()
        -- create a full tile at (1, 1), i.e. (8, 8) to (15, 15) px
        mock_mset(1, 1, full_tile_id)
      end)

      it('should return {false, nil} on (7, 7)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(7, 7)})
      end)

      -- + asymmetrical coordinates showed that top and left were inverted
      it('should return {false, nil} on (7, 8)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(7, 8)})
      end)

      it('should return {false, nil} on (7, 15)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(7, 15)})
      end)

      it('should return {false, nil} on (7, 16)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(7, 16)})
      end)

      it('should return {false, nil} on (8, 7)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(8, 7)})
      end)

      -- + true case showed than sign was wrong in column_top calculation
      it('should return true on (8, 8)', function ()
        assert.are_same({true, 0}, {world.get_pixel_collision_info(8, 8)})
      end)

      it('should return true on (8, 9)', function ()
        assert.are_same({true, 0}, {world.get_pixel_collision_info(8, 9)})
      end)

      it('should return true on (8, 15)', function ()
        assert.are_same({true, 0}, {world.get_pixel_collision_info(8, 15)})
      end)

      it('should return {false, nil} on (8, 16)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(8, 16)})
      end)

      it('should return {false, nil} on (15, 7)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(15, 7)})
      end)

      it('should return true on (15, 8)', function ()
        assert.are_same({true, 0}, {world.get_pixel_collision_info(15, 8)})
      end)

      it('should return true on (15, 15)', function ()
        assert.are_same({true, 0}, {world.get_pixel_collision_info(15, 15)})
      end)

      it('should return {false, nil} on (15, 16)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(15, 16)})
      end)

      it('should return {false, nil} on (16, 7)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(16, 7)})
      end)

      it('should return {false, nil} on (16, 8)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(16, 8)})
      end)

      it('should return {false, nil} on (16, 15)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(16, 15)})
      end)

      it('should return {false, nil} on (16, 16)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(16, 16)})
      end)

    end)

    describe('with ascending slope 45', function ()

      before_each(function ()
        -- create an ascending slope at (1, 1), i.e. (8, 15) to (15, 8) px
        mock_mset(1, 1, asc_slope_45_id)
      end)

      it('should return {false, nil} on (8, 14)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(8, 14)})
      end)

      it('should return true on (8, 15)', function ()
        assert.are_same({true, 45/360}, {world.get_pixel_collision_info(8, 15)})
      end)

      it('should return {false, nil} on (8, 16)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(8, 16)})
      end)

      it('should return {false, nil} on (9, 13)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(9, 13)})
      end)

      it('should return true on (9, 14)', function ()
        assert.are_same({true, 45/360}, {world.get_pixel_collision_info(9, 14)})
      end)

      it('should return true on (9, 15)', function ()
        assert.are_same({true, 45/360}, {world.get_pixel_collision_info(9, 15)})
      end)

      it('should return {false, nil} on (9, 16)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(9, 16)})
      end)

      it('should return {false, nil} on (15, 7)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(15, 7)})
      end)

      it('should return true on (15, 8)', function ()
        assert.are_same({true, 45/360}, {world.get_pixel_collision_info(15, 8)})
      end)

      it('should return true on (15, 15)', function ()
        assert.are_same({true, 45/360}, {world.get_pixel_collision_info(15, 15)})
      end)

      it('should return {false, nil} on (15, 16)', function ()
        assert.are_same({false, nil}, {world.get_pixel_collision_info(15, 16)})
      end)

    end)

  end)

end)

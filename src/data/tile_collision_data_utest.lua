require("test/bustedhelper_ingame")
local tile_collision_data = require("data/tile_collision_data")

-- when we have to mock tile sprite data in PICO-8,
-- we use the following

-- mask tile 1: bottom-right asc slope variant with column 0 empty
-- (just to cover case column_height = 0 in read_height_array)
-- pixel representation:
-- ........
-- ........
-- ........
-- ........
-- ......##
-- ....####
-- ..######
-- .#######

-- mask tile 2: top-left concave ceiling
-- pixel representation:
-- ########
-- ######..
-- ####....
-- ###.....
-- ##......
-- ##......
-- #.......
-- #.......

-- mask tile 3: top-right concave ceiling (to check asymmetry)
-- pixel representation:
-- ########
-- ..######
-- ....####
-- .....###
-- ......##
-- ......##
-- .......#
-- .......#

describe('tile_collision_data', function ()

  describe('init', function ()

    it('should create a tile_collision_data with reciprocal arrays and slope angle', function ()
      local tcd = tile_collision_data(sprite_id_location(1, 0), {0, 1, 2, 2, 3, 3, 4, 4}, {0, 0, 0, 0, 2, 4, 6, 7}, atan2(8, -4), horizontal_dirs.right, vertical_dirs.down, true)
      assert.are_same({sprite_id_location(1, 0), {0, 1, 2, 2, 3, 3, 4, 4}, {0, 0, 0, 0, 2, 4, 6, 7}, atan2(8, -4), true}, {tcd.mask_tile_id_loc, tcd.height_array, tcd.width_array, tcd.slope_angle, tcd.land_on_empty_qcolumn})
    end)

  end)

  describe('get_height', function ()

    it('should return the height at the given column index', function ()
      local tcd = tile_collision_data(sprite_id_location(1, 0), {0, 1, 2, 2, 3, 3, 4, 4}, {0, 0, 0, 0, 2, 4, 6, 7}, atan2(8, -4))
      assert.are_equal(2, tcd:get_height(2))
    end)

  end)

  describe('get_width', function ()

    it('should return the width at the given column index', function ()
      local tcd = tile_collision_data(sprite_id_location(1, 0), {0, 1, 2, 2, 3, 3, 4, 4}, {0, 0, 0, 0, 2, 4, 6, 7}, atan2(8, -4))
      assert.are_equal(2, tcd:get_width(4))
    end)

  end)

  describe('is_full_vertical_rectangle', function ()

    -- just skip defining width array, we don't use it
    --  if you want to now what it should be normally,
    --  check the utests for is_full_horizontal_rectangle, which
    --  define the same tiles!

    it('should return true when empty (abnormal case though)', function ()
      local tcd = tile_collision_data(sprite_id_location(2, 0), {0, 0, 0, 0, 0, 0, 0, 0}, "unused", 0)
      assert.is_true(tcd:is_full_vertical_rectangle())
    end)

    it('should return true when made of empty/full columns', function ()
      local tcd = tile_collision_data(sprite_id_location(3, 0), {8, 8, 8, 0, 0, 0, 0, 0}, "unused", 0.75)
      assert.is_true(tcd:is_full_vertical_rectangle())
    end)

    it('should return false when not made of empty/full columns only', function ()
      local tcd = tile_collision_data(sprite_id_location(4, 0), {4, 4, 4, 4, 3, 3, 3, 3}, "unused", atan2(8, -1))
      assert.is_false(tcd:is_full_vertical_rectangle())
    end)

  end)

  describe('is_full_horizontal_rectangle (abnormal case though)', function ()

    -- same, no need to define columns

    it('should return true when empty', function ()
      local tcd = tile_collision_data(sprite_id_location(5, 0), "unused", {0, 0, 0, 0, 0, 0, 0, 0}, 0)
      assert.is_true(tcd:is_full_horizontal_rectangle())
    end)

    it('should return true when made of empty/full rows', function ()
      local tcd = tile_collision_data(sprite_id_location(6, 0), "unused", {0, 0, 0, 0, 0, 8, 8, 8}, 0)
      assert.is_true(tcd:is_full_horizontal_rectangle())
    end)

    it('should return false when not made of empty/full rows only', function ()
      local tcd = tile_collision_data(sprite_id_location(7, 0), "unused", {0, 0, 0, 0, 4, 8, 8, 8}, atan2(8, -1))
      assert.is_false(tcd:is_full_horizontal_rectangle())
    end)

  end)

  describe('is_rectangle', function ()

    -- we're only testing columns, so to simplify we don't define rows

    it('should return true when empty (abnormal case though)', function ()
      local tcd = tile_collision_data(sprite_id_location(5, 0), {0, 0, 0, 0, 0, 0, 0, 0}, "unused", 0, vertical_dirs.down, horizontal_dirs.right)
      assert.is_true(tcd:is_rectangle())
    end)

    it('should return true when made of empty/full columns', function ()
      local tcd = tile_collision_data(sprite_id_location(6, 0), {0, 0, 0, 0, 0, 8, 8, 8}, "unused", 0, vertical_dirs.down, horizontal_dirs.right)
      assert.is_true(tcd:is_rectangle())
    end)

    it('should return true when made of empty/partial columns, but all of same height', function ()
      local tcd = tile_collision_data(sprite_id_location(6, 0), {5, 5, 5, 5, 5, 0, 0, 0}, "unused", 0, vertical_dirs.down, horizontal_dirs.right)
      assert.is_true(tcd:is_rectangle())
    end)

    it('should return false when made of at least two columns of different heights', function ()
      local tcd = tile_collision_data(sprite_id_location(7, 0), {0, 0, 0, 0, 4, 7, 7, 7}, "unused", atan2(8, -1), vertical_dirs.down, horizontal_dirs.right)
      assert.is_false(tcd:is_rectangle())
    end)

    it('should return true when made of empty/partial columns all of same height, but land_on_empty_qcolumn is true', function ()
      local tcd = tile_collision_data(sprite_id_location(6, 0), {1, 1, 1, 1, 1, 1, 0, 0}, "unused", 0, true, vertical_dirs.down, horizontal_dirs.right, true)
      assert.is_false(tcd:is_rectangle())
    end)

  end)

  describe('(#debug_collision_mask) debug_render', function ()

    setup(function ()
      stub(_G, "spr")
    end)

    teardown(function ()
      spr:revert()
    end)

    after_each(function ()
      spr:clear()
    end)

    it('should call spr with mask_tile_id', function ()
      -- sprite id = 16 + 1 = 17, args after the 1st one don't matter
      local tcd = tile_collision_data(sprite_id_location(1, 1), "unused", "unused", 0, vertical_dirs.down, horizontal_dirs.right)

      tcd:debug_render(location(2, 4))

      assert.spy(spr).was_called(1)
      assert.spy(spr).was_called_with(17, 8 * 2, 8 * 4)
    end)

  end)

  describe('slope_angle_to_interiors', function ()

    -- cardinals

    it('should return down, right (edge case) for 0', function ()
      assert.are_same({vertical_dirs.down, horizontal_dirs.right}, {tile_collision_data.slope_angle_to_interiors(0)})
    end)

    it('should return up (edge case), right for 0.25', function ()
      assert.are_same({vertical_dirs.up, horizontal_dirs.right}, {tile_collision_data.slope_angle_to_interiors(0.25)})
    end)

    it('should return up, left (edge case) for 0.5', function ()
      assert.are_same({vertical_dirs.up, horizontal_dirs.left}, {tile_collision_data.slope_angle_to_interiors(0.5)})
    end)

    it('should return down (edge case), left for 0.75', function ()
      assert.are_same({vertical_dirs.down, horizontal_dirs.left}, {tile_collision_data.slope_angle_to_interiors(0.75)})
    end)

    -- diagonals

    it('should return a down, right for bottom-right tile', function ()
      assert.are_same({vertical_dirs.down, horizontal_dirs.right}, {tile_collision_data.slope_angle_to_interiors(atan2(8, -4))})
    end)

    it('should return a tile_collision_data containing (mock tile 2) height/width array, slope angle, derived interior directions', function ()
      assert.are_same({vertical_dirs.up, horizontal_dirs.left}, {tile_collision_data.slope_angle_to_interiors(atan2(-8, 8))})
    end)

    it('should return a tile_collision_data containing (mock tile 3) height/width array, slope angle, derived interior directions', function ()
      assert.are_same({vertical_dirs.up, horizontal_dirs.right}, {tile_collision_data.slope_angle_to_interiors(atan2(-8, -8))})
    end)

  end)

  describe('from_raw_tile_collision_data', function ()

    -- we wrote these utests before extracting slope_angle_to_interiors
    -- so we don't stub slope_angle_to_interiors and check final result directly

    setup(function ()
      stub(tile_collision_data, "read_height_array", function (tile_mask_id_location, slope_angle)
        assert(tile_mask_id_location.j == 0, "we are only testing on first row to simplify")
        if tile_mask_id_location.i == 1 then
          return {0, 1, 2, 2, 3, 3, 4, 4}
        elseif tile_mask_id_location.i == 2 then
          return {8, 6, 4, 3, 2, 2, 1, 1}
        else
          return {1, 1, 2, 2, 3, 4, 6, 8}
        end
      end)
      stub(tile_collision_data, "read_width_array", function (tile_mask_id_location, slope_angle)
        assert(tile_mask_id_location.j == 0, "we are only testing on first row to simplify")
        if tile_mask_id_location.i == 1 then
          return {0, 0, 0, 0, 2, 4, 6, 7}
        elseif tile_mask_id_location.i == 2 then
          return {8, 6, 4, 3, 2, 2, 1, 1}
        else
          return {8, 6, 4, 3, 2, 2, 1, 1}
        end
      end)
    end)

    teardown(function ()
      tile_collision_data.read_height_array:revert()
      tile_collision_data.read_width_array:revert()
    end)

    it('should return a tile_collision_data containing (mock tile 1) height/width array, slope angle, derived interior directions, land_on_empty_qcolumn (default: nil)', function ()
      local tcd = tile_collision_data.from_raw_tile_collision_data(1, atan2(8, -4))
      -- struct equality with are_equal would work, we just use are_same to benefit from diff asterisk provided by luassert
      assert.are_same(tile_collision_data(sprite_id_location(1, 0), {0, 1, 2, 2, 3, 3, 4, 4}, {0, 0, 0, 0, 2, 4, 6, 7}, atan2(8, -4), vertical_dirs.down, horizontal_dirs.right, nil), tcd)
    end)

    it('should return a tile_collision_data containing (mock tile 2) height/width array, slope angle, derived interior directions, land_on_empty_qcolumn (default: nil)', function ()
      local tcd = tile_collision_data.from_raw_tile_collision_data(2, atan2(-8, 8))
      assert.are_same(tile_collision_data(sprite_id_location(2, 0), {8, 6, 4, 3, 2, 2, 1, 1}, {8, 6, 4, 3, 2, 2, 1, 1}, atan2(-8, 8), vertical_dirs.up, horizontal_dirs.left, nil), tcd)
    end)

    it('should return a tile_collision_data containing (mock tile 3) height/width array, slope angle, derived interior directions, land_on_empty_qcolumn', function ()
      local tcd = tile_collision_data.from_raw_tile_collision_data(2, atan2(-8, -8), true)
      assert.are_same(tile_collision_data(sprite_id_location(2, 0), {8, 6, 4, 3, 2, 2, 1, 1}, {8, 6, 4, 3, 2, 2, 1, 1}, atan2(-8, -8), vertical_dirs.up, horizontal_dirs.right, true), tcd)
    end)

  end)

  describe('(mock sget)', function ()

    local sget_mock

    setup(function ()
      local mock_mask_dot_matrix1 = {
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 1, 1},
        {0, 0, 0, 0, 1, 1, 1, 1},
        {0, 0, 1, 1, 1, 1, 1, 1},
        {0, 1, 1, 1, 1, 1, 1, 1},
      }

      local mock_mask_dot_matrix2 = {
        {1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 0, 0},
        {1, 1, 1, 1, 0, 0, 0, 0},
        {1, 1, 1, 0, 0, 0, 0, 0},
        {1, 1, 0, 0, 0, 0, 0, 0},
        {1, 1, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 0, 0, 0, 0},
      }

      -- simulate an sget that would return the pixel of a tile mask
      --  if coordinates fall in the sprite 1 at location (1, 0), i.e. [8-15] x [0-8],
      --  or sprite 2 at location (2, 0), i.e. [16-23] x [0-8]
      stub(_G, "sget", function (x, y)
        if x >= 8 and x <= 15 and y >= 0 and y <= 8 then
          -- convert offset to 1-based Lua index
          -- multi-dimensional array above is first indexed by row (j), then column (i)
          return mock_mask_dot_matrix1[y+1][x-8+1]
        elseif x >= 16 and x <= 23 and y >= 0 and y <= 8 then
          return mock_mask_dot_matrix2[y+1][x-16+1]
        end
        return 0
      end)
    end)

    teardown(function ()
      sget:revert()
    end)

    -- read_height/width_array utests could be done without mocking sget
    --  and mocking check_collision_pixel instead, but since we had already written the utests below
    -- (which check the final result without stubbing) before extracting check_collision_pixel,
    -- it was simpler to just keep them, that to create a stub for check_collision_pixel that would cheat a lot
    -- with the passed arguments

    describe('read_height_array', function ()

      it('should return an array with respective column heights, from left to right', function ()
        local array = tile_collision_data.read_height_array(sprite_id_location(1, 0), vertical_dirs.down)
        assert.are_same({0, 1, 2, 2, 3, 3, 4, 4}, array)
      end)

      it('should return an array with respective column heights, from left to right', function ()
        local array = tile_collision_data.read_height_array(sprite_id_location(2, 0), vertical_dirs.up)
        assert.are_same({8, 6, 4, 3, 2, 2, 1, 1}, array)
      end)

    end)

    describe('read_width_array', function ()

      it('should return an array with respective column rows, from top to bottom', function ()
        local array = tile_collision_data.read_width_array(sprite_id_location(1, 0), horizontal_dirs.right)
        assert.are_same({0, 0, 0, 0, 2, 4, 6, 7}, array)
      end)

      it('should return an array with respective column rows, from top to bottom', function ()
        local array = tile_collision_data.read_width_array(sprite_id_location(2, 0), horizontal_dirs.left)
        assert.are_same({8, 6, 4, 3, 2, 2, 1, 1}, array)
      end)

    end)

    describe('check_collision_pixel', function ()

      it('(mock tile 1) should return nil when column pixel falls on empty pixel (interior down)', function ()
        -- note that 5 from top means 6th pixel on this column from the top
        local column_height = tile_collision_data.check_collision_pixel(8, 0, 2, 5, vertical_dirs.down, nil, tile_collision_data.evaluate_collision_height)
        assert.are_equal(nil, column_height)
      end)

      it('(mock tile 1) should return 2 when column pixel falls on collision pixel at height 2 from bottom (interior down)', function ()
        local column_height = tile_collision_data.check_collision_pixel(8, 0, 2, 6, vertical_dirs.down, nil, tile_collision_data.evaluate_collision_height)
        assert.are_equal(2, column_height)
      end)

      it('(mock tile 2) should return nil when column pixel falls on empty pixel (interior up)', function ()
        local column_height = tile_collision_data.check_collision_pixel(16, 0, 2, 4, vertical_dirs.up, nil, tile_collision_data.evaluate_collision_height)
        assert.are_equal(nil, column_height)
      end)

      it('(mock tile 2) should return 4 when column pixel falls on collision pixel at height 2 from top (interior up)', function ()
        local column_height = tile_collision_data.check_collision_pixel(16, 0, 2, 3, vertical_dirs.up, nil, tile_collision_data.evaluate_collision_height)
        assert.are_equal(4, column_height)
      end)

    end)

  end)  -- stub sget

  describe('evaluate_collision_height', function ()

    it('return tile_size - dy for interior down', function ()
      local column_height = tile_collision_data.evaluate_collision_height(nil, 2, vertical_dirs.down, nil)
      assert.are_equal(6, column_height)
    end)

    it('return dy + 1 for interior up', function ()
      local column_height = tile_collision_data.evaluate_collision_height(nil, 3, vertical_dirs.up, nil)
      assert.are_equal(4, column_height)
    end)

  end)

  describe('evaluate_collision_width', function ()

    it('return tile_size - dx for interior down', function ()
      local row_width = tile_collision_data.evaluate_collision_width(2, nil, nil, horizontal_dirs.right)
      assert.are_equal(6, row_width)
    end)

    it('return dx + 1 for interior up', function ()
      local row_width = tile_collision_data.evaluate_collision_width(3, nil, nil, horizontal_dirs.left)
      assert.are_equal(4, row_width)
    end)

  end)

end)

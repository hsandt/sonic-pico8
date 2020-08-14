require("engine/test/bustedhelper")
local tile_collision_data = require("data/tile_collision_data")

describe('tile_collision_data', function ()

  describe("mocking _fill_array", function ()

    describe('_init', function ()

      it('should create a tile_collision_data with reciprocal arrays and slope angle', function ()
        local tcd = tile_collision_data({1, 1, 2, 2, 3, 3, 4, 4}, {0, 0, 0, 0, 2, 4, 6, 8}, 0.125)
        assert.are_same({{1, 1, 2, 2, 3, 3, 4, 4}, {0, 0, 0, 0, 2, 4, 6, 8}, 0.125}, {tcd.height_array, tcd.width_array, tcd.slope_angle})
      end)

    end)

    describe('get_height', function ()

      it('should return the height at the given column index', function ()
        local tcd = tile_collision_data({1, 1, 2, 2, 3, 3, 4, 4}, {0, 0, 0, 0, 2, 4, 6, 8}, 0.125)
        assert.are_equal(2, tcd:get_height(2))
      end)

    end)

    describe('get_width', function ()

      it('should return the width at the given column index', function ()
        local tcd = tile_collision_data({1, 1, 2, 2, 3, 3, 4, 4}, {0, 0, 0, 0, 2, 4, 6, 8}, 0.125)
        assert.are_equal(2, tcd:get_width(4))
      end)

    end)

  end)

  describe('read_height_array', function ()

    local sget_mock

    setup(function ()
      -- simulate an sget that would return the pixel of a tile mask
      --  if coordinates fall in the sprite at location (1, 2), i.e. [8-15] x [16-23],
      --  where mock_height_array contains the respective height of the mask columns
      --  for each column from left to right
      local mock_height_array = {2, 3, 5, 6, 0, 1, 4, 2}
      sget_mock = stub(_G, "sget", function (x, y)
        if x >= 8 and x <= 15 and y >= 16 and y <= 23 then
          -- return filled pixel color iff below mask height on this column
          local height = mock_height_array[x - 7]
          if y - 16 >= tile_size - height then
            return 1
          else
            return 0
          end
        end
      end)
    end)

    teardown(function ()
      sget_mock:revert()
    end)

    it('should fill the array with ', function ()
      local array = tile_collision_data.read_height_array(sprite_id_location(1, 2), 0)
      assert.are_same({2, 3, 5, 6, 0, 1, 4, 2}, array)
    end)

  end)

end)

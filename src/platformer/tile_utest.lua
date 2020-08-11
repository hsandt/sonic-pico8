require("engine/test/bustedhelper")
local tile = require("platformer/tile")
local tile_data = tile.tile_data
local height_array = tile.height_array

describe('tile', function ()

  describe('tile_data', function ()

    describe('_init', function ()

      it('should create a tile data setting the sprite id location and the slope angle', function ()
        local td = tile_data(sprite_id_location(1, 2), 0.125)
        assert.are_same({sprite_id_location(1, 2), 0.125}, {td.id_loc, td.slope_angle})
      end)

    end)

    describe('_tostring', function ()

      it('should return "height_array({4, 5, 6, 7, 8, 9, 10, 11}, 0.125)"', function ()
        local td = tile_data(sprite_id_location(1, 2), 0.125)
        assert.are_equal("tile_data(sprite_id_location(1, 2), 0.125)", td:_tostring())
      end)

    end)

  end)

  describe('height_array', function ()

    describe("mocking _fill_array", function ()

      local fill_array_mock

      setup(function ()
        fill_array_mock = stub(height_array, "_fill_array", function (array, tile_mask_sprite_id_location)
          for i = 1, tile_size do
            array[i] = tile_mask_sprite_id_location.i + tile_mask_sprite_id_location.j + i
          end
        end)
      end)

      teardown(function ()
        fill_array_mock:revert()
      end)

      after_each(function ()
        fill_array_mock:clear()
      end)

      describe('_init', function ()

        it('should create a height array using fill_array and setting the slope angle', function ()
          local h_array = height_array(tile_data(sprite_id_location(1, 2), 0.125))
          assert.are_same({{4, 5, 6, 7, 8, 9, 10, 11}, 0.125}, {h_array._array, h_array.slope_angle})
        end)

      end)

      describe('_tostring', function ()

        it('should return "height_array({4, 5, 6, 7, 8, 9, 10, 11}, 0.125)"', function ()
          local h_array = height_array(tile_data(sprite_id_location(1, 2), 0.125))
          assert.are_equal("height_array({4, 5, 6, 7, 8, 9, 10, 11}, 0.125)", h_array:_tostring())
        end)

      end)

      describe('get_height', function ()

        it('should return the height at the given column index', function ()
          local h_array = height_array(tile_data(sprite_id_location(1, 2), 0.125))
          assert.are_equal(6, h_array:get_height(2))
        end)

      end)

    end)

    describe('_fill_array', function ()

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
        local array = {}
        height_array._fill_array(array, sprite_id_location(1, 2))
        assert.are_same({2, 3, 5, 6, 0, 1, 4, 2}, array)
      end)

    end)

  end)

end)

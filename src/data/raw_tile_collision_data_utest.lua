require("test/bustedhelper")
local raw_tile_collision_data = require("data/raw_tile_collision_data")

describe('raw_tile_collision_data', function ()

  describe('_init', function ()

    it('should create a raw tile data setting the sprite id location and the slope angle', function ()
      local td = raw_tile_collision_data(sprite_id_location(1, 2), 0.125)
      assert.are_same({sprite_id_location(1, 2), 0.125}, {td.mask_tile_id_loc, td.slope_angle})
    end)

  end)

  describe('_tostring', function ()

    it('should return "height_array({4, 5, 6, 7, 8, 9, 10, 11}, 0.125)"', function ()
      local td = raw_tile_collision_data(sprite_id_location(1, 2), 0.125)
      assert.are_equal("raw_tile_collision_data(sprite_id_location(1, 2), 0.125)", td:_tostring())
    end)

  end)

end)

local collision = require("engine/physics/collision")
local tile_data = collision.tile_data

sprite_flags = {
  collision = 0
}

return {

  -- table mapping tile sprite id to tile data (collision mask + slope)
  -- the mask is generally placed just below the visual tile in pico8 sprite editor,
  --  hence the location @ (i, j) but the sprite_id_location(i, j + 1)
  -- this will be completed as tiles are added, adding extra information
  --  such as "mirror_y: true" for upside-down tiles
  -- for readability we also indicate the sprite id location in comment
  -- note that for mockup, tile_test_data now contains the mock height arrays
  --  while this contains the slopes, which is bad practice; we'll need to centralize
  --  mock data in the end. we'll probably create a pico8 tile data to data string
  --  converter so we can edit visually, but also generate data code reusable
  --  for headless tests
  tiles_data = {
    [64] = tile_data(sprite_id_location(0, 5), 0),       -- 64 @ (0, 4)
    [65] = tile_data(sprite_id_location(1, 5), -0.125),  -- 65 @ (1, 4)
    [66] = tile_data(sprite_id_location(2, 5), 0.125),   -- 66 @ (2, 4)
    [67] = tile_data(sprite_id_location(3, 5), -0.0625), -- 67 @ (3, 4)
    [68] = tile_data(sprite_id_location(4, 5), 0),       -- 68 @ (4, 4)
    [69] = tile_data(sprite_id_location(5, 5), 0),       -- 69 @ (5, 4)
    [70] = tile_data(sprite_id_location(6, 5), 0),       -- 70 @ (6, 4)
    [71] = tile_data(sprite_id_location(7, 5), 0),       -- 71 @ (7, 4)
    [72] = tile_data(sprite_id_location(8, 5), 0),       -- 72 @ (8, 4)
    [73] = tile_data(sprite_id_location(9, 5), 0),       -- 73 @ (9, 4)
    [74] = tile_data(sprite_id_location(10, 5), 0),      -- 74 @ (10, 4)
  }

}

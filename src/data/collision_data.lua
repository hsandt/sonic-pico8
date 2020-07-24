require("engine/core/math")
local tile = require("platformer/tile")
local tile_data = tile.tile_data

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
    [49] = tile_data(sprite_id_location(1, 2), atan2(8, 2)),       -- 49 @ (1, 3)
    [50] = tile_data(sprite_id_location(0, 2), 0),                  -- 50 @ (2, 3)
    [51] = tile_data(sprite_id_location(0, 2), 0),                  -- 51 @ (3, 3)
    [52] = tile_data(sprite_id_location(0, 2), 0),                  -- 52 @ (4, 3)
    [53] = tile_data(sprite_id_location(5, 2), atan2(8, -2)),       -- 53 @ (5, 3)
    [54] = tile_data(sprite_id_location(6, 2), 0),                  -- 54 @ (6, 3)
    [65] = tile_data(sprite_id_location(0, 2), 0),                  -- 65 @ (1, 4)
    [66] = tile_data(sprite_id_location(0, 2), 0),                  -- 66 @ (2, 4)
    [67] = tile_data(sprite_id_location(0, 2), 0),                  -- 67 @ (3, 4)
    [68] = tile_data(sprite_id_location(0, 2), 0),                  -- 68 @ (4, 4)
    [81] = tile_data(sprite_id_location(0, 2), 0),                  -- 81 @ (1, 5)
    [82] = tile_data(sprite_id_location(0, 2), 0),                  -- 82 @ (2, 5)
    [83] = tile_data(sprite_id_location(0, 2), 0),                  -- 83 @ (3, 5)
    [84] = tile_data(sprite_id_location(0, 2), 0),                  -- 84 @ (4, 5)
    [97] = tile_data(sprite_id_location(0, 2), 0),                  -- 97 @ (1, 6)
    [98] = tile_data(sprite_id_location(0, 2), 0),                  -- 98 @ (2, 6)
    [99] = tile_data(sprite_id_location(0, 2), 0),                  -- 99 @ (3, 6)
    [100]= tile_data(sprite_id_location(0, 2), 0),                  --100 @ (4, 6)
    [114]= tile_data(sprite_id_location(0, 2), 0),                  --114 @ (2, 7)
    [115]= tile_data(sprite_id_location(0, 2), 0),                  --115 @ (3, 7)
    [87] = tile_data(sprite_id_location(7, 4),  atan2(8, 2)),      -- 87 @ (7, 5)
    [88] = tile_data(sprite_id_location(8, 4),  atan2(8, 1)),      -- 88 @ (8, 5)
    [89] = tile_data(sprite_id_location(9, 4),  atan2(8, 2)),      -- 89 @ (9, 5)
    [90] = tile_data(sprite_id_location(10, 4), atan2(8, 2)),      -- 90 @ (10, 5)
    [91] = tile_data(sprite_id_location(11, 4), atan2(8, -2)),      -- 91 @ (11, 5)
    [92] = tile_data(sprite_id_location(12, 4), atan2(8, -2)),      -- 92 @ (12, 5)
    [93] = tile_data(sprite_id_location(13, 4), atan2(8, -1)),      -- 93 @ (13, 5)
    [94] = tile_data(sprite_id_location(14, 4), atan2(8, -2)),      -- 94 @ (14, 5)
    [103]= tile_data(sprite_id_location(0, 2), 0),                  -- 103 @ (7, 6)
    [104]= tile_data(sprite_id_location(0, 2), 0),                  -- 104 @ (8, 6)
    [105]= tile_data(sprite_id_location(0, 2), 0),                  -- 105 @ (9, 6)
    [106]= tile_data(sprite_id_location(0, 2), 0),                  -- 106 @ (10, 6)
    [107]= tile_data(sprite_id_location(0, 2), 0),                  -- 107 @ (11, 6)
    [108]= tile_data(sprite_id_location(0, 2), 0),                  -- 108 @ (12, 6)
    [109]= tile_data(sprite_id_location(0, 2), 0),                  -- 109 @ (13, 6)
    [110]= tile_data(sprite_id_location(0, 2), 0),                  -- 110 @ (14, 6)
    -- proto (black and white tiles being their own collision masks)
    -- must match tile_data.lua
    -- if too heavy, surround with #itest and create a separate spritesheet for itests with only polygonal tiles
    -- stored in some proto_data.p8 or test_data.p8
    -- this will allow us to reuse the extra space left by removing proto tiles for release (adding FX, etc.)
    [32] = tile_data(sprite_id_location(0, 2), 0),                  -- 32  @ (0, 2) FULL TILE #
    [80] = tile_data(sprite_id_location(0, 5), 0),                  -- 80  @ (0, 5) HALF TILE (4px high) =
    [96] = tile_data(sprite_id_location(0, 6), 0),                  -- 96  @ (0, 6) FLAT LOW TILE (2px high) _
    [64] = tile_data(sprite_id_location(0, 4), 0),                  -- 64  @ (0, 4) BOTTOM-RIGHT QUARTER TILE (4px high) r
    [112]= tile_data(sprite_id_location(1, 7), -0.125),             -- 112 @ (1, 7) ASCENDING 45 /
    [113]= tile_data(sprite_id_location(0, 7), -0.0625),            -- 113 @ (0, 7) ASCENDING 22.5 <
    [116]= tile_data(sprite_id_location(4, 7), 0.125),              -- 116 @ (4, 7) DESCENDING 45 \
  }

}

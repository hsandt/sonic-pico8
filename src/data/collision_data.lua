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

  -- all angles are defined with atan2 using top-left XY convention to avoid issues
  -- proto tiles may pass values manually, but in this case make sure to enter the angle
  -- between 0 and 1, as if Sonic was running a loop counter-clockwise
  tiles_data = {
    [49] = tile_data(sprite_id_location(1, 2), atan2(8, -2)),       -- 49 @ (1, 3)
    [50] = tile_data(sprite_id_location(0, 2), 0),                  -- 50 @ (2, 3)
    [51] = tile_data(sprite_id_location(0, 2), 0),                  -- 51 @ (3, 3)
    [52] = tile_data(sprite_id_location(0, 2), 0),                  -- 52 @ (4, 3)
    [53] = tile_data(sprite_id_location(5, 2), atan2(8, 2)),       -- 53 @ (5, 3)
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
    -- low slopes ascending and descending
    [103] = tile_data(sprite_id_location(7, 5),  atan2(8, -2)),      -- 87 @ (7, 6)
    [104] = tile_data(sprite_id_location(8, 5),  atan2(8, -1)),      -- 88 @ (8, 6)
    [105] = tile_data(sprite_id_location(9, 5),  atan2(8, -2)),      -- 89 @ (9, 6)
    [106] = tile_data(sprite_id_location(10, 5), atan2(8, -2)),      -- 90 @ (10, 6)
    [107] = tile_data(sprite_id_location(11, 5), atan2(8, 2)),      -- 91 @ (11, 6)
    [108] = tile_data(sprite_id_location(12, 5), atan2(8, 2)),      -- 92 @ (12, 6)
    [109] = tile_data(sprite_id_location(13, 5), atan2(8, 1)),      -- 93 @ (13, 6)
    [110] = tile_data(sprite_id_location(14, 5), atan2(8, 2)),      -- 94 @ (14, 6)
    -- bottom of said slopes (full tiles)
    [119]= tile_data(sprite_id_location(0, 2), 0),                  -- 119 @ (7, 7)
    [120]= tile_data(sprite_id_location(0, 2), 0),                  -- 120 @ (8, 7)
    [121]= tile_data(sprite_id_location(0, 2), 0),                  -- 121 @ (9, 7)
    [122]= tile_data(sprite_id_location(0, 2), 0),                  -- 122 @ (10, 7)
    [123]= tile_data(sprite_id_location(0, 2), 0),                  -- 123 @ (11, 7)
    [124]= tile_data(sprite_id_location(0, 2), 0),                  -- 124 @ (12, 7)
    [125]= tile_data(sprite_id_location(0, 2), 0),                  -- 125 @ (13, 7)
    [126]= tile_data(sprite_id_location(0, 2), 0),                  -- 126 @ (14, 7)
    -- loop (start from top-left tile, then rotate clockwise)
    -- note that we always write angles as atan2(dx, dy) with motion (dx, dy)
    --  as if Sonic was running the loop counter-clockwise
    -- this allows to identify ceiling angles vs floor angles easily
    --  (ceiling angles between 0.25 and 0.75)
    [8]= tile_data(sprite_id_location(12, 0), atan2(-4, 4)),        -- 8 @ (8, 0)
    [9]= tile_data(sprite_id_location(13, 0), atan2(-8, 4)),        -- 9 @ (9, 0)
    [10]= tile_data(sprite_id_location(14, 0), atan2(-8, -4)),      -- 10 @ (10, 0)
    [11]= tile_data(sprite_id_location(15, 0), atan2(-4, -4)),      -- 11 @ (11, 0)
    [27]= tile_data(sprite_id_location(15, 1), atan2(-4, -8)),      -- 27 @ (11, 1)
    [43]= tile_data(sprite_id_location(15, 2), atan2(4, -8)),       -- 43 @ (11, 2)
    [59]= tile_data(sprite_id_location(15, 3), atan2(4, -4)),       -- 59 @ (11, 3)
    [58]= tile_data(sprite_id_location(14, 3), atan2(8, -4)),       -- 58 @ (10, 3)
    [57]= tile_data(sprite_id_location(13, 3), atan2(8, 4)),        -- 57 @ (9, 3)
    [56]= tile_data(sprite_id_location(12, 3), atan2(4, 4)),        -- 56 @ (8, 3)
    [40]= tile_data(sprite_id_location(12, 2), atan2(4, 8)),        -- 40 @ (8, 2)
    [24]= tile_data(sprite_id_location(12, 1), atan2(-4, 8)),       -- 24 @ (8, 1)
    -- loop bottom ground (full)
    [72]= tile_data(sprite_id_location(12, 4), 0),                  -- 72 @ (8, 4)
    [73]= tile_data(sprite_id_location(13, 4), 0),                  -- 73 @ (9, 4)
    [74]= tile_data(sprite_id_location(14, 4), 0),                  -- 74 @ (10, 4)
    [75]= tile_data(sprite_id_location(15, 4), 0),                  -- 75 @ (11, 4)

    -- proto (black and white tiles being their own collision masks)
    -- must match tile_data.lua
    -- if too heavy, surround with #itest and create a separate spritesheet for itests with only polygonal tiles
    -- stored in some proto_data.p8 or test_data.p8
    -- this will allow us to reuse the extra space left by removing proto tiles for release (adding FX, etc.)
    [32] = tile_data(sprite_id_location(0, 2), 0),                  -- 32  @ (0, 2) FULL TILE #
    [80] = tile_data(sprite_id_location(0, 5), 0),                  -- 80  @ (0, 5) HALF TILE (4px high) =
    [96] = tile_data(sprite_id_location(0, 6), 0),                  -- 96  @ (0, 6) FLAT LOW TILE (2px high) _
    [64] = tile_data(sprite_id_location(0, 4), 0),                  -- 64  @ (0, 4) BOTTOM-RIGHT QUARTER TILE (4px high) r
    [112]= tile_data(sprite_id_location(1, 7), 0.125),             -- 112 @ (1, 7) ASCENDING 45 /
    [113]= tile_data(sprite_id_location(0, 7), 0.0625),            -- 113 @ (0, 7) ASCENDING 22.5 <
    [116]= tile_data(sprite_id_location(4, 7), 1-0.125),           -- 116 @ (4, 7) DESCENDING 45 \
    [117]= tile_data(sprite_id_location(5, 7), atan2(8, -4)),      -- 117 @ (5, 7) higher 2:1 ascending slope (completes 58 from loop)
  }

}

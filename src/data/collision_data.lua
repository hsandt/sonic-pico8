local serialization = require("engine/data/serialization")

local raw_tile_collision_data = require("data/raw_tile_collision_data")
local tile_collision_data = require("data/tile_collision_data")

sprite_flags = {
  collision = 0
}

-- table mapping visual tile sprite id to tile collision data (collision mask sprite id location + slope)
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

--[[
  EXPLANATION OF EACH TILE ID <-> (I, J) IN SPRITESHEET
  (put in comments outside data string because we don't have a preprocess step able to strip comments
  inside data strings, nor is parse_expression able to ignore comments)
  # common tiles (flat or very low slope)
   49 @ (1, 3)
   50 @ (2, 3)
   51 @ (3, 3)
   52 @ (4, 3)
   53 @ (5, 3)
   54 @ (6, 3)
   65 @ (1, 4)
   66 @ (2, 4)
   67 @ (3, 4)
   68 @ (4, 4)
   81 @ (1, 5)
   82 @ (2, 5)
   83 @ (3, 5)
   84 @ (4, 5)
   97 @ (1, 6)
   98 @ (2, 6)
   99 @ (3, 6)
  100 @ (4, 6)
  114 @ (2, 7)
  115 @ (3, 7)
  # low slopes ascending and descending
   87 @ (7, 6)
   88 @ (8, 6)
   89 @ (9, 6)
   90 @ (10, 6)
   91 @ (11, 6)
   92 @ (12, 6)
   93 @ (13, 6)
   94 @ (14, 6)
  # bottom of said slopes (full tiles)
  119 @ (7, 7)
  120 @ (8, 7)
  121 @ (9, 7)
  122 @ (10, 7)
  123 @ (11, 7)
  124 @ (12, 7)
  125 @ (13, 7)
  126 @ (14, 7)
  # loop (start from top-left tile, then rotate clockwise)
  # note that we always write angles as atan2(dx, dy) with motion (dx, dy)
  #  as if Sonic was running the loop counter-clockwise
  # this allows to identify ceiling angles vs floor angles easily
  #  (ceiling angles between 0.25 and 0.75)
   8 @ (8, 0)
   9 @ (9, 0)
  10 @ (10, 0)
  11 @ (11, 0)
  27 @ (11, 1)
  43 @ (11, 2)
  59 @ (11, 3)
  58 @ (10, 3)
  57 @ (9, 3)
  56 @ (8, 3)
  40 @ (8, 2)
  24 @ (8, 1)
  # loop bottom ground (full)
  72 @ (8, 4)
  73 @ (9, 4)
  74 @ (10, 4)
  75 @ (11, 4)

  # proto (black and white tiles being their own collision masks)
  # must match tile_data.lua
  # if too heavy, surround with #itest and create a separate spritesheet for itests with only polygonal tiles
  # stored in some proto_data.p8 or test_data.p8
  # this will allow us to reuse the extra space left by removing proto tiles for release (adding FX, etc.)
   32  @ (0, 2) FULL TILE #
   80  @ (0, 5) HALF TILE (4px high) =
   96  @ (0, 6) FLAT LOW TILE (2px high) _
   64  @ (0, 4) BOTTOM-RIGHT QUARTER TILE (4px high) r
   112 @ (1, 7) ASCENDING 45 /   slope_angle: 0.125 = atan2(1, -1)
   113 @ (0, 7) ASCENDING 22.5 < slope_angle: 0.0625 ~= atan2(8, -4) (actually 0.0738) but kept for historical utest/itest reasons
   116 @ (4, 7) DESCENDING 45 \  slope_angle: 1-0.125 = atan2(1, 1)
   117 @ (5, 7) higher 2:1 ascending slope (completes 58 from loop)
   12  @ (12, 0) LOOP TOP-LEFT: reusing mask of loop top-left with itself
 --]]
local raw_tiles_data = serialization.parse_expression(
   --[tile_id] = tile_data(
   --       mask_tile_id_loc, slope_angle=atan2(x, y) or angle (proto only))
  [[{
    [49] = {{1, 2}, {8, -2}},
    [50] = {{0, 2}, {8, 0}},
    [51] = {{0, 2}, {8, 0}},
    [52] = {{0, 2}, {8, 0}},
    [53] = {{5, 2}, {8, 2}},
    [54] = {{6, 2}, {8, 0}},
    [65] = {{0, 2}, {8, 0}},
    [66] = {{0, 2}, {8, 0}},
    [67] = {{0, 2}, {8, 0}},
    [68] = {{0, 2}, {8, 0}},
    [81] = {{0, 2}, {8, 0}},
    [82] = {{0, 2}, {8, 0}},
    [83] = {{0, 2}, {8, 0}},
    [84] = {{0, 2}, {8, 0}},
    [97] = {{0, 2}, {8, 0}},
    [98] = {{0, 2}, {8, 0}},
    [99] = {{0, 2}, {8, 0}},
    [100]= {{0, 2}, {8, 0}},
    [114]= {{0, 2}, {8, 0}},
    [115]= {{0, 2}, {8, 0}},

    [103] = {{7, 5},  {8, -2}},
    [104] = {{8, 5},  {8, -1}},
    [105] = {{9, 5},  {8, -2}},
    [106] = {{10, 5}, {8, -2}},
    [107] = {{11, 5}, {8, 2}},
    [108] = {{12, 5}, {8, 2}},
    [109] = {{13, 5}, {8, 1}},
    [110] = {{14, 5}, {8, 2}},

    [119]= {{0, 2}, {8, 0}},
    [120]= {{0, 2}, {8, 0}},
    [121]= {{0, 2}, {8, 0}},
    [122]= {{0, 2}, {8, 0}},
    [123]= {{0, 2}, {8, 0}},
    [124]= {{0, 2}, {8, 0}},
    [125]= {{0, 2}, {8, 0}},
    [126]= {{0, 2}, {8, 0}},

    [8]= {{12, 0}, {-4, 4}},
    [9]= {{13, 0}, {-8, 4}},
    [10]= {{14, 0}, {-8, -4}},
    [11]= {{15, 0}, {-4, -4}},
    [27]= {{15, 1}, {-4, -8}},
    [43]= {{15, 2}, {4, -8}},
    [59]= {{15, 3}, {4, -4}},
    [58]= {{14, 3}, {8, -4}},
    [57]= {{13, 3}, {8, 4}},
    [56]= {{12, 3}, {4, 4}},
    [40]= {{12, 2}, {4, 8}},
    [24]= {{12, 1}, {-4, 8}},

    [72]= {{12, 4}, {8, 0}},
    [73]= {{13, 4}, {8, 0}},
    [74]= {{14, 4}, {8, 0}},
    [75]= {{15, 4}, {8, 0}},

    [32] = {{0, 2}, {8, 0}},
    [80] = {{0, 5}, {8, 0}},
    [96] = {{0, 6}, {8, 0}},
    [64] = {{0, 4}, {8, 0}},
    [112]= {{1, 7}, {8, -8}},
    [113]= {{0, 7}, 0.0625},
    [116]= {{4, 7}, {8, 8}},
    [117]= {{5, 7}, {8, -4}},
    [12]= {{12, 0}, {-4, 4}}
  }]], function (t)
    -- t[2] may be {x, y} to use for atan2 or slope_angle directly
    -- this is only for [113], if we update utests/itests to use the more correct atan2(8, -4) then we can get rid of
    --  that ternary check
    return raw_tile_collision_data(sprite_id_location(t[1][1], t[1][2]), type(t[2]) == 'table' and atan2(t[2][1], t[2][2]) or t[2])
  end
)

local tiles_collision_data = transform(raw_tiles_data, tile_collision_data.from_raw_tile_collision_data)

return {
  -- proxy getter is only here to make stubbing possible in tile_test_data
  get_tile_collision_data = function (tile_id)
    return tiles_collision_data[tile_id]
  end
}

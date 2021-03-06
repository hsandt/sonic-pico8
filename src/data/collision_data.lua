local tile_collision_data = require("data/tile_collision_data")

local collision_data = {}

-- below, we are not using serialization.parse_expression anymore
--  because we want to insert inline comments and have unlimited tokens anyway

-- table of slope angles indexed by collision mask tile id
-- we define the angles as (dx, dy) following convention of a point moving CCW
--  then compute atan2(dx, dy)
-- we could compute the angles manually from the height array, but since there subtleties of +/- 1px
--  depending on how we interpretr pixel ladders, we prefer setting them manually to get the slope factor we want
local mask_tile_angles = transform(
  {
    -- low slope descending every 4px with flat ground at every step
    [1]  = {8, 2},
    [2]  = {8, 0},  -- flat tile 6px high
    [3]  = {8, 2},
    [4]  = {8, 0},  -- half-tile (4px high)
    [5]  = {8, 2},
    [6]  = {8, 0},  -- flat tile 2px high
    [7]  = {8, 2},

    -- low slope ascending every 4px
    [8]  = {8, -2},
    [9]  = {8, -2},
    [10] = {8, -2},
    [11] = {8, -2},

    -- mid slope descending every 2px,
    --  but manually adjust from {8, 4} to a lower slope angle
    --  for better physics feel, closer to Sonic 3 (and no 45 deg sprite rotation)
    [12] = {8, 3},
    [13] = {8, 3},

    -- mid slope ascending every 2px
    --  (see remark on adjustment above)
    [14] = {8, -3},
    [15] = {8, -3},

    -- loop (collider only)

    -- loop parts: bottom (from left to right)
    [16] = {8,  8},  -- 45-deg slope descending
    [17] = {8,  5},  -- loop bottom-left
    [18] = {8,  3},  -- loop bottom-bottom-left
    [19] = {8, -3},  -- loop bottom-bottom-right
    [20] = {8, -5},  -- loop bottom-right
    [21] = {8, -8},  -- 45-deg slope ascending

    -- loop parts: right (from bottom to top)
    [38] = { 4, -8},
    [22] = { 3, -8},
    [39] = {-3, -8},
    [23] = {-4, -8},

    -- loop parts: top (from left to right)
    [32] = {-8,  8},
    [33] = {-8,  5},
    [34] = {-8,  3},
    [35] = {-8, -3},
    [36] = {-8, -5},
    [37] = {-8, -8},

    -- loop parts: left (from top to right)
    [24] = {-4, 8},
    [40] = {-3, 8},
    [25] = { 3, 8},
    [41] = { 4, 8},

    -- 6px-high rectangles (angle doesn't matter)
    [26] = {8, 0},  -- 4x6 used for spring left part (collider only)
    [27] = {8, 0},  -- 8x6 used for spring right part (collider only)  -- TODO: reuse 2, it's the same!

    -- 8px-high rectangles (angle doesn't matter)
    [28] = {8, 0},  -- 4x8 used for rock left part
    [29] = {8, 0},  -- 8x8 used for rock right part and any full ground
    [30] = {8, 0},  -- 6x8 used for spring oriented left (ground part only, object is separate)
    [31] = {8, 0},  -- 6x8 used for spring oriented right (ground part only, object is separate)

    -- test only, no corresponding visual tiles
    [42] = {8, -4},  -- mid slope ascending but starts 2px high unlike 15 (which starts 4px high)
    [43] = {8, -4},  -- mid slope ascending but starts 5px high unlike 15
    [44] = {8,  0},  -- 4x4 block in bottom-right corner, useful for small mask testing (angle doesn't matter)

    -- [45] = {45, {8, 0}},  -- empty tile (can be reused for visual sprite if needed)
  },
  function (dx_dy)
    return atan2(dx_dy[1], dx_dy[2])
  end
)

-- table of tile collision mask ids indexed by tile id
local mask_tile_ids = {

--#if proto

-- PROTO TILES
-- those tiles are meant for testing and level blockout,
--  and are their own collision masks
-- they have no additional flags in the spritesheet
--  so they cannot be used as special tiles like loops or springs
-- in order to spare characters in release we surround them with #proto
--  which is currently only defined in build_itest.sh, but you can
--  temporarily define it for any config if you need it outside itests

-- low slope descending every 4px with flat ground at every step
  [1]  = 1,
  [2]  = 2,
  [3]  = 3,
  [4]  = 4,
  [5]  = 5,
  [6]  = 6,
  [7]  = 7,

-- low slope ascending every 4px
  [8]  = 8,
  [9]  = 9,
  [10] = 10,
  [11] = 11,

-- mid slope descending every 2px
  [12] = 12,
  [13] = 13,

-- mid slope ascending every 2px
  [14] = 14,
  [15] = 15,

-- loop (collider only)

-- loop parts: bottom (from left to right)
  [16] = 16,
  [17] = 17,
  [18] = 18,
  [19] = 19,
  [20] = 20,
  [21] = 21,

-- loop parts: right (from bottom to top)
  [38] = 38,
  [22] = 22,
  [39] = 39,
  [23] = 23,

-- loop parts: top (from left to right)
  [32] = 32,
  [33] = 33,
  [34] = 34,
  [35] = 35,
  [36] = 36,
  [37] = 37,

-- loop parts: left (from top to right)
  [24] = 24,
  [40] = 40,
  [25] = 25,
  [41] = 41,

-- 6px-high rectangles (angle doesn't matter)
  [26] = 26,
  [27] = 27,

-- 8px-high rectangles (angle doesn't matter)
  [28] = 28,
  [29] = 29,
  [30] = 30,
  [31] = 31,

-- test only, no corresponding visual tiles
  [42] = 42,
  [43] = 43,
  [44] = 44,

-- [45] = 45,  -- empty tile

--(proto)
--#endif

-- VISUAL TILES
-- those tiles are associated to one of the collision masks above

-- one-way tiles

-- one-way platform tiles are in the runtime mask area, so overlapping proto tiles
--#ifn proto
-- the bottom doesn't matter as one-way, otherwise surface is full, so just use full tile mask
  [35] = 29,
  [36] = 29,
--#endif

-- full tiles

-- wood
  [218] = 29,  -- wood (specular middle left)
  [219] = 29,  -- wood (specular middle right)
  [235] = 29,  -- wood (generic)
  [48] = 29,  -- wood (specular top 1-column)
  [64] = 29,  -- wood (specular middle 1-column)
  [80] = 29,  -- wood (specular top 1-column)
  [83] = 29,  -- wood (specular top left)
  [84] = 29,  -- wood (specular top right)

-- floating platform bottom (left and right)
  [124] = 29,
  [125] = 29,

-- ground with grass, flat and slopes
  [49] = 1,
  [50] = 2,
  [51] = 3,
  [52] = 4,
  [53] = 5,
  [54] = 6,
  [55] = 7,
  [56] = 8,
  [57] = 9,
  [58] = 10,
  [59] = 11,
  [60] = 12,
  [61] = 13,
  [62] = 14,
  [63] = 15,
  [65] = 29,
  [66] = 29,
  [67] = 29,
  [68] = 29,
  [69] = 29,
  [70] = 29,
  [71] = 29,
  [72] = 29,
  [73] = 29,
  [85] = 29,
  [86] = 29,
  [87] = 29,
  [88] = 29,
  [89] = 29,

-- leaves
  [94]  = 29,  -- wood (specular bottom left) with first leaves
  [95]  = 29,  -- wood (specular bottom right) with first leaves
  [110] = 29,  -- full leaves (pattern 1)
  [111] = 29,  -- full leaves (pattern 2)

-- other shapes

-- spring
  [74]  = 26,  -- normal: left part
  [75]  = 27,  -- normal: right part
  [106] = 29,  -- extended: bottom-left part
  [107] = 29,  -- extended: bottom-right part
-- extended higher parts (no collisions)
--[[
  [90] = 0,    -- spring extended: top-left part (we only collide with bottom)
  [91] = 0,    -- spring extended: top-right part (we only collide with bottom)
--]]
  [202] = 30,  -- spring oriented left representative tile (still collides to avoid "falling inside")
  [173] = 31,  -- spring oriented right representative tile (still collides to avoid "falling inside")

-- rock
-- (only left parts have partial colliders)
  [168] = 28,  -- rock (top-left part)
  [92]  = 29,  -- rock (top-middle part)
  [93]  = 29,  -- rock (top-right part)
  [184] = 28,  -- rock (small rock bottom-left part, can be connected to medium rock extension)
  [108] = 29,  -- rock (small rock bottom-middle part, can be connected to medium rock extension)
  [109] = 29,  -- rock (small rock bottom-right part, can be connected to medium rock extension)
  [169] = 28,  -- rock (medium rock bottom-left part, can be connected to big rock extension)
  [190] = 29,  -- rock (medium rock bottom-middle part, can be connected to big rock extension)
  [191] = 29,  -- rock (medium rock bottom-right part, can be connected to big rock extension)
  [185] = 28,  -- rock (big rock extension top-left part)
  [206] = 29,  -- rock (big rock extension top-middle part)
  [207] = 29,  -- rock (big rock extension top-right part)
  [186] = 28,  -- rock (big rock bottom-left part)
  [122] = 29,  -- rock (big rock bottom-middle part)
  [123] = 29,  -- rock (big rock bottom-right part)

-- loop (collider only)

-- loop parts: bottom (from left to right)
  [96] = 16,
  [97] = 17,
  [98] = 18,
  [99] = 19,
  [100] = 20,
  [101] = 21,

-- loop parts: right (from bottom to top)
  [118] = 38,
  [102] = 22,
  [119] = 39,
  [103] = 23,

-- loop parts: top (from left to right)
  [112] = 32,
  [113] = 33,
  [114] = 34,
  [115] = 35,
  [116] = 36,
  [117] = 37,

-- loop parts: left (from top to right)
  [104] = 24,
  [120] = 40,
  [105] = 25,
  [121] = 41,

-- launch ramp
  -- note that the edge is one-way in Sonic 3, but we only have solid platforms for now,
  --  so we need to define colliders even for the edge of the lower row (244, 245)

  -- lower row
  [240] = 8,
  [241] = 9,
  [242] = 10,
  [243] = 11,
  [244] = 29,
  [245] = 32,
  -- upper row
  [228] = 19,
  [229] = 20,

-- decorative tiles (no collision, but kept commented for tracking purpose)
--[[
  [234] = 0,  -- hiding leaves

-- grass top decorations
  [76] = 0,
  [77] = 0,
  [78] = 0,

  [79] = 0,   -- mouse cursor (#mouse only)
  [81] = 0,   -- ledge grass left
  [82] = 0,   -- ledge grass right
  [122] = 0,  -- emerald core part (custom collision detection for pick-up)
  [123] = 0,  -- emerald right part (just a small bit)
  [126] = 0,  -- falling leaves (pattern 1)
  [127] = 0,  -- falling leaves (pattern 2)
--]]
}

-- convert angle and mask information into complete tile collision data table
-- ! this is an actual operation done outside function scope, and therefore executed
--   at require time. In practice, the ingame cartridge indirectly requires collision_data
--   (via picosonic_app_ingame > stage_state > player_char > world)
--   so this will be initialized on game start, which is perfect for us as the initial
--   spritesheet is loaded at that point, and it contains all the collision masks
-- doing this later, after background data cartridge reload (in stage on_enter)
--  would fail, as the collision mask sprites would be overwritten by the runtime background
--  sprites (only meant to be drawn programmatically)
-- could probably be done via transform too
local tiles_collision_data = {}
for sprite_id, mask_tile_id in pairs(mask_tile_ids) do
  tiles_collision_data[sprite_id] = tile_collision_data.from_raw_tile_collision_data(mask_tile_id, mask_tile_angles[mask_tile_id])
end

-- proxy getter is only here to make stubbing possible in tile_test_data
collision_data.get_tile_collision_data = function (sprite_id)
  return tiles_collision_data[sprite_id]
end

return collision_data

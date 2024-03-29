local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")

-- sdt: sprite_data_table
-- OPTIMIZE CHARS: only spring_jump has different span, so we could default to {2, 2} if passing "nil" or 0
local sdt = transform(
  -- anim_name below is not protected since accessed via minified member to define animations more below
  --anim_name = sprite_data(
  --                    id_loc,  span,   pivot, transparent_color = colors.pink)
  {
    idle             = {{12, 8}, {2, 2}, {10, 8}},
    walk1            = {{0,  8}, {2, 2}, { 8, 8}},
    walk2            = {{2,  8}, {2, 2}, { 8, 8}},
    walk3            = {{4,  8}, {2, 2}, { 9, 8}},
    walk4            = {{6,  8}, {2, 2}, { 8, 8}},
    walk5            = {{8,  8}, {2, 2}, { 8, 8}},
    walk6            = {{10, 8}, {2, 2}, { 8, 8}},
    brake1           = {{10, 8}, {2, 2}, { 9, 8}},
    brake2           = {{12, 8}, {2, 2}, { 9, 8}},
    brake3           = {{14, 8}, {2, 2}, {11, 8}},
    spring_jump      = {{14, 8}, {2, 3}, { 9, 8}},
    run1             = {{0,  8}, {2, 2}, { 8, 8}},
    run2             = {{2,  8}, {2, 2}, { 8, 8}},
    run3             = {{4,  8}, {2, 2}, { 8, 8}},
    run4             = {{6,  8}, {2, 2}, { 8, 8}},
    spin_full_ball   = {{0,  8}, {2, 2}, { 6, 6}},
    spin1            = {{2,  8}, {2, 2}, { 6, 6}},
    spin2            = {{4,  8}, {2, 2}, { 6, 6}},
    spin3            = {{6,  8}, {2, 2}, { 6, 6}},
    spin4            = {{8,  8}, {2, 2}, { 6, 6}},
    crouch1          = {{12, 8}, {2, 2}, { 7,10}},
    crouch2          = {{14, 8}, {2, 2}, { 7,10}},
    spin_dash_shrink = {{0,  8}, {2, 2}, { 3,10}},
    spin_dash1       = {{2,  8}, {2, 2}, { 3,10}},
    spin_dash2       = {{4,  8}, {2, 2}, { 3,10}},
    spin_dash3       = {{6,  8}, {2, 2}, { 3,10}},
    spin_dash4       = {{8,  8}, {2, 2}, { 3,10}},
--#if landing_anim
    landing          = {{10, 8}, {2, 2}, { 8, 8}},
--#endif
  }, function (raw_data)
    return sprite_data(
      sprite_id_location(raw_data[1][1], raw_data[1][2]),  -- id_loc
      tile_vector(raw_data[2][1], raw_data[2][2]),         -- span
      vector(raw_data[3][1], raw_data[3][2]),              -- pivot
      colors.pink                                   -- transparent_color
    )
end)

-- define animated sprite data in a second step, as it needs sprite data to be defined first
-- note that we do not split spin_slow and spin_fast as distinguished by SPG anymore
--  in addition, while spin_slow was defined to have 1 spin_full_ball frame and
--  spin_fast had 2, our spin has 4, once every other frame, to match Sonic 3 more closely
-- asdt: animated_sprite_data_table
local asdt = transform(
  -- access sprite data by non-protected member to allow minification
  -- see animated_sprite_data.lua for anim_loop_modes values
  --[anim_name] = animated_sprite_data(
  --           sprite_keys,     step_frames, loop_mode as int)
  {
    ["idle"] = {{sdt.idle},               1,                2},
    ["walk"] = {{sdt.walk1, sdt.walk2, sdt.walk3, sdt.walk4, sdt.walk5, sdt.walk6},
                                         10,                4},
    ["brake_start"]   = {{sdt.brake1, sdt.brake2},
                                         10,                2},
    ["brake_reverse"] = {{sdt.brake3},
                                         15,                2},
    ["run"]  = {{sdt.run1, sdt.run2, sdt.run3, sdt.run4},
                                          5,                4},
    ["spin"] = {{sdt.spin_full_ball, sdt.spin1, sdt.spin_full_ball, sdt.spin2, sdt.spin_full_ball,
                 sdt.spin3, sdt.spin_full_ball, sdt.spin4},
                                          5,                4},
    ["crouch"] = {{sdt.crouch1, sdt.crouch2},
                                          6,                2},
    ["spring_jump"] = {{sdt.spring_jump}, 1,                2},
    ["spin_dash"] = {{sdt.spin_dash_shrink, sdt.spin_dash1, sdt.spin_dash_shrink, sdt.spin_dash2, sdt.spin_dash_shrink,
                 sdt.spin_dash3, sdt.spin_dash_shrink, sdt.spin_dash4},
                                          1,                4},
--#if landing_anim
    ["landing"] = {{sdt.landing},         1,                2},
--#endif
}, function (raw_data)
  return animated_sprite_data(raw_data[1], raw_data[2], raw_data[3])
end)

local pc_sprite_data = {
  sonic_sprite_data_table = sdt,
  sonic_animated_sprite_data_table = asdt
}

return pc_sprite_data

local animated_sprite_data = require("engine/render/animated_sprite_data")
local sprite_data = require("engine/render/sprite_data")

local visual = {
  -- springs are drawn directly via tilemap, so id is enough to play extend anim
  spring_left_id = 74,                   -- add 1 to get right, must match value in tile_representation
  spring_extended_bottom_left_id = 106,  -- add 1 to get right
  spring_extended_top_left_id = 90,      -- add 1 to get right

  -- palm tree top representative tile is drawn via tilemap, so id is enough
  --  for extension sprites drawn around it, see sprite_data_t.palm_tree_leaves*
  palm_tree_leaves_core_id = 236,

  -- launch ramp last tile
  launch_ramp_last_tile_id = 229,

  -- goal plate base id (representative tile used to generate animated sprite)
  goal_plate_base_id = 226,

  -- emerald color palettes (apply to red emerald sprite to get them all)
  emerald_colors = {
    -- light color, dark color
    {colors.red, colors.dark_purple},
    {colors.peach, colors.orange},
    {colors.pink, colors.dark_purple},
    {colors.indigo, colors.dark_gray},
    {colors.blue, colors.dark_blue},
    {colors.green, colors.dark_green},
    {colors.yellow, colors.orange},
    {colors.orange, colors.brown},
  }
}

local sprite_data_t = {
  -- COMMON INITIAL SPRITES
--#if mouse
  cursor = sprite_data(sprite_id_location(15, 4), nil, nil, colors.pink),
--#endif
  menu_cursor = sprite_data(sprite_id_location(1, 0), nil, nil, colors.pink),
  emerald = sprite_data(sprite_id_location(10, 7), tile_vector(2, 1), vector(4, 4), colors.pink),
  -- palm tree extension sprites
  -- top pivot is located at top-left of core
  palm_tree_leaves_top = sprite_data(sprite_id_location(12, 12), tile_vector(1, 2), vector(0, 16), colors.pink),
  -- right side pivot is located at top-right of core
  -- left side is a mirror of right side, and must be placed just on the left of the core
  palm_tree_leaves_right = sprite_data(sprite_id_location(13, 12), tile_vector(3, 4), vector(0, 16), colors.pink),

  -- RUNTIME SPRITES (stage-specific and common runtime)
  -- below need runtime sprites to be reloaded, overwriting collision masks
  background_forest_bottom_hole = sprite_data(sprite_id_location(1, 0), tile_vector(2, 3), vector(0, 0), colors.pink),
  emerald_silhouette = sprite_data(sprite_id_location(10, 0), tile_vector(2, 1), vector(4, 4), colors.pink),
  emerald_pick_fx1 = sprite_data(sprite_id_location(12, 0), tile_vector(1, 1), vector(4, 4), colors.pink),
  emerald_pick_fx2 = sprite_data(sprite_id_location(13, 0), tile_vector(1, 1), vector(4, 4), colors.pink),
  emerald_pick_fx3 = sprite_data(sprite_id_location(14, 0), tile_vector(1, 1), vector(4, 4), colors.pink),
  emerald_pick_fx4 = sprite_data(sprite_id_location(15, 0), tile_vector(1, 1), vector(4, 4), colors.pink),

  goal_plate_goal = sprite_data(sprite_id_location(3, 0), tile_vector(3, 2), vector(12, 16), colors.pink),
  goal_plate_sonic = sprite_data(sprite_id_location(6, 0), tile_vector(3, 2), vector(12, 16), colors.pink),
  goal_plate_rotating_90 = sprite_data(sprite_id_location(0, 1), tile_vector(1, 2), vector(4, 16), colors.pink),

  -- rotating goal plates at 45 degrees are exceptions and placed in the common area despite only being used at runtime
  --  this is simply because there was no space left for sprites 2-tile high in the runtime area; hence the high location j
  goal_plate_rotating_45_ccw = sprite_data(sprite_id_location(6, 14), tile_vector(2, 2), vector(7, 16), colors.pink),
  goal_plate_rotating_45_cw = sprite_data(sprite_id_location(8, 14), tile_vector(2, 2), vector(8, 16), colors.pink),
}

-- derived data: the representative sprite of an emerald (the one placed on the tilemap)
--  in the left part of the sprite, so convert id location (which is at top-left) to sprite ID
visual.emerald_repr_sprite_id = sprite_data_t.emerald.id_loc:to_sprite_id()

visual.animated_sprite_data_t = {
  emerald_pick_fx = {
    -- manual construction via sprite direct access appears longer than animated_sprite_data.create in code,
    --  but this will actually be minified and therefore very compact (as names are not protected)
    ["once"] = animated_sprite_data(
      {
        sprite_data_t.emerald_pick_fx1,
        sprite_data_t.emerald_pick_fx2,
        sprite_data_t.emerald_pick_fx3,
        sprite_data_t.emerald_pick_fx4
      },
      5,
      2  -- anim_loop_modes.freeze_last (just to sport forgotten fx clear easily)
    )
  }
}

visual.sprite_data_t = sprite_data_t

return visual

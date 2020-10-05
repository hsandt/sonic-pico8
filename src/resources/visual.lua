local sprite_data = require("engine/render/sprite_data")

local visual = {
  -- springs are drawn directly via tilemap, so id is enough to play extend anim
  spring_left_id = 74,                   -- add 1 to get right
  spring_extended_bottom_left_id = 106,  -- add 1 to get right
  spring_extended_top_left_id = 90,      -- add 1 to get right

  -- palm tree top representative tile is drawn via tilemap, so id is enough
  --  for extension sprites drawn around it, see sprite_data_t.palm_tree_leaves*
  palm_tree_leaves_core_id = 236,

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
  -- below need runtime sprites to be reloaded, overwriting collision masks
  background_forest_bottom_hole = sprite_data(sprite_id_location(1, 0), tile_vector(2, 3), vector(0, 0), colors.pink),
  emerald_silhouette = sprite_data(sprite_id_location(10, 0), tile_vector(2, 1), vector(4, 4), colors.pink),
}

visual.sprite_data_t = sprite_data_t

return visual

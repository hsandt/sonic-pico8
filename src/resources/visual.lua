local sprite_data = require("engine/render/sprite_data")

local visual = {
  -- springs are drawn directly via tilemap, so id is enough to play extend anim
  spring_left_id = 74,                   -- add 1 to get right
  spring_extended_bottom_left_id = 106,  -- add 1 to get right
  spring_extended_top_left_id = 90,      -- add 1 to get right

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
}

visual.sprite_data_t = sprite_data_t

return visual

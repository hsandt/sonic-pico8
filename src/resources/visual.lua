local sprite_data = require("engine/render/sprite_data")

local visual = {
  -- springs are drawn directly via tilemap, so id is enough to play extend anim
  spring_normal_sprite_id = 4,
  spring_extend_sprite_id = 5,

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
  cursor = sprite_data(sprite_id_location(1, 0), nil, nil, colors.pink),
--#endif
  menu_cursor = sprite_data(sprite_id_location(1, 0), nil, nil, colors.pink),
  emerald = sprite_data(sprite_id_location(4, 1), tile_vector(2, 1), vector(4, 4), colors.pink),
}

visual.sprite_data_t = sprite_data_t

return visual

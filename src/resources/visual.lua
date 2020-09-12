local sprite_data = require("engine/render/sprite_data")

local visual = {
  -- springs are drawn directly via tilemap, so id is enough to play extend anim
  spring_normal_sprite_id = 4,
  spring_extend_sprite_id = 5,
}

local sprite_data_t = {
--#if mouse
  cursor = sprite_data(sprite_id_location(1, 0), nil, nil, colors.pink),
--#endif
  emerald = sprite_data(sprite_id_location(4, 1), tile_vector(2, 1), vector(4, 3), colors.pink),
}

visual.sprite_data_t = sprite_data_t

return visual

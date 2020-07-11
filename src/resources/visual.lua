local sprite_data = require("engine/render/sprite_data")

local visual = {}

local sprite_data_t = {
--#if mouse
  cursor = sprite_data(sprite_id_location(1, 0))
--#endif
}

visual.sprite_data_t = sprite_data_t

return visual

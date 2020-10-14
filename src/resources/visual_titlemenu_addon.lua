local visual = require("resources/visual_common")

require("engine/core/table_helper")
local sprite_data = require("engine/render/sprite_data")

-- visuals for titlemenu only
-- it uses the add-on system, which means you only need to require it along with visual_common,
--  but only get the return value of visual_common named `visual` here
-- it will automatically add extra information to `visual`
local titlemenu_sprite_data_t = {
  menu_cursor = sprite_data(sprite_id_location(1, 0), tile_vector(2, 1), vector(8, 5), colors.pink),
  title_logo = sprite_data(sprite_id_location(0, 3), tile_vector(14, 10), nil, colors.pink),
}

merge(visual.sprite_data_t, titlemenu_sprite_data_t)

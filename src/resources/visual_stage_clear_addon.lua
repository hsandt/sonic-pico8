local visual = require("resources/visual_common")

local sprite_data = require("engine/render/sprite_data")

-- visuals for stage_clear only
-- it uses the add-on system, which means you only need to require it along with visual_common,
--  but only get the return value of visual_common named `visual` here
-- it will automatically add extra information to `visual`
local menu_sprite_data_t = {
  -- stage clear spritesheet is pretty busy as it must contain stage tiles, so we had to move menu cursor
  --  sprites to a different location than in titlemenu, that we define in this stage_clear-specific add-on
  menu_cursor = sprite_data(sprite_id_location(10, 0), tile_vector(2, 1), vector(8, 5), colors.pink),
}

merge(visual.sprite_data_t, menu_sprite_data_t)

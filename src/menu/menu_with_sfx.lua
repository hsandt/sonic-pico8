local menu = require("menu/menu")
local audio = require("resources/audio")

local menu_with_sfx = derived_class(menu)

function menu_with_sfx:on_selection_changed()  -- override
  -- audio
  sfx(audio.sfx_ids.menu_select)
end

function menu_with_sfx:on_confirm_selection()  -- override
  -- audio
  sfx(audio.sfx_ids.menu_confirm)
end

return menu_with_sfx

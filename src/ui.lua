local visual = require("visual")
local input = require("input")

local ui = {}

local function draw_cursor()
  camera(0, 0)
  local cursor_position = input.get_cursor_position()
  visual.sprite_data_t.cursor:render(cursor_position)
end

-- export
ui.draw_cursor = draw_cursor
return ui

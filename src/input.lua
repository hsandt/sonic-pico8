require("math")

local input = {}

local mouse_devkit_address = 0x5f2d
local cursor_x_stat = 32
local cursor_y_stat = 33

-- activate mouse devkit
local function toggle_mouse(active)
  value = active and 1 or 0
  poke(mouse_devkit_address, value)
end

-- return the current cursor position
local function get_cursor_position()
  return vector(stat(cursor_x_stat), stat(cursor_y_stat))
end

input.toggle_mouse = toggle_mouse
input.get_cursor_position = get_cursor_position

return input

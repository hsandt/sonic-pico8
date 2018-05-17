require("math")

local input = {}

local mouse_devkit_address = 0x5f2d
local cursor_x_stat = 32
local cursor_y_stat = 33

local button_ids = {
  left = 0,
  right = 1,
  up = 2,
  down = 3,
  o = 4,
  x = 5
}

-- activate mouse devkit
local function toggle_mouse(active)
  value = active and 1 or 0
  poke(mouse_devkit_address, value)
end

-- return the current cursor position
local function get_cursor_position()
  return vector(stat(cursor_x_stat), stat(cursor_y_stat))
end

input.button_ids = button_ids
input.toggle_mouse = toggle_mouse
input.get_cursor_position = get_cursor_position

return input

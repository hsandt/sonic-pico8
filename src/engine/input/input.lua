require("engine/core/math")
-- require("engine/ui/ui")

local input = {
  mouse_active = false
}

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
function input:toggle_mouse(active)
  if active == nil then
    -- no argument => reverse value
    active = not self.mouse_active
  end
  value = active and 1 or 0
  self.mouse_active = active
  poke(mouse_devkit_address, value)
end

-- return the current cursor position
local function get_cursor_position()
  return vector(stat(cursor_x_stat), stat(cursor_y_stat))
end

input.button_ids = button_ids
input.get_cursor_position = get_cursor_position

return input

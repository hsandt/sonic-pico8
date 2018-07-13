require("engine/core/math")
-- require("engine/ui/ui")

local input = {
  active = true,          -- is global input active? true when playing, false during itests
  mouse_active = false    -- is the mouse specifically active? only useful when active is true
}

local mouse_devkit_address = 0x5f2d
local cursor_x_stat = 32
local cursor_y_stat = 33

input.button_ids = {
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
function input.get_cursor_position()
  return vector(stat(cursor_x_stat), stat(cursor_y_stat))
end

return input

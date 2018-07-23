--#if profiler

require("engine/render/color")
local wtk = require("engine/wtk/pico8wtk")

local stats_info = {
  {"memory",     0},
  {"total cpu",  1},
  {"system cpu", 2},
  {"fps",        7},
  {"target fps", 8},
  {"actual fps", 9}
}

-- in order to align all stat values, we will draw them after the longest
-- stat name (+ a small margin)
local max_stat_name_length = 0
for stat_info in all(stats_info) do
  local stat_name = stat_info[1]
  max_stat_name_length = max(max_stat_name_length, #stat_name)
end
local stat_value_char_offset = max_stat_name_length + 1

local profiler = {
  -- has the profiler been lazy initialized?
  initialized = false,

  -- gui root
  gui = nil
}

-- return a callback function to use for stat labels
-- exposed via profiler for testing only
function profiler.get_stat_function(stat_index)
  return function()
    local stat_info = stats_info[stat_index]
    local stat_name = stat_info[1]
    -- pad stat name with spaces until it reaches a fixed length for stat value alignment
    local space_padding_size = stat_value_char_offset - #stat_name
    local space_padding = ""
    for i = 1, space_padding_size do
       space_padding = space_padding.." "
     end
    -- example: "total cpu  0.032"
    return stat_name..space_padding..stat(stat_info[2])
  end
end

function profiler:show()
  if not self.initialized then
    self:init_window()
  end

  self.gui.visible = true
end

function profiler:hide()
  self.gui.visible = false
end

function profiler:init_window()
  self.gui = wtk.gui_root.new()
  self.gui.visible = false
  -- add stat labels to draw with their text callbacks
  for i = 1, #stats_info do
    local stat_label = wtk.label.new(profiler.get_stat_function(i), colors.light_gray)
    self.gui:add_child(stat_label, 1, 1 + 6*(i-1))  -- aligned vertically
  end

  self.initialized = true
end

function profiler:update_window()
  if self.gui then
    self.gui:update()
  end
end

function profiler:render_window()
  if self.gui then
    camera()
    self.gui:draw()
  end
end

return profiler

--#endif

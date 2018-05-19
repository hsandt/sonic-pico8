require("color")
local ui = require("ui")

local stats_info = {
  {"memory",     0},
  {"total cpu",  1},
  {"system cpu", 2},
  {"fps",        7},
  {"target fps", 8},
  {"actual fps", 9}
}

local profiler = {
  -- parameters

  -- should the profiler overlay be rendered? checked in main loop
  active = false,

  -- state vars
  initialized = false,
  stat_overlay = ui.overlay(0)
}

-- hard to test because cpu changes every line
local function get_stat_values()
  local stat_values = {}
  for stat_info in all(stats_info) do
    add(stat_values, stat(stat_info[2]))
  end
  return stat_values
end

function profiler:lazy_init()
  local stat_values = get_stat_values()

  self.initialized = true
  for i= 1, #stat_values do
    -- example: "total cpu   0.032"
    warn(stats_info[i][1])
    self.stat_overlay:add_label(stats_info[i][1], stats_info[i][1], vector(1, 1 + 6*(i-1)), colors.white)
    self.stat_overlay:add_label(stats_info[i][1].." (value)", stat_values[i], vector(45, 1 + 6*(i-1)), colors.white)
  end
end

function profiler:update_stats()
  assert(self.initialized)
  local stat_values = get_stat_values()

  for i= 1, #stat_values do
    -- example: "total cpu -> 0.034"
    self.stat_overlay.labels[stats_info[i][1].." (value)"].text = stat_values[i]
  end
end

function profiler:render()
  if not self.initialized then
    self:lazy_init()
  else
    self:update_stats()
  end

  camera()
  self.stat_overlay:draw_labels()
end

return profiler

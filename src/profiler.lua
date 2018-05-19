require("color")
local ui = require("ui")

local profiler = {
  -- parameters

  -- should the profiler overlay be rendered? checked in main loop
  active = false,

  -- state vars
  initialized = false,
  stat_overlay = ui.overlay(0)
}

-- hard to test because cpu changes every line
local function get_stats()
  return stat(0), stat(1), stat(2)
end

function profiler:lazy_init()
  local memory, total_cpu, system_cpu = get_stats()

  self.initialized = true
  self.stat_overlay:add_label("memory", memory, vector(10, 10), colors.white)
  self.stat_overlay:add_label("total cpu", total_cpu, vector(10, 16), colors.white)
  self.stat_overlay:add_label("system cpu", system_cpu, vector(10, 22), colors.white)
end

function profiler:update_stats()
  assert(self.initialized)
  local memory, total_cpu, system_cpu = get_stats()

  self.stat_overlay.labels["memory"].text = memory
  self.stat_overlay.labels["total cpu"].text = total_cpu
  self.stat_overlay.labels["system cpu"].text = system_cpu
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

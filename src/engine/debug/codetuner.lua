--#if tuner

require("engine/core/class")
require("engine/render/color")
local wtk = require("engine/wtk/pico8wtk")

-- code tuner: a debug utility that allows to tune
--   any value in code by using a small widget on screen
-- usage:
--   where you need to test different numerical values in your code,
--     use `tuned("my var", default_value)` instead of `default_value`
--   then, in game, in a build config that defines `tuner` symbol,
--     use the number selection widget for entry "my var" to tune it
local codetuner = singleton(function (self)
    -- parameters

    -- if true, tuned values are used, else default values are used
    self.active = false

    -- state vars

    -- table of tuned variables, identified by their names
    self.tuned_vars = {}

    -- gui
    self.gui = nil
    self.main_panel = nil
end)

-- utilities from widget toolkit demo

-- return a new position on the right of a widget w at position (x, y), of width w, plus a margin dist
function codetuner.next_to(w, dist)
 return w.x+w.w+(dist or 2), w.y
end

-- return a new position below a widget w at position (x, y), of height h, plus a margin dist
function codetuner.below(w, dist)
 return w.x, w.y+w.h+(dist or 2)
end

-- todo: use this struct for easier variable handling
-- tuned variable struct, represents a variable to tune in the code tuner
-- currently unused, it will replace the free vars in codetuner.tuned_vars
-- to provide better information (type, range, default value)
codetuner.tuned_variable = new_struct()

-- name           string   tuned variable identifier
-- default_value  any      value used for tuned variable if codetuner is inactive
function codetuner.tuned_variable:_init(name, default_value)
  self.name = name
  self.default_value = default_value
end

-- return a string with format: tuned_variable "{name}" (default: {default_value})
function codetuner.tuned_variable:_tostring(name, default_value)
  return "tuned_variable \""..self.name.."\" (default: "..self.default_value..")"
end

-- return a function callback for the spinner, that sets the corresponding tuned variable
-- exposed via codetuner for testing
function codetuner:get_spinner_callback(tuned_var_name)
  return function (spinner)
    self:set_tuned_var(tuned_var_name, spinner.value)
  end
end

-- if codetuner is active, retrieve tuned var or create a new one with default value if needed
-- if codetuner is inactive, return default value
function codetuner:get_or_create_tuned_var(name, default_value)
  if self.active then
    -- booleans may be used, so always compare to nil
    if self.tuned_vars[name] == nil then
      self:create_tuned_var(name, default_value)
    end
    return self.tuned_vars[name]
  else
    return default_value
  end
end

function codetuner:create_tuned_var(name, default_value)
  self.tuned_vars[name] = default_value

  -- register to ui
  local tuning_spinner = wtk.spinner.new(-100, 100, default_value, 1, self:get_spinner_callback(name))
  local next_pos_x, next_pos_y
  if #self.main_panel.children > 0 then
    next_pos_x, next_pos_y = codetuner.below(self.main_panel.children[#self.main_panel.children])
  else
    next_pos_x, next_pos_y = 1, 1
  end
  self.main_panel:add_child(tuning_spinner, next_pos_x, next_pos_y)
end

-- set tuned variable, even if codetuner is inactive
-- fails with warning if name doesn't exist
function codetuner:set_tuned_var(name, value)
  if self.tuned_vars[name] ~= nil then
    self.tuned_vars[name] = value
  else
    warn("codetuner:set_tuned_var: no tuned var found with name: "..tostr(name), "codetuner")
  end
end

-- short global alias for codetuner:get_or_create_tuned_var
function tuned(name, default_value)
  return codetuner:get_or_create_tuned_var(name, default_value)
end

function codetuner:show()
  self.gui.visible = true
end

function codetuner:hide()
  self.gui.visible = false
end

function codetuner:init_window()
  self.gui = wtk.gui_root.new()
  self.gui.visible = false
  self.main_panel = wtk.panel.new(1, 1, colors.dark_gray, true)
  self.gui:add_child(self.main_panel)
end

function codetuner:update_window()
  self.gui:update()
end

function codetuner:render_window()
  self.gui:draw()
end

-- always initialize window on start so we can add widgets for tuned variables
-- at any time, even if the window is not shown
codetuner:init_window()

--#endif

-- prevent busted from parsing both versions of codetuner
--[[#pico8

--#ifn tuner

local codetuner = {}

-- if tuner is disabled, use default value
function tuned(name, default_value)
  return default_value
end

--#endif

--#pico8]]

return codetuner

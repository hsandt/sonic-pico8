require("engine/debug/debug")
local flow = require("engine/application/flow")
local titlemenu = require("game/menu/titlemenu")
local credits = require("game/menu/credits")
local stage = require("game/ingame/stage")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")
local profiler = require("engine/debug/profiler")
local codetuner = require("engine/debug/codetuner")

-- config
profiler:show()
-- codetuner:show()
-- codetuner.active = true

-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  input.toggle_mouse(true)

  flow:add_gamestate(titlemenu.state)
  flow:add_gamestate(credits.state)
  flow:add_gamestate(stage.state)
  flow:query_gamestate_type(titlemenu.state.type)
end

function _update60()
  flow:update()
  profiler:update_window()
  codetuner:update_window()
end

function _draw()
  cls()
  flow.current_gamestate:render()
  profiler:render_window()
  codetuner:render_window()
  ui:render_mouse()
end

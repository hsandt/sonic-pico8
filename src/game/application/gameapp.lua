local flow = require("engine/application/flow")
local codetuner = require("engine/debug/codetuner")
local profiler = require("engine/debug/profiler")
local ui = require("engine/ui/ui")
local credits = require("game/menu/credits")
local stage = require("game/ingame/stage")
local titlemenu = require("game/menu/titlemenu")
local visual = require("game/resources/visual")

local gameapp = {}

function gameapp.init()
--#if debug
  profiler:show()
  codetuner:show()
  codetuner.active = true
--#endif

  ui:set_cursor_sprite_data(visual.sprite_data_t.cursor)

  flow:add_gamestate(titlemenu.state)
  flow:add_gamestate(credits.state)
  flow:add_gamestate(stage.state)
  flow:query_gamestate_type(titlemenu.state.type)
end

function gameapp.update()
  flow:update()
  profiler:update_window()
  codetuner:update_window()
end

function gameapp.draw()
  cls()
  flow:render()
  profiler:render_window()
  codetuner:render_window()
  ui:render_mouse()
end

return gameapp

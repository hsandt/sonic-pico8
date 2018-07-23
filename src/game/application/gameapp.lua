local input = require("engine/input/input")
local flow = require("engine/application/flow")
local credits = require("game/menu/credits")
local stage = require("game/ingame/stage")
local titlemenu = require("game/menu/titlemenu")
local visual = require("game/resources/visual")

--#if tuner
local codetuner = require("engine/debug/codetuner")
--#endif

--#if profiler
local profiler = require("engine/debug/profiler")
--#endif

--#if mouse
local ui = require("engine/ui/ui")
--#endif

local gameapp = {}

function gameapp.init()
--#if mouse
  ui:set_cursor_sprite_data(visual.sprite_data_t.cursor)
--#endif

  flow:add_gamestate(titlemenu.state)
  flow:add_gamestate(credits.state)
  flow:add_gamestate(stage.state)
  flow:query_gamestate_type(titlemenu.state.type)
end

function gameapp.update()
  input:process_players_inputs()
  flow:update()
--#if profiler
  profiler:update_window()
--#endif
--#if tuner
  codetuner:update_window()
--#endif
end

function gameapp.draw()
  cls()
  flow:render()
--#if profiler
  profiler:render_window()
--#endif
--#if tuner
  codetuner:render_window()
--#endif
--#if mouse
  ui:render_mouse()
--#endif
end

return gameapp

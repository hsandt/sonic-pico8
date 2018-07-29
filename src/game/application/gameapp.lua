local flow = require("engine/application/flow")
local input = require("engine/input/input")
local gamestate_proxy = require("game/application/gamestate_proxy")
local gamestate = require("game/application/gamestate")
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

  flow:add_gamestate(gamestate_proxy:get("titlemenu"))
  flow:add_gamestate(gamestate_proxy:get("credits"))
  flow:add_gamestate(gamestate_proxy:get("stage"))
  flow:query_gamestate_type(gamestate.types.titlemenu)
end

function gameapp.update()
  input:process_players_inputs()
  flow:update()
--#if profiler
  profiler.window:update()
--#endif
--#if tuner
  codetuner:update_window()
--#endif
end

function gameapp.draw()
  cls()
  flow:render()
--#if profiler
  profiler.window:render()
--#endif
--#if tuner
  codetuner:render_window()
--#endif
--#if mouse
  ui:render_mouse()
--#endif
end

return gameapp

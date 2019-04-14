local flow = require("engine/application/flow")
local input = require("engine/input/input")
local gamestate_proxy = require("game/application/gamestate_proxy")
local gamestate = require("game/application/gamestate")
local visual = require("game/resources/visual")

--#if log
local logging = require("engine/debug/logging")
-- pico8 doesn't support output file path containing "-" so use "_"
logging.file_log_stream.file_prefix = "sonic_pico8_v2.2"
--#endif

--#if visual_logger
local vlogger = require("engine/debug/visual_logger")
--#endif

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

-- todo: consider making gameapp a singleton with init like the other modules,
--  so we can easily reinit it (implementation would b more a reset than the init
--  below, as it would reinit the flow, etc.)

-- in pico8 builds, pass nothing for active_gamestates
-- in busted tests, pass active_gamestates so they can be required automatically on gameapp init
function gameapp.init(active_gamestates)
--#ifn pico8
 assert(active_gamestates, "gameapp.init: non-pico8 build requires active_gamestates to define them at runtime")
--#endif

--#if mouse
  ui:set_cursor_sprite_data(visual.sprite_data_t.cursor)
--#endif

--#ifn pico8
  gamestate_proxy:require_gamestates(active_gamestates)
--#endif

  for state in all({"titlemenu", "credits", "stage"}) do
    flow:add_gamestate(gamestate_proxy:get(state))
  end
  flow:query_gamestate_type(gamestate.types.titlemenu)
end

--#ifn utest
function gameapp.reinit_modules()
--#if mouse
  ui:set_cursor_sprite_data(nil)
--#endif

--#ifn pico8
  gamestate_proxy:init()
--#endif

  flow:init()
end
--#endif

function gameapp.update()
  input:process_players_inputs()
  flow:update()

--#if visual_logger
  vlogger.window:update()
--#endif

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

--#if visual_logger
  vlogger.window:render()
--#endif

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

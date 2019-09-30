local gameapp = require("engine/application/gameapp")

local flow = require("engine/application/flow")
local gamestate_proxy = require("application/gamestate_proxy")
local visual = require("resources/visual")

--#if log
local logging = require("engine/debug/logging")
-- pico8 doesn't support output file path containing "-" so use "_"
logging.file_log_stream.file_prefix = "sonic_pico8_v2.3"
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

local picosonic_app = derived_class(gameapp)

function picosonic_app:register_gamestates() -- override
  for state in all({"titlemenu", "credits", "stage"}) do
    flow:add_gamestate(gamestate_proxy:get(state))
  end
end

function picosonic_app.on_start() -- override
--#if mouse
  ui:set_cursor_sprite_data(visual.sprite_data_t.cursor)
--#endif

--#if profiler
  profiler.window:fill_stats(colors.light_gray)
--#endif
end

--#if itest
function picosonic_app.on_reset() -- override
--#if mouse
  ui:set_cursor_sprite_data(nil)
--#endif
end
--#endif

function picosonic_app.on_update() -- override
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

function picosonic_app.on_render()
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

return picosonic_app

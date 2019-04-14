local gameapp = require("game/application/gameapp")
local gamestate_proxy = require("game/application/gamestate_proxy")

--#if log
local logging = require("engine/debug/logging")
logging.logger:register_stream(logging.console_log_stream)
logging.logger:register_stream(logging.file_log_stream)
logging.logger.active_categories["trace"] = true

--#if visual_logger
local vlogger = require("engine/debug/visual_logger")
logging.logger:register_stream(vlogger.vlog_stream)
vlogger.window:show()
--#endif

--#endif

--#if profiler
local profiler = require("engine/debug/profiler")
profiler.window:show()
--#endif

-- always require code tuner, since ifn tuned, `tuned` will simply use the default value
local codetuner = require("engine/debug/codetuner")
--#if tuner
codetuner:show()
codetuner.active = true
--#endif

--#if mouse
local input = require("engine/input/input")
input:toggle_mouse(true)
--#endif

-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  -- clear log file on new game session
  logging.file_log_stream:clear()

  -- require all gamestate modules, according to preprocessing step
  gamestate_proxy:require_gamestates()
  gameapp.init()
end

function _update60()
  gameapp.update()
end

function _draw()
  gameapp.draw()
end

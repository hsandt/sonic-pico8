-- main entry file for the game

-- we must require engine/pico8/api at the top of our main.lua, so API bridges apply to all modules
require("engine/pico8/api")

--#if log
local logging = require("engine/debug/logging")
--#endif

--#if visual_logger
local vlogger = require("engine/debug/visual_logger")
--#endif

--#if profiler
local profiler = require("engine/debug/profiler")
--#endif

-- always require code tuner, since ifn tuned, `tuned` will simply use the default value
local codetuner = require("engine/debug/codetuner")

local picosonic_app = require("application/picosonic_app")

local app = picosonic_app()

function _init()
--#if log
  -- start logging before app in case we need to read logs about app start itself
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(logging.file_log_stream)
  logging.logger:register_stream(vlogger.vlog_stream)

  logging.file_log_stream.file_prefix = "picosonic"

  -- clear log file on new game session (or to preserve the previous log,
  -- you could add a newline and some "[SESSION START]" tag instead)
  logging.file_log_stream:clear()

  logging.logger.active_categories = {
    -- engine
    ['default'] = true,
    ['codetuner'] = true,
    ['flow'] = true,
    ['itest'] = true,
    ['log'] = true,
    ['ui'] = true,
    -- ['frame'] = nil,

    -- game
    -- ['...'] = true,
  }
--#endif

--#if visual_logger
  -- uncomment to enable visual logger
  -- vlogger.window:show()
--#endif

--#if profiler
  -- uncomment to enable profiler
  -- profiler.window:show(colors.orange)
--#endif

--#if tuner
  codetuner:show()
  codetuner.active = true
--#endif

  app.initial_gamestate = ':titlemenu'
  app:start()
end

function _update60()
  app:update()
end

function _draw()
  app:draw()
end

-- main entry file for the attract_mode cartridge
--  game states: stage

-- must require at main top, to be used in any required modules from here
require("engine/pico8/api")
require("engine/common")
require("common_attract_mode")

-- require visual add-on for ingame, so any require visual_common
--  in this cartridge will get both common data and ingame data
require("resources/visual_ingame_addon")

-- we also require codetuner so any file can used tuned()
-- if tuner symbol is defined, then we also initialize it in init
local codetuner = require("engine/debug/codetuner")

--#if log
local logging = require("engine/debug/logging")
--#endif

--#if visual_logger
local vlogger = require("engine/debug/visual_logger")
--#endif

--#if profiler
local profiler = require("engine/debug/profiler")
--#endif

local flow = require("engine/application/flow")
local coroutine_runner = require("engine/application/coroutine_runner")

local picosonic_app_attract_mode = require("application/picosonic_app_attract_mode")

local app = picosonic_app_attract_mode()

function _init()
--#if log
  -- start logging before app in case we need to read logs about app start itself
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(logging.file_log_stream)
--#if visual_logger
  logging.logger:register_stream(vlogger.vlog_stream)
--#endif

  logging.file_log_stream.file_prefix = "picosonic_attract_mode"

  -- clear log file on new game session (or to preserve the previous log,
  -- you could add a newline and some "[SESSION START]" tag instead)
  logging.file_log_stream:clear()

  logging.logger.active_categories = {
    -- engine
    -- ['default'] = true,
    -- ['codetuner'] = true,
    -- ['flow'] = true,
    -- ['itest'] = true,
    -- ['log'] = true,
    -- ['ui'] = true,
    -- ['reload'] = true,
    -- ['trace'] = true,
    -- ['trace2'] = true,
    -- ['frame'] = true,

    -- game
    ['recorder'] = true,
    -- ['...'] = true,
  }
--#endif

--#if visual_logger
  -- uncomment to enable visual logger
  -- vlogger.window:show()
--#endif

--#if profiler
  -- uncomment to enable profiler
  profiler.window:show(colors.orange)
--#endif

--#if tuner
  codetuner:show()
  codetuner.active = true
--#endif

  app.initial_gamestate = ':stage'
  app:start()
end

function _update60()
  app:update()
end

function _draw()
  app:draw()
end

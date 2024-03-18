-- main entry file for the stage_clear cartridge
--  game states: stage_clear

-- must require at main top, to be used in any required modules from here
require("engine/common")
require("common_stage_clear")

-- require ingame visual add-on for stage clear since we still show the stage
-- any require visual_common in this cartridge will get both common data and ingame data
require("resources/visual_ingame_addon")
require("resources/visual_stage_clear_addon")

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

local picosonic_app_stage_clear = require("application/picosonic_app_stage_clear")

local app = picosonic_app_stage_clear()

function _init()
--#if log
  -- start logging before app in case we need to read logs about app start itself
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(logging.file_log_stream)
--#if visual_logger
  logging.logger:register_stream(vlogger.vlog_stream)
--#endif

  logging.file_log_stream.file_prefix = "picosonic_stage_clear"

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
    -- ['ui'] = true,
    -- ['goal'] = true,
    -- ['reload'] = true,
    -- ['trace'] = true,
    -- ['trace2'] = true,
    -- ['frame'] = true,

    -- game
    -- ['...'] = true,
  }
--(log)
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

  app.initial_gamestate = ':stage_clear'
  app:start()
end

function _update60()
  app:update()
end

function _draw()
  app:draw()
end

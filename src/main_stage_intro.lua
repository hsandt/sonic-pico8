-- main entry file for the stage_intro cartridge
--  game states: stage_intro

-- must require at main top, to be used in any required modules from here
require("engine/pico8/api")
require("engine/common")
require("common_stage_intro")

-- require ingame visual add-on for stage clear since we already show the stage
-- any require visual_common in this cartridge will get both common data and ingame data
-- in fact, visual_ingame_addon contains sprites unused in stage_intro,
--  but stage_clear cartridge has enough space, so it's okay (worst case, we can strip some of them,
--  or even extract a common addon later)
require("resources/visual_ingame_addon")
-- also require visual_stage_intro_addon for clouds
require("resources/visual_stage_intro_addon")

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

local picosonic_app_stage_intro = require("application/picosonic_app_stage_intro")

local app = picosonic_app_stage_intro()

function _init()
--#if log
  -- start logging before app in case we need to read logs about app start itself
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(logging.file_log_stream)
--#if visual_logger
  logging.logger:register_stream(vlogger.vlog_stream)
--#endif

  logging.file_log_stream.file_prefix = "picosonic_stage_intro"

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
    -- ['trace'] = true,
    -- ['trace2'] = true,
    -- ['frame'] = true,

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
  profiler.window:show(colors.orange)
--#endif

--#if tuner
  codetuner:show()
  codetuner.active = true
--#endif

  app.initial_gamestate = ':stage_intro'
  app:start()
end

function _update60()
  app:update()
end

function _draw()
  app:draw()
end

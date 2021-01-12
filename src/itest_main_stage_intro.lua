-- main source file for all itests, used to run itests in pico8

-- must require at main top, to be used in any required modules from here
require("engine/pico8/api")
require("engine/common")
require("common_stage_intro")

-- require visual add-on for ingame (also used for stage_intro), so any require visual_common
--  in this cartridge will get both common data and ingame data
require("resources/visual_ingame_addon")

local itest_manager = require("engine/test/itest_manager")

--#if log
local logging = require("engine/debug/logging")
--#endif

local picosonic_app_stage_intro = require("application/picosonic_app_stage_intro")

-- set app immediately so during itest registration by require,
--   time_trigger can access app fps
local app = picosonic_app_stage_intro()
itest_manager.itest_run.app = app

-- tag to add require for itest files here
--[[add_require]]

function _init()
--#if log
  -- register log streams to output logs to both the console and the file log
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(logging.file_log_stream)
  logging.file_log_stream.file_prefix = "picosonic_itest_stage_intro"

  -- clear log file on new itest session
  logging.file_log_stream:clear()

  logging.logger.active_categories = {
    -- engine
    ['default'] = true,
    -- ['codetuner'] = nil,
    -- ['flow'] = nil,
    ['itest'] = true,
    -- ['log'] = nil,
    -- ['ui'] = nil,
    ['frame'] = true,
    ['frame2'] = true,
    ['trace'] = true,

    -- game
    -- ['spring'] = true,
    -- ['...'] = true,
  }
--#endif

  picosonic_app_stage_intro.initial_gamestate = ':stage_intro'

  -- start first itest
  itest_manager:init_game_and_start_next_itest()
end

function _update60()
  itest_manager:handle_input()
  itest_manager:update()
end

function _draw()
  itest_manager:draw()
end

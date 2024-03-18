-- main source file for all itests, used to run itests in pico8

-- must require at main top, to be used in any required modules from here
require("engine/common")
require("common_stage_clear")

-- require visual add-on for ingame (also used for stage_clear), so any require visual_common
--  in this cartridge will get both common data and ingame data
-- in fact, visual_ingame_addon contains sprites unused in stage_clear,
--  but stage_clear cartridge has enough space, so it's okay (worst case, we can strip some of them,
--  or even extract a common addon later)
require("resources/visual_ingame_addon")
require("resources/visual_stage_clear_addon")

local itest_manager = require("engine/test/itest_manager")

--#if log
local logging = require("engine/debug/logging")
--#endif

local picosonic_app_stage_clear = require("application/picosonic_app_stage_clear")

-- set app immediately so during itest registration by require,
--   time_trigger can access app fps
local app = picosonic_app_stage_clear()
itest_manager.itest_run.app = app

-- tag to add require for itest files here
--[[add_require]]

function _init()
--#if log
  -- register log streams to output logs to both the console and the file log
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(logging.file_log_stream)
  logging.file_log_stream.file_prefix = "picosonic_itest_stage_clear"

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

  picosonic_app_stage_clear.initial_gamestate = ':stage_clear'

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

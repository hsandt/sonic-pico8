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

local attract_mode_coroutine_runner

-- define everything Sonic must do during the attract mode here
-- it's not 100% correct to do it in main because this relies on flow having entered stage state
--  but since it's the initial state, it should be entered on frame 1 anyway
local function attract_mode_scenario_async()
  -- wait for 1 frame so flow finishes loading the initial state: stage
  --  (yield_delay requires +1 so 2)
  yield_delay(2)

  assert(flow.curr_state, "flow has no current state yet")
  assert(flow.curr_state.type == ':stage')

  local pc = flow.curr_state.player_char
  assert(pc)

  -- normally we should set pc.control_mode to control_modes.puppet
  --  but since we're already stripping player_char:handle_input from #ifn attract_mode,
  --  we don't need to do anything

  -- now do the demonstration!
  -- this is similar to our itest DSL, except the DSL being too expensive in a cartridge
  --  (when combined with ingame code which includes background rendering unlike our itests)
  --  so we just manually set character intention and wait between actions with yield_delay

  -- run to the right at max speed!
  pc.move_intention.x = 1

  -- wait 5s
  app:yield_delay_s(5)

  -- jump
  pc.jump_intention = true

  -- wait 5s
  app:yield_delay_s(5)

  -- end demo, go back to title menu
  load('picosonic_titlemenu')
end

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
    ['default'] = true,
    ['codetuner'] = true,
    ['flow'] = true,
    ['itest'] = true,
    ['log'] = true,
    ['ui'] = true,
    ['reload'] = true,
    -- ['trace'] = true,
    -- ['trace2'] = true,
    -- ['frame'] = true,

    -- game
    -- ['loop'] = true,
    -- ['emerald'] = true,
    -- ['palm'] = true,
    -- ['ramp'] = true,
    -- ['goal'] = true,
    ['spring'] = true,
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

  -- create coroutine runner and start attract mode scenario
  attract_mode_coroutine_runner = coroutine_runner()
  attract_mode_coroutine_runner:start_coroutine(attract_mode_scenario_async)
end

function _update60()
  -- update coroutine so player character receives puppet mode instructions
  attract_mode_coroutine_runner:update_coroutines()

  app:update()
end

function _draw()
  app:draw()
end

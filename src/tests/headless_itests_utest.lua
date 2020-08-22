-- todo: use busted --helper=.../bustedhelper instead of all the bustedhelper requires!
require("test/bustedhelper")
require("engine/test/headless_itest")
require("engine/test/integrationtest")
local logging = require("engine/debug/logging")

local picosonic_app = require("application/picosonic_app")

local app = picosonic_app()
app.initial_gamestate = ':titlemenu'

logging.logger:register_stream(logging.console_log_stream)
logging.logger:register_stream(logging.file_log_stream)
logging.file_log_stream.file_prefix = "picosonic_headless_itests"

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
  -- ['frame'] = nil,

  -- game
  -- ['...'] = true,
}

-- set app immediately so during itest registration by require,
--   time_trigger can access app fps
itest_runner.app = app

-- require *_itest.lua files to automatically register them in the integration test manager
require_all_scripts_in('src', 'itests')

local should_render = check_env_should_render()
if should_render then
  print("[headless itest] enabling rendering")
end

-- uncomment below to randomize seed (doesn't matter too much in picosonic)
-- (busted needs that to give different results each time,
--   while PICO-8 will automatically randomize the seed on start)
-- ! since itests won't give the same results every time, if you want a specific result,
--   you need to force setup some variables (like the next opponent) in your specific itest
-- local random_seed = os.time()
-- print("[headless itest] setting random seed to: "..random_seed)
-- srand(random_seed)

create_describe_headless_itests_callback(app, should_render, describe, setup, teardown, before_each, after_each, it, assert)

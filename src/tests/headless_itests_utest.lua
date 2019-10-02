-- todo: use busted --helper=.../bustedhelper instead of all the bustedhelper requires!
require("engine/test/bustedhelper")
require("engine/test/headless_itest")
local picosonic_app = require("application/picosonic_app")

-- require *_itest.lua files to automatically register them in the integration test manager
require_all_scripts_in('src', 'itests')

local app = picosonic_app()
app.initial_gamestate = ':main_menu'

create_describe_headless_itests_callback(app, describe, setup, teardown, it, assert)

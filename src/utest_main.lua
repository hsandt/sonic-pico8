-- main source file to run a unit test in pico8
-- this is really useful for data tests and pico8 fixed-point math tests,
--  otherwise busted tests should be enough
-- each utest should be put inside the src/utests folder with the name utest{something}.lua

-- must require at main top, to be used in any required modules from here
require("engine/common")
-- utest_main is neutral, but we might as well require common_ingame which has
--  more stuff than common_titlemenu
require("common_ingame")

-- same, utest_main is neutral, but right now we're testing ingame tiles
--  so if we have to use visual at some point, requiring the ingame add-on
--  is probably more useful than the titlemenu/stage_clear add-on
require("resources/visual_ingame_addon")

local p8utest = require("engine/test/p8utest")
-- tag to add require for pico8 utests files (should be in utests/)
--[[add_require]]

--#if log
local logging = require("engine/debug/logging")
logging.logger:register_stream(logging.console_log_stream)
--#endif

function _init()
  p8utest.utest_manager:run_all_tests()
end

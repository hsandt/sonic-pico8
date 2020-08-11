-- main source file to run a unit test in pico8
-- this is really useful for data tests and pico8 fixed-point math tests,
--  otherwise busted tests should be enough
-- each utest should be put inside the src/utests folder with the name utest{something}.lua

-- must require at main top, to be used in any required modules from here
require("engine/pico8/api")
require("engine/common")

local unittest = require("engine/test/unittest")
local utest_manager, unit_test = unittest.utest_manager, unittest.unit_test
-- tag to add require for pico8 utests files (should be in utests/)
--[[add_require]]

--#if log
local logging = require("engine/debug/logging")
logging.logger:register_stream(logging.console_log_stream)
--#endif

function _init()
  utest_manager:run_all_tests()
end

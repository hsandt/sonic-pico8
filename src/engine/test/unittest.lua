require("engine/core/class")
require("engine/test/unittest_helper")

local unittest = {}

-- unit test framework mimicking some busted features
--  for direct use in pico8 headless
-- busted features supported: "it" as "check" (immediate assert, no collection of test results)


-- unit test manager: registers all utests and runs them
-- utests   [utest]   registered utests
utest_manager = singleton(function (self)
  self.utests = {}
end)
unittest.utest_manager = utest_manager

function utest_manager:register(utest)
  add(self.utests, utest)
end

function utest_manager:run_all_tests()
  for utest in all(self.utests) do
    utest.callback()
  end
end

-- unit test class for pico8
local unit_test = new_class()
unittest.unit_test = unit_test

-- parameters
-- name        string     test name
-- callback    function   test callback, containing assertions
function unit_test:_init(name, callback)
  self.name = name
  self.callback = callback
end

-- busted-like shortcut functions

function check(name, callback)
  local utest = unit_test(name, callback)
  utest_manager:register(utest)
end

return unittest

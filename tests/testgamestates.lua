picotest = require("picotest")

require("testcredits")
require("testflow")
require("teststage")
require("testtitlemenu")

function run_all_tests()
  picotest.test('all', function(desc,it)
    for test_callback in all(picotest.test_suite) do
      test_callback(desc,it)
    end
  end)
end

function _init()
  run_all_tests()
end

-- empty update allows to close test window with ctrl+c on success
function _update()
end

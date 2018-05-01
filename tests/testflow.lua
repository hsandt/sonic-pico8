picotest = require("picotest")
flow = require("src/flow")

function run_test()
 picotest.test('titlemenu', test_callback)
end

function test_callback(desc,it)
 desc('flow.titlemenu_state.state_type', function()
  it('should be titlemenu', function()
   return flow.titlemenu_state.state_type == flow.gamestate_type.titlemenu
  end)
 end)
end

add(picotest.test_suite, test_callback)

-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
 run_test()
end

-- empty update allows to close test window with ctrl+c
function _update()
end

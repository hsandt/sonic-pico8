picotest = require("picotest")
main = require("src/main")

function run_test()
 picotest.test('gamestates', test_callback)
end

function test_callback(desc,it)
 desc('main.add_gamestate', function ()
  it('should add a gamestate by type key', function ()
   add_gamestate(flow.titlemenu_state)
   return gamestates[flow.titlemenu_state.state_type] == flow.titlemenu_state
  end)
 end)
 desc('main.change_state', function ()
  it('should enter a gamestate by type', function ()
   change_state(flow.titlemenu_state.state_type)
   return current_gamestate == gamestates[flow.titlemenu_state.state_type]
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

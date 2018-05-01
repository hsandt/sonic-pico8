picotest = require("picotest")
flow = require("src/flow")
titlemenu = require("src/titlemenu")

function run_test()
 picotest.test('gamestates', test_gamestates)
end

function test_gamestates(desc,it)
 desc('flow.add_gamestate', function ()
  it('should add a gamestate by type key', function ()
   if titlemenu.state then
    add_gamestate(titlemenu.state)
    local result = gamestates[titlemenu.state.state_type] == titlemenu.state
    gamestates[titlemenu.state.state_type] = nil
    return result
   end
   return false
  end)
 end)
 desc('[after flow.add_gamestate] flow.change_state', function ()
  it('should enter a gamestate by type', function ()
   add_gamestate(titlemenu.state)
   change_state(titlemenu.state.state_type)
   return current_gamestate == gamestates[titlemenu.state.state_type]
  end)
 end)
end

add(picotest.test_suite, test_gamestates)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
 run_test()
end

-- empty update allows to close test window with ctrl+c
function _update()
end

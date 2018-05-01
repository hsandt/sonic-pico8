picotest = require("picotest")
titlemenu = require("src/titlemenu")

function run_test()
 picotest.test('titlemenu', titlemenu)
end

function test_titlemenu(desc,it)
 desc('titlemenu.state.type', function ()
  it('should be gamestate_type.titlemenu', function ()
   return titlemenu.state.type == gamestate_type.titlemenu
  end)
 end)
end

add(picotest.test_suite, test_titlemenu)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
 run_test()
end

-- empty update allows to close test window with ctrl+c
function _update()
end

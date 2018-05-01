picotest = require("picotest")
credits = require("src/credits")

function run_test()
 picotest.test('credits', credits)
end

function test_credits(desc,it)
 desc('credits.state.state_type', function ()
  it('should be flow.gamestate_type.credits', function ()
   return credits.state.state_type == flow.gamestate_type.credits
  end)
 end)
end

add(picotest.test_suite, test_credits)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
 run_test()
end

-- empty update allows to close test window with ctrl+c
function _update()
end

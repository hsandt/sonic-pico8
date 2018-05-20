picotest = require("picotest")
require("game/application/gamestates")
credits = require("game/menu/credits")

function test_credits(desc,it)
 desc('credits.state.type', function ()
  it('should be gamestate_types.credits', function ()
   return credits.state.type == gamestate_types.credits
  end)
 end)
end

add(picotest.test_suite, test_credits)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
 picotest.test('credits', test_credits)
end

-- empty update allows to close test window with ctrl+c
function _update()
end

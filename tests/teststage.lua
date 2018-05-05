picotest = require("picotest")
stage = require("stage")

function test_stage(desc,it)
 desc('stage.state.type', function ()
  it('should be gamestate_type.stage', function ()
   return stage.state.type == gamestate_type.stage
  end)
 end)
end

add(picotest.test_suite, test_stage)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
 picotest.test('stage', test_stage)
end

-- empty update allows to close test window with ctrl+c
function _update()
end

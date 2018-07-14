require("engine/test/integrationtest")
local debug = require("engine/debug/debug")
local gameapp = require("game/application/gameapp")
local flow = require("engine/application/flow")
local stage = require("game/ingame/stage")

function setup()
  -- we still need on_enter to spawn character
  flow:_change_gamestate(stage.state)
  stage.state.player_character.position = vector(0., 80.)
  stage.state.player_character.control_mode = control_modes.puppet
end

function define_itest()
  local itest = integration_test('character debug moves to right')
  itest.setup = setup
  -- player char starts moving to the right
  itest:add_action(time_trigger(0.), function ()
    stage.state.player_character.move_intention = vector(1., 0.)
  end)
  -- stop after 1 second
  itest:add_action(time_trigger(1.), function () end)
  -- check that player char has moved a little to the right (integrate accel)
  itest.final_assertion = function ()
    return almost_eq_with_message(vector(57, 80.), stage.state.player_character.position, 0.5)
  end
  return itest
end

function _init()
  gameapp.init()
  integration_test_runner:start(define_itest())
  -- factorize
  if integration_test_runner.current_result ~= test_result.none then
    log("(on start) itest '"..integration_test_runner.current_test.name.."' ended with result: "..integration_test_runner.current_result, "itest")
  end
end

function _update60()
  if integration_test_runner.current_result == test_result.none then
    gameapp.update()
    integration_test_runner:update()
    if integration_test_runner.current_result ~= test_result.none then
      log("itest '"..integration_test_runner.current_test.name.."' ended with result: "..integration_test_runner.current_result, "itest")
    end
  end
end

function _draw()
  gameapp.draw()
end

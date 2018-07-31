-- gamestates: stage
require("engine/test/integrationtest")
local flow = require("engine/application/flow")
local stage = require("game/ingame/stage")  -- required

local itest = integration_test('character debug moves to right', {stage.state.type})


itest.setup = function ()
  -- we still need on_enter to spawn character
  flow:change_gamestate_by_type(gamestate.types.stage)
  stage.state.player_character.position = vector(0., 80.)
  stage.state.player_character.control_mode = control_modes.puppet
end

-- player char starts moving to the right
itest:add_action(time_trigger(0.), function ()
  stage.state.player_character.move_intention = vector(1., 0.)
end)
-- stop after 1 second
itest:add_action(time_trigger(1.), function () end)

-- check that player char has moved a little to the right (integrate accel)
itest.final_assertion = function ()
  -- 56.7185 in PICO-8 fixed point precision
  -- 56.7333 in Lua floating point precision
  return almost_eq_with_message(vector(57, 80.), stage.state.player_character.position, 0.5)
end

itest_manager:register(itest)

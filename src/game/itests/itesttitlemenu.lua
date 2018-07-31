-- gamestates: titlemenu
require("engine/test/integrationtest")
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local gamestate = require("game/application/gamestate")

local itest = integration_test('player confirms credits selection', {gamestate.types.titlemenu})

itest.setup = function ()
  flow:change_gamestate_by_type(gamestate.types.titlemenu)
end

-- player holds down, causing a just pressed input
itest:add_action(time_trigger(1.0), function ()
  input.simulated_buttons_down[0][button_ids.down] = true
end)
-- end short press. cursor should point to 'credits'
itest:add_action(time_trigger(0.5), function ()
  input.simulated_buttons_down[0][button_ids.down] = false
end)
-- player holds x, causing a just pressed input. this should enter the credits
itest:add_action(time_trigger(0.5), function ()
  input.simulated_buttons_down[0][button_ids.x] = true
end)
-- end short press (1 frame after press is enough to load the next game state)
itest:add_action(time_trigger(0.5), function ()
  input.simulated_buttons_down[0][button_ids.x] = false
end)

-- check that we entered the credits state
itest.final_assertion = function ()
  return flow.current_gamestate.type == gamestate.types.credits, "current game state is not '"..gamestate.types.credits.."', has instead type: "..flow.current_gamestate.type
end

itest_manager:register(itest)

require("engine/test/integrationtest")
local debug = require("engine/debug/debug")
local gameapp = require("game/application/gameapp")
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local titlemenu = require("game/menu/titlemenu")
local credits = require("game/menu/credits")

local itest = integration_test('player confirms credits selection')

itest.setup = function ()
  flow:_change_gamestate(titlemenu.state)
end

-- player holds down, causing a just pressed input
itest:add_action(time_trigger(0.), function ()
  input.simulated_buttons_down[0][button_ids.down] = true
end)
-- end short press. cursor should point to 'credits'
itest:add_action(time_trigger(0.5), function ()
  input.simulated_buttons_down[0][button_ids.down] = false
end)
-- player holds x, causing a just pressed input. this should enter the credits
itest:add_action(time_trigger(0.), function ()
  input.simulated_buttons_down[0][button_ids.x] = true
end)
-- end short press (1 frame after press is enough to load the next game state)
itest:add_action(time_trigger(0.5), function ()
  input.simulated_buttons_down[0][button_ids.x] = false
end)

-- check that we entered the credits state
itest.final_assertion = function ()
  return flow.current_gamestate.type == credits.state.type, "current game state is not 'credits', has instead type: "..flow.current_gamestate.type
end

itest_manager:register(itest)


function _init()
  integration_test_runner:init_game_and_start(itest)
end

function _update60()
  integration_test_runner:update_game_and_test()
end

function _draw()
  integration_test_runner:draw_game_and_test()
end

-- gamestates: titlemenu
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test, time_trigger = integrationtest.itest_manager, integrationtest.integration_test, integrationtest.time_trigger
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local gamestate = require("game/application/gamestate")

itest_manager:register_itest('player select credits, confirm',
    {gamestate.types.titlemenu}, function ()

  -- enter title menu
  setup_callback(function ()
    flow:change_gamestate_by_type(gamestate.types.titlemenu)
  end)

  -- player holds down, causing a just pressed input
  add_action(time_trigger(1.0), function ()
    input.simulated_buttons_down[0][button_ids.down] = true
  end)
  -- end short press. cursor should point to 'credits'
  add_action(time_trigger(0.5), function ()
    input.simulated_buttons_down[0][button_ids.down] = false
  end)
  -- player holds x, causing a just pressed input. this should enter the credits
  add_action(time_trigger(0.5), function ()
    input.simulated_buttons_down[0][button_ids.x] = true
  end)
  -- end short press (1 frame after press is enough to load the next game state)
  add_action(time_trigger(0.5), function ()
    input.simulated_buttons_down[0][button_ids.x] = false
  end)

  -- check that we entered the credits state
  final_assert(function ()
    return flow.curr_state.type == gamestate.types.credits, "current game state is not '"..gamestate.types.credits.."', has instead type: "..flow.curr_state.type
  end)

end)

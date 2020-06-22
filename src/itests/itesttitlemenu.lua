-- gamestates: titlemenu
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test, time_trigger = integrationtest.itest_manager, integrationtest.integration_test, integrationtest.time_trigger
local input = require("engine/input/input")
local flow = require("engine/application/flow")

itest_manager:register_itest('player select credits, confirm',
    {':titlemenu'}, function ()

  -- enter title menu
  setup_callback(function (app)
    flow:change_gamestate_by_type(':titlemenu')
  end)

  wait(1.0)

  -- player holds down, causing a just pressed input
  act(function ()
    input.simulated_buttons_down[0][button_ids.down] = true
  end)

  wait(0.5)

  -- end short press. cursor should point to 'credits'
  act(function ()
    input.simulated_buttons_down[0][button_ids.down] = false
  end)

  wait(0.5)

  -- player holds x, causing a just pressed input. this should enter the credits
  act(function ()
    input.simulated_buttons_down[0][button_ids.x] = true
  end)

  wait(0.5)

  -- end short press (1 frame after press is enough to load the next game state)
  act(function ()
    input.simulated_buttons_down[0][button_ids.x] = false
  end)

  -- check that we entered the credits state
  final_assert(function ()
    return flow.curr_state.type == ':credits', "current game state is not ':credits', has instead type: "..flow.curr_state.type
  end)

end)

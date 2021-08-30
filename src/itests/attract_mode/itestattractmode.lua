-- gamestates: stage
local itest_manager = require("engine/test/itest_manager")
local flow = require("engine/application/flow")

itest_manager:register_itest('attract mode returns to titlemenu after end of sequence',
    {':stage'}, function ()

  -- enter stage
  setup_callback(function (app)
    flow:change_gamestate_by_type(':stage')
  end)

  -- wait for attract mode to end
  --  (summing all the yield frames + 30 frames of fade out gives (917+30)/60 = 15.78333s)
  wait(16.0)

  -- check that we loaded the titlemenu cartridge
  -- busted cannot load cartridges, so it checks the pico8 api instead
  final_assert(function ()
--[[#pico8
    return flow.curr_state.type == ':titlemenu', "current game state is not ':titlemenu', has instead type: "..flow.curr_state.type
--#pico8]]
--#if busted
    return pico8.last_cartridge_loaded == 'picosonic_titlemenu', "last loaded cartridge is not 'picosonic_titlemenu', is instead: '"..pico8.last_cartridge_loaded.."'"
--#endif
  end)

end)

itest_manager:register_itest('attract mode returns to titlemenu on press O',
    {':stage'}, function ()

  -- enter stage
  setup_callback(function (app)
    flow:change_gamestate_by_type(':stage')
  end)

  -- player presses o to exit attract mode (x should also work)
  short_press(button_ids.o)

  -- wait a moment for fade out to finish
  wait(1.0)

  -- check that we loaded the titlemenu cartridge
  -- busted cannot load cartridges, so it checks the pico8 api instead
  final_assert(function ()
--[[#pico8
    return flow.curr_state.type == ':titlemenu', "current game state is not ':titlemenu', has instead type: "..flow.curr_state.type
--#pico8]]
--#if busted
    return pico8.last_cartridge_loaded == 'picosonic_titlemenu', "last loaded cartridge is not 'picosonic_titlemenu', is instead: '"..pico8.last_cartridge_loaded.."'"
--#endif
  end)

end)

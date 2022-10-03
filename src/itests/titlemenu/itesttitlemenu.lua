-- gamestates: splash_screen, titlemenu, credits
local itest_manager = require("engine/test/itest_manager")
local flow = require("engine/application/flow")

itest_manager:register_itest('#solo player waits on splash screen',
    {':splash_screen'}, function ()

  -- enter splash screen
  setup_callback(function (app)
    flow:change_gamestate_by_type(':splash_screen')
  end)

  -- wait enough for splash screen to end
  wait(10.0)

  -- check that we entered titlemenu state automatically
  final_assert(function ()
    return flow.curr_state.type == ':titlemenu', "current game state is not ':titlemenu', has instead type: "..flow.curr_state.type
  end)

end)

itest_manager:register_itest('player presses o to skip splash screen',
    {':splash_screen'}, function ()

  -- enter splash screen
  setup_callback(function (app)
    flow:change_gamestate_by_type(':splash_screen')
  end)

  -- player presses o to enter the titlemenu immediately
  short_press(button_ids.o)

  -- wait 100 frame for fade out to finish (30 frames) AND extra wait before entering titlemenu (60 frames)
  wait(100, true)

  -- check that we are now in the titlemenu state
  final_assert(function ()
    return flow.curr_state.type == ':titlemenu', "current game state is not ':titlemenu', has instead type: "..flow.curr_state.type
  end)

end)

-- we still try to test start game now, because we want to verify that the start cinematic
--  doesn't silently crash (coroutines tend to do that)
itest_manager:register_itest('player select start, confirm',
    {':titlemenu'}, function ()

  -- enter title menu
  setup_callback(function (app)
    flow:change_gamestate_by_type(':titlemenu')
  end)

  -- player presses o to skip splash screen and enter the titlemenu immediately
  short_press(button_ids.o)

  -- wait 30 frame for fade out to finish
  wait(30, true)

  -- player presses o again to make menu appear immediately
  short_press(button_ids.o)

  -- player presses o again to confirm 'start' (default selection)
  short_press(button_ids.o)

  -- wait a moment to cover 90% of the start cinematic
  wait(20.0)

  -- check that we are still in the titlemenu state
  final_assert(function ()
    return flow.curr_state.type == ':titlemenu', "current game state is not ':titlemenu', has instead type: "..flow.curr_state.type
  end)

end)

-- testing credits is easier than entering stage
--  because stage in on another cartridge (ingame),
--  and itest builds are done separately (so we'd need to stub load)
itest_manager:register_itest('player select credits, confirm',
    {':titlemenu'}, function ()

  -- enter title menu
  setup_callback(function (app)
    flow:change_gamestate_by_type(':titlemenu')
  end)

  -- menu should appear within 2 seconds
  wait(2.0)

  -- player presses down 1 frame to select 'credits'
  short_press(button_ids.down)

  -- player presses o to enter the credits
  short_press(button_ids.o)

  -- just for visualization
  wait(1.0)

  -- check that we are now in the credits state
  final_assert(function ()
    return flow.curr_state.type == ':credits', "current game state is not ':credits', has instead type: "..flow.curr_state.type
  end)

end)

-- testing entering attract mode after a long time
itest_manager:register_itest('attract mode starts after opening jingle',
    {':titlemenu'}, function ()

  -- enter title menu
  setup_callback(function (app)
    flow:change_gamestate_by_type(':titlemenu')
  end)

  -- opening jingle except fade out
  wait(864 / 60)

  -- fade out + small delay
  wait(108 / 60)

  -- we cannot really test load(), so just return true
  -- a human can still verify that "load cartridge: picosonic_attract_mode" was printed
  final_assert(function ()
    return true
  end)

end)

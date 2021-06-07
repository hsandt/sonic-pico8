-- gamestates: titlemenu
local itest_manager = require("engine/test/itest_manager")
local flow = require("engine/application/flow")

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

  -- menu should appear in 96 frames 2 seconds
  wait(96 / 60)

  -- attract mode should start 816 frames after that
  wait(816 / 60)

  -- check that we are now in the attract_mode state
  final_assert(function ()
    return flow.curr_state.frames_before_showing_attract_mode == 0, "timer for attract mode is not over: "..flow.curr_state.frames_before_showing_attract_mode
  end)

end)

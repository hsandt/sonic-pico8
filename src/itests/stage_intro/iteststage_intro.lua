-- gamestates: stage_intro
local itest_manager = require("engine/test/itest_manager")
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local visual = require("resources/visual_common")  -- we should require ingameadd-on in main

-- testing credits is easier than entering stage
--  because stage in on another cartridge (ingame),
--  and itest builds are done separately (so we'd need to stub load)
itest_manager:register_itest('(intro) player waits',
    {':stage_intro'}, function ()

  -- enter stage intro state
  setup_callback(function (app)
    flow:change_gamestate_by_type(':stage_intro')
  end)

  -- let stage intro sequence play and see if nothing crashes
  -- reduced frames from 750 to 100 to make it shorter, although we won't test the whole sequence
  wait(100, true)

  -- we should still be in stage intro (because even if we load() titlemenu cartridge in headless,
  --  it won't do anything)
  final_assert(function ()
    return flow.curr_state.type == ':stage_intro', "current game state is not ':stage_intro', has instead type: "..flow.curr_state.type
  end)

end)

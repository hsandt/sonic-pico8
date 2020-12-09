-- gamestates: stage_clear
local itest_manager = require("engine/test/itest_manager")
local input = require("engine/input/input")
local flow = require("engine/application/flow")


-- testing credits is easier than entering stage
--  because stage in on another cartridge (ingame),
--  and itest builds are done separately (so we'd need to stub load)
itest_manager:register_itest('player waits',
    {':stage_clear'}, function ()

  -- enter title menu
  setup_callback(function (app)
    -- simulate having stored picked emeralds bitset from ingame cartridge
    -- 0b01001001 -> 73 (low-endian, so lowest bit is for emerald 1)
    poke(0x4300, 73)

    flow:change_gamestate_by_type(':stage_clear')
  end)

  -- let stage clear sequence play and see if nothing crashes
  wait(20.0)

  -- we should still be in stage clear (because even if we load() titlemenu cartridge in headless,
  --  it won't do anything)
  final_assert(function ()
    return flow.curr_state.type == ':stage_clear', "current game state is not ':stage_clear', has instead type: "..flow.curr_state.type
  end)

end)

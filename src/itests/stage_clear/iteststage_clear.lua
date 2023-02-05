-- gamestates: stage_clear
local itest_manager = require("engine/test/itest_manager")
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local visual_ingame_data = require("resources/visual_ingame_numerical_data")  -- we should require ingameadd-on in main

-- testing credits is easier than entering stage
--  because stage in on another cartridge (ingame),
--  and itest builds are done separately (so we'd need to stub load)
itest_manager:register_itest('(stage clear) player waits',
    {':stage_clear'}, function ()

  -- enter stage clear state, simulate data from ingame cartridge and goal plate in tilemap
  setup_callback(function (app)
    -- simulate having stored picked emeralds bitset from ingame cartridge
    -- 0b01001001 -> 73 (low-endian, so lowest bit is for emerald 1)
    poke(0x4300, 73)

    -- simulate goal plate in level (which starts empty) so render doesn't fail
    mset(64, 16, visual_ingame_data.goal_plate_base_id)

    flow:change_gamestate_by_type(':stage_clear')
  end)

  -- let stage clear sequence play and see if nothing crashes, long enough to test some Eggman cycles
  wait(1000, true)

  -- we should still be in stage clear (because even if we load() titlemenu cartridge in headless,
  --  it won't do anything)
  final_assert(function ()
    return flow.curr_state.type == ':stage_clear', "current game state is not ':stage_clear', has instead type: "..flow.curr_state.type
  end)

end)

itest_manager:register_itest('(stage clear) player skips to try again screen',
    {':stage_clear'}, function ()

  -- enter stage clear state, simulate data from ingame cartridge and goal plate in tilemap
  setup_callback(function (app)
    -- simulate having stored picked emeralds bitset from ingame cartridge
    -- 0b01001001 -> 73 (low-endian, so lowest bit is for emerald 1)
    poke(0x4300, 73)

    -- simulate goal plate in level (which starts empty) so render doesn't fail
    mset(64, 16, visual_ingame_data.goal_plate_base_id)

    flow:change_gamestate_by_type(':stage_clear')
  end)

  -- skip to try again screen
  short_press(button_ids.o)

  -- let try again screen appear and wait for some Eggman cycles
  wait(100, true)

  -- we should still be in stage clear (because even if we load() titlemenu cartridge in headless,
  --  it won't do anything)
  final_assert(function ()
    return flow.curr_state.retry_menu ~= nil, "retry menu has not been created or has been cleared too early"
  end)

end)

itest_manager:register_itest('#solo (stage clear) player skips to ending credits (all emeralds)',
    {':stage_clear'}, function ()

  -- enter stage clear state, simulate data from ingame cartridge and goal plate in tilemap
  setup_callback(function (app)
    -- simulate having stored picked emeralds bitset from ingame cartridge
    -- 0b11111111 -> 255
    poke(0x4300, 255)

    -- simulate goal plate in level (which starts empty) so render doesn't fail
    mset(64, 16, visual_ingame_data.goal_plate_base_id)

    flow:change_gamestate_by_type(':stage_clear')
  end)

  -- skip to ending credits screen
  short_press(button_ids.o)

  -- let for ending credits to advance enough to spot any crash
  wait(30, false)

  final_assert(function ()
    return true, "crash test only"
  end)

end)

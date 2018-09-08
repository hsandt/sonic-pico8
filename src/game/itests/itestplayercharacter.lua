-- gamestates: stage
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test, time_trigger = integrationtest.itest_manager, integrationtest.integration_test, integrationtest.time_trigger
local flow = require("engine/application/flow")
local stage = require("game/ingame/stage")  -- required
--#ifn pico8
local tile_test_data = require("game/test_data/tile_test_data")
--#endif

local itest = integration_test('character debug moves to right', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  -- we still need on_enter to spawn character
  flow:change_gamestate_by_type(stage.state.type)
  stage.state.player_character.position = vector(0., 80.)
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.debug
end

-- player char starts moving to the right
itest:add_action(time_trigger(0.), function ()
  stage.state.player_character.move_intention = vector(1., 0.)
end)
-- stop after 1 second
itest:add_action(time_trigger(1.), function () end)

-- check that player char has moved a little to the right (integrate accel)
itest.final_assertion = function ()
  -- 56.7185 in PICO-8 fixed point precision
  -- 56.7333 in Lua floating point precision
  return almost_eq_with_message(vector(57, 80.), stage.state.player_character.position, 0.5)
end


-- bugfix history: test failed because initial character position was wrong in the test
local itest = integration_test('. character platformer lands vertically', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
--#ifn pico8
  -- add tile where the character will land
  tile_test_data.setup()
  mset(0, 10, 64)
--#endif

  -- we still need on_enter to spawn character
  flow:change_gamestate_by_type(stage.state.type)
  stage.state.player_character.position = vector(4., 48.)
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer
end

--#ifn pico8
itest.teardown = function ()
  tile_test_data.teardown()
  mset(0, 10, 0)
end
--#endif

-- wait 1 second and stop
itest:add_action(time_trigger(1.), function () end)

-- check that player char has landed and snapped to the ground
itest.final_assertion = function ()
  return almost_eq_with_message(vector(4., 80.), stage.state.player_character:get_bottom_center(), 1/256)
end


--[[#pico8
-- human test for pico8 only to check rendering
-- bugfix history: fixed character pivot computed from drawn sprite topleft (with some gap above character's head)
--  and not actual sprite topleft in the spritesheet
local itest = integration_test('= character is correctly rendered idle', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  flow:change_gamestate_by_type(stage.state.type)
  stage.state.player_character:set_bottom_center(vector(4., 80.))
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.debug
end

-- wait just 0.1 second so the character can be rendered at least 1 frame because the test pauses
itest:add_action(time_trigger(1.), function () end)

-- no final assertion, let the user check if result is correct or not (note it will display success whatever)
-- #pico8]]

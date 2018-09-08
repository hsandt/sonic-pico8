-- gamestates: stage
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test, time_trigger = integrationtest.itest_manager, integrationtest.integration_test, integrationtest.time_trigger
local flow = require("engine/application/flow")
local stage = require("game/ingame/stage")  -- required
local collision = require("engine/physics/collision")
local collision_data = require("game/data/collision_data")


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
  -- busted/luassert functions are not directly accessible in scriptes required from main
  --  script called with busted
  local stub = require 'luassert.stub'

  -- setup part of the tilemap of PICO-8 we just need for the test in busted

  -- mock sprite flags
  fset(64, sprite_flags.collision, true)  -- full tile

  -- mock height array _init so it doesn't have to dig in sprite data, inaccessible from busted
  height_array_init_mock = stub(collision.height_array, "_init", function (self, tile_mask_id_location, slope_angle)
    if tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[64] then
      self._array = {8, 8, 8, 8, 8, 8, 8, 8}  -- full tile
    end
    self._slope_angle = slope_angle
  end)

  -- where the character will land
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
  fset(64, sprite_flags.collision, false)
  height_array_init_mock:revert()
  mset(0, 10, 0)
end
--#endif

-- wait 1 second and stop
itest:add_action(time_trigger(1.), function () end)

-- check that player char has landed and snapped to the ground
itest.final_assertion = function ()
  return almost_eq_with_message(vector(4., 80.), stage.state.player_character:get_bottom_center(), 1/256)
end

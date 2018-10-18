-- gamestates: stage
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test, time_trigger = integrationtest.itest_manager, integrationtest.integration_test, integrationtest.time_trigger
local flow = require("engine/application/flow")
local stage = require("game/ingame/stage")  -- required
local playercharacter_data = require("game/data/playercharacter_data")
--#ifn pico8
local tile_test_data = require("game/test_data/tile_test_data")
--#endif


-- for itests that need map setup, we exceptionally not teardown
--  the map since we would need to store a backup of the original map
--  and we don't care, since each itest will build its own mock map
local function setup_map_data()
--#ifn pico8
  tile_test_data.setup()
  pico8:clear_map()
--#endif

--[[#pico8
  -- clear map data
  memset(0x2000, 0, 0x1000)
-- #pico8]]
end

local function teardown_map_data()
--#ifn pico8
  tile_test_data.teardown()
--#endif
end


local itest

--[[
itest = integration_test('debug move right', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- just add a tile in the way to make sure debug motion ignores collisions
  mset(1, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)
  stage.state.player_character.position = vector(0., 80.)
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.debug

  -- player char starts moving to the right
  stage.state.player_character.move_intention = vector(1., 0.)
end

itest.teardown = function ()
  teardown_map_data()
end

-- stop after 1 second
itest:add_action(time_trigger(1.), function () end)

-- check that player char has moved a little to the right (integrate accel)
itest.final_assertion = function ()
  -- 56.7185 in PICO-8 fixed point precision
  -- 56.7333 in Lua floating point precision
  return almost_eq_with_message(vector(56.7185, 80.), stage.state.player_character.position, 0.015)
end


-- bugfix history:
-- . test failed because initial character position was wrong in the test
-- * test failed in pico8 only because in _compute_signed_distance_to_closest_ground,
--  I was setting min_signed_distance = 32768 = -32767
itest = integration_test('platformer land vertical', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tile where the character will land
  mset(0, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character in the air (important to always start with airborne state)
  stage.state.player_character:spawn_at(vector(4., 48.))
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer
end

itest.teardown = function ()
  teardown_map_data()
end

-- wait 1 second and stop
itest:add_action(time_trigger(1.), function () end)

-- check that player char has landed and snapped to the ground
itest.final_assertion = function ()
  return almost_eq_with_message(vector(4., 80.), stage.state.player_character:get_bottom_center(), 1/256)
end


-- bugfix history: . test was wrong, initialize in setup, not at time trigger 0
itest = integration_test('platformer accel right flat', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  mset(0, 10, 64)
  mset(1, 10, 64)
  mset(2, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start moving to the right from frame 0 by setting intention in setup
  stage.state.player_character.move_intention = vector(1, 0)
end

itest.teardown = function ()
  teardown_map_data()
end

-- wait 30 frames and stop
itest:add_action(time_trigger(0.5), function () end)

-- check that player char has moved to the right and is still on the ground
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.grounded == stage.state.player_character.motion_state, "Expected motion state 'grounded', got "..stage.state.player_character.motion_state
  -- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
  local is_position_expected, position_message = almost_eq_with_message(vector(14.8984375, 80.), stage.state.player_character:get_bottom_center(), 1/256)
  -- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0.703125, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0.703125, 0), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


itest = integration_test('platformer decel right flat', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)
  mset(1, 10, 64)
  mset(2, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start moving to the right from frame 0 by setting intention in setup
  stage.state.player_character.move_intention = vector(1, 0)
end

itest.teardown = function ()
  teardown_map_data()
end

-- at frame 30, decelerate (brake)
itest:add_action(time_trigger(0.5), function ()
  stage.state.player_character.move_intention = vector(-1, 0)
end)

-- wait 10 frames and stop
itest:add_action(time_trigger(10, true), function () end)

-- check that player char has moved to the right and is still on the ground
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.grounded == stage.state.player_character.motion_state, "Expected motion state 'grounded', got "..stage.state.player_character.motion_state
  -- to compute position, apply deceleration to the current speed and sum to the last position at frame 30. don't forget to clamp speed to - max speed when changing sign over max speed,
  --  before continuing to increase speed with - max accel each step after that
  local is_position_expected, position_message = almost_eq_with_message(vector(14.7109375, 80.), stage.state.player_character:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(-0.1875, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(-0.1875, 0), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


itest = integration_test('platformer friction right flat', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)
  mset(1, 10, 64)
  mset(2, 10, 64)
  mset(3, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start moving to the right from frame 0 by setting intention in setup
  stage.state.player_character.move_intention = vector(1, 0)
end

itest.teardown = function ()
  teardown_map_data()
end

-- at frame 30, slow down with friction
itest:add_action(time_trigger(0.5), function ()
  stage.state.player_character.move_intention = vector.zero()
end)

-- wait 30 frames and stop
itest:add_action(time_trigger(0.5), function () end)

-- check that player char has moved to the right and is still on the ground
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.grounded == stage.state.player_character.motion_state, "Expected motion state 'grounded', got "..stage.state.player_character.motion_state
  -- to compute position, use the fact that friction == accel, so our speed describes a pyramid over time with a non-mirrored, unique max at 0.703125,
  --  so we can 2x the accumulated distance computed in the first test (only accel over 30 frames), then subtract the non-doubled max value, and add the initial position x
  local is_position_expected, position_message = almost_eq_with_message(vector(4 + 2 * 10.8984375 - 0.703125, 80.), stage.state.player_character:get_bottom_center(), 1/256)
  -- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, 0), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


-- bugfix history: . forgot to add a solid ground below the slope to confirm ground
itest = integration_test('platformer ascending slope right', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)  -- flat ground
  mset(1, 10, 64)  -- solid ground to support slope, as with current motion rules, character needs it
  mset(1, 9, 65)   -- ascending slope 45, one level up

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start moving to the right from frame 0 by setting intention in setup
  stage.state.player_character.move_intention = vector(1, 0)
end

itest.teardown = function ()
  teardown_map_data()
end

-- wait 30 frames and stop
-- ground_accel_frame2 = 0.0234375
-- at frame 1: pos (4 + ground_accel_frame2, 74), velocity (ground_accel_frame2, 0)
-- at frame n before slope: pos (4 + n(n+1)/2*ground_accel_frame2, 74), velocity (n*ground_accel_frame2, 0)
-- character makes first step on slope when right sensor reaches position x = 8 (column 0 height of tile 65 is 1)
--  i.e. center reaches 8 - ground_sensor_extent_x = 5.5
-- at frame 10: pos (5.2890625, 74), velocity (0.234375, 0)
-- at frame 11: pos (5.546875, 73), velocity (0.2578125, 0), first step on slope tile
-- note that speed decrease on slope is not implemented yet (via cosine but also gravity), so this test will have to change when it is
--  however, the result should stay true for a very low slope (a wave where registered slope is 0)
itest:add_action(time_trigger(11, true), function () end)

-- check that player char has moved to the right and is still on the ground
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.grounded == stage.state.player_character.motion_state, "Expected motion state 'grounded', got "..stage.state.player_character.motion_state
  -- to compute position, use the fact that friction == accel, so our speed describes a pyramid over time with a non-mirrored, unique max at 0.703125,
  --  so we can 2x the accumulated distance computed in the first test (only accel over 30 frames), then subtract the non-doubled max value, and add the initial position x
  local is_position_expected, position_message = almost_eq_with_message(vector(5.546875, 79), stage.state.player_character:get_bottom_center(), 1/256)
  -- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0.2578125, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0.2578125, 0), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


-- bugfix history: ! identified bug in _update_platformer_motion where absence of elseif
--  allowed to enter both grounded and airborne update, causing 2x update when leaving the cliff
itest = integration_test('platformer fall cliff', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)
  mset(1, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start moving to the right from frame 0 by setting intention in setup
  stage.state.player_character.move_intention = vector(1, 0)
end

itest.teardown = function ()
  teardown_map_data()
end

-- at frame 34: pos (17.9453125, 74), velocity (0.796875, 0), grounded
-- at frame 35: pos (18.765625, 74), velocity (0.8203125, 0), airborne -> stop accel
itest:add_action(time_trigger(35, true), function ()
  stage.state.player_character.move_intention = vector.zero()
end)

-- wait 25 frames and stop
-- at frame 60: pos (39.2734375, 74 + 35.546875), velocity (0.8203125, 2.734375), airborne
itest:add_action(time_trigger(25, true), function () end)

-- check that player char has moved to the right and fell
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.airborne == stage.state.player_character.motion_state, "Expected motion state 'airborne', got "..stage.state.player_character.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(39.2734375, 80. + 35.546875), stage.state.player_character:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0.8203125, 2.734375), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


itest = integration_test('platformer hop flat', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start jump
  stage.state.player_character.jump_intention = true  -- will be consumed
  -- don't set hold_jump_intention at all to get a hop
  -- (you can also set it on setup and reset it at end of frame 1)
end

itest.teardown = function ()
  teardown_map_data()
end

-- wait for apogee (frame 20) and stop
-- at frame 1:  bpos (4, 80), velocity (0, 0), grounded (waits 1 frame before confirming hop/jump)
-- at frame 2:  bpos (4, 80 - 2), velocity (0, -2), airborne (hop confirmed)
-- at frame 3:  bpos (4, 80 - 3.890625), velocity (0, -1.890625), airborne (hop confirmed)
-- at frame 19: pos (4, 80 - 19.265625), velocity (0, -0.140625), airborne -> before apogee
-- at frame 20: pos (4, 80 - 19.296875), velocity (0, -0.03125), airborne -> reached apogee
-- at frame 21: pos (4, 80 - 19.21875), velocity (0, 0.078125), airborne -> starts going down
-- at frame 38: pos (4, 80 - 1.15625), velocity (0, 1.9375), airborne ->  about to land
-- at frame 39: pos (4, 80), velocity (0, 0), grounded -> has landed
itest:add_action(time_trigger(20, true), function ()
end)

-- check that player char has moved to the right and fell
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.airborne == stage.state.player_character.motion_state, "Expected motion state 'airborne', got "..stage.state.player_character.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(4, 80. - 19.296875), stage.state.player_character:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, -0.03125), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


itest = integration_test('platformer jump f2 interrupt flat', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start jump
  stage.state.player_character.jump_intention = true  -- will be consumed
  stage.state.player_character.hold_jump_intention = true
end

itest.teardown = function ()
  teardown_map_data()
end

-- interrupt variable jump at the end of frame 2
-- at frame 1: bpos (4, 80), velocity (0, 0), grounded (waits 1 frame before confirming hop/jump)
-- at frame 2: bpos (4, 80 - 3.25), velocity (0, -3.25), airborne (jump confirmed)
itest:add_action(time_trigger(2, true), function ()
  stage.state.player_character.hold_jump_intention = false
end)

-- wait for the apogee (frame 20) and stop
-- at frame 3:  bpos (4, 80 - 5.140625), velocity (0, -1.890625), airborne -> jump interrupted (gravity is applied *after* setting speed y to -2)
-- at frame 19: bpos (4, 80 - 20.515625), velocity (0, -0.140625), airborne -> before apogee
-- at frame 20: bpos (4, 80 - 20.546875), velocity (0, -0.03125), airborne -> reached apogee
-- at frame 21: bpos (4, 80 - 20.46875), velocity (0, 0.078125), airborne -> starts going down
-- at frame 39: bpos (4, 80 - 0.3594), velocity (0, 2.15625), airborne -> about to land
-- at frame 40: bpos (4, 80), velocity (0, 0), grounded -> has landed
itest:add_action(time_trigger(18, true), function () end)

-- check that player char has reached the apogee of the jump
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.airborne == stage.state.player_character.motion_state, "Expected motion state 'airborne', got "..stage.state.player_character.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(4, 80 - 20.546875), stage.state.player_character:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, -0.03125), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


itest = integration_test('platformer full jump flat', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start jump
  stage.state.player_character.jump_intention = true  -- will be consumed
  stage.state.player_character.hold_jump_intention = true
end

itest.teardown = function ()
  teardown_map_data()
end

-- wait for the apogee (frame 31) and stop
-- at frame 1: pos (4, 80), velocity (0, 0), grounded (waits 1 frame before confirming hop/jump)
-- at frame 2: pos (4, 80 - 3.25), velocity (0, -3.25), airborne (do not apply gravity on first frame of jump since we were grounded)
-- at frame 30: pos (4, 80 - 49.84375), velocity (0, -0.1875), airborne -> before apogee
-- at frame 31: pos (4, 80 - 49.921875), velocity (0, -0.078125), airborne -> reached apogee (100px in 16-bit, matches SPG on Jumping)
-- at frame 32: pos (4, 80 - 49.890625), velocity (0, 0.03125), airborne -> starts going down
-- at frame 61: pos (4, 80 - 1.40625), velocity (0, 3.203125), airborne -> about to land
-- at frame 62: pos (4, 80), velocity (0, 0), grounded -> has landed
itest:add_action(time_trigger(31, true), function () end)

-- check that player char has moved to the right and fell
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.airborne == stage.state.player_character.motion_state, "Expected motion state 'airborne', got "..stage.state.player_character.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(4, 80 - 49.921875), stage.state.player_character:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, -0.078125), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


itest = integration_test('platformer jump air accel', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start full jump and immediately try to move right
  stage.state.player_character.jump_intention = true  -- will be consumed
  stage.state.player_character.hold_jump_intention = true
end

itest.teardown = function ()
  teardown_map_data()
end

-- wait 2 frame (1 to register jump, 1 to confirm and leave ground) then move to the right
-- this is just to avoid starting moving on the ground, as we only want to test air control here,
--  not how ground speed is transferred to air velocity
itest:add_action(time_trigger(2, true), function ()
  stage.state.player_character.move_intention = vector(1, 0)
end)


-- wait for the apogee (frame 31) and stop
-- at frame 1: pos (4, 80), velocity (0, 0), grounded (waits 1 frame before confirming hop/jump)
-- at frame 2: pos (4, 80 - 3.25), velocity (0, -3.25), airborne (do not apply gravity on first frame of jump, no air accel yet)
-- at frame 3: pos (4 + 0.046875, 80 - 49.84375), velocity (0.046875, -3.140625), airborne -> accel forward
-- at frame 30: pos (4 + 19.03125, 80 - 49.84375), velocity (1.3125, -0.1875), airborne -> before apogee
-- at frame 31: pos (4 + 20.390625, 80 - 49.921875), velocity (1.359375, -0.078125), airborne -> reached apogee (100px in 16-bit, matches SPG on Jumping)
-- at frame 32: pos (4 + 21.796875, 80 - 49.890625), velocity (1.40625, 0.03125), airborne -> starts going down
-- at frame 61: pos (4 + 82.96875, 80 - 1.40625), velocity (2.765625, 3.203125), airborne -> about to land
-- at frame 62: pos (4 + 85.78125, 80), velocity (2.8125, 0), grounded -> has landed, preserve x speed
itest:add_action(time_trigger(29, true), function () end)

-- check that player char has moved to the right and fell
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.airborne == stage.state.player_character.motion_state, "Expected motion state 'airborne', got "..stage.state.player_character.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(4 + 20.390625, 80 - 49.921875), stage.state.player_character:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(1.359375, -0.078125), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end
--]]

itest = integration_test('platformer ground wall block right', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  mset(0, 10, 64)  -- to walk on
  mset(1, 10, 64)  -- to walk on
  mset(2, 10, 64)  -- for now, we need supporting block
  mset(2,  9, 64)  -- blocking wall

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start moving to the right from frame 0 by setting intention in setup
  stage.state.player_character.move_intention = vector(1, 0)
end

itest.teardown = function ()
  teardown_map_data()
end


-- wait 29 frames and stop
-- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
-- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
-- character will be blocked when right wall sensor is at x = 16, so when center is at x = 12
-- at frame 1: pos (4 + 0.0234375, 80), velocity (0.0234375, 0), grounded
-- at frame 24: pos (11.59375, 80 - 8), velocity (0.5625, 0), about to meet wall
-- at frame 25: pos (2, 80 - 8), velocity (0, 0), about to meet wall
-- at frame 26: pos (12.8359375, 80 - 8), velocity (0, 0), about to meet wall
-- strange! I get vector(12.2265625, 73.0) there
-- itest:add_action(time_trigger(26, true), function () end)  -- to test
itest:add_action(time_trigger(27, true), function () end)

-- check that player char has moved to the right and is still on the ground
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.grounded == stage.state.player_character.motion_state, "Expected motion state 'grounded', got "..stage.state.player_character.motion_state
  -- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
  local is_position_expected, position_message = almost_eq_with_message(vector(12., 80.), stage.state.player_character:get_bottom_center(), 1/256)
  -- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, 0), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


itest = integration_test('#solo platformer slope wall block right', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  mset(0, 10, 64)  -- to walk on
  mset(1, 10, 64)  -- support ground for slope
  mset(1,  9, 65)  -- slope to walk on
  mset(2,  9, 64)  -- for now, we need supporting block
  mset(2,  8, 64)  -- blocking wall at the top of the slope

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_character:spawn_at(vector(4., 80. - playercharacter_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.platformer

  -- start moving to the right from frame 0 by setting intention in setup
  stage.state.player_character.move_intention = vector(1, 0)
end

itest.teardown = function ()
  teardown_map_data()
end

-- wait 29 frames and stop

-- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
-- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
-- character will be blocked when right wall sensor is at x = 16, so when center is at x = 12
-- remember character must reach x=13 (not visible, inside frame calculation) to detect the wall, then snap to 12!
-- at frame 1: pos (4 + 0.0234375, 80), velocity (0.0234375, 0), grounded
-- at frame 24: pos (11.59375, 80 - 8), velocity (0.5625, 0), about to meet wall
-- at frame 25: pos (2, 80 - 8), velocity (0, 0), about to meet wall
-- at frame 26: pos (12.8359375, 80 - 8), velocity (0, 0), about to meet wall
-- strange! I get vector(12.2265625, 73.0) there
-- please check the accel/decel itests again as subpixel precision seem to have changed
-- at frame 27: pos (12, 80 - 8), velocity (0, 0), stopped at wall (snapped from 13.4921875), position clamped and speed reset to 0
-- note that speed decrease on slope is not implemented yet (via cosine but also gravity), so this test will have to change when it is
--  when it is, prefer passing a very low slope or apply slope factor to adapt the position/velocity calculation
-- itest:add_action(time_trigger(26, true), function () end)  -- to test exact position before meeting wall
itest:add_action(time_trigger(27, true), function () end)

-- check that player char has moved to the right and is still on the ground
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.grounded == stage.state.player_character.motion_state, "Expected motion state 'grounded', got "..stage.state.player_character.motion_state
  -- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
  -- actually 13 if we use more narrow ground sensor
  local is_position_expected, position_message = almost_eq_with_message(vector(12, 80 - 8), stage.state.player_character:get_bottom_center(), 1/256)
  -- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_character.ground_speed_frame, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, 0), stage.state.player_character.velocity_frame, 1/256)

  local final_message = ""

  local success = is_position_expected and is_ground_speed_expected and is_velocity_expected and is_motion_state_expected
  if not success then
    if not is_motion_state_expected then
      final_message = final_message..motion_state_message.."\n"
    end
    if not is_position_expected then
      final_message = final_message..position_message.."\n"
    end
    if not is_ground_speed_expected then
      final_message = final_message..ground_speed_message.."\n"
    end
    if not is_velocity_expected then
      final_message = final_message..velocity_message.."\n"
    end

  end

  return success, final_message
end


--[[#pico8
-- human test for pico8 only to check rendering
-- bugfix history: fixed character pivot computed from drawn sprite topleft (with some gap above character's head)
--  and not actual sprite topleft in the spritesheet
itest = integration_test('= character is correctly rendered idle', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  mset(0, 10, 64)  -- to stand on

  flow:change_gamestate_by_type(stage.state.type)
  stage.state.player_character:set_bottom_center(vector(4., 80.))
  stage.state.player_character.control_mode = control_modes.puppet
  stage.state.player_character.motion_mode = motion_modes.debug
end

-- wait just 0.1 second so the character can be rendered at least 1 frame because the test pauses
itest:add_action(time_trigger(1.), function () end)

-- no final assertion, let the user check if result is correct or not (note it will display success whatever)
-- #pico8]]

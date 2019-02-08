-- gamestates: stage
local integrationtest = require("engine/test/integrationtest")
local itest_dsl = require("engine/test/itest_dsl")
local itest_dsl_parser = itest_dsl.itest_dsl_parser
local itest_manager,   integration_test,   time_trigger = get_members(integrationtest,
     "itest_manager", "integration_test", "time_trigger")
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local stage = require("game/ingame/stage")  -- required
local pc_data = require("game/data/playercharacter_data")
local tile_data = require("game/data/tile_data")
--#ifn pico8
local tile_test_data = require("game/test_data/tile_test_data")
--#endif

local itest


-- debug motion

itest_dsl_parser.register(
  'debug move right', [[
@stage #
.#

set_motion_mode debug
warp 0 8
move right
wait 60

expect pc_bottom_pos 0x0038.b7f1 8
]])

-- precision note on expected pc_bottom_pos:
-- 56.7185211181640625 (0x0038.b7f1) in PICO-8 fixed point precision
-- 56.7333 in Lua floating point precision


-- ground motion

-- bugfix history:
-- . test was wrong, initialize in setup, not at time trigger 0
itest_dsl_parser.register(
  'platformer accel right flat', [[
@stage #
...
###

warp 4 8
move right
wait 30

expect pc_bottom_pos 14.8984375 8
expect pc_motion_state grounded
expect pc_ground_spd 0.703125
expect pc_velocity 0.703125 0
]])

itest_dsl_parser.register(
  'platformer decel right flat', [[
@stage #
...
###

warp 4 8
move right
wait 30
move left
wait 10

expect pc_bottom_pos 14.7109375 8
expect pc_motion_state grounded
expect pc_ground_spd -0.1875
expect pc_velocity -0.1875 0
]])

itest_dsl_parser.register(
  'platformer friction right flat', [[
@stage #
....
####

warp 4 8
move right
wait 30
stop
wait 30

expect pc_bottom_pos 25.09375 8
expect pc_motion_state grounded
expect pc_ground_spd 0
expect pc_velocity 0 0
]])

-- calculation notes:
-- to compute position, use the fact that friction == accel, so our speed describes a pyramid over where each value is mirrored
--   around the middle, where the max is, except the max speed itself (0.703125) which is only reached a single frame
--   so we can 2x the accumulated distance computed in the first test (only accel over 30 frames),
--   then subtract the unique max value, and add the initial position x
-- expected position: vector(4 + 2 * 10.8984375 - 0.703125, 80.) = vector(25.09375, 80)
-- otherwise, character has stopped so expected speed is 0


-- bugfix history:
-- . forgot to add a solid ground below the slope to confirm ground
-- ! identified bug in _compute_ground_motion_result where slope angle was set on extra step,
--   despite being only a subpixel extra move
-- . was expecting positive speed but slope was ascending
itest_dsl_parser.register(
  'platformer ascending slope right', [[
@stage #
..
./
#.

warp 4 16
move right
wait 15

expect pc_bottom_pos 6.519668501758 15
expect pc_motion_state grounded
expect pc_slope -0.125
expect pc_ground_spd 0.26318359375
expect pc_velocity 0.1860961140625 -0.1860961140625
]])

-- pc_slope -45/360 = -1/8 = -0.125

-- calculation notes:
-- at frame  1: bottom pos (4 + ground_accel_frame2, 16), velocity (ground_accel_frame2, 0), ground_speed (ground_accel_frame2)
-- at frame n before slope: bpos (4 + n(n+1)/2*ground_accel_frame2, 16), velocity (n*ground_accel_frame2, 0)
-- character makes first step on slope when right sensor reaches position x = 8 (column 0 height of tile 65 is 1)
--  i.e. center reaches 8 - ground_sensor_extent_x = 5.5
-- at frame  1: bpos (4.0234375, 16), velocity (0.0234375, 0), ground_speed(0.0234375)
-- at frame  9: bpos (5.0546875, 16), velocity (0.2109375, 0), ground_speed(0.2109375)
-- at frame 10: bpos (5.2890625, 16), velocity (0.234375, 0), ground_speed(0.234375)
-- at frame 11: bpos (5.546875, 16), velocity (0.2578125, 0), ground_speed(0.2578125)
-- at frame 12: bpos (5.828125, 16), velocity (0.28125, 0), ground_speed(0.28125)
-- at frame 13: bpos (6.1328125, 15), velocity (0.3046875, 0), ground_speed(0.3046875), first step on slope and at higher level than flat ground, acknowledge slope as current ground
-- at frame 14: bpos (6.333572387695, 15), velocity (0.2007598876953125, -0.2007598876953125), ground_speed(0.283935546875), because slope was current ground at frame start, slope factor was applied with 0.0625*sin(45) = -0.044189453125 (in PICO-8 16.16 fixed point precision)
-- at frame 15: bpos (6.519668501758, 15), velocity (0.1860961140625, -0.1860961140625), ground_speed(0.26318359375), still under slope factor effect and velocity following slope tangent


-- air motion

-- bugfix history:
-- . test failed because initial character position was wrong in the test
-- * test failed in pico8 only because in _compute_signed_distance_to_closest_ground,
--   I was setting min_signed_distance = 32768 = -32767
itest_dsl_parser.register(
  'platformer land vertical', [[
@stage #
.
.
.
#

warp 4 0
wait 21

expect pc_bottom_pos 4 24
expect pc_motion_state grounded
expect pc_ground_spd 0
expect pc_velocity 0 0
]])


-- bugfix history:
-- ! identified bug in _update_platformer_motion where absence of elseif
--  allowed to enter both grounded and airborne update, causing 2x update when leaving the cliff
-- * revealed that new system always flooring pixel position x caused leaving cliff
--  frame later, adding a grounded frame with friction
itest_dsl_parser.register(
  'platformer fall cliff', [[
@stage #
..
##

warp 4 8
move right
wait 36
stop
wait 24

expect pc_bottom_pos 39.859375 40.8125
expect pc_motion_state airborne
expect pc_ground_spd 0
expect pc_velocity 0.84375 2.625
]])

-- calculation notes:
-- at frame 1: pos (17.9453125, 8), velocity (0.796875, 0), grounded
-- at frame 34: pos (17.9453125, 8), velocity (0.796875, 0), grounded
-- at frame 35: pos (18.765625, 8), velocity (0.8203125, 0), grounded (do not apply ground sensor extent: -2.5 directly, floor to full px first)
-- at frame 36: pos (19.609375, 8), velocity (0.84375, 0), airborne (flr_x=19) -> stop accel
-- wait 24 frames and stop
-- gravity during 24 frames: accel = 0.109375 * (24 * 25 / 2), velocity = 0.109375 * 24 = 2.625
-- at frame 60: pos (39.859375, 8 + 32.8125), velocity (0.84375, 2.625), airborne


--[[
itest = integration_test('platformer hop flat', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_char:spawn_at(vector(4., 80. - pc_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_char.control_mode = control_modes.puppet
  stage.state.player_char.motion_mode = motion_modes.platformer

  -- start jump
  stage.state.player_char.jump_intention = true  -- will be consumed
  -- don't set hold_jump_intention at all to get a hop
  -- (you can also set it on setup and reset it at end of frame 1)
end

itest.teardown = function ()
  clear_map()
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
  local is_motion_state_expected, motion_state_message = motion_states.airborne == stage.state.player_char.motion_state, "Expected motion state 'airborne', got "..stage.state.player_char.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(4, 80. - 19.296875), stage.state.player_char:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_char.ground_speed, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, -0.03125), stage.state.player_char.velocity, 1/256)

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
  stage.state.player_char:spawn_at(vector(4., 80. - pc_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_char.control_mode = control_modes.puppet
  stage.state.player_char.motion_mode = motion_modes.platformer

  -- start jump
  stage.state.player_char.jump_intention = true  -- will be consumed
  stage.state.player_char.hold_jump_intention = true
end

itest.teardown = function ()
  clear_map()
  teardown_map_data()
end

-- interrupt variable jump at the end of frame 2
-- at frame 1: bpos (4, 80), velocity (0, 0), grounded (waits 1 frame before confirming hop/jump)
-- at frame 2: bpos (4, 80 - 3.25), velocity (0, -3.25), airborne (jump confirmed)
itest:add_action(time_trigger(2, true), function ()
  stage.state.player_char.hold_jump_intention = false
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
  local is_motion_state_expected, motion_state_message = motion_states.airborne == stage.state.player_char.motion_state, "Expected motion state 'airborne', got "..stage.state.player_char.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(4, 80 - 20.546875), stage.state.player_char:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_char.ground_speed, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, -0.03125), stage.state.player_char.velocity, 1/256)

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
  stage.state.player_char:spawn_at(vector(4., 80. - pc_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_char.control_mode = control_modes.puppet
  stage.state.player_char.motion_mode = motion_modes.platformer

  -- start jump
  stage.state.player_char.jump_intention = true  -- will be consumed
  stage.state.player_char.hold_jump_intention = true
end

itest.teardown = function ()
  clear_map()
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
  local is_motion_state_expected, motion_state_message = motion_states.airborne == stage.state.player_char.motion_state, "Expected motion state 'airborne', got "..stage.state.player_char.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(4, 80 - 49.921875), stage.state.player_char:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_char.ground_speed, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, -0.078125), stage.state.player_char.velocity, 1/256)

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


--[[

-- if the player presses the jump button in mid-air, the character should not
--  jump again when he lands on the ground (later, it will trigger a special action)
itest = integration_test('platformer no predictive jump in air', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  -- add tiles where the character will move
  mset(0, 10, 64)

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_char:spawn_at(vector(4., 80. - pc_data.center_height_standing))  -- set bottom y at 80
  -- this is an end-to-end test because we don't want bother with how mid-air predicitve jump order is ignored
  --  indeed, if it is ignored by ignoring the input itself, then hijacking the jump_intention
  --  in puppet mode will prove nothing
  -- if it is ignored by resetting the jump intention on land, the puppet test would be useful
  --  to show that the intention itself is reset, but here we only want to ensure the end-to-end behavior is correct
  --  so we us a human control mode and hijack the input directly
  stage.state.player_char.control_mode = control_modes.human
  stage.state.player_char.motion_mode = motion_modes.platformer

  -- start hop
  input.simulated_buttons_down[0][button_ids.o] = true
end

itest.teardown = function ()
  clear_map()
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

-- end of frame 2: end short press for a hop
itest:add_action(time_trigger(1, true), function ()
  input.simulated_buttons_down[0][button_ids.o] = false
end)

-- frame bug: it seems that 1+19!=20, time_trigger(1) is just ignored and it will give frame 19
-- end of frame 20: at the jump apogee, try another jump press
itest:add_action(time_trigger(19, true), function ()
  input.simulated_buttons_down[0][button_ids.o] = true
end)

-- end of frame 21: end short press
itest:add_action(time_trigger(1, true), function ()
  input.simulated_buttons_down[0][button_ids.o] = false
end)

-- frame bug: it seems that character will be on ground during frames +16 and +17
--  not sure why since he only needs 1 frame to confirm a hop
-- wait for character to land (frame 39) and see if he hops again
-- for now, to be safe we +19 -> frame 40, but actually supposedly frame 39 also works due to frame bug mentioned above
-- frame 40: character should still be on ground, not re-jump
itest:add_action(time_trigger(19, true), function ()
end)

-- check that player char has moved to the right and fell
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.grounded == stage.state.player_char.motion_state, "Expected motion state 'airborne', got "..stage.state.player_char.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(4, 80.), stage.state.player_char:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_char.ground_speed, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, 0), stage.state.player_char.velocity, 1/256)

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
  stage.state.player_char:spawn_at(vector(4., 80. - pc_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_char.control_mode = control_modes.puppet
  stage.state.player_char.motion_mode = motion_modes.platformer

  -- start full jump and immediately try to move right
  stage.state.player_char.jump_intention = true  -- will be consumed
  stage.state.player_char.hold_jump_intention = true
end

itest.teardown = function ()
  clear_map()
  teardown_map_data()
end

-- wait 2 frame (1 to register jump, 1 to confirm and leave ground) then move to the right
-- this is just to avoid starting moving on the ground, as we only want to test air control here,
--  not how ground speed is transferred to air velocity
itest:add_action(time_trigger(2, true), function ()
  stage.state.player_char.move_intention = vector(1, 0)
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
  local is_motion_state_expected, motion_state_message = motion_states.airborne == stage.state.player_char.motion_state, "Expected motion state 'airborne', got "..stage.state.player_char.motion_state
  local is_position_expected, position_message = almost_eq_with_message(vector(4 + 20.390625, 80 - 49.921875), stage.state.player_char:get_bottom_center(), 1/256)
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_char.ground_speed, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(1.359375, -0.078125), stage.state.player_char.velocity, 1/256)

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

--[[

-- bugfix history:
-- + revealed that spawn_at was not resetting state vars, so added _setup method
itest = integration_test('platformer ground wall block right', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  --   X
  -- XXX
  mset(0, 10, 64)  -- to walk on
  mset(1, 10, 64)  -- to walk on
  mset(2, 10, 64)  -- for now, we need supporting block
  mset(2,  9, 64)  -- blocking wall

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_char:spawn_at(vector(4., 80. - pc_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_char.control_mode = control_modes.puppet
  stage.state.player_char.motion_mode = motion_modes.platformer

  -- start moving to the right from frame 0 by setting intention in setup
  stage.state.player_char.move_intention = vector(1, 0)
end

itest.teardown = function ()
  clear_map()
  teardown_map_data()
end


-- wait 29 frames and stop
-- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
-- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
-- character will be blocked when right wall sensor is at x = 16, so when center is at x = 12
-- at frame 1: pos (4 + 0.0234375, 80), velocity (0.0234375, 0), grounded
-- at frame 27: pos (12.8359375, 80 - 8), velocity (0.6328125, 0), about to meet wall
-- at frame 28: pos (13, 80 - 8), velocity (0, 0), hit wall
itest:add_action(time_trigger(28, true), function () end)

-- check that player char has moved to the right and is still on the ground
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.grounded == stage.state.player_char.motion_state, "Expected motion state 'grounded', got "..stage.state.player_char.motion_state
  -- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
  local is_position_expected, position_message = almost_eq_with_message(vector(13., 80.), stage.state.player_char:get_bottom_center(), 1/256)
  -- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_char.ground_speed, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, 0), stage.state.player_char.velocity, 1/256)

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

--[[

itest = integration_test('platformer slope wall block right', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  mset(0, 10, 64)  -- to walk on
  mset(1, 10, 64)  -- support ground for slope
  mset(1,  9, 67)  -- ascending slope 22.5 to walk on
  mset(2,  8, 64)  -- blocking wall at the top of the slope

  flow:change_gamestate_by_type(stage.state.type)

  -- respawn character on the ground (important to always start with grounded state)
  stage.state.player_char:spawn_at(vector(4., 80. - pc_data.center_height_standing))  -- set bottom y at 80
  stage.state.player_char.control_mode = control_modes.puppet
  stage.state.player_char.motion_mode = motion_modes.platformer

  -- start moving to the right from frame 0 by setting intention in setup
  stage.state.player_char.move_intention = vector(1, 0)
  -- cheat for fast startup (velocity will be updated on first frame)
  stage.state.player_char.ground_speed = 40
end

itest.teardown = function ()
  clear_map()
  teardown_map_data()
end

-- wait 29 frames and stop

-- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
-- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
-- character will be blocked when right wall sensor is at x = 16, so when center is at x = 12
-- remember character must reach x=13 (not visible, inside frame calculation) to detect the wall, then snap to 12!
-- at frame 1: pos (4 + 0.0234375, 80), velocity (0.0234375, 0), grounded

-- at frame 12: bpos (5.828125, 80), velocity (0.28125, 0), ground_speed(0.28125)
-- at frame 13: bpos (6.1328125, 79), velocity (0.3046875, 0), ground_speed(0.3046875), first step on slope and at higher level than flat ground, acknowledge slope as current ground
-- at frame 14: bpos (6.333572387695, 79), velocity (0.2007598876953125, -0.2007598876953125), ground_speed(0.283935546875), because slope was current ground at frame start, slope factor was applied with 0.0625*sin(45) = -0.044189453125 (in PICO-8 16.16 fixed point precision)
-- at frame 15: bpos (6.519668501758, 79), velocity (0.1860961140625, -0.1860961140625), ground_speed(0.26318359375), still under slope factor effect and velocity following slope tangent
-- problem: with slope 45, character slows down and never get past x=7
-- instead, we just cheat and add an extra speed, then just check the final position after a long time enough to reach the block at the top

-- at frame 27: pos (12.8359375, 80 - 8), velocity (0.6328125, 0), about to meet wall
-- at frame 28: pos (13, 80 - 8), velocity (0, 0), hit wall

-- at frame  1: bpos (4.0234375, 80), velocity (0.0234375, 0), ground_speed(0.0234375)
-- at frame  9: bpos (5.0546875, 80), velocity (0.2109375, 0), ground_speed(0.2109375)
-- at frame 10: bpos (5.2890625, 80), velocity (0.234375, 0), ground_speed(0.234375)
-- at frame 11: bpos (5.546875, 80), velocity (0.2578125, 0), ground_speed(0.2578125)

-- even at 22.5, character doesn't manage to climb up perfectly and oscillates near the top...

-- note that speed decrease on slope is not implemented yet (via cosine but also gravity), so this test will have to change when it is
--  when it is, prefer passing a very low slope or apply slope factor to adapt the position/velocity calculation

itest:add_action(time_trigger(28, true), function () end)

-- check that player char has moved to the right and is still on the ground
itest.final_assertion = function ()
  local is_motion_state_expected, motion_state_message = motion_states.grounded == stage.state.player_char.motion_state, "Expected motion state 'grounded', got "..stage.state.player_char.motion_state
  -- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
  -- actually 13 if we use more narrow ground sensor
  local is_position_expected, position_message = almost_eq_with_message(vector(13, 80 - 8), stage.state.player_char:get_bottom_center(), 1/256)
  -- to compute speed s from s0 after n frames at accel a: x = s0 + n*a
  local is_ground_speed_expected, ground_speed_message = almost_eq_with_message(0, stage.state.player_char.ground_speed, 1/256)
  local is_velocity_expected, velocity_message = almost_eq_with_message(vector(0, 0), stage.state.player_char.velocity, 1/256)

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

--[[ Really comment this block out for now, as it makes too many chars

--[[#pico8
-- human test for pico8 only to check rendering
-- bugfix history:
-- = fixed character pivot computed from drawn sprite topleft (with some gap above character's head)
--   and not actual sprite topleft in the spritesheet
itest = integration_test('character is correctly rendered idle', {stage.state.type})
itest_manager:register(itest)

itest.setup = function ()
  setup_map_data()

  mset(0, 10, 64)  -- to stand on

  flow:change_gamestate_by_type(stage.state.type)
  stage.state.player_char:warp_bottom_to(vector(4., 80.))
  stage.state.player_char.control_mode = control_modes.puppet
  stage.state.player_char.motion_mode = motion_modes.debug
end

itest.teardown = function ()
  clear_map()
  teardown_map_data()
end

-- wait just 0.1 second so the character can be rendered at least 1 frame because the test pauses
itest:add_action(time_trigger(1.), function () end)

-- no final assertion, let the user check if result is correct or not (note it will display success whatever)
--#pico8]]

--]]

-- gamestates: stage
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test, time_trigger = integrationtest.itest_manager, integrationtest.integration_test, integrationtest.time_trigger
local itest_dsl = require("itest/itest_dsl")
local itest_dsl_parser = itest_dsl.itest_dsl_parser
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local pc_data = require("data/playercharacter_data")

local itest

-- itests are too big in terms of chars and will reach the max easily
--  so we keep them to a minimum in PICO-8 itest build
-- build we still want to run them as headless itests, in particular during CI
--  so we uncomment them gradually while adding --#if busted to strip them from
--  itest build
-- unfortunately various itests were broken without me noticing while they were
--  commented out, so I'm trying to uncomment them one by one now
-- it's less a problem now that the itests have been useful during development
--  and as we're closer to release, human test for game feel becomes more important

-- debug motion

--#if busted

itest_dsl_parser.register(
  'debug move right', [[
@stage #
.#

set_motion_mode debug
warp 0 8
move right
wait 2

expect pc_bottom_pos 0.3 8
]])

-- calculation notes:
-- F1: ACC 0.1 SPD 0.1 X 0.1
-- F1: ACC 0.1 SPD 0.2 X 0.3

--#endif

-- ground motion

-- common calculation notes:
-- to compute position x from x0 after n frames at accel a from speed s0: x = x0 + n*s0 + n(n+1)/2*a
-- to compute speed s from s0 after n frames at accel a: x = s0 + n*a

--[=[

-- currently fails on busted with 4, 11 and PICO-8 with 4, 8!
itest_dsl_parser.register(
  'platformer stand half tile', [[
@stage #
.
=

warp 4 8
wait 10

expect pc_bottom_pos 4 12
expect pc_motion_state grounded
expect pc_ground_spd 0
expect pc_velocity 0 0
]])

--]=]

--[=[

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

--]=]

-- commented out to fit in 65536 chars
-- but you can run them anytime as headless itests with busted
-- however, note that airborne tests are broken due to the new air drag feature
-- so either set air_drag_factor_per_frame to 0 for the itests,
-- or update all the airborne itests
-- or use broader expectations such as Sonic being in a certain area or reaching a large trigger

--[=[

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
-- note that I reduced frame count from 15 tp 14 as I didn't want to check slope factor reduction too much
-- eventually it's more a utest than an itest, but fine
-- I will stop doing those super-precise checks anyway, since I may add for Original Features not matching
-- Sonic behavior exactly
itest_dsl_parser.register(
  'platformer ascending slope right', [[
@stage #
..
./
#.

warp 4 16
move right
wait 14

expect pc_bottom_pos 6.36378532203461338585 15
expect pc_motion_state grounded
expect pc_slope -0.125
expect pc_ground_spd 0.3266448974609375
expect pc_velocity 0.23097282203461338585 -0.23097282203461338585
]])

-- expect pc_bottom_pos 0x0006.8509 15
-- expect pc_motion_state grounded
-- expect pc_slope -0.125
-- expect pc_ground_spd 0.26318359375
-- expect pc_velocity 0x0000.2fa4 -0x0000.2fa5
-- ]])

--[[
Frame       Ground Speed     Velocity     Bottom Pos
    1
--]]

-- precision note on expected pc_bottom_pos:
-- 6.5196685791015625, 15 (0x0006.8509, 0x000f.0000) in PICO-8 fixed point precision
-- 6.5196741403377, 15 in Lua floating point precision

-- precision note on expected pc_velocity:
-- 0.18609619140625, −0.186111450195 (0x0000.2fa4, 0xffff.d05b = -1 + 0x0000.d05b = -0x0000.2fa5) in PICO-8 fixed point precision
-- (we cannot use 0xffff. which would be interpreted as 65535; also note that vx != -vy due to cos imprecision of 0x0001 I guess)
-- 0.1860922277609, -0.1860922277609 in Lua floating point precision

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

-- from here, we apply Original feature (not in SPG): Progressive Ascending Steep Slope Factor
-- without Original Feature: at frame 14: bpos (6.333572387695, 15), velocity (0.2007598876953125, -0.2007598876953125), ground_speed(0.283935546875), because slope was current ground at frame start, slope factor was applied with 0.0625*sin(45) = -0.044189453125 (in PICO-8 16.16 fixed point precision)
-- with Original Feature: at frame 14: bpos (6.333572387695, 15), velocity (0.23097282203461338585, -0.23097282203461338585), ground_speed(0.32665186087253), because slope was current ground at frame start, slope factor was applied with 1/60/0.5*0.0625*sin(45) = -0.001472982 ~ 0xffff.ffd0 (in PICO-8 16.16 fixed point precision)
-- but still applying normal accel 0.0234375
-- on this slope, divide ground speed in *sqrt(2) on x and y, hence velocity
-- y snaps to integer floor so it's just deduced from x as 15


-- bugfix history:
-- + revealed that spawn_at was not resetting state vars, so added _setup method
itest_dsl_parser.register(
  'platformer ground wall block right', [[
@stage #
..#
##.

warp 4 8
move right
wait 28

expect pc_bottom_pos 13 8
expect pc_motion_state grounded
expect pc_ground_spd 0
expect pc_velocity 0 0
]])

-- calculation notes

-- wait 28 frames and stop
-- character will be blocked when right wall sensor is at x = 16.5, so when center will be at x = 13

-- at frame 1: pos (4 + 0.0234375, 8), velocity (0.0234375, 0), grounded
-- at frame 27: pos (12.8359375, 8), velocity (0.6328125, 0), about to meet wall
-- at frame 28: pos (13, 8), velocity (0, 0), hit wall


itest_dsl_parser.register(
  'platformer slope ceiling block right', [[
@stage #
..#
.<.
#..

warp 4 16
set pc_ground_spd 3
move right
wait 4

expect pc_bottom_pos 13 11
expect pc_motion_state grounded
expect pc_ground_spd 0
expect pc_velocity 0 0
]])


-- calculation notes

-- ground speed start at 40 for fast startup (velocity will be updated on first frame)

-- wait 29 frames and stop

-- character will be blocked when right wall sensor is at x = 16.5, so when center will be at x = 13

-- if move intention is applied after slope factor (or both are applied, then ground speed is clamped as we should):
-- at frame 1: pos (7, 14), velocity (3, 0), grounded
-- at frame 2: pos (7 + 0x0002.c589 = 9.771621704102, 13), velocity (3, 0), grounded
-- at frame 3: pos (7 + 2 * 0x0002.c589 = 12.543243408204, 11), velocity (3, 0), grounded
-- at frame 4: pos (13, 11), velocity (3, 0), grounded

-- in practice, slope after is applied after intention, causing a slight decel:

-- frame 2: ground speed 2.9995
-- frame 3: ground speed 2.9991

-- however, this strongly depends on the slope factor x intention combination before clamping
-- and is likely to change, so no need to test this far for being blocked by the final ceiling


-- air motion

-- bugfix history:
-- . test failed because initial character position was wrong in the test
-- * test failed in pico8 only because in _compute_closest_ground_query_info,
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

-- this test is now failing, I suspect air friction to mess up X...
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
expect pc_motion_state falling
expect pc_ground_spd 0
expect pc_velocity 0.84375 2.625
]])

-- calculation notes:
-- at frame 1: pos (17.9453125, 8), velocity (0.796875, 0), grounded
-- at frame 34: pos (17.9453125, 8), velocity (0.796875, 0), grounded
-- at frame 35: pos (18.765625, 8), velocity (0.8203125, 0), grounded (do not apply ground sensor extent: -2.5 directly, floor to full px first)
-- at frame 36: pos (19.609375, 8), velocity (0.84375, 0), falling (flr_x=19) -> stop accel
-- wait 24 frames and stop
-- gravity during 24 frames: accel = 0.109375 * (24 * 25 / 2), velocity = 0.109375 * 24 = 2.625
-- at frame 60: pos (39.859375, 8 + 32.8125), velocity (0.84375, 2.625), falling

--]=]

--[=[

-- this test is now failing by 1 frame because jump is interrupted on frame 3 only...
-- not sure why, otherwise hoping works fine in real game
itest_dsl_parser.register(
  'platformer hop flat', [[
@stage #
.
#

warp 4 8
jump
stop_jump
wait 20

expect pc_bottom_pos 4 -11.296875
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0 -0.03125
]])

-- calculation notes

-- wait for apogee (frame 20) and stop
-- at frame 1:  bpos (4, 8), velocity (0, 0), grounded (waits 1 frame before confirming hop/jump)
-- at frame 2:  bpos (4, 8 - 2), velocity (0, -2), air_spin (hop confirmed, no gravity applied this frame)
-- at frame 3:  bpos (4, 8 - 3.890625), velocity (0, -1.890625), air_spin
-- at frame 19: pos (4, 8 - 19.265625), velocity (0, -0.140625), air_spin -> before apogee
-- at frame 20: pos (4, 8 - 19.296875), velocity (0, -0.03125), air_spin -> reached apogee
-- at frame 21: pos (4, 8 - 19.21875), velocity (0, 0.078125), air_spin -> starts going down
-- at frame 38: pos (4, 8 - 1.15625), velocity (0, 1.9375), air_spin ->  about to land
-- at frame 39: pos (4, 8), velocity (0, 0), grounded -> has landed

-- => apogee at y = 8 - 19.296875 = -11.296875

--]=]

--[=[

itest_dsl_parser.register(
  'platformer jump start flat', [[
@stage #
.
#

warp 4 8
jump
wait 2

expect pc_bottom_pos 4 4.75
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0 -3.25
]])


itest_dsl_parser.register(
  'platformer jump interrupt flat', [[
@stage #
.
#

warp 4 8
jump
wait 4
stop_jump
wait 1

expect pc_bottom_pos 4 -3.421875
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0 -2
]])

-- calculation notes

-- interrupt variable jump at the end of frame 2
-- at frame 1: bpos (4, 8), velocity (0, 0), grounded (waits 1 frame before confirming hop/jump)
-- at frame 2: bpos (4, 8 - 3.25), velocity (0, -3.25), air_spin (jump confirmed)
-- at frame 3: bpos (4, 8 - 6.390625), velocity (0, -3.140625), air_spin
-- at frame 4: bpos (4, 8 - 9.421875), velocity (0, -3.03125), air_spin
-- at frame 5: bpos (4, 8 - 11.421875), velocity (0, -2), air_spin (interrupt jump, no extra gravity)


itest_dsl_parser.register(
  'platformer small jump flat', [[
@stage #
.
#

warp 4 8
jump
wait 4
stop_jump
wait 6

expect pc_bottom_pos 4 -11.78125
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0 -1.453125
]])

-- calculation notes

-- frames 1-5 is same as 'platformer jump interrupt flat'

-- wait 5 frames and stop
-- at frame 6:  bpos (4, 8 - 13.3125), velocity (0, -1.890625), air_spin
-- at frame 7:  bpos (4, 8 - 15.09375), velocity (0, -1.78125), air_spin
-- at frame 8:  bpos (4, 8 - 16.765625), velocity (0, -1.671875), air_spin
-- at frame 9:  bpos (4, 8 - 18.328125), velocity (0, -1.5625), air_spin
-- at frame 10: bpos (4, 8 - 19.78125), velocity (0, -1.453125), air_spin


itest_dsl_parser.register(
  'platformer full jump flat', [[
@stage #
.
#

warp 4 8
jump
wait 31

expect pc_bottom_pos 4 -41.921875
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0 -0.078125
]])

-- calculation notes

-- wait for the apogee (frame 31) and stop
-- at frame 1: bpos (4, 8), velocity (0, 0), grounded (waits 1 frame before confirming hop/jump)
-- at frame 2: bpos (4, 8 - 3.25), velocity (0, -3.25), air_spin (do not apply gravity on first frame of jump since we were grounded)
-- at frame 30: bpos (4, 8 - 49.84375), velocity (0, -0.1875), air_spin -> before apogee
-- at frame 31: bpos (4, 8 - 49.921875), velocity (0, -0.078125), air_spin -> reached apogee (100px in 16-bit, matches SPG on Jumping)
-- at frame 32: bpos (4, 8 - 49.890625), velocity (0, 0.03125), air_spin -> starts going down
-- at frame 61: bpos (4, 8 - 1.40625), velocity (0, 3.203125), air_spin -> about to land
-- at frame 62: bpos (4, 8), velocity (0, 0), grounded -> has landed


itest_dsl_parser.register(
  'ignore hold jump landing', [[
@stage #
.
#

warp 4 8
jump
stop_jump
wait 20
set_control_mode human
press o
wait 20

expect pc_bottom_pos 4 8
expect pc_motion_state grounded
expect pc_ground_spd 0
expect pc_velocity 0 0
]])

-- if the player presses the jump button in mid-air, the character should not
--  jump again when he lands on the ground (later, it will trigger a special action)

-- input note:
-- this is an end-to-end test because we don't want bother with how mid-air predicitve jump order is ignored
--  indeed, if it is ignored by ignoring the input itself, then hijacking the jump_intention
--  in puppet mode will prove nothing
-- if it is ignored by resetting the jump intention on land, the puppet test would be useful
--  to show that the intention itself is reset, but here we only want to ensure the end-to-end behavior is correct
--  so we us a human control mode and hijack the input directly

-- calculation notes:
-- wait for apogee (frame 20) and stop
-- at frame 1:  bpos (4, 8), velocity (0, 0), grounded (waits 1 frame before confirming hop/jump)
-- at frame 2:  bpos (4, 8 - 2), velocity (0, -2), air_spin (hop confirmed)
-- at frame 3:  bpos (4, 8 - 3.890625), velocity (0, -1.890625), air_spin (hop confirmed)
-- at frame 19: bpos (4, 8 - 19.265625), velocity (0, -0.140625), air_spin -> before apogee
-- at frame 20: bpos (4, 8 - 19.296875), velocity (0, -0.03125), air_spin -> reached apogee
-- at frame 21: bpos (4, 8 - 19.21875), velocity (0, 0.078125), air_spin -> starts going down
-- at frame 38: bpos (4, 8 - 1.15625), velocity (0, 1.9375), air_spin ->  about to land
-- at frame 39: bpos (4, 8), velocity (0, 0), grounded -> has landed

-- and wait an extra frame to see if Sonic will jump due to holding jump input,
-- so stop at frame 40


itest_dsl_parser.register(
  'platformer jump air accel', [[
@stage #
.
#

warp 4 8
jump
wait 2
move right
wait 29

expect pc_bottom_pos 24.390625 -41.921875
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 1.359375 -0.078125
]])

itest_dsl_parser.register(
  'platformer air right wall block', [[
@stage #
.#
.#
..
#.

warp 4 24
jump
stop_jump
wait 1
move right
wait 9

expect pc_bottom_pos 5 9.9375
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0 -1.125
]])

-- calculation notes:
-- start jump input
-- at frame 1:  bpos (4, 24), velocity (0, 0), grounded
-- wait 1 frame to confirm hop, and start moving right, then wait 9 frames
-- at frame 2:  bpos (4 + .046875, 24 - 2), velocity (3/64, -2), air_spin (hop)
-- at frame 3:  bpos (4.140625, 24 - 3.890625), velocity (6/64, -1 - 57/64), air_spin
-- at frame 4:  bpos (4.28125, 24 - 5.671875), velocity (9/64, -1 - 50/64), air_spin
-- at frame 5:  bpos (4.46875, 24 - 7.34375), velocity (12/64, -1 - 43/64), air_spin
-- at frame 6:  bpos (4.703125, 24 - 8.90625), velocity (15/64, -1 - 36/64), air_spin
-- UPDATE: here, abs(vx) > air_drag_min_velocity_x (0.25) so we multiply vx by air_drag_factor_per_frame (62/64 = 0.96875)
-- so new vx = 18/64 * 0.96875 = 0.2724609375 or 18/64 * 62/64 = 279/1024
-- and new x = 4.703125 + 0.2724609375 = 4.9755859375
-- at frame 7:  bpos (4.9755859375, 24 - 10.359375), velocity (0.2724609375, -1 - 29/64), air_spin
-- after 7 frames, we are almost touching the wall above
-- new vx = (0.2724609375 + 3/64) * 62/64 = 0.309356689453125
-- new x = 4.9755859375 + 0.309356689453125 = 5.284942626953125 -> blocked to 5.0
-- at frame 8:  bpos (5, 24 - 11.703125), velocity (0.309356689453125, -1 - 22/64), air_spin (hit wall)
-- after 8 frames, we have hit the wall
-- at frame 9:  bpos (5, 24 - 12.9375), velocity (0, -1 - 15/64), air_spin (hit wall)
-- at frame 10: bpos (5, 24 - 14.0625), velocity (0, -1 - 8/64), air_spin (hit wall)

-- /64 format is nice, but I need to make a helper
-- that converts floats to this format if I want a meaningful
-- comparison with itest trace log

-- the test below used to block Sonic completely but since we don't check
--  ground when going up at high diagonal, nor ceiling not high enough relative to
--  character center, the character started to get past the block during the last two frames,
--  hence the slightly positive x/vx
-- to preserve the original expectations we duplicated the itest above,
--  except we added another block above the existing one to really block Sonic in the air
itest_dsl_parser.register(
  'platformer air right wall block then just above', [[
@stage #
.#
..
#.

warp 4 16
jump
stop_jump
wait 1
move right
wait 9

expect pc_bottom_pos 5.140625 1.9375
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0.09375 -1.125
]])

itest_dsl_parser.register(
  'platformer air left wall block', [[
@stage #
#.
#.
..
.#

warp 12 24
jump
stop_jump
wait 1
move left
wait 9

expect pc_bottom_pos 11 9.9375
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0 -1.125
]])

itest_dsl_parser.register(
  'platformer air left wall block', [[
@stage #
#.
..
.#

warp 12 16
jump
stop_jump
wait 1
move left
wait 9

expect pc_bottom_pos 10.859375 1.9375
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity -0.09375 -1.125
]])

itest_dsl_parser.register(
  'platformer air ceiling block', [[
@stage #
#
.
.
.
#

warp 4 32
jump
wait 7

expect pc_bottom_pos 4 16
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0 0
]])

-- calculation notes

-- we are now using sonic compact height = 8 during jump
--   so he will hit ceiling at bottom pos = (1 tile '#') * 8 + 8 = 16 = 32 - 16
--   where 32 is the initial bottom pos, so we need to jump over 16px

-- wait for the apogee (frame 31) and stop
-- frame  bottom pos            velocity         state     event
-- 1      (4, 32)               (0, 0)           grounded
-- 2      (4, 32 - 3  - 16/64)  (0, -3 - 16/64)  air_spin  confirm jump (no gravity on first frame)
-- 3      (4, 32 - 6  - 25/64)  (0, -3 -  9/64)  air_spin
-- 4      (4, 32 - 8)           (0, 0)           air_spin
-- 4      (4, 32 - 9  - 27/64)  (0, -3 -  2/64)  air_spin
-- 5      (4, 32 - 12 - 22/64)  (0, -2 - 59/64)  air_spin
-- 6      (4, 32 - 15 - 10/64)  (0, -2 - 52/64)  air_spin
-- 7      (4, 32 - 16)          (0, 0)           air_spin  hit ceiling

--]=]

--[=[

itest_dsl_parser.register(
  'platformer air ceiling corner block', [[
@stage #
##
#.
#.
##

warp 11 24
jump
move left
wait 5

expect pc_bottom_pos 11 16
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity 0 0
]])

-- should hit ceiling at frame 5, Y 12
-- when ceiling bug was active, removing the "move left" instruction
--  proved it as the test would pass with a vertical jump that stops at:
--[[
[frame] frame #4
[trace] self.position: vector(11.0, 13.609375)
[trace] self.velocity: vector(0.0, -3.140625)
[frame] frame #5
[trace] self.position: vector(11.0, 12.0) (add 4 for bottom pos, so 16)
[trace] self.velocity: vector(0.0, 0)
--]]

--]=]

--[=[

-- complete test above with velocity, must be positive above all
-- test below is more complex, forget about it

itest_dsl_parser.register(
  'platformer air ceiling corner block (loop)', [[
@stage #
YZ.
...
...
...
...
...
...
###

warp 20 56
jump
move left
wait 17

expect pc_bottom_pos 14.17681884765625 17.125
expect pc_motion_state air_spin
expect pc_ground_spd 0
expect pc_velocity -0x000.9aba -1.609375
]])

--]=]


-- itest

-- [frame] frame #20
-- [trace] self.position: vector(12.2065, 8.9531)
-- [trace] self.velocity: vector(-0.6816, -1.2812)
-- [frame] frame #21
-- [trace] self.position: vector(11.5008, 7.7812)
-- [trace] self.velocity: vector(-0.7057, -1.1719)
-- [frame] frame #22
-- [trace] self.position: vector(11, 6.7188)
-- [trace] self.velocity: vector(0, -1.0625)


-- vs

-- [frame] frame #20
-- [trace] self.position: vector(12.207809448242, 8.953125)
-- [trace] self.velocity: vector(-0.68148803710938, -1.28125)
-- [frame] frame #21
-- [trace] self.position: vector(11.502212524414, 8)
-- [trace] self.velocity: vector(-0.70559692382812, 0)
-- [frame] frame #22
-- [trace] self.position: vector(11, 8.109375)
-- [trace] self.velocity: vector(0, 0.109375)

-- calculation notes

-- wait ceiling hit (frame 31) and stop
-- at frame 1: bpos (19.9765625, 56), velocity (-0.0234375, 0), grounded (apply ground accel, waits 1 frame before confirming jump)
-- at frame 2: bpos (19.90625, 56 - 3.25), velocity (-0.0703125, -3.25), air_spin (apply air accel, do not apply gravity on first frame of jump since we were grounded)
-- at frame 3: bpos (19.7890625, 56 - 6.390625), velocity (-0.1171875, -3.140625), air_spin (start applying gravity)
-- ...
-- unfortunately vx is affected by air drag which is hard to sum
-- but we really care about y and vy in this test, moving in x is only to reproduce the "jump through ceiling" when moving diagonally" bug
-- so we cheat and copy-paste retroactively the itest result passed values into expectations there
-- which gives expected velocity = 0.604400634765625 - -0x000.9aba
-- at frame 2+n: bpos (19.90625-0.0703125*n-0.046875*n*(n+1)/2, 56 - 3.25 - 3.25*n + 0.109375*n*(n+1)/2), velocity (-0.0703125-0.046875*n REDUCED BY DRAG, -3.25+0.109375*n), air_spin

-- we approach ceiling when 56 - 3.25*n + 0.109375*n*(n+1)/2 = 16 <=> 40 + (-3.25+0.109375/2)*n + 0.109375/2*n*n = 0
-- a = 0.0546875
-- b = -3.1953125
-- c = 40
-- DELTA = b*b - 4ac = 1.46002197265625 (should be small since we aim for position close to ceiling which is also close to apogee so both solutions are close to it)
-- just to check:
-- -b/2a = 29.21428571428571428571 (apogee, at 30 frames as we know)
-- We are interested in the first time we reach the ceiling of course, so:
-- s1 = (-b - sqrt(DELTA)) / (2*a) = 18.16684626582767176288
-- so let's explore around 18

-- at frame 17: bpos (4, 17.125), velocity (-0.7734375, -1.609375), air_spin -> before apogee
-- at frame 18: bpos (4, 15.625), velocity (0, -1.5), air_spin -> before apogee
-- at frame 2+n: bpos (19.90625-0.0703125*n-0.046875*n*(n+1)/2, 18.875), velocity (-0.0703125-0.046875*n, -3.25+0.109375*n), air_spin
-- at frame 31: bpos (4, 8 - 49.921875), velocity (0, -0.078125), air_spin -> reached apogee (100px in 16-bit, matches SPG on Jumping)

-- added to fix #129 BUG MOTION curve_run_up_fall_in_wall
-- with bug, character is preserving his center but when falling without spinning,
--  his shape is a rectangle not a square, so the instant rotation of 90 degrees
--  will place his feet inside the wall just above the steep slope (responsible
--  for the sudden quadrant change)
-- with the fix, his position should be readjusted so his feet really just touch the wall
--  increasing max_ground_escape_height to 6 can hotfix the thing, but it would still take
--  2 frames to move down a full pixel and trigger the escape during ground motion
-- that's why we prefer solving the issue on frame 9 (when landing is done) and not frame 11
-- note that in the tilemap, we add the column of # for a realistic case,
--  but even without them the issue appears, which makes us think the issue is the same as
--  #128 BUG MOTION edgy_rising_curve_sonic_stuck and possibly
--  #131 BUG MOTION fall_on_curve_to_death

--#if busted
itest_dsl_parser.register(
  'fall on curve top', [[
@stage #
..#
..#
.i#

warp 13 12
wait 9

expect pc_bottom_pos 15 8
expect pc_motion_state grounded
expect pc_velocity 0 0.984375
]])
--#endif

-- variant after discovering:
--  #189 BUG MOTION walking up loop stopping midway falls in wall right without safety offset
-- WIP
itest_dsl_parser.register(
  '#mute fall inside curve top after rising', [[
@stage #
..#
..#
..#
..#
.i#

warp 11 42
set pc_velocity 1 -2
move right
wait 60

expect pc_bottom_pos 15 8
expect pc_motion_state grounded
expect pc_velocity 0 0.984375
]])

--[=[

itest_dsl_parser.register(
  'bounce on spring (escape)', [[
@stage #
..
..
..
..
sS

warp 10 34
wait 1

expect pc_bottom_pos 10 34
expect pc_motion_state falling
expect pc_velocity 0 -5
]])


itest_dsl_parser.register(
  'bounce on spring (land)', [[
@stage #
..
..
..
..
sS

warp 10 33.9
wait 1

expect pc_bottom_pos 10 34
expect pc_motion_state falling
expect pc_velocity 0 -5
]])

--]=]

--[=[

-- human tests: let human check rendering (until I find a way to automate this)
-- they have no final assertion, and will always succeed
-- although it's about rendering, we don't strip them from busted headless itests so we can debug the trace without having to run pico8

-- bugfix history:
-- = fixed character pivot computed from drawn sprite topleft (with some gap above character's head)
--   and not actual sprite topleft in the spritesheet
itest_dsl_parser.register(
  'pc anim idle right', [[
@stage #
.
#

warp 4 8
wait 60
]])

itest_dsl_parser.register(
  'pc anim idle left', [[
@stage #
.
#

warp 4 8
move left
wait 1
stop
wait 59
]])
-- note: due to flooring, character will go 1px to the left in only 1 frame,
-- so it will look offset compared to the previous test with right


itest_dsl_parser.register(
  'pc anim run left and fall', [[
@stage #
...
###

warp 20 8
move left
wait 60
]])


itest_dsl_parser.register(
  'pc anim run right and fall', [[
@stage #
...
###

warp 4 8
move right
wait 60
]])

--]=]

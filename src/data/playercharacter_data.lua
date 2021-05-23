local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")

local pc_data = {

  -- platformer motion
  -- values in px, px/frame, px/frame^2 are /2 compared to SPG since we work with 8px tiles
  -- for values in px, px/frame, px/frame^2, I added /64
  -- for degrees, /360 form
  -- (for readability)

  -- ground acceleration (px/frame^2)
  ground_accel_frame2 = 0.0234375,  -- 1.5/64

  -- ground active deceleration (brake) (px/frame^2)
  ground_decel_frame2 = 0.25,  -- 16/64

  -- ground active deceleration (brake) during toll (px/frame^2)
  ground_roll_decel_frame2 = 0.0625,  -- 4/64

--#if original_slope_features
  -- Original feature (not in SPG): Reduced Deceleration on Descending Slope
  -- ground active deceleration factor on descending slope (no unit, [0-1])
  ground_decel_descending_slope_factor = 0.5,
--#endif

  -- ground friction (passive deceleration) (px/frame^2)
  ground_friction_frame2 = 0.0234375,  -- 1.5/64

  -- ground friction (passive deceleration) during roll (px/frame^2)
  -- interestingly, it is cumulated with active deceleration during roll
  ground_roll_friction_frame2 = 0.01171875,  -- 0.75/64, half of ground_friction_frame2

  -- minimum absolute ground speed required to perform a roll by crouching while moving (px/frame)
  -- Note that we are really using the Sonic & Knuckles value of 1, divided by 2 for PICO-8 scaling,
  --  and not the Sonic 1-3 value of 0.5. This allows character to crouch for spin dash more easily.
  roll_min_ground_speed = 0.5,  -- 32/64

  -- minimum absolute ground speed required to continue a roll, after starting it (px/frame)
  -- if ground speed goes under this (in abs value), Sonic automatically stands up
  continue_roll_min_ground_speed = 0.25,  -- 16/64

  -- slope accel acceleration factor (px/frame^2), to multiply by sin(angle)
  slope_accel_factor_frame2 = 0.0625,  -- 7/64

--#if original_slope_features
  -- Used by 3 original features (not in SPG):
  --  - Reduced Deceleration on Steep Descending Slope
  --  - No Friction on Steep Descending Slope
  --  - Progressive Ascending Steep Slope Factor
  -- max slope angle on which friction is applied (]0-0.25[, but we recommend more than 22.5 degrees i.e. 0.0625)
  --  (PICO-8 angle)
  steep_slope_min_angle = 0.075,  -- 27/360

  -- derived data: the slope angle for which ground friction is exactly opposed to slope factor
  -- is 22.02 degrees ~ 0.061 angle/360 ratio (PICO-8 unit)

  -- Original feature (not in SPG): Progressive Ascending Slope Factor
  -- time needed when ascending a slope before full slope factor is applied (s)
  progressive_ascending_slope_duration = 0.5,
--#endif

  -- Use for Original slope feature: Take-Off Angle Difference
  take_off_angle_difference = 0.125,  -- between 0.125 (45 deg) and 0.25 (90 deg)

  -- air acceleration on x axis (px/frame^2)
  -- from this, air_drag_factor_per_frame, initial_var_jump_speed_frame and gravity,
  --  we can deduce the jump distance X on flat ground when jumping and starting to move
  --  horizontally at the same time (jump without run-up)
  --  air drag makes calculation a bit complicated but observation gives ~9.5 tiles
  air_accel_x_frame2 = 0.046875,  -- 3/64

  -- air drag factor applied every frame, at 60 FPS (no unit)
  -- note that combined with air_accel_x_frame2, we can deduce the actual
  --  max air speed x: air_accel_x_frame2 / (1/air_drag_factor_per_frame - 1)
  --  = 1.453125 px/frame
  -- value comes from 1 - 0.125*256, as SPG mentions value is subtracted by ((previous_value div 0.125) / 256)
  --  but we don't mind about the Euclidian division and just keep the remainder, effectively dividing by 0.125*256
  air_drag_factor_per_frame = 0.96875,  -- 62/64

  -- min absolute velocity x for which air drag is applied (px/frame)
  air_drag_min_velocity_x = 0.25,  -- 16/64

  -- maximum absolute velocity y for which air drag is applied (px/frame)
  -- the actual range is ] -air_drag_max_abs_velocity_y, 0 [
  air_drag_max_abs_velocity_y = 8,  -- 512/64

  -- maximum absolute ground speed when running (standing) (px/frame)
  -- do not force clamping if character is already above (horizontal spring, spin dash + landing...)
  -- from this and the ground acceleration we can deduce the time and distance required to reach
  --  max speed on flat ground:
  -- it takes 3/0.0234375 = 128 frames (~2.1s) to reach max speed
  --  over a distance of 192px (perfect integration) / 193.5px (discrete series sum)
  --  ~ 24 tiles
  max_running_ground_speed = 3,  -- 192/64

  -- maximum absolute air velocity x (px/frame)
  -- should be the same as max_running_ground_speed to avoid slow-down/speed-up
  --  just by jumping while running on flat ground (on slope, it will slow down air motion on X though)
  -- do not force clamping if character is already above (horizontal spring + jump, spin dash + jump...)
  -- from this, initial_var_jump_speed_frame and gravity you can deduce the max jump distance on X
  --  on a flat ground: we know that we land after ~60 frames, so:
  --  max distance X = max_air_velocity_x * 60 = 180 (22.5 tiles)
  max_air_velocity_x = 3,  -- 192/64

  -- ground speed threshold under which character will fall/slide off when walking at more
  --  than 90 degrees, or lock control when walking on wall under 90 degrees (px/frame)
  ceiling_adherence_min_ground_speed = 1.25,  -- 80/64 = 1 + 16/64

  -- range of angle allowing ceiling adherence catch (Sonic lands on the ceiling after touching it/
  --  colliding with it). This applies to top-left and top-right ceiling corners (e.g. in loops),
  --  and ranges are always counted from the right vertical and left vertical, i.e.
  --  [0.25, 0.25 + range] and [0.75 - range, 0.75] resp. (pico8 angle unit)
  ceiling_adherence_catch_range_from_vertical = 0.125,  -- 45/360

  -- duration of horizontal control lock after fall/slide off (frames)
  fall_off_horizontal_control_lock_duration = 30,  -- 0.5s

  -- max air speed (px/frame)
  --  (very high, probably won't happen unless Sonic falls in bottomless pit)
  max_air_velocity_y = 32,  -- 2048/64

  -- initial variable jump speed (Sonic) (px/frame)
  -- from this and gravity we can deduce the max jump height: 49.921875 (6.2 tiles) at frame 31 (~0.5s)
  --  you land with 2x the time, after ~60 frames
  -- when hopping, you'll reach jump height: 19.296875 (2.4 tiles) at frame 20
  initial_var_jump_speed_frame = 3.25,  -- 208/64 = 3 + 16/64

  -- initial hop vertical speed and new speed when jump is interrupted by releasing jump button (px/frame)
  --  note that when jump is interrupted mid-air, gravity should still be applied just after that
  --  which will give a value of 1.890625. for a hop, the initial speed will remain 2.
  jump_interrupt_speed_frame = 2,

  -- absolute vertical speed given by spring bounce (px/frame)
  -- from this and gravity we can deduce the max jump height: 116.71875
  --  (measurement with debug step: 112) ~ 14+ tiles at frame 45
  -- note: this is the value of yellow springs only, red springs would be 8
  spring_jump_speed_frame = 5,

  -- duration of horizontal control lock after bouncing on a spring (frames)
  spring_horizontal_control_lock_duration = 16,

  -- ground speed required to trigger launch ramp (px/frame)
  launch_ramp_min_ground_speed = 2,

  -- speed multiplier for launch ramp effect (px/frame)
  launch_ramp_speed_multiplier = 2.7,

  -- abs maximum of launch speed after applying multiplier (px/frame)
  -- this was added after finding a very rare case of rolling so fast toward the slope
  --  that Sonic was launched above the emerald and almost reached the upper level
  --  (could not repro, but safer esp. considering we may add spin dash later)
  launch_ramp_speed_max_launch_speed = 9.7,

  -- launch angle of ramp (PICO-8 angle)
  launch_ramp_velocity_angle = atan2(8, -5),

  -- duration to ignore launch ramp after trigger to avoid hitting it and landing again
  --  (frames)
  ignore_launch_ramp_duration = 3,

  -- gravity acceleration (px/frame^2)
  gravity_frame2 = 0.109375,  -- 7/64

  -- half-width of ground sensors, i.e. x distance of a ground sensor from the character's center vertical axis
  --  (px)
  -- the 0.5 allows us to always have the sensor above the middle of a pixel (we always offset from a floored coord)
  --  so we can get the right pixel when offsetting to the left and flooring
  -- note that we don't define wall_sensor_extent_x, which is assumed to be ground_sensor_extent_x + 1
  -- see comment in player_char:next_ground_step on last block
  ground_sensor_extent_x = 2.5,

  -- height between the standing character center and the ground sensors, i.e. the height of the character sprite center (0 when the center is at the bottom pixel level)
  --  (px)
  center_height_standing = 8,

  -- height between the ground sensors and the top of the standing character's collider (used to detect ceiling)
  --  (px)
  -- should be 2 * center_height_standing, but left as separate data for customization (e.g. you can add 1 as in the SPG)
  full_height_standing = 16,

  -- same as center_height_standing but when character is crouching, rolling or jumping
  --  (px)
  center_height_compact = 6,

  -- same as full_height_standing but when character is crouching, rolling or jumping
  --  (px)
  -- should be 2 * center_height_compact, but left as separate data for customization (e.g. you can add 1 as in the SPG)
  full_height_compact = 12,

  -- max vertical distance allowed to escape from inside ground (must be < tile_size as
  --  (px)
  --  _compute_closest_ground_query_info uses it as upper_limit tile_size)
  -- also the max step up of the character in ground motion
  max_ground_escape_height = 4,

  -- max vertical distance allowed to snap to a lower ground while running (on step or curve)
  -- a.k.a. max step down
  --  (px)
  max_ground_snap_height = 4,


--#if cheat
  -- debug motion

  -- motion speed in debug mode (px/frame)
  debug_move_max_speed = 6,

  -- acceleration speed in debug mode (px/frame^2)
  debug_move_accel = 0.1,

  -- active deceleration speed in debug mode (px/frame^2)
  debug_move_decel = 2,

  -- friction aka passive deceleration speed in debug mode (px/frame^2)
  debug_move_friction = 1,
--#endif


  -- spin dash

  -- rev increase every time player pressed jump button
  -- note that this is an abstract value, so we don't divide it by 2 like speed values
  -- (no unit)
  spin_dash_rev_increase_step = 2,

  -- when not revving (charging spin dash) this frame, apply this factor to reduce rev slightly
  -- same value as air_drag_factor_per_frame (SPG remarks that)
  -- (no unit)
  spin_dash_drag_factor_per_frame = 0.96875,  -- 62/64

  -- maximum rev value (abstract value, so no division by 2 for PICO-8)
  -- (no unit)
  spin_dash_rev_max = 8,

  -- base launch speed on spin dash release (SPG value / 2) (px/frame)
  spin_dash_base_speed = 4,

  -- factor applied to floor part of spin dash rev to contribute to spin dash launch speed (px/frame)
  -- SPG divides rev by 2, so in PICO-8 units we must divide by 4, so multiply by 0.25
  spin_dash_rev_increase_factor = 0.25,


  -- sprite

  -- speed at which the character sprite angle falls back toward 0 (upward)
  --  when character is airborne (after falling from ceiling or running up and off an ascending slope) (pico8 angle/frame)
  -- SPG: 2/256*360=2.8125° <=> 2/256=1/128=0.0078125 pico8 angle unit
  -- deduced duration to rotate from upside down to upward: 0.5/(1/128) = 64 frames = 1s + 4 frames
  sprite_angle_airborne_reset_speed_frame = 1/128,

  -- stand right
  -- colors.pink: 14
  sonic_sprite_data_table = transform(
    -- anim_name below is not protected since accessed via minified member to define animations more below
    --anim_name = sprite_data(
    --          id_loc,  span,   pivot,   transparent_color (14: pink))
    {
      idle             = {{12, 8}, {2, 2}, {10, 8}, 14},
      walk1            = {{0,  8}, {2, 2}, { 8, 8}, 14},
      walk2            = {{2,  8}, {2, 2}, { 8, 8}, 14},
      walk3            = {{4,  8}, {2, 2}, { 9, 8}, 14},
      walk4            = {{6,  8}, {2, 2}, { 8, 8}, 14},
      walk5            = {{8,  8}, {2, 2}, { 8, 8}, 14},
      walk6            = {{10, 8}, {2, 2}, { 8, 8}, 14},
      brake1           = {{10, 1}, {2, 2}, { 9, 8}, 14},
      brake2           = {{12, 1}, {2, 2}, { 9, 8}, 14},
      brake3           = {{14, 1}, {2, 2}, {11, 8}, 14},
      spring_jump      = {{14, 8}, {2, 3}, { 9, 8}, 14},
      run1             = {{0, 10}, {2, 2}, { 8, 8}, 14},
      run2             = {{2, 10}, {2, 2}, { 8, 8}, 14},
      run3             = {{4, 10}, {2, 2}, { 8, 8}, 14},
      run4             = {{6, 10}, {2, 2}, { 8, 8}, 14},
      spin_full_ball   = {{0, 12}, {2, 2}, { 6, 6}, 14},
      spin1            = {{2, 12}, {2, 2}, { 6, 6}, 14},
      spin2            = {{4, 12}, {2, 2}, { 6, 6}, 14},
      spin3            = {{6, 12}, {2, 2}, { 6, 6}, 14},
      spin4            = {{8, 12}, {2, 2}, { 6, 6}, 14},
      crouch1          = {{12, 8}, {2, 2}, { 7,10}, 14},
      crouch2          = {{14, 8}, {2, 2}, { 7,10}, 14},
      spin_dash_shrink = {{0, 12}, {2, 2}, { 3,10}, 14},
      spin_dash1       = {{2, 12}, {2, 2}, { 3,10}, 14},
      spin_dash2       = {{4, 12}, {2, 2}, { 3,10}, 14},
      spin_dash3       = {{6, 12}, {2, 2}, { 3,10}, 14},
      spin_dash4       = {{8, 12}, {2, 2}, { 3,10}, 14},
    }, function (raw_data)
      return sprite_data(
        sprite_id_location(raw_data[1][1], raw_data[1][2]),  -- id_loc
        tile_vector(raw_data[2][1], raw_data[2][2]),         -- span
        vector(raw_data[3][1], raw_data[3][2]),              -- pivot
        raw_data[4]                                   -- transparent_color
      )
  end),

  -- minimum playback speed for "walk" animation, to avoid very slow animation
  -- 10/16=5/8: the 10 counters the 10 duration frames of ["walk"] below, 1/8 to represent max duration 8 in SPG:Animations
  -- and an extra 1/2 factor because for some reason, SPG values make animations look too fast (as if durations were for 30FPS)
  walk_anim_min_play_speed = 0.625,

  -- same for spinning animation, when rolling (it seems very fast in Sonic 3 even at low ground speed)
  rolling_spin_anim_min_play_speed = 1.25,

  -- same for spinning animation, when airborne
  air_spin_anim_min_play_speed = 0.625,

  -- speed from which the run cycle anim is played, instead of the walk cycle (px/frame)
  run_cycle_min_speed_frame = 3,

  -- speed from which the brake anim is played when decelerating (px/frame)
  brake_anim_min_speed_frame = 2,


  -- pfx

  -- spin dash dust particle spawn period (frames)
  spin_dash_dust_spawn_period_frames = 3.1,

  -- spin dash dust particle spawn count every period
  spin_dash_dust_spawn_count = 4,

  -- spin dash dust particle spawn period (frames)
  spin_dash_dust_lifetime_frames = 34,

  -- spin dash dust particle spawn period (frames)
  spin_dash_dust_base_init_velocity = vector(-0.43, -0.17),

  -- spin dash dust particle spawn period (frames)
  spin_dash_dust_max_deviation = 0.04,

  -- spin dash dust particle spawn period (frames)
  spin_dash_dust_base_max_size = 4.1,
}

local sdt = pc_data.sonic_sprite_data_table

-- define animated sprite data in a second step, as it needs sprite data to be defined first
-- note that we do not split spin_slow and spin_fast as distinguished by SPG anymore
--  in addition, while spin_slow was defined to have 1 spin_full_ball frame and
--  spin_fast had 2, our spin has 4, once every other frame, to match Sonic 3 more closely
pc_data.sonic_animated_sprite_data_table = transform(
  -- access sprite data by non-protected member to allow minification
  -- see animated_sprite_data.lua for anim_loop_modes values
  --[anim_name] = animated_sprite_data.create(pc_data.sonic_sprite_data_table,
  --        sprite_keys,   step_frames, loop_mode as int)
  {
    ["idle"] = {{sdt.idle},               1,                2},
    ["walk"] = {{sdt.walk1, sdt.walk2, sdt.walk3, sdt.walk4, sdt.walk5, sdt.walk6},
                                         10,                4},
    ["brake_start"]   = {{sdt.brake1, sdt.brake2},
                                         10,                2},
    ["brake_reverse"] = {{sdt.brake3},
                                         15,                2},
    ["run"]  = {{sdt.run1, sdt.run2, sdt.run3, sdt.run4},
                                          5,                4},
    ["spin"] = {{sdt.spin_full_ball, sdt.spin1, sdt.spin_full_ball, sdt.spin2, sdt.spin_full_ball,
                 sdt.spin3, sdt.spin_full_ball, sdt.spin4},
                                          5,                4},
    ["crouch"] = {{sdt.crouch1, sdt.crouch2},
                                          6,                2},
    ["spring_jump"] = {{sdt.spring_jump}, 1,                2},
    ["spin_dash"] = {{sdt.spin_dash_shrink, sdt.spin_dash1, sdt.spin_dash_shrink, sdt.spin_dash2, sdt.spin_dash_shrink,
                 sdt.spin_dash3, sdt.spin_dash_shrink, sdt.spin_dash4},
                                          1,                4},
}, function (raw_data)
  return animated_sprite_data(raw_data[1], raw_data[2], raw_data[3])
end)

return pc_data

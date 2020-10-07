local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")

local playercharacter_data = {

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

  -- Original feature (not in SPG): Reduced Deceleration on Descending Slope
  -- ground active deceleration factor on descending slope (no unit, [0-1])
  ground_decel_descending_slope_factor = 0.5,

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

  -- air acceleration on x axis (px/frame^2)
  air_accel_x_frame2 = 0.046875,  -- 3/64

  -- air drag factor applied every frame, at 60 FPS (no unit)
  -- note that combined with air_accel_x_frame2, we can deduce the actual
  --  max air speed x: air_accel_x_frame2 / (1/air_drag_factor_per_frame - 1)
  --  = 1.453125 px/frame
  air_drag_factor_per_frame = 0.96875,  -- 62/64

  -- min absolute velocity x for which air drag is applied (px/frame)
  air_drag_min_velocity_x = 0.25,  -- 16/64

  -- maximum absolute velocity y for which air drag is applied (px/frame)
  -- the actual range is ] -air_drag_max_abs_velocity_y, 0 [
  air_drag_max_abs_velocity_y = 8,  -- 512/64

  -- maximum absolute ground speed when running (standing) (px/frame)
  -- do not force clamping if character is already above (horizontal spring, spin dash + landing...)
  max_running_ground_speed = 3,  -- 192/64

  -- maximum absolute air velocity x (px/frame)
  -- should be the same as max_running_ground_speed to avoid slow-down/speed-up
  --  just by jumping while running on flat ground (on slope, it will slow down air motion on X though)
  -- do not force clamping if character is already above (horizontal spring + jump, spin dash + jump...)
  max_air_velocity_x = 3,  -- 192/64

  -- ground speed threshold under which character will fall/slide off when walking at more
  --  than 90 degrees, or lock control when walking on wall under 90 degrees (px/frame)
  ceiling_adherence_min_ground_speed = 1.25,  -- 80/64 = 1 + 16/64

  -- duration of horizontal control lock after fall/slide off (frames)
  horizontal_control_lock_duration = 30,  -- 0.5s

  -- max air speed (px/frame)
  --  (very high, probably won't happen unless Sonic falls in bottomless pit)
  max_air_velocity_y = 32,  -- 2048/64

  -- initial variable jump speed (Sonic) (px/frame)
  -- from this and gravity we can deduce the max jump height: 49.921875 (6+ tiles) at frame 31
  -- when hopping, you'll reach jump height: 19.296875 (2+ tiles) at frame 20
  initial_var_jump_speed_frame = 3.25,  -- 208/64 = 3 + 16/64

  -- initial hop vertical speed and new speed when jump is interrupted by releasing jump button (px/frame)
  --  note that when jump is interrupted mid-air, gravity should still be applied just after that
  --  which will give a value of 1.890625. for a hop, the initial speed will remain 2.
  jump_interrupt_speed_frame = 2,

  -- absolute vertical speed given by spring bounce (px/frame)
  -- from this and gravity we can deduce the max jump height: 116.71875 (14+ tiles) at frame 45
  spring_jump_speed_frame = 5,

  -- ground speed required to trigger launch ramp
  launch_ramp_min_ground_speed = 2,

  -- speed multiplier and angle for launch ramp
  launch_ramp_speed_multiplier = 2.7,
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

  -- debug motion

  -- motion speed in debug mode (px/frame)
  debug_move_max_speed = 6,

  -- acceleration speed in debug mode (px/frame^2)
  debug_move_accel = 0.1,

  -- active deceleration speed in debug mode (px/frame^2)
  debug_move_decel = 2,

  -- friction aka passive deceleration speed in debug mode (px/frame^2)
  debug_move_friction = 1,

  -- sprite

  -- speed at which the character sprite angle falls back toward 0 (upward)
  --  when character is airborne (typically after falling from ceiling)
  sprite_angle_airborne_reset_speed_frame = 0.0095,  -- 0.5/(7/8×60) ie character moves from upside down to upward in 7/8 s

  -- stand right
  -- colors.pink: 14
  sonic_sprite_data_table = transform(
    --anim_name = sprite_data(
    --          id_loc,  span,   pivot,   transparent_color (14: pink))
    {
      ["idle"]   = {{0,  8}, {2, 2}, {10, 8}, 14},
      ["walk1"]  = {{2,  8}, {2, 2}, { 9, 8}, 14},
      ["walk2"]  = {{4,  8}, {2, 2}, { 8, 8}, 14},
      ["walk3"]  = {{6,  8}, {2, 2}, { 9, 8}, 14},
      ["walk4"]  = {{8,  8}, {2, 2}, { 9, 8}, 14},
      ["walk5"]  = {{10, 8}, {2, 2}, { 9, 8}, 14},
      ["walk6"]  = {{12, 8}, {2, 2}, { 9, 8}, 14},
      ["brake1"] = {{10, 1}, {2, 2}, { 9, 8}, 14},
      ["brake2"] = {{12, 1}, {2, 2}, { 9, 8}, 14},
      ["brake3"] = {{14, 1}, {2, 2}, {11, 8}, 14},
      ["spring_jump"] = {{14, 8}, {2, 3}, {9, 8}, 14},
      ["run1"]   = {{0, 10}, {2, 2}, { 8, 8}, 14},
      ["run2"]   = {{2, 10}, {2, 2}, { 8, 8}, 14},
      ["run3"]   = {{4, 10}, {2, 2}, { 8, 8}, 14},
      ["run4"]   = {{6, 10}, {2, 2}, { 8, 8}, 14},
      ["spin_full_ball"] = {{0, 12}, {2, 2}, { 6, 6}, 14},
      ["spin1"]  = {{2, 12}, {2, 2}, { 6, 6}, 14},
      ["spin2"]  = {{4, 12}, {2, 2}, { 6, 6}, 14},
      ["spin3"]  = {{6, 12}, {2, 2}, { 6, 6}, 14},
      ["spin4"]  = {{8, 12}, {2, 2}, { 6, 6}, 14},
    }, function (t)
      return sprite_data(
        sprite_id_location(t[1][1], t[1][2]),  -- id_loc
        tile_vector(t[2][1], t[2][2]),         -- span
        vector(t[3][1], t[3][2]),              -- pivot
        t[4]                                   -- transparent_color
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
}

-- define animated sprite data in a second step, as it needs sprite data to be defined first
-- note that we do not split spin_slow and spin_fast as distinguished by SPG anymore
--  in addition, while spin_slow was defined to have 1 spin_full_ball frame and
--  spin_fast had 2, our spin has 4, once every other frame, to match Sonic 3 more closely
playercharacter_data.sonic_animated_sprite_data_table = transform(
  -- see animated_sprite_data.lua for anim_loop_modes values
  --[anim_name] = animated_sprite_data.create(playercharacter_data.sonic_sprite_data_table,
  --        sprite_keys,   step_frames, loop_mode as int)
  {
    ["idle"] = {{"idle"},               10,                2},
    ["walk"] = {{"walk1", "walk2", "walk3", "walk4", "walk5", "walk6"},
                                        10,                4},
    ["brake_start"]   = {{"brake1", "brake2"},
                                        10,                2},
    ["brake_reverse"] = {{"brake3"},
                                        15,                2},
    ["run"]  = {{"run1", "run2", "run3", "run4"},
                                         5,                4},
    ["spin"] = {{"spin_full_ball", "spin1", "spin_full_ball", "spin2", "spin_full_ball", "spin3", "spin_full_ball", "spin4"},
                                         5,                4},
    ["spring_jump"] = {{"spring_jump"}, 10,                2}
}, function (t)
  return animated_sprite_data.create(playercharacter_data.sonic_sprite_data_table, t[1], t[2], t[3])
end)

return playercharacter_data

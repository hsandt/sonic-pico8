local serialization = require("engine/data/serialization")
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

  -- Original feature (not in SPG): Reduced Deceleration on Descending Slope
  -- ground active deceleration factor on descending slope ([0-1])
  ground_decel_descending_slope_factor = 0.5,

  -- ground friction (passive deceleration) (px/frame^2)
  ground_friction_frame2 = 0.0234375,  -- 1.5/64

  -- gravity acceleration (px/frame^2)
  gravity_frame2 = 0.109375,  -- 7/64

  -- slope accel acceleration factor (px/frame^2), to multiply by sin(angle)
  slope_accel_factor_frame2 = 0.0625,  -- 7/64

  -- Used by 3 original features (not in SPG):
  --  - Reduced Deceleration on Steep Descending Slope
  --  - No Friction on Steep Descending Slope
  --  - Progressive Ascending Steep Slope Factor
  -- max slope angle on which friction is applied (]0-0.25[, but we recommend more than 22.5 degrees i.e. 0.0625)
  steep_slope_min_angle = 0.075,  -- 27/360

  -- derived data: the slope angle for which ground friction is exactly opposed to slope factor
  -- is 22.02 degrees ~ 0.061 angle/360 ratio (PICO-8 unit)

  -- Original feature (not in SPG): Progressive Ascending Slope Factor
  -- time needed when ascending a slope before full slope factor is applied (s)
  progressive_ascending_slope_duration = 0.5,

  -- air acceleration on x axis (px/frames^2)
  air_accel_x_frame2 = 0.046875,  -- 3/64

  -- air drag factor applied every frame, at 60 FPS
  -- note that combined with air_accel_x_frame2, we can deduce the actual
  --  max air speed x: air_accel_x_frame2 / (1/air_drag_factor_per_frame - 1)
  --  = 1.453125 px/frames
  air_drag_factor_per_frame = 0.96875,  -- 62/64

  -- min absolute velocity x for which air drag is applied
  air_drag_min_velocity_x = 0.25,  -- 16/64

  -- maximum absolute velocity y for which air drag is applied
  -- the actual range is ] -air_drag_max_abs_velocity_y, 0 [
  air_drag_max_abs_velocity_y = 8,  -- 512/64

  -- ground acceleration (px/frame)
  max_ground_speed = 3,  -- 192/64

  -- ground speed threshold under which character will fall/slide off when walking at more
  --  than 90 degrees, or lock control when walking on wall under 90 degrees (px/frame)
  ceiling_adherence_min_ground_speed = 1.25,  -- 80/64 = 1 + 16/64

  -- duration of horizontal control lock after fall/slide off (frames)
  horizontal_control_lock_duration = 30,  -- 0.5s

  -- max air speed (very high, probably won't happen unless Sonic falls in bottomless pit)
  max_air_velocity_y = 32,  -- 2048/64

  -- initial variable jump speed (Sonic) (px/frame)
  initial_var_jump_speed_frame = 3.25,  -- 208/64 = 3 + 16/64

  -- initial hop vertical speed and new speed when jump is interrupted by releasing jump button (px/frame)
  --  note that when jump is interrupted mid-air, gravity should still be applied just after that
  --  which will give a value of 1.890625. for a hop, the initial speed will remain 2.
  jump_interrupt_speed_frame = 2,

  -- half-width of ground sensors, i.e. x distance of a ground sensor from the character's center vertical axis
  -- the 0.5 allows us to always have the sensor above the middle of a pixel (we always offset from a floored coord)
  --  so we can get the right pixel when offsetting to the left and flooring
  -- note that we don't define wall_sensor_extent_x, which is assumed to be ground_sensor_extent_x + 1
  -- see comment in player_char:_next_ground_step on last block
  ground_sensor_extent_x = 2.5,

  -- height between the standing character center and the ground sensors, i.e. the height of the character sprite center (0 when the center is at the bottom pixel level)
  center_height_standing = 8,

  -- height between the ground sensors and the top of the standing character's collider (used to detect ceiling)
  -- should be 2 * center_height_standing, but left as separate data for customization (e.g. you can add 1 as in the SPG)
  full_height_standing = 16,

  -- same as center_height_standing but when character is crouching, rolling or jumping
  center_height_compact = 4,

  -- same as full_height_standing but when character is crouching, rolling or jumping
  -- should be 2 * center_height_compact, but left as separate data for customization (e.g. you can add 1 as in the SPG)
  full_height_compact = 8,

  -- max vertical distance allowed to escape from inside ground (must be < tile_size as
  --  _compute_signed_distance_to_closest_ground uses it as upper_limit tile_size)
  -- also the max step up of the character in ground motion
  max_ground_escape_height = 4,

  -- max vertical distance allowed to snap to a lower ground while running (on step or curve)
  -- a.k.a. max step down
  max_ground_snap_height = 4,

  -- debug motion

  -- motion speed in debug mode, in px/s
  debug_move_max_speed = 60.,

  -- acceleration speed in debug mode, in px/s^2 (480. to reach max speed of 60. in 0.5s)
  debug_move_accel = 480.,

  -- deceleration speed in debug mode, in px/s^2 (480. to stop from a speed of 60. in 0.5s)
  debug_move_decel = 480.,


  -- sprite

  -- speed at which the character sprite angle falls back toward 0 (upward)
  --  when character is airborne (typically after falling from ceiling)
  sprite_angle_airborne_reset_speed_frame = 0.0095,  -- 0.5/(7/8×60) ie character moves from upside down to upward in 7/8 s

  -- stand right
  -- colors.pink: 14
  sonic_sprite_data_table = serialization.parse_expression(
    --anim_name = sprite_data(
    --          id_loc,  span,   pivot,   transparent_color (14: pink))
    [[{
      idle  = {{0, 8},  {2, 2}, {11, 8}, 14},
      run1  = {{2, 8},  {2, 2}, {11, 8}, 14},
      run2  = {{4, 8},  {2, 2}, {11, 8}, 14},
      run3  = {{6, 8},  {2, 2}, {11, 8}, 14},
      run4  = {{8, 8},  {2, 2}, {11, 8}, 14},
      run5  = {{10, 8}, {2, 2}, {11, 8}, 14},
      run6  = {{12, 8}, {2, 2}, {11, 8}, 14},
      run7  = {{14, 8}, {2, 2}, {11, 8}, 14},
      run8  = {{0, 10}, {2, 2}, {11, 8}, 14},
      run9  = {{2, 10}, {2, 2}, {11, 8}, 14},
      run10 = {{4, 10}, {2, 2}, {11, 8}, 14},
      run11 = {{6, 10}, {2, 2}, {11, 8}, 14},
      spin  = {{0, 12}, {2, 2}, {5, 5},  14},
    }]], function (t)
      return sprite_data(
        sprite_id_location(t[1][1], t[1][2]),  -- id_loc
        tile_vector(t[2][1], t[2][2]),         -- span
        vector(t[3][1], t[3][2]),              -- pivot
        t[4]                                   -- transparent_color
      )
  end),

  -- minimum playback speed for "run" animation, to avoid very slow animation
  -- 5/16: the 5 counters the 5 duration frames of ["run"] below, 1/8 to represent max duration 8 in SPG:Animations
  -- and an extra 1/2 because for some reason, SPG values make animations look too fast (as if durations were for 30FPS)
  run_anim_min_play_speed = 0.3125

}

-- define animated sprite data in a second step, as it needs sprite data to be defined first
playercharacter_data.sonic_animated_sprite_data_table = serialization.parse_expression(
  --[anim_name] = animated_sprite_data.create(playercharacter_data.sonic_sprite_data_table,
  --        sprite_keys,  step_frames, loop_mode)
  [[{
    idle = {{"idle"},     10,          true},
    run  = {{"run1", "run2", "run3", "run4", "run5", "run6", "run7", "run8", "run9", "run10", "run11"},
                           5,          true},
    spin = {{"spin"},     10,          true},
}]], function (t)
  return animated_sprite_data.create(playercharacter_data.sonic_sprite_data_table, t[1], t[2], t[3])
end)

return playercharacter_data

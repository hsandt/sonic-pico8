require("engine/render/color")
local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")

local playercharacter_data = {

  -- platformer motion

  -- ground acceleration (px/frame^2)
  ground_accel_frame2 = 0.0234375,  -- 1.5/64

  -- ground active deceleration (brake) (px/frame^2)
  ground_decel_frame2 = 0.25,  -- 16/64

  -- ground friction (passive deceleration) (px/frame^2)
  ground_friction_frame2 = 0.0234375,  -- 1.5/64

  -- gravity acceleration (px/frame^2)
  gravity_frame2 = 0.109375,  -- 7/64

  -- slope accel acceleration factor (px/frame^2), to multiply by sin(angle)
  slope_accel_factor_frame2 = 0.0625,  -- 7/64

  -- air acceleration on x axis (px/frames^2)
  air_accel_x_frame2 = 0.046875,  -- 3/64

  -- ground acceleration (px/frame)
  max_ground_speed = 3,

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

  -- height between the character center and the ground sensors, i.e. the height of the character sprite center (0 when the center is at the bottom pixel level)
  center_height_standing = 8,

  -- height between the ground sensors and the top of the character's collider (used to detect ceiling)
  full_height_standing = 16,

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

  -- stand right
  sonic_sprite_data_table = {
    ["idle"]  = sprite_data(sprite_id_location(0, 8),  tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run1"]  = sprite_data(sprite_id_location(2, 8),  tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run2"]  = sprite_data(sprite_id_location(4, 8),  tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run3"]  = sprite_data(sprite_id_location(6, 8),  tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run4"]  = sprite_data(sprite_id_location(8, 8),  tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run5"]  = sprite_data(sprite_id_location(10, 8), tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run6"]  = sprite_data(sprite_id_location(12, 8), tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run7"]  = sprite_data(sprite_id_location(14, 8), tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run8"]  = sprite_data(sprite_id_location(0, 10), tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run9"]  = sprite_data(sprite_id_location(2, 10), tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run10"] = sprite_data(sprite_id_location(4, 10), tile_vector(2, 2), vector(11, 8), colors.pink),
    ["run11"] = sprite_data(sprite_id_location(6, 10), tile_vector(2, 2), vector(11, 8), colors.pink),
    ["spin"]  = sprite_data(sprite_id_location(0, 12), tile_vector(2, 2), vector(5, 5),  colors.pink),
  },

}

-- define animated sprite data in a second step, as it needs sprite data to be defined first
playercharacter_data.sonic_animated_sprite_data_table = {
  idle = animated_sprite_data.create(playercharacter_data.sonic_sprite_data_table, {"idle"}, 10, true),
  run = animated_sprite_data.create(playercharacter_data.sonic_sprite_data_table,
    {"run1", "run2", "run3", "run4", "run5", "run6", "run7", "run8", "run9", "run10", "run11"}, 5, true),
  spin = animated_sprite_data.create(playercharacter_data.sonic_sprite_data_table, {"spin"}, 10, true),
}

return playercharacter_data

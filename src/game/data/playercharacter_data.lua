return {

  -- motion

  -- motion speed in debug mode, in px/s
  debug_move_max_speed = 60.,

  -- acceleration speed in debug mode, in px/s^2 (480. to reach max speed of 60. in 0.5s)
  debug_move_accel = 480.,

  -- deceleration speed in debug mode, in px/s^2 (480. to stop from a speed of 60. in 0.5s)
  debug_move_decel = 480.,

  -- gravity acceleration (px/frames^2)
  gravity_per_frame2 = 0.109375,

  -- half-width of ground sensors, i.e. x distance of a ground sensor from the character's center vertical axis (1 for the pixel just touching the axis)
  -- use 0.5px to place the sensor above a full pixel when character center is at an integer x (we consider character center to be "between" pixels)
  ground_sensor_extent_x = 2.5,

  -- height between the character center and the ground sensors, i.e. the height of the character sprite center (0 when the center is at the bottom pixel level)
  center_height_standing = 6,

  -- sprite data
  character_sprite_loc = sprite_id_location(0, 2),
  character_sprite_span = tile_vector(1, 2),       -- vertical sprite
  character_sprite_pivot = vector(4, 6)            -- sprite center (when standing)

}

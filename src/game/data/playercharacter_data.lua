return {

  -- platformer motion

  -- ground acceleration (px/frame^2)
  ground_accel_frame2 = 0.0234375,

  -- ground active deceleration (brake) (px/frame^2)
  ground_decel_frame2 = 0.25,

  -- ground friction (passive deceleration) (px/frame^2)
  ground_friction_frame2 = 0.0234375,

  -- gravity acceleration (px/frame^2)
  gravity_frame2 = 0.109375,

  -- air acceleration on x axis (px/frames^2)
  air_accel_x = 0.046875,

  -- ground acceleration (px/frame)
  max_ground_speed_frame = 3,

  -- initial variable jump speed (Sonic) (px/frame)
  initial_var_jump_speed_frame = 3.25,

  -- initial hop vertical speed and new speed when jump is interrupted by releasing jump button (px/frame)
  --  note that when jump is interrupted mid-air, gravity should still be applied just after that
  --  which will give a value of 1.890625. for a hop, the initial speed will remain 2.
  jump_interrupt_speed_frame = 2,

  -- half-width of ground sensors, i.e. x distance of a ground sensor from the character's center vertical axis (1 for the pixel just touching the axis)
  -- use 0.5px to place the sensor above a full pixel when character center is at an integer x (we consider character center to be "between" pixels)
  ground_sensor_extent_x = 2.5,

  -- height between the character center and the ground sensors, i.e. the height of the character sprite center (0 when the center is at the bottom pixel level)
  center_height_standing = 6,

  -- max vertical distance allowed to escape from inside ground (must be < tile_size as
  --  _compute_signed_distance_to_closest_ground uses it as upper_limit tile_size)
  max_ground_escape_height = 4,

  -- max vertical distance allowed to snap to a lower ground while running (on step or curve)
  max_ground_snap_height = 4,

  -- debug motion

  -- motion speed in debug mode, in px/s
  debug_move_max_speed = 60.,

  -- acceleration speed in debug mode, in px/s^2 (480. to reach max speed of 60. in 0.5s)
  debug_move_accel = 480.,

  -- deceleration speed in debug mode, in px/s^2 (480. to stop from a speed of 60. in 0.5s)
  debug_move_decel = 480.,


  -- sprite

  character_sprite_loc = sprite_id_location(0, 2),
  character_sprite_span = tile_vector(1, 2),        -- vertical sprite
  character_sprite_pivot = vector(4, 10)            -- sprite center (when standing)

}
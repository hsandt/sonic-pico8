-- camera parameters

local camera_data = {
  -- window reference y (where character center y should be) is not vertically centered
  --  on screen in original game, it is slightly up and the camera shows more things
  --  below the character than above
  -- we tried to adjust this value to PICO-8 scale with a law of three: 96×128/224 ~= 55
  --  hence the offset 55 - 64 = -9
  -- set to 0 if you want to recenter window vertically
  window_center_offset_y = -9,

  -- half width of the camera window (px)
  -- According to SPG, window left and right are dissymmetrical,
  --  which is not convenient is levels where moving left is just as important
  --  as moving right. As suggested, we center the window horizontally but preserve
  --  the half-width: ((160 - 144) / 2) / 2 (PICO-8 scaling)
  -- That's why there is no window_center_offset_x
  window_half_width = 4,

  -- half height of the camera window (px)
  -- ((128 - 64) / 2) / 2 (PICO-8 scaling)
  window_half_height = 16,

  -- ground speed from which fast catchup speed is used (when grounded only)
  fast_catchup_min_ground_speed = 4,

  -- catchup speed on Y when grounded with ground speed < fast_catchup_min_ground_speed
  --  (e.g. when running)
  slow_catchup_speed_y = 3,

  -- catchup speed on Y when airborne or grounded with ground speed of
  --  fast_catchup_min_ground_speed or more (e.g. when rolling fast)
  fast_catchup_speed_y = 8,

  -- Forward extension system:
  -- When character is moving fast on X, the camera moves slightly forward
  --  so the player can see what's incoming (Sonic CD only, but common in modern speed platformers)
  -- As suggested by the SPG, we apply this to airborne motion instead of only ground speed in Sonic CD
  -- In counterpart, because we don't apply this to ground speed anymore,
  --  running on a slope will be considered slower in X and will require an even higher ground speed
  --  to activate the forward extension.
  -- If it's an issue, just reduce forward_ext_min_speed_x or switch to a gradual system
  --  where the forward extension distance gradually increases toward its max when speed X increases.

  -- min speed on X to activate forward extension (px/frame)
  forward_ext_min_speed_x = 3,

  -- forward extension distance (px)
  forward_ext_distance = 32,

  -- catchup speed on X to reach maximum forward extension (px/frame)
  forward_ext_catchup_speed_x = 1,
}

return camera_data

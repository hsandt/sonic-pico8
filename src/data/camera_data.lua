-- camera parameters

local camera_data = {
  -- half width of the camera window (px)
  -- According to SPG, window left and right are dissymmetrical,
  --  which is not convenient is levels where moving left is just as important
  --  as moving right. As suggested, we center the window horizontally but preserve
  --  the half-width: ((160 - 144) / 2) / 2 (PICO-8 scaling)
  window_half_width = 4,

  -- window reference y is not vertically centered in original game, it is slightly up
  --  and show more things below the character
  -- we tried to adjust this value to PICO-8 scale with a law of three: 96×128/224
  -- set to 64 if you want to recenter window vertically
  vertical_window_center = 55,

  -- half height of the camera window (px)
  -- ((128 - 64) / 2) / 2 (PICO-8 scaling)
  window_half_height = 16,
}

return camera_data

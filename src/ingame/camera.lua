local camera_data = require("data/camera_data")

--#if cheat
local player_char = require("ingame/playercharacter")
--#endif

local camera_class = new_class()

-- target_pc  target_pc  player character this camera is following
--                       often unavailable on init, you need to set it manually after character spawn
function camera_class:init()
  -- set it later
  -- self.target_pc = nil

  -- position of the camera, at the center of the view
  self.position = vector.zero()

  -- camera forward offset (px, signed)
  -- this intermediate value needs to be stored because it follows its own catchup over time
  self.forward_offset = 0

  -- store last grounded orientation of character to keep using it while it is airborne
  self.last_grounded_orientation = horizontal_dirs.right

  -- time elapsed since last grounded orientation change (frames)
  self.frames_since_grounded_orientation_change = 0

  -- when a last grounded orientation has last enough time (including during airborne time)
  --  it is confirmed and can be applied to forward base offset
  self.confirmed_orientation = horizontal_dirs.right

--#if busted
  -- intermediate values that are much easier to test when isolated, but don't need to be stored
  --  at runtime (only set in update, not in setup)
  self.base_position_x = 0
--#endif
end

-- setup camera for stage data
function camera_class:setup_for_stage(data)
  -- store ref for later
  self.stage_data = data

  -- warp the camera to spawn location (anywhere in the starting region will be enough
  --  so the tilemap region is loaded properly for collision detection; but centering it
  --  on the character first makes sense, since with the window system several positions are possible)
  self.position = data.spawn_location:to_center_position()

  -- prepare forward base offset set for future character (we assume it will be facing right)
  --  just so camera doesn't move just on start (this is quick, would probably
  --  be covered by stage splash screen eventually)
  -- note that we don't need to also add this offset (as a vector) to self.position,
  --  since it will be updated with forward_offset next frame (right now, position is really
  --  set just for the initial region loading, so only the approx. location matters)
  self.forward_offset = camera_data.forward_distance
end

-- update camera position based on player character position
function camera_class:update()
--#if cheat
    if self.target_pc.motion_mode == motion_modes.debug then
      -- in debug motion, just track the character (otherwise he may move too fast vertically
      --  and lost the camera)
      self.position = self.target_pc.position
      return
    end
    -- else: self.motion_mode == motion_modes.platformer
--#endif

  local should_reset_ground_orientation_timer = false
  if self.target_pc:is_grounded() then
    if self.last_grounded_orientation ~= self.target_pc.orientation then
      self.last_grounded_orientation = self.target_pc.orientation
      should_reset_ground_orientation_timer = true
    end
  end

  if should_reset_ground_orientation_timer then
    self.frames_since_grounded_orientation_change = 0
  elseif self.confirmed_orientation ~= self.last_grounded_orientation then
    self.frames_since_grounded_orientation_change = self.frames_since_grounded_orientation_change + 1
    if self.frames_since_grounded_orientation_change >= camera_data.grounded_orientation_confirmation_duration then
      self.confirmed_orientation = self.last_grounded_orientation
    end
  end

  -- Window system: most of the time, only move camera when character
  --  is leaving the central window

  -- X tracking

  -- Window system
  -- clamp to required window
  -- Be sure to use the non-forward-offset camera position X by subtracting the old
  --  self.forward_offset
  -- (if you subtract self.forward_offset after its update below,
  --  result will change slightly)
  local windowed_camera_x = mid(self.position.x - self.forward_offset,
    self.target_pc.position.x - camera_data.window_half_width,
    self.target_pc.position.x + camera_data.window_half_width)

--#if busted
  self.base_position_x = windowed_camera_x
--#endif

  -- Forward offset system

  -- # Base

  local forward_base_offset = camera_data.forward_distance * horizontal_dir_signs[self.confirmed_orientation]

  -- # Extension

  -- When character is moving fast on X, the camera moves slightly forward
  -- When moving slowly again, the forward offset is gradually reduced back to zero
  -- The rest of the time, camera X is just set to where it should be, using the window system
  -- To make window and extension system independent, and avoid having the window
  --  system clamp immediately the extension when character suddenly changes direction,
  --  we track the extension offset independently.
  -- This means that when checking if character X is inside the window,
  --  we must mentally subtract the offset back to get the non-extended camera position
  --  (or we could store some self.base_position if we didn't mind the extra member)

  -- running fast enough activate forward extension (if below forward_ext_min_speed_x, ratio will be 0)
  -- unlike original game, we prefer a gradual increase toward the max extension distance to avoid
  --  jittering when running on a bumpy ground that makes character oscillates between 2.9 and 3 (the threshold
  --  at which they activate forward extension)
  --  (the original game uses ground speed not velocity X so it doesn't have this issue)
  local range = camera_data.max_forward_ext_speed_x - camera_data.forward_ext_min_speed_x
  local ratio = mid(0, 1, (abs(self.target_pc.velocity.x) - camera_data.forward_ext_min_speed_x) / range)
  -- remember that our offset is signed to allow left/right transitions
  local forward_ext_offset = sgn(self.target_pc.velocity.x) * ratio * camera_data.forward_ext_max_distance

  -- Combine both
  local target_forward_offset = forward_base_offset + forward_ext_offset

  -- compute delta to target
  local forward_dx = target_forward_offset - self.forward_offset

  -- clamp abs forward_dx with catchup speed
  forward_dx = sgn(forward_dx) * min(abs(forward_dx), camera_data.forward_ext_catchup_speed_x)

  -- apply delta
  self.forward_offset = self.forward_offset + forward_dx

  -- combine Window and Forward extension
  self.position.x = windowed_camera_x + self.forward_offset

  -- Y tracking
  -- unlike original game we simply use the current center position even when compact (curled)
  --  instead of the ghost standing center position
  if self.target_pc:is_grounded() then
    -- on the ground, stick to y as much as possible
    local target_y = self.target_pc.position.y - camera_data.window_center_offset_y
    local dy = target_y - self.position.y

    -- clamp abs dy with catchup speed (which depends on ground speed)
    local catchup_speed_y = abs(self.target_pc.ground_speed) < camera_data.fast_catchup_min_ground_speed and
      camera_data.slow_catchup_speed_y or camera_data.fast_catchup_speed_y
    dy = sgn(dy) * min(abs(dy), catchup_speed_y)

    -- apply move
    self.position.y = self.position.y + dy
  else
    -- in the air apply vertical window (stick to top and bottom edges)
    local target_y = mid(self.position.y,
      self.target_pc.position.y - camera_data.window_center_offset_y - camera_data.window_half_height,
      self.target_pc.position.y - camera_data.window_center_offset_y + camera_data.window_half_height)
    local dy = target_y - self.position.y

    -- clamp abs dy with fast catchup speed
    dy = sgn(dy) * min(abs(dy), camera_data.fast_catchup_speed_y)

    -- apply move
    self.position.y = self.position.y + dy
  end

  -- clamp on level edges
  -- we are handling the center so we need to offset by screen_width/height
  self.position.x = mid(screen_width / 2, self.position.x, self.stage_data.tile_width * tile_size - screen_width / 2)

  -- Y has dynamic clamping so compute it from camera_bottom_limit_margin_keypoints
  local dynamic_bottom_limit = self:get_bottom_limit_at_x(self.position.x)
  self.position.y = mid(screen_height / 2, self.position.y, dynamic_bottom_limit - screen_height / 2)
end

function camera_class:get_bottom_limit_at_x(x)
  local bottom_limit_tile_margin = 0

  -- first, evaluate piecewise constant curve, considering each keypoint is placed
  --  at the *end* of a constant region
  -- iterate from left to right
  for keypoint in all(self.stage_data.camera_bottom_limit_margin_keypoints) do
    -- check if X is before next keypoint X since it indicates the end
    if x < keypoint.x * tile_size then
      -- we are in the right region since we iterated from left to right
      -- we can immediately break with the value for this region
      bottom_limit_tile_margin = keypoint.y
      break
    end
  end

  -- whether we reached the end and kept margin 0 or found a specific margin,
  --  return the complemented value at pixel scale for the bottom limit as Y
  return (self.stage_data.tile_height - bottom_limit_tile_margin) * tile_size
end

-- return true if a rectangle with diagonal corners at (topleft, bottomright)
--  intersects the camera view rectangle
-- we use topleft inclusive, bottomright exclusive convention
-- this means that camera actually shows pixels 0 to 127 on each direction, not 128,
--  but we still use the exclusive bottom-right corner (128, 128) for the calculation
-- similarly, the rectangle bottomright to test is actually 1px bottom and 1px right to
--  the last visible bottom-right pixel of the sprite to test visibility of
-- this makes it easier to compute bounds (e.g. for a 8x8 sprite, bottomright = topleft + (8, 8))
-- we assume integer coordinates
function camera_class:is_rect_visible(topleft, bottomright)
  -- AABB intersection: are camera view rectangle and object rectangle intersecting?

  -- compute camera view bounds
  local left_edge = self.position.x - screen_width / 2
  local right_edge = self.position.x + screen_width / 2
  local top_edge = self.position.y - screen_height / 2
  local bottom_edge = self.position.y + screen_height / 2

  -- compare edge positions
  return left_edge < bottomright.x and right_edge > topleft.x and
    top_edge < bottomright.y and bottom_edge > topleft.y
end

return camera_class

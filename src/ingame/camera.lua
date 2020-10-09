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
  self.forward_offset = 0
end

-- setup camera for stage data
function camera_class:setup_for_stage(data)
  -- store ref for later
  self.stage_data = data

  -- warp the camera to spawn location (anywhere in the starting region will be enough
  --  so the tilemap region is loaded properly for collision detection; but centering it
  --  on the character first makes sense, since with the window system several positions are possible)
  self.position = data.spawn_location:to_center_position()
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

  -- Forward offset system

  -- # Base

  local forward_base_offset = camera_data.forward_distance * horizontal_dir_signs[self.target_pc.orientation]

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

  -- clamp on level edges (we are handling the center so need offset by screen_width/height)
  self.position.x = mid(screen_width / 2, self.position.x, self.stage_data.tile_width * tile_size - screen_width / 2)
  self.position.y = mid(screen_height / 2, self.position.y, self.stage_data.tile_height * tile_size - screen_height / 2)
end

return camera_class

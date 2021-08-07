local camera_data = require("data/camera_data")

local pc_data = require("data/playercharacter_numerical_data")

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
  self.forward_signed_offset = 0

  -- store last grounded orientation of character to keep using it while it is airborne
  self.last_grounded_orientation = horizontal_dirs.right

  -- time elapsed since last grounded orientation change (frames)
  self.frames_since_grounded_orientation_change = 0

  -- when a last grounded orientation has last enough time (including during airborne time)
  --  it is confirmed and can be applied to forward base offset
  self.confirmed_orientation = horizontal_dirs.right

  -- time since crouching, incremented until we reach frames_before_look_down,
  --  and reset when leaving crouching (frames)
  self.frames_since_crouching = 0

  -- current offset of look down (positive when camera moves down) (px)
  self.look_down_offset = 0

  -- base position: must be stored to track current position without offset
  --  which moves smoothly at catch up speeds on X and Y toward windowed positions,
  --  before we apply the offsets (which have their own smoothing and catchup speeds)
  self.base_position = vector.zero()

  -- time during which camera targets the old spin dash start position instead of Sonic's actual position
  self.spin_dash_lag_timer = 0

  -- registered position where character was spin dashing (initializing is useful to allow copy_assign)
  self.spin_dashing_position = vector.zero()

  -- registered orientation when character was spin dashing (commented out to spare characters, make sure
  --  to assign it at the same time as spin_dashing_position)
  -- self.spin_dashing_orientation = nil
end

-- setup camera for stage data
function camera_class:setup_for_stage(data)
  -- store ref for later
  self.curr_stage_data = data

  -- warp the camera to spawn location (anywhere in the starting region will be enough
  --  so the tilemap region is loaded properly for collision detection; but centering it
  --  on the character first makes sense, since with the window system several positions are possible)
  -- topleft position is passed to match behavior of stage_state:spawn_player_char
  self:init_position(data.spawn_location:to_topleft_position())

  -- prepare forward base offset set for future character (we assume it will be facing right)
  --  just so camera doesn't move just on start (this is quick, would probably
  --  be covered by stage splash screen eventually)
  -- note that we don't need to also add this offset (as a vector) to self.position,
  --  since it will be updated with forward_signed_offset next frame (right now, position is really
  --  set just for the initial region loading, so only the approx. location matters)
  self.forward_signed_offset = camera_data.forward_distance
end

-- initialize camera position
-- only used by setup_for_stage at runtime, it was useful to extract for the various utests
--  so they could start with a base position y matching the initial position
function camera_class:init_position(initial_position)
  -- copy by value to avoid changing initial_position in case it was not just a temporary value
  -- we used to copy by reference, and this triggered the infamous bug of debug mode -> exit debug mode
  --  inside ground -> character moves in a linear fashion due to camera position being the same as character
  --  position!
  self.position:copy_assign(initial_position)
  -- immediately sync base position x/y, which needs a starting point
  -- note that this is not the final position, as x will need to receive the base forward offset
  --  for current character orientation; but currently this happens immediately on stage start, so not perceptible
  -- in utests though, you may need to set self.base_position.x to pure base position on X
  --  (subtract signed base forward offset) depending on what you are testing
  self.base_position.x = initial_position.x
  self.base_position.y = initial_position.y
end

-- --#if busted
-- -- helper for utests, as it's sometimes easier to work directly with camera on final position
-- --  so we should subtract the base forward offset from the initial position on X
-- -- but we need target_pc which we don't have at first during stage setup, so not used in runtime
-- function camera_class:init_position_including_base_forward_offset(initial_position)
--   assert(self.target_pc)
--   self.position = initial_position
--   -- immediately sync base position x/y, which needs a starting point, to the expected
--   --  static position after waiting an infinite amount of time
--   -- x needs to receive the base forward offset for current character orientation
--   self.base_position.x = initial_position.x - camera_data.forward_distance * horizontal_dir_signs[self.target_pc.orientation]
--   self.base_position.y = initial_position.y
-- end
-- --#endif

-- update camera position based on player character position
function camera_class:update()
--#if cheat
    if self.target_pc.motion_mode == motion_modes.debug then
      -- in debug motion, just track the character (otherwise he may move too fast vertically
      --  and lost the camera)
      -- init_position seems weird here, but it's just to update base_position.y
      --  so the camera doesn't start from a different Y again when leaving debug motion mode
      self:init_position(self.target_pc.position)
      return
    end
    -- else: self.motion_mode == motion_modes.platformer
--#endif

  -- this part is done before spin dash lag fictive target creation, because we really care about
  --  the actual character state for ground orientation tracking
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

  -- update frames_since_crouching (increment or reset)
  if self.target_pc.motion_state == motion_states.crouching then
    if self.frames_since_crouching >= camera_data.frames_before_look_down then
      -- move camera down at given speed until limit
      self.look_down_offset = min(self.look_down_offset + camera_data.look_down_speed, camera_data.max_look_down_distance)
    else
      -- we haven't crouched for long enough, increment frame counter
      -- note that we are not increasing look down offset this frame, so when frames_before_look_down is 1,
      --  we effectively wait 1 frame before starting looking down
      self.frames_since_crouching = self.frames_since_crouching + 1
    end
  else
    -- reset frame counter immediately in case it was positive
    self.frames_since_crouching = 0

    -- move camera back up at same speed as when moving down, until neutral position
    -- note that due to level bottom limit clamping, when crouching near the bottom limit,
    --  we won't see the camera move back up before a small delay
    self.look_down_offset = max(0, self.look_down_offset - camera_data.look_down_speed)
  end

  -- check for spin dash lag
  if self.target_pc.motion_state == motion_states.spin_dashing then
    -- setup timer in case it wasn't already
    self.spin_dash_lag_timer = camera_data.spin_dash_lag_duration
    -- remember position and orientation of spin dash start
    self.spin_dashing_position:copy_assign(self.target_pc.position)
    self.spin_dashing_orientation = self.target_pc.orientation
  elseif self.spin_dash_lag_timer > 0 then
    -- we are not preparing spin dash anymore (now rolling, or even in another state after launching)
    --  decrement timer
    self.spin_dash_lag_timer = self.spin_dash_lag_timer - 1
  end

  local target_pos
  local target_velocity_x
  local is_target_grounded
  local target_orientation

  if self.spin_dash_lag_timer > 0 then
    -- spin dash lag is active, set fictive grounded target at previous spin dash position and orientation,
    --  velocity 0
    -- note that we're a variant of the simplified version of spin dash lag suggested at the end of
    --  http://info.sonicretro.org/SPG:Camera#Spindash_Lag
    -- so we just target the old spin dash position after launch (almost like freezing camera, except if camera
    --  had some motion to catch up from before spin dash start, we allow it to do so), and wait 16 frames
    --  before tracking actual player character again (instead of recording 32 frames of motion and catching them
    --  up 2 by 2)
    -- also, we currently don't subtract spin dash rev (actually rev/2 since we start timer at 16 instead of 32)
    --  from the initial timer; do it if you feel that lag is too strong when rev is high
    -- copy reference is safe here, we won't be modifying target_pos
    target_pos = self.spin_dashing_position
    target_velocity_x = 0
    is_target_grounded = true
    -- overwrite target_orientation temporarily but *preserve* self.confirmed_orientation
    -- we actually updated self.confirmed_orientation at the top, checking actual self.target_pc:is_grounded()
    --  rather than is_target_grounded on purpose, so we keep track of the real character orientation
    --  in the background -> when spin dash lag is over, we can immediately switch to the correct
    --  Base Forward offset (e.g. spin dashing right against a wall, then immediately turning left,
    --  will still give a reactive camera)
    target_orientation = self.spin_dashing_orientation
  else
    -- use actual character position
    -- copy reference is safe here, we won't be modifying target_pos
    target_pos = self.target_pc.position
    target_velocity_x = self.target_pc.velocity.x
    is_target_grounded = self.target_pc:is_grounded()
    target_orientation = self.confirmed_orientation
  end

  -- Window system: most of the time, only move camera when character
  --  is leaving the central window

  -- X tracking

  -- Window system
  -- Target base X is clamped to required window, but we move there smoothly with max catchup speed
  --  to avoid warping the camera
  local target_base_x = mid(self.base_position.x,
    target_pos.x - camera_data.window_half_width,
    target_pos.x + camera_data.window_half_width)

  local dx = target_base_x - self.base_position.x

  -- clamp abs dx with catchup speed
  dx = sgn(dx) * min(abs(dx), camera_data.catchup_speed_x)

  -- apply move to base x
  self.base_position.x = self.base_position.x + dx


  -- Forward offset system

  -- # Base

  local forward_base_offset = camera_data.forward_distance * horizontal_dir_signs[target_orientation]

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
  local ratio = mid(0, 1, (abs(target_velocity_x) - camera_data.forward_ext_min_speed_x) / range)
  -- remember that our offset is signed to allow left/right transitions
  local forward_ext_offset = sgn(target_velocity_x) * ratio * camera_data.forward_ext_max_distance

  -- Combine both
  local target_forward_signed_offset = forward_base_offset + forward_ext_offset

  -- compute delta to target
  local forward_dx = target_forward_signed_offset - self.forward_signed_offset

  -- clamp abs forward_dx with catchup speed
  forward_dx = sgn(forward_dx) * min(abs(forward_dx), camera_data.forward_offset_catchup_speed_x)

  -- apply delta
  self.forward_signed_offset = self.forward_signed_offset + forward_dx

  -- combine Window and Forward extension
  self.position.x = self.base_position.x + self.forward_signed_offset


  -- Y tracking

  -- Always track fictive center of character as if standing, for camera stability on Y
  -- In particular, when crouching, character center moves down (compact height is lower), which would cause
  --  the camera to move down if it was tracking the real center. When standing, adjusted_target_pc_pos_y == target_pos.y
  -- SPG confirms this even when airborne, see GIF and comment about "5px offset while sonic is curled"
  --  on http://info.sonicretro.org/SPG:Camera#In_the_Air
  local adjusted_target_pc_pos_y = target_pos.y + self.target_pc:get_center_height() - pc_data.center_height_standing
  local dy

  -- unlike original game we simply use the current center position even when compact (curled)
  --  instead of the ghost standing center position
  if self.target_pc:is_grounded() then
    -- on the ground, stick to y as much as possible
    -- we recently added a mini-window of -1/+1 around target y though, to avoid vertical camera jitter
    --  when character is running on ground with small bumps of 1px
    -- (Sonic 3 actually has the jitter, but 1px on Genesis is much less remarkable, on PICO-8 with its
    --  half resolution it would be like a 2x jitter on Genesis)
    local target_base_y = mid(self.base_position.y,
      adjusted_target_pc_pos_y - camera_data.window_center_offset_y - 1,
      adjusted_target_pc_pos_y - camera_data.window_center_offset_y + 1)
    dy = target_base_y - self.base_position.y

    -- clamp abs dy with catchup speed (which depends on ground speed)
    local catchup_speed_y = abs(self.target_pc.ground_speed) < camera_data.fast_catchup_min_ground_speed and
      camera_data.slow_catchup_speed_y or camera_data.fast_catchup_speed_y
    dy = sgn(dy) * min(abs(dy), catchup_speed_y)
  else
    -- in the air apply vertical window (stick to top and bottom edges)
    local target_base_y = mid(self.base_position.y,
      adjusted_target_pc_pos_y - camera_data.window_center_offset_y - camera_data.window_half_height,
      adjusted_target_pc_pos_y - camera_data.window_center_offset_y + camera_data.window_half_height)
    dy = target_base_y - self.base_position.y

    -- clamp abs dy with fast catchup speed
    dy = sgn(dy) * min(abs(dy), camera_data.fast_catchup_speed_y)
  end

  -- apply move to base y
  self.base_position.y = self.base_position.y + dy

  -- apply look down offset
  self.position.y = self.base_position.y + self.look_down_offset

  -- clamp on level edges
  -- we are handling the center so we need to offset by screen_width/height
  self.position.x = mid(screen_width / 2, self.position.x, self.curr_stage_data.tile_width * tile_size - screen_width / 2)

  -- Y has dynamic clamping so compute it from camera_bottom_limit_margin_keypoints
  local dynamic_bottom_limit = self:get_bottom_limit_at_x(self.position.x)
  self.position.y = mid(screen_height / 2, self.position.y, dynamic_bottom_limit - screen_height / 2)
end

-- return position with floored coordinates
--  use this when passing position to a function that doesn't automatically floor
--  like pico8's camera(), and where pixel fractions may cause unintended effects
function camera_class:get_floored_position()
  return vector(flr(self.position.x), flr(self.position.y))
end

function camera_class:get_bottom_limit_at_x(x)
  local bottom_limit_tile_margin = 0

  -- first, evaluate piecewise constant curve, considering each keypoint is placed
  --  at the *end* of a constant region
  -- iterate from left to right
  for keypoint in all(self.curr_stage_data.camera_bottom_limit_margin_keypoints) do
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
  return (self.curr_stage_data.tile_height - bottom_limit_tile_margin) * tile_size
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
function camera_class:is_rect_visible(topleft, exclusive_bottomright)
  -- AABB intersection: are camera view rectangle and object rectangle intersecting?

  -- compute camera view bounds
  -- ! we should probably floor camera and passed coordinates, and use >= (+1) instead of >
  -- however in our current usages, at least one of them is integer so it still works
  -- but consider flooring if you have enough compressed characters left, for robustness
  local left_edge = self.position.x - screen_width / 2
  local right_edge = self.position.x + screen_width / 2
  local top_edge = self.position.y - screen_height / 2
  local bottom_edge = self.position.y + screen_height / 2

  -- compare edge positions
  return left_edge < exclusive_bottomright.x and right_edge > topleft.x and
    top_edge < exclusive_bottomright.y and bottom_edge > topleft.y
end

return camera_class

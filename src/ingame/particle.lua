local particle = new_class()

-- single particle class

-- parameters
-- frame_lifetime            float           total lifetime (frames)
-- frame_accel               vector          velocity difference applied every frame (px/frame^2)

-- state
-- elapsed_frames            vector          elapsed frames since spawn
-- position                  vector          current position
-- initial_frame_velocity    vector          current velocity (applied every frame, so divide second-based velocity by FPS)
-- base_size                 float           base size (px)
-- size_ratio_over_lifetime  ratio -> float  function returning factor of base size over lifetime ratio
function particle:init(frame_lifetime, initial_position, initial_frame_velocity, frame_accel, base_size, size_ratio_over_lifetime)
  -- parameters
  self.frame_lifetime = frame_lifetime
  self.frame_accel = frame_accel or vector.zero()
  self.base_size = base_size
  self.size_ratio_over_lifetime = size_ratio_over_lifetime

  -- state
  self.elapsed_frames = 0
  self.position = initial_position
  self.frame_velocity = initial_frame_velocity
  self.size = 0  -- will be set on first update
end

-- update particle and return true iff particle is still alive this frame
function particle:update_and_check_alive()
  -- increment elapsed frames
  self.elapsed_frames = self.elapsed_frames + 1

  -- check lifetime (we don't update on spawn frame, so we should really destroy particle
  --  when elapsed_frames reaches frame_lifetime, hence >= not >)
  if self.elapsed_frames >= self.frame_lifetime then
    -- no need to update state, this particle is gonna disappear this frame
    return  -- false, commented out to spare characters but [nil] will work the same
  end

  self:update()
  return true
end

-- update particle state
function particle:update()
  self.position = self.position + self.frame_velocity
  self.frame_velocity = self.frame_velocity + self.frame_accel
  self.size = self.base_size * self.size_ratio_over_lifetime(self.elapsed_frames / self.frame_lifetime)
end

-- render particle at its current location
function particle:render()
  -- PICO-8 shapes evolve suddenly with radius, so we mix and match shapes to get the gradual size we want
  -- size = 0..2 -> circfill radius 0 -> dot
  -- size = 2..3 -> rectfill width and height 2 -> 2x2 square (center at topleft, as even size forces us to offset)
  -- size = 3..4 -> circfill radius 1 (size/2) -> 3x3 cross
  -- size = 4..5 -> circfill radius 2 (size/2) -> 4x4 disc
  -- size = 5+   -> circfill radius size/2
  -- since circfill auto-floors radius, we can just pass size/2 for size >= 3, and even for size = 1
  if 2 <= self.size and self.size < 3 then
    rectfill(self.position.x, self.position.y, self.position.x + 1, self.position.y + 1, colors.white)
  else
    circfill(self.position.x, self.position.y, self.size / 2, colors.white)
  end
end

return particle

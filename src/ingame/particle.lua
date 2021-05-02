local particle = new_class()

-- single particle class

-- parameters
-- frame_lifetime   float     total lifetime (frames)

-- state
-- elapsed_frames   vector    elapsed frames since spawn
-- position         vector    current position
-- frame_velocity   vector    current velocity (applied every frame, so divide second-based velocity by FPS)
-- size             float     current size
function particle:init(frame_lifetime, initial_position, initial_frame_velocity, initial_size)
  -- parameters
  self.frame_lifetime = frame_lifetime

  -- state
  self.elapsed_frames = 0
  self.position = initial_position
  self.frame_velocity = initial_frame_velocity
  self.size = initial_size
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

  self.position = self.position + self.frame_velocity
  return true
end

-- render particle at its current location
function particle:render()
  circfill(self.position.x, self.position.y, self.size, colors.white)
end

return particle

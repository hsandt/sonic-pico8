local particle = new_class()

-- single particle class

-- parameters
-- lifetime         float     total lifetime

-- state
-- position         vector    current position
-- frame_velocity   vector    current velocity (applied every frame, so divide second-based velocity by FPS)
-- size             float     current size
function particle:init(lifetime, initial_position, initial_frame_velocity, initial_size)
  -- parameters
  self.lifetime = lifetime

  -- state
  self.position = initial_position
  self.frame_velocity = initial_frame_velocity
  self.size = initial_size
end

-- update particle
function particle:update()
  self.position = self.position + self.frame_velocity
end

-- render particle at its current location
function particle:render()
  circfill(self.position.x, self.position.y, self.size, colors.white)
end

return particle

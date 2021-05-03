local particle = new_class()

-- single particle class

-- parameters
-- frame_lifetime   float     total lifetime (frames)
-- frame_accel      vector    velocity difference applied every frame (px/frame^2)

-- state
-- elapsed_frames          vector    elapsed frames since spawn
-- position                vector    current position
-- initial_frame_velocity  vector    current velocity (applied every frame, so divide second-based velocity by FPS)
-- size                    float     current size (px)
function particle:init(frame_lifetime, initial_position, initial_frame_velocity, initial_size, frame_accel)
  -- parameters
  self.frame_lifetime = frame_lifetime
  self.frame_accel = frame_accel or vector.zero()

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

  self:update()
  return true
end

-- update particle state
function particle:update()
  self.position = self.position + self.frame_velocity
  self.frame_velocity = self.frame_velocity + self.frame_accel
  -- make size grow quickly at start of lifetime, but shrink again at 1/3 of lifetime
  --  (to avoid big particles hiding character bottom too much)
  -- use linear function decreasing from 1 to -1 over lifetime
  -- local size_delta = (1 - 2 * self.elapsed_frames / self.frame_lifetime) * tuned("size var", 0.03, 0.01)
  -- negative size will draw nothing, no need to clamp
  local function size_ratio_over_lifetime(life_ratio)
    if life_ratio < 0.3 then
      return life_ratio / 0.3
    end
    return 1 - (life_ratio - 0.3) / 0.7
  end
  self.size = tuned("size ratio", 4.9, 0.1) * size_ratio_over_lifetime(self.elapsed_frames / self.frame_lifetime)
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

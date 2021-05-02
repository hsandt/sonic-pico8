local pfx = new_class()

local particle = require("ingame/particle")

-- particle effect class
-- it is a game script, and currently only used for spin dash smoke
-- therefore, some behaviors and parameters are hard-coded
-- in addition, some interfaces are not what you'd commonly find in other engines,
--  e.g. we pass position to start() (ok because we don't move during spin dash...)

-- parameters
-- frame_period    frame_period  spawning period (frames)

-- state
-- particles       {particle}    sequence of particles to update and render
-- is_emitting     bool          is the particle effect playing, i.e. spawning particles periodically?
-- frame_time      float         current time since started playing, modulo frame_period
-- position        vector        current position, used as a base to determine where to spawn new particles

function pfx:init(frame_period)
  -- parameters
  self.frame_period = frame_period

  -- state
  self.particles = {}
  self.is_emitting = false
  -- more correct to setup, but commented out to spare characters (start() will set it anyway,
  --  and frame_time/position are only accessed if is_emitting, which only start() can set to true)
  -- self.frame_time = 0
  -- self.position = vector.zero()
end

function pfx:start(position)
  self.is_emitting = true
  self.frame_time = 0
  self.position = position
end

function pfx:stop()
  self.is_emitting = false
end

function pfx:spawn_particle()
  add(self.particles, particle(self.position, vector(0, 0), 3))
end

-- update each pfx
function pfx:update()
  -- in a reverse loop, delete particles that have reached end of lifetime
  -- reverse iteration to avoid messing up with the loop when removing entries
  for i = #self.particles, 1, -1 do
    local should_stay_alive = self.particles[i]:update_and_check_alive()
    if not should_stay_alive then
      deli(self.particles, i)
    end
  end

  if self.is_emitting then
    -- update time and check frame_period to see if we should spawn new particles
    self.frame_time = self.frame_time + 1
    if self.frame_time >= self.frame_period then
      self.frame_time = 0
      self:spawn_particle()
    end
  end
end

-- render each pfx at its current location
function pfx:render()
  -- render existing particles
  -- particles can live after pfx stopped emitting, so don't check for self.is_emitting here
  foreach(self.particles, particle.render)
end

return pfx

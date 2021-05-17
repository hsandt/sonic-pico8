local pfx = new_class()

local particle = require("ingame/particle")

-- particle effect class
-- it is a game script, and currently only used for spin dash smoke
-- therefore, some behaviors and parameters are hard-coded
-- in addition, some interfaces are not what you'd commonly find in other engines,
--  e.g. we pass position to start() (ok because we don't move during spin dash...)

-- parameters
-- spawn_period_frames       number          particle spawning period (frames, fractions ok)
-- spawn_count               int             number of particles emitted every spawn period
-- base_lifetime_frames      number          base lifetime for spawned particles (frames, fractions ok)
-- base_velocity             vector          base velocity for spawned particles (px/frame)
-- max_deviation             float           max factor of base_velocity magnitude used for orthogonal
--                                           acceleration, randomized per particle (ratio)
-- base_size                 float           base max size for spawned particles (px, fraction ok)
-- size_ratio_over_lifetime  ratio -> float  function returning factor of base size over lifetime ratio

-- state
-- particles       {particle}    sequence of particles to update and render
-- is_emitting     bool          is the particle effect playing, i.e. spawning particles periodically?
-- frame_time      float         current time since started playing, modulo spawn_period_frames
-- position        vector        current position, used as a base to determine where to spawn new particles
-- mirror_x        bool          if true, mirror particle velocity on X

function pfx:init(spawn_period_frames, spawn_count, base_lifetime_frames, base_velocity, max_deviation, base_size, size_ratio_over_lifetime)
  -- parameters
  self.spawn_period_frames = spawn_period_frames
  self.spawn_count = spawn_count
  self.base_lifetime_frames = base_lifetime_frames
  self.base_velocity = base_velocity
  self.max_deviation = max_deviation
  self.base_size = base_size
  self.size_ratio_over_lifetime = size_ratio_over_lifetime

  -- state
  self.particles = {}
  self.is_emitting = false
  -- more correct to setup, but commented out to spare characters (start() will set it anyway,
  --  and frame_time/position are only accessed if is_emitting, which only start() can set to true)
  -- self.frame_time = 0
  -- self.position = vector.zero()
end

function pfx:start(position, mirror_x)
  self.is_emitting = true
  self.frame_time = 0
  self.position = position
  self.mirror_x = mirror_x  -- "or false" stripped to spare a few characters, as nil has same behavior as false
end

function pfx:stop()
  self.is_emitting = false
end

function pfx:spawn_particle()
  local initial_frame_velocity = self.base_velocity:copy()
  if self.mirror_x then
    initial_frame_velocity.x = -initial_frame_velocity.x
  end

  -- apply random orthogonal velocity variation to cause motion deviation over time
  local frame_accel = initial_frame_velocity:rotated_90_cw() * (rnd(2 * self.max_deviation) - self.max_deviation)
  add(self.particles, particle(self.base_lifetime_frames, self.position, initial_frame_velocity, frame_accel,
    self.base_size, self.size_ratio_over_lifetime))
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
    -- update time and check spawn_period_frames to see if we should spawn new particles
    self.frame_time = self.frame_time + 1
    if self.frame_time >= self.spawn_period_frames then
      self.frame_time = 0
      for i = 1, self.spawn_count do
        self:spawn_particle()
      end
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

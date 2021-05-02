local pfx = new_class()

local particle = require("ingame/particle")

-- particle effect class

-- state
-- particles   {particle}    sequence of particles to update and render

function pfx:init()
  self.particles = {}
end

-- update each pfx
function pfx:update()
  foreach(self.particles, particle.update)
end

-- render each pfx at its current location
function pfx:render()
  foreach(self.particles, particle.render)
end

return pfx

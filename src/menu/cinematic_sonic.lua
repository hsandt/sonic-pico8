local animated_sprite = require("engine/render/animated_sprite")

local visual = require("resources/visual_common")

-- non-physics sprite of sonic used for splash screen only, drawn at scale x2
-- only plays run animation
-- implements drawable interface {position: vector, draw: function}
local cinematic_sonic = new_class()

-- position     vector        position of the animated sprite on screen
-- anim_spr  animated_sprite  animated sprite
function cinematic_sonic:init(position)
  -- for drawable interface
  self.position = position

  self.anim_spr = animated_sprite(visual.animated_sprite_data_t.cinematic_sonic)
  self.anim_spr:play("run")
end

--#if tostring
function cinematic_sonic:_tostring()
 return "cinematic_sonic("..joinstr(', ', self.position, self.anim_spr)..")"
end
--#endif

-- update the animated sprite
function cinematic_sonic:update()
  self.anim_spr:update()
end

-- for drawable interface
-- render the animated sprite at its current location
function cinematic_sonic:draw()
  -- always draw at scale 2 so it covers "SAGE" logo
  self.anim_spr:render(self.position, false, false, 0, 2)
end

return cinematic_sonic

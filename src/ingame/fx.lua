local animated_sprite = require("engine/render/animated_sprite")

local fx = new_class()

-- a simple entity with 2 components: position and animated_sprite
-- position    vector
-- anim_spr    animated_sprite
function fx:init(position, anim_spr_data)
  self.position = position
  self.anim_spr = animated_sprite(anim_spr_data)
  -- we're not using pooling system yet, so just play on construction
  --  and stage will clear when it detects animation has ended
  -- we use the hardcoded "once" name for the unique fx animation, so make sure
  --  your fx animated sprite data define a "once" animation (that ends with freeze_last or clear,
  --  freeze_last helping debug in case we forget to clear, and clear being safer visually but may
  --  hide memory leaks of invisible fx staying in memory)
  self.anim_spr:play("once")
end

-- Pool pattern: return true iff animated sprite is still playing
function fx:is_active()
  return self.anim_spr.playing
end

-- update the fx animated sprite
function fx:update()
  self.anim_spr:update()
end

-- render the fx at its current location
function fx:render()
  -- we only use position as fx sprites tend to be self-contained
  --  but we could also pass flip and angle to spare spritesheet memory
  --  (e.g. the pick FX anim can be constructed from a mix of flip and angles),
  --  providing animated_sprite supported flip/angle change per key frame
  self.anim_spr:render(self.position)
end

return fx

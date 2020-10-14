local fx = require("ingame/fx")

local emerald_fx = derived_class(fx)

local emerald = require("ingame/emerald")
local visual = require("resources/visual_common")

-- a simple entity with 2 components: position and animated_sprite
-- position    vector
-- anim_spr    animated_sprite
function emerald_fx:init(number, position, anim_spr_data)
  fx.init(self, position, visual.animated_sprite_data_t.emerald_pick_fx)
  self.number = number
end

-- override
-- render the fx with color swap matching emerald number
function emerald_fx:render()
  -- recolor emerald based on number (see emerald.draw)
  emerald.set_color_palette(self.number)
  self.anim_spr:render(self.position)
  pal()
end

return emerald_fx

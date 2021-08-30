local fx = require("ingame/fx")

local emerald_fx = derived_class(fx)

local emerald_common = require("render/emerald_common")
local visual = require("resources/visual_common")

-- extra attributes:
-- number    int    number of the represented emerald to color the fx
-- note that you can still customize the animated sprite data,
--  as some will use the pick FX, others (start cinematic) will use the single star
function emerald_fx:init(number, position, anim_spr_data)
  fx.init(self, position, anim_spr_data)
  self.number = number
end

-- override
-- render the fx with color swap matching emerald number
function emerald_fx:render()
  -- recolor emerald based on number (see emerald.draw)
  emerald_common.set_color_palette(self.number)
  self.anim_spr:render(self.position)
  pal()
end

return emerald_fx

-- this file is dedicated to emerald as it appears in the titlemenu start cinematic

-- visual requires titlemenu add-on
local visual = require("resources/visual_common")

local emerald_common = require("render/emerald_common")

local emerald_cinematic = new_class()

-- number    int            number of the emerald, from 1 to 8
--                          also determines the color palette
-- position  vector         position of the emerald on screen
-- scale     number         scale to draw sprite with (nil is OK)
function emerald_cinematic:init(number, position, scale)
  assert(number <= 8, "emerald:init: only 8 emeralds allowed")
  self.number = number
  self.position = position
  self.scale = scale or 1
end

--#if tostring
function emerald_cinematic:_tostring()
 return "emerald("..joinstr(', ', self.number, self.position, self.scale)..")"
end
--#endif

-- render the emerald at its current location
-- renamed "draw" compared to ingame emerald to match drawable API
function emerald_cinematic:draw()
  -- we now need scale, so we don't use common draw anymore
  -- emerald_common.draw(self.number, self.position)
  -- (we could implement scale in common draw, but that would make ingame cartridge
  --  slightly bigger, and it's already slightly bigger because we added scaling support
  --  in sprite_data:render using sspr)

  -- so instead we inlined the 1st part of common draw and added scale

  assert(self.number >= 0)
  emerald_common.set_color_palette(self.number--[[, brightness: 0]])
  visual.sprite_data_t.emerald:render(self.position, false, false, 0, self.scale)
  pal()
end

return emerald_cinematic

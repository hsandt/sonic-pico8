-- this file is dedicated to emerald as it appears in the titlemenu start cinematic

-- visual requires titlemenu add-on
local visual = require("resources/visual_common")

local postprocess = require("engine/render/postprocess")

local emerald_common = require("render/emerald_common")

local emerald_cinematic = new_class()

-- number      int            number of the emerald, from 1 to 8
--                            also determines the color palette
-- position    vector         position of the emerald on screen
-- scale       number         scale to draw sprite with (nil is OK)
-- brightness  int            signed brightness, supports negative values
function emerald_cinematic:init(number, position, scale)
  assert(number <= 8, "emerald:init: only 8 emeralds allowed")
  self.number = number
  self.position = position
  self.scale = scale or 1
  self.brightness = 0
end

--#if tostring
function emerald_cinematic:_tostring()
 return "emerald("..joinstr(', ', self.number, self.position, self.scale)..")"
end
--#endif

-- render the emerald at its current location
-- renamed "draw" compared to ingame emerald to match drawable API
function emerald_cinematic:draw()
  assert(self.number >= 0)

  -- we now need scale, so we don't use common draw anymore
  -- emerald_common.draw(self.number, self.position)
  -- (we could implement scale in common draw, but that would make ingame cartridge
  --  slightly bigger, and it's already slightly bigger because we added scaling support
  --  in sprite_data:render using sspr)

  -- so instead we inlined the 1st part of common draw and added scale

  -- to support both negative brightness (darkness) and positive brightness,
  --  either use postprocess or emerald_common function depending on signed brightness
  if self.brightness < 0 then
    local darkness = -self.brightness
    -- inspired by postprocess code, but remember the raw sprite is red, so we must always
    --  pass original colors as shades of red; but target color depends on emerald number
    -- in addition, don't pass 1 as it's preprocess this time
    local light_color, dark_color = unpack(visual.emerald_colors[self.number])
    pal(colors.red, postprocess.swap_palette_by_darkness[light_color][darkness])
    pal(colors.dark_purple, postprocess.swap_palette_by_darkness[dark_color][darkness])
  else
    emerald_common.set_color_palette(self.number, self.brightness)
  end

  visual.sprite_data_t.emerald:render(self.position, false, false, 0, self.scale)

  pal()
end

return emerald_cinematic

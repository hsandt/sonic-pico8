-- visual requires either ingame or titlemenu add-on, as each cartridge contains
--  its own copy of the emerald sprite at different location
-- the main (or the utest) decides what add-on to use from the outside
local visual = require("resources/visual_common")

local emerald = new_class()

-- static (as used by emerald.draw and emerald_fx:render)
-- set the color palette swap from red to emerald matching passed number
-- don't forget to reset with pal() manually after drawing
-- optional brightness can be passed, to convert light to white (level 1 and 2),
-- dark to light (level 1) and dark to white (level 2). Default 0 preserves brightness.
function emerald.set_color_palette(number, brightness)
  brightness = brightness or 0

  -- swap colors based on emerald number
  -- note that the reference emerald in the Red emerald,
  --  which uses white (invariant), red (light color) and dark_purple (dark color)
  --  so we must replace the last two with our custom colors
  local light_color, dark_color = unpack(visual.emerald_colors[number])

  if brightness == 0 then
    pal(colors.red, light_color)
    pal(colors.dark_purple, dark_color)
  elseif brightness == 1 then
    pal(colors.red, colors.white)
    pal(colors.dark_purple, light_color)
  else  -- brightness == 2
    pal(colors.red, colors.white)
    pal(colors.dark_purple, colors.white)
  end
end

-- static (as used by render_hud even without a proper emerald object)
-- draw emerald with correct color based on number, at given position
-- can be used for HUD and stage
-- optional brightness affects palette, see set_color_palette
function emerald.draw(number, position, brightness)
  if number >= 0 then
    emerald.set_color_palette(number, brightness)

    -- pass center of tile, so emerald is represented with pivot at the center
    visual.sprite_data_t.emerald:render(position)
    pal()
  else
    -- negative number (typically -1) for empty emerald,
    --  draw emerald silhouette instead (HUD only)
    visual.sprite_data_t.emerald_silhouette:render(position)
  end
end

-- number    int            number of the emerald, from 1 to 8
--                          also determines the color palette
-- location  tile_location  location of the emerald on the map (top-left)
function emerald:init(number, location)
  assert(number <= 8, "emerald:init: only 8 emeralds allowed")
  self.number = number
  self.location = location
end

--#if tostring
function emerald:_tostring()
 return "emerald("..joinstr(', ', self.number, self.location)..")"
end
--#endif

function emerald:get_center()
  return self.location:to_center_position()
end

-- render the emerald at its current location
function emerald:render()
  emerald.draw(self.number, self:get_center())
end

return emerald

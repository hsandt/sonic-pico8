local visual = require("resources/visual")

local emerald = new_class()
emerald.emerald = emerald

-- static (as used by emerald.draw and emerald_fx:render)
-- set the color palette swap from red to emerald matching passed number
-- don't forget to reset with pal() manually after drawing
function emerald.set_color_palette(number)
  -- swap colors based on emerald number
  -- note that the reference emerald in the Red emerald,
  --  which uses white (invariant), red (light color) and dark_purple (dark color)
  --  so we must replace the last two with our custom colors
  local custom_colors = visual.emerald_colors[number]

  -- crash prevention in case there are too many emeralds for colors
  -- in #assert we should have asserted in emerald:init() if number came from
  --  an actual emerald object, but at least it avoids crash in release
  if custom_colors then
    pal(colors.red, custom_colors[1])
    pal(colors.dark_purple, custom_colors[2])
  end
end

-- static (as used by render_hud even without a proper emerald object)
-- draw emerald with correct color based on number, at given position
-- can be used for HUD and stage
function emerald.draw(number, position)
  if number >= 0 then
    emerald.set_color_palette(number)

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

--#if log
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

local visual = require("resources/visual")

local emerald = new_class()
emerald.emerald = emerald

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
  -- recolor emerald based on number
  -- note that the reference emerald in the Red emerald,
  --  which uses white (invariant), red (light color) and dark_purple (dark color)
  --  so we must replace the last two with our custom colors
  local custom_colors = visual.emerald_colors[self.number]

  -- crash prevention in case there are too many emeralds for colors
  -- in #assert we should have asserted in init(), but avoids crash in release
  if custom_colors then
    pal(colors.red, custom_colors[1])
    pal(colors.dark_purple, custom_colors[2])
  end

  -- pass center of tile, so emerald is represented with pivot at the center
  visual.sprite_data_t.emerald:render(self:get_center())
  pal()
end

return emerald

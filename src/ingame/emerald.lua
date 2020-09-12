local visual = require("resources/visual")

local emerald = new_class()
emerald.emerald = emerald

-- number    int            number of the emerald, from 1 to 8
--                          also determines the color palette
-- location  tile_location  location of the emerald on the map (top-left)
function emerald:_init(number, location)
  self.number = number
  self.location = location
end

--#if log
function emerald:_tostring()
 return "emerald("..joinstr(', ', self.number, self.location)..")"
end
--#endif

-- render the emerald at its current location
function emerald:render()
  -- recolor emerald based on number
  -- note that the reference emerald in the Red emerald,
  --  which uses white (invariant), red (light color) and dark_purple (dark color)
  --  so we must replace the last two with our custom colors
  local custom_colors = visual.emerald_colors[self.number]
  pal(colors.red, custom_colors[1])
  pal(colors.dark_purple, custom_colors[2])
  -- pass center of tile, so emerald is represented with pivot at the center
  visual.sprite_data_t.emerald:render(self.location:to_center_position())
  pal()
end

return emerald

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
  -- pass center of tile, so emerald is represented with pivot at the center
  printh("self.location:to_center_position(): "..dump(self.location:to_center_position()))
  visual.sprite_data_t.emerald:render(self.location:to_center_position())
end

return emerald

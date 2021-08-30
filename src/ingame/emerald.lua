-- this file is dedicated to emerald as it appears ingame, as it mentions location
-- titlemenu uses a different class, emerald_cinematic

-- visual requires ingame add-on
local visual = require("resources/visual_common")

local emerald_common = require("render/emerald_common")

local emerald = new_class()

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
  local center_position = self.location:to_center_position()

  -- stage trick: last emerald (above spring) is offset compared to spring sprite,
  --  so adjust position to place it above spring center (this also affects picking collision)
  if self.number == 8 then
    center_position:add_inplace(vector(5, 0))
  end

  return center_position
end

function emerald:get_render_bounding_corners()
  -- no need to have minimum bounding box for sprite, a 1x1-tile-sized box is enough
  local topleft = self.location:to_topleft_position()
  return topleft, topleft + tile_size * vector(1, 1)
end

-- render the emerald at its current location
function emerald:render()
  emerald_common.draw(self.number, self:get_center())
end

return emerald

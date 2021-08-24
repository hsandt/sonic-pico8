-- this file is dedicated to emerald as it appears in the titlemenu start cinematic

-- visual requires titlemenu add-on
local visual = require("resources/visual_common")

local emerald_common = require("render/emerald_common")

local emerald_cinematic = new_class()

-- number    int            number of the emerald, from 1 to 8
--                          also determines the color palette
-- position  vector         position of the emerald on screen
function emerald_cinematic:init(number, position)
  assert(number <= 8, "emerald:init: only 8 emeralds allowed")
  self.number = number
  self.position = position
end

--#if tostring
function emerald_cinematic:_tostring()
 return "emerald("..joinstr(', ', self.number, self.position)..")"
end
--#endif

-- render the emerald at its current location
-- renamed "draw" compared to ingame emerald to match drawable API
function emerald_cinematic:draw()
  emerald_common.draw(self.number, self.position)
end

return emerald_cinematic

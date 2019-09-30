require("engine/application/flow")
require("engine/core/class")
require("engine/render/color")
local gamestate = require("application/gamestate")

local credits = {}

-- game state
credits.state = singleton(function (self)
  self.type = gamestate.types.credits
end)

function credits.state:on_enter()
end

function credits.state:on_exit()
end

function credits.state:update()
end

function credits.state:render()
  color(colors.white)
  api.print("credits state", 4*11, 6*12)
end

-- export

return credits

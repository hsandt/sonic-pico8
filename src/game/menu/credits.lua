require("engine/application/flow")
require("engine/render/color")
require("game/application/gamestates")

local credits = {}

-- game state
credits.state = {
  type = gamestate_types.credits
}

--#if log
function credits.state:_tostring()
  return "[credits state]"
end
--#endif

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

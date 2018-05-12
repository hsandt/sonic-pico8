require("flow")

local credits = {}

-- game state
local credits_state = {
  type = gamestate_type.credits
}

function credits_state:on_enter()
end

function credits_state:on_exit()
end

function credits_state:update()
end

function credits_state:render()
  cls()
  color(colors.white)
  print("credits state", 4*11, 6*12)
end

-- export

credits.state = credits_state

return credits

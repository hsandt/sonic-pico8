require("flow")

local credits = {}

-- game state

local state = {
 state_type = flow.gamestate_type.credits
}

function state:on_enter()
end

function state:update()
end

function state:render()
end

-- export

credits.state = state

return credits

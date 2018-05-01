require("flow")

local credits = {}

-- game state

local state = {
 type = gamestate_type.credits
}

function state:on_enter()
end

function state:update()
 flow:query_gamestate_type(gamestate_type.stage)
end

function state:render()
end

-- export

credits.state = state

return credits

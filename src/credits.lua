require("flow")

local credits = {}

-- game state

local state = {
 type = gamestate_type.credits
}

function state:on_enter()
 printh("credits:on_enter")
end

function state:on_exit()
 printh("credits:on_exit")
end

function state:update()
 flow:query_gamestate_type(gamestate_type.stage)
end

function state:render()
end

-- export

credits.state = state

return credits

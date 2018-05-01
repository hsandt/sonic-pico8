require("flow")

local titlemenu = {}

-- game state

local state = {
 type = gamestate_type.titlemenu
}

function state:on_enter()
end

function state:update()
 flow:query_gamestate_type(gamestate_type.credits)
end

function state:render()
end

-- export
titlemenu.state = state
return titlemenu

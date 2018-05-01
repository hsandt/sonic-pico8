require("flow")

local titlemenu = {}

-- game state

local state = {
 state_type = flow.gamestate_type.titlemenu
}

function state:on_enter()
end

function state:update()
end

function state:render()
end

-- export

titlemenu.state = state

return titlemenu

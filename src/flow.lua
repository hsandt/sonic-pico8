local flow = {}

-- game states (behave like singletons)

local gamestate_type = {
 titlemenu = 1,
 stage = 2,
}

local titlemenu_state = {
 state_type = gamestate_type.titlemenu
}

function titlemenu_state:on_enter()
end

function titlemenu_state:update()
end

function titlemenu_state:render()
end

-- export

flow.gamestate_type = gamestate_type
flow.titlemenu_state = titlemenu_state

return flow

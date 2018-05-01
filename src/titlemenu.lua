require("flow")

local titlemenu = {}

-- game state

local state = {
 type = gamestate_type.titlemenu
}

function state:on_enter()
 printh("titlemenu:on_enter")
end

function state:on_exit()
 printh("titlemenu:on_exit")
end

function state:update()
 flow:query_gamestate_type(gamestate_type.credits)
end

function state:render()
end

-- export
titlemenu.state = state
return titlemenu

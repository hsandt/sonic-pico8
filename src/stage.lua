require("flow")

local stage = {}

-- game state

local state = {
 type = gamestate_type.stage
}

function state:on_enter()
 printh("stage:on_enter")
end

function state:on_exit()
 printh("stage:on_exit")
end

function state:update()
end

function state:render()
end

-- export

stage.state = state

return stage

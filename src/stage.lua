require("flow")

local stage = {}

-- game state

local state = {
 state_type = flow.gamestate_type.stage
}

function state:on_enter()
end

function state:update()
end

function state:render()
end

-- export

stage.state = state

return stage

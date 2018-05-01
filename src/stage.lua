require("flow")

local stage = {}

-- game state

local state = {
 type = gamestate_type.stage
}

function state:on_enter()
 log("flow", "stage:on_enter")
end

function state:on_exit()
 log("flow", "stage:on_exit")
end

function state:update()
end

function state:render()
end

-- export

stage.state = state

return stage

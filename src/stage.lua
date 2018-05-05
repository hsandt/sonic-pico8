require("flow")

local stage = {}

-- game state
local stage_state = {
  type = gamestate_type.stage
}

function stage_state:on_enter()
end

function stage_state:on_exit()
end

function stage_state:update()
end

function stage_state:render()
  cls()
  print("stage state", 4*11, 6*12)
end

-- export

stage.state = stage_state

return stage

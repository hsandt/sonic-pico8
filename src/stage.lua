require("math")
require("flow")
require("playercharacter")

local stage = {}

-- stage data
local stage_data = {
  spawn_location = location(0, -3)
}

-- game state
local stage_state = {
  type = gamestate_type.stage,

  -- state vars

  -- player character
  player_character = nil
}

function stage_state:on_enter()
  self:spawn_player_character()
end

function stage_state:on_exit()
end

function stage_state:update()
end

function stage_state:render()
  cls()
  print("stage state", 4*11, 6*12)
end

function stage_state:spawn_player_character()
  local spawn_position = stage_data.spawn_location:to_position()
  self.player_character = player_character(spawn_position)
end

-- export

stage.state = stage_state
stage.data = stage_data

return stage

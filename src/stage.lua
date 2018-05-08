require("color")
require("flow")
require("math")
require("playercharacter")

local stage = {}

-- stage data
local stage_data = {
  spawn_location = location(1, 1)
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

  -- background
  rectfill(0, 0, 127, 127, colors.dark_purple)
  rectfill(0, 0, 7, 7, colors.pink)
  rectfill(8, 8, 15, 15, colors.pink)

  print("stage state", 4*11, 1*12)

  self:render_player_character()
end

-- setup

-- spawn the player character at the stage spawn location
function stage_state:spawn_player_character()
  local spawn_position = stage_data.spawn_location:to_center_position()
  self.player_character = player_character(spawn_position)
end

-- render

-- render the player character at its current position
function stage_state:render_player_character()
  self.player_character:render()
end

-- export

stage.state = stage_state
stage.data = stage_data

return stage

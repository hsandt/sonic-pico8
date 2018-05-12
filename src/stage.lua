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
  player_character = nil,

  camera_position = vector(0, 0)
}

function stage_state:on_enter()
  self:spawn_player_character()
  self.camera_position = vector(0, 0)
end

function stage_state:on_exit()
  -- reinit camera offset for other states
  camera()
end

function stage_state:update()
  self:handle_input()
  self.player_character:update()
  self:update_camera()
end

function stage_state:render()
  cls()

  -- background
  camera()
  rectfill(0, 0, 127, 127, colors.dark_purple)
  print("stage state", 3*11, 1*12)

  -- update camera offset
  camera(self.camera_position.x - screen_width / 2, self.camera_position.y - screen_height / 2)

  -- dummy tiles
  rectfill(0, 0, 7, 7, colors.pink)
  rectfill(8, 8, 15, 15, colors.pink)

  -- player character
  self:render_player_character()
end


-- setup

-- spawn the player character at the stage spawn location
function stage_state:spawn_player_character()
  local spawn_position = stage_data.spawn_location:to_center_position()
  self.player_character = player_character(spawn_position)
end


-- input

-- handle player input
function stage_state:handle_input()
  local player_move_intention = vector.zero()

  if btn(##l) then
    player_move_intention += vector(-1, 0)
  elseif btn(##r) then
    player_move_intention += vector(1, 0)
  end

  if btn(##u) then
    player_move_intention += vector(0, -1)
  elseif btn(##d) then
    player_move_intention += vector(0, 1)
  end

  self.player_character.move_intention = player_move_intention
end


-- camera

function stage_state:update_camera()
  -- following player character with stiff motion
  self.camera_position.x = self.player_character.position.x
  self.camera_position.y = self.player_character.position.y
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

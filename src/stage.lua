require("color")
require("coroutine")
require("math")
require("playercharacter")
local flow = require("flow")
local audio = require("audio")

local stage = {}

-- enums
local substates = {
  play = "play",     -- playing and moving around
  result = "result"  -- result screen
}

-- stage global data
local global_params = {
  back_to_titlemenu_delay = 1.0
}

-- stage data
local stage_data = {
  -- where the player character spawns on stage start
  spawn_location = location(0, 10),

  -- the x to reach to finish the stage
  goal_x = 16 * 8
}

-- game state
local stage_state = {
  type = gamestate_type.stage,

  -- state vars

  -- current coroutines
  coroutine_curries = {},

  -- substate
  current_substate = substates.play,

  -- player character
  player_character = nil,
  -- has the player character already reached the goal once?
  has_reached_goal = false,
  -- position of the main camera, at the center of the view
  camera_position = vector.zero()
}

function stage_state:on_enter()
  self.current_substate = substates.play
  self:spawn_player_character()
  self.has_reached_goal = false
  self.camera_position = vector.zero()
end

function stage_state:on_exit()
  -- clear all coroutines
  clear_table(self.coroutine_curries)

  -- reinit camera offset for other states
  camera()
end

function stage_state:update()
  self:update_coroutines()

  if self.current_substate == substates.play then
    self:handle_input()
    self.player_character:update()
    self:check_reached_goal()
    self:update_camera()
  else

  end
end

function stage_state:render()
  cls()

  camera()
  -- background
  rectfill(0, 0, 127, 127, colors.dark_purple)
  -- debug label
  print("stage state", 3*11, 1*12)

  -- update camera offset
  self:set_camera_offset_stage()
  self:render_environment()
  self:render_player_character()
end


-- coroutines

-- create and register coroutine with optional arguments
function stage_state:add_coroutine(async_function, ...)
 coroutine = cocreate(async_function)
 add(self.coroutine_curries, coroutine_curry(coroutine, ...))
end

-- variant for methods that apply self argument automatically
function stage_state:add_coroutine_method(async_function)
  self:add_coroutine(async_function, self)
end

-- update emit coroutine if active, remove if dead
function stage_state:update_coroutines()
  for i, coroutine_curry in pairs(self.coroutine_curries) do
    local status = costatus(coroutine_curry.coroutine)
    if status == "suspended" then
      -- resume the coroutine and assert if failed
      -- (assertions don't work from inside coroutines, but will return false)
      -- pass the curry arguments now (most of the time they are only useful
      -- on the 1st coresume call, since other times they are just yield() return values)
      assert(coresume(coroutine_curry.coroutine, unpack(coroutine_curry.args)))
    elseif status == "dead" then
      -- remove the coroutine for garbage collection
      self.coroutine_curries[i] = nil
    else  -- status == "running"
      warn("flow", "warning: coroutine should not be running outside its body")
    end
  end
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


-- gameplay events

function stage_state:check_reached_goal()
  if not self.has_reached_goal and
      self.player_character.position.x >= stage_data.goal_x then
    self.has_reached_goal = true
    self:add_coroutine_method(self.on_reached_goal_async)
  end
end

function stage_state:on_reached_goal_async()
  self:feedback_reached_goal()
  self.current_substate = substates.result
  yield_delay(global_params.back_to_titlemenu_delay)
  self:back_to_titlemenu()
end

function stage_state:feedback_reached_goal()
  sfx(audio.sfx_ids.goal_reached)
end

function stage_state:back_to_titlemenu()
  flow:query_gamestate_type(gamestate_type.titlemenu)
end


-- camera

-- update camera position based on player character position
function stage_state:update_camera()
  -- stiff motion
  self.camera_position.x = self.player_character.position.x
  self.camera_position.y = self.player_character.position.y
end

-- set the camera offset for stage elements
function stage_state:set_camera_offset_stage()
  -- the camera position is used to render the stage, subtracting a half screen to center the view
  camera(self.camera_position.x - screen_width / 2, self.camera_position.y - screen_height / 2)
end


-- render

-- render the player character at its current position
function stage_state:render_player_character()
  self.player_character:render()
end

-- render the stage environment (tiles)
function stage_state:render_environment()
  -- optimize: don't draw the whole stage offset by camera,
  -- instead just draw the portion of the level of interest
  -- (and either keep camera offset or offset manually and subtract from camera offset)
  map(0, 0, 0, 0, 16, 14)
  -- goal as vertical line
  rectfill(stage_data.goal_x, 0, stage_data.goal_x + 5, 15*8, colors.yellow)
end


-- export

stage.substates = substates
stage.global_params = global_params
stage.data = stage_data
stage.state = stage_state

return stage

require("engine/render/color")
require("engine/core/coroutine")
require("engine/core/math")
require("game/ingame/playercharacter")
require("game/application/gamestates")
local flow = require("engine/application/flow")
local audio = require("game/resources/audio")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")

local stage = singleton {
  -- enums
  substates = {
    play = "play",     -- playing and moving around
    result = "result"  -- result screen
  },

  -- stage global data
  global_params = {
    -- delay between stage enter and showing stage title (s)
    show_stage_title_delay = 4.0,
    -- delay between reaching goal and going back to title menu (s)
    back_to_titlemenu_delay = 1.0,
    -- duration of bgm fade out after reaching goal (s)
    bgm_fade_out_duration = 1.0
  },

  -- stage data
  data = {
    -- stage title
    title = "proto zone",

    -- where the player character spawns on stage start
    spawn_location = location(0, 10),

    -- the x to reach to finish the stage
    goal_x = 16 * 8,

    -- bgm id
    bgm_id = audio.music_pattern_ids.green_hill
  },

  state = nil
}

-- game state
stage.state = {
  type = gamestate_types.stage,

  -- state vars

  -- current coroutines
  coroutine_curries = {},

  -- substate
  current_substate = stage.substates.play,

  -- player character
  player_character = nil,
  -- has the player character already reached the goal once?
  has_reached_goal = false,
  -- position of the main camera, at the center of the view
  camera_position = vector.zero(),

  -- title overlay
  title_overlay = ui.overlay(0)
}

--#if log
function stage.state:_tostring()
  return "[stage state]"
end
--#endif

function stage.state:on_enter()
  self.current_substate = stage.substates.play
  self:spawn_player_character()
  self.has_reached_goal = false
  self.camera_position = vector.zero()

  self:start_coroutine_method(self.show_stage_title_async)
  self:play_bgm()
end

function stage.state:on_exit()
  -- clear all coroutines
  clear_table(self.coroutine_curries)

  -- clear object state vars
  self.player_character = nil
  self.title_overlay:clear_labels()

  -- reinit camera offset for other states
  camera()

  -- stop audio
  self:stop_bgm()
end

function stage.state:update()
  self:update_coroutines()

  if self.current_substate == stage.substates.play then
    self:handle_input()
    self.player_character:update()
    self:check_reached_goal()
    self:update_camera()
  else

  end
end

function stage.state:render()
  camera()

  -- background
  rectfill(0, 0, 127, 127, colors.blue)

  -- update camera offset
  self:render_stage_elements()
  self:render_title_overlay()
end


-- coroutines

-- create and register coroutine with optional arguments
function stage.state:start_coroutine(async_function, ...)
 coroutine = cocreate(async_function)
 add(self.coroutine_curries, coroutine_curry(coroutine, ...))
end

-- variant for methods that apply self argument automatically
function stage.state:start_coroutine_method(async_function, ...)
  self:start_coroutine(async_function, self, ...)
end

-- update emit coroutine if active, remove if dead
function stage.state:update_coroutines()
  local coroutine_curries_to_delete = {}
  for i, coroutine_curry in pairs(self.coroutine_curries) do
    local status = costatus(coroutine_curry.coroutine)
    if status == "suspended" then
      -- resume the coroutine and assert if failed
      -- (assertions don't work from inside coroutines, but will return false)
      -- pass the curry arguments now (most of the time they are only useful
      -- on the 1st coresume call, since other times they are just yield() return values)
      local result = coresume(coroutine_curry.coroutine, unpack(coroutine_curry.args))
      assert(result, "Assertion failed in coroutine update for: "..coroutine_curry)
    elseif status == "dead" then
      -- register the coroutine for removal from the sequence (don't delete it now since we are iterating over it)
      -- note that this block is only entered on the frame after the last coresume
      add(coroutine_curries_to_delete, coroutine_curry)
    else  -- status == "running"
      warn("stage.state:update_coroutines: coroutine should not be running outside its body: "..coroutine_curry, "flow")
    end
  end
  -- delete dead coroutines
  for coroutine_curry in all(coroutine_curries_to_delete) do
    del(self.coroutine_curries, coroutine_curry)
  end
end


-- setup

-- spawn the player character at the stage spawn location
function stage.state:spawn_player_character()
  local spawn_position = stage.data.spawn_location:to_center_position()
  self.player_character = player_character(spawn_position)
end


-- input

-- handle player input
function stage.state:handle_input()
  if self.player_character.control_mode == control_modes.human then
    local player_move_intention = vector.zero()

    if input:is_down(button_ids.left) then
      player_move_intention:add_inplace(vector(-1, 0))
    elseif input:is_down(button_ids.right) then
      player_move_intention:add_inplace(vector(1, 0))
    end

    if input:is_down(button_ids.up) then
      player_move_intention:add_inplace(vector(0, -1))
    elseif input:is_down(button_ids.down) then
      player_move_intention:add_inplace(vector(0, 1))
    end

    self.player_character.move_intention = player_move_intention
  end
end


-- gameplay events

function stage.state:check_reached_goal()
  if not self.has_reached_goal and
      self.player_character.position.x >= stage.data.goal_x then
    self.has_reached_goal = true
    self:start_coroutine_method(self.on_reached_goal_async)
  end
end

function stage.state:on_reached_goal_async()
  self:feedback_reached_goal()
  self.current_substate = stage.substates.result
  self:stop_bgm(stage.global_params.bgm_fade_out_duration)
  yield_delay(stage.global_params.back_to_titlemenu_delay)
  self:back_to_titlemenu()
end

function stage.state:feedback_reached_goal()
  sfx(audio.sfx_ids.goal_reached)
end

function stage.state:back_to_titlemenu()
  flow:query_gamestate_type(gamestate_types.titlemenu)
end


-- camera

-- update camera position based on player character position
function stage.state:update_camera()
  -- stiff motion
  self.camera_position.x = self.player_character.position.x
  self.camera_position.y = self.player_character.position.y
end

-- set the camera offset for stage elements
function stage.state:set_camera_offset_stage()
  -- the camera position is used to render the stage. it represents the screen center
  -- whereas pico-8 defines a top-left camera position, so we subtract a half screen to center the view
  camera(self.camera_position.x - screen_width / 2, self.camera_position.y - screen_height / 2)
end


-- ui

function stage.state:show_stage_title_async()
  self.title_overlay:add_label("title", stage.data.title, vector(50, 30), colors.white)
  yield_delay(stage.global_params.show_stage_title_delay)
  self.title_overlay:remove_label("title")
end


-- render

-- render the stage elements with the main camera:
-- - environment
-- - player character
function stage.state:render_stage_elements()
  self:set_camera_offset_stage()
  self:render_environment()
  self:render_player_character()
end

-- render the stage environment (tiles)
function stage.state:render_environment()
  -- optimize: don't draw the whole stage offset by camera,
  -- instead just draw the portion of the level of interest
  -- (and either keep camera offset or offset manually and subtract from camera offset)
  map(0, 0, 0, 0, 16, 14)
  -- goal as vertical line
  rectfill(stage.data.goal_x, 0, stage.data.goal_x + 5, 15*8, colors.yellow)
end

-- render the player character at its current position
function stage.state:render_player_character()
  self.player_character:render()
end

-- render the title overlay with a fixed ui camera
function stage.state:render_title_overlay()
  camera(0, 0)
  self.title_overlay:draw_labels()
end


-- audio

function stage.state:play_bgm()
  music(stage.data.bgm_id, 0)
end

function stage.state:stop_bgm(fade_duration)
  -- convert duration from seconds to milliseconds
  if fade_duration then
    fade_duration_ms = 1000 * fade_duration
  else
    fade_duration_ms = 0
  end
  music(-1, fade_duration_ms)
end


-- export

return stage

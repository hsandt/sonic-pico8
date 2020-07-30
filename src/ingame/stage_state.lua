require("engine/core/coroutine")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local overlay = require("engine/ui/overlay")

local player_char = require("ingame/playercharacter")
local stage_data = require("data/stage_data")
local audio = require("resources/audio")

local stage_state = derived_class(gamestate)

stage_state.type = ':stage'

-- enums
stage_state.substates = {
  play = "play",     -- playing and moving around
  result = "result"  -- result screen
}

function stage_state:_init()
  gamestate._init(self)

  -- stage id
  self.curr_stage_id = 1

  -- reference to current stage data (derived from curr_stage_id)
  self.curr_stage_data = stage_data.for_stage[self.curr_stage_id]

  -- substate
  self.current_substate = stage_state.substates.play

  -- player character
  self.player_char = nil
  -- has the player character already reached the goal once?
  self.has_reached_goal = false
  -- position of the main camera, at the center of the view
  self.camera_pos = vector.zero()

  -- title overlay
  self.title_overlay = overlay(0)
end

function stage_state:on_enter()
  self.current_substate = stage_state.substates.play
  self:spawn_player_char()
  self.has_reached_goal = false
  self.camera_pos = vector.zero()

  self.app:start_coroutine(self.show_stage_title_async, self)
  self:play_bgm()
end

function stage_state:on_exit()
  -- clear all coroutines (we normally let app handle them, but in this context
  -- we know that all coroutines belong to the stage state, so no risk clearing them from here)
  self.app:stop_all_coroutines()

  -- clear object state vars
  self.player_char = nil
  self.title_overlay:clear_labels()

  -- reinit camera offset for other states
  camera()

  -- stop audio
  self:stop_bgm()
end

function stage_state:update()
  if self.current_substate == stage_state.substates.play then
    self.player_char:update()
    self:check_reached_goal()
    self:update_camera()
  else

  end
end

function stage_state:render()
  camera()

  self:render_background()
  self:render_stage_elements()
  self:render_title_overlay()
end


-- setup

-- spawn the player character at the stage spawn location
function stage_state:spawn_player_char()
  local spawn_position = self.curr_stage_data.spawn_location:to_center_position()
  self.player_char = player_char()
  self.player_char:spawn_at(spawn_position)
end


-- gameplay events

function stage_state:check_reached_goal()
  if not self.has_reached_goal and
      self.player_char.position.x >= self.curr_stage_data.goal_x then
    self.has_reached_goal = true
    self.app:start_coroutine(self.on_reached_goal_async, self)
  end
end

function stage_state:on_reached_goal_async()
  self:feedback_reached_goal()
  self.current_substate = stage_state.substates.result
  self:stop_bgm(stage_data.bgm_fade_out_duration)
  self.app:yield_delay_s(stage_data.back_to_titlemenu_delay)
  self:back_to_titlemenu()
end

function stage_state:feedback_reached_goal()
  sfx(audio.sfx_ids.goal_reached)
end

function stage_state:back_to_titlemenu()
  flow:query_gamestate_type(':titlemenu')
end


-- camera

-- update camera position based on player character position
function stage_state:update_camera()
  -- stiff motion
  self.camera_pos.x = self.player_char.position.x
  self.camera_pos.y = self.player_char.position.y
end

-- set the camera offset for stage elements
function stage_state:set_camera_offset_stage()
  -- the camera position is used to render the stage. it represents the screen center
  -- whereas pico-8 defines a top-left camera position, so we subtract a half screen to center the view
  camera(self.camera_pos.x - screen_width / 2, self.camera_pos.y - screen_height / 2)
end


-- ui

function stage_state:show_stage_title_async()
  self.title_overlay:add_label("title", self.curr_stage_data.title, vector(50, 30), colors.white)
  self.app:yield_delay_s(stage_data.show_stage_title_delay)
  self.title_overlay:remove_label("title")
end


-- render

-- render the stage background
function stage_state:render_background()
  camera()
  rectfill(0, 0, 127, 127, self.curr_stage_data.background_color)
end

-- render the stage elements with the main camera:
-- - environment
-- - player character
function stage_state:render_stage_elements()
  self:set_camera_offset_stage()
  self:render_environment()
  self:render_player_char()
end

-- render the stage environment (tiles)
function stage_state:render_environment()
  -- optimize: don't draw the whole stage offset by camera,
  -- instead just draw the portion of the level of interest
  -- (and either keep camera offset or offset manually and subtract from camera offset)
  set_unique_transparency(colors.pink)
  map(0, 0, 0, 0, self.curr_stage_data.width, self.curr_stage_data.height)

  -- goal as vertical line
  rectfill(self.curr_stage_data.goal_x, 0, self.curr_stage_data.goal_x + 5, 15*8, colors.yellow)
end

-- render the player character at its current position
function stage_state:render_player_char()
  self.player_char:render()
end

-- render the title overlay with a fixed ui camera
function stage_state:render_title_overlay()
  camera(0, 0)
  self.title_overlay:draw_labels()
end


-- audio

function stage_state:play_bgm()
  music(self.curr_stage_data.bgm_id, 0)
end

function stage_state:stop_bgm(fade_duration)
  -- convert duration from seconds to milliseconds
  if fade_duration then
    fade_duration_ms = 1000 * fade_duration
  else
    fade_duration_ms = 0
  end
  music(-1, fade_duration_ms)
end


-- export

return stage_state

require("engine/core/coroutine")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local overlay = require("engine/ui/overlay")

local emerald = require("ingame/emerald")
local player_char = require("ingame/playercharacter")
local stage_data = require("data/stage_data")
local audio = require("resources/audio")
local visual = require("resources/visual")

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

  -- items (could also be in world if it was a singleton or member of stage_state
  --  instead of being essentially static; as member, it may be renamed 'stage')
  self.emeralds = {}

  -- position of the main camera, at the center of the view
  self.camera_pos = vector.zero()

  -- title overlay
  self.title_overlay = overlay(0)

  -- list of background tree delta heights (i.e. above base height),
  --  per row, from farthest (top) to closest
  --  (added for doc, commented out since nil does nothing)
  -- self.tree_dheight_array_list = nil

  -- list of falling leaves heights per row, from farthest (bottom) to closest
  -- self.leaves_dheight_array_list = nil
end

function stage_state:on_enter()
  self.current_substate = stage_state.substates.play
  self:spawn_player_char()
  self.has_reached_goal = false
  self.camera_pos = vector.zero()

  self.app:start_coroutine(self.show_stage_title_async, self)
  self:play_bgm()

  -- randomize background data on stage start so it's stable during the stage
  self:randomize_background_data()

  self:spawn_emeralds()
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

-- replace emerald representative sprite (the left part with most of the pixels)
--  with an actual emerald object, to make it easier to recolor and pick up
function stage_state:spawn_emeralds()
  -- to be precise, visual.sprite_data_t.emerald is the full sprite data of the emerald
  --  (with a span of (2, 1)), but in our case the representative sprite of emeralds used
  --  in the tilemap is at the topleft of the full sprite, hence also the id_loc
  local emerald_repr_sprite_id = visual.sprite_data_t.emerald.id_loc:to_sprite_id()
  for i = 0, 127 do
    for j = 0, 127 do
      local tile_sprite_id = mget(i, j)
      if tile_sprite_id == emerald_repr_sprite_id then
        -- replace the representative tile (spawn point) with nothing,
        --  since we're going to create a distinct emerald object
        mset(i, j, 0)
        -- spawn emerald object and store it is sequence member
        add(self.emeralds, emerald(#self.emeralds + 1, location(i, j)))
      end
    end
  end
end

-- visual events

function stage_state:extend_spring(spring_loc)
  self.app:start_coroutine(self.extend_spring_async, self, spring_loc)
end

function stage_state:extend_spring_async(spring_loc)
  -- set tilemap to show extended spring
  mset(spring_loc.i, spring_loc.j, visual.spring_extend_sprite_id)
  -- wait just enough to show extended spring before it goes out of screen
  self.app:yield_delay_s(stage_data.spring_extend_duration)
  -- revert to default spring sprite
  mset(spring_loc.i, spring_loc.j, visual.spring_normal_sprite_id)
end

-- gameplay events

-- check if position is in emerald pick up area and if so,
--  return emerald. Else, return nil.
function stage_state:check_emerald_pick_area(position)
  for em in all(self.emeralds) do
    -- max xy distance check <=> inside square area (simplified version of AABB)
    local delta = position - em:get_center()
    local max_distance = max(abs(delta.x), abs(delta.y))
    if max_distance < stage_data.emerald_pick_radius then
      return em
    end
  end
end

function stage_state:character_pick_emerald(em)
  -- remove emerald from sequence (use del to make sure
  --  later object indices are decremented)
  del(self.emeralds, em)
end

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
  -- clamp on level edges (we are handling the center so need offset by screen_width/height)
  self.camera_pos.x = mid(screen_width / 2, self.player_char.position.x, self.curr_stage_data.width * tile_size - screen_width / 2)
  self.camera_pos.y = mid(screen_height / 2, self.player_char.position.y, self.curr_stage_data.height * tile_size - screen_height / 2)
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

  -- dark blue sky + sea
  -- (in stage data, but actually the code below only makes sense
  --  for stage with jungle/sea background)
  rectfill(0, 0, 127, 127, colors.dark_blue)

  -- horizon line is very bright
  local horizon_line_y = 90 - 0.5 * self.camera_pos.y
  -- dithering above horizon line
  for i = 0, 126, 2 do
    line(i, horizon_line_y - 3, i + 1, horizon_line_y - 2, colors.blue)
  end
  -- blue line above horizon line
  rectfill(0, horizon_line_y - 1, 127, horizon_line_y - 1, colors.blue)
  -- white horizon line
  rectfill(0, horizon_line_y, 127, horizon_line_y, colors.white)
  rectfill(0, horizon_line_y + 1, 127, horizon_line_y + 1, colors.indigo)

  -- clouds in the sky, from lowest to highest (and biggest)
  local cloud_dx_list_per_j = {
    {0, 60, 140, 220},
    {30, 150, 240},
    {10, 90, 210},
    {50, 130}
  }
  local dy_list_per_j = {
    {0, 0, -1, 0},
    {0, -1, -1, 0},
    {0, -1, 1, 0},
    {0, 1, -1, 1}
  }
  local dy0 = 8.9
  local dy_mult = 14.7
  local r0 = 2
  local r_mult = 0.9
  local speed0 = 3
  local speed_mult = 3.5
  for j = 0, 3 do
    for cloud_dx in all(cloud_dx_list_per_j[j + 1]) do
      self:draw_cloud(cloud_dx, horizon_line_y - dy0 - dy_mult * j, dy_list_per_j[j + 1], r0 + r_mult * j, speed0 + speed_mult * j)
    end
  end

  -- shiny reflections in water
  -- vary y
  local reflection_dy_list = {4, 3, 6, 2, 1, 5}
  local period_list = {0.7, 1.5, 1.2, 1.7, 1.1}
  -- parallax speed of (relatively) close reflection (dy = 6)
  local water_parallax_speed_max = 0.015
  -- to cover up to ~127 with intervals of 6,
  --  we need i up to 21 since 21*6 = 126
  for i = 0, 21 do
    local dy = reflection_dy_list[i % 6 + 1]
    local y = horizon_line_y + 2 + dy
    -- elements farther from camera have slower parallax speed, closest has base parallax speed
    -- clamp in case some y are bigger than 6, but it's better if you can adjust to max of
    --  reflection_dy_list so max is still max and different dy give different speeds
    -- we have speed 0 at the horizon line, so no need to compute min
    -- note that real optics would give some 1 / tan(distance) factor but linear is enough for us
    local parallax_speed = water_parallax_speed_max * min(6, dy) / 6
    local parallax_offset = flr(parallax_speed * self.camera_pos.x)
    self:draw_water_reflections(parallax_offset, 6 * i, y, period_list[i % 5 + 1])
  end

  -- under the trees background
  rectfill(0, horizon_line_y + 50, 127, horizon_line_y + 50 + screen_height, colors.dark_green)

  -- tree/leaves data

  -- base height so trees have a bottom part long enough to cover the gap with the trees below
  local tree_base_height = 10
  local tree_row_y0 = horizon_line_y + 29
  local tree_row_dy_mult = 8
  -- parallax speed of farthest row
  local tree_row_parallax_speed_min = 0.3
  -- parallax speed of closest row
  local tree_row_parallax_speed_max = 0.42
  local tree_row_parallax_speed_range = tree_row_parallax_speed_max - tree_row_parallax_speed_min

  local leaves_base_height = 21
  local leaves_y0 = horizon_line_y + 33
  local leaves_row_dy_mult = 18
  -- for max parallax speed, reuse the one of trees
  -- indeed, if you play S3 Angel Island, you'll notice that the highest falling leave row
  --  is actually the same sprite as the closest tree top (which is really just a big green patch)
  -- due to a small calculation error the final speeds end slightly different, so if you really
  --  want both elements to move exactly together, prefer drawing a long line from tree top to leaf bottom
  --  in a single draw_tree_and_leaves function
  -- however we use different speeds for farther leaves
  local leaves_row_parallax_speed_min = 0.36
  local leaves_row_parallax_speed_range = tree_row_parallax_speed_max - leaves_row_parallax_speed_min

  -- leaves (before trees so trees can hide some leaves with base height too long if needed)
  for j = 0, 1 do
    local parallax_speed = leaves_row_parallax_speed_min + leaves_row_parallax_speed_range * j / 1
    local parallax_offset = flr(parallax_speed * self.camera_pos.x)
    -- first patch of leaves chains from closest trees, so no base height
    --  easier to connect and avoid hiding closest trees
    -- intermediate var for luamin #50
    local complementary_j = 1 - j
    self:draw_leaves_row(parallax_offset, leaves_y0 + leaves_row_dy_mult * complementary_j, leaves_base_height, self.leaves_dheight_array_list[j + 1], j % 2 == 0 and colors.green or colors.dark_green)
  end

  -- tree rows
  for j = 0, 3 do
    -- elements farther from camera have slower parallax speed, closest has base parallax speed
    local parallax_speed = tree_row_parallax_speed_min + tree_row_parallax_speed_range * j / 3
    local parallax_offset = flr(parallax_speed * self.camera_pos.x)
    self:draw_tree_row(parallax_offset, tree_row_y0 + tree_row_dy_mult * j, tree_base_height, self.tree_dheight_array_list[j + 1], j % 2 == 0 and colors.green or colors.dark_green)
  end
end

function stage_state:draw_cloud(x, y, dy_list, base_radius, speed)
  -- indigo outline (prefer circfill to circ to avoid gaps
  --  between inside and outline for some values)
  local offset_x = t() * speed
  -- we make clouds cycle horizontally but we don't want to
  --  make them disappear as soon as they reach the left edge of the screen
  --  so we take a margin of 100px (must be at least cloud width)
  --  before applying modulo (and similarly have a modulo on 128 + 100 + extra margin
  --  where extra margin is to avoid having cloud spawning immediately on screen right
  --  edge)
  -- intermediate var to avoid luamin bracket stripping bug #50
  local x0 = x - offset_x + 100

  -- clouds move to the left
  x0 = x0 % 300 - 100

  local dx_rel_to_r_list = {0, 1.5, 3, 4.5}
  local r_mult_list = {0.8, 1.4, 1.1, 0.7}

  -- indigo outline
  for i=1,4 do
    circfill(x0 + flr(dx_rel_to_r_list[i] * base_radius), y + dy_list[i], r_mult_list[i] * base_radius + 1, colors.indigo)
  end

  -- white inside
  for i=1,4 do
    circfill(x0 + flr(dx_rel_to_r_list[i] * base_radius), y + dy_list[i], r_mult_list[i] * base_radius, colors.white)
  end
end

function stage_state:draw_water_reflections(parallax_offset, x, y, period)
  -- animate reflections by switching colors over time
  local ratio = (t() % period) / period
  local c1, c2
  if ratio < 0.2 then
    c1 = colors.dark_blue
    c2 = colors.blue
  elseif ratio < 0.4 then
    c1 = colors.white
    c2 = colors.blue
  elseif ratio < 0.6 then
    c1 = colors.blue
    c2 = colors.dark_blue
  elseif ratio < 0.8 then
    c1 = colors.blue
    c2 = colors.white
  else
    c1 = colors.dark_blue
    c2 = colors.blue
  end
  pset((x - parallax_offset) % screen_width, y, c1)
  pset((x - parallax_offset + 1) % screen_width, y, c2)
end

function stage_state:randomize_background_data()
  self.tree_dheight_array_list = {}
  for j = 1, 4 do
    self.tree_dheight_array_list[j] = {}
    -- longer periods on closer tree rows (also removes the need for offset
    --  to avoid tree rows sin in sync, although parallax will offset anyway)
    local period = 20 + 10 * (j-1)
    for i = 1, 64 do
      -- shape of trees are a kind of sin min threshold with random peaks
      self.tree_dheight_array_list[j][i] = flr(3 * abs(sin(i/period)) + rnd(8))
    end
  end

  self.leaves_dheight_array_list = {}
  for j = 1, 2 do
    self.leaves_dheight_array_list[j] = {}
    -- longer periods on closer leaves
    local period = 70 + 35 * (j-1)
    for i = 1, 64 do
      -- shape of trees are a kind of broad sin random peaks
      self.leaves_dheight_array_list[j][i] = flr(9 * abs(sin(i/period)) + rnd(4))
    end
  end
end

function stage_state:draw_tree_row(parallax_offset, y, base_height, dheight_array, color)
  local size = #dheight_array
  for x = 0, 127 do
    -- intermediate var to avoid luamin bracket removal issue #50
    local parallax_x = x + parallax_offset
    local height = base_height + dheight_array[parallax_x % size + 1]
    -- draw vertical line from bottom to (variable) top
    line(x, y, x, y - height, color)
  end
end

function stage_state:draw_leaves_row(parallax_offset, y, base_height, dheight_array, color)
  local size = #dheight_array
  for x = 0, 127 do
    -- intermediate var to avoid luamin bracket removal issue #50
    local parallax_x = x + parallax_offset
    local height = base_height + dheight_array[parallax_x % size + 1]
    -- draw vertical line from top to (variable) bottom
    line(x, y, x, y + height, color)
  end
end

-- render the stage elements with the main camera:
-- - environment
-- - player character
function stage_state:render_stage_elements()
  self:set_camera_offset_stage()
  self:render_environment()
  self:render_player_char()
  self:render_emeralds()
end

-- render the stage environment (tiles)
function stage_state:render_environment()
  -- optimize: don't draw the whole stage offset by camera,
  -- instead just draw the portion of the level of interest
  -- (and either keep camera offset or offset manually and subtract from camera offset)
  set_unique_transparency(colors.pink)
  -- todo: first render everything but loop entrance tiles, then after player char,
  -- only loop entrance tiles
  map(0, 0, 0, 0, self.curr_stage_data.width, self.curr_stage_data.height)

  -- goal as vertical line
  rectfill(self.curr_stage_data.goal_x, 0, self.curr_stage_data.goal_x + 5, 15*8, colors.yellow)
end

-- render the player character at its current position
function stage_state:render_player_char()
  self.player_char:render()
end

-- render the emeralds
function stage_state:render_emeralds()
  for em in all(self.emeralds) do
    em:render()
  end
end

-- render the title overlay with a fixed ui camera
function stage_state:render_title_overlay()
  camera(0, 0)
  self.title_overlay:draw_labels()
end


-- audio

function stage_state:play_bgm()
  -- only 4 channels at a time in PICO-8
  -- set music channel mask (priority over SFX) to everything but 1,
  --  which is a nice bass (at least with current GHZ BGM)
  music(self.curr_stage_data.bgm_id, 0, shl(1, 0) + shl(1, 2) + shl(1, 3))
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

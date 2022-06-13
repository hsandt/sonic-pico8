local input = require("engine/input/input")
local postprocess = require("engine/render/postprocess")
local label = require("engine/ui/label")
local overlay = require("engine/ui/overlay")
local rectangle = require("engine/ui/rectangle")

local pc_data = require("data/playercharacter_numerical_data")
local stage_data = require("data/stage_data")
local stage_intro_data = require("data/stage_intro_data")
local base_stage_state = require("ingame/base_stage_state")
local camera_class = require("ingame/camera")
local player_char = require("ingame/playercharacter")
local visual = require("resources/visual_common")
local visual_ingame_data = require("resources/visual_ingame_numerical_data")
local visual_stage = require("resources/visual_stage")
local ui_animation = require("engine/ui/ui_animation")

local stage_intro_state = derived_class(base_stage_state)

stage_intro_state.type = ':stage_intro'

-- coordinates for local forest sprite batches located on the right, offscreen region of the tilemap

local bg_forest_local_tilemap_left = 16
local bg_forest_local_tilemap_top = 0

local fg_leaves_local_tilemap_left = 20
local fg_leaves_top_local_tilemap_top = 0
local fg_leaves_center_local_tilemap_top = 1

function stage_intro_state:init()
  base_stage_state.init(self)

  -- stage id
  self.curr_stage_id = 1

  -- data
  self.curr_stage_data = stage_data[1]

  -- render

  -- create camera, but wait for player character to spawn before assigning it a target
  -- see on_enter for how we warp it to a good place first
  self.camera = camera_class()

  self.overlay = overlay()
  self.postproc = postprocess()
  self.is_fading_in = true  -- start at true immediately to avoid trying to fade out on first frame

  -- flag to indicate how far we are in the stage intro, and decide whether we can still skip or not
  self.is_about_to_load = false
end

function stage_intro_state:on_enter()
  -- like the original stage_state, we need to have collision masks in builtin spritesheet
  -- in v3, the builtin contains *only* collision masks so we must reload the *full* spritesheet
  --  for stage intro, hence reload memory length 0x2000
  -- alternatively, like stage clear, we could have a custom intro cinematics that doesn't use physics
  --  at all, and so no tile collision data is needed and we can just set intro spritesheet as built-in data
  local runtime_data_path = "data_stage"..self.curr_stage_id.."_intro.p8"
  reload(0x0, 0x0, 0x2000, runtime_data_path)

  -- we now copy the whole spritesheet for stage intro, as it uses the landing pose
  self:reload_sonic_spritesheet()

  self.camera:setup_for_stage(self.curr_stage_data)

  -- initial map region loading at region (0, 0), where stage intro starts
  reload(0x2000, 0x2000, 0x1000, self:get_map_region_filename(0, 0))
  self.loaded_map_region_coords = vector(0, 0)

  -- Copy the forest FG sprite batches in current tilemap memory to somewhere into general memory,
  --  so after reloading region 01 near the end of the character's fall,
  --  we can paste those back to the off-screen right region of the tilemap and
  --  keep drawing the FG leaves just during the transition where we see both
  --  the FG leaves and the tilemap wall + waterfall before landing
  -- According to base_stage_state:reload_sonic_spritesheet, all general memory is used,
  --  but in practice we don't need rows 2-4 of the sonic sprites (idle and fall main part
  --  are on row 1, landing is on row 5), for a total of 3 dual rows = 6 rows.
  -- Stored Sonic sprite memory row 1 starts at 0x4b00
  --  so row 2 starts at 0x4b00 + 0x400 = 0x4f00
  -- The forest FG center leaves sprites are located at top-left
  --  (fg_leaves_local_tilemap_left, fg_leaves_center_local_tilemap_top),
  --  where each line takes 128 = 0x80 cells (so advance by steps of 0x80 on source address),
  --  and 1 cell takes 1 byte.
  -- The union of all the batches cover 6 columns and 12 lines, so we're going to copy each line, 6 cells = 6 bytes at a time,
  --  so copy 6 bytes and advance by steps of 6 bytes on the destination address.
  -- Destination start address: 0x4f00
  -- Covered range: 12 * 6 = 72 = 0x48 bytes
  -- Destination end address + 1: 0x4f00 + 12 * 6 = 0x4f48
  -- 1 byte = 2px, so we cover 72*2 = 144px = 18*8px = 18 cell rows = 1 pixel row + 2 cell rows,
  --  and we have 6 full rows (in general memory equivalent), so it's more than enough.
  for i=0,11 do
    memcpy(0x4f00 + i * 6, 0x2000 + 0x80 * fg_leaves_center_local_tilemap_top + fg_leaves_local_tilemap_left + i * 0x80, 6)
  end

  -- starting v2 we want to play the full intro with character falling down from the sky,
  --  for a nice transition from the Start Cinematic
  -- however, it's still convenient to call spawn_player_char to create the PC and get it
  --  at the right X (the coroutine below will then warp Sonic upward)
  self:spawn_player_char()
  self.camera.target_pc = self.player_char

  -- warp Sonic very high in the sky
  self.player_char:warp_to(vector(self.player_char.position.x,
    self.player_char.position.y - map_region_height * 7))

  -- init camera immediately to ensure we only load region 00 for now
  self.camera:init_position(self.player_char.position)

  self.app:start_coroutine(self.play_intro_async, self)
end

-- never called, we directly load ingame cartridge
--[[
function stage_intro_state:on_exit()
  -- clear all coroutines
  self.app:stop_all_coroutines()

  -- clear object state vars
  self.overlay:clear_drawables()

  -- reinit camera offset for other states
  camera()
end
--]]


-- setup

function stage_intro_state:update()
  self.player_char:update()
  self.camera:update()
  self:check_reload_map_region()

  if input:is_just_pressed(button_ids.o) or input:is_just_pressed(button_ids.x) then
    -- skip sequence
    self.app:start_coroutine(self.skip_intro_and_load_ingame_async, self)
  end
end

function stage_intro_state:render()
  -- no need to floor camera position like stage_state, since we don't really move on X

  -- render custom background for the stage intro, instead of visual_stage.render_background
  self:render_background(self.camera.position)
  self:render_stage_elements()
  self:render_overlay()

  -- note that postproc is applied at the end, no matter where this is called
  -- fortunately, overlay is now shown after fade-in, so it doesn't matter
  self.postproc:apply()

--#if debug_character
  if self.player_char then
    self.player_char:debug_print_info()
  end
--#endif
end

local cloud_offsets = {
  vector(8, 0),
  vector(88, 20),
  vector(-20, 48),
  vector(34, 80),
  vector(110, 90),
  vector(-10, 110),
}

local horizon_offset = -150

-- render the stage background
function stage_intro_state:render_background(camera_pos)
  -- always draw full sky background to be safe
  camera()
  rectfill(0, 0, 127, 127, colors.dark_blue)

  -- apply some scaling < 1 so horizon elements move more slowly together
  local horizon_progress = -0.5 * camera_pos.y

  -- draw clouds
  -- render two batches, each covering the equivalent of a screen and chained,
  --  so that we can switch them alternatively every 150px (for a total of 300px)
  --  for a smooth looping without player seeing the disjunction (a batch of clouds
  --  is entirely offscreen when it warps to the other side, and warps also to an
  --  offscreen position, thanks to period of 300 > 2*128 and the offset subtracting
  --  150 > 128 in render_clouds_batch
  self:render_clouds_batch(horizon_progress)
  -- 150 to have the second batch halfway of period
  self:render_clouds_batch(horizon_progress + 150)

  -- horizon line serves as a reference for the background
  --  and moves down slowly when camera moves up
  local horizon_line_dy = horizon_offset + horizon_progress
  camera(0, -horizon_line_dy)

  -- horizon
  for i=0,15 do
    visual.sprite_data_t.horizon_gradient:render(vector(8 * i, 0))
  end
  visual.sprite_data_t.island:render(vector(24, 1))

  -- water
  self:render_water_shimmers()

  -- background forest: moves faster (remember we already have 0.5 of camera speed injected via camera(),
  --  so we only need to add 0.25 to get 0.75 of it)
  -- prefer injecting horizon progress (positive) and resetting camera() in
  --  render_background_forest, so we can use the passed argument to determine
  --  where to crop the drawing to optimize draw calls
  self:render_background_forest(-0.1 * camera_pos.y + horizon_line_dy)
end

function stage_intro_state:render_clouds_batch(progress)
  -- calculate section, which decreases from 3 (top) to -2 (ground)
  local section = int_div(progress, 300)
  local wrapped_reversed_camera_pos = progress % 300 - 150

  local cloud_sprite_data

  -- draw clouds smaller and smaller as we go down, then stop
  --  drawing them at all (as they should not be seen below the horizon line)
  if section > 1 then
    cloud_sprite_data = visual.sprite_data_t.cloud_medium
  elseif section > 0 then
    cloud_sprite_data = visual.sprite_data_t.cloud_small
  end

  if cloud_sprite_data then
    for offset in all(cloud_offsets) do
      cloud_sprite_data:render(offset + vector(0, wrapped_reversed_camera_pos))
    end
  end
end

function stage_intro_state:render_water_shimmers()
  -- this part copied from titlemenu:draw_sea_drawables
  -- if we do the same ingame eventually, just merge everything in some common
  -- visual method, like swap_colors

  -- water shimmer color cycle (in red and yellow in the original sprite)
  -- note that in stage intro we don't have sprites with water shimmer,
  --  so in fact the red and yellow are only drawn here in procedurally generated
  --  FX
  local period = visual.water_shimmer_period
  local ratio = (t() % period) / period
  local step_count = #visual.water_shimmer_color_cycle
  -- compute step from ratio (normally ratio should be < 1
  --  just in case, max to step_count)
  local step = min(flr(ratio * step_count) + 1, step_count)
  local new_colors = visual.water_shimmer_color_cycle[step]
  swap_colors({colors.red, colors.yellow}, new_colors)

  -- remaining code strongly adapted and simplified from titlemenu:draw_sea_drawables

  -- draw every given interval on y
  local shimmer_y_interval = 9
  local shimmer_base_x_list = {17, 43, 58, 77, 85, 100, 116}

  -- we are relative to horizon camera so just start short after y=0
  --  and continue for around 3 cells (24px) until we reach the forest
  -- (forest moves in vertical parallax so a bit faster, but at its maximum
  -- distance we should see around 3 cells of water vertically)
  local start_y = 12
  local stop_y = 30
  for y = start_y, stop_y, shimmer_y_interval do
    -- only draw if shimmers are visible on camera (values found by tuning,
    --  total range must cover 2 * screen_height since background moves at 0.5 speed)
    if horizon_offset - 380 < self.camera.position.y and self.camera.position.y < horizon_offset - 290 + screen_height then
      for x in all(shimmer_base_x_list) do
        -- pseudo-randomize raw colors (based on x, so won't change next frame)
        local color1, color2
        if x % 2 == 0 then
          color1 = colors.red
          color2 = colors.yellow
        else
          color1 = colors.yellow
          color2 = colors.red
        end

        -- pseudo-randomize x to avoid regular shimmers as we always use the same
        --  shimmer_base_x_list, by using y, a stable input
        x = x + (y-12) * y

        -- wrap horizontally
        x = x % screen_width

        -- add small offset on y for vertical variation
        -- make sure to create a new variable as y is used for the iteration
        local adjusted_y = y + x % 2

        -- draw triplets for "richer" visuals
        pset(x % screen_width, adjusted_y, color1)
        pset((x + 1) % screen_width, adjusted_y, color2)
        pset((x + 2) % screen_width, adjusted_y, color1)
      end
    end
  end

  pal()
end

-- a disordered list of numbers between 0 and 3 to avoid regular patterns
--  when drawing multiple lines of the same sprites, by offsetting them
--  based on j
local i_shuffle = {0, 2, 1, 3}

local leaves_tiles_height = 79

function stage_intro_state:render_background_forest(y_offset)
  camera()

  local y = y_offset - 20

  if -28 <= y and y <= 125 then
    -- draw bg forest tiles from mini-tilemap filled with forest sprites
    --  placed outside the visible tilemap area, i.e. after the 16 first columns
    --  of the actual tilemap
    -- note that the patch contains both the top and enough repeated middle sections
    --  to cover everything we need until the dark green midground
    palt(colors.pink)
    -- with patches of 4 cells, we only need 16/4 = 4 patches, so iterate on 0-3
    for i=0,3 do
      -- 8 px per cell, 4 cells horizontally per bg forest patch, so 8 * 4 = 32
      --  and pass 4 again as number of tiles horizontally
      -- dark green midground will cover the rest, so no need to span on 16 rows,
      --  10 rows are enough (we have a little more in tilemap data just in case)
      map(bg_forest_local_tilemap_left, bg_forest_local_tilemap_top, 32 * i, y, 4, 10)
    end
    palt()
  end
end

function stage_intro_state:render_foreground_leaves(y_offset)
  -- draw with neutral camera but use y (same plane as Sonic)
  camera()

  local fg_leaves_bottom = visual.sprite_data_t.fg_leaves_bottom

  local y = y_offset - 300

  -- draw shadow on top on character to hide it a few times, and esp. the last time
  --  to make it change animation behind the hood
  rectfill(0, y + 28 * 8, 127, y + 28 * 8 + 32, colors.black)
  rectfill(0, y + 58 * 8, 127, y + 58 * 8 + 96, colors.black)

  palt(colors.pink)

  -- draw bg forest tiles from mini-tilemap filled with forest sprites
  --  placed outside the visible tilemap area, i.e. after the 16 first columns
  --  of the actual tilemap
  -- this time, we draw top and center separately, as we'll need to repeat
  --  the center patch multiple times vertically to cover more height

  -- draw foreground leaves top
  -- note that the real upper bound is flr(y) <= screen_height - 1
  --  but to avoid a flr with just set the upper bound to screen_height
  -- in fact, map is very efficient, so this check is not as relevant as it was when drawing individual sprites
  if -7 <= y and y <= screen_height then
    -- this time we have a patch of 6 cells, so to cover screen we need ceil(16/6) = 3,
    --  so iterate on 0-2
    for i=0,2 do
      -- 8 px per cell, 6 cells horizontally per fg leaves patch, so 8 * 6 = 48
      --  and pass 6 again as number of tiles horizontally
      -- we only draw the top row, so pass 1 at the end
      map(fg_leaves_local_tilemap_left, fg_leaves_top_local_tilemap_top, 48 * i, y, 6, 1)
    end
  end

  local fg_leaves_center_batch_repeat_count = 6

  -- draw leaves center
  -- since map is very efficient and clips off-screen graphics, don't bother calling it only when at least one pixel
  --  is visible on screen
  -- same as above, to cover 16 tiles we need 3 batches, with some overshoot
  for i=0,2 do
    for j=0,fg_leaves_center_batch_repeat_count-1 do
      -- no manual offset code anymore, shuffling tiles for more variety is now part of the patch
      -- we prepared 12 rows of patches, for a total of 3 patches of 6x4 (themselves repeating 2x4 3 times)
      -- 1+ inside brackets since we draw center patch *after* the top row
      map(fg_leaves_local_tilemap_left, fg_leaves_center_local_tilemap_top, 48 * i, y + 8 * (1 + 12 * j), 6, 12)
    end
    -- final batch is a bit smaller, with only 6 rows
    map(fg_leaves_local_tilemap_left, fg_leaves_center_local_tilemap_top, 48 * i, y + 8 * (1 + 12 * fg_leaves_center_batch_repeat_count), 6, 6)
  end

  palt()

  -- draw foreground leaves bottom
  -- this could be done with map + sprite batches too, but for just a row
  --  we didn't bother, as we already got 60 FPS except on reload frame, and we'd need to copy
  --  that part to general memory to paste it back after reload region too
  -- each *full* patch of leaves center above occupies 12 rows
  -- +6 for the extra smaller batch at the end
  -- 1+ inside brackets since we draw center patch *after* the top row
  local y_leaves_bottom = y + 8 * (1 + 12 * fg_leaves_center_batch_repeat_count + 6)
  -- same remark on range/flr as for leaves top
  if -7 <= y_leaves_bottom and y_leaves_bottom <= screen_height then
    for i=0,15,2 do
      fg_leaves_bottom:render(vector(8 * i, y_leaves_bottom))
    end
  end
end

-- render the stage elements with the main camera:
-- - environment
-- - player character
function stage_intro_state:render_stage_elements()
  self:render_environment_midground()
  self:render_player_char()
  self:render_environment_foreground()
end

-- override
function stage_intro_state:render_environment_midground()
  -- only draw map tiles when low enough, to avoid odd periodic tiles drawing
  --  in "negative" regions as we warp very high in the sky
  if self.camera.position.y > 128 then
    -- base call
    base_stage_state.render_environment_midground(self)
  end

  -- draw leaves' own background as midground after normal map tiles
  --  to make sure they cover trunks/waterfall

  -- use neutral camera like render_foreground_leaves and work with y instead
  camera()

  -- same as y in render_foreground_leaves
  local y_leaves = -self.camera.position.y - 300

  if y_leaves < 128 then
    -- draw uniform background color until a little before bottom leaves
    rectfill(0, y_leaves + 8 * 8, 127, y_leaves + 8 * (leaves_tiles_height - 1) - 2, colors.dark_green)
  end
end

-- render the player character at its current position
function stage_intro_state:render_player_char()
  -- we override set_camera_with_origin to loop palm trees,
  --  so we must call the original implementation to draw the character,
  --  as it is the only entity unaffecting by the fake vertical looping
  base_stage_state.set_camera_with_origin(self)

  self.player_char:render()
end

-- override
function stage_intro_state:render_environment_foreground()
  -- base call
  base_stage_state.render_environment_foreground(self)

  -- foreground leaves: moves on same plane as Sonic
  self:render_foreground_leaves(-self.camera.position.y)
end

-- render the title overlay with a fixed ui camera
function stage_intro_state:render_overlay()
  camera()
  self.overlay:draw()
end

-- stage-related methods, simplified/adapted versions of stage_state equivalents

-- base_stage_state override
function stage_intro_state:get_map_region_coords(position)
  local uv = base_stage_state.get_map_region_coords(self, position)
  local region_count_per_row, region_count_per_column = self:get_region_grid_dimensions()

  -- we won't be touching the right edge in stage intro, so just clamp on left edge
  -- region_count_per_row is unused
  uv.x = max(0, uv.x)

  -- still clamp at bottom just in case we go too low
  -- (should be OK without though, as the dynamic camera limit clamps camera already)
  uv.y = min(uv.y, region_count_per_column - 1)

  return uv
end

-- base_stage_state override
function stage_intro_state:reload_map_region(new_map_region_coords)
  -- we didn't override get_map_region_coords and do all the job here so we can remember
  --  if we are above region 00 and wrapping with modulo
  local region_count_per_row, region_count_per_column = self:get_region_grid_dimensions()

  if new_map_region_coords.y < 0 then
    -- no wrapping, but at least load top-left region which should mostly be empty,
    --  so we can draw our custom background instead
    new_map_region_coords.y = 0
  end

  -- due to clamping, we can exceptionally get the same region again despite
  --  caller context difference check, so check difference again, or rather return
  --  early if nothing to do
  if self.loaded_map_region_coords == new_map_region_coords then
    return
  end

  local u_left = flr(new_map_region_coords.x)
  local v_upper = flr(new_map_region_coords.y)

  if new_map_region_coords.x % 1 == 0 and new_map_region_coords.y % 1 == 0 then
    -- integer coordinates => solo region
    log("reload map region: "..new_map_region_coords.." (single)", "reload")
    reload(0x2000, 0x2000, 0x1000, self:get_map_region_filename(u_left, v_upper))
  elseif new_map_region_coords.x % 1 == 0 and new_map_region_coords.y % 1 ~= 0 then
    -- fractional y => vertically overlapping region (2 patches)
    log("reload map region: "..new_map_region_coords.." (Y overlap)", "reload")

    -- copy lower part of map region above to upper part of map memory
    self:reload_vertical_half_of_map_region(vertical_dirs.up, self:get_map_region_filename(u_left, v_upper))
    -- copy upper part of map region below to lower part of map memory
    self:reload_vertical_half_of_map_region(vertical_dirs.down, self:get_map_region_filename(u_left, v_upper + 1))
--#if assert
  else
    assert(false, "unsupported case")
--#endif
  end

  self.loaded_map_region_coords = new_map_region_coords

  -- extra code to reload the FG leaves (center) from region 00 into memory after losing them when reloading new regions
  --  (0, 0.5) and (0, 1)
  for i=0,11 do
    -- reverse operation of on_enter
    memcpy(0x2000 + 0x80 * fg_leaves_center_local_tilemap_top + fg_leaves_local_tilemap_left + i * 0x80, 0x4f00 + i * 6, 6)
  end
end

-- base_stage_state override
function stage_intro_state:set_camera_with_origin(origin)
  origin = origin or vector.zero()

  local camera_topleft = vector(self.camera.position.x - screen_width / 2 - origin.x, self.camera.position.y - screen_height / 2 - origin.y)
  if camera_topleft.y < 0 then
    -- above normal region, loop the decor
    camera_topleft.y = camera_topleft.y % 128
  end

  camera(camera_topleft.x, camera_topleft.y)
end


-- async sequences

-- only for user-requested skip sequence
function stage_intro_state:skip_intro_and_load_ingame_async()
  -- do not fade out during fade in to avoid postproc conflict,
  --  and do not fade out if we're about to load before fade out could end anyway,
  --  to avoid partial darkness at load time
  if not self.is_fading_in and not self.is_about_to_load then

    -- stop wind looping SFX if any
    -- (short fade out to avoid pop)
    -- (does nothing if we've already stopped it)
    music(-1, 100)

    -- fade out
    for i = 1, 5 do
      self.postproc.darkness = i
      yield_delay_frames(6)
    end

    -- If Sonic has already landed (before or during the fade out above),
    --  we should warp it to the ground with no landing animation,
    --  then fade in again so player understands what happened before getting into ingame and to avoid
    --  clash of brightness on ingame cartridge load.
    -- Otherwise, don't bother, as we will see Sonic land right before fade out finishes (worst case,
    --  exactly on fade out frame so technically player won't see it, but okay), which is enough
    --  to understand (plus, Sonic would be in his landing pose + PFX already, which is more complicated
    --  to cancel). We will have a sudden brightness change on ingame cartridge load, but skipping
    --  stage intro at the last moment is rare enough that we can tolerate this.
    if self.player_char.motion_state ~= motion_states.standing then
      -- to avoid a clash when loading ingame cartridge, we warp Sonic to the ground and
      --  fade in already, so the darkness doesn't suddenly change after load, and Sonic
      --  is already at the correct position

      -- warp Sonic immediately down to the ground, and warp camera too
      -- also set speed on y to anything between 0 and landing_anim_min_speed_y (excluded)
      --  to prevent landing animation + PFX due to fast landing
      -- here, we chose landing_anim_min_speed_y / 2, but even 0 would work as the 6 frames of wait
      --  more below are enough to ensure Sonic reaches the ground before fading in again
      self.player_char:warp_to(self.curr_stage_data.spawn_location:to_topleft_position())
      self.camera:init_position(self.player_char.position)
      self.player_char.velocity.y = pc_data.landing_anim_min_speed_y / 2

      -- Before, when we were not reducing Sonic velocity, it was important to call
      -- self:check_reload_map_region()
      -- to avoid having Sonic fall through the ground.
      -- (Explanation: otherwise, Sonic falls 1 extra frame at max air speed y (7px),
      --  then next frame once more for a total of 14px which is above
      --  max_ground_escape_height and actually falls through the ground.
      -- With loading, it stops just at 7px, the limit, and lands correctly.)
      -- Now, it is not needed anymore because the reduced landing speed ensures that
      --  region is loaded before Sonic goes too far under the ground.

      yield_delay_frames(6)

      -- fade in
      for i = 4, 0, -1 do
        self.postproc.darkness = i
        yield_delay_frames(6)
      end
    end

    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_ingame')
  end
end

function stage_intro_state:play_intro_async()
  -- start with black screen
  self.postproc.darkness = 5

  -- set fall speed to max to avoid slow motion at the beginning of the sequence
  self.player_char.velocity.y = pc_data.max_air_velocity_y

  -- force enter air spin without trigerring an actual jump, just to play the spin animation
  self.player_char:enter_motion_state(motion_states.air_spin)

  -- play falling wind looping SFX as music
  music(audio.music_ids.fall_wind)

  yield_delay_frames(31)

  -- fade in
  for i = 4, 0, -1 do
    self.postproc.darkness = i
    yield_delay_frames(6)
  end

  -- we're technically 6 frames after the end of fade in, but it's okay
  self.is_fading_in = false

  -- wait for Sonic to enter leaves area
  yield_delay_frames(90)

  -- play falling through leaves looping SFX as music (replaces wind)
  music(audio.music_ids.fall_leaves)

  -- wait for Sonic to fall go behind some opaque foreground/midground
  --  so we can switch sprite without player noticing sudden change
  yield_delay_frames(70)

  self.player_char:enter_motion_state(motion_states.falling)
  self.player_char.should_play_spring_jump = true

  -- wait for Sonic to leave leaves area
  yield_delay_frames(10)

  -- stop looping SFX
  -- (short fade out to avoid pop)
  music(-1, 100)

  yield_delay_frames(110)

  -- show splash screen
  self:show_stage_splash_async()

  -- wait 2s
  yield_delay_frames(60*2)

  -- hide splash as Sonic is still falling
  self:hide_stage_splash_async()

  -- see skip_intro_and_load_ingame_async, we have 2 fades, each takes 5 iterations of 6 frames
  --  (the last frame has no darkness but we count it in to simplify)
  local fade_out_in_duration = 60  -- 2 * 6 * 5

  -- subtract duration of fade out from time remaining
  -- of course, in this particular case, we wait 0 frames which does nothing,
  --  but we keep the general formula in case fade_out_in_duration becomes less than
  --  that delay before load of 60 frames (if it becomes more, then we must set
  --  is_about_to_load flag to true before hide_stage_splash_async call)
  yield_delay_frames(60 - fade_out_in_duration)

  -- from this point, there is not enough time to complete fade out, we are about to load
  self.is_about_to_load = true

  -- corresponds to fade out + fade in time
  yield_delay_frames(fade_out_in_duration)

  -- splash is over, load ingame cartridge and give control to player
  -- prefer passing basename for compatibility with .p8.png
  load('picosonic_ingame')

  --[[#pico8
    assert(false, "could not load picosonic_ingame, make sure cartridge has been built")
  --#pico8]]
end

function stage_intro_state:show_stage_splash_async()
  self.app:yield_delay_s(stage_intro_data.show_stage_splash_delay)

  -- init position y is -height so it starts just at the screen top edge
  local banner = rectangle(vector(9, -106), 32, 106, colors.red)
  self.overlay:add_drawable("banner", banner)

  -- banner text accompanies text, and ends at y = 89, so starts at y = 89 - 106 = -17
  local banner_text = label("pico\nsonic", vector(16, -17), colors.white)
  self.overlay:add_drawable("banner_text", banner_text)

  -- make banner enter from the top
  ui_animation.move_drawables_on_coord_async("y", {banner, banner_text}, {0, 89}, -106, 0, 9)

  local zone_rectangle = rectangle(vector(128, 45), 47, 3, colors.black)
  self.overlay:add_drawable("zone_rect", zone_rectangle)

  local zone_label = label(self.curr_stage_data.title, vector(129, 43), colors.white)
  self.overlay:add_drawable("zone", zone_label)

  -- make text enter from the right
  ui_animation.move_drawables_on_coord_async("x", {zone_rectangle, zone_label}, {0, 1}, 128, 41, 14)
end

function stage_intro_state:hide_stage_splash_async()
  -- hide is now split from show, so we must retrieve the drawable references by name

  -- make banner exit to the top
  local banner = self.overlay.drawables_map["banner"]
  local banner_text = self.overlay.drawables_map["banner_text"]
  ui_animation.move_drawables_on_coord_async("y", {banner, banner_text}, {0, 89}, 0, -106, 8)

  -- make text exit to the right
  local zone_rectangle = self.overlay.drawables_map["zone_rect"]
  local zone_label = self.overlay.drawables_map["zone"]
  ui_animation.move_drawables_on_coord_async("x", {zone_rectangle, zone_label}, {0, 1}, 41, 128, 14)

  self.overlay:remove_drawable("banner")
  self.overlay:remove_drawable("banner_text")
  self.overlay:remove_drawable("zone")
end


return stage_intro_state

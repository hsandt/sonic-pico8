local postprocess = require("engine/render/postprocess")
local label = require("engine/ui/label")
local overlay = require("engine/ui/overlay")
local rectangle = require("engine/ui/rectangle")

local stage_data = require("data/stage_data")
local stage_intro_data = require("data/stage_intro_data")
local base_stage_state = require("ingame/base_stage_state")
local camera_class = require("ingame/camera")
local player_char = require("ingame/playercharacter")
local visual = require("resources/visual_common")
local visual_ingame_data = require("resources/visual_ingame_numerical_data")
local visual_stage = require("resources/visual_stage")
local ui_animation = require("ui/ui_animation")

local stage_intro_state = derived_class(base_stage_state)

stage_intro_state.type = ':stage_intro'

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

  -- for now, just hardcode region loading/coords to simplify, as we know the intro
  -- only takes place in the region (0, 1)
  reload(0x2000, 0x2000, 0x1000, self:get_map_region_filename(0, 1))
  self.loaded_map_region_coords = vector(0, 1)

  -- starting v2 we want to play the full intro with character falling down from the sky,
  --  for a nice transition from the Start Cinematic
  -- however, it's still convenient to call spawn_player_char to create the PC and get it
  --  at the right X (the coroutine below will then warp Sonic upward)
  self:spawn_player_char()
  self.camera.target_pc = self.player_char

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
end

local cloud_offsets = {
  vector(8, 0),
  vector(88, 20),
  vector(-20, 48),
  vector(34, 80),
  vector(110, 90),
  vector(-10, 110),
}

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
  local horizon_line_dy = 156 + horizon_progress
  camera(0, -horizon_line_dy)

  -- horizon
  for i=0,15 do
    visual.sprite_data_t.horizon_gradient:render(vector(8 * i, 0))
  end
  visual.sprite_data_t.island:render(vector(24, 1))

  -- water
  self:render_water_shimmers()

  -- background forest: moves faster
  self:render_background_forest(-0.75 * camera_pos.y)

  -- foreground leaves: moves on same plane as Sonic
  self:render_foreground_leaves(-camera_pos.y)
end

function stage_intro_state:render_clouds_batch(progress)
  -- calculate section, which decreases from 3 (top) to -2 (ground)
  local section = int_div(progress, 300)
  local wrapped_reversed_camera_pos = progress % 300 - 150

  local cloud_sprite_data

  -- draw clouds smaller and smaller as we go down, then stop
  --  drawing them at all (as they should not be seen below the horizon line)
  if section > 2 then
    cloud_sprite_data = visual.sprite_data_t.cloud_big
  elseif section > 0 then
    cloud_sprite_data = visual.sprite_data_t.cloud_medium
  elseif section > -1 then
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
    if self.camera.position.y > 156 - 90 and self.camera.position.y < 156 + 30 + screen_height then
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
local j_shuffle = {0, 2, 1, 3}

function stage_intro_state:render_background_forest(progress)
  local bg_forest_top = visual.sprite_data_t.bg_forest_top
  local bg_forest_center = visual.sprite_data_t.bg_forest_center

  local y = progress + 100

  -- draw forest top
  for i=0,15,4 do
    bg_forest_top:render(vector(8 * i, y))
  end

  for j=1,15 do
    local j_offset = j_shuffle[(j-1) % 4 + 1]
    -- draw forest center line with adjusted i for variation
    -- since we are drawing a sprite of 4x1 and not 1x1 sprites,
    --  we cannot simply apply modulo on i to wrap around horizontally
    --  (the 4x1 sprite's i itself is never out of range, 12 + 3 = 15)
    -- instead, let's draw the sprites as usual first,
    --  then, as we created a hole on the left if j_offset > 0,
    --  we'll fill the hole with an extra draw
    for i=0,15,4 do
      local adjusted_i = i + j_offset
      bg_forest_center:render(vector(8 * adjusted_i, y + 8 * j))
    end
    if j_offset > 0 then
      -- fill the hole on the left
      bg_forest_center:render(vector(8 * (j_offset - 4), y + 8 * j))
    end
  end
end

function stage_intro_state:render_foreground_leaves(progress)
end

-- render the stage elements with the main camera:
-- - environment
-- - player character
function stage_intro_state:render_stage_elements()
  self:render_environment_midground()
  self:render_player_char()
  self:render_environment_foreground()
end

-- render the player character at its current position
function stage_intro_state:render_player_char()
  -- we override set_camera_with_origin to loop palm trees,
  --  so we must call the original implementation to draw the character,
  --  as it is the only entity unaffecting by the fake vertical looping
  base_stage_state.set_camera_with_origin(self)

  self.player_char:render()
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

  -- don't clamp ap
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
end

-- base_stage_state override
function stage_intro_state:set_camera_with_origin(origin)
  -- hacked implementation to loop the decor (used to render palm trees as part of foreground,
  --  and midground via set_camera_with_region_origin)

  origin = origin or vector.zero()

  -- ! Unlike tiles, palm trees are not looped with a smart swapping of vertical halves,
  --   so region 00 must have 2 identical vertical halves when it comes to palm tree representative
  --   tiles (other tiles can differ) to give the illusion of looping without a break every 128

  local camera_topleft = vector(self.camera.position.x - screen_width / 2 - origin.x, self.camera.position.y - screen_height / 2 - origin.y)
  if camera_topleft.y < 0 then
    -- above normal region, loop the decor
    camera_topleft.y = camera_topleft.y % 128
  end

  camera(camera_topleft.x, camera_topleft.y)
end

function stage_intro_state:spawn_palm_tree_leaves_at(global_loc)
  -- remember where we found palm tree leaves core tile, to draw extension sprites around later
  add(self.palm_tree_leaves_core_global_locations, global_loc)
  log("added palm #"..#self.palm_tree_leaves_core_global_locations, "palm")
end

-- iterate over each tile of the current region
--  and apply method callback for each of them (to spawn objects, etc.)
--  the method callback but take self, a global tile location and the sprite id at this location
function stage_intro_state:scan_current_region_to_spawn_objects()
  for i = 0, map_region_tile_width - 1 do
    for j = 0, map_region_tile_height - 1 do
      -- here we already have region (i, j), so no need to convert for mget
      local tile_sprite_id = mget(i, j)

      -- there is only one object type we are interested in, the goal plate,
      --  so check it manually instead of using a table of spawn callbacks as in stage_state
      if tile_sprite_id == visual_ingame_data.palm_tree_leaves_core_id then
        -- tile has been recognized as a representative tile for object spawning
        --  apply callback now

        -- we do need to convert location now since spawn methods work in global coordinates
        local region_loc = location(i, j)
        -- hardcoded region 00, so:
        -- local global_loc = region_loc + location(0, 0)
        --  so just pass region_loc
        self:spawn_palm_tree_leaves_at(region_loc)
      end
    end
  end
end


-- async sequences

function stage_intro_state:play_intro_async()
  -- start with black screen
  self.postproc.darkness = 5

  -- warp Sonic to the sky
  self.player_char:warp_to(vector(self.player_char.position.x, self.player_char.position.y - map_region_height * 6))
  self.camera:init_position(self.player_char.position)

  -- force enter air spin without trigerring an actual jump, just to play the spin animation
  self.player_char:enter_motion_state(motion_states.air_spin)

  -- self:check_reload_map_region() will be called on next update since coroutines are updated
  --  after state in gameapp:step(), so wait at least 1 frame
  yield_delay_frames(1)

  -- we still need to reload map region hardcoded to 00,
  --  and spawn objects just there (basically just spawn the palm trees)
  -- it's very important that we reloaded map region at this point!
  self:scan_current_region_to_spawn_objects()

  yield_delay_frames(30)

  -- while splash is still shown, fade in (as in Hydrocity Act 1)
  for i = 4, 0, -1 do
    self.postproc.darkness = i
    yield_delay_frames(6)
  end

  yield_delay_frames(30)


  -- wait for Sonic to fall a bit and go behind some leaves
  --  so we can switch sprite without player noticing sudden change
  yield_delay_frames(30)

  self.player_char:enter_motion_state(motion_states.falling)
  self.player_char.should_play_spring_jump = true

  -- wait for fall to end
  yield_delay_frames(60*4)

  -- show splash screen
  self:show_stage_splash_async()

  yield_delay_frames(60*3)

  -- hide splash as Sonic is still falling
  self:hide_stage_splash_async()

  yield_delay_frames(60*1)

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

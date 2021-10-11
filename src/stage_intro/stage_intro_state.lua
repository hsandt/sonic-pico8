local postprocess = require("engine/render/postprocess")
local label = require("engine/ui/label")
local overlay = require("engine/ui/overlay")
local rectangle = require("engine/ui/rectangle")

local stage_data = require("data/stage_data")
local stage_intro_data = require("data/stage_intro_data")
local base_stage_state = require("ingame/base_stage_state")
local camera_class = require("ingame/camera")
local player_char = require("ingame/playercharacter")
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

  -- Reduced version of Sonic sprite copy, copied from stage_state:reload_runtime_data
  --  We know Sonic doesn't spin dash during the intro, so storing the main sprites in general memory will be enough
  -- Copy the first 8 rows = 4 double rows at once
  reload(0x4b00, 0x400, 0x1000, "data_stage_sonic.p8")

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
  visual_stage.render_background(self.camera.position)
  self:render_stage_elements()
  self:render_overlay()
  self.postproc:apply()
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
  -- self:set_camera_with_origin()
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

  -- -- in stage intro, we cheat to show an infinite vertically scrolling background
  -- --  during the fall phase by applying a modulo to the region v, instead of clamping
  -- if uv.y < 0 then
  --   uv.y = uv.y % 1
  -- else
    -- still clamp at bottom just in case we go too low
    -- (should be OK without though, as the dynamic camera limit clamps camera already)
    uv.y = min(uv.y, region_count_per_column - 1)
  -- end
  return uv
end
-- not enough, override the whole thing to allow wrapping on single region (invert lower and upper halves!)

-- base_stage_state override
function stage_intro_state:reload_map_region(new_map_region_coords)
  -- we didn't override get_map_region_coords and do all the job here so we can remember
  --  if we are above region 00 and wrapping with modulo
  local region_count_per_row, region_count_per_column = self:get_region_grid_dimensions()

  -- we won't be touching the right edge in stage intro, so just clamp on left edge
  -- region_count_per_row is unused
  new_map_region_coords.x = max(0, new_map_region_coords.x)

  local is_wrapping = false
  printh("new_map_region_coords.y: "..nice_dump(new_map_region_coords.y))

  -- in stage intro, we cheat to show an infinite vertically scrolling background
  --  during the fall phase by applying a modulo to the region v, instead of clamping
  if new_map_region_coords.y < 0 then
    new_map_region_coords.y = new_map_region_coords.y % 1
    is_wrapping = true
  else
    -- -- still clamp at bottom just in case we go too low
    -- -- (should be OK without though, as the dynamic camera limit clamps camera already)
    -- new_map_region_coords.y = min(new_map_region_coords.y, region_count_per_column - 1)
  end

  local u_left = flr(new_map_region_coords.x)
  local v_upper = flr(new_map_region_coords.y)

  printh("new_map_region_coords adjusted: "..nice_dump(new_map_region_coords))

  if new_map_region_coords.x % 1 == 0 and new_map_region_coords.y % 1 == 0 then
    -- integer coordinates => solo region
    log("reload map region: "..new_map_region_coords.." (single)", "reload")

    reload(0x2000, 0x2000, 0x1000, self:get_map_region_filename(u_left, v_upper))
    printh("full region")
  elseif new_map_region_coords.x % 1 == 0 and new_map_region_coords.y % 1 ~= 0 then
    -- fractional y => vertically overlapping region (2 patches)
    log("reload map region: "..new_map_region_coords.." (Y overlap)", "reload")

    -- copy lower part of map region above to upper part of map memory
    self:reload_vertical_half_of_map_region(vertical_dirs.up, self:get_map_region_filename(u_left, v_upper))
    -- copy upper part of map region below to lower part of map memory
    -- simulate infinite looping tilemap above by wrapping region 00 bottom with top when above region 00
    local v_upper_to_load
    if is_wrapping then
      -- reuse upper half of region 00 (0)
      v_upper_to_load = v_upper
    else
      v_upper_to_load = v_upper + 1
    end
    self:reload_vertical_half_of_map_region(vertical_dirs.down, self:get_map_region_filename(u_left, v_upper_to_load))
    printh("half region")
  else
    assert(false, "unsupported case")
  end

  self.loaded_map_region_coords = new_map_region_coords
end

-- set the camera offset to draw stage elements with optional origin (default (0, 0))
-- tilemap should be drawn with region map topleft (in px) as origin
-- characters and items should be drawn with extended map topleft (0, 0) as origin
-- function stage_intro_state:set_camera_with_origin(origin)
--   origin = origin or vector.zero()
--   printh("origin: "..nice_dump(origin))
--   -- the camera position is used to render the stage. it represents the screen center
--   -- whereas pico-8 defines a top-left camera position, so we subtract a half screen to center the view
--   -- finally subtract the origin to place tiles correctly
--   camera(self.camera.position.x - screen_width / 2 - origin.x, self.camera.position.y - screen_height / 2 - origin.y)
-- end

-- base_stage_state override
-- hacked implementation to loop the decor (used to render palm trees as part of foreground,
--  and midground via set_camera_with_region_origin)
function stage_intro_state:set_camera_with_origin(origin)
  origin = origin or vector.zero()

  -- FIXME: palm tree top sprite doesn't match leaves
  -- use stage_common_data.transition_margin?

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
  self.player_char:warp_to(vector(self.player_char.position.x, self.player_char.position.y - 8*16*6))
  self.camera:init_position(self.player_char.position)
  -- self:check_reload_map_region() will be called on next update since coroutines are updated
  --  after state in gameapp:step(), so wait at least 1 frame
  yield_delay_frames(1)

  -- we still need to reload map region hardcoded to 00,
  --  and spawn objects just there (basically just spawn the palm trees)
  -- it's very important that we reloaded map region at this point!
  self:scan_current_region_to_spawn_objects()

  -- show splash screen while still background is still black
  self.app:start_coroutine(self.show_stage_splash_async, self)

  -- while splash is still shown, fade in (as in Hydrocity Act 1)
  for i = 4, 0, -1 do
    self.postproc.darkness = i
    yield_delay_frames(6)
  end

  -- wait for fall to end
  yield_delay_frames(60*5)

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

  -- keep zone displayed for a moment
  yield_delay_frames(101)

  -- make banner exit to the top
  ui_animation.move_drawables_on_coord_async("y", {banner, banner_text}, {0, 89}, 0, -106, 8)

  -- make text exit to the right
  ui_animation.move_drawables_on_coord_async("x", {zone_rectangle, zone_label}, {0, 1}, 41, 128, 14)

  self.overlay:remove_drawable("banner")
  self.overlay:remove_drawable("banner_text")
  self.overlay:remove_drawable("zone")
end


return stage_intro_state

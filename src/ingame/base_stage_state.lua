local gamestate = require("engine/application/gamestate")

local stage_data = require("data/stage_data")
local camera_class = require("ingame/camera")
local visual = require("resources/visual_common")

-- abstract base class for stage_state, stage_intro_state and stage_clear_state
-- it contains functionality common to all three cartridges showing stage content,
--  such as rendering the environment
local base_stage_state = derived_class(gamestate)

function base_stage_state:init()
  -- create camera, but wait for player character to spawn before assigning it a target
  -- see on_enter for how we warp it to a good place first
  self.camera = camera_class()

  -- CARTRIDGE NOTE: currently objects are not scanned in stage_intro, and there are no
  --  palm trees at stage start anyway. Stage clear doesn't have them at stage end either.
--#if ingame
  -- palm trees: list of global locations of palm tree leaves core sprites detected
  -- used to draw the palm tree extension sprites on foreground
  self.palm_tree_leaves_core_global_locations = {}
--#endif

-- don't initialize loaded region coords (we don't know in which region player character will spawn),
--  each child class on_enter will set them in on_enter
-- self.loaded_map_region_coords = nil
end


-- extended map system

-- return map filename for current stage and given region coordinates (u: int, v: int)
--  do not try this with transitional regions, instead we'll patch them from individual regions
function base_stage_state:get_map_region_filename(u, v)
  return "data_stage"..self.curr_stage_id.."_"..u..v..cartridge_ext
end


--#ifn stage_clear

-- global <-> region location converters

function base_stage_state:global_to_region_location(global_loc)
  return global_loc - self:get_region_topleft_location()
end

function base_stage_state:region_to_global_location(region_loc)
  return region_loc + self:get_region_topleft_location()
end

-- queries

-- return true iff global_tile_loc: location is in any of the areas: {location_rect}
function base_stage_state:is_tile_in_area(global_tile_loc, areas, extra_condition_callback)
  for area in all(areas) do
    if (extra_condition_callback == nil or extra_condition_callback(global_tile_loc, area)) and
        area:contains(global_tile_loc) then
      return true
    end
  end
  return false
end

-- return true iff tile is located in loop entrance area
--  *except at its top-left which is reversed to non-layered entrance trigger*
function base_stage_state:is_tile_in_loop_entrance(global_tile_loc)
  return self:is_tile_in_area(global_tile_loc, self.curr_stage_data.loop_entrance_areas, function (global_tile_loc, area)
    return global_tile_loc ~= location(area.left, area.top)
  end)
end

-- return true iff tile is located in loop entrance area
--  *except at its top-right which is reversed to non-layered entrance trigger*
function base_stage_state:is_tile_in_loop_exit(global_tile_loc)
  return self:is_tile_in_area(global_tile_loc, self.curr_stage_data.loop_exit_areas, function (global_tile_loc, area)
    return global_tile_loc ~= location(area.right, area.top)
  end)
end

-- return true iff tile is located at the top-left (trigger location) of any entrance loop
function base_stage_state:is_tile_loop_entrance_trigger(global_tile_loc)
  for area in all(self.curr_stage_data.loop_entrance_areas) do
    if global_tile_loc == location(area.left, area.top) then
      return true
    end
  end
end

-- return true iff tile is located at the top-right (trigger location) of any exit loop
function base_stage_state:is_tile_loop_exit_trigger(global_tile_loc)
  for area in all(self.curr_stage_data.loop_exit_areas) do
    if global_tile_loc == location(area.right, area.top) then
      return true
    end
  end
end

--#endif


-- camera

-- set the camera offset to draw stage elements with optional origin (default (0, 0))
-- tilemap should be drawn with region map topleft (in px) as origin
-- characters and items should be drawn with extended map topleft (0, 0) as origin
function base_stage_state:set_camera_with_origin(origin)
  origin = origin or vector.zero()
  -- the camera position is used to render the stage. it represents the screen center
  -- whereas pico-8 defines a top-left camera position, so we subtract a half screen to center the view
  -- finally subtract the origin to place tiles correctly
  camera(self.camera.position.x - screen_width / 2 - origin.x, self.camera.position.y - screen_height / 2 - origin.y)
end

-- set the camera offset to draw stage elements with region origin
--  use this to draw tiles with relative location
function base_stage_state:set_camera_with_region_origin()
  local region_topleft_loc = self:get_region_topleft_location()
  self:set_camera_with_origin(vector(tile_size * region_topleft_loc.i, tile_size * region_topleft_loc.j))
end


-- region helpers

-- return current region topleft as location (convert uv to ij)
function base_stage_state:get_region_topleft_location()
  -- note that result should be integer, although due to region coords being sometimes in .5 for transitional areas
  --  they will be considered as fractional numbers by Lua (displayed with '.0' in native Lua)
  return location(map_region_tile_width * self.loaded_map_region_coords.x, map_region_tile_height * self.loaded_map_region_coords.y)
end


-- render

--#ifn itest

local waterfall_color_cycle = {
  -- original colors : dark_blue, indigo, blue, white
  {colors.dark_blue, colors.blue,      colors.blue,      colors.white},
  {colors.white,     colors.dark_blue, colors.blue,      colors.blue},
  {colors.blue,      colors.white,     colors.dark_blue, colors.blue},
  {colors.blue,      colors.blue,      colors.white,     colors.dark_blue},
}

function base_stage_state:set_color_palette_for_waterfall_animation()
  local period = 0.5
  local ratio = (t() % period) / period
  local step_count = #waterfall_color_cycle
  local step = min(flr(ratio * step_count) + 1, step_count)
  local new_colors = waterfall_color_cycle[step]
  pal(colors.dark_blue, new_colors[1])
  pal(colors.indigo, new_colors[2])
  pal(colors.blue, new_colors[3])
  pal(colors.white, new_colors[4])
end

--#endif

-- render the stage environment (tiles)
function base_stage_state:render_environment_midground()
  self:set_camera_with_region_origin()
  self:render_environment_midground_static()
  self:render_environment_midground_waterfall()
end

-- render the stage environment (tiles)
function base_stage_state:render_environment_midground_static()
  set_unique_transparency(colors.pink)

  -- only draw midground tiles that don't need waterfall color swapping animation
  --  note that we are drawing loop entrance tiles even though they will be (they'll be drawn on foreground later)
  -- possible optimize: don't draw the whole stage offset by camera,
  --  instead just draw the portion of the level of interest
  --  (and either keep camera offset or offset manually and subtract from camera offset)
  -- that said, I didn't notice a performance drop by drawing the full tilemap
  --  so I guess map is already optimized to only draw what's on camera
  map(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.midground)
end

-- render the stage environment (tiles)
function base_stage_state:render_environment_midground_waterfall()
--#ifn itest
  -- waterfall sprites are now placed as tiles of the tilemap, so we apply the waterfall color swap animation
  --  directly on them
  self:set_color_palette_for_waterfall_animation()
--#endif

  -- only draw midground tiles that need waterfall color swapping animation
  map(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.waterfall)

--#ifn itest
  -- clear palette swap, or Sonic (and rocks, etc.) will inherit from the waterfall blue color swapping!
  pal()
--#endif
end

function base_stage_state:render_environment_foreground()
--#ifn itest
  set_unique_transparency(colors.pink)

  -- draw tiles always on foreground first
  self:set_camera_with_region_origin()
  map(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.foreground)

--#if busted
  if not self.curr_stage_data then
    return
  end
--#endif

  -- CARTRIDGE NOTE: currently objects are not scanned in stage_intro, and there are no
  --  loops nor palm trees at stage start anyway. Stage clear doesn't have them at stage end either.
--#if ingame

  -- draw loop entrances on the foreground (it was already drawn on the midground, so we redraw on top of it;
  --  it's ultimately more performant to draw twice than to cherry-pick, in case loop entrance tiles
  --  are reused in loop exit or other possibly disabled layers so we cannot just tag them all foreground)
  local region_topleft_loc = self:get_region_topleft_location()

  self:set_camera_with_origin()
  for area in all(self.curr_stage_data.loop_entrance_areas) do
    -- draw map subset just for the loop entrance
    -- if this is out-of-screen, map will know it should draw nothing so this is very performant already
    map(area.left - region_topleft_loc.i, area.top - region_topleft_loc.j,
        tile_size * area.left, tile_size * area.top,
        area.right - area.left + 1, area.bottom - area.top + 1,
        sprite_masks.midground)
  end

  -- draw palm tree extension sprites on the foreground, so they can hide the character and items at the top
  for global_loc in all(self.palm_tree_leaves_core_global_locations) do
    -- top has pivot at its bottom-left = the top-left of the core
    visual.sprite_data_t.palm_tree_leaves_top:render(global_loc:to_topleft_position())
    -- right has pivot at is bottom-left = the top-right of the core
    local right_global_loc = global_loc + location(1, 0)
    visual.sprite_data_t.palm_tree_leaves_right:render(right_global_loc:to_topleft_position())
    -- left is mirrored from right, so its pivot is at its bottom-right = the top-left of the core
    visual.sprite_data_t.palm_tree_leaves_right:render(global_loc:to_topleft_position(), --[[flip_x:]] true)
  end

--(ingame)
--#endif

--(!itest)
--#endif
end

return base_stage_state

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

--#ifn stage_clear
  -- waterfall: list of global locations i of every column where we should draw a waterfall
  --  going down. We don't need to store full location with j because waterfall always
  --  start at j=0
  self.waterfall_global_locations_i = {}
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


--#ifn stage_clear

-- background

function base_stage_state:scan_current_region_to_spawn_waterfalls()
  -- iterate over the top row
  for i = 0, map_region_tile_width - 1 do
    -- here we already have region (i, 0), so no need to convert for mget
    local tile_sprite_id = mget(i, 0)
    if tile_sprite_id == 0 then
      -- this top tile is empty, waterfall should fall from here
      -- we do need to convert location now since spawn methods work in global coordinates
      local region_loc = location(i, 0)
      local global_loc = self:region_to_global_location(region_loc)
      add(self.waterfall_global_locations_i, global_loc.i)
    end
  end
end

--#endif


-- render

-- render waterfalls
-- usually in visual_state, this one requires some extra info and to track time,
--  so it was easier to put in base_stage_state
function base_stage_state:render_waterfalls()
  self:set_camera_with_origin()

  local camera_pos = self.camera.position
  local left_edge = camera_pos.x - screen_width / 2
  local right_edge = camera_pos.x + screen_width / 2
  local top_tile_to_draw, bottom_tile_to_draw

  for waterfall_global_location_i in all(self.waterfall_global_locations_i) do
    -- extract the horizontal part of the check in camera_class:is_rect_visible
    -- proper check on right edge is flr(right_edge) >= ... + 1 but we know the rhs is integer
    --  so we just do this to spare characters
    if left_edge < tile_size * (waterfall_global_location_i + 1) and
        right_edge > tile_size * waterfall_global_location_i then

      -- lazy evaluation (to spare cpu when no waterfall is visible)
      if not top_tile_to_draw then
        -- flr on one side, ceil on the other, so we are sure to draw a sprite as long
        --  as it's even partially visible
        top_tile_to_draw = flr((camera_pos.y - screen_height / 2) / tile_size)
        bottom_tile_to_draw = ceil((camera_pos.y + screen_height / 2) / tile_size) - 1
      end

      self:draw_waterfall(waterfall_global_location_i, top_tile_to_draw, bottom_tile_to_draw)
    end
  end
end

local waterfall_color_cycle = {
  -- original colors : dark_blue, indigo, blue, white
  {colors.dark_blue, colors.blue,      colors.blue,      colors.white},
  {colors.white,     colors.dark_blue, colors.blue,      colors.blue},
  {colors.blue,      colors.white,     colors.dark_blue, colors.blue},
  {colors.blue,      colors.blue,      colors.white,     colors.dark_blue},
}

function base_stage_state:draw_waterfall(waterfall_global_location_i, top_tile_to_draw, bottom_tile_to_draw)
  -- waterfall sprite contains black
  palt(colors.black, false)

  local period = 0.5
  local ratio = (t() % period) / period
  local step_count = #waterfall_color_cycle
  local step = min(flr(ratio * step_count) + 1, step_count)
  local new_colors = waterfall_color_cycle[step]
  pal(colors.dark_blue, new_colors[1])
  pal(colors.indigo, new_colors[2])
  pal(colors.blue, new_colors[3])
  pal(colors.white, new_colors[4])

  for j = top_tile_to_draw, bottom_tile_to_draw do
    spr(stage_data.waterfall_sprite_id, tile_size * waterfall_global_location_i, tile_size * j)
  end

  pal()
end

-- render the stage environment (tiles)
function base_stage_state:render_environment_midground()
  -- possible optimize: don't draw the whole stage offset by camera,
  --  instead just draw the portion of the level of interest
  --  (and either keep camera offset or offset manually and subtract from camera offset)
  -- that said, I didn't notice a performance drop by drawing the full tilemap
  --  so I guess map is already optimized to only draw what's on camera
  set_unique_transparency(colors.pink)

  -- only draw midground tiles
  --  note that we are drawing loop entrance tiles even though they will be  (they'll be drawn on foreground later)
  self:set_camera_with_region_origin()
  map(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.midground)
end

function base_stage_state:render_environment_foreground()
  set_unique_transparency(colors.pink)

  -- draw tiles always on foreground first
  self:set_camera_with_region_origin()
  map(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.foreground)


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

--#endif

end

return base_stage_state

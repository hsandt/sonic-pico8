local gamestate = require("engine/application/gamestate")

local stage_common_data = require("data/stage_common_data")
local camera_class = require("ingame/camera")
local player_char = require("ingame/playercharacter")
local visual = require("resources/visual_common")

-- abstract base class for stage_state, stage_intro_state and stage_clear_state
-- it contains functionality common to all three cartridges showing stage content,
--  such as rendering the environment
local base_stage_state = derived_class(gamestate)

function base_stage_state:init()
  -- create camera, but wait for player character to spawn before assigning it a target
  -- see on_enter for how we warp it to a good place first
  self.camera = camera_class()

  -- CARTRIDGE NOTE: palm trees are used in stage_intro and ingame only.
--#ifn stage_clear
  -- palm trees: list of global locations of palm tree leaves core sprites detected
  -- used to draw the palm tree extension sprites on foreground
  self.palm_tree_leaves_core_global_locations = {}
--#endif

-- don't initialize loaded region coords (we don't know in which region player character will spawn),
--  each child class on_enter will set them in on_enter
-- self.loaded_map_region_coords = nil
end


-- extended map system: to allow game to display more than the standard 128x32 PICO-8 map
--  (as we need shared data for extra sprites and it wouldn't work for horizontal extension),
--  we split an extended map into multiple cartridge __map__ data (called regions) and
--  reload them at runtime
-- when player is near the boundary between two regions, camera is overlapping them but
--  we don't want to see empty areas in the non-loaded region, so we need an intermediate reload
--  that picks half of each region
-- when player is near the cross intersection of 4 regions, camera is overlapping 4 of them
--  so we need an intermediate reload that picks a quarter of each region (called overlapping region)
-- for instance, with an extended map compounded of a grid of 2x2 = 4 maps, we'd have
--  4 full reloads, 4 2-half reloads, 1 4-quarter reloads for a total of 9 possible reloads

-- return map filename for current stage and given region coordinates (u: int, v: int)
--  do not try this with transitional regions, instead we'll patch them from individual regions
function base_stage_state:get_map_region_filename(u, v)
  return "data_stage"..self.curr_stage_id.."_"..u..v..".p8"
end


-- global <-> region location and position -> region converters

-- this one is used by #stage_clear
function base_stage_state:region_to_global_location(region_loc)
  return region_loc + self:get_region_topleft_location()
end


--#ifn stage_clear

function base_stage_state:global_to_region_location(global_loc)
  return global_loc - self:get_region_topleft_location()
end

function base_stage_state:get_region_grid_dimensions()
  -- compute number of regions per row/column (ceil in case the last region does not cover full PICO-8 map)
  local region_count_per_row = ceil(self.curr_stage_data.tile_width / map_region_tile_width)
  local region_count_per_column = ceil(self.curr_stage_data.tile_height / map_region_tile_height)
  return region_count_per_row, region_count_per_column
end

-- return the map region coordinates corresponding to a position
-- if the position is close to a map region boundary (typically close enough so camera
--  may show empty tiles if the neighbor region is not loaded),
--  return coordinates for a transitional region (ending in .5, half-way between the two regions,
--  on x, y, or both is near the cross boundary of 4 regions)
function base_stage_state:get_map_region_coords(position)
  -- get region where the position is located, without minding being near boundaries at first
  local u = flr(position.x / map_region_width)
  local v = flr(position.y / map_region_height)

  -- check if we are near a boundary, ie modulo map_region_width/height is either
  --  < margin or > map_region_width/height - margin

  local dx = position.x % map_region_width
  if dx < stage_common_data.transition_margin then
    -- position is close to left border, transition with left region
    -- (don't check that we are not on the left edge of the extended map anymore;
    -- let child override implementation decide if it wants to clamp or loop)
    u = u - 0.5
  elseif dx > map_region_width - stage_common_data.transition_margin then
    -- position is close to right border, transition with right region
    -- (don't check that we are not on the right edge of the extended map anymore)
    u = u + 0.5
  end

  local dy = position.y % map_region_height
  if dy < stage_common_data.transition_margin then
    -- position is close to top border, transition with region above
    -- (don't check that we are not on the top edge of the extended map anymore)
    v = v - 0.5
  elseif dy > map_region_height - stage_common_data.transition_margin then
    -- position is close to bottom border, transition with region below
    -- (don't check that we are not on the bottom edge of the extended map anymore)
    v = v + 0.5
  end

  -- no clamping anymore, let stage intro / state decide if they want to clamp or loop
  return vector(u, v)
end


-- region reload methods

-- reload horizontal half (left or right) of map in filename
--  to opposite half (right or left, indicated by dest_hdir) in current map memory
function base_stage_state:reload_horizontal_half_of_map_region(dest_hdir, filename)
  -- unfortunately, reload doesn't allow us to copy rectangular portions of any width
  --  into memory, only contiguous memory in the linear sense (read row by row)
  -- in order to copy the horizontal half of a tilemap (64x32 tiles), we need to copy
  --  32 lines of 64 tiles, one by one

  -- depending on whether we copy from their left half to our right half, or reversely,
  --  we set the source and destination addresses differently
  -- a line contains 128 = 0x80 tiles so:
  --  1. current map memory always starts at 0x2000, line offset j adds j * 0x80
  --  2. general memory always starts at 0x4300, line offset j adds j * 0x80
  --  3. to start on the right half of a line, add 64 = 0x40 tiles
  local dest_addr0 = 0x2000
  local temp_source_addr0 = 0x4300
  if dest_hdir == horizontal_dirs.right then
    dest_addr0 = dest_addr0 + 0x40
  else
    temp_source_addr0 = temp_source_addr0 + 0x40
  end

  -- reloading from an external file 32 times is too slow, so we store parts of
  --  the external tilemap in general memory, then copy half-lines from it one by one
  --  with local memory copy operations only
  -- we used to copy the full tilemap, but to avoid using too much of general memory
  --  as temporary memory for one-time operations, we prefer splitting the load of 0x1000 bytes
  --  in 2: first copy the upper part, second copy the lower part into the same location,
  --  0x800 bytes each (so it uses as much temp memory as reload_quarter_of_map_region)
  -- with fast reload, reload is relatively fast and therefore 2 reloads at runtime are OK,
  --  there is only a slight CPU increment but this will make sense to optimize (e.g. slicing the op
  --  over 2 frames) when we reached 60 FPS
  --  (but we couldn't do 32 reloads, as even with fast reload, a half-second freeze would be perceived)
  -- for now we just put everything at the start of general memory 0x4300
  reload(0x4300, 0x2000, 0x800, filename)

  -- copy first 16 lines of length 64 = 0x40
  for j = 0, 15 do
    memcpy(dest_addr0 + j * 0x80, temp_source_addr0 + j * 0x80, 0x40)
  end

  -- same as before, but add 0x800 to source addresses to access the lower part of the map
  reload(0x4300, 0x2800, 0x800, filename)

  -- copy last 16 lines of length 64 = 0x40
  -- note that we reuse the same temporary address, so make sure to restart index at 0
  --  just for the temporary address offset
  for j = 16, 31 do
    memcpy(dest_addr0 + j * 0x80, temp_source_addr0 + (j-16) * 0x80, 0x40)
  end
end

-- reload vertical half (upper or lower) of map in filename
--  to opposite half (lower or upper, indicated by dest_hdir) in current map memory
function base_stage_state:reload_vertical_half_of_map_region(dest_vdir, filename)
  -- copying vertical half is much easier than horizontal half because the lines are complete
  -- so we just pick the topleft of that half and copy a contiguous sequence of 128*16 = 0x800
  --  (the easiest is to remember that full map size is 0x1000 so take half of it)
  --  into current map memory
  -- addresses are obtained this way:
  --  1. current map memory topleft is 0x2000
  --  2. loaded map memory topleft is 0x2000
  --  3. to start on the bottom half of a map, add 0x800 tiles
  local dest_addr = 0x2000
  local source_addr = 0x2000
  if dest_vdir == vertical_dirs.down then
    dest_addr = dest_addr + 0x800
  else
    source_addr = source_addr + 0x800
  end

  reload(dest_addr, source_addr, 0x800, filename)
end

-- reload quarter of map in filename
--  to opposite quarter (left <-> right and lower <-> upper, destination indicated by dest_hdir and dest_vdir)
--  in current map memory
function base_stage_state:reload_quarter_of_map_region(dest_hdir, dest_vdir, filename)
  -- copying quarter combines logic from horizontal half and vertical half reload:
  -- as with horizontal half, we must copy line by line and we may start on the bottom side, offset by 0x800,
  --  and to be faster, we copy map data into general memory (but only half of it)
  -- as with vertical half, lines have a length of 64 = 0x40 and may start on the right side with an offset of 0x40
  --  in addition, we only need to copy 16 lines

  -- addresses are obtained this way:
  --  1. current map memory topleft is 0x2000
  --  2. general memory topleft is 0x4300
  --  3. to start on the bottom half of a map, add 0x800
  --  3. to start on the right half of a map, add 0x40
  --  4. line offset j adds j * 0x80

  -- finally, as a small optimization, we only copy the vertical half of interest
  --  from the map file to general memory (but always at its top)
  -- this means we need to compute the 0x800 offset when copying a lower
  --  quarter from the *original* map data to temp memory, but we won't need to re-add
  --  that offset again when copying from the temp memory to current map memory

  local dest_addr0 = 0x2000
  local source_addr0 = 0x2000
  local temp_source_addr0 = 0x4300

  if dest_vdir == vertical_dirs.down then
    dest_addr0 = dest_addr0 + 0x800
  else
    -- here is the lower quarter offset for original map only
    source_addr0 = source_addr0 + 0x800
  end

  if dest_hdir == horizontal_dirs.right then
    dest_addr0 = dest_addr0 + 0x40
  else
    -- for horizontal offset, we must add it to temp memory address though
    temp_source_addr0 = temp_source_addr0 + 0x40
  end

  -- now we only need to copy half of the tilemap (0x800) for the vertical half of interest
  reload(0x4300, source_addr0, 0x800, filename)

  -- copy 16 lines of length 64 = 0x40
  for j = 0, 15 do
    memcpy(dest_addr0 + j * 0x80, temp_source_addr0 + j * 0x80, 0x40)
  end
end

function base_stage_state:reload_map_region(new_map_region_coords)
  -- distinguish solo regions, which are literally loaded from a single region data file,
  --  and overlapping regions, which are patched from 2 or 4 region data files
  -- to simplify, we do not reuse current map memory and instead
  --  completely reload map data from files, which should still be fast enough
  --  (we have to load some data for unloaded parts anyway)

  -- when using fractions, use the top-left side as a reference,
  --  then add 1 if you need transition with bottom-right neighbor
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
  elseif new_map_region_coords.x % 1 ~= 0 and new_map_region_coords.y % 1 == 0 then
    -- fractional x => horizontally overlapping region (2 patches)
    log("reload map region: "..new_map_region_coords.." (X overlap)", "reload")

    -- copy right part of left map region to left part of map memory
    self:reload_horizontal_half_of_map_region(horizontal_dirs.left, self:get_map_region_filename(u_left, v_upper))
    -- copy left part of right map region to right part of map memory
    self:reload_horizontal_half_of_map_region(horizontal_dirs.right, self:get_map_region_filename(u_left + 1, v_upper))
  else
    -- fractional x & y => cross overlapping region (4 patches)
    log("reload map region: "..new_map_region_coords.." (cross overlap)", "reload")
    -- copy to temp memory, but with 4 files this time

    -- copy bottom-right quarter of top-left map to top-left
    self:reload_quarter_of_map_region(horizontal_dirs.left, vertical_dirs.up, self:get_map_region_filename(u_left, v_upper))
    -- copy top-right quarter of bottom-left map to bottom-left:
    self:reload_quarter_of_map_region(horizontal_dirs.left, vertical_dirs.down, self:get_map_region_filename(u_left, v_upper + 1))
    -- copy bottom-left quarter of top-right map to top-right:
    self:reload_quarter_of_map_region(horizontal_dirs.right, vertical_dirs.up, self:get_map_region_filename(u_left + 1, v_upper))
    -- copy top-left quarter of bottom-right map to bottom-right:
    self:reload_quarter_of_map_region(horizontal_dirs.right, vertical_dirs.down, self:get_map_region_filename(u_left + 1, v_upper + 1))
  end

  self.loaded_map_region_coords = new_map_region_coords
end

-- if player character is approaching another map region, reload full or overlapping region
function base_stage_state:check_reload_map_region()
  -- we consider camera close enough to player character to use either position
  -- in our case we use the camera because:
  -- 1. on stage enter, the player has not spawn yet but we need to set some region just
  --    so when the player spawns and queries the world about initial collision, they
  --    know where to search tile data with correct region origin
  -- 2. if camera moves away from player a bit too much, we are sure never to discover empty tiles
  --    in unloaded areas as the regions would be loaded by tracking camera movement
  local new_map_region_coords = self:get_map_region_coords(self.camera.position)

  if self.loaded_map_region_coords ~= new_map_region_coords then
    -- current map region changed, must reload
    self:reload_map_region(new_map_region_coords)

-- CARTRIDGE NOTE:
-- overlap tiles system is only used for leaves hiding emerald, therefore ingame-only
-- so use the same trick as in render_environment_foreground

--#if busted
  if self.type ~= ':stage' then
    return
  end
--#endif

--#if ingame
    for overlap_tile_info in all(self.overlap_tiles) do
      local global_loc, sprite_id = unpack(overlap_tile_info)
      local region_loc = self:global_to_region_location(global_loc)
      -- OPTIMIZE CHARS: region coords range check is to be cleaner,
      --  but PICO-8 can handle an mset outside the 128x32 tiles, just do nothing
      --  So you can remove this check if it really costs too many characters
      if region_loc.i >= 0 and region_loc.i < map_region_tile_width and
          region_loc.j >= 0 and region_loc.j < map_region_tile_height then
        mset(region_loc.i, region_loc.j, sprite_id)
      end
    end
--#endif
  end
end


-- spawn

-- spawn the player character at the stage spawn location
function base_stage_state:spawn_player_char()
  -- note we switched from center to topleft position because it gave better initial positions
  --  (with ground bumps, center was higher in the air or too deep inside ground, while topleft
  --  was just 1px from the surface, allowing immediate escape from ground)
  local spawn_position = self.curr_stage_data.spawn_location:to_topleft_position()
  self.player_char = player_char()
  self.player_char:spawn_at(spawn_position)
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
  swap_colors({colors.dark_blue, colors.indigo, colors.blue, colors.white}, new_colors)
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

  -- CARTRIDGE NOTE: stage_intro only scans and spawns palm trees,
  -- stage clear only scans and spawns goal plate, which is not rendered here.
  -- stage_clear will error on nil self.curr_stage_data anyway, so just skip the whole operation
  --  if stage clear.
  -- Headless itests will use #busted + state type check, while PICO-8 will rely on symbols.
  -- We used to test for self.curr_stage_data being not nil directly to pass utests,
  --  then removed it as we removed utests on base methods, then revived the #busted check
  --  for headless itests with render but we prefer checking state type now, as it really matches
  --  the symbols check below.

--#if busted
  if self.type == ':stage_clear' then
    return
  end
--#endif

--#ifn stage_clear
  self:set_camera_with_origin()

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

--#if busted
  if self.type ~= ':stage' then
    return
  end
--#endif

--#if ingame

  -- draw loop entrances on the foreground (it was already drawn on the midground, so we redraw on top of it;
  --  it's ultimately more performant to draw twice than to cherry-pick, in case loop entrance tiles
  --  are reused in loop exit or other possibly disabled layers so we cannot just tag them all foreground)
  local region_topleft_loc = self:get_region_topleft_location()

  for area in all(self.curr_stage_data.loop_entrance_areas) do
    -- draw map subset just for the loop entrance
    -- if this is out-of-screen, map will know it should draw nothing so this is very performant already
    map(area.left - region_topleft_loc.i, area.top - region_topleft_loc.j,
        tile_size * area.left, tile_size * area.top,
        area.right - area.left + 1, area.bottom - area.top + 1,
        sprite_masks.midground)
  end

--(ingame)
--#endif

--(!itest)
--#endif
end

return base_stage_state

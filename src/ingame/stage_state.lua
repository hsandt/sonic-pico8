require("engine/core/coroutine")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local overlay = require("engine/ui/overlay")

local emerald = require("ingame/emerald")
local fx = require("ingame/fx")
local player_char = require("ingame/playercharacter")
local camera_data = require("data/camera_data")
local stage_data = require("data/stage_data")
local audio = require("resources/audio")
local visual = require("resources/visual")

local stage_state = derived_class(gamestate)

-- aliases (they don't need to be short, as they will be minified)
local rectfill_ = rectfill

stage_state.type = ':stage'

-- enums
stage_state.substates = {
  play = "play",     -- playing and moving around
  result = "result"  -- result screen
}

function stage_state:init()
  gamestate.init(self)

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

  -- emeralds: spawned global locations list (to remember not to respawn on region reload) and
  --  actual objects list (we remove objects when picked up)
  -- DEPRECATED: remove spawned_emerald_locations, they shouldn't be needed since we now
  --  spawn all objects on stage start
  -- but replace it with total_emeralds_count since render_hud uses its length
  self.spawned_emerald_locations = {}
  self.emeralds = {}
  -- set of number of emeralds picked, with format: {[number] = true} (no entry if not picked)
  self.picked_emerald_numbers_set = {}
  -- list of emerald pick fxs playing (currently no pooling, just add and delete)
  self.emerald_pick_fxs = {}

  -- palm trees: list of global locations of palm tree leaves core sprites detected
  -- used to draw the palm tree extension sprites on foreground
  self.palm_tree_leaves_core_global_locations = {}

  -- position of the main camera, at the center of the view
  self.camera_pos = vector.zero()
  -- camera forward extension offset (px, signed)
  self.camera_forward_ext_offset = 0

  -- title overlay
  self.title_overlay = overlay(0)

  -- list of background tree delta heights (i.e. above base height),
  --  per row, from farthest (top) to closest
  --  (added for doc, commented out since nil does nothing)
  -- self.tree_dheight_array_list = nil

  -- list of falling leaves heights per row, from farthest (bottom) to closest
  -- self.leaves_dheight_array_list = nil

--#if itest
  -- set to false in itest setup to disable object spawning, which relies on very slow map scan
  self.enable_spawn_objects = true
--#endif
end

function stage_state:on_enter()
  -- don't initialize loaded region coords to force first
  --  (we don't know in which region player character will spawn)
  -- self.loaded_map_region_coords = nil

  -- to avoid scanning object tiles to spawn new objects every time a new region is loaded,
  --  we preload all map regions on stage start and spawn

--#if itest
  -- skip this step during itests unless you specifically need to test objects e.g. picking an emerald,
  --  as it's slow and will add considerable overhead on test start
  if self.enable_spawn_objects then
    self:spawn_objects_in_all_map_regions()
  end
--#endif

--[[#pico8
--#ifn itest
  self:spawn_objects_in_all_map_regions()
--#endif
--#pico8]]

  -- make sure to reload map region where player character will be before spawning player character,
  --  as he will need it for initial collision check
  -- region being based on camera, we need to set the camera position first
  -- anywhere near the spawning location is good (worst case, it's too far and the character
  --  will not detect ground for 1 frame), so let's just set it to where PC will spawn
  self.camera_pos = self.curr_stage_data.spawn_location:to_center_position()
  self:check_reload_map_region()

  self.current_substate = stage_state.substates.play
  self:spawn_player_char()
  self.has_reached_goal = false

  self.app:start_coroutine(self.show_stage_title_async, self)

  -- reload bgm only once, then we can play bgm whenever we want for this stage
  self:reload_bgm()
  -- initial play bgm
  self:play_bgm()

  -- randomize background data on stage start so it's stable during the stage
  self:randomize_background_data()
  -- reload runtime background+HUD sprites by copying spritesheet top from background data
  --  cartridge to the top of the current spritesheet, just to overwrite
  -- we need to copy 3 rows of 16 sprites, 32 = 0x20 bytes per sprite,
  --  so 512 = 0x200 bytes per row,
  --  so 1536 = 0x600 bytes
  reload(0x0, 0x0, 0x600, "data_stage"..self.curr_stage_id.."_runtime.p8")
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
  -- common in case we picked some emerald near the goal line, as we'd still want
  --  to see the animation end
  self:update_fx()

  if self.current_substate == stage_state.substates.play then
    self.player_char:update()
    self:check_reached_goal()
    self:update_camera()
    self:check_reload_map_region()
  else
    -- add stage ending logic here
  end
end

function stage_state:render()
  camera()

  self:render_background()
  self:render_stage_elements()
  self:render_fx()
  self:render_hud()
  self:render_title_overlay()
end


-- queries

-- return true iff global_tile_loc: location is in any of the areas: {location_rect}
function stage_state:is_tile_in_area(global_tile_loc, areas, extra_condition_callback)
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
function stage_state:is_tile_in_loop_entrance(global_tile_loc)
  return self:is_tile_in_area(global_tile_loc, self.curr_stage_data.loop_entrance_areas, function (global_tile_loc, area)
    return global_tile_loc ~= location(area.left, area.top)
  end)
end

-- return true iff tile is located in loop entrance area
--  *except at its top-right which is reversed to non-layered entrance trigger*
function stage_state:is_tile_in_loop_exit(global_tile_loc)
  return self:is_tile_in_area(global_tile_loc, self.curr_stage_data.loop_exit_areas, function (global_tile_loc, area)
    return global_tile_loc ~= location(area.right, area.top)
  end)
end

-- return true iff tile is located at the top-left (trigger location) of any entrance loop
function stage_state:is_tile_loop_entrance_trigger(global_tile_loc)
  for area in all(self.curr_stage_data.loop_entrance_areas) do
    if global_tile_loc == location(area.left, area.top) then
      return true
    end
  end
end

-- return true iff tile is located at the top-right (trigger location) of any exit loop
function stage_state:is_tile_loop_exit_trigger(global_tile_loc)
  for area in all(self.curr_stage_data.loop_exit_areas) do
    if global_tile_loc == location(area.right, area.top) then
      return true
    end
  end
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
-- ! VERY SLOW !
-- it's not perceptible at runtime, but consider stubbing it when unit testing
--  while entering stage state in before_each, or you'll waste around 0.5s each time
-- alternatively, you may bake stage data (esp. emerald positions) in a separate object
--  (that doesn't get reset with stage_state) and reuse it whenever you want
function stage_state:spawn_new_emeralds()
  -- to be precise, visual.sprite_data_t.emerald is the full sprite data of the emerald
  --  (with a span of (2, 1)), but in our case the representative sprite of emeralds used
  --  in the tilemap is at the topleft of the full sprite, hence also the id_loc
  local emerald_repr_sprite_id = visual.sprite_data_t.emerald.id_loc:to_sprite_id()
  for i = 0, map_region_tile_width - 1 do
    for j = 0, map_region_tile_height - 1 do
      -- here we already have region (i, j), so no need to convert for mget
      local tile_sprite_id = mget(i, j)

      -- we do need to convert for spawn global locations tracking though
      local region_loc = location(i, j)
      local global_loc = self:region_to_global_location(region_loc)

      if tile_sprite_id == emerald_repr_sprite_id and not seq_contains(self.spawned_emerald_locations, global_loc) then
        -- no need to mset(i, j, 0) because emerald sprites don't have the midground/foreground flag
        --  and won't be drawn at all
        -- besides, the emerald tiles would come back on next region reload anyway
        --  (hence the importance of tracking emeralds already spawned)

        -- remember where you spawned that emerald, in global location so that we can keep track
        --  of all emeralds across the extended map
        add(self.spawned_emerald_locations, global_loc)

        -- spawn emerald object and store it is sequence member (unlike tiles, objects are not unloaded
        --  when changing region)
        -- since self.emeralds may shrink when we pick emeralds, don't count on its length,
        --  use #self.spawned_emerald_locations instead (no +1 since we've just added an element)

        -- aesthetics note: the number depends on the order in which emeralds are discovered
        -- but regions are always preloaded for object spawning in the same order, so
        -- for given emerald locations, their colors are deterministic
        add(self.emeralds, emerald(#self.spawned_emerald_locations, global_loc))

        log("added emerald #"..#self.emeralds, "emerald")
      end
    end
  end
end

-- scan current map region and generate a palm tree leaves object for every palm tree leaves core tile
function stage_state:spawn_palm_tree_leaves()
  for i = 0, map_region_tile_width - 1 do
    for j = 0, map_region_tile_height - 1 do
      -- we already have region location (i, j), so no need to convert to global for mget
      local tile_sprite_id = mget(i, j)

      if tile_sprite_id == visual.palm_tree_leaves_core_id then
        -- we do need to convert for spawn global locations
        local region_loc = location(i, j)
        local global_loc = self:region_to_global_location(region_loc)

        -- remember where we found palm tree leaves core tile, to draw extension sprites around later
        add(self.palm_tree_leaves_core_global_locations, global_loc)
        log("added palm #"..#self.palm_tree_leaves_core_global_locations, "palm")
      end
    end
  end
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
function stage_state:get_map_region_filename(u, v)
  return "data_stage"..self.curr_stage_id.."_"..u..v..".p8"
end

function stage_state:get_region_grid_dimensions()
  local region_count_per_row = ceil(self.curr_stage_data.tile_width / map_region_tile_width)
  local region_count_per_column = ceil(self.curr_stage_data.tile_height / map_region_tile_height)
  return region_count_per_row, region_count_per_column
end

-- return the map region coordinates corresponding to a position
-- if the position is close to a map region boundary (typically close enough so camera
--  may show empty tiles if the neighbor region is not loaded),
--  return coordinates for a transitional region (ending in .5, half-way between the two regions,
--  on x, y, or both is near the cross boundary of 4 regions)
function stage_state:get_map_region_coords(position)
  --  pre-compute number of regions per row/column (ceil in case the last region does not cover full PICO-8 map)
  local region_count_per_row, region_count_per_column = self:get_region_grid_dimensions()

  -- get region where the position is located, without minding being near boundaries at first
  local u = flr(position.x / map_region_width)
  local v = flr(position.y / map_region_height)

  -- check if we are near a boundary, ie modulo map_region_width/height is either
  --  < margin or > map_region_width/height - margin
  -- note that a margin of 8 tiles should be enough for most speeds and collision checks,
  --  increase if character starts moving out of screen and miss tiles and odd events like tat
  local transition_margin = 8 * tile_size

  local dx = position.x % map_region_width
  if dx < transition_margin then
    -- position is close to left border, transition with left region
    --  unless we are already on the left edge of the extended map
    if u > 0 then
      u = u - 0.5
    end
  elseif dx > map_region_width - transition_margin then
    -- position is close to right border, transition with right region
    --  unless we are already on the right edge of the extended map
    --  (compare to number of regions in a row using stage width and ceil in case the last region is partial)
    if u < region_count_per_row - 1 then
      u = u + 0.5
    end
  end

  local dy = position.y % map_region_height
  if dy < transition_margin then
    -- position is close to top border, transition with region above
    --  unless we are already on the top edge of the extended map
    if v > 0 then
      v = v - 0.5
    end
  elseif dy > map_region_height - transition_margin then
    -- position is close to bottom border, transition with region below
    --  unless we are already on the bottom edge of the extended map
    if v < region_count_per_column - 1 then
      v = v + 0.5
    end
  end

  -- clamp to existing region in case character or camera goes awry for some reason
  u = mid(0, u, region_count_per_row - 1)
  v = mid(0, v, region_count_per_column - 1)

  return vector(u, v)
end

-- reload horizontal half (left or right) of map in filename
--  to opposite half (right or left, indicated by dest_hdir) in current map memory
function stage_state:reload_horizontal_half_of_map_region(dest_hdir, filename)
  -- unfortunately, reload doesn't allow us to copy rectangular portions of any width
  --  into memory, only contiguous memory in the linear sense (read row by row)
  -- in order to copy the horizontal half of a tilemap (64x32 tiles), we need to copy
  --  32 lines of 64 tiles, one by one

  -- reloading from an external file 32 times is too slow, so we store the whole
  --  external tilemap first into general memory 0x4300, to process it later
  reload(0x4300, 0x2000, 0x1000, filename)

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

  -- copy 32 lines of length 64 = 0x40
  for j = 0, 31 do
    memcpy(dest_addr0 + j * 0x80, temp_source_addr0 + j * 0x80, 0x40)
  end
end

-- reload vertical half (upper or lower) of map in filename
--  to opposite half (lower or upper, indicated by dest_hdir) in current map memory
function stage_state:reload_vertical_half_of_map_region(dest_vdir, filename)
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
function stage_state:reload_quarter_of_map_region(dest_hdir, dest_vdir, filename)
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

function stage_state:reload_map_region(new_map_region_coords)
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
function stage_state:check_reload_map_region()
  -- we consider camera close enough to player character to use either position
  -- in our case we use the camera because:
  -- 1. on stage enter, the player has not spawn yet but we need to set some region just
  --    so when the player spawns and queries the world about initial collision, they
  --    know where to search tile data with correct region origin
  -- 2. if camera moves away from player a bit too much, we are sure never to discover empty tiles
  --    in unloaded areas as the regions would be loaded by tracking camera movement
  local new_map_region_coords = self:get_map_region_coords(self.camera_pos)

  if self.loaded_map_region_coords ~= new_map_region_coords then
    -- current map region changed, must reload
    self:reload_map_region(new_map_region_coords)
  end
end

-- preload all map regions one by one, scanning object tiles and spawning corresponding objects
function stage_state:spawn_objects_in_all_map_regions()
  local region_count_per_row, region_count_per_column = self:get_region_grid_dimensions()

  -- only load full regions not transition regions, that will be enough to cover all tiles
  for u = 0, region_count_per_row - 1 do
    for v = 0, region_count_per_column - 1 do
      self:reload_map_region(vector(u, v))
      -- load any *new* items detected in this region
      -- TODO OPTIMIZE: instead of scanning the region once per object type,
      --  we should really scan the region once, and call one callback per object type
      --  to check if there is anything to do on each tile
      self:spawn_new_emeralds()
      self:spawn_palm_tree_leaves()
    end
  end
end


-- visual events

function stage_state:extend_spring(spring_left_loc)
  self.app:start_coroutine(self.extend_spring_async, self, spring_left_loc)
end

function stage_state:extend_spring_async(spring_left_loc)
  -- note that we adapted mset to the new region system
  -- but now it's not a good idea to do that with dynamic objects because of region reload
  -- springs may be reloaded, suddenly reverting to their normal form
  --  and the async coroutine may even continue in the absence of cleanup (although it would just
  --  set them to their normal form again anyway)

  -- set tilemap to show extended spring
  self:mset_global_to_region(spring_left_loc.i, spring_left_loc.j, visual.spring_extended_bottom_left_id)
  self:mset_global_to_region(spring_left_loc.i + 1, spring_left_loc.j, visual.spring_extended_bottom_left_id + 1)
  -- if there is anything above spring, tiles will be overwritten, so make sure
  --  to leave space above it
  self:mset_global_to_region(spring_left_loc.i, spring_left_loc.j - 1, visual.spring_extended_top_left_id)
  self:mset_global_to_region(spring_left_loc.i + 1, spring_left_loc.j - 1, visual.spring_extended_top_left_id + 1)

  -- wait just enough to show extended spring before it goes out of screen
  self.app:yield_delay_s(stage_data.spring_extend_duration)

  -- revert to default spring sprite
  self:mset_global_to_region(spring_left_loc.i, spring_left_loc.j, visual.spring_left_id)
  self:mset_global_to_region(spring_left_loc.i + 1, spring_left_loc.j, visual.spring_left_id + 1)
  -- nothing above spring tiles in normal state, so simply remove extended top tiles
  self:mset_global_to_region(spring_left_loc.i, spring_left_loc.j - 1, 0)
  self:mset_global_to_region(spring_left_loc.i + 1, spring_left_loc.j - 1, 0)
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
  -- add emerald number to picked set
  self.picked_emerald_numbers_set[em.number] = true

  -- add emerald pick FX at emerald position and play it immediately
  local pfx = fx(em.location:to_center_position(), visual.animated_sprite_data_t.emerald_pick_fx)
  add(self.emerald_pick_fxs, pfx)

  -- remove emerald from sequence (use del to make sure
  --  later object indices are decremented)
  del(self.emeralds, em)

  self.app:start_coroutine(self.play_pick_emerald_jingle_async, self)
end

-- pause bgm, play pick emerald jingle and resume bgm
function stage_state:play_pick_emerald_jingle_async()
  -- remember bgm pattern we were at so we can restart from it
  --  it won't exactly resume bgm where we were, but resume from the start of
  --  the current pattern = group of 4 measures
  --  (for bgm at SPD 7, we may backtrack up to 1.866s)
  -- thx to dw817 https://www.lexaloffle.com/bbs/?pid=35493
  local pause_music_pattern = stat(24)

  -- fade out current bgm
  music(-1, 500)

  -- start jingle
  sfx(audio.sfx_ids.pick_emerald)

  -- wait for jingle to end
  -- 1 measure (1 column = 8 notes in SFX editor) at SPD 16 lasts 16/15 = 1.0666s
  --  or to be more exact with frames, 16 * 60/15 = 16*4 = 64 frames
  yield_delay(64)

  -- resume bgm at last pattern (like self:play_bgm(), but with previous pattern)
  music(pause_music_pattern, 0, shl(1, 0) + shl(1, 1) + shl(1, 2))
end

-- return (top_left, bottom_right) positions from an entrance area: location_rect
function stage_state.compute_external_entrance_trigger_corners(entrance_area)
  -- by convention, a loop external exit trigger is always made of 1 column just on the *right*
  --  of the *entrance* area, so consider character in when on the right of the exit area,
  --  not farther than a tile away
  -- remember that area uses location units and must be scaled
  -- we don't bother with pc_data exact sensor distance, etc. but our margin
  --  should somewhat match the character width/height + max amount of move in a frame (~6) to be safe
  --  and prevent character from hitting the layer, then having it disabled too late
  -- make sure to add 1 to right/bottom to get the right/bottom position of the tile
  --  not its topleft
  -- all positions are global, so we don't need any region coordinate conversion
  return vector(tile_size * (entrance_area.right + 1) + 3,  tile_size * entrance_area.top - 8),
         vector(tile_size * (entrance_area.right + 1) + 11, tile_size * (entrance_area.bottom + 1) + 8)
end

-- return (top_left, bottom_right) positions from an exit area: location_rect
function stage_state.compute_external_exit_trigger_corners(exit_area)
  -- by convention, a loop external entrance trigger is always made of 1 column just on the *left*
  --  of the *exit* area, so consider character in when on the left of the entrance area,
  --  not farther than a tile away
  return vector(tile_size * exit_area.left - 11,  tile_size * exit_area.top - 8),
         vector(tile_size * exit_area.left - 3,   tile_size * (exit_area.bottom + 1) + 8)
end

-- if character is entering an external loop trigger that should activate a *new* loop layer,
--  return that layer number
-- else, return nil
function stage_state:check_loop_external_triggers(position, previous_active_layer)
  -- first, if character was already on layer 1 (entrance), we only need to check
  --  for character entering a loop from the back (external exit trigger)
  --  to make sure they don't get stuck there, and vice-versa
  if previous_active_layer == 1 then
    for area in all(self.curr_stage_data.loop_entrance_areas) do
      local ext_entrance_trigger_top_left, ext_entrance_bottom_right = stage_state.compute_external_entrance_trigger_corners(area)
      if ext_entrance_trigger_top_left.x <= position.x and position.x <= ext_entrance_bottom_right.x and
          ext_entrance_trigger_top_left.y <= position.y and position.y <= ext_entrance_bottom_right.y then
        -- external exit trigger detected, switch to exit layer
        return 2
      end
    end
  else
    for area in all(self.curr_stage_data.loop_exit_areas) do
      -- by convention, a loop external entrance trigger is always made of 1 column just on the *left*
      --  of the *exit* area, so consider character in when on the left of the entrance area,
      --  not farther than a tile away
      local ext_exit_trigger_top_left, ext_exit_bottom_right = stage_state.compute_external_exit_trigger_corners(area)
      if ext_exit_trigger_top_left.x <= position.x and position.x <= ext_exit_bottom_right.x and
          ext_exit_trigger_top_left.y <= position.y and position.y <= ext_exit_bottom_right.y then
        -- external entrance trigger detected, switch to entrance layer
        return 1
      end
    end
  end
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
  load('picosonic_titlemenu.p8')
end


-- fx

function stage_state:update_fx()
  local to_delete = {}

  for pfx in all(self.emerald_pick_fxs) do
    pfx:update()

    if not pfx:is_active() then
      add(to_delete, pfx)
    end
  end

  for pfx in all(to_delete) do
    del(self.emerald_pick_fxs, pfx)
  end
end

function stage_state:render_fx()
  for pfx in all(self.emerald_pick_fxs) do
    pfx:render()
  end
end


-- camera

-- update camera position based on player character position
function stage_state:update_camera()
--#if cheat
    if self.player_char.motion_mode == motion_modes.debug then
      -- in debug motion, just track the character (otherwise he may move too fast vertically
      --  and lost the camera)
      self.camera_pos = self.player_char.position
      return
    end
    -- else: self.motion_mode == motion_modes.platformer
--#endif

  -- Window system: most of the time, only move camera when character
  --  is leaving the central window

  -- X tracking

  -- Window system
  -- clamp to required window
  -- Be sure to use the non-extended camera position X by subtracting the old
  --  self.camera_forward_ext_offset
  -- (if you subtract self.camera_forward_ext_offset after its update below,
  --  result will change slightly)
  local windowed_camera_x = mid(self.camera_pos.x - self.camera_forward_ext_offset,
    self.player_char.position.x - camera_data.window_half_width,
    self.player_char.position.x + camera_data.window_half_width)

  -- Forward extension system:
  -- When character is moving fast on X, the camera moves slightly forward
  -- When moving slowly again, the forward offset is gradually reduced back to zero
  -- The rest of the time, camera X is just set to where it should be, using the window system
  -- To make window and extension system independent, and avoid having the window
  --  system clamp immediately the extension when character suddenly changes direction,
  --  we track the extension offset independently.
  -- This means that when checking if character X is inside the window,
  --  we must mentally subtract the offset back to get the non-extended camera position
  --  (or we could store some self.base_camera_pos if we didn't mind the extra member)

  -- running fast enough activate forward extension (if below forward_ext_min_speed_x, ratio will be 0)
  -- unlike original game, we prefer a gradual increase toward the max extension distance to avoid
  --  jittering when running on a bumpy ground that makes character oscillates between 2.9 and 3 (the threshold
  --  at which they activate forward extension)
  --  (the original game uses ground speed not velocity X so it doesn't have this issue)
  local range = camera_data.max_forward_ext_speed_x - camera_data.forward_ext_min_speed_x
  local ratio = mid(0, 1, (abs(self.player_char.velocity.x) - camera_data.forward_ext_min_speed_x) / range)
  -- remember that our offset is signed to allow left/right transitions
  local target_forward_ext_offset = sgn(self.player_char.velocity.x) * ratio * camera_data.forward_ext_max_distance

  -- compute delta to target
  local ext_dx = target_forward_ext_offset - self.camera_forward_ext_offset

  -- clamp abs ext_dx with catchup speed
  ext_dx = sgn(ext_dx) * min(abs(ext_dx), camera_data.forward_ext_catchup_speed_x)

  -- apply delta
  self.camera_forward_ext_offset = self.camera_forward_ext_offset + ext_dx

  -- combine Window and Forward extension
  self.camera_pos.x = windowed_camera_x + self.camera_forward_ext_offset

  -- Y tracking
  -- unlike original game we simply use the current center position even when compact (curled)
  --  instead of the ghost standing center position
  if self.player_char:is_grounded() then
    -- on the ground, stick to y as much as possible
    local target_y = self.player_char.position.y - camera_data.window_center_offset_y
    local dy = target_y - self.camera_pos.y

    -- clamp abs dy with catchup speed (which depends on ground speed)
    local catchup_speed_y = abs(self.player_char.ground_speed) < camera_data.fast_catchup_min_ground_speed and
      camera_data.slow_catchup_speed_y or camera_data.fast_catchup_speed_y
    dy = sgn(dy) * min(abs(dy), catchup_speed_y)

    -- apply move
    self.camera_pos.y = self.camera_pos.y + dy
  else
    -- in the air apply vertical window (stick to top and bottom edges)
    local target_y = mid(self.camera_pos.y,
      self.player_char.position.y - camera_data.window_center_offset_y - camera_data.window_half_height,
      self.player_char.position.y - camera_data.window_center_offset_y + camera_data.window_half_height)
    local dy = target_y - self.camera_pos.y

    -- clamp abs dy with fast catchup speed
    dy = sgn(dy) * min(abs(dy), camera_data.fast_catchup_speed_y)

    -- apply move
    self.camera_pos.y = self.camera_pos.y + dy
  end

  -- clamp on level edges (we are handling the center so need offset by screen_width/height)
  self.camera_pos.x = mid(screen_width / 2, self.camera_pos.x, self.curr_stage_data.tile_width * tile_size - screen_width / 2)
  self.camera_pos.y = mid(screen_height / 2, self.camera_pos.y, self.curr_stage_data.tile_height * tile_size - screen_height / 2)
end

-- set the camera offset to draw stage elements with optional origin (default (0, 0))
-- tilemap should be drawn with region map topleft (in px) as origin
-- characters and items should be drawn with extended map topleft (0, 0) as origin
function stage_state:set_camera_with_origin(origin)
  origin = origin or vector.zero()
  -- the camera position is used to render the stage. it represents the screen center
  -- whereas pico-8 defines a top-left camera position, so we subtract a half screen to center the view
  -- finally subtract the origin to place tiles correctly
  camera(self.camera_pos.x - screen_width / 2 - origin.x, self.camera_pos.y - screen_height / 2 - origin.y)
end

-- set the camera offset to draw stage elements with region origin
--  use this to draw tiles with relative location
function stage_state:set_camera_with_region_origin()
  local region_topleft_loc = self:get_region_topleft_location()
  self:set_camera_with_origin(vector(tile_size * region_topleft_loc.i, tile_size * region_topleft_loc.j))
end


-- ui

function stage_state:show_stage_title_async()
  self.title_overlay:add_label("title", self.curr_stage_data.title, vector(50, 30), colors.white)
  self.app:yield_delay_s(stage_data.show_stage_title_delay)
  self.title_overlay:remove_label("title")
end


-- render
local function draw_full_line(y, c)
  line(0, y, 127, y, c)
end

-- render the stage background
function stage_state:render_background()
  -- always draw full sky background to be safe
  camera()
  rectfill_(0, 0, 127, 127, colors.dark_blue)

  -- horizon line serves as a reference for the background
  --  and moves down slowly when camera moves up
  local horizon_line_dy = 156 - 0.5 * self.camera_pos.y
  camera(0, -horizon_line_dy)

  -- only draw sky and sea if camera is high enough

  -- -31 is based on the offset y 31 of the highest trees
  -- basically, when the top of the trees goes lower than the top of the screen,
  --  you start seeing the sea, so you can start drawing the sea decorations
  --  (note that the sea background itself is always rendered above, so it's quite safe at the border)
  if horizon_line_dy >= -31 then
    self:draw_background_sea()
  end

  -- draw forest bottom first as it contains the big uniform background that may
  --  cover forest top if it was drawn before

  -- 58 was tuned to start showing forest bottom when the lowest forest leaf starts going
  --  higher than the screen bottom
  if horizon_line_dy <= 58 then
    self:draw_background_forest_bottom(horizon_line_dy)
  end

  self:draw_background_forest_top()
end

function stage_state:draw_background_sea()
  -- blue line above horizon line
  draw_full_line(- 1, colors.blue)
  -- white horizon line
  draw_full_line(0, colors.white)
  draw_full_line(1, colors.indigo)

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
  for j = 0, 3 do
    for cloud_dx in all(cloud_dx_list_per_j[j + 1]) do
      self:draw_cloud(cloud_dx, - --[[dy0]] 8.9 - --[[dy_mult]] 14.7 * j,
        dy_list_per_j[j + 1], --[[r0]] 2 + --[[r_mult]] 0.9 * j,
        --[[speed0]] 3 + --[[speed_mult]] 3.5 * j)
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
    local y = 2 + dy
    -- elements farther from camera have slower parallax speed, closest has base parallax speed
    -- clamp in case some y are bigger than 6, but it's better if you can adjust to max of
    --  reflection_dy_list so max is still max and different dy give different speeds
    -- we have speed 0 at the horizon line, so no need to compute min
    -- note that real optics would give some 1 / tan(distance) factor but linear is enough for us
    local parallax_speed = water_parallax_speed_max * min(6, dy) / 6
    local parallax_offset = flr(parallax_speed * self.camera_pos.x)
    self:draw_water_reflections(parallax_offset, 6 * i, y, period_list[i % 5 + 1])
  end
end

function stage_state:draw_background_forest_top()
  -- tree/leaves data

  -- parallax speed of farthest row
  local tree_row_parallax_speed_min = 0.3
  -- parallax speed of closest row
  local tree_row_parallax_speed_max = 0.42
  local tree_row_parallax_speed_range = tree_row_parallax_speed_max - tree_row_parallax_speed_min

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
    local parallax_speed = leaves_row_parallax_speed_min + leaves_row_parallax_speed_range * j  -- actually j / 1 where 1 is max j
    local parallax_offset = flr(parallax_speed * self.camera_pos.x)
    -- first patch of leaves chains from closest trees, so no base height
    --  easier to connect and avoid hiding closest trees
    self:draw_leaves_row(parallax_offset, 31 + --[[leaves_row_dy_mult]] 18 * (1 - j), --[[leaves_base_height]] 21, self.leaves_dheight_array_list[j + 1], j % 2 == 0 and colors.green or colors.dark_green)
  end

  -- tree rows
  for j = 0, 3 do
    -- elements farther from camera have slower parallax speed, closest has base parallax speed
    local parallax_speed = tree_row_parallax_speed_min + tree_row_parallax_speed_range * j / 3
    local parallax_offset = flr(parallax_speed * self.camera_pos.x)
    -- tree_base_height ensures that trees have a bottom part long enough to cover the gap with the trees below
    self:draw_tree_row(parallax_offset, 31 + --[[tree_row_dy_mult]] 8 * j, --[[tree_base_height]] 10,
      self.tree_dheight_array_list[j + 1], j % 2 == 0 and colors.green or colors.dark_green)
  end
end

function stage_state:draw_background_forest_bottom(horizon_line_dy)
  -- under the trees background (since we set camera y to - horizon_line_dy previously,
  --  a rectfill down to 127 - horizon_line_dy will effectively cover the bottom of the screen)
  --  to the screen bottom to cover anything left)

  -- for very dark green we dither between dark green and black using fill pattern:
  --  pure Lua and picotool don't allow 0b notation unlike PICO-8, so pass the hex value directly
  --  grid pattern: 0b0101101001011010 -> 0x5A5A
  -- the Stan shirt effect will cause slight eye distraction around the hole patch edges
  --  as the grid pattern won't be moving while the patches are, but this is less worse
  --  than trying to move the pattern by alternating with 0xA5A5 when parallax_offset % 2 == 1
  -- so we kept it like this
  fillp(0x5a5a)
  rectfill_(0, 50, 127, 127 - horizon_line_dy, colors.dark_green * 0x10 + colors.black)
  fillp()

  -- put value slightly lower than leaves_row_parallax_speed_min (0.36) since holes are supposed to be yet
  --  a bit farther, so slightly slower in parallax
  local parallax_speed = 0.3
  local parallax_offset = flr(parallax_speed * self.camera_pos.x)

  -- place holes at different levels for more variety
  local tile_offset_j_cycle = {0, 1, 3}
  local patch_extra_tile_j_cycle = {0, 0, 2}

  for i = 0, 2 do
    -- like clouds, the extra margin beyond screen_width of 128 and the +16/-16 are because sprites
    --  cannot be cut and looped around the screen, and the full background is wider than the screen too
    --  (contains too many elements to be displayed at once)
    -- 8 * tile_size the width of a hole graphics area (the hole sprite and some programmed transition
    --  tiles around)
    -- for 3 times a hole sequence spanning over 8 tiles on X, we get 3 * 8 * 8 = 192
    -- or if we considering offset from screen width: 128 + 8 * tile_size = 192 so perfectly fits
    -- hole areas are placed at different X and follow parallax X
    -- in our case, there is no "space" between what we consider hole areas
    --  so the offset per i is the same as the area width
    local area_width = 8 * tile_size
    local x0 = (80 - parallax_offset) + area_width * i
    x0 = (x0 + area_width) % 192 - area_width
    local y0 = 102
    -- sprite topleft is placed at (x0, y0), and we program graphics around sprite from that position
    -- dark green patch around the hole
    local extra_tile_j = patch_extra_tile_j_cycle[i + 1]

    rectfill_(x0, y0 - tile_size, x0 + 4 * tile_size, y0 + (5 + extra_tile_j) * tile_size, colors.dark_green)
    -- transitional zigzagging lines between dark green and black to avoid "squary" patch
    self:draw_background_forest_bottom_hole_transition_x(x0 - 1, y0, extra_tile_j, -1)
    self:draw_background_forest_bottom_hole_transition_x(x0 + 4 * tile_size, y0, extra_tile_j, 1)
    self:draw_background_forest_bottom_hole_transition_y(x0, y0 - tile_size - 1, -1)
    self:draw_background_forest_bottom_hole_transition_y(x0, y0 + (5 + extra_tile_j) * tile_size, 1)
    -- actual hole sprite
    local hole_y0 = y0 + tile_offset_j_cycle[i + 1] * tile_size
    visual.sprite_data_t.background_forest_bottom_hole:render(vector(x0, hole_y0))
    -- light shaft
    local light_shaft_start = vector(x0 - 1, hole_y0 + 2 * tile_size + 4)
    line(light_shaft_start.x, light_shaft_start.y, light_shaft_start.x - 15, light_shaft_start.y + 7, colors.dark_green)
    line(light_shaft_start.x + 1, light_shaft_start.y, light_shaft_start.x - 15, light_shaft_start.y + 8, colors.green)
    -- add bits of yellow to make the ray shinier
    for k = 0, 2 do
      pset(light_shaft_start.x - 3 - 6 * k, light_shaft_start.y + 2 + 3 * k, colors.yellow)
    end
    line(light_shaft_start.x, light_shaft_start.y + 1, light_shaft_start.x - 14, light_shaft_start.y + 9, colors.green)
    line(light_shaft_start.x, light_shaft_start.y + 2, light_shaft_start.x - 13, light_shaft_start.y + 9, colors.green)
    line(light_shaft_start.x + 1, light_shaft_start.y + 2, light_shaft_start.x - 11, light_shaft_start.y + 9, colors.green)
    line(light_shaft_start.x, light_shaft_start.y + 3, light_shaft_start.x - 10, light_shaft_start.y + 9, colors.dark_green)
  end
end

-- dir_mult: -1 for transition toward left, +1 for transition toward right
function stage_state:draw_background_forest_bottom_hole_transition_x(x0, y0, extra_tile_j, dir_mult)
  for dy = - tile_size, (5 + extra_tile_j) * tile_size - 1 do
    local y = y0 + dy
    line(x0 + dir_mult * flr(2.5 * (1 + sin(dy/abs(1.7)) * sin(dy/1.41))), y, x0, y, colors.dark_green)
  end
end

-- dir_mult: -1 for transition toward up, +1 for transition toward down
function stage_state:draw_background_forest_bottom_hole_transition_y(x0, y0, dir_mult)
  for dx = 0, 4 * tile_size - 1 do
    local x = x0 + dx
    line(x, y0 + dir_mult * flr(3.7 * (1 + sin(dx/abs(1.65)) * sin(dx/1.45))), x, y0, colors.dark_green)
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

  -- clouds move to the left
  x0 = (x - offset_x + 100) % 300 - 100

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
    local height = base_height + dheight_array[(x + parallax_offset) % size + 1]
    -- draw vertical line from bottom to (variable) top
    line(x, y, x, y - height, color)
  end
end

function stage_state:draw_leaves_row(parallax_offset, y, base_height, dheight_array, color)
  local size = #dheight_array
  for x = 0, 127 do
    local height = base_height + dheight_array[(x + parallax_offset) % size + 1]
    -- draw vertical line from top to (variable) bottom
    line(x, y, x, y + height, color)
  end
end

-- render the stage elements with the main camera:
-- - environment
-- - player character
function stage_state:render_stage_elements()
  self:render_environment_midground()
  self:render_emeralds()
  self:render_player_char()
  self:render_environment_foreground()
--#if debug_trigger
  self:debug_render_trigger()
--#endif
end

-- global <-> region location converters

function stage_state:global_to_region_location(global_loc)
  return global_loc - self:get_region_topleft_location()
end

function stage_state:region_to_global_location(region_loc)
  return region_loc + self:get_region_topleft_location()
end

-- same kind of helper, but for mset
function stage_state:mset_global_to_region(global_loc_i, global_loc_j, sprite_id)
  local region_loc = location(global_loc_i, global_loc_j) - self:get_region_topleft_location()
  mset(region_loc.i, region_loc.j, sprite_id)
end

-- return current region topleft as location (convert uv to ij)
function stage_state:get_region_topleft_location()
  -- note that result should be integer, although due to region coords being sometimes in .5 for transitional areas
  --  they will be considered as fractional numbers by Lua (displayed with '.0' in native Lua)
  return location(map_region_tile_width * self.loaded_map_region_coords.x, map_region_tile_height * self.loaded_map_region_coords.y)
end

--#if deprecated
-- DEPRECATED as very expensive
-- draw all tiles entirely or partially on-screen if they verify condition_callback: function(i, j) -> bool
--  where (i, j) is the location of the tile to possibly draw
function stage_state:draw_onscreen_tiles(condition_callback)
  -- get screen corners
  local screen_topleft = self.camera_pos - vector(screen_width / 2, screen_height / 2)
  local screen_bottomright = self.camera_pos + vector(screen_width / 2, screen_height / 2)

  local region_topleft_loc = self:get_region_topleft_location()

  -- set camera offset to take region topleft into account
  -- this way we don't have to add that offset to spr() on every call
  self:set_camera_with_region_origin()

  -- find which tiles are bordering the screen and define boundary locations
  -- camera is not supposed to show things beyond the map
  --  but just in case, clamp tiles to defined map to avoid avoid shared sprite data
  local screen_left_i = flr(screen_topleft.x / tile_size) - region_topleft_loc.i
  screen_left_i = max(0, screen_left_i)

  local screen_right_i = flr((screen_bottomright.x - 1) / tile_size) - region_topleft_loc.i
  screen_right_i = min(screen_right_i, 127)

  local screen_top_j = flr(screen_topleft.y / tile_size) - region_topleft_loc.j
  screen_top_j = max(0, screen_top_j)

  local screen_bottom_j = flr((screen_bottomright.y - 1) / tile_size) - region_topleft_loc.j
  screen_bottom_j = min(screen_bottom_j, 32)

  -- only draw tiles that are inside or partially on screen,
  --  and on midground layer
  for i = screen_left_i, screen_right_i do
    for j = screen_top_j, screen_bottom_j do
      local sprite_id = mget(i, j)
      -- don't bother checking empty tile 0, otherwise delegate check to condition callback, if any
      if sprite_id ~= 0 and (condition_callback == nil or condition_callback(i, j)) then
        spr(sprite_id, tile_size * i, tile_size * j)
      end
    end
  end
end
--#endif

-- render the stage environment (tiles)
function stage_state:render_environment_midground()
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

  -- goal as vertical line
  rectfill_(self.curr_stage_data.goal_x, 0, self.curr_stage_data.goal_x + 5, 15*8, colors.yellow)
end

function stage_state:render_environment_foreground()
  set_unique_transparency(colors.pink)

  -- draw tiles always on foreground first
  self:set_camera_with_region_origin()
  map(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.foreground)

  local region_topleft_loc = self:get_region_topleft_location()

  -- draw loop entrances on the foreground (it was already drawn on the midground, so we redraw on top of it;
  --  it's ultimately more performant to draw twice than to cherry-pick, in case loop entrance tiles
  --  are reused in loop exit or other possibly disabled layers so we cannot just tag them all foreground)
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
end

-- render the player character at its current position
function stage_state:render_player_char()
  self:set_camera_with_origin()

  self.player_char:render()
end

--#if debug_trigger
-- render the stage triggers
function stage_state:debug_render_trigger()
  self:set_camera_with_origin()


  for area in all(self.curr_stage_data.loop_entrance_areas) do
    local ext_entrance_trigger_top_left, ext_entrance_bottom_right = stage_state.compute_external_entrance_trigger_corners(area)
    rect(ext_entrance_trigger_top_left.x, ext_entrance_trigger_top_left.y, ext_entrance_bottom_right.x, ext_entrance_bottom_right.y, colors.red)
  end

  for area in all(self.curr_stage_data.loop_exit_areas) do
    local ext_exit_trigger_top_left, ext_exit_bottom_right = stage_state.compute_external_exit_trigger_corners(area)
    rect(ext_exit_trigger_top_left.x, ext_exit_trigger_top_left.y, ext_exit_bottom_right.x, ext_exit_bottom_right.y, colors.red)
  end
end
--#endif

-- render the emeralds
function stage_state:render_emeralds()
  self:set_camera_with_origin()

  for em in all(self.emeralds) do
    em:render()
  end
end

-- render the hud:
--  - emeralds obtained
function stage_state:render_hud()
  camera()
  -- draw emeralds obtained at top-left of screen, in order from left to right,
  --  with the right color
  for i = 1, #self.spawned_emerald_locations do
    local draw_position = vector(-4 + 10 * i, 6)
    if self.picked_emerald_numbers_set[i] then
      emerald.draw(i, draw_position)
    else
      -- display silhouette for unpicked emeralds (code is based on emerald.draw)
      emerald.draw(-1, draw_position)
    end
  end
end

-- render the title overlay with a fixed ui camera
function stage_state:render_title_overlay()
  camera()
  self.title_overlay:draw_labels()
end


-- audio

function stage_state:reload_bgm()
  -- reload music sfx and patterns from bgm cartridge memory
  -- we guarantee that:
  -- the bgm will take maximum 40 patterns (out of 64)
  --  => 40 * 4 = 160 = 0xa0 bytes
  -- the music sfx will take maximum 50 entries (out of 64)
  --  => 50 * 68 = 3400 = 0xd48 bytes
  -- the bgm should start at pattern 0, and bgm sfx at index 0 on both source and
  --  current cartridge, so use copy memory from the start of each section

  -- copy music patterns
  reload(0x3100, 0x3100, 0xa0, "data_bgm"..self.curr_stage_id..".p8")
  -- copy music sfx
  reload(0x3200, 0x3200, 0xd48, "data_bgm"..self.curr_stage_id..".p8")
end

function stage_state:play_bgm()
  -- only 4 channels at a time in PICO-8
  -- Angel Island BGM currently uses only 3 channels so t's pretty safe
  --  as there is always a channel left for SFX, but in case we add a 4th one
  --  (or we try to play 2 SFX at once), protect the 3 channels by passing priority mask
  music(self.curr_stage_data.bgm_id, 0, shl(1, 0) + shl(1, 1) + shl(1, 2))
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

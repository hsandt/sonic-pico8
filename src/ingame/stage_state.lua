local volume = require("engine/audio/volume")

local base_stage_state = require("ingame/base_stage_state")
local emerald = require("ingame/emerald")
local emerald_fx = require("ingame/emerald_fx")
local goal_plate = require("ingame/goal_plate")
local player_char = require("ingame/playercharacter")
local spring = require("ingame/spring")
local stage_data = require("data/stage_data")
local audio = require("resources/audio")
local visual = require("resources/visual_common")  -- we should require ingameadd-on in main
local visual_stage = require("resources/visual_stage")

local stage_state = derived_class(base_stage_state)

stage_state.type = ':stage'

function stage_state:init()
  base_stage_state.init(self)

  -- stage id
  self.curr_stage_id = 1

  -- reference to current stage data (derived from curr_stage_id)
  self.curr_stage_data = stage_data.for_stage[self.curr_stage_id]

  -- player character
  -- self.player_char = nil  -- commented out to spare characters

  -- has the player character already reached the goal once?
  self.has_player_char_reached_goal = false

  -- emeralds: spawned global locations list
  self.spawned_emerald_locations = {}
  -- actual emerald objects list (we remove objects when picked up)
  self.emeralds = {}
  -- set of number of emeralds picked, with format: {[number] = true} (no entry if not picked)
  self.picked_emerald_numbers_set = {}
  -- list of emerald pick fxs playing (currently no pooling, just add and delete)
  self.emerald_pick_fxs = {}

  -- spring objects
  self.springs = {}

--#if itest
  -- set to false in itest setup to disable object spawning, which relies on very slow map scan
  self.enable_spawn_objects = true
--#endif
end

--#if tostring
function stage_state:_tostring()
  return "stage_state("..self.curr_stage_id..")"
end
--#endif

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
    self:restore_picked_emerald_data()
  end
--#endif

-- ! Make sure to duplicate content of block above in #pico8 block below !

--[[#pico8
--#ifn itest
  self:spawn_objects_in_all_map_regions()
  self:restore_picked_emerald_data()
--#endif
--#pico8]]

  -- make sure to reload map region where player character will be before spawning player character,
  --  as he will need it for initial collision check
  -- region being based on camera, we need to set the camera position first
  -- anywhere near the spawning location is good (worst case, it's too far and the character
  --  will not detect ground for 1 frame), so let's just set it to where PC will spawn
  -- this is currently done as part of setup_for_stage, which also stores stage data for later clamping
  self.camera:setup_for_stage(self.curr_stage_data)
  self:check_reload_map_region()

  self:spawn_player_char()
  self.camera.target_pc = self.player_char

  self.has_player_char_reached_goal = false

  -- reload bgm only once, then we can play bgm whenever we want for this stage
  self:reload_bgm()
  -- initial play bgm
  self:play_bgm()

  self:reload_runtime_data()
end

-- reload background, HUD and character sprites from runtime data
-- also store non-rotated and rotated sprites into general memory for swapping later
function stage_state:reload_runtime_data()
  -- reload runtime background+HUD sprites by copying spritesheet top from background data
  --  cartridge to the top of the current spritesheet, just to overwrite
  -- spritesheet starts at 0x0 in memory
  -- we need to copy 3 rows of 16 sprites, 32 = 0x20 bytes per sprite,
  --  so 512 = 0x200 bytes per row,
  --  so 1536 = 0x600 bytes
  -- NOTE: we are *not* reloading sprite flags (could do by copying 0x100 bytes from 0x3000-0x30ff)
  --  which means our builtin spritesheet *must* contain any new flags brought by runtime extra tiles
  --  (located in the 3 top rows of the spritesheet). Those are rare (only one-way platform tiles)
  --  but without the flags, they won't behave properly. This means you must (unintuitively) place flags
  --  on the mask tiles in the built-in spritesheet. To make it easier, you may edit the flags on a cartridge
  --  containing all the sprites of interest, then copy-paste the __gff__ lines into the builtin .p8 cartridge
  -- Later, you can move all mask tiles to another spritesheet to reload
  --  on start instead.
  local runtime_data_path = "data_stage"..self.curr_stage_id.."_runtime"..cartridge_ext
  reload(0x0, 0x0, 0x600, runtime_data_path)

  -- the runtime spritesheet also contains 45-degree rotated sprite variants
  --  for Sonic walk and run cycle, meant to replace the non-rotated equivalents
  --  in the built-in spritesheet
  -- we don't want to reload data files (neither the built-in nor the runtime)
  --  every time Sonic changes 1/8 rotation, so we copy both the non-rotated
  --  and rotated variants now into in general memory, so we can swap them later

  -- 1st argument of memcpy is destination, and is always general memory address
  --  (0x4300) + some offset
  -- first, we need to spare 0x1000 for reload_..._map_region methods
  --  which use the general memory as temporary storage for patching operations
  -- second, we prefer keeping memory compact by copying the sprites one after
  --  the other in general memory, rather than following the spritesheet layout
  --  (even if there is a hole after a rotated sprite because it made sprite
  --  alignment look better, we don't have a similar hole in general memory)
  -- so, we start at 0x5300 and then simply add the length of the previous memcpy
  --  operation to get the next dest address

  -- the non-rotated variants are already in current memory, so just copy them

  -- the walk cycle sprites start at row 8, column 2 (counting from 0)
  -- sprites are stored in memory line by line, 1 cell being 8x8 px, and
  --  8px are represented by 4 bytes, so top-left address is at:
  --  8 * 0x200 + 2 * 0x4 = 0x1008
  -- there are 6 walk sprites of span 2x2, which don't cover the whole row of 16 cells of 8x8
  --  and need to copy 8 * 2 = 16 partial lines over 6 * 2 = 12 cells of 8x8, which makes
  --  12 * 4 = 48 = 0x30 bytes per line
  -- to go to the next line, advance px by px over 16 cells (number of cells in a row)
  --  of 8x8, which makes 16 * 4 = 64 = 0x40 (it's also 0x200 / 8 since 0x200 advances
  --  by 1 full row of sprites, each sprite containing 8 lines)

  -- we don't have to keep the same structure in general memory, as we don't debug it
  --  visually, which means we can just paste partial lines of 0x30 one after the other
  --  for the most compact memory (but represented with line breaks every 0x40 like
  --  the spritesheet, it would look garbage due to the offset of 0x10 every line)
  -- we could also keep the structure aligned by pasting every 0x40, then to fill the holes
  --  (2 sprites of span 2x2 left at the end), we could place 2 run cycle sprites
  --  but we'd still need to place the remaining 2 run cycle sprites 2 rows below,
  --  occupying 2 partial lines, and if we want to use general memory for non-sprite
  --  data later then we don't have the most compact memory as we'd have holes for each
  --  partial line but the last one

  -- the run cycle sprites follow the same logic, but they start at row 10, column 0,
  --  and there are 4 sprites of span 2x2, so their topleft address is at:
  --  10 * 0x200 = 0x1400
  -- and we need 8 * 2 = 16 partial lines over 4 * 2 = 8 cells of 8x8,
  --  so 8 * 4 = 32 = 0x20 bytes per line

  -- to make code shorter, let's copy in parallel the 16 lines for the walk and run sprites
  -- each time, we advance dest address by the same value as copied length, so 0x30 and 0x20
  --  resp.
  for i = 0, 15 do
    -- 6 walk cycle sprites
    memcpy(0x5300 + i * 0x30, 0x1008 + i * 0x40, 0x30)

    -- 4 run cycle sprites
    memcpy(0x5600 + i * 0x20, 0x1400 + i * 0x40, 0x20)
  end

  -- the rotated sprite variants are in the runtime data, so reload them from that cartridge
  -- the dest addresses start just after the last memcpy above, at 0x5800
  -- from here, the same principle applies, but the dest addresses are offset by 0x300
  --  (the src addresses are the same because the runtime spritesheet's rotated sprite variants
  --  are located at the same location as their non-rotated equivalents in the built-in spritesheet)

  for i = 0, 15 do
    -- 6 walk cycle sprites (rotated)
    reload(0x5800 + i * 0x30, 0x1008 + i * 0x40, 0x30, runtime_data_path)

    -- 4 run cycle sprites (rotated)
    reload(0x5b00 + i * 0x20, 0x1400 + i * 0x40, 0x20, runtime_data_path)
  end

  -- we check that we arrive at 0x5d00, and the general memory ends at 0x5dff,
  --  so we just have a little margin!
end

-- never called, we directly load stage_clear cartridge
-- if you want to optimize stage retry by just re-entering stage_state though,
--  you will need on_exit for cleanup (assuming you don't patch PICO-8 for fast load)
--[[
function stage_state:on_exit()
  -- clear all coroutines (we normally let app handle them, but in this context
  -- we know that all coroutines belong to the stage state, so no risk clearing them from here)
  self.app:stop_all_coroutines()

  -- clear object state vars
  self.player_char = nil

  -- reinit camera offset for other states
  camera()

  -- stop audio
  self:stop_bgm()
end
--]]

function stage_state:update()
  self:update_fx()

  -- springs can be updated before or after player character,
  --  updating before will simply make them appear extended 1 extra frame
  for spring_obj in all(self.springs) do
    spring_obj:update()
  end

  self.player_char:update()

  self:check_reached_goal()

  if self.goal_plate then
    self.goal_plate:update()
  end

  self.camera:update()
  self:check_reload_map_region()
end

function stage_state:render()
  visual_stage.render_background(self.camera.position)
  self:render_stage_elements()
  self:render_fx()
  self:render_hud()
end


-- setup

-- spawn the player character at the stage spawn location
function stage_state:spawn_player_char()
  local spawn_position = self.curr_stage_data.spawn_location:to_center_position()
  self.player_char = player_char()
  self.player_char:spawn_at(spawn_position)
end

function stage_state:spawn_emerald_at(global_loc)
  -- no need to mset(i, j, 0) because emerald sprites don't have the midground/foreground flag
  --  and won't be drawn at all
  -- besides, the emerald tiles would come back on next region reload anyway
  --  (hence the importance of tracking emeralds already spawned)

  -- remember where you spawned that emerald, in global location so that we can keep track
  --  of all emeralds across the extended map
  -- note that release only uses the length of this sequence for render_hud
  --  but the actual locations are used for #cheat warp_to_emerald_by
  --  and it's not worth keeping just the count on release and the locations besides on #cheat,
  --  so we just keep the locations (if pooling/deactivating emeralds on pick up instead of
  --  destroying them, we'd have a single list with all the information + active bool)
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

function stage_state:spawn_palm_tree_leaves_at(global_loc)
  -- remember where we found palm tree leaves core tile, to draw extension sprites around later
  add(self.palm_tree_leaves_core_global_locations, global_loc)
  log("added palm #"..#self.palm_tree_leaves_core_global_locations, "palm")
end

function stage_state:spawn_goal_plate_at(global_loc)
  assert(self.goal_plate == nil, "stage_state:spawn_goal_plate_at: goal plate already spawned!")
  self.goal_plate = goal_plate(global_loc)
  log("added goal plate at "..global_loc, "goal")
end

local function generate_spawn_spring_dir_at_callback(direction, global_loc)
  return function (self, global_loc)
    add(self.springs, spring(direction, global_loc))
  log("added spring dir "..direction.." at "..global_loc, "spring")
  end
end

stage_state.spawn_spring_up_at = generate_spawn_spring_dir_at_callback(directions.up)
stage_state.spawn_spring_left_at = generate_spawn_spring_dir_at_callback(directions.left)
stage_state.spawn_spring_right_at = generate_spawn_spring_dir_at_callback(directions.right)

-- register spawn object callbacks by tile id to find them easily in scan_current_region_to_spawn_objects
stage_state.spawn_object_callbacks_by_tile_id = {
  [visual.emerald_repr_sprite_id] = stage_state.spawn_emerald_at,
  [visual.palm_tree_leaves_core_id] = stage_state.spawn_palm_tree_leaves_at,
  [visual.goal_plate_base_id] = stage_state.spawn_goal_plate_at,
  [visual.spring_up_repr_tile_id] = stage_state.spawn_spring_up_at,
  [visual.spring_left_repr_tile_id] = stage_state.spawn_spring_left_at,
  [visual.spring_right_repr_tile_id] = stage_state.spawn_spring_right_at,
}

-- proxy for table above, mostly to ease testing
function stage_state:get_spawn_object_callback(tile_id)
  return stage_state.spawn_object_callbacks_by_tile_id[tile_id]
end

-- iterate over each tile of the current region
--  and apply method callback for each of them (to spawn objects, etc.)
--  the method callback but take self, a global tile location and the sprite id at this location
function stage_state:scan_current_region_to_spawn_objects()
  for i = 0, map_region_tile_width - 1 do
    for j = 0, map_region_tile_height - 1 do
      -- here we already have region (i, j), so no need to convert for mget
      local tile_sprite_id = mget(i, j)

      local spawn_object_callback = self:get_spawn_object_callback(tile_sprite_id)

      if spawn_object_callback then
        -- tile has been recognized as a representative tile for object spawning
        --  apply callback now

        -- we do need to convert location now since spawn methods work in global coordinates
        local region_loc = location(i, j)
        local global_loc = self:region_to_global_location(region_loc)
        spawn_object_callback(self, global_loc, tile_sprite_id)
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
  local new_map_region_coords = self:get_map_region_coords(self.camera.position)

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
      -- load region and scan it for any object to spawn
      self:reload_map_region(vector(u, v))
      self:scan_current_region_to_spawn_objects()
    end
  end
end


-- gameplay events

-- check if position is in emerald pick up area and if so,
--  return emerald. Else, return nil.
function stage_state:check_player_char_in_spring_trigger_area()
  for spring_obj in all(self.springs) do
    if spring_obj.direction == directions.up then
      -- check that character is standing just on spring (replaces spring ground tile check)
      local pivot = spring_obj:get_adjusted_pivot()
      local pc_bottom_center = self.player_char:get_bottom_center()
      if flr(pc_bottom_center.y) == pivot.y and
          -- left/right pixel integer dissymmetry means we have -flr(8.5) and +ceil(8.9)
          pivot.x - 8 <= pc_bottom_center.x and pc_bottom_center.x < pivot.x + 9 then
        return spring_obj
      end
    else
      -- we only support horizontal spring from here
      -- check that character center is located so that its left/right edge
      --  just touched the right/left edge a spring oriented right/left
      -- we detect walls at 3.5, and to maintain left/right symmetry we should use the same trick
      --  as during motion, ceiling so we get an extra pixel on the right;
      --  but in this particular case, get_adjusted_pivot already adds an offset of 6 instead of 5
      --  for springs oriented right (else the spring is drawn 1px inside the wall on the left),
      --  so we can just use 3 and no ceil() on trigger_center.x
      -- note that when falling right in front of the spring, even without velocity X,
      --  Sonic will detect the spring
      local trigger_center = spring_obj:get_adjusted_pivot() + 3 * dir_vectors[spring_obj.direction]
      local pc_center = self.player_char.position
      if flr(pc_center.x) == trigger_center.x and
          -- up/down pixel integer dissymmetry means we have -flr(6.5) and +ceil(6.5)
          trigger_center.y - 6 <= pc_center.y and pc_center.y < trigger_center.y + 7 then
        return spring_obj
      end
    end
  end
end

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
  local pfx = emerald_fx(em.number, em.location:to_center_position())
  add(self.emerald_pick_fxs, pfx)

  -- remove emerald from sequence (use del to make sure
  --  later object indices are decremented)
  del(self.emeralds, em)

  self.app:start_coroutine(self.play_pick_emerald_jingle_async, self)
end

-- pause bgm, play pick emerald jingle and resume bgm
function stage_state:play_pick_emerald_jingle_async()
  -- reduce bgm volume by half (notes have volume from 0 to 4, so decrement all sound volumes by 2)
  --  to make the pick emerald jingle stand out
  -- the music sfx take maximum 50 entries (out of 64), so cover all tracks from 0 to 49
  volume.decrease_volume_for_track_range(0, 49, 2)

  -- start jingle with an SFX since the usic still occupies the 3 channels, at lower volume
  -- this has high priority so we don't use sound.play_low_priority_sfx unlike PC SFX,
  --  and music occupies channels 0-2 so it will automatically pick channel 3
  sfx(audio.sfx_ids.pick_emerald)

  -- TODO: add a flag that protect the jingle as top-priority SFX
  --  or check stat(19) before playing an SFX so no minor SFX covers it

  -- wait for jingle to end
  -- 1 measure (1 column = 8 notes in SFX editor) at SPD 16 lasts 16/15 = 1.0666s
  --  or to be more exact with frames, 16 * 60/15 = 16*4 = 64 frames
  -- however, we want at the same time to start resetting bgm volume to normal (since player
  --  won't hear the step-by-step volume transition too much during the end of the jingle),
  --  so only wait 48 frames for now, then the remaining 16 frames after we incremented bgm
  --  volume once
  yield_delay(48)

  -- unfortunately we cannot reincrement volume as some values were clamped to 0 durng decrease
  --  so we completely reload the bgm sfx, and redecrement them a little from the original volumes,
  --  then reset without decrementing to retrieve the original volume
  self:reload_bgm_tracks()
  volume.decrease_volume_for_track_range(0, 49, 1)

  -- wait the remaining 16 frames, the jingle should have ended just after that
  yield_delay(16)

  self:reload_bgm_tracks()
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
  if not self.has_player_char_reached_goal and self.goal_plate and
--[[#pico8
--#if ultrafast
      -- ultrafast to immediately finish stage and test stage clear routine
      true then
--#endif
--#pico8]]
--#ifn ultrafast
      self.player_char.position.x >= self.goal_plate.global_loc:to_center_position().x then
--#endif
    self.has_player_char_reached_goal = true


    self.app:start_coroutine(stage_state.on_reached_goal_async, self)
  end
end

function stage_state:on_reached_goal_async()
  -- make character move right to exit the screen
  self.player_char:force_move_right()

  -- play goal plate animation and wait for it to end
  self:feedback_reached_goal()
  yield_delay(stage_data.goal_rotating_anim_duration)
  self.goal_plate.anim_spr:play("sonic")

  self:stop_bgm(stage_data.bgm_fade_out_duration)
  self.app:yield_delay_s(stage_data.bgm_fade_out_duration)

  -- take advantage of the dead time to load the stage_clear cartridge,
  --  which is a super-stripped version of ingame that doesn't know about
  --  player character, dynamic camera, stage items (except goal plate), etc.
  --  and only renders the stage clear sequence with the stage environment still visible
  -- we assume the character has exited the screen and camera is properly centered on goal plate
  --  at this point, so the player won't notice a glitch during the transition

  -- just before the load the new cartridge, we just need to store the player progress
  --  in some memory address that is not reset on cartridge loading
  self:store_picked_emerald_data()

  -- finally advance to stage clear sequence on new cartridge
  -- prefer passing basename for compatibility with .p8.png
  load('picosonic_stage_clear')
end

function stage_state:restore_picked_emerald_data()
  -- Retrieve and store picked emeralds set information from memory stored in stage_clear
  --  or system pause menu before warp to start / retry (keep emeralds).
  -- If you come directly from the titlemenu or a retry from zero, this should do nothing.
  -- Similar to stage_clear_state:restore_picked_emerald_data, but we also
  --  remove emerald objects from the stage with a "silent pick"
  --  (so this method must be called after object spawning)
  -- It is stored in 0x5d00, see store_picked_emerald_data below
  local picked_emerald_byte = peek(0x5d00)

  -- consume emerald immediately to avoid sticky emeralds on hard ingame reload (ctrl+R)
  poke(0x5d00, 0)

  -- read bitset low-endian, from highest bit (emerald 8) to lowest bit (emerald 1)
  -- the only reason we iterate from the end is because del() will remove elements
  --  from self.emeralds sequence, rearranging them to fill gaps
  -- by iterating backward, we don't have to worry about their index changing
  for i = 8, 1, -1 do
    if band(picked_emerald_byte, shl(1, i - 1)) ~= 0 then
      -- add emerald number to picked set
      self.picked_emerald_numbers_set[i] = true

      -- remove emerald from sequence (backward iteration ensures correct index)
      del(self.emeralds, self.emeralds[i])
    end
  end
end

function stage_state:store_picked_emerald_data()
  -- General memory is persistent during a single session, so a good fit to store data
  --  across cartridges, although this behavior is undocumented.
  -- However, 0x4300-0x52ff is occupied by runtime regions, and 0x5300-0x5cff
  --  is occupied non-rotated/rotated walk/run sprite variants, so store 1 byte at 0x5d00.
  -- We could also use persistent memory, considering we may save emeralds collected by player
  --  on next run (but for now we don't, so player always starts game from zero)
  --
  -- Convert set of picked emeralds to bitset (1 if emerald was picked, low-endian)
  --  there are 8 emeralds so we need 1 byte
  local picked_emerald_bytes = 0
  for i = 1, 8 do
    if self.picked_emerald_numbers_set[i] then
      -- technically we want bor (|), but + is shorter to write and equivalent in this case
      picked_emerald_bytes = picked_emerald_bytes + shl(1, i - 1)
    end
  end
  poke(0x5d00, picked_emerald_bytes)
end

function stage_state:feedback_reached_goal()
  self.goal_plate.anim_spr:play("rotating")

  -- last emerald is far from goal, so no risk of SFX conflict
  sfx(audio.sfx_ids.goal_reached)
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
  self:set_camera_with_origin()

  for pfx in all(self.emerald_pick_fxs) do
    pfx:render()
  end
end


-- render

-- render the stage elements with the main camera:
-- - environment
-- - player character
function stage_state:render_stage_elements()
  self:render_environment_midground()
  self:render_emeralds()
  self:render_springs()
  self:render_goal_plate()
  self:render_player_char()
  self:render_environment_foreground()
--#if debug_trigger
  self:debug_render_trigger()
--#endif
--#if debug_character
  self.player_char:debug_draw_rays()
--#endif
end

-- same kind of helper as base_stage_state:global_to_region_location and region_to_global_location,
--  but for mset
function stage_state:mset_global_to_region(global_loc_i, global_loc_j, sprite_id)
  local region_loc = location(global_loc_i, global_loc_j) - self:get_region_topleft_location()
  mset(region_loc.i, region_loc.j, sprite_id)
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

function stage_state:render_springs()
  self:set_camera_with_origin()

  for spring_obj in all(self.springs) do
    if self.camera:is_rect_visible(spring_obj:get_render_bounding_corners()) then
      spring_obj:render()
    end
  end
end

-- render the goal plate upper body
function stage_state:render_goal_plate()
  if self.goal_plate then
    self:set_camera_with_origin()
    self.goal_plate:render()
  end
end

-- render the hud:
--  - emeralds obtained
--  - character debug info (#debug_character only)
function stage_state:render_hud()
  -- HUD is drawn directly in screen coordinates
  camera()

  -- draw emeralds obtained at top-left of screen, in order from left to right,
  --  with the right color
  for i = 1, #self.spawned_emerald_locations do
    local draw_position = vector(-4 + 8 * i, 3)
    if self.picked_emerald_numbers_set[i] then
      emerald.draw(i, draw_position)
    else
      -- display silhouette for unpicked emeralds (code is based on emerald.draw)
      emerald.draw(-1, draw_position)
    end
  end

--#if debug_character
  self.player_char:debug_print_info()
--#endif
end


-- audio

function stage_state:reload_bgm()
  -- reload music patterns from bgm cartridge memory
  -- we guarantee that the bgm will take maximum 40 patterns (out of 64)
  --  => 40 * 4 = 160 = 0xa0 bytes
  -- the bgm should start at pattern 0 on both source and
  --  current cartridge, so use copy memory from the start of music section
  reload(0x3100, 0x3100, 0xa0, "data_bgm"..self.curr_stage_id..cartridge_ext)

  -- we also need the music sfx referenced by the patterns
  self:reload_bgm_tracks()
end

function stage_state:reload_bgm_tracks()
  -- reload sfx from bgm cartridge memory
  -- we guarantee that the music sfx will take maximum 50 entries (out of 64),
  --  potentially 0-7 for custom instruments and 8-49 for music tracks
  --  => 50 * 68 = 3400 = 0xd48 bytes
  -- the bgm sfx should start at index 0 on both source and
  --  current cartridge, so use copy memory from the start of sfx section
  reload(0x3200, 0x3200, 0xd48, "data_bgm"..self.curr_stage_id..cartridge_ext)
end

function stage_state:play_bgm()
  -- only 4 channels at a time in PICO-8
  -- Angel Island BGM currently uses only 3 channels so it's pretty safe
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

return stage_state

local volume = require("engine/audio/volume")

local base_stage_state = require("ingame/base_stage_state")
local emerald = require("ingame/emerald")
local emerald_fx = require("ingame/emerald_fx")
local goal_plate = require("ingame/goal_plate")
local spring = require("ingame/spring")
local stage_common_data = require("data/stage_common_data")
local stage_data = require("data/stage_data")
local emerald_common = require("render/emerald_common")
local audio = require("resources/audio")
local memory = require("resources/memory")
local visual = require("resources/visual_common")  -- we should require ingameadd-on in main
local visual_ingame_data = require("resources/visual_ingame_numerical_data")
local visual_stage = require("resources/visual_stage")

local stage_state = derived_class(base_stage_state)

stage_state.type = ':stage'

function stage_state:init()
  base_stage_state.init(self)

  -- stage id
  self.curr_stage_id = 1

  -- reference to current stage data (derived from curr_stage_id)
  self.curr_stage_data = stage_data[self.curr_stage_id]

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

  -- overlap tiles: tiles that are overlapping another tile in the tilemap and cannot be defined directly
  --  in tilemap data, but can be stored in advance and mset on every region reload
  -- they can be midground or foreground, it's the sprite flag that decides how they are rendered
  --  since they are rendered as part of the tilemap
  -- format: {{global tile location, sprite_id}, ...}
  self.overlap_tiles = {}

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

--#if normal_mode
--(attract mode doesn't care about remembering picked emeralds)
  self:restore_picked_emerald_data()
--#endif

--(ifn itest)
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

  -- must be done before spawn_player_char so the player character can access
  --  the initial anim spritesheet in its init > update_sprite_row_and_play_sprite_animation
  self:reload_runtime_data()

  self:spawn_player_char()
  self.camera.target_pc = self.player_char

  self.has_player_char_reached_goal = false

  -- initial play bgm
  self:play_bgm()
end

-- reload background, HUD and character sprites from runtime data
-- also store non-rotated and rotated sprites into general memory for swapping later
function stage_state:reload_runtime_data()
  -- in v3, the builtin contains *only* collision masks so we must reload the *full* spritesheet
  --  for stage ingame, hence reload memory length 0x2000
  -- NOTE: we are *not* reloading sprite flags (could do by copying 0x100 bytes from 0x3000-0x30ff)
  --  which means our builtin spritesheet *must* contain all the sprite flags.
  -- in v3, this is terrible since the built-in data only shows collision masks, but works because we already
  --  defined all the sprite flags during v2
  -- if we start adding/moving tiles around and changing sprite flags, then I'd strongly recommend
  --  setting the flags on the spritesheets actually showing the tiles, and copy the flags from them
  --  with the addresses mentioned above
  -- OR if you really need to spare code characters, copy-paste the __gff__ lines into the builtin .p8 cartridge
  -- manually.
  local runtime_data_path = "data_stage"..self.curr_stage_id.."_ingame.p8"
  reload(0x0, 0x0, 0x2000, runtime_data_path)

  self:reload_sonic_spritesheet()

  -- put in pico8 only to avoid polluting unit test counting reload calls
  --[[#pico8

  --#if debug_collision_mask
    -- exceptionally overwrite the top of the spritesheet with tile collision mask sprites again,
    --  so we can debug them with tile_collision_data:debug_render
    -- the collision masks are located in the built-in data of ingame cartridge (also stage_intro),
    --  so just reload data from the current cartridge (pass no filename)
    -- spritesheet is located at 0x0
    -- there are 3 lines of collision masks, so we need to copy 3 * 0x200 = 0x600 bytes
    -- !! this will mess up runtime sprites like the emerald pick up FX !!
    reload(0x0, 0x0, 0x600)
  --#endif

  --#pico8]]
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

--#if normal_mode
--(attract mode never reaches goal)
  self:check_reached_goal()

  if self.goal_plate then
    self.goal_plate:update()
  end
--#endif

  self.camera:update()
  self:check_reload_map_region()
end

function stage_state:render()
  -- background parallax layers use precise calculation and will sometimes move parallax
  --  during sub-pixel motion, causing visual instability => so floor camera position
  visual_stage.render_background(self.camera:get_floored_position())
  self:render_stage_elements()
  self:render_fx()
--#ifn itest
  self:render_hud()
--(!itest)
--#endif
end


-- base_stage_state override
function stage_state:get_map_region_coords(position)
  local uv = base_stage_state.get_map_region_coords(self, position)
  local region_count_per_row, region_count_per_column = self:get_region_grid_dimensions()

  -- clamp to existing region in case character or camera goes awry for some reason
  uv.x = mid(0, uv.x, region_count_per_row - 1)
  uv.y = mid(0, uv.y, region_count_per_column - 1)

  return uv
end


-- setup (spawn methods to support extended map system in base_stage_state)

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

  -- if emerald is surrounded by hiding leaves (we only check if there's one on the right)
  --  we must draw an extra hiding leaves sprite on top of the emerald
  -- but to make it cheaper, we mset it directly onto the tilemap
  -- except tilemap is reloaded from file on region reload, so we cannot mset now,
  --  and must store that info for later (to mset during every region reload)
  local region_loc = self:global_to_region_location(global_loc)
  local s = mget(region_loc.i, region_loc.j)
  if mget(region_loc.i + 1, region_loc.j) == visual_ingame_data.hiding_leaves_id then
    add(self.overlap_tiles, {global_loc, visual_ingame_data.hiding_leaves_id})
  end

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
  -- emerald sprite id is computed via sprite location so not replaced numerical constants like the rest
  --  (but once we're settled, could be added to visual_ingame_numerical_data.lua for more compact code)
  [visual.emerald_repr_sprite_id] = stage_state.spawn_emerald_at,
  [visual_ingame_data.palm_tree_leaves_core_id] = stage_state.spawn_palm_tree_leaves_at,
  [visual_ingame_data.goal_plate_base_id] = stage_state.spawn_goal_plate_at,
  [visual_ingame_data.spring_up_repr_tile_id] = stage_state.spawn_spring_up_at,
  [visual_ingame_data.spring_left_repr_tile_id] = stage_state.spawn_spring_left_at,
  [visual_ingame_data.spring_right_repr_tile_id] = stage_state.spawn_spring_right_at,
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
    if max_distance < stage_common_data.emerald_pick_radius then
      return em
    end
  end
end

function stage_state:character_pick_emerald(em)
  -- add emerald number to picked set
  self.picked_emerald_numbers_set[em.number] = true

  -- add emerald pick FX at emerald position and play it immediately
  local pfx = emerald_fx(em.number, em:get_center(), visual.animated_sprite_data_t.emerald_pick_fx)
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
  -- the music sfx take maximum 46 entries (out of 64), so cover all tracks from 8 to 53
  volume.decrease_volume_for_track_range(8, 53, 2)

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
  yield_delay_frames(48)

  -- unfortunately we cannot reincrement volume as some values were clamped to 0 during decrease
  --  so we completely reload the bgm sfx, and redecrement them a little from the original volumes,
  --  then reset without decrementing to retrieve the original volume
  self:reload_bgm_tracks()
  volume.decrease_volume_for_track_range(8, 53, 1)

  -- wait the remaining 16 frames, the jingle should have ended just after that
  yield_delay_frames(16)

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

--#if normal_mode
--(attract mode never reaches goal nor remembers picked emeralds)

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
  yield_delay_frames(stage_common_data.goal_rotating_anim_duration)
  self.goal_plate.anim_spr:play("sonic")

  self:stop_bgm(stage_common_data.bgm_fade_out_duration)
  self.app:yield_delay_s(stage_common_data.bgm_fade_out_duration)

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
  -- It is stored in picked_emerald_address (0x5dff), see store_picked_emerald_data below
  local picked_emerald_byte = peek(memory.picked_emerald_address)

  -- consume emerald immediately to avoid sticky emeralds on hard ingame reload (ctrl+R)
  poke(memory.picked_emerald_address, 0)

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
  -- We only need to store 1 byte = 8 bits, 1 bit per emerald, so we just poke one byte.
  -- However, 0x4300-0x4aff is occupied by runtime regions, and 0x4b00-0x56ff
  --  is occupied non-rotated/rotated walk/run sprite variants... but it was annoying to offset
  --  picked emerald byte address every time I added a runtime sprite, so I decided to use the
  --  *last* byte (picked_emerald_address = 0x5dff) so it will always be free (as long as runtime sprites don't occupy all the memory
  --  left). When saving data in persistent memory (so player can continue emerald hunting later),
  --  it won't even be a problem since we will use a very different address in the persistent block.
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
  poke(memory.picked_emerald_address, picked_emerald_bytes)
end

function stage_state:feedback_reached_goal()
  self.goal_plate.anim_spr:play("rotating")

  -- last emerald is far from goal, so no risk of SFX conflict
  sfx(audio.sfx_ids.goal_reached)
end

--(normal_mode)
--#endif

-- fx

function stage_state:update_fx()
  local to_delete = {}

  for pfx in all(self.emerald_pick_fxs) do
    pfx:update()

    if not pfx:is_active() then
      add(to_delete, pfx)
    end
  end

  -- normally we should deactivate pfx and reuse it for pooling,
  --  but deleting them was simpler (fewer characters) and single-time operation
  --- so CPU cost is OK
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
--#if debug_collision_mask
  self.player_char:debug_draw_tile_collision_masks()
--#endif
--#if debug_character
  self.player_char:debug_draw_rays()
--#endif
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
    if self.camera:is_rect_visible(em:get_render_bounding_corners()) then
      em:render()
    end
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

--#ifn itest

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
      emerald_common.draw(i, draw_position)
    else
      -- display silhouette for unpicked emeralds (code is based on emerald_common.draw)
      emerald_common.draw(-1, draw_position)
    end
  end

--#if debug_character
  self.player_char:debug_print_info()
--#endif
end

--(!itest)
--#endif

-- audio

function stage_state:reload_bgm_tracks()
  -- Note: bgm is now integrated in builtin data as we've reached the max cartridge limit of 16
  -- We still kept this method, as besides loading music tracks on stage start (which is not needed
  --  anymore), we were also using it to restore volume during the pick emerald jingle
  --  (see play_pick_emerald_jingle_async), so it's still useful, but now needs a mere
  -- We cannot use memcpy since memory has been modified in-place, so still reload.

  -- !! PICO-8 PATCH vs COMPRESSED CHARS
  -- Normally, we should call reload without filename argument so it gets memory directly from the
  --  current original cartridge file.
  -- But because this method is called during play_pick_emerald_jingle_async which happens
  --  mid-game, and due to a quirk, our fast-reload patch only works consistently with reload()
  --  taking filename argument, we still pass the ingame cartridge filename just to get fast reload
  --  and not interrupt the game flow! (when not passing filename, game may freeze or not on reload
  --  depending on the last cartridge reloaded)
  -- (note that builtin_data_ingame.p8 doesn't exist in distribution, since it has been integrated
  --  inside picosonic_ingame cartridge, so we really load the ingame cartridge)
  -- Ideally, we'd improve the fast reload patch to cover reload from current cartridge file
  --  (and possibly make load fast too), but for now this is the easiest approach,
  --  at the cost of a few extra compressed characters

  -- Reload sfx from builtin data ingame cartridge memory (must be current one)
  -- we guarantee that the music sfx will take maximum 46 entries (out of 64),
  --  skip 0-7 (custom instruments reserved to normal SFX) use 8-53 for music tracks
  -- https://pico-8.fandom.com/wiki/Memory says 1 sfx = 68 bytes, so we must copy:
  --  => 46 * 68 = 3400 = 0xc38 bytes
  -- the bgm sfx should start at index 8 (after custom instruments) on both source and
  --  current cartridge, so use copy memory from 8 * 68 = 544 = +0x220 after start of sfx section,
  --  i.e. 0x3200 + 0x220 = 0x3420
  reload(0x3420, 0x3420, 0xc38, "picosonic_ingame.p8")
end

function stage_state:play_bgm()
  -- only 4 channels at a time in PICO-8
  -- Angel Island BGM currently uses only 3 channels so it's pretty safe
  --  as there is always a channel left for SFX, but in case we add a 4th one
  --  (or we try to play 2 SFX at once), protect the 3 channels by passing priority mask
  music(stage_common_data.bgm_id, 0, shl(1, 0) + shl(1, 1) + shl(1, 2))
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

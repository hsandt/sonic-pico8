local gamestate = require("engine/application/gamestate")
local label = require("engine/ui/label")
local overlay = require("engine/ui/overlay")
local rectangle = require("engine/ui/rectangle")

local stage_clear_data = require("data/stage_clear_data")
local emerald = require("ingame/emerald")
local goal_plate = require("ingame/goal_plate")
local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")
local audio = require("resources/audio")
local ui_animation = require("ui/ui_animation")
local visual = require("resources/visual_common")  -- we should require ingameadd-on in main
local visual_stage = require("resources/visual_stage")

local stage_clear_state = derived_class(gamestate)

stage_clear_state.type = ':stage_clear'

-- sequence of menu items to display, with their target states
stage_clear_state.retry_items = transform({
    {"retry (keep emeralds)", function(app)
      -- load stage cartridge without clearing picked emerald data in general memory
      stage_clear_state.retry_stage()
    end},
    {"retry from zero", function(app)
      stage_clear_state.retry_from_zero()
    end},
    {"back to title", function(app)
      stage_clear_state.back_to_titlemenu()
    end},
  }, unpacking(menu_item))

function stage_clear_state:init()
  -- gamestate.init(self)  -- kept for expliciteness, but does nothing

  -- result (stage clear) overlay
  self.result_overlay = overlay()

  -- emerald variables for result UI animation
  self.picked_emerald_numbers_set = {}
  self.picked_emerald_count = 0
  self.result_show_emerald_cross_base = false
  self.result_emerald_cross_palette_swap_table = {}  -- for emerald cross bright animation
  self.result_show_emerald_set_by_number = {}  -- [number] = nil means don't show it
  self.result_emerald_brightness_levels = {}  -- for emerald bright animation (nil means 0)

  -- self.retry_menu starts nil, only created when it must be shown
end

function stage_clear_state:on_enter()
  -- simplified compared to stage_state
  -- we don't even need to reload runtime spritesheet since the stage_clear builtin spritesheet
  --  now integrates the runtime spritesheet top rows from the start (and later, ingame may do the same,
  --  since ultimately we only need the tile masks in the top rows for initial collision data loading,
  --  and we could quick reload on stage start just for that)
  -- we need the runtime sprites for goal plate and menu cursor in particular

  -- first, restore picked emerald data set in ingame, just before loading this cartridge
  self:restore_picked_emerald_data()

  -- we still need to reload map region hardcoded to where goal is,
  --  and spawn objects just there (basically just spawn the goal plate)
  self:reload_map_region()
  self:scan_current_region_to_spawn_objects()

  self.app:start_coroutine(self.play_stage_clear_sequence_async, self)
end

-- good to know what on_exit should do, but never called since stage_clear cartridge only contains stage_clear state
--  and we directly load other cartridges without ever exiting this state; so strip it
--[[
function stage_clear_state:on_exit()
  -- clear all coroutines (we normally let app handle them, but in this context
  -- we know that all coroutines belong to the stage state, so no risk clearing them from here)
  self.app:stop_all_coroutines()

  -- clear object state vars
  self.result_overlay:clear_drawables()

  -- reinit camera offset for other states
  camera()
end
--]]

function stage_clear_state:update()
  if self.retry_menu then
    self.retry_menu:update()
  end
end

function stage_clear_state:render()
  -- see set_camera_with_origin for value explanation (we must pass camera position)
  visual_stage.render_background(vector(3392, 328))
  self:render_stage_elements()
  self:render_overlay()

  -- draw either picked or missed emeralds
  self:render_emerald_cross()

  if self.retry_menu then
    self.retry_menu:draw(29, 90)
  end
end

function stage_clear_state:spawn_goal_plate_at(global_loc)
  -- remember where we found palm tree leaves core tile, to draw extension sprites around later
  assert(self.goal_plate == nil, "stage_clear_state:spawn_goal_plate_at: goal plate already spawned!")
  self.goal_plate = goal_plate(global_loc)

  -- since at the end of the ingame cartidge, goal plate has flipped to show sonic face,
  --  show it immediately now
  self.goal_plate.anim_spr:play("sonic")
end

-- register spawn object callbacks by tile id to find them easily in scan_current_region_to_spawn_objects
stage_clear_state.spawn_object_callbacks_by_tile_id = {
  [visual.goal_plate_base_id] = stage_clear_state.spawn_goal_plate_at,
}

-- proxy for table above, mostly to ease testing
function stage_clear_state:get_spawn_object_callback(tile_id)
  return stage_clear_state.spawn_object_callbacks_by_tile_id[tile_id]
end

-- iterate over each tile of the current region
--  and apply method callback for each of them (to spawn objects, etc.)
--  the method callback but take self, a global tile location and the sprite id at this location
function stage_clear_state:scan_current_region_to_spawn_objects()
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
        -- hardcoded region 31
        local global_loc = region_loc + location(map_region_tile_width * 3, map_region_tile_height * 1)
        spawn_object_callback(self, global_loc, tile_sprite_id)
      end
    end
  end
end


-- extended map system: see stage_state

-- return map filename for current stage and given region coordinates (u: int, v: int)
--  do not try this with transitional regions, instead we'll patch them from individual regions
function stage_clear_state:get_map_region_filename(u, v)
  -- hardcoded for stage 1
  return "data_stage1_"..u..v..".p8"
end

function stage_clear_state:reload_map_region()
  -- hardcoded for goal region
  reload(0x2000, 0x2000, 0x1000, self:get_map_region_filename(3, 1))
end

function stage_clear_state:play_stage_clear_sequence_async()
  -- show result UI
  self:show_result_async()

  -- stop BGM and play stage clear jingle
  music(audio.jingle_ids.stage_clear)
  yield_delay(stage_clear_data.stage_clear_duration)

  -- play result UI "calculation" (we don't have score so it's just checking
  --  if we have all the emeralds)
  self:assess_result_async()

  -- fade out and show retry screen
  self:zigzag_fade_out_async()
  self:show_retry_screen()
end

function stage_clear_state.retry_stage()
  load('picosonic_ingame.p8')
end

function stage_clear_state.retry_from_zero()
  -- clear picked emeralds data (see stage_state:store_picked_emerald_data) in general memory
  poke(0x4300, 0)
  stage_clear_state.retry_stage()
end

function stage_clear_state.back_to_titlemenu()
  -- remember to clear picked emerald data, so if we start again from titlemenu we'll also restart from zero
  poke(0x4300, 0)
  load('picosonic_titlemenu.p8')
end

function stage_clear_state:restore_picked_emerald_data()
  -- retrieve and store picked emeralds set information from memory stored in ingame before stage clear
  --  cartridge was loaded
  -- similar to stage_state:restore_picked_emerald_data, but we don't remove emerald objects
  --  and cache the picked count for assessment
  local picked_emerald_byte = peek(0x4300)

  -- read bitset low-endian, from lowest bit (emerald 1) to highest bit (emerald 8)
  for i = 1, 8 do
    if band(picked_emerald_byte, shl(1, i - 1)) ~= 0 then
      self.picked_emerald_numbers_set[i] = true
      self.picked_emerald_count = self.picked_emerald_count + 1
    end
  end
end

function stage_clear_state:show_result_async()
  -- "sonic got through": 17 characters, so 17*4 = 68 px wide
  -- so to enter from left, offset by -68 (we even get an extra margin pixel)
  local sonic_label = label("sonic", vector(-68, 14), colors.dark_blue, colors.orange)
  self.result_overlay:add_drawable("sonic", sonic_label)
  -- "got through" is 6 chars after the string start so 24px after , -68+24=-44
  local through_label = label("got through", vector(-44, 14), colors.white, colors.black)
  self.result_overlay:add_drawable("through", through_label)

  -- move text from left to right
  ui_animation.move_drawables_on_coord_async("x", {sonic_label, through_label}, {0, 24}, -68, 30, 20)

  -- enter from screen right so offset is 128
  local result_label = label("angel island", vector(128, 26), colors.white, colors.black)
  self.result_overlay:add_drawable("stage", result_label)

  -- move text from right to left
  ui_animation.move_drawables_on_coord_async("x", {result_label}, {0}, 128, 40, 20)

  -- show emerald cross
  self.result_show_emerald_cross_base = true

  for step = 1, 2 do
    self.result_emerald_cross_palette_swap_table = visual.bright_to_normal_palette_swap_by_original_color_sequence[step]
    yield_delay(10)  -- duration of a step
  end

  -- finish with normal colors
  clear_table(self.result_emerald_cross_palette_swap_table)
end

function stage_clear_state:assess_result_async()
  for num = 1, 8 do
    -- only display and yield wait for picked emeralds
    if self.picked_emerald_numbers_set[num] then
      self.result_show_emerald_set_by_number[num] = true
      for step = 1, 2 do
        -- instead of setting self.result_emerald_palette_swap_table_by_number[num] = visual.bright_to_normal_palette_swap_by_original_color_sequence[step]
        -- after defining bright color for every color, we manually pick the bright-dark mapping of this emerald
        --  since it helps us distinguish nuances (e.g. dark_purple from red emerald is red when brighter, while
        --  dark_purple from pink emerald is pink when brighter... subtle nuance, but allows us to have a smaller table
        --  for bright_to_normal_palette_swap_sequence_by_original_color)
        local light_color, dark_color = unpack(visual.emerald_colors[num])
        -- brightness level is: step 1 => 2, step 2 => 1, step 3 => 0 (or nil)
        self.result_emerald_brightness_levels[num] = 3 - step
        yield_delay(10)  -- duration of a step
      end
    end
    -- clear table will reset brightness level to nil, interpreted as 0
    clear_table(self.result_emerald_brightness_levels)
    yield_delay(10)  -- pause between emeralds
  end

  yield_delay(30)

  self.result_overlay:remove_drawable("sonic")
  self.result_overlay:remove_drawable("through")
  self.result_overlay:remove_drawable("stage")

  yield_delay(30)

  -- create another sonic label (previous one was also local var, so can't access it from here)
  local sonic_label = label("sonic", vector(-88, 14), colors.dark_blue, colors.orange)
  self.result_overlay:add_drawable("sonic", sonic_label)
  local emerald_text

  -- show how many emeralds player got
  -- "sonic got all emeralds" (the longest sentence) has 22 chars so is 22*4 88 px wide
  -- it comes from the left again, so offset negatively on start
  -- "got ..." is 6 chars after the string start so 24px after , -88+24=-64
  -- hardcoded since we don't have access to spawned_emerald_locations anymore
  if self.picked_emerald_count < 8 then
    emerald_text = "got "..self.picked_emerald_count.." emeralds"
  else
    emerald_text = "got all emeralds"
  end

  local emerald_label = label(emerald_text, vector(-64, 14), colors.white, colors.black)
  self.result_overlay:add_drawable("emerald", emerald_label)

  -- move text from left to right and give some time to player to read
  ui_animation.move_drawables_on_coord_async("x", {sonic_label, emerald_label}, {0, 24}, -88, 20, 20)
  self.app:yield_delay_s(stage_clear_data.show_emerald_assessment_duration)
end

function stage_clear_state:zigzag_fade_out_async()
  -- todo

  -- at the end of the zigzag, clear the emerald assessment widgets which are now completely hidden
  self.result_overlay:clear_drawables()

  -- only clear members that draw custom items, except for actual emeralds as we'll draw the missing emeralds
  --  soon anyway
  self.result_show_emerald_cross_base = false

  -- just keep the full black screen rectangle as background for retry screen
  local bg = rectangle(vector(0, 0), 128, 128, colors.black)
  self.result_overlay:add_drawable("bg", bg)

  for num = 1, 8 do
    -- only display missed emeralds
    -- not nil is true, and not true is false, so we are effectively filling the set,
    --  just setting false for picked emeralds instead of the usual nil, but works the same
    self.result_show_emerald_set_by_number[num] = not self.picked_emerald_numbers_set[num]
  end
end

function stage_clear_state:show_retry_screen()
  -- at the end of the zigzag, clear the emerald assessment widgets which are now completely hidden,
  -- but keep the full black screen rectangle as background for retry screen
  local try_again_label = label("try again?", vector(41, 34), colors.white)
  self.result_overlay:add_drawable("try again", try_again_label)

  printh("visual.sprite_data_t.menu_cursor: "..nice_dump(visual.sprite_data_t.menu_cursor))
  self.retry_menu = menu(self.app, alignments.left, 1, colors.white, visual.sprite_data_t.menu_cursor, 7)
  self.retry_menu:show_items(stage_clear_state.retry_items)
end


-- camera

-- hardcoded version of stage_state:set_camera_with_origin
function stage_clear_state:set_camera_with_origin(origin)
  origin = origin or vector.zero()
  -- hardcoded version: we printed the following value during ingame just before loading stage_clear:
  --  self.camera.position.x = 3392
  --  self.camera.position.y = 328
  --  self.camera.position.x - screen_width / 2 = 3328
  --  self.camera.position.y - screen_height / 2 = 264
  -- and reinjected the values below (correspond to camera approx. centered on goal plate)
  camera(3328 - origin.x, 264 - origin.y)
end

-- same as stage_state:set_camera_with_region_origin but short enough to copy
function stage_clear_state:set_camera_with_region_origin()
  local region_topleft_loc = self:get_region_topleft_location()
  self:set_camera_with_origin(vector(tile_size * region_topleft_loc.i, tile_size * region_topleft_loc.j))
end

-- same as stage_state:region_to_global_location but short enough to copy
function stage_clear_state:region_to_global_location(region_loc)
  return region_loc + self:get_region_topleft_location()
end

-- return current region topleft as location (convert uv to ij)
-- hardcoded version of stage_state:get_region_topleft_location
--  for stage_clear: goal is in region (3, 1) for pico island
function stage_clear_state:get_region_topleft_location()
  return location(map_region_tile_width * 3, map_region_tile_height * 1)
end


-- render

-- render the stage elements with the main camera:
-- - environment
-- - player character
function stage_clear_state:render_stage_elements()
  self:render_environment_midground()
  self:render_goal_plate()
  self:render_environment_foreground()
end

-- render the stage environment (tiles)
function stage_clear_state:render_environment_midground()
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

function stage_clear_state:render_environment_foreground()
  set_unique_transparency(colors.pink)

  -- draw tiles always on foreground
  self:set_camera_with_region_origin()
  map(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.foreground)
end

-- render the goal plate upper body (similar to stage_state equivalent, but don't check for goal_plate)
function stage_clear_state:render_goal_plate()
  assert(self.goal_plate)

  self:set_camera_with_origin()
  self.goal_plate:render()
end

-- render the result overlay with a fixed ui camera
function stage_clear_state:render_overlay()
  camera()
  self.result_overlay:draw()
end

-- render the emerald cross base and every picked emeralds
function stage_clear_state:render_emerald_cross()
  camera()

  if self.result_show_emerald_cross_base then
    visual.draw_emerald_cross_base(64, 64, self.result_emerald_cross_palette_swap_table)
  end

  self:draw_emeralds_around_cross(64, 64)
end

-- render the emerald cross base and every picked emeralds
-- (x, y) is at cross center
function stage_clear_state:draw_emeralds_around_cross(x, y)
  -- indexed by emerald number
  -- numbers would be more consistent (0, 11, 20 everywhere)
  --  if pivot was at (4, 3) instead of (4, 4)
  --  but we need to make this work with the stage too
  local emerald_relative_positions = {
    vector(0, -19),
    vector(11, -10),
    vector(20, 1),
    vector(11, 12),
    vector(0, 21),
    vector(-11, 12),
    vector(-20, 1),
    vector(-11, -10)
  }

  -- draw emeralds around the cross, from top, CW
  -- usually we iterate from 1 to #self.spawned_emerald_locations
  -- but here we obviously only defined 8 relative positions,
  --  so just iterate to 8 (but if you happen to only place 7, you'll need to update that)
  for num = 1, 8 do
    -- self.result_show_emerald_set_by_number[num] is only set to true when
    --  we have picked emerald, so no need to check self.picked_emerald_numbers_set again
    if self.result_show_emerald_set_by_number[num] then
      local draw_position = vector(x, y) + emerald_relative_positions[num]
      emerald.draw(num, draw_position, self.result_emerald_brightness_levels[num])
    end
  end
end

return stage_clear_state

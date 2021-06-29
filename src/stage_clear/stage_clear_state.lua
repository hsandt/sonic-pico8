local flow = require("engine/application/flow")
local postprocess = require("engine/render/postprocess")
local label = require("engine/ui/label")
local overlay = require("engine/ui/overlay")
local rectangle = require("engine/ui/rectangle")

local stage_clear_data = require("data/stage_clear_data")
local base_stage_state = require("ingame/base_stage_state")
local emerald = require("ingame/emerald")
local goal_plate = require("ingame/goal_plate")
local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")
local audio = require("resources/audio")
local ui_animation = require("ui/ui_animation")
local visual = require("resources/visual_common")  -- we should require ingameadd-on in main
local visual_stage = require("resources/visual_stage")

local stage_clear_state = derived_class(base_stage_state)

stage_clear_state.type = ':stage_clear'

-- sequence of menu items to display, with their target states
local retry_keep_menu_item = menu_item("retry (keep emeralds)", function(app)
  -- load stage cartridge without clearing picked emerald data in general memory
  app:start_coroutine(stage_clear_state.retry_stage_async)
end)

local retry_zero_menu_item = menu_item("retry from zero", function(app)
  app:start_coroutine(stage_clear_state.retry_from_zero_async)
end)

local back_title_menu_item = menu_item("back to title", function(app)
  app:start_coroutine(stage_clear_state.back_to_titlemenu_async)
end)

-- menu callbacks

function stage_clear_state.retry_stage_async()
  -- zigzag fadeout will also give time to player to hear confirm SFX
  flow.curr_state:zigzag_fade_out_async()
  -- prefer passing basename for compatibility with .p8.png
  load('picosonic_ingame')
end

function stage_clear_state.retry_from_zero_async()
  -- clear picked emeralds data (see stage_state:store_picked_emerald_data) in general memory
  poke(0x5d00, 0)
  stage_clear_state.retry_stage_async()
end

function stage_clear_state.back_to_titlemenu_async()
  -- remember to clear picked emerald data, so if we start again from titlemenu we'll also restart from zero
  poke(0x5d00, 0)

  -- zigzag fadeout will also give time to player to hear confirm SFX
  flow.curr_state:zigzag_fade_out_async()
  -- prefer passing basename for compatibility with .p8.png
  load('picosonic_titlemenu')
end

function stage_clear_state:init()
  base_stage_state.init(self)

  -- stage id
  self.curr_stage_id = 1

  -- phase 0: stage result
  -- phase 1: retry menu
  self.phase = 0

  -- postprocessing for fade out effect
  self.postproc = postprocess()

  -- result (stage clear) overlay
  self.result_overlay = overlay()

  -- emerald variables for result UI animation
  self.picked_emerald_numbers_set = {}
  self.picked_emerald_count = 0
  self.result_show_emerald_set_by_number = {}  -- [number] = nil means don't show it
  self.result_emerald_brightness_levels = {}  -- for emerald bright animation (nil means 0)

  -- self.retry_menu starts nil, only created when menu must be shown
end

function stage_clear_state:on_enter()
  -- simplified compared to stage_state
  -- we don't even need to reload runtime spritesheet since the stage_clear builtin spritesheet
  --  now integrates the runtime spritesheet top rows from the start (as there is no physics during stage clear
  --  so we don't need the collision masks as builtin data)
  -- we need the runtime sprites for goal plate and menu cursor in particular

  -- first, restore picked emerald data set in ingame, just before loading this cartridge
  self:restore_picked_emerald_data()

  -- Hardcoded: in stage_clear the camera doesn't move, so we don't need to call self.camera:setup_for_stage,
  --  pass a player character, etc. (and player char is absent anyway).
  -- Instead we just set the position directly to values observed at the end
  --  of ingame cartridge, just before loading stage_clear. This allows us to use base_stage_state methods
  --  relying on the camera position.
  self.camera:init_position(vector(3392, 328))

  -- Hardcoded: we know that goal is in region (3, 1)
  reload(0x2000, 0x2000, 0x1000, self:get_map_region_filename(3, 1))
  self.loaded_map_region_coords = vector(3, 1)

  -- we still need to reload map region hardcoded to where goal is,
  --  and spawn objects just there (basically just spawn the goal plate)
  self:scan_current_region_to_spawn_objects()

  self.app:start_coroutine(self.play_stage_clear_sequence_async, self)
end


-- play overall stage clear sequence (coroutine)
function stage_clear_state:play_stage_clear_sequence_async()
  -- show result UI
  self:show_result_async()

  -- stop BGM and play stage clear jingle
  music(audio.jingle_ids.stage_clear)
  yield_delay_frames(stage_clear_data.stage_clear_duration)

  -- play result UI "calculation" (we don't have score so it's just checking
  --  if we have all the emeralds)
  self:assess_result_async()

  -- fade out and show retry screen
  self.app:yield_delay_s(stage_clear_data.fadeout_delay_s)
  self:zigzag_fade_out_async()

  -- enter phase 1: retry menu immediately so we can clear screen
  self.phase = 1

  self.app:yield_delay_s(stage_clear_data.delay_after_zigzag_fadeout)

  self:show_retry_screen_async()
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
  if self.phase == 0 then
    -- phase 0: stage result

    -- see set_camera_with_origin for value explanation (we must pass camera position)
    visual_stage.render_background(vector(3392, 328))
    self:render_stage_elements()
  else
    -- phase 1: retry menu
    cls()

    --  for retry menu
    if self.retry_menu then
      self.retry_menu:draw(29, 95)
    end
  end

  -- draw picked/missed emeralds
  self:render_emeralds()

  -- draw overlay on top to hide result widgets
  self:render_overlay()

  self.postproc:apply()
end


-- stage-related methods, simplified versions of stage_state equivalents

function stage_clear_state:spawn_goal_plate_at(global_loc)
  -- remember where we found palm tree leaves core tile, to draw extension sprites around later
  assert(self.goal_plate == nil, "stage_clear_state:spawn_goal_plate_at: goal plate already spawned!")
  self.goal_plate = goal_plate(global_loc)

  -- since at the end of the ingame cartidge, goal plate has flipped to show sonic face,
  --  show it immediately now
  self.goal_plate.anim_spr:play("sonic")
end

-- iterate over each tile of the current region
--  and apply method callback for each of them (to spawn objects, etc.)
--  the method callback but take self, a global tile location and the sprite id at this location
function stage_clear_state:scan_current_region_to_spawn_objects()
  for i = 0, map_region_tile_width - 1 do
    for j = 0, map_region_tile_height - 1 do
      -- here we already have region (i, j), so no need to convert for mget
      local tile_sprite_id = mget(i, j)

      -- there is only one object type we are interested in, the goal plate,
      --  so check it manually instead of using a table of spawn callbacks as in stage_state
      if tile_sprite_id == visual.goal_plate_base_id then
        -- tile has been recognized as a representative tile for object spawning
        --  apply callback now

        -- we do need to convert location now since spawn methods work in global coordinates
        local region_loc = location(i, j)
        -- hardcoded region 31
        local global_loc = region_loc + location(map_region_tile_width * 3, map_region_tile_height * 1)
        self:spawn_goal_plate_at(global_loc)
      end
    end
  end
end


-- camera methods, also simplified versions of stage_stage equivalent

-- same as stage_state:region_to_global_location but short enough to copy
function stage_clear_state:region_to_global_location(region_loc)
  return region_loc + self:get_region_topleft_location()
end


-- actual stage clear sequence functions

function stage_clear_state:restore_picked_emerald_data()
  -- retrieve and store picked emeralds set information from memory stored in ingame before stage clear
  --  cartridge was loaded
  -- similar to stage_state:restore_picked_emerald_data, but we don't remove emerald objects
  --  and cache the picked count for assessment
  local picked_emerald_byte = peek(0x5d00)

  -- read bitset low-endian, from lowest bit (emerald 1) to highest bit (emerald 8)
  for i = 1, 8 do
    if band(picked_emerald_byte, shl(1, i - 1)) ~= 0 then
      self.picked_emerald_numbers_set[i] = true
      self.picked_emerald_count = self.picked_emerald_count + 1
    end
  end
end

function stage_clear_state:show_result_async()
  -- create "sonic" label separately just for different color
  local sonic_label = label("sonic", vector(0, 14), colors.dark_blue, colors.orange)
  self.result_overlay:add_drawable("sonic", sonic_label)
  local through_label = label("got through", vector(0, 14), colors.white, colors.black)
  self.result_overlay:add_drawable("through", through_label)

  -- "sonic got through": 17 characters, so 17*4 = 68 px wide
  -- make text enter from left to right (starts on screen edge, so -68 with even an extra margin pixel after last char)
  -- "got through" is 6 chars after the string start so 24px after "sonic"
  ui_animation.move_drawables_on_coord_async("x", {sonic_label, through_label}, {0, 24}, -68, 30, 20)

  local stage_label = label("pico island", vector(0, 26), colors.white, colors.black)
  self.result_overlay:add_drawable("stage", stage_label)

  -- make text enter screen from right to left (starts on screen edge, so 128)
  ui_animation.move_drawables_on_coord_async("x", {stage_label}, {0}, 128, 42, 20)
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
        yield_delay_frames(9)  -- duration of a step
      end
    end
    -- clear table will reset brightness level to nil, interpreted as 0
    clear_table(self.result_emerald_brightness_levels)
    yield_delay_frames(9)  -- pause between emeralds
  end

  yield_delay_frames(30)

  -- retrieve labels from overlay (as we didn't store references as state members)
  local sonic_label = self.result_overlay.drawables_map["sonic"]
  local through_label = self.result_overlay.drawables_map["through"]
  local stage_label = self.result_overlay.drawables_map["stage"]

  -- make text exit to the left (faster)
  ui_animation.move_drawables_on_coord_async("x", {sonic_label, through_label}, {0, 24}, 30, -68, 10)

  -- make text exit to the right (faster)
  ui_animation.move_drawables_on_coord_async("x", {stage_label}, {0}, 40, 128, 10)

  -- clean up labels outside screen, except "sonic" that we will reuse
  -- "sonic" label is already outside screen so it won't bother us until we use it again
  self.result_overlay:remove_drawable("through")
  self.result_overlay:remove_drawable("stage")

  yield_delay_frames(30)

  local got_all_emeralds = self.picked_emerald_count >= 8

  local emerald_text

  -- show how many emeralds player got
  -- "[number]" is has1 character but "all" has 3 characters, and label doesn't support centered text,
  --  so adjust manually shorter label to be a little more to the right to center it on screen
  local x_offset = 0

  if got_all_emeralds then
    emerald_text = "got all emeralds"
  else
    emerald_text = "got "..self.picked_emerald_count.." emeralds"
    x_offset = 6
  end

  -- don't mind initial x, move_drawables_on_coord_async now sets it before first render
  local emerald_label = label(emerald_text, vector(0, 14), colors.white, colors.black)
  self.result_overlay:add_drawable("emerald", emerald_label)

  -- move text "sonic got X emeralds" (reusing "sonic" label) from left to right and give some time to player to read
  -- "got ..." is 6 chars after the full string start so 24px after "sonic" -> second offset is 24
  -- "sonic got all emeralds" (the longest sentence) has 22 chars so is 22*4 88 px wide
  -- it comes from the left again, so offset negatively on start -> a = -88
  -- apply offset for shorter label to start and end x
  -- animation takes 20 frames
  ui_animation.move_drawables_on_coord_async("x", {sonic_label, emerald_label}, {0, 24}, -88 + x_offset, 20 + x_offset, 20)

  if got_all_emeralds then
    self.app:yield_delay_s(stage_clear_data.got_all_emeralds_sfx_delay_s)
    sfx(audio.sfx_ids.got_all_emeralds)
    self.app:yield_delay_s(stage_clear_data.got_all_emeralds_sfx_duration_s)
  end
end

-- drawable for the right part of the fade-out layer (the body will be filled with a separate rectangle)
-- there is only one, so don't bother creating a struct just for that
local zigzag_drawable = {
  position = vector(0, 0)
}

function zigzag_drawable:draw()
  for j = 0, 127 do
    -- zigzag can be represented by a periodical abs function (length is 0 when line contains 1 px)
    local length = abs((j - 8) % (2 * visual.fadeout_zigzag_width) - visual.fadeout_zigzag_width)
    line(self.position.x, j, self.position.x + length, j, colors.black)
  end
end

function stage_clear_state:zigzag_fade_out_async()
  local fadeout_rect = rectangle(vector(0, 0), 128, 128, colors.black)
  self.result_overlay:add_drawable("fadeout_rect", fadeout_rect)
  self.result_overlay:add_drawable("zigzag", zigzag_drawable)

  -- swipe sfx must be played during swipe animation
  sfx(audio.sfx_ids.menu_swipe)

  -- make rectangle with zigzag edge enter the screen from the left
  -- note that we finish at 128 and not 127 so the zigzag fully goes out of the screen to the right,
  --  and the fadeout_rect fully covers the screen, ready to be used as background
  ui_animation.move_drawables_on_coord_async("x", {fadeout_rect, zigzag_drawable}, {-128, 0}, - visual.fadeout_zigzag_width, 128, stage_clear_data.zigzag_fadeout_duration)

  -- at the end of the zigzag fade-out, clear the emerald assessment widgets which are now completely hidden
  -- also hide the emeralds until we show them again (but it will be the missed ones)
  -- no need to preserve fadeout_rect either because in phase 2, we cls() on render start anyway
  self.result_overlay:clear_drawables()
  clear_table(self.result_show_emerald_set_by_number)
end

function stage_clear_state:show_retry_screen_async()

  local has_got_any_emeralds = false
  local has_missed_any_emeralds = false

  -- display missed emeralds
  for num = 1, 8 do
    -- not nil is true, and not true is false, so we are effectively filling the set,
    --  just setting false for picked emeralds instead of the usual nil, but works the same
    local has_got_this_emerald = self.picked_emerald_numbers_set[num]
    -- remember we show missed emeralds, hence the not
    self.result_show_emerald_set_by_number[num] = not has_got_this_emerald
    has_got_any_emeralds = has_got_any_emeralds or has_got_this_emerald
    has_missed_any_emeralds = has_missed_any_emeralds or not has_got_this_emerald
  end

  -- change text if player has got all emeralds
  local result_label
  if has_missed_any_emeralds then
    result_label = label("try again?", vector(45, 30), colors.white)
  else
    result_label = label("congratulations!", vector(35, 45), colors.white)
  end
  self.result_overlay:add_drawable("result text", result_label)

  self.retry_menu = menu(self.app, alignments.left, 1, colors.white, visual.sprite_data_t.menu_cursor, 7)

  -- prepare menu items
  local retry_menu_items = {}
  if has_got_any_emeralds then
    -- keeping emeralds only makes sense if we got at least one
    add(retry_menu_items, retry_keep_menu_item)
  end
  add(retry_menu_items, retry_zero_menu_item)
  add(retry_menu_items, back_title_menu_item)

  self.retry_menu:show_items(retry_menu_items)

  -- fade in (we start from everything black so skip max darkness 5)
  for i = 4, 0, -1 do
    self.postproc.darkness = i
    yield_delay_frames(4)
  end
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

-- render the goal plate upper body (similar to stage_state equivalent)
function stage_clear_state:render_goal_plate()
  assert(self.goal_plate, "stage_clear_state:render_goal_plate: no goal plate spawned in stage")

  self:set_camera_with_origin()
  self.goal_plate:render()
end

-- render the result overlay with a fixed ui camera
function stage_clear_state:render_overlay()
  camera()
  self.result_overlay:draw()
end

-- render every picked/missed emeralds at fixed screen position
function stage_clear_state:render_emeralds()
  camera()

  self:draw_emeralds(64, 64)
end

-- draw picked/missed emeralds on an invisible circle centered on (x, y)
function stage_clear_state:draw_emeralds(x, y)
  -- draw emeralds around the clock, from top, CW
  -- usually we iterate from 1 to #self.spawned_emerald_locations
  -- but here we obviously only defined 8 relative positions,
  --  so just iterate to 8 (but if you happen to only place 7, you'll need to update that)
  for num = 1, 8 do
    -- self.result_show_emerald_set_by_number[num] is only set to true when
    --  we have missed emerald, so no need to check self.picked_emerald_numbers_set again
    if self.result_show_emerald_set_by_number[num] then
      local radius = visual.missed_emeralds_radius
      local draw_position = vector(x + radius * cos(0.25 - (num - 1) / 8),
        y + radius * sin(0.25 - (num - 1) / 8))
      emerald.draw(num, draw_position, self.result_emerald_brightness_levels[num])
    end
  end
end

return stage_clear_state

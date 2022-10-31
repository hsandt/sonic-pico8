local flow = require("engine/application/flow")
local input = require("engine/input/input")
local postprocess = require("engine/render/postprocess")
local animated_sprite_object = require("engine/render/animated_sprite_object")
local sprite_object = require("engine/render/sprite_object")
local label = require("engine/ui/label")
local overlay = require("engine/ui/overlay")
local rectangle = require("engine/ui/rectangle")

local stage_clear_data = require("data/stage_clear_data")
local base_stage_state = require("ingame/base_stage_state")
local goal_plate = require("ingame/goal_plate")
local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")
local emerald_common = require("render/emerald_common")
local audio = require("resources/audio")
local ui_animation = require("engine/ui/ui_animation")
local memory = require("resources/memory")
local visual = require("resources/visual_common")  -- we should require ingameadd-on in main
local visual_ingame_data = require("resources/visual_ingame_numerical_data")
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
  -- clear picked emeralds data (see stage_state:store_picked_emerald_data) in persistent memory
--#ifn itest
  -- itests do not save (do not call cartdata), so do not call this to avoid error
  --  "dset called before cardata()"
  dset(memory.persistent_picked_emerald_index, 0)
--#endif
  stage_clear_state.retry_stage_async()
end

function stage_clear_state.back_to_titlemenu_async()
  -- now picosonic_app_titlemenu:on_pre_start clears picked emerald data in persistent memory,
  --  so no need to clear it here too

  -- zigzag fadeout will also give time to player to hear confirm SFX
  flow.curr_state:zigzag_fade_out_async()
  -- prefer passing basename for compatibility with .p8.png
  load('picosonic_titlemenu')
end


-- render helpers

-- a wrapper class to draw the same sprite twice, once normally and once flipped X around its pivot
--  use a pivot in .5 if the center vertical axis go through through a pixel (for width = odd number of px)
-- it is a drawable itself
local mirror_wrapper = new_class()

-- sprite_object  sprite_object|animated_sprite_object   sprite object to draw mirrored on X
--                                                       must have fields visible, position, flip_x/flip_y and method draw
function mirror_wrapper:init(spr_object)
  self.spr_object = spr_object
end

function mirror_wrapper:update()
  self.spr_object:update()
end

function mirror_wrapper:draw(spr_object)
  self.spr_object:draw()

  -- as a trick, we temporarily swap flip x before the second draw to draw a mirrored image, then revert it
  local original_flip_x = self.spr_object.flip_x
  self.spr_object.flip_x = not original_flip_x
  self.spr_object:draw()
  self.spr_object.flip_x = original_flip_x
end


-- parameters

local arm_offset_y_from_body = -16

local juggling_mode_strings = {
  "ping-pong",
  " shower",  -- space is just to center a little between the arrows
}

function stage_clear_state:get_current_juggling_mode_string()
  return juggling_mode_strings[self.emerald_juggling_mode + 1]
end


function stage_clear_state:init()
  base_stage_state.init(self)

  -- stage id
  self.curr_stage_id = 1

  -- phase 0: stage result
  -- phase 1: retry menu
  self.phase = 0
  self.is_fading_out_for_retry_screen = false

  -- eggman state
  -- self.eggman_timer = nil
  -- self.emerald_juggling_mode = nil

  -- postprocessing for fade out effect
  self.postproc = postprocess()

  -- result (stage clear) overlay
  self.result_overlay = overlay()

  -- fading overlay, should be displayed on top of the rest
  self.fading_overlay = overlay()

  -- emerald variables for result UI animation
  self.picked_emerald_numbers_set = {}
  self.picked_emerald_count = 0
  self.result_show_emerald_set_by_number = {}  -- [number] = nil means don't show it
  self.result_emerald_brightness_levels = {}  -- for emerald bright animation (nil means 0)

  -- self.retry_menu starts nil, only created when menu must be shown

  -- eggman sprites
  -- we don't have a hierarchical sprite system with child offsets yet, so for now, we just work with
  --  separate static or animated sprites
  self.eggman_legs = mirror_wrapper(animated_sprite_object(visual.animated_sprite_data_t.eggman_leg_left, vector(64, 74)))
  self.eggman_body_initial_y = 65
  self.eggman_body = mirror_wrapper(sprite_object(visual.sprite_data_t.eggman_body_half_left, vector(64, self.eggman_body_initial_y)))

  -- first arm (initially on the left)
  self.eggman_arm = animated_sprite_object(visual.animated_sprite_data_t.eggman_arm_left)

  -- second arm (initially on the right)
  self.eggman_arm2 = animated_sprite_object(visual.animated_sprite_data_t.eggman_arm_left)
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
  self.camera:init_position(vector(3376, 328))

  -- Hardcoded: we know that goal is in region (3, 1)
  reload(0x2000, 0x2000, 0x1000, self:get_map_region_filename(3, 1))
  self.loaded_map_region_coords = vector(3, 1)

  -- we still need to reload map region hardcoded to where goal is,
  --  and spawn objects just there (basically just spawn the goal plate)
  self:scan_current_region_to_spawn_objects()

  self.app:start_coroutine(self.play_stage_clear_sequence_async, self)
end

function stage_clear_state:change_juggling_mode(juggling_mode)
  self.emerald_juggling_mode = juggling_mode

  local body_position_y = self.eggman_body.spr_object.position.y
  self.eggman_arm.position:copy_assign(vector(64 - 9, body_position_y + arm_offset_y_from_body))
  self.eggman_arm.flip_x = false
  self.eggman_arm2.position:copy_assign(vector(64 + 9, body_position_y + arm_offset_y_from_body))
  self.eggman_arm2.flip_x = true

  self.eggman_timer = 0

  if juggling_mode == 0 then
    -- Ping-pong
    -- second arm is always in down position (and switches between left and right regularly)
    self.eggman_arm2:play("down")
    -- legs will play raise_and_lower and update body/arm position on first frame in update
  else
    -- Shower juggling
    -- Start at down position just to make sure to show something and so receiving an emerald looks natural,
    --  we'll play more specific animations later
    self.eggman_arm:play("down")
    self.eggman_arm2:play("down")
    self.eggman_legs.spr_object:play("up")  -- always up in this mode

    -- Adjust body and arm position to up position (1px up)
    local eggman_body_position_ref = self.eggman_body.spr_object.position
    local eggman_arm_position_ref = self.eggman_arm.position
    local eggman_arm2_position_ref = self.eggman_arm2.position

    eggman_body_position_ref.y = self.eggman_body_initial_y - 1
    eggman_arm_position_ref.y = eggman_body_position_ref.y + arm_offset_y_from_body
    eggman_arm2_position_ref.y = eggman_arm_position_ref.y

    -- sequence of last known way index (high way: 0, low way: 1), indexed per emerald index-1
    --  so we can make Eggman hands react when emeralds change directions
    self.last_emerald_way_indices = {0, 0, 0, 0, 0, 0, 0, 0}
  end

  local juggle_mode_value_label = self.result_overlay.drawables_map["juggle mode value"]

  -- label is an observer, but may not be created at the time change_juggling_mode is called for the first time,
  --  so we must check for nil
  if juggle_mode_value_label then
    juggle_mode_value_label.text = self:get_current_juggling_mode_string()
  end
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

  self.app:yield_delay_s(stage_clear_data.fadeout_delay_s)

  self:try_fade_out_and_show_retry_screen_async()
end

function stage_clear_state:try_fade_out_and_show_retry_screen_async()
  if not self.is_fading_out_for_retry_screen then
    self.is_fading_out_for_retry_screen = true

    self:zigzag_fade_out_async()

    -- fade out music if any (only useful if player manually skipped result)
    music(-1, 500)

    -- stop all coroutines before showing retry screen to avoid, in the case of manual skip,
    --  play_stage_clear_sequence_async and its sub-async methods doing further processing in the background
    --  and messing up with the sequence
    -- since we do this after the last async call here, this very coroutine will still finish properly
    -- note that we must start a brand new coroutine below for this to work, else we would stop our own coroutine
    self.app:stop_all_coroutines()

    self.app:start_coroutine(self.transition_to_retry_screen_async, self)
  end
end

function stage_clear_state:transition_to_retry_screen_async()
  -- -- enter phase 1: retry menu immediately so we can clear screen
  self.phase = 1

  if self.picked_emerald_count < 8 then
    -- haven't got all emeralds, so eggman is shown

    -- initialize juggling mode
    -- 0: ping-pong, as in Sonic 1
    -- 1: shower (cycle with high and low way)
    self:change_juggling_mode(0)
  end

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
  self.fading_overlay:clear_drawables()

  -- reinit camera offset for other states
  camera()
end
--]]

function stage_clear_state:update()
  if self.phase == 0 then
    -- check for any input to skip result screen and fade out already to retry menu
    if input:is_just_pressed(button_ids.o) or input:is_just_pressed(button_ids.x) then
      -- start fade out in parallel with existing animations to keep things smooth
      -- but at the end of fade out, we'll stop all coroutines to avoid sequence overlap
      self.app:start_coroutine(self.try_fade_out_and_show_retry_screen_async, self)
    end
  else  -- self.phase == 1
    if self.picked_emerald_count < 8 then
      -- haven't got all emeralds, so eggman is shown

      -- check input to change juggling mode
      -- currently, there are only 2, so left and right do, in fact, the same thing
      if input:is_just_pressed(button_ids.left) then
        self:change_juggling_mode((self.emerald_juggling_mode - 1) % 2)
      elseif input:is_just_pressed(button_ids.right) then
        self:change_juggling_mode((self.emerald_juggling_mode + 1) % 2)
      end

      -- update eggman body parts

      -- we know that legs spr_object is an animated_sprite_object
      local old_legs_step = self.eggman_legs.spr_object.current_step
      self.eggman_legs:update()
      local new_legs_step = self.eggman_legs.spr_object.current_step

      -- sync body vertical offset with legs
      -- remember that our struct are nothing more than elevated class with copy methods,
      --  so they are still passed by reference
      local eggman_body_position_ref = self.eggman_body.spr_object.position
      local eggman_arm_position_ref = self.eggman_arm.position
      local eggman_arm2_position_ref = self.eggman_arm2.position
      if old_legs_step == 1 and new_legs_step == 2 then
        -- Eggman just flexed his legs, move body and arm down
        eggman_body_position_ref.y = self.eggman_body_initial_y
        eggman_arm_position_ref.y = eggman_body_position_ref.y + arm_offset_y_from_body
        eggman_arm2_position_ref.y = eggman_arm_position_ref.y
      end
      -- up never happens naturally, only via play, so we'll change position when calling play

      self.eggman_arm:update()
      self.eggman_arm2:update()

      -- juggling-specific update

      if self.emerald_juggling_mode == 0 then
        -- Sonic 1 Try Again screen juggling: half-circle ping-pong

        -- half-cycle: a throw from left to right, or right to left, takes 120 frames
        if self.eggman_timer % 120 == 0 then
          self.eggman_timer = 0

          -- flip Eggman's arms
          local new_global_flip = not self.eggman_arm.flip_x
          self.eggman_arm.flip_x = new_global_flip
          local arm_offset = self.eggman_arm.flip_x and 9 or -9
          self.eggman_arm.position.x = eggman_body_position_ref.x + arm_offset

          -- the arm down is always at the opposite of the main (rising) arm
          self.eggman_arm2.flip_x = not new_global_flip
          self.eggman_arm2.position.x = eggman_body_position_ref.x - arm_offset

          -- play animation again that starts up for most of the cycle, then down just before flipping
          -- we know that legs spr_object is an animated_sprite_object
          self.eggman_legs.spr_object:play("raise_and_lower", --[[from_start:]] true)
          self.eggman_arm:play("raise_and_lower", --[[from_start:]] true)

          -- as noted above, we manually play the animation whose 1st frame moves Eggman
          --  up again, so we must move body and arm down at this moment
          eggman_body_position_ref.y = self.eggman_body_initial_y - 1
          eggman_arm_position_ref.y = eggman_body_position_ref.y + arm_offset_y_from_body
          eggman_arm2_position_ref.y = eggman_arm_position_ref.y
        end
      else
        -- Shower juggling (most of the code is done in rendering)

        if self.eggman_timer % visual.juggled_emeralds_shower_period == 0 then
          self.eggman_timer = 0
        end
      end

      self.eggman_timer = self.eggman_timer + 1
    end

    -- retry menu

    if self.retry_menu then
      self.retry_menu:update()
    end
  end
end

function stage_clear_state:render()
  if self.phase == 0 then
    -- phase 0: stage result

    -- see set_camera_with_origin for value explanation (we must pass camera position)
    visual_stage.render_background(vector(3376, 328))
    self:render_stage_elements()

    -- draw picked emeralds
    self:render_picked_emeralds()
  else
    -- phase 1: retry menu
    cls()

    if self.picked_emerald_count < 8 then
      -- haven't got all emeralds, so eggman is shown juggling emeralds

      -- draw Eggman
      self.eggman_legs:draw()
      self.eggman_body:draw()
      self.eggman_arm:draw()
      self.eggman_arm2:draw()

      -- draw juggled emeralds on top of Eggman's hand
      --  when overlapping it
      self:render_missed_emeralds_juggled()
    end

    --  for retry menu
    if self.retry_menu then
      self.retry_menu:draw(29, 108)
    end
  end

  -- draw overlay on top to hide result widgets
  self:render_overlay()

  self.postproc:apply()
end


-- stage-related methods, simplified/adapted versions of stage_state equivalents

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
      if tile_sprite_id == visual_ingame_data.goal_plate_base_id then
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


-- actual stage clear sequence functions

function stage_clear_state:restore_picked_emerald_data()
  -- retrieve and store picked emeralds set information from persistent memory saved during ingame
  --  before stage clear cartridge was loaded
  -- similar to stage_state:restore_picked_emerald_data, but we don't remove emerald objects
  --  and cache the picked count for assessment
--#ifn itest
  -- itests do not save (do not call cartdata), so do not call this to avoid error
  --  "dget called before cardata()"
  local picked_emerald_byte = dget(memory.persistent_picked_emerald_index)
--#endif

  -- read bitset low-endian, from lowest bit (emerald 1) to highest bit (emerald 8)
  for i = 1, 8 do
    if band(picked_emerald_byte, shl(1, i - 1)) ~= 0 then
      self.picked_emerald_numbers_set[i] = true
      self.picked_emerald_count = self.picked_emerald_count + 1
    end
    -- DEBUG: uncomment both lines to simulate getting all emeralds when testing stage_clear directly
    -- self.picked_emerald_numbers_set[i] = true
    -- self.picked_emerald_count = 8
  end
end

function stage_clear_state:show_result_async()
  -- create "sonic" label separately just for different color
  -- "sonic got through": 17 characters, so 17*4 = 68 px wide
  -- make text enter from left to right (starts on screen edge, so -68 with even an extra margin pixel after last char)
  -- "got through" is 6 chars after the string start so 24px after "sonic"
  -- using new feature to preserve initial relative offset, pass 0 and 24 now just to set this relative positioning on X,
  --  then we can pass coord_offsets = nil to move_drawables_on_coord_async
  local sonic_label = label("sonic", vector(0, 14), colors.dark_blue, colors.orange)
  self.result_overlay:add_drawable("sonic", sonic_label)
  local through_label = label("got through", vector(24, 14), colors.white, colors.black)
  self.result_overlay:add_drawable("through", through_label)

  ui_animation.move_drawables_on_coord_async("x", {sonic_label, through_label}, nil, -68, 30, 20)

  local stage_label = label("pico island", vector(0, 26), colors.white, colors.black)
  self.result_overlay:add_drawable("stage", stage_label)

  -- make text enter screen from right to left (starts on screen edge, so 128)
  ui_animation.move_drawables_on_coord_async("x", {stage_label}, nil, 128, 42, 20)
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
  ui_animation.move_drawables_on_coord_async("x", {sonic_label, through_label}, nil, 30, -68, 10)

  -- make text exit to the right (faster)
  ui_animation.move_drawables_on_coord_async("x", {stage_label}, nil, 40, 128, 10)

  -- clean up labels outside screen, except "sonic" that we will reuse
  -- "sonic" label is already outside screen so it won't bother us until we use it again
  self.result_overlay:remove_drawable("through")
  self.result_overlay:remove_drawable("stage")

  yield_delay_frames(30)

  local got_all_emeralds = self.picked_emerald_count >= 8

  local emerald_text

  -- show how many emeralds player got
  -- "[number]" is has 1 character but "all" has 3 characters, and label doesn't support centered text,
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
  -- this time, sonic_label position on X depends on last movement, so it's not trivial to setup emerald_label
  --  at the right relative position (we'd need to pass sonic_label.position.x + 24), so in this case, passing coord_offsets
  --  directly seems better
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
  self.fading_overlay:add_drawable("fadeout_rect", fadeout_rect)
  self.fading_overlay:add_drawable("zigzag", zigzag_drawable)

  -- swipe sfx must be played during swipe animation
  sfx(audio.sfx_ids.menu_swipe)

  -- make rectangle with zigzag edge enter the screen from the left
  -- note that we finish at 128 and not 127 so the zigzag fully goes out of the screen to the right,
  --  and the fadeout_rect fully covers the screen, ready to be used as background
  ui_animation.move_drawables_on_coord_async("x", {fadeout_rect, zigzag_drawable}, {-128, 0}, - visual.fadeout_zigzag_width, 128, stage_clear_data.zigzag_fadeout_duration)

  -- at the end of the zigzag fade-out, clear all drawables including from fading overlay rect
  --  and set darkness to max in counterpart, so we don't accidentally show stuff behind until we fade in again
  self.result_overlay:clear_drawables()
  self.fading_overlay:clear_drawables()
  self.postproc.darkness = 5
end

function stage_clear_state:show_retry_screen_async()
  clear_table(self.result_show_emerald_set_by_number)

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
    local juggle_mode_selector_label = label("juggling: ##l           ##r", vector(23, 82), colors.white)
    -- mind +1 to convert our index-0 to Lua index
    local juggle_mode_value_label = label(self:get_current_juggling_mode_string(), vector(75, 82), colors.white)
    self.result_overlay:add_drawable("juggle mode selector", juggle_mode_selector_label)
    self.result_overlay:add_drawable("juggle mode value", juggle_mode_value_label)

    result_label = label("try again?", vector(45, 96), colors.white)
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

  -- no need to play Eggman animations at this point, they will be called on first frame where it can be shown

  -- fade in (we should have been at max darkness 5 since last fade out, so start at 4)
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

  -- draw overlays, make sure to draw fading on top, so in case of manual result skip,
  --  we draw the labels (added after fading drawables) behind the fading drawables
  self.result_overlay:draw()
  self.fading_overlay:draw()
end

-- render every picked/missed emeralds at fixed screen position
function stage_clear_state:render_picked_emeralds()
  camera()
  self:draw_picked_emeralds(64, 64)
end

-- render every missed emeralds, juggled by Eggman
function stage_clear_state:render_missed_emeralds_juggled()
  camera()
  self:draw_missed_emeralds_juggled(63, 45)
end

-- draw picked emeralds on an invisible circle centered on (x, y)
function stage_clear_state:draw_picked_emeralds(x, y)
  -- draw emeralds around the clock, from top, CW
  -- usually we iterate from 1 to #self.spawned_emerald_locations
  -- but here we obviously only defined 8 relative positions,
  --  so just iterate to 8 (but if you happen to only place 7, you'll need to update that)
  for num = 1, 8 do
    if self.result_show_emerald_set_by_number[num] then
      local radius = visual.picked_emeralds_radius
      local param = 0.25 - (num - 1) / 8
      local draw_position = vector(x + radius * cos(param), y + radius * sin(param))
      emerald_common.draw(num, draw_position, self.result_emerald_brightness_levels[num])
    end
  end
end

function stage_clear_state:draw_missed_emeralds_juggled(x, y)
  if self.emerald_juggling_mode == 0 then
    self:draw_missed_emeralds_juggled_ping_pong(x, y)
  else
    self:draw_missed_emeralds_juggled_shower(x, y)
  end
end

-- draw missed emeralds juggled by Eggman on an invisible half circle centered on (x, y)
function stage_clear_state:draw_missed_emeralds_juggled_ping_pong(x, y)
  -- draw emeralds starting with the last one, so the lower indices are shown on top,
  --  as in Sonic 1's Try Again screen
  for num = 8, 1, -1 do
    if self.result_show_emerald_set_by_number[num] then
      -- simulate juggling by only moving parameter between angles 0 (right side) to 0.5 (left side),
      --  adding an offset based on index
      -- note that there will be a bigger gap between some emeralds if the emerald(s) between has been picked

      -- throw is faster than half-cycle since we must have the latest emerald reach the hand on the opposite
      --  side despite its delay
      -- so if a half-cycle is 120 frames, move emeralds in 60 frames
      local timer_ratio = self.eggman_timer / 60

      -- each emerald is placed with offset, the higher the index, the later
      -- give enough offset between emeralds so they don't overlap except near the hands
      local emerald_param_offset = (num - 1) / 8

      -- higher index emeralds are late, so subtract offset
      local param = timer_ratio - emerald_param_offset

      if self.eggman_arm.flip_x then
        -- throwing from right to left, with a small advance to match raised hand
        param = ui_animation.lerp_clamped(0 + 0.08, 0.5, param)
      else
        -- throwing from left to right, with a small advance to match raised hand
        param = ui_animation.lerp_clamped(0.5 - 0.08, 0, param)
      end

      -- amplitude on y is a little bigger than amplitude on x (vertical ellipsis),
      --  to have emeralds higher
      local draw_position = vector(x + 22 * cos(param), y + 28 * sin(param))
      emerald_common.draw(num, draw_position, self.result_emerald_brightness_levels[num])
    end
  end
end

-- draw missed emeralds juggled by Eggman in a cyclic trajectory, with a higher and lower path
function stage_clear_state:draw_missed_emeralds_juggled_shower(x, y)
  for num = 8, 1, -1 do
    -- only draw if emerald was missed
    -- note that there will be a bigger gap between some emeralds if the emerald(s) between has been picked
    if self.result_show_emerald_set_by_number[num] then
      local timer_ratio = self.eggman_timer / visual.juggled_emeralds_shower_period

      -- each emerald is placed with offset, the higher the index, the later
      -- give enough offset between emeralds so they don't overlap except near the hands
      local emerald_param_offset = (num - 1) / 8

      -- higher index emeralds are late, so subtract offset
      -- apply modulo since emeralds are continuously looping in the shower pattern
      local param = (timer_ratio - emerald_param_offset) % 1

      local offset_x
      local offset_y

      -- we're gonna play some animations in sync with emerald reaching hand below
      -- it's not great to change the state of objects in render, but it allows us to inject the check
      --  directly in the emerald loop used for rendering

      -- high way takes more time, then low way move is very fast but stops (clamped) in hand
      --  for a moment, so the param threshold for high is more than 0.5
      local param_high_threshold = 0.65
      if param < param_high_threshold then
        -- first part: high way, from left to right

        if self.last_emerald_way_indices[num] == 1 then
          self.last_emerald_way_indices[num] = 0
          -- this emerald just touched the hand on the left to start high way, make it react
          self.eggman_legs.spr_object:play("raise_and_lower", --[[from_start:]] true)
          self.eggman_arm:play("full_raise_and_lower", --[[from_start:]] true)
        end

        -- compute local progress ratio inside high way
        local local_progress_ratio = param / param_high_threshold
        local normalized_signed_offset_x = ui_animation.lerp_clamped(-1, 1, local_progress_ratio)
        offset_x = 22 * normalized_signed_offset_x
        offset_y = 160 * local_progress_ratio * (local_progress_ratio - 1)
      else  -- param between 0.5 and 1 (excluded)
        -- second part: low way, from right to left

        if self.last_emerald_way_indices[num] == 0 then
          self.last_emerald_way_indices[num] = 1
          -- this emerald just touched the hand on the right to start low way, make it react
          -- this one only needs to raise to middle level
          self.eggman_legs.spr_object:play("raise_and_lower", --[[from_start:]] true)
          self.eggman_arm2:play("raise_middle_and_lower", --[[from_start:]] true)
        end

        -- compute local progress ratio inside low way
        local local_progress_ratio = (param - param_high_threshold) / (1 - param_high_threshold)
        -- to make emerald on low way go fast, then stop in hand for a moment,
        --  multiply the normalized progress and clamp progress itself (so both x and y match it)
        local_progress_ratio = min(1.3 * local_progress_ratio, 1)
        offset_x = 22 * ui_animation.lerp_clamped(1, -1, local_progress_ratio)
        offset_y = 20 * local_progress_ratio * (local_progress_ratio - 1)
      end

      local draw_position = vector(x + offset_x, y + offset_y)
      emerald_common.draw(num, draw_position, self.result_emerald_brightness_levels[num])
    end
  end
end

return stage_clear_state

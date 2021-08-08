local flow = require("engine/application/flow")
local input = require("engine/input/input")
local animated_sprite = require("engine/render/animated_sprite")

local collision_data = require("data/collision_data")
local pc_data = require("data/playercharacter_numerical_data")
local pc_sprite_data = require("data/playercharacter_sprite_data")
local pfx = require("ingame/pfx")
local motion = require("platformer/motion")
local world = require("platformer/world")
local audio = require("resources/audio")
local visual = require("resources/visual_common")
-- we should require ingameadd-on in main, as early as possible

--#if debug_character
local outline = require("engine/ui/outline")
--#endif

local player_char = new_class()

-- helper for spin dash dust
function player_char.pfx_size_ratio_over_lifetime(life_ratio)
  -- make size grow quickly at start of lifetime, but shrink again around 1/3 of lifetime
  --  (to avoid big particles hiding character bottom too much)
  -- negative size will draw nothing, no need to clamp
  local junction = 0.36
  if life_ratio < junction then
    -- linear piece, start at size 0.4 at 0, ends at 1 at junction
    return 0.4 * (1 - life_ratio / junction) + life_ratio / junction
  end
  -- linear piece start at 1 at junction, ends at 0 at 1
  return 1 - (life_ratio - junction) / (1 - junction)
end

-- parameters cached from PC data

-- debug_move_max_speed (#cheat)  float                   move max speed in debug mode
-- debug_move_accel     (#cheat)  float                   move acceleration in debug mode
-- debug_move_decel     (#cheat)  float                   move deceleration in debug mode
-- debug_move_friction  (#cheat)  float                   move friction in debug mode


-- components

-- anim_spr               animated_sprite controls sprite animation, responsible for sprite rendering


-- state vars

-- control_mode             control_modes   control mode: human (default), puppet or ai (#itest only)
-- motion_mode  (#cheat)    motion_modes    motion mode: platformer (under gravity) or debug (fly around)
-- motion_state             motion_states   motion state (platformer mode only)
-- quadrant                 directions      down vector of quadrant where character is located (down on floor, up on ceiling, left/right on walls)
-- orientation              horizontal_dirs direction faced by character
-- active_loop_layer        int             currently active loop layer (1 for entrance, 2 for exit)
-- ignore_launch_ramp_timer int             time left before we stop ignoring launch ramp last tile (0 if not ignoring) (frames)

-- ground_tile_location     location|nil    location of current ground tile character is on (nil if airborne)
-- position                 vector          current position (character center "between" pixels)
-- ground_speed             float           current speed along the ground (~px/frame)
-- horizontal_control_lock_timer    int     time left before regaining horizontal control after fall/slide off (frames)
-- velocity                 vector          current velocity in platformer mode (px/frame)
-- debug_velocity (#cheat)  vector          current velocity in debug mode (m/s)
-- slope_angle              float           slope angle of the current ground (clockwise turn ratio)
-- late_jump_slope_angle    float           (late jump feature only) slope angle of the last ground
-- ascending_slope_time     float           time before applying full slope factor, when ascending a slope (s)
-- (#original_slope_features)
-- spin_dash_rev            float           spin dash charge (aka revving) value (float to allow drag over time)

-- move_intention           vector          current move intention (binary cardinal)
-- jump_intention           bool            current intention to start jump or spin dash (consumed on jump or spin dash)
-- hold_jump_intention      bool            current intention to hold jump (always true when jump_intention is true)
-- should_jump              bool            should the character jump when next frame is entered? used to delay variable jump/hop by 1 frame
-- has_jumped_this_frame    bool            has the character started a jump/hop this frame?
-- can_interrupt_jump       bool            can the character interrupted his jump once?
-- time_left_for_late_jump  int             (late jump feature only) number of frames left to do a late jump after falling. Initialized on fall, decrement each frame.

-- anim_spr                 animated_sprite animated sprite component
-- anim_run_speed           float           Walk/Run animation playback speed. Reflects ground_speed, but preserves value even when falling.
-- continuous_sprite_angle  float           Sprite angle with high precision used internally. Reflects slope_angle when standing, but gradually moves toward 0 (upward) when airborne.
--                                          To avoid ugly sprite rotations, only a few angle steps are actually used on render.
-- is_sprite_diagonal       bool            Derived from continuous_sprite_angle. True iff continuous angle is closer to diagonal (45-degree multiple).
-- sprite_angle             float           Derived from continuous_sprite_angle. Sprite angle actually used for rendering. Rounded to multiple of 0.25. Takes 45-degree sprite variant into account.
--                                          To avoid ugly sprite rotations, only a few angle steps are actually used on render.
-- last_copied_double_row   float           Last sprite double row index copied to spritesheet memory, tracked to avoid copying it every frame
-- should_play_spring_jump  bool            Set to true when sent upward in the air thanks to spring, and not falling down yet
-- brake_anim_phase         int             0: no braking anim. 1: brake start. 2: brake reverse.

-- smoke_pfx                pfx             particle system used to render smoke during spin dash charge

-- last_emerald_warp_nb (cheat)     int     number of last emerald character warped to
-- debug_rays (#debug_character)    {start = vector, direction_vector = vector, distance = number, hit = bool}
--                                          rays to draw for debug render this frame
-- debug_mask_global_tile_locations (#debug_collision_mask)
--                                  {tile_location}
--                                          tile locations on which we should debug render collision mask
function player_char:init()
--#if cheat
  self.debug_move_max_speed = pc_data.debug_move_max_speed
  self.debug_move_accel = pc_data.debug_move_accel
  self.debug_move_decel = pc_data.debug_move_decel
  self.debug_move_friction = pc_data.debug_move_friction
--#endif

  self.anim_spr = animated_sprite(pc_sprite_data.sonic_animated_sprite_data_table)
  self.smoke_pfx = pfx(pc_data.spin_dash_dust_spawn_period_frames,
    pc_data.spin_dash_dust_spawn_count,
    pc_data.spin_dash_dust_lifetime_frames,
    vector(pc_data.spin_dash_dust_base_init_velocity_x, pc_data.spin_dash_dust_base_init_velocity_y),
    pc_data.spin_dash_dust_max_deviation,
    pc_data.spin_dash_dust_base_max_size,
    player_char.pfx_size_ratio_over_lifetime)

--#if cheat
  -- exceptionally not in setup, because this member but be persistent persist after warping
  self.last_emerald_warp_nb = 0
--#endif

  self:setup()
end

function player_char:setup()
  self.control_mode = control_modes.human
--#if cheat
  self.motion_mode = motion_modes.platformer
--#endif
  self.motion_state = motion_states.standing
  self.quadrant = directions.down
  self.orientation = horizontal_dirs.right
  self.active_loop_layer = 1
  self.ignore_launch_ramp_timer = 0

  -- no ground -> nil
  -- self.ground_tile_location = nil  -- commented out to spare characters
  -- undefined position convention
  self.position = vector(-1, -1)
  self.ground_speed = 0
  self.horizontal_control_lock_timer = 0
  self.velocity = vector.zero()
--#if cheat
  self.debug_velocity = vector.zero()
--#endif

  -- slope_angle starts at 0 instead of nil to match standing state above
  -- (if spawning in the air, fine, next update will reset angle to nil)
  self.slope_angle = 0
  self.late_jump_slope_angle = 0
--#if original_slope_features
  self.ascending_slope_time = 0
--#endif
  self.spin_dash_rev = 0

  self.move_intention = vector.zero()
  self.jump_intention = false
  self.hold_jump_intention = false
  self.should_jump = false
  self.has_jumped_this_frame = false
  self.can_interrupt_jump = false
  self.time_left_for_late_jump = 0

  self:set_continuous_sprite_angle(0)
  -- equivalent to:
  -- self.continuous_sprite_angle = 0
  -- self.is_sprite_diagonal = false
  -- self.sprite_angle = 0

  -- no need to setup that, update_sprite_row_and_play_sprite_animation will set it to match idle sprite below
  -- nil is not equal to any number, so the first call will always copy a row and initialize last_copied_double_row
  -- self.last_copied_double_row = nil

  -- must be called after setting angle, as it checks if we need diagonal sprites
  self:update_sprite_row_and_play_sprite_animation("idle")
  self.anim_run_speed = 0

  self.should_play_spring_jump = false
  self.brake_anim_phase = 0

--#if debug_character
  self.debug_rays = {}
--#endif

--#if debug_collision_mask
  self.debug_mask_global_tile_locations = {}
--#endif
end

-- return true iff character is grounded
function player_char:is_grounded()
  return contains({motion_states.standing, motion_states.rolling, motion_states.crouching, motion_states.spin_dashing}, self.motion_state)
end

-- return true iff character is curled
function player_char:is_compact()
  return contains({motion_states.air_spin, motion_states.rolling, motion_states.crouching, motion_states.spin_dashing}, self.motion_state)
end

function player_char:get_center_height()
  return self:is_compact() and pc_data.center_height_compact or pc_data.center_height_standing
end

function player_char:get_full_height()
  return self:is_compact() and pc_data.full_height_compact or pc_data.full_height_standing
end

-- return horizontal direction relative to quadrant in world direction, depending on horizontal_dir
-- equivalent to returning quadrant down, rotated by 90 degrees cw if horizontal_dir is left,
--  and by 90 degrees ccw if horizontal_dir is right
function player_char:get_horizontal(horizontal_dir)
  -- See formula of rotate_dir_90_cw in direction_ext.lua (not included for minimal chars usage)
  -- => we want + 1 for CW, so when dir is left, so we must oppose the horizontal sign, hence `-`
  return (self.quadrant - horizontal_dir_signs[horizontal_dir]) % 4
end

-- return quadrant normal down (interior) unit vector
function player_char:get_quadrant_down()
  return dir_vectors[self.quadrant]
end

-- return copy of vector rotated by quadrant right angle
--  this is a forward transformation, and therefore useful for intention (ground motion)
function player_char:quadrant_rotated(v)
--[[#pico8
  return v:rotated(world.quadrant_to_right_angle(self.quadrant))
--#pico8]]
--#if busted
  -- native Lua's floating point numbers cause small precision errors with cos/sin
  --  so prefer perfect quadrant rotations (PICO-8 could also use this, but requires more tokens)
  -- when testing, make sure to temporarily uncomment the pico8 block above
  --  and comment the busted block below, so you can confirm that the pico8 version is valid too
  if self.quadrant == directions.down then
    return v:copy()
  elseif self.quadrant == directions.right then
    return v:rotated_90_ccw()
  elseif self.quadrant == directions.up then
    return -v
  else  -- self.quadrant == directions.left
    return v:rotated_90_cw()
  end
--#endif
end

-- spawn character at given position, detecting ground/air on arrival
function player_char:spawn_at(position)
  self:setup()
  self:warp_to(position)
end

-- warp character to specific position, and update motion state (standing/falling)
-- while escaping from ground if needed
--  use this when you don't want to reset the character state as spawn_at does
function player_char:warp_to(position)
  self.position = position

  -- start falling, then call check_escape_from_ground
  -- if no ground is found, character will just fall
  -- otherwise (even if just touching ground), state will be set to standing
  -- note that unlike running, we never snap down
  -- we could also not set motion state at all, as the next update will detect no ground
  --  and start character fall if needed (but if late jump feature is enabled, it may allow
  --  player to oddly jump in the air just after warping)
  self:enter_motion_state(motion_states.falling)
  self:check_escape_from_ground()
end

--#if itest
-- same as warp_to, but with bottom position
function player_char:warp_bottom_to(bottom_position)
  self:warp_to(bottom_position - vector(0, self:get_center_height()))
end
--#endif

--#if ingame

--#if cheat
-- same as warp_to, but with bottom position
function player_char:warp_to_emerald_by(delta)
  local curr_stage_state = flow.curr_state
  assert(curr_stage_state.type == ':stage')

  -- safety if no emeralds found (test stage or emerald spawning disabled for some reason)
  if #curr_stage_state.spawned_emerald_locations == 0 then
    return
  end

  -- -1/+1 to loop from 1, not 0
  -- clamping to 0 after delta is only for the edge case where your first warp is previous (-1)
  --  since you want to reach the last emerald, no the penultimate one
  self.last_emerald_warp_nb = (max(0, self.last_emerald_warp_nb + delta) - 1) % #curr_stage_state.spawned_emerald_locations + 1

  -- spawned_emerald_locations is deprecated and may be removed in the future,
  --  but it's convenient to get a stable sequence of locations to warp to
  -- if removed we can still use curr_stage_state.emeralds, but note that emeralds are deleted on pick
  --  and therefore the last_emerald_warp_nb would be invalid (the modulo would ensure we always
  --  fall on a correct index but we wouldn't fall where we think we should since array length would change)
  -- alternatively you could replace picked emeralds with some dummy value like false (but not nil)
  --  to keep a stable index, and skip them on warp; or you could just keep the emerald objects around
  --  but deactivate them pooling style, so we can still locate them and warp to their original positions
  local target_pos = curr_stage_state.spawned_emerald_locations[self.last_emerald_warp_nb]:to_center_position()
  self:warp_to(target_pos)
end
--(cheat)
--#endif

--(ingame)
--#endif

-- move the player character so that the bottom center is at the given position
function player_char:get_bottom_center()
  return self.position + self:get_center_height() * self:get_quadrant_down()
end

--#if busted
-- move the player character so that the bottom center is at the given position
function player_char:set_bottom_center(bottom_center_position)
  self.position = bottom_center_position - self:get_center_height() * self:get_quadrant_down()
end
--#endif

-- set ground tile location and apply any trigger if it changed
function player_char:set_ground_tile_location(global_tile_loc)
  if self.ground_tile_location ~= global_tile_loc then
    self.ground_tile_location = global_tile_loc

--#if ingame

--#if busted
    if flow.curr_state.type == ':stage' then
--#endif
      -- when touching (internal) loop entrance trigger, enable entrance (and disable exit) layer
      --  and reversely
      -- we are now checking loop triggers directly from stage data
      -- external triggers are different and can be entered airborne, see check_loop_external_triggers
      local curr_stage_state = flow.curr_state
      assert(curr_stage_state.type == ':stage')

      -- new convention is to check ground location at the end of update_platformer_motion
      --  like check_spring, because changing state to airborne in the middle of ground motion
      --  may cause issues
      -- but loops were added before springs and they keep the character grounded, so we kept
      --  this behavior here
      if curr_stage_state:is_tile_loop_entrance_trigger(global_tile_loc) then
        -- note that active loop layer may already be 1
        log("internal trigger detected, set active loop layer: 1", 'loop')
        self.active_loop_layer = 1
      elseif curr_stage_state:is_tile_loop_exit_trigger(global_tile_loc) then
        -- note that active loop layer may already be 2
        log("internal trigger detected, set active loop layer: 2", 'loop')
        self.active_loop_layer = 2
      end
--#if busted
    end
--#endif

--(ingame)
--#endif
  end
end

function player_char:set_continuous_sprite_angle(angle)
  self.continuous_sprite_angle = angle
  self:update_sprite_angle_parameters()
end

function player_char:update_sprite_angle_parameters()
  local sprite_angle = 0
  local is_sprite_diagonal = false

  if self.anim_spr.current_anim_key == "idle" then
    -- snap render angle to a few set of values (90 degrees steps)
    -- originally we always used angle = 0 as Sonic cannot normally be idle on a wall or ceiling,
    --  but in edge cases (speed reaches 0 for 1 frame on a slope, Sonic get stuck inside wall and
    --  we want to debug quadrant) it can happen and then it's more useful to show at least
    --  the correct 90-degree rotation (as we don't have 45-deg sprite variants)
    -- 90 degrees is 0.25 = 1/4, so by multiplying by 4, each integer represent a 90-degree step
    --  we just need to add 0.5 before flooring to effectively round to the closest step, then go back
    sprite_angle = flr(4 * self.continuous_sprite_angle + 0.5) / 4
  elseif contains({"walk", "run"}, self.anim_spr.current_anim_key) then
    -- snap render angle to a few set of values (45 degrees steps), classic style
    --  (unlike Freedom Planet and Sonic Mania)
    -- 45 degrees is 0.125 = 1/8, so by multiplying by 8, each integer represent a 45-degree step
    --  we just need to add 0.5 before flooring to effectively round to the closest step, then go back
    sprite_angle = flr(8 * self.continuous_sprite_angle + 0.5) / 8

    -- a computed rotation of 45 degrees would result in an ugly sprite
    --  so we only use rotations multiple of 90 degrees, using handmade 45-degree
    --  sprites when we want a better angle resolution
    if sprite_angle % 0.25 ~= 0 then
      is_sprite_diagonal = true

      -- rotated sprite embeds a rotation of 45 degrees, so if not flipped, rotate by angle - 45 degrees
      -- if flipped, the sprite is 45 degrees *behind* the horizontal left, so we must add 45 degrees instead
      local flip_x = self.orientation == horizontal_dirs.left
      sprite_angle = sprite_angle + (flip_x and 1 or -1) * 0.125
    end
  end

  self.sprite_angle = sprite_angle % 1
  self.is_sprite_diagonal = is_sprite_diagonal
end

-- set slope angle and update quadrant
-- if force_upward_sprite is true, set sprite angle to 0
-- else, set sprite angle to angle (if not nil)
function player_char:set_slope_angle_with_quadrant(angle, force_upward_sprite)
  assert(angle == nil or 0 <= angle and angle < 1, "player_char:set_slope_angle_with_quadrant: angle is "..tostr(angle)..", should be nil or between 0 and 1 (excluded), please apply % 1 if needed")

  self.slope_angle = angle

  -- only set sprite angle with true grounded angle, do not set it to 0 when nil
  -- this is to prevent character sprite from switching straight upward immediately
  --  on fall
  if force_upward_sprite then
    self:set_continuous_sprite_angle(0)
  elseif angle then
    self:set_continuous_sprite_angle(angle)
  end

  self.quadrant = world.angle_to_quadrant(angle)
end

function player_char:update()

--#if debug_collision_mask
  clear_table(self.debug_mask_global_tile_locations)
--#endif

--#if debug_character
  -- clear the debug rays to start anew for this frame (don't clear them after rendering
  --  so you can continue seeing them during debug pause)
  -- OPTIMIZE: pool the rays instead (you can also make them proper structs)
  clear_table(self.debug_rays)
--#endif

-- in stage_intro cartridge, we want Sonic to stay idle, so no input
--  but update physics and render as usual
--#if ingame

-- input is used by normal (non-attract) mode and attract-mode in recorder sub-mode only
--#if normal_mode || recorder

--#if busted
  if flow.curr_state.type == ':stage' then
--#endif
    self:handle_input()
--#if busted
  end
--#endif

--(not attract_mode)
--#endif

--(ingame)
--#endif
  self:update_motion()
  self:update_anim()
  self.anim_spr:update()
  self.smoke_pfx:update()
end

--#if ingame

-- input is used by normal (non-attract) mode and attract-mode in recorder sub-mode only
--#if normal_mode || recorder

-- update intention based on current input
function player_char:handle_input()
  if self.control_mode == control_modes.human then
    -- move
    local player_move_intention = vector.zero()

    -- ignore horizontal input when *grounded* with control lock timer is active
    -- checking == 0 is enough, <= 0 is just for safety
    if not self:is_grounded() or self.horizontal_control_lock_timer <= 0 then

      -- horizontal input
      -- note: in the original game, pressing left + right at the same time makes the game think
      --  Sonic is moving toward left at speed 0, then braking to the right, making him walk toward right
      --  at a very low speed. This is useful for a quick startup in TAS and a quick controlled break
      --  when going to the right; but not useful otherwise and not feasible on some gamepads; so we don't
      --  emulate this behavior (see Start faster on http://tasvideos.org/GameResources/Genesis/SonicTheHedgehog.html)
      if input:is_down(button_ids.left) then
        player_move_intention:add_inplace(vector(-1, 0))
      elseif input:is_down(button_ids.right) then
        player_move_intention:add_inplace(vector(1, 0))
      end

    end

    -- in original game, horizontal control lock timer is only decremented when *grounded*
    --  this caused delayed lock such as jumping out of lock situation to escape but still being locked for
    --  a moment on ground, or falling off a ceiling and still not being able to move freely for a moment
    -- this contributes to the feel of lack of control after falling off and may be desirable,
    --  but in pico sonic we prefer decrementing timer when airborne, so after a long fall or jump you
    --  can immediately get control back
    -- to restore original game behavior, uncomment the line below and comment out the 2nd line below
    -- if self.horizontal_control_lock_timer > 0 and self:is_grounded() then
    if self.horizontal_control_lock_timer > 0 then
      -- decrement control lock frame timer
      -- normally it's better to update non-intention state vars
      --  in a normal update method not handle_input, but since we know
      --  that both are updated at 60FPS, it shouldn't be a problem here
      self.horizontal_control_lock_timer = self.horizontal_control_lock_timer - 1
    end

    -- vertical input (used for debug motion, crouch/roll, and possibly look up/down in the future)
    if input:is_down(button_ids.up) then
      player_move_intention:add_inplace(vector(0, -1))
    elseif input:is_down(button_ids.down) then
      player_move_intention:add_inplace(vector(0, 1))
    end

--#if recorder
    -- No unit test for this code, it is only meant for temporary usage to record intention changes and find good async delays
    --  in attract_mode_scenario_async. #recorder symbol should be dfined together with #tostring to make meaningful logs.

    -- detect move intention direction change
    if self.move_intention ~= player_move_intention then
      -- print usable Lua directly to the log (we'll just have to remove [recorder] at the start)
      -- ex:
      -- yield_delay_frames(10)
      -- pc.move_intention = vector(1, 0)
      if total_frames > 0 then
        log("yield_delay_frames("..total_frames..")", "recorder")

        -- reset total frames as we want relative delays since last record
        total_frames = 0
      end
      log("pc.move_intention = "..player_move_intention, "recorder")

      -- reset total frames as we want relative delays since last record
      total_frames = 0
    end
--#endif

    self.move_intention = player_move_intention

    -- jump
    local is_jump_input_down = input:is_down(button_ids.o)  -- convenient var for optional pre-check
    -- set jump intention *each frame*, don't set it to true for later consumption to avoid sticky input
    --  without needing a reset later during update

--#if recorder
    -- No unit test for this code, it is only meant for temporary usage to record intention changes and find good async delays
    --  in attract_mode_scenario_async. #recorder symbol should be defined together with #tostring and #log in some 'recorder' config.

    local has_jump_intention_this_frame = is_jump_input_down and input:is_just_pressed(button_ids.o)

    -- safety code to detect a jump intention that was not consumed (and player doesn't keep trying
    --  to jump, rare as they'd need to repeat pressing the button every frame)
    -- this allows to clear a jump intention recorded by player pressing jump button
    --  while not able to jump (e.g. in the air) as it would be sticky and cause an unwanted
    --  chained jump as soon as able to jump again (e.g. when landing)
    if self.jump_intention and not has_jump_intention_this_frame then
      -- usable Lua ex:
      -- yield_delay_frames(10)
      -- pc.jump_intention = false
      if total_frames > 0 then
        log("yield_delay_frames("..total_frames..")", "recorder")

        -- reset total frames as we want relative delays since last record
        total_frames = 0
      end
      log("pc.jump_intention = false", "recorder")
    end

    -- detect start jump
    if not self.jump_intention and has_jump_intention_this_frame then
      -- usable Lua ex:
      -- yield_delay_frames(10)
      -- pc.jump_intention = true
      if total_frames > 0 then
        log("yield_delay_frames("..total_frames..")", "recorder")

        -- reset total frames as we want relative delays since last record
        total_frames = 0
      end
      log("pc.jump_intention = true", "recorder")
    end

    -- detect start and stop holding jump intention
    if self.hold_jump_intention ~= is_jump_input_down then
      -- usable Lua ex:
      -- yield_delay_frames(10)
      -- pc.hold_jump_intention = true
      if total_frames > 0 then
        log("yield_delay_frames("..total_frames..")", "recorder")

        -- reset total frames as we want relative delays since last record
        total_frames = 0
      end
      log("pc.hold_jump_intention = "..tostr(is_jump_input_down), "recorder")
    end
--#endif

    self.jump_intention = is_jump_input_down and input:is_just_pressed(button_ids.o)
    self.hold_jump_intention = is_jump_input_down

--#if cheat
    if input:is_just_pressed(button_ids.x) then
      self:toggle_debug_motion()
    end
--#endif
--#if itest
  elseif self.control_mode == control_modes.ai then
    -- for now, ai just resets intention
    -- it is current unused, as puppet is more convienent for itests,
    --  post-goal behavior, attract mode, etc. (like a scripted behavior)
    self.move_intention = vector.zero()
    self.jump_intention = false
    self.hold_jump_intention = false
--#endif
  end
end

--(not attract_mode)
--#endif

function player_char:force_move_right()
  -- force player to move to the right
  self.control_mode = control_modes.puppet
  self.move_intention = vector(1, 0)
  self.jump_intention = false
  self.hold_jump_intention = false
end

--#if cheat

function player_char:toggle_debug_motion()
  -- 1 -> 2 (debug)
  -- 2 -> 1 (platformer)
  self:set_motion_mode(self.motion_mode % 2 + 1)
end

function player_char:set_motion_mode(val)
  self.motion_mode = val
  if val == motion_modes.platformer then
    -- respawn character at current position
    -- this will detect ground and update the motion state correctly
    -- prefer warp_at if you want to preserve previous state vars
    --  and resume Sonic motion from here
    self:spawn_at(self.position)
  else  -- self.motion_mode == motion_modes.debug
    self.debug_velocity = vector.zero()
  end
end

--(cheat)
--#endif

--(ingame)
--#endif

-- update player position
function player_char:update_motion()
  self:update_collision_timer()

--#if ingame
--#if cheat

--#if busted
  if flow.curr_state.type == ':stage' then
--#endif
    if self.motion_mode == motion_modes.debug then
      self:update_debug()
      return
    end
--#if busted
  end
--#endif

--(ingame)
--#endif
--(cheat)
--#endif

  self:update_platformer_motion()
end

-- return ground_query_info(tile_location, signed_distance, slope_angle) where:
--  - tile_location is the location of the detected ground tile, nil if no ground detected
--  - signed_distance is the signed distance to the highest ground when character center is at center_position,
--   either negative when (in abs, penetration height)
--   or positive (actual distance to ground), always abs clamped to tile_size+1
--  - slope_angle is the slope angle of the highest ground. in case of tie,
--   the character's velocity x sign, then his horizontal direction determines which ground is chosen
-- if both sensors have different signed distances,
--  the lowest signed distance is returned (to escape completely or to have just 1 sensor snapping to the ground)
function player_char:compute_ground_sensors_query_info(center_position)
  return self:compute_sensors_query_info(self.compute_closest_ground_query_info, center_position)
end

-- similar to compute_ground_sensors_query_info, but ceiling
-- it is not completely symmetrical adherence rules differ
function player_char:compute_ceiling_sensors_query_info(center_position)
  return self:compute_sensors_query_info(self.compute_closest_ceiling_query_info, center_position)
end

-- general method that returns general ground query info for ground or ceiling closest to both of ground sensors
-- pass compute_closest_query_info: compute_closest_ground_query_info or compute_closest_ceiling_query_info
function player_char:compute_sensors_query_info(compute_closest_query_info, center_position)
  -- initialize with negative value to return if the character is not intersecting ground
  local min_signed_distance = 1 / 0  -- max (32768 in pico-8, but never enter it manually as it would be negative)
  local highest_ground_query_info = nil

  -- check both ground sensors for ground/ceiling (ceiling also uses ground sensors, it just uses an offset to adjust)
  for i=1,2 do
  -- equivalent to:
  -- for i in all({horizontal_dirs.left, horizontal_dirs.right}) do

    -- check that ground sensor #i is on q-top of or q-below the mask column
    local sensor_position = self:get_ground_sensor_position_from(center_position, i)
    local query_info = compute_closest_query_info(self, sensor_position)
    local signed_distance = query_info.signed_distance

    -- apply ground priority rule: highest ground, then ground speed (velocity X in the air) sign breaks tie,
    --  then q-horizontal direction breaks tie
    -- it also applies to ceiling, although when running, we only care about hitting ceiling or not (bool) so priority
    --  doesn't change the result; so it only applies to airborne movement

    -- store the biggest penetration height among sensors
    -- case a: this ground is higher than the previous one, store new height and slope angle
    -- case b: this ground has the same height as the previous one, but character orientation
    --  makes him stand on that one rather than the previous one, so we use its slope
    -- (for ceiling, think of everything upside down, as when dealing with q-up ground)
    -- check both cases in condition below
    if signed_distance < min_signed_distance or signed_distance == min_signed_distance and self:get_prioritized_dir() == i then
      min_signed_distance = signed_distance  -- does nothing in case b
      highest_ground_query_info = query_info
    end

  end

  return motion.ground_query_info(highest_ground_query_info.tile_location, min_signed_distance, highest_ground_query_info.slope_angle)
end

function player_char:get_prioritized_dir()
  if self:is_grounded() then
    -- on the ground, ground speed decides priority
    if self.ground_speed ~= 0 then
      return signed_speed_to_dir(self.ground_speed)
    end
  else
    -- in the air, no quadrant, just use velocity X
    if self.velocity.x ~= 0 then
      return signed_speed_to_dir(self.velocity.x)
    end
  end
  -- if not moving, orientation decides priority
  return self.orientation
end

-- return the position of the ground sensor in quadrant_horizontal_dir when the character center is at center_position
-- subpixels are ignored
function player_char:get_ground_sensor_position_from(center_position, quadrant_horizontal_dir)
  local x = center_position.x
  local y = center_position.y

  -- ignore subpixels from center position in qx (collision checks use Sonic's integer position,
  -- but we keep exact qy coordinate to get the exact ground sensor qy, and thus exact distance to ground)
  -- this is important to avoid assert in iterate_over_collision_tiles as the qx value will be used
  --  as (integer) index to get qcolumn height
  -- vertical: up (1) and down (3)
  if self.quadrant % 2 == 1 then
    x = flr(x)
  else
    y = flr(y)
  end
  -- from character center, move down by center height to get the character bottom center
  local qx_floored_bottom_center = vector(x, y) + self:get_center_height() * self:get_quadrant_down()

  -- using a ground_sensor_extent_x in .5 and flooring +/- this value allows us to get the checked column x (the x corresponds to the left of that column)
  --  rotate proper vector (initially horizontal) for quadrant compatibility, but make sure to apply coord flooring
  --  *afterward* so it applies to the final coord and we don't rotate a +2.5 -> +2 into a -2 instead of having -3
  local offset_qx_vector = self:quadrant_rotated(pc_data.ground_sensor_extent_x * horizontal_dir_vectors[quadrant_horizontal_dir])
  -- brutal way to floor coordinates after rotation, without having to extract qx, recreating (qx, 0) vector and rotating again
  offset_qx_vector = vector(flr(offset_qx_vector.x), flr(offset_qx_vector.y))

  return qx_floored_bottom_center + offset_qx_vector
end

-- Return the position of the wall sensor position when checking wall in quadrant_horizontal_dir
--  (relatively to current quadrant) and character center is at center_position.
-- Note that in the future, we may merge this method with get_ground_sensor_position_from and
--  also move the wall sensor position to the front of Sonic; if so, re-add parameter quadrant_horizontal_dir,
function player_char:get_wall_sensor_position_from(center_position)
  local x = center_position.x
  local y = center_position.y

  -- ignore subpixels from center position in qx (see get_ground_sensor_position_from)
  -- however, since it's a wall, the test is reversed: up and down means walls are checked with horizontal
  --  raycast where qx is actually y, which must be floored
  if self.quadrant % 2 == 0 then
    x = flr(x)
  else
    y = flr(y)
  end

  local qx_floored_center_position = vector(x, y)

  -- http://info.sonicretro.org/SPG:Solid_Tiles#Wall_Sensors_.28E_and_F.29
  -- On flat ground, lower the wall sensor position so Sonic can detect low steps as in Marble Zone
  -- (in pico island that will just be vertical springs placed on the ground)
  -- Note that compute_closest_wall_query_info already has a parameter sensor_offset_qy
  --  for that, so consider using it instead
  if self.slope_angle == 0 then
    -- normally we should use a clean constant, but at this point we just hardcode the offset
    -- more exactly, unlike the original games we don't set the wall sensor qy lower when compact,
    --  because it made the wall sensor very low when rolling, and combined with spin dash it was easy
    --  to hit a very low slope (esp. in a loop) and get blocked for no reason
    -- instead, we always place the wall sensor 6px above the ground
    -- (ideal to detect vertical spring of height 6px while not detecting low ground in loops at high speed)
    return qx_floored_center_position + (self:get_center_height() - 6) * self:get_quadrant_down()
  else
    -- return copy of vector for safety
    -- in practice, it's not modified in-place, but we prefer satefy to saving compressed chars
    --  unless we're really tight on budget
    return qx_floored_center_position:copy()
  end
end

-- helper method for compute_closest_ground_query_info, compute_closest_ceiling_query_info, compute_closest_wall_query_info
-- for given player character pc, it iterates over tiles from start to last (defined via offset from sensor position), providing distance from sensor_position_base + sensor_offset_qy along q-down (foot or head)
--  to q-column q-top (with reverse tile support) to custom callbacks which should return ground query info to closest ground/ceiling in quadrant direction
-- pass it a quadrant of interest (direction used to check collisions), iteration start and last tile locations
local function iterate_over_collision_tiles(pc, collision_check_quadrant, start_tile_offset_qy, last_tile_offset_qy, sensor_position_base, sensor_offset_qy, collider_distance_callback, no_collider_callback, ignore_reverse_on_start_tile)
  -- precompute region topleft uv
  -- note that we never change region during a collision check, but the 8 tiles margin
  --  should be enough compared to the short distance along which we check for ground, wall and ceiling
  local curr_stage_state = flow.curr_state
  assert(curr_stage_state.type == ':stage' or curr_stage_state.type == ':stage_intro')
  local region_topleft_loc = curr_stage_state:get_region_topleft_location()

  -- get check quadrant down vector (for ceiling check, it's actually up relative to character quadrant)
  local collision_check_quadrant_down = dir_vectors[collision_check_quadrant]

  -- apply sensor offset along check quadrant down (only used for ceiling, so actually upward to get head top position)
  local sensor_position = sensor_position_base + sensor_offset_qy * collision_check_quadrant_down

  assert(world.get_quadrant_x_coord(sensor_position, collision_check_quadrant) % 1 == 0, "iterate_over_collision_tiles: sensor_position qx for collision_check_quadrant: "..collision_check_quadrant.." must be floored, found "..sensor_position)

  -- deduce start and last tile from offset from the sensor position
  --  always oriented with check quadrant (by convention we check from q-top to q-bottom)
  -- p8tool has a bug that prevents support of (complex expression):method() syntax (although PICO-8 does support it)
  --  so we play on the fact that method = function bound to self and just write the .static_method(self) syntax (same token count)
  local start_global_tile_loc = vector.to_location(sensor_position + start_tile_offset_qy * collision_check_quadrant_down)
  local last_global_tile_loc = vector.to_location(sensor_position + last_tile_offset_qy * collision_check_quadrant_down)

--#if assert
  -- only used for tile qj safety check, see comment at the bottom
  local last_qj = world.get_quadrant_j_coord(last_global_tile_loc, collision_check_quadrant)
--#endif

  -- precompute start tile topleft (we're actually only interested in sensor location topleft,
  --  and both have the same qx)
  local start_tile_topleft = start_global_tile_loc:to_topleft_position()

  -- we iterate on tiles along quadrant down, so just convert it to tile_vector
  --  to allow step addition
  local tile_loc_step = tile_vector(collision_check_quadrant_down.x, collision_check_quadrant_down.y)

  -- we *always* iterate on columns from left to right, rows from top to bottom,
  --  and columns/rows are stored exactly like that in collision data (not CCW or anything)
  --  so unlike other operations, the subtraction from topleft (combined with qx coord) is correct
  --  to get column index for qcolumn height later, without the need to quadrant-rotate vectors first
  -- note that we use start_tile_topleft instead of the sensor_position:to_location():to_topleft_position()
  --  they may differ on qy (ceiling iteration starts a little higher than sensor position)
  --  but they have the same qx, so the operation is valid, and equivalent to using sensor location topleft,
  --  but with fewer tokens as we don't need the extra conversion
  local qcolumn_index0 = world.get_quadrant_x_coord(sensor_position - start_tile_topleft, collision_check_quadrant)  -- from 0 to tile_size - 1

  -- start iteration from start_global_tile_loc
  local curr_global_tile_loc = start_global_tile_loc:copy()

  -- keep looping until callback is satisfied (in general we found a collision or neary ground)
  --  or we've reached the last tile
  while true do
    local qcolumn_height, slope_angle

    -- check for tile collision special cases (world.compute_qcolumn_height_at
    --  does *not* check for this since it requires player character state)

    local ignore_tile = false

    -- convert to region location before using mget
    local tile_region_loc = curr_stage_state:global_to_region_location(curr_global_tile_loc)
    local visual_tile_id = mget(tile_region_loc.i, tile_region_loc.j)
    local is_oneway = fget(visual_tile_id, sprite_flags.oneway)
    local ignore_loop_layer = fget(visual_tile_id, sprite_flags.ignore_loop_layer)

--#if ingame

--#if busted
    if flow.curr_state.type == ':stage' then
--#endif
      -- we now check for ignored tiles:
      --  a. ramps just after launching
      --  b. loops on inactive layer from PC's point-of-view
      --  c. one-way platforms unless we check collision downward
      if pc.ignore_launch_ramp_timer > 0 and visual_tile_id == visual.launch_ramp_last_tile_id or
          not ignore_loop_layer and
            (pc.active_loop_layer == 1 and curr_stage_state:is_tile_in_loop_exit(curr_global_tile_loc) or
             pc.active_loop_layer == 2 and curr_stage_state:is_tile_in_loop_entrance(curr_global_tile_loc)) or
          is_oneway and collision_check_quadrant ~= directions.down then
        ignore_tile = true
      end

--#if busted
    end
--#endif

--(ingame)
--#endif

    if ignore_tile then
        -- tile is on layer with disabled collision, return emptiness
        qcolumn_height, slope_angle = 0--, nil
    else
      -- Ceiling ignore reverse full tiles on first tile. Comment from compute_closest_ceiling_query_info
      --  before extracting iterate_over_collision_tiles
      -- on the first tile, we don't cannot really be blocked by a ground
      --  with the same interior direction as quadrant <=> opposite to quadrant_opp
      --  (imagine Sonic standing on a half-tile; this definitely cannot be ceiling)
      --  so we do not consider the reverse collision with full tile_size q-height with them
      -- if you're unsure, try to force-set this to false and you'll see utests like
      --  '(1 ascending slope 45) should return false for sensor position on the left of the tile'
      --  failing
      local ignore_reverse = ignore_reverse_on_start_tile and start_global_tile_loc == curr_global_tile_loc

      -- check for ground (by q-column) in currently checked tile, at sensor qX
      -- make sure to convert the global tile location into region coordinates
      qcolumn_height, slope_angle = world.compute_qcolumn_height_at(curr_global_tile_loc - region_topleft_loc,
        qcolumn_index0, collision_check_quadrant, ignore_reverse)

--#if debug_collision_mask
      -- add global tile location (to avoid unstability on frames where we change regions)
      --  to debug render, if there was a collision tile
      -- (remember that with land_on_empty_qcolumn feature, qcolumn_height may be 0 yet there is a collision tile,
      --  so testing slope_angle is more reliable)
      if slope_angle then
        add(pc.debug_mask_global_tile_locations, curr_global_tile_loc)
      end
--#endif
    end

    -- if ground is found, including ground of height 0 thx to land_on_empty_qcolumn, slope_angle is never nil
    --  so check that, it's more reliable than the ground height
    -- if no ground is found (ground height is 0 and slope angle is nil),
    --  we still don't know whether there is something below
    -- so don't do anything yet but check for the tile one level lower
    --  (unless we've reached end of iteration with the last tile, in which case
    --  the next tile would be too far to snap down anyway)
    if slope_angle then
      -- get q-bottom of tile to compare heights
      -- when iterating q-upward (ceiling check) this is actually a q-top from character's perspective
      local current_tile_qbottom = world.get_tile_qbottom(curr_global_tile_loc, collision_check_quadrant)

      -- signed distance to closest ground/ceiling is positive when q-above ground/q-below ceiling
      -- PICO-8 Y sign is positive up, so to get the current relative height of the sensor
      --  in the current tile, you need the opposite of (quadrant-signed) (sensor_position.qy - current_tile_qbottom)
      -- then subtract qcolumn_height and you get the signed distance to the current ground q-column
      -- SYMMETRY NOTE: we decided to *not* subtract 1 when collision_check_quadrants is "positive" ie right or down,
      --  although that would be the thing to do if we take the convention that sensor position covers a full pixel,
      --  and we want the distance to that full pixel (actually its edge in the collision_check_quadrant direction)
      -- Instead, we picked the convention that the sensor position is a CROSS between 4 pixels, so we don't need to do that
      --  and results are symmetrical. When sensor position is on the top pixel of a ground column, distance is 0.
      -- For wall detection, sensor position does not need the +/-0.5 with flooring hack to be at visually symmetrical pixels:
      --  since it's on a cross, it's already placed symmetrically. Therefore the +/-0.5 hack is only needed to place
      --  *ground* sensors on *qx*, i.e. the direction orthogonal to the raycast direction aka collision_check_quadrant.
      -- Test along collision_check_quadrant itself never needs it.
      local signed_distance_to_closest_collider = world.sub_qy(current_tile_qbottom, world.get_quadrant_y_coord(sensor_position, collision_check_quadrant), collision_check_quadrant) - qcolumn_height

      -- callback returns ground query info, let it decide how to handle presence of collider
      local result = collider_distance_callback(curr_global_tile_loc, signed_distance_to_closest_collider, slope_angle)

      -- we cannot 2x return from a called function directly, so instead, we check if a result was returned
      --  if so, we return from the caller
      if result then
--#if debug_character
      -- store debug ray for hit or no-hit (we may have found ground/ceiling which happens to be too far)
      add(pc.debug_rays, {start = sensor_position:copy(), direction_vector = collision_check_quadrant_down:copy(), distance = result.signed_distance, hit = result.tile_location ~= nil})
--#endif
        return result
      end

      -- else (can only happen in compute_closest_ground_query_info): ground has been found, but it is too far below character's q-feet
      --  to snap q-down. This can only happen on the last tile we iterate on
      --  (since it was computed to be at the snap q-down limit),
      --  *unless* we are ignore a one-way platform from below (we can't check signed_distance_to_closest_collider < 0
      --  because signed_distance_to_closest_collider changed already, but we could by storing a backup var if #assert only),
      --  which means we will enter the "end of iteration" block below (if because on one-way, we'll continue iteration as normal)
      assert(curr_global_tile_loc == last_global_tile_loc or is_oneway)
    end

    -- check for end of iteration (reached last tile)
    -- we do a simple check in PICO-8 release:
--[[#pico8
--#ifn assert
    if curr_global_tile_loc == last_global_tile_loc then
--#endif
--#pico8]]
    -- ... which is perfectly fine in normal conditions
    --  because we are supposed to reach the last tile at some point
    -- however, for malformed requests like a very big ceiling escape distance that would start the iteration above
    --  character full height top tile, we'd go crazy and iterate toward the infinite, then loop back at 65536 to -65536
    --  and finally come back
    -- to avoid this we do a proper q-comparison of qj "is current tile beyond last tile in the iteration direction"
    --  so if we start beyond, it's fine, but still assert as weird behavior would occur like vx -> 0 when hitting ceiling
    -- it's a rare case where assert version is faster than release version *in weird conditions*, useful to test
    --  crazy escape values, but otherwise stick to the version above to reduce char count
--#if assert
    local curr_qj = world.get_quadrant_j_coord(curr_global_tile_loc, collision_check_quadrant)
    if world.sub_qy(curr_qj, last_qj, collision_check_quadrant) >= 0 then
--#endif
      assert(curr_global_tile_loc == last_global_tile_loc, "see comment in iterate_over_collision_tiles")
      -- callback returns ground query info, let it decide how to handle the end of iteration without finding any collider
      local result = no_collider_callback()

--#if debug_character
      -- store debug ray for no-hit (result.signed_distance will just be some max detection distance + 1)
      add(pc.debug_rays, {start = sensor_position:copy(), direction_vector = collision_check_quadrant_down:copy(), distance = result.signed_distance, hit = false})
--#endif

      -- this is the final check so return the result whatever it is
      return result
    end

    curr_global_tile_loc = curr_global_tile_loc + tile_loc_step
  end
end

-- actual body of compute_closest_ground_query_info passed to iterate_over_collision_tiles
--  as no_collider_callback
-- defined before ground_check_collider_distance_callback to make it callable from there
local function ground_check_no_collider_callback()
  -- end of iteration, and no ground found or too far below to snap q-down
  -- return edge case for ground considered too far below
  --  (pc_data.max_ground_snap_height + 1, nil)
  return motion.ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil)
end

-- actual body of compute_closest_ground_query_info passed to iterate_over_collision_tiles
--  as collider_distance_callback
-- return nil if no clear result and we must continue to iterate (until the last tile)
local function ground_check_collider_distance_callback(tile_location, signed_distance_to_closest_ground, slope_angle)
  if signed_distance_to_closest_ground < -pc_data.max_ground_escape_height then
    -- ground found, but character is too deep inside to snap q-up
    -- return edge case (nil, -pc_data.max_ground_escape_height - 1, 0)
    -- the slope angle 0 allows to still have character stand straight (world) up visually,
    --  but he's probably stuck inside the ground...
    -- convention v3 is to ignore ground completely is too deep inside
    --  to avoid walking with head on ceiling or inside one-way platform when a little too low
    -- to spare characters just reuse no collider callback directly
    return ground_check_no_collider_callback()
  elseif signed_distance_to_closest_ground <= pc_data.max_ground_snap_height then
    -- ground found, and close enough to snap up/down, return ground query info
    --  to allow snapping + set slope angle
    return motion.ground_query_info(tile_location, signed_distance_to_closest_ground, slope_angle)
  end
end

-- return ground_query_info(tile_location, signed_distance, slope_angle) where:
--  - tile_location is the location where we found the first colliding tile, or nil if no collision
--  - signed distance to closest ground from sensor_position,
--     either negative when (in abs, penetration height, clamped to max_ground_escape_height+1)
--      or positive (actual distance to ground, clamped to max_ground_snap_height+1)
--     if no closest ground is detected, this defaults to max_ground_snap_height+1 (character in the air)
--  - slope_angle is the slope angle of the detected ground (whether character is touching it, above or below)
--  the closest ground is detected in the range [-max_ground_escape_height-1, max_ground_snap_height+1]
--   around the sensor_position's qy, so it's easy to know if the character can q-step up/down,
--   and so that it's meaningful to check for q-ceiling obstacles after the character did his best to step
--  the test should be tile-insensitive so it is possible to detect q-step up/down in vertical-neighboring tiles
function player_char:compute_closest_ground_query_info(sensor_position)
  assert(world.get_quadrant_x_coord(sensor_position, self.quadrant) % 1 == 0, "player_char:compute_closest_ground_query_info: sensor_position qx must be floored")

  -- we used to flr sensor_position.y (would now be qy) at this point,
  -- but actually collision checks don't mind the fractions
  -- in addition, we will automatically get the correct signed distance to ground with fractional part!

  -- check the presence of a colliding q-column from q-top to q-bottom, with offset from -(max step up) to +(min step down)
  -- because we work by q-columns and not pixels, we iterate over tiles directly, so deduce tile locations
  --  from sensor + offset position (in qy)
  -- we are effectively finding the tiles covered (even partially) by the q-vertical segment between the edge positions
  --  where the character can snap up (escape) and snap down
  return iterate_over_collision_tiles(self, self.quadrant, - (pc_data.max_ground_escape_height + 1), pc_data.max_ground_snap_height, sensor_position, 0, ground_check_collider_distance_callback, ground_check_no_collider_callback)
end

-- actual body of compute_closest_ceiling_query_info passed to iterate_over_collision_tiles
--  as no_collider_callback
-- defined before ceiling_check_collider_distance_callback to make it callable from there
local function ceiling_check_no_collider_callback()
  -- end of iteration, and no ceiling found
  return motion.ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil)
end

-- actual body of compute_closest_ceiling_query_info passed to iterate_over_collision_tiles
--  as collider_distance_callback
-- return "ground query info" although it's ceiling, because depending on the angle, character may actually adhere, making it
--  a q-up ground
-- return nil if no clear result and we must continue to iterate (until the last tile)
local function ceiling_check_collider_distance_callback(curr_tile_loc, signed_distance_to_closest_ceiling, slope_angle)
  -- previous calculations already reversed sign of distance to match convention (> 0 when not touching, < 0 when inside)
  if signed_distance_to_closest_ceiling <= 0 then
    -- head (or body) just touching or inside ceiling
    return motion.ground_query_info(curr_tile_loc, signed_distance_to_closest_ceiling, slope_angle)
  else
    -- head far touching ceiling or has some gap from ceiling
    -- unlike ground, we never "step q-down" onto ceiling, the ceiling check only results in collision with movement interruption
    --  or ceiling adherence, but then character started going inside ceiling (distance <= 0), therefore distance is never > 0
    --  unless we reached ceiling_check_no_collider_callback and then it's the max + 1
    -- TODO OPTIMIZE CPU: I'm pretty sure we can stop the search here since we found a ceiling, it's just too far,
    --  and there's no chance we'll find a ceiling *closer* from here one.
    -- So we can probably, like ceiling_check_no_collider_callback, do:
    --   return motion.ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil)
    -- but I'll wait for the rest of new physics to work before trying that.
    -- when you're ready, just uncomment this:
    -- return ceiling_check_no_collider_callback()
    return nil
  end
end

-- similar to compute_closest_ground_query_info, but for ceiling
-- return ground_query_info(tile_location, signed_distance, slope_angle) (see compute_closest_ground_query_info for more info)
-- note that we return a query info with negative sign (inside ceiling) even if the detected obstacle is lower than one step up's height,
--  because we assume that if the character could step this up, it would have and the passed
--  sensor_position would be the resulting position, so only higher tiles will be considered
--  so the step up itself will be ignored (e.g. when moving from a flat ground to an ascending slope)
function player_char:compute_closest_ceiling_query_info(sensor_position)
  assert(world.get_quadrant_x_coord(sensor_position, self.quadrant) % 1 == 0, "player_char:compute_closest_ceiling_query_info: sensor_position qx must be floored")

  -- oppose_dir since we check ceiling by detecting tiles q-above, and their q-column height matters
  --  when measured from the q-top (e.g. if there's a top half-tile maybe character head is not hitting it
  --  depending on the exact distance; if q-bottom based, it's considered reverse so full q-height and character
  --  head will hit it as soon as it enters the tile)

  -- top must be q-above bottom or we will get stuck in infinite loop
  -- (because to reduce tokens we compare locations directly instead of sub_qy(curr_tile_qj, last_tile_qy, quadrant_opp) >= 0
  --  which would ensure loop end)

  -- we must at least start checking ceiling 1 px above foot sensor (because when foot is just on top of tile,
  --  the current sensor tile is actually the tile *below* the character, which is often a full tile and will bypass
  --  ignore_reverse (see world.compute_qcolumn_height_at); in practice +4/+8 is a good offset, we pick max_ground_escape_height + 1 = 5
  --  because it allows us to effectively check the q-higher pixels not already checked in compute_closest_ground_query_info)

  -- finally, we check actual collision at head top position, so we pass an offset of self:get_full_height() (argument 5)
  --  from here, we need:
  --  - (max_ground_escape_height + 1 - full_height) offset for first tile according to explanation above + the fact that we consider this offset from sensor_position base + offset (full_height)
  --  - no offset for last tile since we end checking at head top exactly, so argument 3 is 0
  local full_height = self:get_full_height()
  -- the pc_data constant will be replaced in-line by replace_strings if game constant info is passed correctly
  --  ("text "..number.." text" will fail to pass luamin although correct, and adding tostr() is a waste)
  assert(pc_data.max_ground_escape_height + 1 - full_height <= 0, "max_ground_escape_height: pc_data.max_ground_escape_height is too high, risk of infinite loop (only ends thx to number wrapping), consider clamping start_tile_offset_qy")
  return iterate_over_collision_tiles(self, oppose_dir(self.quadrant), pc_data.max_ground_escape_height + 1 - full_height, 0, sensor_position, full_height, ceiling_check_collider_distance_callback, ceiling_check_no_collider_callback, --[[ignore_reverse_on_start_tile:]] true)
end

-- actual body of compute_closest_wall_query_info passed to iterate_over_collision_tiles
--  as no_collider_callback
-- defined before wall_check_no_collider_callback to make it callable from there
local function wall_check_no_collider_callback()
  -- end of iteration, and no wall found
  -- by convention pass a distance bigger than the raycast length (ceil(pc_data.ground_sensor_extent_x))
  return motion.ground_query_info(nil, ceil(pc_data.ground_sensor_extent_x) + 1, nil)
end

-- actual body of compute_closest_wall_query_info passed to iterate_over_collision_tiles
--  as collider_distance_callback
local function wall_check_collider_distance_callback(curr_tile_loc, signed_distance_to_closest_wall, slope_angle)
  -- note that we want to block character and floor its position (at least on qx) when just *entering* wall,
  --  not if just touching wall (makes left and right symmetrical), hence <
  if signed_distance_to_closest_wall < ceil(pc_data.ground_sensor_extent_x) then
    -- touching or inside wall
    return motion.ground_query_info(curr_tile_loc, signed_distance_to_closest_wall, slope_angle)
  else
    -- we noted in the ceiling version that maybe we should return like the check_no_collider_callback
    --  but didn't want to change the implementation on existing code yet
    -- wall detection is new though, so let's return the same as wall_check_no_collider_callback,
    --  running the risk of stopping the tile iteration early, as it may benefit CPU
    -- to spare characters, reuse no collider callback
    return wall_check_no_collider_callback()
  end
end

-- "raycast" from wall sensor_position: vector toward q-left or q-right
--  (based on quadrant_hdir: horizontal_dirs, itself based on movement direction relative to q-ground)
--  and return ground_query_info(tile_location, signed_distance, slope_angle)
--    - tile_location is the location of the detected tile (or nil), but it is not used for walls
--    - signed_distance is positive when not touching wall, negative when inside wall (and needs escape)
--      if nothing is detected, by convention we return ceil(pc_data.ground_sensor_extent_x) + 1
--      (1 above raycast length)
--    - slope_angle is the angle of the detected tile (or nil), but it is not used for walls
function player_char:compute_closest_wall_query_info(sensor_position, quadrant_hdir)
  -- collision_check_quadrant:
  -- if going q-left, we must detect collision in quadrant rotated 90 clockwise from q-down, else 90 counter-clockwise
  -- => self:get_horizontal(quadrant_hdir)

  -- start_tile_offset_qy: 0 since we already "raycast" from character center which should be far enough from the wall surface
  --  if character didn't "enter" wall at a speed too high (max ground speed is 3 though, so it may happen, be careful)

  -- last_tile_offset_qy: ceil(ground_sensor_extent_x) as we want to detect walls as close as the ground sensors
  --  can detect, as those would be blocking us (no need to +1 unless we absolutely want to detect walls on the
  --  absolute LEFT when we are just touching them; this particularity is due to dissymmetry of pixels,
  --  where a pixel position is considered to contain the bottom/right position but not the top/left one)

  -- sensor_position_base: the passed sensor_position
  --  note that we must simulate a motion big step to get the future next position, then check wall
  --  from that predicted position (and if we're blocked the real next position will be adjusted to touch wall)

  -- sensor_offset_qy: 0 since no offset required
  -- (there is an offset on qx though, which is already embedded in wall sensor position)

  return iterate_over_collision_tiles(self,
    --[[collision_check_quadrant]] self:get_horizontal(quadrant_hdir),
    --[[start_tile_offset_qy]] 0,
    --[[last_tile_offset_qy]] ceil(pc_data.ground_sensor_extent_x),
    --[[sensor_position_base]] sensor_position,
    --[[sensor_offset_qy]] 0,
    --[[collider_distance_callback]] wall_check_collider_distance_callback,
    --[[no_collider_callback]] wall_check_no_collider_callback--[[,]]
    --[[ignore_reverse_on_start_tile: false]])
end

-- verifies if character is inside ground, and push him upward outside if inside but not too deep inside
-- if ground is detected and the character can escape, update the slope angle with the angle of the new ground
-- if the character is too deep in ground and cannot escape, set tile to nil and angle to 0 by convention
-- if ground is detected but character was airborne, enter standing state
-- if no ground is detected, do nothing. Do not even enter airborne state. Either the caller must enter it
--  by default before calling this method, or they should count on the next frame update to start character fall.
-- note that unlike other escape methods, exceptionally we do care about the "touch" case
-- this is because the method is called after warp, where we'd like an instant landing (but that's optional,
--  character would fall and land in 1 frame without this anyway)
function player_char:check_escape_from_ground()
  local query_info = self:compute_ground_sensors_query_info(self.position)
  local signed_distance_to_closest_ground, next_slope_angle = query_info.signed_distance, query_info.slope_angle
  if - pc_data.max_ground_escape_height <= signed_distance_to_closest_ground and signed_distance_to_closest_ground <= 0 then
    -- character is either just touching ground (signed_distance_to_closest_ground == 0)
    --  or inside ground and enough close to surface to escape
    -- snap character q-upward to ground q-top (it does nothing if already touching ground)
    -- (we currently only check_escape_from_ground after a warp where quadrant is down,
    --  but this can prove useful if using this for ceiling adherence later; currently
    --  we just use a manual offset when landing on a non-down quadrant to fix
    --  #129 BUG MOTION curve_run_up_fall_in_wall as check_escape_from_ground even with quadrant
    --  gives a different result, pushing out too much and ending quadrant down again)
    local vector_to_closest_ground = signed_distance_to_closest_ground * self:get_quadrant_down()
    self.position:add_inplace(vector_to_closest_ground)
    -- register ground tile for later
    self:set_ground_tile_location(query_info.tile_location)
    -- set slope angle to new ground
    self:set_slope_angle_with_quadrant(next_slope_angle)

    -- if airborne, simulate landing
    -- if already grounded, don't change state in case we were rolling etc.
    --  (it never happends with pixel step motion, but it can with big step / frame by frame motion)
    if not self:is_grounded() then
      self:enter_motion_state(motion_states.standing)
    end
  end
  -- note: if inside ground but too deep to escape:
  -- convention v3 is to ignore ground completely is too deep inside
  --  to avoid walking with head on ceiling or inside one-way platform when a little too low
  -- since in this context we must not do anything when no ground is detected, do nothing
end

-- enter motion state, reset state vars appropriately
-- refactor: consider separate methods go_airborne or land
--  so you can pass more specific arguments
-- current, self.slope_angle must have been previously set when
--  entering ground state
function player_char:enter_motion_state(next_motion_state)
  -- store previous grounded/compact state before changing motion state
  local was_grounded = self:is_grounded()
  local was_compact = self:is_compact()

  -- update motion state
  self.motion_state = next_motion_state

  -- adjust center when switching compact mode
  if was_compact ~= self:is_compact() then
    -- character switched compact mode, prepare center adjustment vector
    local become_compact_qdown_vector = self:quadrant_rotated(vector(0, pc_data.center_height_standing - pc_data.center_height_compact))
    -- if character became compact (e.g. crouching or start jumping),
    --  move it slightly down to keep center position continuity
    --  => multiplier = 1, use qdown vector directly
    -- if character is now standing (e.g. landing after air spin),
    --  move it slightly up to keep center position continuity
    --  => multiplier = -1, oppose qdown vector to get qup vector
    local multiplier = was_compact and -1 or 1
    self.position:add_inplace(multiplier * become_compact_qdown_vector)
  end

  -- update state vars like slope, etc. *after* adjusting center
  --  because center adjustment on fall relies on quadrant *before* falling
  --  (it's is always down after fall anyway)
  -- when landing, we set the slope angle *before* calling this method,
  --  so quadrant is also correct when quadrant_rotated is called
  if next_motion_state == motion_states.falling then
    -- we have just left the ground without jumping, enter falling state
    --  and since ground speed is now unused, reset it for clarity
    self.ground_tile_location = nil
    self:set_slope_angle_with_quadrant(nil)
    self.ground_speed = 0
    self.should_jump = false
    -- don't reset brake_anim_phase, Sonic can play brake anim while falling!
  elseif next_motion_state == motion_states.air_spin then
    -- we have just jumped, enter air_spin state
    --  and since ground speed is now unused, reset it for clarity
    self.ground_tile_location = nil
    self:set_slope_angle_with_quadrant(nil, --[[force_upward_sprite:]] true)
    self.ground_speed = 0
    self.should_jump = false
    self.should_play_spring_jump = false
  elseif next_motion_state == motion_states.standing then
    if not was_grounded then
      -- Momentum: transfer part of airborne velocity tangential to slope to ground speed (self.slope_angle must have been set previously)
      --  using a projection on the ground
      -- do not clamp ground speed! this allows us to spin dash, fall a bit, land and run at high speed!
      -- SPG (https://info.sonicretro.org/SPG:Slope_Physics#Reacquisition_Of_The_Ground) says original calculation either preserves vx or
      --  uses vy * sin * some factor depending on angle range (possibly to reduce CPU)
      --  but for now we keep this as it's physically logical and feels good enough
      -- The difference is very perceptible when jumping on the first two slopes of pico island
      -- - When landing on the first, very low slope with vx = 0 Sonic will retain momentum and descend left,
      --   while in Sonic 3 he would stop moving at once
      -- - When landing on the second slope, resulting velocity will smoothly change with vx, going through 0,
      --   while in Sonic 3, the behavior completely changes when |vx| crosses |vy|: when going to the left fast enough,
      --   Sonic will only preserve vx and keep going to the left; when going not fast enough, vy * sin is used
      --   and Sonic goes down to the right; he can never just stop.
      self.ground_speed = self.velocity:dot(vector.unit_from_angle(self.slope_angle))

      -- immediately update velocity to avoid keeping old air velocity while grounded,
      --  which would result in chained jump being very low, or even going downward, due to
      --  downward velocity remaining when cumulated with jump impulse
      self.velocity:copy_assign(self:compute_velocity_from_ground_speed())

      -- we have just reached the ground (and possibly escaped),
      --  reset values airborne vars
      self.has_jumped_this_frame = false  -- optional since consumed immediately in update_platformer_motion_airborne
      self.can_interrupt_jump = false
      self.should_play_spring_jump = false
    end
  elseif next_motion_state == motion_states.rolling then
    -- we don't have code to preserve airborne tangential velocity here because we cannot really land and immediately roll
    --  without going through the standing state (even Sonic 3 shows Sonic in standing sprite for 1 frame);
    --  and Sonic Mania's Drop Dash would probably ignore previous velocity anyway
    if not was_grounded then
      -- we have just reached the ground (and possibly escaped),
      --  reset values airborne vars
      self.has_jumped_this_frame = false  -- optional since consumed immediately in update_platformer_motion_airborne
      self.can_interrupt_jump = false
      self.should_play_spring_jump = false
    end
  end

  -- reset brake anim unless standing (actually walking) or falling (which exceptionally allows brake anim)
  -- the most common case is to brake, then immediately try to crouch to roll -> we should show roll animation
  if next_motion_state ~= motion_states.standing and next_motion_state ~= motion_states.falling then
    self.brake_anim_phase = 0
  end

  -- reset late jump timer if not falling any more
  if next_motion_state ~= motion_states.falling then
    self.time_left_for_late_jump = 0
  end
end

function player_char:update_collision_timer()
  if self.ignore_launch_ramp_timer > 0 then
    self.ignore_launch_ramp_timer = self.ignore_launch_ramp_timer - 1
  end
end

-- update velocity, position and state based on current motion state
function player_char:update_platformer_motion()
  -- SPG note: http://info.sonicretro.org/SPG:Main_Game_Loop
  -- I started working on this before this page appeared though, so the order may not exactly be the same
  -- Nevertheless, it's working quite well.

  -- check for jump before apply motion, so character can jump at the beginning of the motion
  --  (as in classic Sonic), but also apply an initial impulse if character starts idle and
  --  left/right is pressed just when jumping (to fix classic Sonic missing a directional input frame there)
  -- In the original game, pressing down and jump at the same time gives priority to jump.
  --  Releasing down and pressing jump during crouch gives also priority to spin dash.
  --  So checking jump before crouching is the correct order (you need 2 frames to crouch, then spin dash)
  if self:is_grounded() or self.time_left_for_late_jump > 0 then
    if self.time_left_for_late_jump > 0 then
    end
    self:check_jump()  -- this may change the motion state to air_spin and affect branching below
    self:check_spin_dash()  -- this is exclusive with jumping, so there is no order conflict
  end

  -- decrement late jump timer if positive
  -- make sure to do this *after* checking it above and *before* update_platformer_motion_grounded
  -- because if we decrement it before checking it above, on the last frame allowed for late jump (time == 1),
  --  we will call check_jump_intention (see below) but we need an extra frame to confirm the jump
  --  and on the next update_platformer_motion, time == 0 and we won't enter the block above
  -- if we decrement it after update_platformer_motion_grounded (before check_jump_intention),
  --  since it can set time_left_for_late_jump, that would immediately decrement the initial value
  --  so we'd need to add +1 to optional_jump_delay_after_fall (and we want initial value 1 to work already)
  if self.time_left_for_late_jump > 0 then
    self.time_left_for_late_jump = self.time_left_for_late_jump - 1
  end

  -- do not move check below inside the is_grounded() check above,
  --  to clearly show that the state may have changed and we check it properly again
  --  (even though ultimately, the current checks are all about grounded states)
  if contains({motion_states.standing, motion_states.crouching}, self.motion_state) then
    self:check_crouch_and_roll_start()
  elseif self.motion_state == motion_states.rolling then
    self:check_roll_end()
  end

  if self:is_grounded() then
    self:update_platformer_motion_grounded()
  else
    self:update_platformer_motion_airborne()
  end

  -- only allow jump preparation for next frame if still grounded,
  --  or started falling recently with late jump feature enabled
  if self:is_grounded() or self.time_left_for_late_jump > 0 then
    if self.time_left_for_late_jump > 0 then
    end
    self:check_jump_intention()
  end

--#if ingame

--#if busted
  if flow.curr_state.type == ':stage' then
--#endif
    self:check_spring()
    self:check_launch_ramp()
    self:check_emerald()
    self:check_loop_external_triggers()
--#if busted
  end
--#endif

--(ingame)
--#endif
end

-- Check if character wants to crouch (move pure down) or stop crouching (release down or move horizontally).
-- If crouching and moving fast enough, he will roll.
-- We assume character is standing on ground or crouching.
function player_char:check_crouch_and_roll_start()
  -- Check move intention down (as in the original down, no horizontal direction must be pressed)
  if self:wants_to_crouch() then
    -- if character is walking fast enough, he will roll; else, he will crouch
    -- if character is already crouching and starts sliding at high speed because of a slope,
    --  rolling also starts; else, do nothing, character just keeps crouching (can slide at low speed)
    if abs(self.ground_speed) >= pc_data.roll_min_ground_speed then
      -- currently enter_motion_state from standing to rolling will do nothing more than set the state
      --  but we call it so we have a centralized place to add other side effects or cleanup if needed
      self:enter_motion_state(motion_states.rolling)
      self:play_low_priority_sfx(audio.sfx_ids.roll)
    elseif self.motion_state ~= motion_states.crouching then
      -- same remark as above, no side effect as crouch is really like standing state except
      --  it shrinks the hitbox and allows spin dash
      self:enter_motion_state(motion_states.crouching)
    end
  elseif self.motion_state ~= motion_states.standing then
    self:enter_motion_state(motion_states.standing)
  end
end

-- check if character is too slow enough to continue rolling
-- if so, stop rolling
-- we assume character is rolling on ground
function player_char:check_roll_end()
  if abs(self.ground_speed) < pc_data.continue_roll_min_ground_speed then
    -- currently enter_motion_state from rolling to standing will do nothing more than set the state
    --  but we call it so we have a centralized place to add other side effects or cleanup if needed
    self:enter_motion_state(motion_states.standing)
  end
end

-- update motion following platformer grounded motion rules
function player_char:update_platformer_motion_grounded()
  -- SPG note: http://info.sonicretro.org/SPG:Main_Game_Loop
  -- I started working on this before this page appeared though, so the order may not exactly be the same
  -- Nevertheless, it's working quite well.

  self:update_ground_speed()

  local ground_motion_result = self:compute_ground_motion_result()

  -- reset ground speed if blocked
  if ground_motion_result.is_blocked then
    self.ground_speed = 0
  end

  -- check for stage left edge soft block
  -- normally we'd compute ground sensor position with q-left and q-right vectors
  --  but since left side of level is always flat, we don't mind
  if flr(ground_motion_result.position.x) < pc_data.ground_sensor_extent_x then
    -- clamp position to stage left edge
    -- note that in theory we should update the ground motion result
    --  tile location and slope angle to match the new position,
    --  but in practice we know that speeds are low and besides there is
    --  nothing on the left of the stage, so basically we are not changing
    --  ground tile here
    ground_motion_result.position.x = ceil(pc_data.ground_sensor_extent_x)
    -- also clamp ground speed to a very small negative value
    --  (btw it is probably already negative since we're going left)
    --  to preserve Sonic's running animation at the slowest playback speed
    --  to match original game's behavior
    --  and also to make it continue trying to cross the stage boundary
    --  and enter this block next frame, until player stops moving
    self.ground_speed = max(-0.1, self.ground_speed)
  end

  if self.ground_speed ~= 0 then
    -- set animation speed for run now, since it can be used during actual run on ground
    --  but also after falling (from cliff or ceiling) in which case the playing speed is preserved
    -- (according to SPG, in original game, ground speed in preserved when airborne, so they use it directly
    --  for airborne animations)
    -- for the run playback speed, we don't follow the SPG which uses flr(max(0, 8-abs(self.ground_speed)))
    --  instead, we prefer the more organic approach of continuous playback speed
    -- however, to simulate the max duration clamping, we use min playback speed clamping
    --  (this prevents Sonic sprite from running super slow, bad visually)
    self.anim_run_speed = abs(self.ground_speed)
  else
    -- character is really idle, we don't want a minimal playback speed
    self.anim_run_speed = 0
  end

  -- update velocity based on new ground speed and old slope angle (positive clockwise and top-left origin, so +cos, -sin)
  -- we must use the old slope because if character is leaving ground (falling)
  --  this frame, new slope angle will be nil
  self.velocity:copy_assign(self:compute_velocity_from_ground_speed())

  -- update position
  self.position:copy_assign(ground_motion_result.position)

  -- character falls by default if finds no ground to stick to
  local should_fall = ground_motion_result.is_falling

  -- SPG: Falling and Sliding Off Of Walls And Ceilings
  -- if we are already falling due to lack of ground, do not check this
  -- this means we won't trigger horizontal control lock even if going under adherence speed if falling naturally this frame
  if not should_fall and self.quadrant ~= directions.down and abs(self.ground_speed) < pc_data.ceiling_adherence_min_ground_speed then
    -- Only falling when on straight wall, wall-ceiling or ceiling
    -- Note that at this point, we haven't set slope angle and we were grounded so it should not be nil
    if self.slope_angle >= 0.25 and self.slope_angle <= 0.75 then
      should_fall = true
    end
    self.horizontal_control_lock_timer = pc_data.fall_off_horizontal_control_lock_duration
  end

  if should_fall then
    local new_state

    -- if enabling late jump, track frames after falling naturally from ground (no spring jump, etc. which is
    --  done elsewhere in code). This also applies to rolling -> falling with air_spin.
    -- note that it's the only place where we check for the feature. In other places, we keep decrementing the timer
    --  and applying late jump. This is simpler and avoids having a frozen timer that is resumed later in bad places.
--#ifn attract_mode
    -- picosonic_app_attract_mode doesn't have get_enable_late_jump_feature, and we want
    --  the attract mode recording the always play the same way anyway, so just skip the test altogether
    if flow.curr_state.app.get_enable_late_jump_feature() then
--#endif
      self.time_left_for_late_jump = pc_data.late_jump_max_delay

      -- track slope angle of current ground before we clear it due to fall/jump
      --  so we can do the late jump with the correct angle (otherwise, running off a rising curve + late jumping
      --  sends character to tremendous heights)
      -- this must be called before enter_motion_state so slope_angle is still set!
      -- note that we don't clear it even when time_left_for_late_jump reaches 0 to spare characters,
      --  as we won't be using when not doing late jump
      self.late_jump_slope_angle = self.slope_angle
--#ifn attract_mode
    end
--#endif

    -- in the original game, Sonic keeps crouching and spin dash during fall (possible using crouch slide
    --  or spin dashing on crumbling ground), but you cannot release spin dash during the fall...
    -- this is very rare, and we don't want to handle the case of air crouching to prevent spin dashing,
    --  so we just switch to normal fall in this case (and air_spin for spin_dashing, but there is
    --  no crumbling ground in the level and spin dash freezes velocity X, so this cannot even happen)
    if contains({motion_states.standing, motion_states.crouching}, self.motion_state) then
      new_state = motion_states.falling
    else  -- self.motion_state == motion_states.rolling or self.motion_state == motion_states.spin_dashing
      -- roll fall is like an air_spin without can_interrupt_jump (nor double jump in Sonic 3)
      new_state = motion_states.air_spin
    end
    self:enter_motion_state(new_state)
  else
    -- we are still grounded, so:

    -- update ground tile (if needed)
    self:set_ground_tile_location(ground_motion_result.tile_location)

    -- update slope angle (if needed)
    self:set_slope_angle_with_quadrant(ground_motion_result.slope_angle)

    -- we moved self:check_jump_intention() to after calling this method
    --  because of the new time_left_for_late_jump
  end

  log("self.position: "..self.position, "trace")
  log("self.position.x (hex): "..tostr(self.position.x, true), "trace")
  log("self.position.y (hex): "..tostr(self.position.y, true), "trace")
  log("self.velocity: "..self.velocity, "trace")
  log("self.velocity.x (hex): "..tostr(self.velocity.x, true), "trace")
  log("self.velocity.y (hex): "..tostr(self.velocity.y, true), "trace")
  log("self.ground_speed: "..self.ground_speed, "trace")
end

-- update ground speed
function player_char:update_ground_speed()
  -- We apply slope factor *before* move intention because it gives
  --  better results when not moving on a low slope (friction will stop you completely).
  -- Another side effect is that the ground speed *after* slope factor application
  --  will be considered for the move intention effect, such as using ground active deceleration
  --  when moving forward on an ascending slope if it started make you move down.
  -- Disabled Original Slope Feature Note:
  --  Also, if ground speed is 0 and we start trying to ascend slope,
  --  Progressive Ascending Steep Slope Factor feature won't be applied the first frame.
  -- But it should be OK overall.
  -- Note that this order is supported by the SPG (http://info.sonicretro.org/SPG:Solid_Tiles)
  if contains({motion_states.standing, motion_states.crouching}, self.motion_state) then
    local previous_ground_speed = self.ground_speed
    self:update_ground_speed_by_slope()
    -- the two below are not needed for crouching:
    --  - there should be no move intention x with crouch
    --  - high speed will turn crouch into roll, so crouch only has low speed
    -- but it takes fewer characters not to add an extra check... and it shouldn't take much extra CPU
    self:update_ground_run_speed_by_intention()
    self:clamp_ground_speed(previous_ground_speed)
  elseif self.motion_state == motion_states.rolling then
    self:update_ground_speed_by_slope()
    self:update_ground_roll_speed_by_intention()
    -- There is some particular clamping based on speed X in the original game,
    --  with max speed 8 (in PICO-8 scale). SPG suggests to apply clamping to ground speed instead,
    --  or not at all. Right now there's no place in the level where you'd go overspeed,
    --  actually you'd rather try to get as much speed as possible to get past the loops,
    --  so we are not clamping roll speed at all. Otherwise we'd probably just clamp ground speed to 8.
  -- else  -- self.motion_state == motion_states.spin_dashing
    -- do nothing so ground speed is frozen, as in the original game (crouch and spin dash just before
    --  falling down after trying to climb up a slope with not enough momentum to reproduce)
  end
end

-- update ground speed based on current slope
function player_char:update_ground_speed_by_slope()
  local is_ascending_slope = false

  -- below does nothing if self.slope_angle == 0,
  --  but we removed that check just to spare some characters

--#if original_slope_features

  -- Original feature (not in SPG): Progressive Ascending Steep Slope Factor
  --  If character is ascending a slope, do not apply the full slope factor immediately.
  --  Instead, linearly increase the applied slope factor from 0 to full over a given duration.
  --  We use the ground speed before applying intention to avoid exploid of spamming
  --  the left/right (ascending) input to restart the timer thanks to the ground speed
  --  being slightly increased by the intention, but actually countered by slope accel in the same frame.
  -- Effect: the character can completely cross steep but short slopes
  -- Resolves: character was suddenly stopped by longer slopes when starting ascension with low momentum,
  --  falling back to the flat ground behind, and repeating, causing a glitch-like oscillation
  local ascending_slope_factor = 1
  -- make sure to compare sin in abs value (steep_slope_min_angle is between 0 and 0.25 so we know its sin is negative)
  --  since slope angle is module 1 and cannot be directly compared (and you'd need to use (slope_angle + 0.5) % 1 - 0.5 to be sure)
  if self.ground_speed ~= 0 and abs(sin(self.slope_angle)) >= sin(-pc_data.steep_slope_min_angle) and sgn(self.ground_speed) ~= sgn(sin(self.slope_angle)) then
    is_ascending_slope = true
    local ascending_slope_duration = pc_data.progressive_ascending_slope_duration
    local progressive_ascending_slope_factor = 1
    -- increase tracking time every frame
    self.ascending_slope_time = min(self.ascending_slope_time + delta_time60, ascending_slope_duration)
    ascending_slope_factor = self.ascending_slope_time / ascending_slope_duration
  else
    -- reset ascending slope time
    self.ascending_slope_time = 0
  end
  self.ground_speed = self.ground_speed + ascending_slope_factor * pc_data.slope_accel_factor_frame2 * sin(self.slope_angle)

--#else
--[[#pico8

  -- slope angle is mostly defined with atan2(dx, dy) which follows top-left origin BUT counter-clockwise angle convention
  -- sin also follows this convention, so ultimately + is OK
  self.ground_speed = self.ground_speed + pc_data.slope_accel_factor_frame2 * sin(self.slope_angle)

--#pico8]]
--#endif
end

-- update ground speed while standing based on current move intention
function player_char:update_ground_run_speed_by_intention()
  -- set default new ground speed in case we don't enter any block (totally idle)
  local new_ground_speed = self.ground_speed

  if self.move_intention.x ~= 0 then

    if self.ground_speed == 0 or sgn(self.ground_speed) == sgn(self.move_intention.x) then
      -- accelerate
     new_ground_speed = self.ground_speed + self.move_intention.x * pc_data.ground_accel_frame2
      -- face move direction if not already (this does something when starting running in the opposite
      --  direction of the faced on from idle, and when character is already running backward
      --  e.g. after a reverse jump, and player presses actual forward direction)
      self.orientation = signed_speed_to_dir(self.move_intention.x)
      -- if character started braking (phase 1) then moved forward again, we should stop braking animation
      -- don't interrupt the brake reverse anim (phase 2) though, since it will naturally chain with
      --  a forward acceleration after reverse
      if self.brake_anim_phase == 1 then
        self.brake_anim_phase = 0
      end
    else

--#if original_slope_features

      -- Original feature (not in SPG): Reduced Deceleration on Steep Descending Slope
      --  Apply a fixed factor
      -- Effect: a character descending a steep slope will take more time to brake than if
      --  considering slope factor alone
      -- Resolves: character descending a steep slope was braking and turning back too suddenly
      local ground_decel_factor = 1
      -- make sure to compare sin in abs value (steep_slope_min_angle is between 0 and 0.25 so we know its sin is negative)
      --  since slope angle is module 1 and cannot be directly compared (and you'd need to use (slope_angle + 0.5) % 1 - 0.5 to be sure)
      if abs(sin(self.slope_angle)) >= sin(-pc_data.steep_slope_min_angle) and sgn(self.ground_speed) == sgn(sin(self.slope_angle)) then
        -- character is trying to brake on a descending slope
        ground_decel_factor = pc_data.ground_decel_descending_slope_factor
      end

      -- decelerate
      new_ground_speed = self.ground_speed + self.move_intention.x * ground_decel_factor * pc_data.ground_decel_frame2

--#else
--[[#pico8

      -- decelerate
      new_ground_speed = self.ground_speed + self.move_intention.x * pc_data.ground_decel_frame2

--#pico8]]
--#endif

      -- check if speed has switched sign this frame, i.e. character has turned around
      -- since adding brake_reverse we slightly change edge case handling: if ground speed reaches 0 this frame
      --  we consider the turn around is complete and switch orientation
      -- this makes it easier when brake_start is played to immediately chain with brake_reverse
      -- otherwise, we would enter the neutral case next frame (ground speed starts at 0, always accelerate)
      --  and would need a special condition in accel code (sgn(self.move_intention_x) ~= horizontal_dir_signs[self.orientation] sign)
      --  to detect entering brake reverse phase after going by accident through ground speed 0
      -- we prefer centralizing that code in the decel, hence considering sign reversal at 0 too
      -- of course, clamping will never be applied in that case
      local has_changed_sign = new_ground_speed == 0 or sgn(new_ground_speed) == sgn(self.move_intention.x)
      if has_changed_sign then
        -- clamp speed after turn around by ground accel in absolute value to prevent exploit of
        --  moving back 1 frame then forward to gain an initial speed boost (mentioned in Sonic Physics Guide as a bug)
        if abs(new_ground_speed) > pc_data.ground_accel_frame2 then
          new_ground_speed = sgn(new_ground_speed) * pc_data.ground_accel_frame2
        end
        -- turn around
        self.orientation = signed_speed_to_dir(self.move_intention.x)
        -- only when changing sign via decel after brake start anim:
        --  finalize brake anim with brake reverse phase
        --  it will stop naturally after its full anim duration, or if jumping, etc.
        --  and stopping at exactly ground speed 0 will not reset this to idle, we'll just finish the anim first
        -- This differs from Sonic 3 which plays brake_reverse automatically at the end of brake_start
        --  while still with the same orientation, but the brake3 sprite itself has been flipped X
        --  but in practice, it only shows when you brake and release input, showing a sprite in the wrong direction
        --  for a few frames as you continue going forward; this is because as soon as you change orientation
        --  (or if you press forward input again), intention matches ground speed again so the normal walk/run anim
        --  is played, and brake_reverse is essentially skipped. So I prefer my 2-phase implementation.
        if self.brake_anim_phase == 1 then
          self.brake_anim_phase = 2
        end
      -- check if character was fast enough, and on quadrant down, to play brake anim
      --  (it certainly wasn't the case if we changed sign)
      elseif self.quadrant == directions.down and abs(self.ground_speed) >= pc_data.brake_anim_min_speed_frame then
        -- this will be entered many frames if decelerating from a very high speed,
        --  but the anim_spr:play() will know not to restart the animation
        -- flip subtlety: to make sense, the brake_start animation must be oriented toward
        --  ground speed, so in case Sonic was running backward (e.g. after fast reverse jump)
        --  and is braking, we must flip it back to ground speed dir
        self.orientation = signed_speed_to_dir(self.ground_speed)
        self.brake_anim_phase = 1

        self:play_low_priority_sfx(audio.sfx_ids.brake)
      end
    end
  else
    if self.ground_speed ~= 0 then
      -- no move intention, character is passive

--#if original_slope_features

      -- Original feature (not in SPG): No Friction on Steep Descending Slope
      --  Do not apply friction when character is descending a steep slope passively;
      --  In other words, apply it only on flat ground, low slope and only steep slopes if ascending
      -- Effect: the character will automatically run down a steep slope and accumulate acceleration downward
      --  without friction
      -- Resolves: the character was moving down a steep slope very slowly because of friction
      -- make sure to compare sin in abs value (steep_slope_min_angle is between 0 and 0.25 so we know its sin is negative)
      --  since slope angle is module 1 and cannot be directly compared (and you'd need to use (slope_angle + 0.5) % 1 - 0.5 to be sure)
      if abs(sin(self.slope_angle)) <= sin(-pc_data.steep_slope_min_angle) or sgn(self.ground_speed) ~= sgn(sin(self.slope_angle)) then
        new_ground_speed = sgn(self.ground_speed) * max(0, abs(self.ground_speed) - pc_data.ground_friction_frame2)
      end

--#else
--[[#pico8

      new_ground_speed = sgn(self.ground_speed) * max(0, abs(self.ground_speed) - pc_data.ground_friction_frame2)

--#pico8]]
--#endif

    end

    -- whether still in friction or completely stopped, if the brake_start anim has finished
    --  and player stopped inputting on x, we should stop the brake_start anim
    if self.brake_anim_phase == 1 and not self.anim_spr.playing then
      self.brake_anim_phase = 0
    end
  end

  self.ground_speed = new_ground_speed
end

-- update ground speed while rolling based on current move intention
function player_char:update_ground_roll_speed_by_intention()
  -- rolling differs from running as we always apply friction
  --  then we also apply deceleration is input opposes ground speed
  -- in addition, we are almost certain that there is some ground speed > 0.14 if we are rolling, even if we are on a steep slope,
  --  considering continue_roll_min_ground_speed > gravity_frame2 (by ~0.14) and we unroll as soon as we go under continue_roll_min_ground_speed
  -- so we go straightforward and apply friction (+ decel) and just clamp at 0 as a safety measure
  local abs_decel = pc_data.ground_roll_friction_frame2

  if self.ground_speed ~= 0 and self.move_intention.x ~= 0 then
    if sgn(self.ground_speed) ~= sgn(self.move_intention.x) then
      -- decelerate
      abs_decel = abs_decel + pc_data.ground_roll_decel_frame2
    else  -- sgn(self.ground_speed) == sgn(self.move_intention.x)
      -- the only possible effect of pressing the forward direction during a roll,
      --  is when we are rolling backward, as it corrects the orientation to forward (as when running backward)
      --  but it doesn't affect physics
      self.orientation = signed_speed_to_dir(self.move_intention.x)
    end
  end

  self.ground_speed = sgn(self.ground_speed) * max(0, abs(self.ground_speed) - abs_decel)
end

-- clamp ground speed to max (standing only, not rolling), or to previous ground speed
--  in absolute value if it was already above max
function player_char:clamp_ground_speed(previous_ground_speed)
  -- it's unlikely that the character switched ground speed sign at a very high magnitude,
  --  so simply consider the previous abs ground speed as the new limit, if higher than usual limit
  local max_ground_speed = max(abs(previous_ground_speed), pc_data.max_running_ground_speed)
  if abs(self.ground_speed) > max_ground_speed then
    self.ground_speed = sgn(self.ground_speed) * max_ground_speed
  end
end

-- return velocity when grounded based on slope
-- self.ground_speed and self.slope_angle must be set
function player_char:compute_velocity_from_ground_speed()
  return self.ground_speed * vector.unit_from_angle(self.slope_angle)
end

-- return {next_position: vector, is_blocked: bool, is_falling: bool} where
--  - next_position is the position of the character next frame considering his current ground speed
--  - is_blocked is true iff the character encounters a wall during this motion
--  - is_falling is true iff the character leaves the ground just by running during this motion
function player_char:compute_ground_motion_result()
  assert(self.ground_tile_location, "compute_ground_motion_result: self.ground_tile_location not set")

  -- if character is not moving, immediately return result with same position,
  --  ground location, slope angle, not blocked nor falling (we assume the environment is static)
  if self.ground_speed == 0 then
    return motion.ground_motion_result(
      self.ground_tile_location:copy(),
      self.position:copy(),
      self.slope_angle,
      false,
      false
    )
  end

  -- SPG note: http://info.sonicretro.org/SPG:Main_Game_Loop
  -- We're following the indicated order by checking ground BEFORE wall (and updating quadrant for wall check)
  --  because it prevented stepping up on tiles of height 6 (wall sensor height) to 7 (max ground escape height)
  --  like the spring oriented up.
  -- But we added an EXTRA wall check AFTER ground check, using the new quadrant (and position),
  --  to avoid wall raycasting into what was previously a wall, but is now a ground, when moving at fast speed
  --  (esp. with spin dash) inside a loop.
  -- I also tried checking wall AFTER ground check but NOT BEFORE. It still required me to increase the
  --  max escape distance to 8, and character was stepping up springs (unless moving by less than 1 pixel into them).
  -- In addition, we're not checking roll here, we're doing this earlier, at the same time as checking spin dash

  -- Big step method:
  -- 1. apply full velocity to get hypothetical position next frame in the absence of collisions
  -- 2. check for wall collisions (only recognized if started entering wall)
  -- 3. check for ground collisions (with new position from 2) to snap to / escape from ground,
  --    or fall if no ground / angle difference too big
  -- 4. if found wall and changed quadrant, check for wall collisions again (with new position and quadrant from 3) and cancel wall detection
  --    if not touching wall (this time, we recognize touching wall as collision since 2 made us escape)

  local is_falling = false
  local previous_quadrant = self.quadrant
  local quadrant_horizontal_dir = signed_speed_to_dir(self.ground_speed)

  -- Step 1: future position prediction

  -- Compute next position after velocity is applied, if there were no obstacles
  -- We have *not* updated self.velocity yet at this point (compute_velocity_from_ground_speed will
  --  do it after checking if blocked so it knows if it should force set velocity to 0),
  --  but we can still compute the expected velocity in the absence of collisions in advance,
  --  using compute_velocity_from_ground_speed
  local next_position = self.position + self:compute_velocity_from_ground_speed()

  -- Step 2: 1st wall check (always)

  -- do a wall raycast in the q-direction of ground speed
  local is_blocked = self:check_escape_wall_and_update_next_position(next_position, quadrant_horizontal_dir)

  -- Step 2: ground check

  -- check if next position is inside/above ground
  local query_info = self:compute_ground_sensors_query_info(next_position)
  local signed_distance_to_closest_ground = query_info.signed_distance
  log("signed_distance_to_closest_ground: "..signed_distance_to_closest_ground, "trace2")

  -- signed distance is useful, but for quadrant vector ops we need actual vectors
  --  to get the right escape motions (e.g. on floor, signed distance > 0 <=> offset dy < 0 from ground,
  --  but on left wall, signed distance > 0 <=> offset dx > 0)
  -- signed distance is from character to ground, so get unit vector for quadrant down
  local vector_to_closest_ground = signed_distance_to_closest_ground * self:get_quadrant_down()

  if signed_distance_to_closest_ground < 0 then
    -- Next position is inside ground, but are we close to surface enough?
    if - signed_distance_to_closest_ground <= pc_data.max_ground_escape_height then
      -- Close enough to surface => Step up
      next_position:add_inplace(vector_to_closest_ground)
    end
  elseif signed_distance_to_closest_ground >= 0 then
    -- Next position is above or just touching ground, should we leave ground or step down?
    if signed_distance_to_closest_ground <= pc_data.max_ground_snap_height then
      -- Close enough to step down, but first check angle difference

      -- Original slope feature: Take-Off Angle Difference
      -- When character could normally step down, but the new ground has an angle too low
      --  compared to the previous ground, character still falls off.
      -- Exceptionally not inside --#if original_slope_features because it fixes character NOT falling off
      --  the first curved slope (before the 1st spring) when running or even spin dashing to the left
      --  (no ugly glitch, but Sonic literally sticks to the ground unless the speed is so high that
      --  the big step goes too far to detect the slope's first tile on the first frame leaving the ground)
      -- In the original, Sonic just runs on the steep descending slope as if nothing, and also exceptionally
      --  preserves his sprite angle, but that would have required extra code. Besides, when running fast and spin dashing
      --  he's actually falling off.
      -- When running toward the left, angle diff has opposite sign, so multiply by horizontal sign to counter this
      -- Note that character was grounded last frame since we're calling compute_ground_motion_result,
      --  so self.slope_angle is not nil
      local signed_angle_delta = compute_signed_angle_between(query_info.slope_angle, self.slope_angle)

      -- note the `>` comparison: if difference is just at threshold, we don't fall-off
      if horizontal_dir_signs[quadrant_horizontal_dir] * signed_angle_delta > pc_data.take_off_angle_difference then
        -- Step fall due to angle difference aka angle-based Take-Off
        is_falling = true
      else
        -- Step down
        next_position:add_inplace(vector_to_closest_ground)
      end
    else
      -- Ground is too far to step down, fall
      is_falling = true
    end
  end

  -- don't reverse that ternary! `and nil or ...` won't work!
  local next_ground_tile_location = not is_falling and query_info.tile_location or nil

  -- Step 4: 2nd wall check (only if found wall in step 2, but found ground with different quadrant in step 3)

  -- At this point self.quadrant has not been changed YET, but we can still
  --  predict it from the slope angle to compare previous and new quadrant
  -- Note that even if we don't enter this block and update quadrant now, it will be updated
  --  by the caller of this method afterward
  if is_blocked and previous_quadrant ~= world.angle_to_quadrant(query_info.slope_angle) then
    -- Since we want to apply wall check with new quadrant, to make it meaningful we must update the ground tile location
    --  so the raycasts are more likely to be oriented toward the new character forward and not hit unwanted ground as wall
    self:set_ground_tile_location(next_ground_tile_location)

    -- In principle we should also update the slope angle to be consistent, but check_escape_wall_and_update_next_position
    --  doesn't use it anyway, so we commented out to spare characters, but kept for understanding
    -- if is_falling then
    --   self:set_slope_angle_with_quadrant(nil)
    -- else
    --   self:set_slope_angle_with_quadrant(query_info.slope_angle)
    -- end

    is_blocked = self:check_escape_wall_and_update_next_position(next_position, quadrant_horizontal_dir)

    -- what's interesting is that we noticed that not doing all of this
    --  (set_ground_tile_location + check_escape_wall_and_update_next_position)
    --  and just clearing flag: is_blocked = false
    -- works too, thx to the quadrant check: we don't change quadrant often, and if we do,
    --  we can tolerate ignoring walls and going through for 1 frame; the next frame is unlikely to
    --  change quadrant *again*, and therefore will detect any wall normally
    -- OPTIMIZE CHARS: so consider this alternative if you need to release more characters,
    --  as it showed no issues in the game (and it even passes our utest to fix #265, as long as you only
    --  check the final result and not count spy calls!)
  end

  -- make sure to only pass tile location if not falling, to avoid assert on invalid result construction
  local motion_result = motion.ground_motion_result(
    next_ground_tile_location,
    next_position,
    query_info.slope_angle,
    is_blocked,
    is_falling
  )

  return motion_result
end

-- check for wall in relative quadrant_horizontal_dir when character center is at next position
-- update next position in-place to escape any wall entered
-- return true if escaping wall this way, else falsy value
function player_char:check_escape_wall_and_update_next_position(next_position, quadrant_horizontal_dir)
  local sensor_position_base = self:get_wall_sensor_position_from(next_position)
  local wall_query_info = self:compute_closest_wall_query_info(sensor_position_base, quadrant_horizontal_dir)

  if wall_query_info.tile_location then
    -- We detected a wall, but it doesn't mean we should stop:
    -- a. future position may be just touching a wall on the right (when raycasting over ceil(pc_data.ground_sensor_extent_x)
    --  we can only detect touched walls on the right due to pixel asymmetry)
    --  we ignore his case by checking `< ceil(pc_data.ground_sensor_extent_x)` (although stopping right at that distance is no big deal)
    --  OPTIMIZE CHARS: you can remove this condition if too tight on budget
    -- b. future position may be "too much inside wall to escape". Actually, we should try to escape anyway,
    --  but in this case we shouldn't because of a quirk in the detection: we detect the tile in the start position
    --  of the raycast, so if an object collision mask partially occupies a tile, like the left part of the spring oriented up,
    --  and we have our back turned to that object, we are actually still detecting it BEHIND us with a big negative distance
    --  like -7.5 as if we were inside. Therefore, trying to escape this would drag the character backward into the spring.
    --  To fix this, we either need to
    --  (i) add some threshold on negative distance (here, -6), or
    --  (ii) pass ignore_reverse_on_start_tile: true in the call to iterate_over_collision_tiles in compute_closest_wall_query_info,
    --  exactly as we're doing in compute_closest_ceiling_query_info. Originally, I didn't choose (ii) because I was afraid I would
    --  miss legit tile reverse detection in some places. I tried it though just to see, and in practice I could not
    --  find any places where behavior was unexpected or different from (i). But (i) still makes sense in terms of
    --  escape range, so I kept it.
    --  OPTIMIZE CHARS: you can remove this condition and replace it with [[ignore_reverse_on_start_tile:]] true in compute_closest_wall_query_info
    --   if too tight on budget
    --  If you remove both conditions, you can remove the if entirely!

    -- To simplify, we're just passing 6 hardcoded and not as pc_data, for once.
    -- Remember that we're raycasting from the character center, so 6 is actually super deep already, it means the character's front
    --  is around 9 pixels inside the wall already, which is bigger than tile_size = 8! So enough to cover even the fastest spin dash
    --  (max spin dash launch speed is 6).
    -- OPTIMIZE CHARS: consider storing ceil(pc_data.ground_sensor_extent_x) in a variable in pc_data (either precomputed or hardcoded)
    --  that you'd reuse *everywhere*
    if -6 <= wall_query_info.signed_distance and wall_query_info.signed_distance < ceil(pc_data.ground_sensor_extent_x) then
      -- we're in good range to escape wall

      -- remember we raycast from character center, but to get the escape vector we need to know the actual
      --  distance from character *front* to wall, so subtract the distance from center to front
      -- we really want to *subtract* in that direction: result is negative, but wall quadrant is an *interior* normal
      --  so the escape vector will be in the sense of the *exterior* normal so we can escape
      -- considering the test above, signed_distance_to_closest_wall must be < 0
      local signed_distance_to_closest_wall = wall_query_info.signed_distance - ceil(pc_data.ground_sensor_extent_x)
      log("signed_distance_to_closest_wall: "..signed_distance_to_closest_wall, "trace2")

      local wall_quadrant = dir_vectors[self:get_horizontal(quadrant_horizontal_dir)]
      local vector_to_closest_wall = signed_distance_to_closest_wall * wall_quadrant

      -- Escape wall

      -- Note that sensor position preserves pixel fraction on qy (expected wall normal axis:
      --  we consider the wall quadrant to define qx/qy here, not character quadrant)
      --  so we can get the exact distance to closest wall.
      -- This means that even when we enter wall by a fraction of pixel, we'll escape from it perfectly.
      -- In addition, we don't need to floor the result's qy, similarly to how we perfectly snap
      --  to ground thanks to ground sensor position preserving qy fraction.
      next_position:add_inplace(vector_to_closest_wall)

      -- Return true so caller can remember character was blocked and reset ground speed
      return true
    end
  end

  -- not commented out for now to maintain utests validity,
  --  but if you need to spare characters, comment this out and change utests to check for nil / no value
  return false
end

-- return true iff move intention is down, without horizontal component
function player_char:wants_to_crouch()
  return self.move_intention.x == 0 and self.move_intention.y > 0
end

-- if character intends to jump, prepare jump for next frame
-- this extra frame allows us to detect if the player wants a variable jump or a hop
--  depending whether input is hold or not
-- TODO/CHAR OPTIMIZATION: now hop is no more than a variable jump immediately interrupted, so there is no need
--  to delay jump detection like this. We shouldn't be losing a frame even now as jump is checked
--  at the beginning of the next frame, however since ground accel is weaker than air accel,
--  character will tend to be slower when running and jumping.
--  We can probably merge check_jump_intention and check_jump now, and do it before update_platformer_motion_grounded.
--  Make sure to also trigger spin dash at this point, since it's also using self.jump_intention.
function player_char:check_jump_intention()
  if self.jump_intention then
    -- consume intention so puppet control mode (which is sticky) also works
    self.jump_intention = false
    self.should_jump = true
  end
end

-- if character intends to jump, apply jump velocity from current ground
--  and enter the air_spin state
-- return true iff jump was applied (return value is currently unused)
-- CHAR OPTIMIZATION: no need for return value anymore (update utest too)
function player_char:check_jump()
  if self.should_jump then
    self.should_jump = false

    -- apply initial jump speed for variable jump
    -- note: if the player is doing a hop, the vertical speed will be reset
    --  to the interrupt speed during the same frame in update_platformer_motion_airborne
    --  via check_hold_jump (we don't do it here so we centralize the check and
    --  don't apply gravity during such a frame)
    -- to support slopes, we use the ground normal (rotate right tangent ccw)
    -- either we are grounded and jumping along ground normal, or we are doing late jump
    --  and jumping along last ground normal (defined via late_jump_slope_angle)
    local jump_angle = self.time_left_for_late_jump > 0 and self.late_jump_slope_angle or self.slope_angle
    local jump_impulse = pc_data.initial_var_jump_speed_frame * vector.unit_from_angle(jump_angle):rotated_90_ccw()
    self.velocity:add_inplace(jump_impulse)
    self:enter_motion_state(motion_states.air_spin)
    self.has_jumped_this_frame = true
    self.can_interrupt_jump = true

    self:play_low_priority_sfx(audio.sfx_ids.jump)

    return true
  end
  return false
end

-- check if player should start spin dash, or charge spin dash further
function player_char:check_spin_dash()
  if contains({motion_states.crouching, motion_states.spin_dashing}, self.motion_state) then
    if self.motion_state == motion_states.spin_dashing and self.move_intention.y <= 0 then
      -- player released down button, release spin dash!
      -- edge case: if during crouch, player releases down and pressed JUMP at the same time,
      --  character still rev once, only to release spin dash next frame
      --  (in theory player could press down again to hold the spin dash charge... in the original
      --  game, it doesn't seem possible and spin dash releases anyway, although I couldn't test
      --  with TAS so not sure at; but it doesn't matter, we don't reproduce this edge behavior at 100%)
      self:release_spin_dash()
    elseif self.jump_intention then
      -- player is charging spin dash (this includes the initial charge)
      -- consume intention so puppet control mode (which is sticky) also works
      self.jump_intention = false

      -- enter spin dashing state the first time, after that it will just be rev
      if self.motion_state == motion_states.crouching then
        self:enter_motion_state(motion_states.spin_dashing)

        -- reset ground speed (it effectively freezes it, as update won't apply slope factor
        --  during spin dash charge)
        self.ground_speed = 0

        -- reset spin dash rev (it's important to do because we do not reset it on release)
        self.spin_dash_rev = 0
      end

      -- revvin' up!
      -- this includes the first rev

      -- fill spin dash rev formula from SPG
      self.spin_dash_rev = min(self.spin_dash_rev + pc_data.spin_dash_rev_increase_step, pc_data.spin_dash_rev_max)

      -- visual

      -- exceptionally play anim from here instead of player_char:check_play_anim,
      --  because we must replay animation from start on every rev
      self:update_sprite_row_and_play_sprite_animation("spin_dash", --[[from_start:]] true)

      -- hardcoded values as unlikely to change once set, and to spare characters
      self.smoke_pfx:start(self.position + vector(0, 5), self.orientation == horizontal_dirs.left)

      -- audio
      self:play_low_priority_sfx(audio.sfx_ids.spin_dash_rev)
    else
      if self.motion_state == motion_states.spin_dashing then
        -- only apply friction when not charging this frame (gives a change to reach maximum speed,
        --  although needs perfect timing)
        self.spin_dash_rev = self.spin_dash_rev * pc_data.spin_dash_drag_factor_per_frame
      end
    end
  end
end

-- release spin dash and launch character rolling at charged speed
-- we assume character is spin dashing
function player_char:release_spin_dash()
  -- set ground speed and let velocity be updated next frame (we're not losing a frame)
  local dir_sign = horizontal_dir_signs[self.orientation]
  self:enter_motion_state(motion_states.rolling)

  -- set ground speed using base launch speed and rev contribution
  self.ground_speed = dir_sign * (pc_data.spin_dash_base_speed + flr(self.spin_dash_rev) * pc_data.spin_dash_rev_increase_factor)

  -- visual
  self.smoke_pfx:stop()

  -- audio
  self:play_low_priority_sfx(audio.sfx_ids.spin_dash_release)
end

-- update motion following platformer airborne motion rules
function player_char:update_platformer_motion_airborne()
  -- SPG note: http://info.sonicretro.org/SPG:Main_Game_Loop
  -- I started working on this before this page appeared though, so the order may not exactly be the same
  -- For instance, I update gravity before air drag, so air drag actually checks the new velocity y,
  --  although the difference is not perceptible.
  -- There are also some flow differences, e.g. we call check_update_sprite_angle in update_anim
  --  then check for falling state inside, instead of making it part of the airborne update
  -- Nevertheless, it's working quite well.

  -- TODO: follow Main_Game_Loop and update gravity AFTER applying velocity
  -- this will remove the need for has_jumped_this_frame member while preserving behavior
  if self.has_jumped_this_frame then
    -- do not apply gravity on first frame of jump, and consume has_jumped_this_frame
    self.has_jumped_this_frame = false
  else
    -- apply gravity to current speed y
    self.velocity.y = self.velocity.y + pc_data.gravity_frame2
  end

  -- only allow jump interrupt if character has jumped on its own (no fall)
  -- there is no has_jumped flag so the closest is to check for air_spin
  if self.motion_state == motion_states.air_spin then
    -- check if player is continuing or interrupting jump *after* applying gravity
    -- this means gravity will *not* be applied during the hop/interrupt jump frame
    self:check_hold_jump()
  end

  if self.move_intention.x ~= 0 then
    -- apply x acceleration via intention (if not 0)
    local previous_velocity_x = self.velocity.x
    self.velocity.x = self.velocity.x + self.move_intention.x * pc_data.air_accel_x_frame2
    self:clamp_air_velocity_x(previous_velocity_x)

    -- in the air, apply intended motion to direction immediately
    self.orientation = signed_speed_to_dir(self.move_intention.x)
  end

  self:apply_air_drag()

  if self.velocity.y > pc_data.max_air_velocity_y then
    self.velocity.y = pc_data.max_air_velocity_y
  end

  -- apply air motion without caring about obstacles to start with (step 5 in SPG Main Loop)
  self.position:add_inplace(self.velocity)

  -- we're supposed to apply gravity here

  -- check for air collisions (wall, ceiling, ground) and update position in-place
  local air_motion_result = self:check_air_collisions()

  -- FIX to top-left corner enter during jump lies here, or when is_blocked_by_wall is set...
  -- since motion is not considered up, we are only blocked by wall...

  if air_motion_result.is_blocked_by_wall then
    self.velocity.x = 0
  end

  if air_motion_result.is_blocked_by_ceiling then
    self.velocity.y = 0
  end

  -- check for stage left edge soft block
  -- see update_platformer_motion_grounded
  if flr(self.position.x) < pc_data.ground_sensor_extent_x then
    -- clamp position to stage left edge and clamp velocity x to 0
    -- note that in theory we should update the air motion result
    --  tile location and slope angle to match the new position,
    --  but in practice we know that speeds are low and besides there is
    --  nothing on the left of the stage so basically we already have
    --  the ground info we need, worst case character will fall 1 extra frame
    --  then land
    self.position.x = ceil(pc_data.ground_sensor_extent_x)
    self.velocity.x = max(0, self.velocity.x)
  end

  if air_motion_result.is_landing then
    -- register new ground tile, update slope angle and enter standing state
    self:set_ground_tile_location(air_motion_result.tile_location)
    self:set_slope_angle_with_quadrant(air_motion_result.slope_angle)
    -- always stand on ground, if we want to roll we'll switch to rolling on next frame
    self:enter_motion_state(motion_states.standing)

    -- with the new big step method and reliable escape, the second call to
    --  check_escape_from_ground here is now unneeded
  end

  log("self.position: "..self.position, "trace")
  log("self.velocity: "..self.velocity, "trace")
end

-- check if character can and wants to interrupt jump by not holding anymore,
--  and set vertical speed to interrupt speed if so
function player_char:check_hold_jump()
  -- if character is air spinning after falling from a roll, can_interrupt_jump will simply
  --  be false from the start and it will never enter this block
  -- this will prevent interrupting a rising air spin after rolling off a rising curve when releasing jump
  -- do not set can_interrupt_jump to false when velocity y goes under jump_interrupt_speed_frame
  --  as long as player holds jump input: as it may be processed in the future (under effector
  --  or after enemy bounce for instance, although I'd probably reset it on enemy bounce)
  if self.can_interrupt_jump and not self.hold_jump_intention then
    -- character has not interrupted jump yet and wants to
    -- flag that you can't interrupt jump anymore even if it's too late, so we don't enter this block anymore
    self.can_interrupt_jump = false

    -- character tries to interrupt jump, check if's not too late
    local signed_jump_interrupt_speed_frame = -pc_data.jump_interrupt_speed_frame
    if self.velocity.y < signed_jump_interrupt_speed_frame then
      log("interrupt jump "..self.velocity.y.." -> "..signed_jump_interrupt_speed_frame, "trace")
      self.velocity.y = signed_jump_interrupt_speed_frame
    end
  end
end

function player_char:apply_air_drag()
  local vel = self.velocity  -- ref
  if vel.y < 0 and vel.y > - pc_data.air_drag_max_abs_velocity_y and
      abs(vel.x) >= pc_data.air_drag_min_velocity_x then
    vel.x = vel.x * pc_data.air_drag_factor_per_frame
--#if busted
    -- unlike acceleration, drag is multiplicative and can easily give numbers much more precise
    --  than PICO-8, messing up with tests (in particular itests as they accumulate over frames)
    vel.x = to_fixed_point(vel.x)
--#endif
  end
end

-- clamp air velocity x to max
function player_char:clamp_air_velocity_x(previous_velocity_x)
  assert(not self:is_grounded())
  -- like clamp_ground_speed, keep any speed already above the max, but allow decreasing in abs
  -- and it's unlikely character switches velocity x sign at high speed so only consider abs, not sign
  local max_velocity_x = max(abs(previous_velocity_x), pc_data.max_air_velocity_x)
  if abs(self.velocity.x) > max_velocity_x then
    self.velocity.x = sgn(self.velocity.x) * max_velocity_x
  end
end

-- check for air collisions with wall and ground, and apply escape vector in-place on self.position
-- return {next_position: vector, is_blocked_by_wall: bool, is_blocked_by_ceiling: bool, is_landing: bool} where
--  - next_position is the position of the character next frame considering his current (air) velocity
--  - is_blocked_by_ceiling is true iff the character encounters a ceiling during this motion
--  - is_blocked_by_wall is true iff the character encounters a wall during this motion
--  - is_landing is true iff the character touches a ground from above during this motion
function player_char:check_air_collisions()
  -- if character is not moving, he is not blocked nor landing (we assume the environment is static)
  -- this is pretty rare in the air, but could happen at the apogee
  if self.velocity:is_zero() then
    return motion.air_motion_result(
      nil,    -- start in air, so no ground tile
      false,  -- is_blocked_by_wall
      false,  -- is_blocked_by_ceiling
      false,  -- is_landing
      nil     -- slope_angle
    )
  end

  -- SPG note: http://info.sonicretro.org/SPG:Main_Game_Loop
  -- We're following the indicated order by checking wall before ground

  -- Big step method:
  -- 1. escape from any wall and remember being blocked by it
  -- 2a. (going down) escape from any ground and remember landing
  -- 2b. (going up) escape from any ceiling and remember being blocked by it

  -- Note that there is no extra wall check after that unlike compute_ground_motion_result
  --  because even if we landed and changed quadrant (from air quadrant which is always down) and happen to stop
  --  touching a wall with new quadrant, the effect of blocking would just be to lose velocity X,
  --  but velocity Y would still contribute to landing ground speed, so we would not brutally stop motion as on ground.

  -- There is no position prediction step in this case, because the caller must already
  --  have updated the position to next position (assuming no obstacles at first)

  local ground_tile_location-- = nil
  local is_blocked_by_wall = false
  local is_blocked_by_ceiling = false
  local is_landing = false
  local slope_angle-- = nil

  -- Step 1: wall check

  -- if moving horizontally, do a wall raycast in the direction of velocity X, from current position
  if self.velocity.x ~= 0 then
    local quadrant_horizontal_dir = signed_speed_to_dir(self.velocity.x)
    is_blocked_by_wall = self:check_escape_wall_and_update_next_position(self.position, quadrant_horizontal_dir)
  end

  if self.velocity.y > 0 then
    -- Step 2a: ground check
    -- Note that we just check going down to simplify while original game may accept going slightly up at sheer angle

    -- Check if next position is inside/above ground
    -- (same as compute_ground_motion_result)

    -- REFACTOR: this really is check_escape_from_ground, consider reusing this method here,
    --  although we're setting vars more than actually changing state (except for self.position)
    --  so this may need to readjust method to return something like vector_to_closest_ground or nil
    local ground_query_info = self:compute_ground_sensors_query_info(self.position)
    local signed_distance_to_closest_ground = ground_query_info.signed_distance
    log("signed_distance_to_closest_ground: "..signed_distance_to_closest_ground, "trace2")

    -- to spare characters, instead of checking if we detected a tile, then check distance,
    --  we just check if distance is negative - that should only be true when a tile was found
    --  (new convention makes sure to always set tile position even if too deep inside ground)
    -- convention v3 is to ignore ground completely if too deep inside
    --  to avoid walking with head on ceiling or inside one-way platform when a little too low,
    --  so check for ideal range here
    if - pc_data.max_ground_escape_height <= signed_distance_to_closest_ground and signed_distance_to_closest_ground < 0 then
      assert(ground_query_info.tile_location, "signed_distance_to_closest_ground < 0 yet ground_query_info.tile_location is not set")

      -- Next position is inside ground, close enough to surface => Step up
      -- (same as compute_ground_motion_result)
      -- Note that enter_motion_state contains its own code to adjust center position based on becoming (un)compact
      local vector_to_closest_ground = signed_distance_to_closest_ground * self:get_quadrant_down()
      self.position:add_inplace(vector_to_closest_ground)

      is_landing = true
      ground_tile_location = ground_query_info.tile_location  -- no need to :copy(), we won't reuse ground_query_info
      slope_angle = ground_query_info.slope_angle
    end
    -- unlike compute_ground_motion_result, we don't care about the else case, where we hover over ground
    --  or just touch it, as we don't want to step down, and we only consider we are landing when
    --  entering ground by at least a fraction of pixel
  elseif self.velocity.y < 0 then
    -- Step 2a: ceiling check
    -- Note that we just check going up to simplify while original game may accept going slightly down at sheer angle

    local ceiling_query_info = self:compute_ceiling_sensors_query_info(self.position)
    local signed_distance_to_closest_ceiling = ceiling_query_info.signed_distance

    if signed_distance_to_closest_ceiling < 0 then
      assert(ceiling_query_info.tile_location, "signed_distance_to_closest_ground < 0 yet ceiling_query_info.tile_location is not set")
      assert(ceiling_query_info.slope_angle > 0.25 and ceiling_query_info.slope_angle < 0.75,
        "detected ceiling with slope angle expected between 0.25 and 0.75 excluded, got: "..ceiling_query_info.slope_angle..
        " (we don't check for those bounds in ceiling adherence check so Sonic may adhere to unwanted walls)")
      -- Hit ceiling
      -- Whether we can land or not, we must escape (there is no max ceiling escape distance, so just do it)
      -- Remember to oppose direction of quadrant down to get quadrant up used for ceiling raycast (hence `-`)
      local vector_to_closest_ceiling = - signed_distance_to_closest_ceiling * self:get_quadrant_down()
      self.position:add_inplace(vector_to_closest_ceiling)

      if ceiling_query_info.slope_angle <= 0.25 + pc_data.ceiling_adherence_catch_range_from_vertical or
          ceiling_query_info.slope_angle >= 0.75 - pc_data.ceiling_adherence_catch_range_from_vertical then
        -- Character lands on ceiling aka ceiling adherence catch (we changed convention to match ground
        --  and only land when entering ceiling by at least a fraction of pixel; otherwise, no extra condition on velocity)
        -- Note that enter_motion_state contains its own code to adjust center position based on becoming (un)compact
        ground_tile_location = ceiling_query_info.tile_location
        is_landing = true
        slope_angle = ceiling_query_info.slope_angle
      else
        -- Cannot land, just get blocked by ceiling (will reset velocity Y)
        is_blocked_by_ceiling = true
      end
    end
  end

  return motion.air_motion_result(
    ground_tile_location,
    is_blocked_by_wall,
    is_blocked_by_ceiling,
    is_landing,
    slope_angle
  )
end

-- item and trigger checks

--#if ingame

function player_char:check_spring()
  local curr_stage_state = flow.curr_state
  assert(curr_stage_state.type == ':stage')

  -- unlike emerald we don't just pass position because springs are more complex
  --  and may require to check bottom position or center position depending on direction
  local spring_obj = curr_stage_state:check_player_char_in_spring_trigger_area()
  if spring_obj then
    self:trigger_spring(spring_obj)
  end
end

function player_char:trigger_spring(spring_obj)
  if spring_obj.direction == directions.up then
    self.velocity.y = -pc_data.spring_jump_speed_frame
    self:enter_motion_state(motion_states.falling)
    self.should_play_spring_jump = true
  else
    -- we assume horizontal spring here (spring down not supported)

    -- set orientation to match spring, even in the air
    -- small trick to convert cardinal direction to horizontal direction
    -- cardinal left = 0 -> horizontal left 1, cardinal right = 2 -> horizontal right = 2
    -- unlike the original game, it will make Sonic look in the spring's direction before actually moving
    --  there, since render will be done before next velocity update
    -- to fix that, you can just check for spring collision at the beginning of the update rather than the end
    self.orientation = spring_obj.direction / 2 + 1

    -- set horizontal control lock to prevent character from immediately braking (when grounded)
    self.horizontal_control_lock_timer = pc_data.spring_horizontal_control_lock_duration

    local horizontal_dir_sign = horizontal_dir_signs[self.orientation]
    if self:is_grounded() then
      -- we assume the spring on ground (ceiling would reverse ground speed sign)
      -- set the ground speed and let velocity be updated next frame (we're not losing a frame)
      self.ground_speed = horizontal_dir_sign * pc_data.spring_jump_speed_frame
    else
      -- in the air, only velocity makes sense
      self.velocity.x = horizontal_dir_sign * pc_data.spring_jump_speed_frame
    end
  end

  spring_obj:extend()

  -- audio
  self:play_low_priority_sfx(audio.sfx_ids.spring_jump)
end

function player_char:check_launch_ramp()
  -- only detect launch ramp if ground speed is high enough
  --  (we only have a launch ramp to the right in Angel Island, so we check only positive ground speed,
  --   the absence of abs() is not a mistake)
  -- (we are not checking self.ignore_launch_ramp_timer here, it would be too late as we would
  --  still hit the ramp as a normal collider, only ignore its launch behavior)
  if self.ground_tile_location and self.ground_speed >= pc_data.launch_ramp_min_ground_speed then
    -- get stage state for global to region location conversion
    local curr_stage_state = flow.curr_state
    assert(curr_stage_state.type == ':stage')

    -- convert to region location before using mget
    local ground_tile_region_loc = curr_stage_state:global_to_region_location(self.ground_tile_location)
    local ground_visual_tile_id = mget(ground_tile_region_loc.i, ground_tile_region_loc.j)

    if ground_visual_tile_id == visual.launch_ramp_last_tile_id then
      self:trigger_launch_ramp_effect()
    end
  end
end

function player_char:trigger_launch_ramp_effect()
  -- we only handle launch ramp toward right
  assert(self.ground_speed > 0)

  local new_speed = min(pc_data.launch_ramp_speed_max_launch_speed, self.ground_speed * pc_data.launch_ramp_speed_multiplier)

  self.velocity:copy_assign(new_speed * vector.unit_from_angle(pc_data.launch_ramp_velocity_angle))
  self:enter_motion_state(motion_states.falling)

  -- just reuse spring jump animation since in Sonic 3, launch ramp also uses 3D animation
  --  that we don't have anyway
  self.should_play_spring_jump = true

  -- disable collision with any ramp for a few frames to avoid hitting it and landing again
  --  (even though character would be fast enough to trigger it again immediately,
  --   on landing character is standing so ground speed is clamped to max_ground_speed and
  --   character may lose momentum if he was rolling)
  self.ignore_launch_ramp_timer = pc_data.ignore_launch_ramp_duration

  log("trigger launch ramp at new speed: "..new_speed, "ramp")
end

function player_char:check_emerald()
  local curr_stage_state = flow.curr_state
  assert(curr_stage_state.type == ':stage')

  local em = curr_stage_state:check_emerald_pick_area(self.position)
  if em then
    curr_stage_state:character_pick_emerald(em)
  end
end

function player_char:check_loop_external_triggers()
  local curr_stage_state = flow.curr_state
  assert(curr_stage_state.type == ':stage')

  local layer_to_activate = curr_stage_state:check_loop_external_triggers(self.position, self.active_loop_layer)
  if layer_to_activate then
    log("external trigger detected, set active loop layer: "..layer_to_activate, 'loop')
    self.active_loop_layer = layer_to_activate
  end
end

--#if cheat

-- update the velocity and position of the character following debug motion rules
function player_char:update_debug()
  -- while still holding x, perform warp actions instead of continuous motion
  if input:is_down(button_ids.x) then
    if input:is_just_pressed(button_ids.left) then
      self:warp_to_emerald_by(-1)
    elseif input:is_just_pressed(button_ids.right) then
      self:warp_to_emerald_by(1)
    end
    return
  end

  self:update_velocity_debug()
  -- it's much more complicated to access app from here (e.g. via flow.curr_state)
  -- just to get delta_time, so we just use the constant as we know we are at 60 FPS
  -- otherwise we'd have to change utests to init app+flow each time
  self.position = self.position + self.debug_velocity

  -- clamp on level edges (add a small margin before right edge to avoid finishing the level by moving accidentally
  --  too fast)
  local curr_stage_state = flow.curr_state
  assert(curr_stage_state.type == ':stage')
  self.position.x = mid(0, self.position.x, curr_stage_state.curr_stage_data.tile_width * tile_size - 8)
  self.position.y = mid(0, self.position.y, curr_stage_state.curr_stage_data.tile_height * tile_size)
end

function player_char:update_velocity_debug()
  -- update velocity from input
  -- in debug mode, cardinal speeds are independent and max speed applies to each
  self:update_velocity_component_debug "x"
  self:update_velocity_component_debug "y"
end

-- update the velocity component for coordinate "x" or "y" with debug motion
-- coord  string  "x" or "y"
function player_char:update_velocity_component_debug(coord)
  local old_debug_velocity_comp = self.debug_velocity:get(coord)
  local clamped_move_intention_comp = mid(-1, self.move_intention:get(coord), 1)
  local new_debug_velocity_comp = 0  -- default value matters, else may be nil

  if clamped_move_intention_comp ~= 0 then
    if old_debug_velocity_comp == 0 or sgn(clamped_move_intention_comp) == sgn(old_debug_velocity_comp) then
      -- input from velocity component 0, or in same direction as current velocity component => accelerate
      new_debug_velocity_comp = old_debug_velocity_comp + self.debug_move_accel * clamped_move_intention_comp
      -- clamp to max in abs
      new_debug_velocity_comp = mid(-self.debug_move_max_speed, new_debug_velocity_comp, self.debug_move_max_speed)
    else
      -- input in opposite direction of current velocity component => decelerate
      -- input in same direction as current velocity component => accelerate
      new_debug_velocity_comp = old_debug_velocity_comp + self.debug_move_decel * clamped_move_intention_comp
      -- clamp to max in abs
      new_debug_velocity_comp = mid(-self.debug_move_max_speed, new_debug_velocity_comp, self.debug_move_max_speed)
    end
  elseif old_debug_velocity_comp ~= 0 then
    -- no input => friction aka passive deceleration
    new_debug_velocity_comp = sgn(old_debug_velocity_comp) * max(0, abs(old_debug_velocity_comp) - self.debug_move_friction)
  end

  -- check extra input to 2x debug speed
  if input:is_down(button_ids.o) then
    new_debug_velocity_comp = 2 * new_debug_velocity_comp
  end

  -- set component
  self.debug_velocity:set(coord, new_debug_velocity_comp)
end

--(cheat)
--#endif

--(ingame)
--#endif

-- update sprite animation state
function player_char:update_anim()
  self:check_play_anim()
  self:check_update_sprite_angle()
end

-- play appropriate sprite animation based on current state
function player_char:check_play_anim()
  -- brake anims can be played during standing but also falling, so make a global check
  --  giving priority to them
  if self.brake_anim_phase == 1 then
    self:update_sprite_row_and_play_sprite_animation("brake_start")

    -- unlike Sonic 3:
    -- as long as brake anim has started, it gets priority over standing and falling
    -- brake anim ends with freeze_last and will stay in this state until:
    --  - character completes decel and reverses (phase 2)
    --  - player inputs forward motion again (reset to phase 0 immediately)
    --  - player stops inputting motion and anim is over (reset to phase 0 if anim is over)
    --  - character enters air_spin or rolling state (reset to phase 0 immediately)
    -- therefore, we should now return is any case, as even if self.anim_spr.playing is now false,
    --  we should let update_ground_run_speed_by_intention reset the phase when detecting
    --  no input and anim is over
    return
  elseif self.brake_anim_phase == 2 then
    self:update_sprite_row_and_play_sprite_animation("brake_reverse")

    -- as long as brake anim is playing, it gets priority over standing and falling
    -- brake anim ends with freeze_last, just to give us an extra frame to check
    --  if it has ended and switch to default anim for this state (often walk)
    -- we may be standing or falling at this point, though, so if not playing anymore,
    --  reset brake phase and fallback to the general case below to delegate state check
    if self.anim_spr.playing then
      return
    else
      self.brake_anim_phase = 0
    end
  end

  if self.motion_state == motion_states.standing then
    -- update ground animation based on speed
    if self.ground_speed == 0 then
      self:update_sprite_row_and_play_sprite_animation("idle")
    else
      -- standing and moving: play walk cycle at low speed, run cycle at high speed
      -- we have access to self.ground_speed but self.anim_run_speed is shorter than
      --  abs(self.ground_speed), and the values are the same for normal to high speeds
      if self.anim_run_speed < pc_data.run_cycle_min_speed_frame then
        self:update_sprite_row_and_play_sprite_animation("walk", false, max(pc_data.walk_anim_min_play_speed, self.anim_run_speed))
      else
        self:update_sprite_row_and_play_sprite_animation("run", false, self.anim_run_speed)
      end
    end
  elseif self.motion_state == motion_states.falling then
    -- stop spring jump anim when falling down again
    if self.should_play_spring_jump and self.velocity.y > 0 then
      self.should_play_spring_jump = false
    end

    if self.should_play_spring_jump then
      self:update_sprite_row_and_play_sprite_animation("spring_jump")
    else
      -- normal fall -> run in the air (even if not working, just to avoid having Sonic falling idle
      --  e.g. when crumbling floor breaks beneath his feet; what Classic Sonic does, but we don't mind)
      -- we don't have access to previous ground speed as unlike original game, we clear it when airborne
      --  but we can use the stored anim_run_speed, which is the same except for very low speed
      -- (and we don't mind them as we are checking run cycle for high speeds)
      if self.anim_run_speed < pc_data.run_cycle_min_speed_frame then
        self:update_sprite_row_and_play_sprite_animation("walk", false, max(pc_data.walk_anim_min_play_speed, self.anim_run_speed))
      else
        -- run_cycle_min_speed_frame > walk_anim_min_play_speed so no need to clamp here
        self:update_sprite_row_and_play_sprite_animation("run", false, self.anim_run_speed)
      end
    end
  elseif self.motion_state == motion_states.crouching then
    -- we don't mind about speed here, character can totally slide at low speed due to momentum or slope
    self:update_sprite_row_and_play_sprite_animation("crouch")
  elseif self.motion_state == motion_states.spin_dashing then
    -- exceptionally we don't need to self:update_sprite_row_and_play_sprite_animation("spin_dash"), it's already done on every rev
    --  so we can also pass from_start: true
  else -- self.motion_state == motion_states.rolling and self.motion_state == motion_states.air_spin
    local min_play_speed = self.motion_state == motion_states.rolling and
      pc_data.rolling_spin_anim_min_play_speed or pc_data.air_spin_anim_min_play_speed
    self:update_sprite_row_and_play_sprite_animation("spin", false, max(min_play_speed, self.anim_run_speed))
  end
end

-- table associating sprite animation name to double row index (starting at 0) in Sonic spritesheet
--  memory stored in general memory
-- animations with diagonal (45-degree) sprite variants are indicated by a suffix "45"
-- they are not new animations per se, since they use exactly the same sequence of sprites at the same positions,
--  but we must reload the appropriate sprites
-- use ["key"] syntax to protect member names against minification
local sprite_anim_name_to_double_row_index_table = {
  ["idle"] = 0,
  ["walk"] = 0,
  ["walk45"] = 1,
  ["brake_start"]   = 3,
  ["brake_reverse"] = 3,
  ["run"]  = 2,
  -- encode the fact that the sprites start halfway on the first line of run sprites
  -- remember we use double sprite rows => 16 lines, so 1 line = 1/16 of a double sprite row memory,
  --  and half a line = 1/32 of that, hence + 1/32 (we could use manually add +0x20 if not relying on a pure factor)
  ["run45"]  = 2 + 1/32,
  ["spin"] = 3,
  ["crouch"] = 1,
  ["spring_jump"] = 0,
  ["spin_dash"] = 4,
}

-- helper to copy needed sprite (double) row in memory and play animation
function player_char:update_sprite_row_and_play_sprite_animation(anim_key, from_start, speed)
  -- play anim (important to still call it even if already played, to update speed or restart it)
  self.anim_spr:play(anim_key, from_start, speed)

  -- now update sprite angle parameters
  -- this must be done *after* playing animation as it checks the current anim key
  --  and *before* copying the correct double row of sprites below, as this requires
  --  is_sprite_diagonal updated for the latest anim
  self:update_sprite_angle_parameters()

  -- Copy the first 8 rows = 4 double rows at once
  -- Main Sonic sprites have been copied to general memory in stage_state:reload_runtime_data
  -- We're copying them back, except we only copy the row (or partial row) we are interested in
  -- Source addresses are the Dest addresses from reload_runtime_data + some offset if needed
  -- Dest address is always row index 8 as we always play Sonic sprite animations on double row 8-9
  --  (with spring_jump sprite exceptionally overlapping row 10)
  -- 1 row = 0x200 so row index 8 starts at 0x1000 (middle of spritesheet)
  -- Note that in the table below, double_row_index starts at 0 although the first double row of Sonic sprites
  --  starts at row index 2 (it was just to preserve the cross sprite 0, although it doesn't really matter as we copy the sprites
  --  elsewhere in runtime memory)

  -- double_row_index  Dest    Source  Size    Content
  -- 0                 0x1000  0x4b00  0x400   First double row of Sonic sprites (walk cycle, idle, spring jump top)
  -- 1                 0x1000  0x4f00  0x400   Second double row of Sonic sprites (walk cycle 45 degrees, crouch 2 sprites)
  -- 2                 0x1000  0x5300  0x400   Third double row of Sonic sprites (run cycle 0 and 45 degrees)
  -- 3                 0x1000  0x5700  0x400   Fourth double row of Sonic sprites (air spin, brake 3 sprites)
  -- 4                 0x1000  0x5b00  0x1400  Last 5 Sonic sprites = 10x2 cells located on rows of indices 10-11 (spin dash sprites)

  local anim_name_with_optional_suffix

  -- is_sprite_diagonal already checks for "walk" and "run" so the suffixed name should be a valid entry
  --  in the table
  if self.is_sprite_diagonal then
    -- those two animations have a 45-degree variant
    -- indicate it with suffix "45"
    anim_name_with_optional_suffix = anim_key.."45"
  else
    anim_name_with_optional_suffix = anim_key
  end

  -- find which double row (or half double row) to copy, and remember that for next time
  local double_row_index = sprite_anim_name_to_double_row_index_table[anim_name_with_optional_suffix]
  assert(double_row_index, "sprite_anim_name_to_double_row_index_table has no entry for key: "..anim_name_with_optional_suffix)

  -- only copy row if not already done to preserve CPU every frame
  if self.last_copied_double_row ~= double_row_index then
    self.last_copied_double_row = double_row_index

    local start_address = 0x4b00 + double_row_index * 0x400

    if double_row_index < 4 then
      -- if anim is anything but spin_dash, we can copy 2 full rows at once, back from general memory
      -- note that we do this even for run45 which is a set of 4 sprites located on the right half of the spritesheet
      -- this is because we already computed the correct start address thx to the fractional double_row_index,
      --  and offsetting the whole run sprite set by half a line (+0x20 -> 0x5320) effectively moves the run45 sprites
      --  to the left half of the spritesheet, losing the 1st (half) line of non-rotated run sprites, and ending
      --  with an extra half line of irrelevant air+spin sprites copied from the line just after the last run45 sprites line
      -- we could also copy the 16 half lines manually but it's simpler to just copy unused contiguous memory
      --  as lons as we have a single operation
      memcpy(0x1000, start_address, 0x400)
    else
      -- special case for spin_dash sprites which, for compactness, are only copied by half lines in general memory,
      --  se we must copy 16 half lines back to runtime spritesheet memory
      -- spin_dash sprites span over 10 cell lines = 10 * 4 bytes = 40 bytes = 0x28 bytes
      -- reversing the logic from reload_runtime_data, source addresses are chained (+0x28)
      --  while dest addresses leave a gap and skip a full line each time (+0x40)
      for i = 0, 15 do
        -- for spin_dash, start_address = 0x5b00
        memcpy(0x1000 + i * 0x40, start_address + i * 0x28, 0x28)
      end
    end
  end
end

function player_char:check_update_sprite_angle()
  local angle = self.continuous_sprite_angle
  assert(0 <= angle and angle < 1, "player_char:update_sprite_angle: expecting modulo angle, got: "..angle)

  if self.motion_state == motion_states.falling and angle ~= 0 then
    if angle < 0.5 then
      -- just apply friction calculation as usual
      self:set_continuous_sprite_angle(max(0, abs(angle) - pc_data.sprite_angle_airborne_reset_speed_frame))
    else
      -- problem is we must rotate counter-clockwise toward 1 which is actually 0 modulo 1
      --  so we increase angle, clamp to 1 and % 1 so if we reached 1, we now have 0 instead
      self.continuous_sprite_angle = min(1, abs(angle) + pc_data.sprite_angle_airborne_reset_speed_frame) % 1
    end
  end
end

-- render the player character sprite at its current position
function player_char:render()
  -- floor position to avoid jittering when running on ceiling due to
  --  partial pixel position being sometimes one more pixel on the right due after 180-deg rotation
  local floored_position = vector(flr(self.position.x), flr(self.position.y))
  local flip_x = self.orientation == horizontal_dirs.left
  self.anim_spr:render(floored_position, flip_x, false, self.sprite_angle)
  self.smoke_pfx:render()
end

-- play sfx on channel 3, only if a jingle is not already playing there
-- this is an adaptation of sound.play_low_priority_sfx for this game specifically,
--  because it allows us to specify the jingle sfx id directly
--  (using sound.play_low_priority_sfx prevents new character sfx from covering previous one)
-- note that unlike sfx(), you *must* pass a channel
function player_char:play_low_priority_sfx(n)
  if stat(19) ~= audio.sfx_ids.pick_emerald then
    sfx(n)
  end
end

--#if debug_character
local debug_ray_colors_hit = {
  colors.green,  -- first wall check
  colors.pink,   -- ground check (left sensor)
  colors.pink,   -- ground check (right sensor)
  colors.blue,   -- second wall check (optional)
}

local debug_ray_colors_no_hit = {
  colors.yellow,  -- first wall check
  colors.white,    -- ground check (left sensor)
  colors.white,    -- ground check (right sensor)
  colors.peach,   -- second wall check (optional)
}

function player_char:debug_draw_rays()
  -- debug "raycasts"
  local i = 0
  for debug_ray in all(self.debug_rays) do
    i = i + 1
    local start_pos = debug_ray.start:copy()
    local end_pos = debug_ray.start + debug_ray.distance * debug_ray.direction_vector

    -- if direction is left or up and the start / end position qx (x for left, y for up)
    --  is at integer coordinate, then we must draw the corresponding pixel one pixel to the left/up
    -- this is because start / end position is actually at a crosspoint (for qx; qy is always floored
    --  and corresponds to an exact q-column index already), therefore when doing a symmetrical test
    --  like wall left/right, the source is exactly at the same position, but at an integer qx = 1,
    --  it should only cover qx = 0- when going left, but qx = 1+ when going right
    -- same for the end position
    -- this should fix the raycast stopping right before a left wall when blocked by left wall
    --  (same for ceiling)
    if debug_ray.direction_vector.x == -1 then
      -- left
      start_pos.x = ceil(start_pos.x) - 1
      end_pos.x = ceil(end_pos.x) - 1
    elseif debug_ray.direction_vector.y == -1 then
      -- up
      start_pos.y = ceil(start_pos.y) - 1
      end_pos.y = ceil(end_pos.y) - 1
    end

    if debug_ray.hit then
      -- hit, q-above ground (if distance > 0) or from inside ground (if distance <= 0),
      --  ray will be pink except the last pixel which will be red
      -- (subtract direction which is a cardinal unit vector to get the penultimate pixel)
      line(start_pos.x, start_pos.y, end_pos.x, end_pos.y, debug_ray_colors_hit[i])
      pset(end_pos.x, end_pos.y, colors.red)
    else
      -- no-hit, draw full ray in white to distinguish from hit case
      -- I tried different colors from distance <= 0 vs > 0, but unfortunately
      --  they were hard to distinguish from the midground
      --  so you'll have to guess the distance sign by looking at the environment
      line(start_pos.x, start_pos.y, end_pos.x, end_pos.y, debug_ray_colors_no_hit[i])
    end
  end
end

function player_char:debug_print_info()
  -- debug info
  outline.print_with_outline("state: "..self.motion_state, 8, 94, colors.white, colors.black)
  outline.print_with_outline("quadrant: "..tostr(self.quadrant), 8, 100, colors.white, colors.black)
  outline.print_with_outline("slope: "..tostr(self.slope_angle), 8, 106, colors.white, colors.black)
  outline.print_with_outline("tile: "..(self.ground_tile_location and self.ground_tile_location.i..", "..self.ground_tile_location.j or "[nil]"),
    68, 106, colors.white, colors.black)
  outline.print_with_outline("x: "..self.position.x, 8, 112, colors.white, colors.black)
  outline.print_with_outline("y: "..self.position.y, 8, 118, colors.white, colors.black)
  outline.print_with_outline("vx: "..self.velocity.x, 68, 112, colors.white, colors.black)
  outline.print_with_outline("vy: "..self.velocity.y, 68, 118, colors.white, colors.black)
end
--#endif

--#if debug_collision_mask
function player_char:debug_draw_tile_collision_masks()
  local curr_stage_state = flow.curr_state
  assert(curr_stage_state.type == ':stage')

  local region_topleft_loc = curr_stage_state:get_region_topleft_location()

  -- debug "raycasts"
  for debug_mask_global_tile_location in all(self.debug_mask_global_tile_locations) do
    local debug_mask_region_tile_location = debug_mask_global_tile_location - region_topleft_loc
    local tile_id = mget(debug_mask_region_tile_location.i, debug_mask_region_tile_location.j)
    local tile_collision_flag = fget(tile_id, sprite_flags.collision)
    if tile_collision_flag then
      -- get the tile collision mask
      local tcd = collision_data.get_tile_collision_data(tile_id)
      assert(tcd, "collision_data.tiles_collision_data does not contain entry for sprite id: "..tile_id..", yet it has the collision flag set")

      if tcd then
        tcd:debug_render(debug_mask_global_tile_location)
      end
    else
      assert(false, "region tile location "..debug_mask_region_tile_location.." with tile id "..tile_id.." was added to debug_mask_region_tile_locations "..
        "but it has no collision flag")
    end
  end
end
--#endif

return player_char

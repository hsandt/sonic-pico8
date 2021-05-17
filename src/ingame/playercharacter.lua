local flow = require("engine/application/flow")
local input = require("engine/input/input")
local animated_sprite = require("engine/render/animated_sprite")

local collision_data = require("data/collision_data")
local pc_data = require("data/playercharacter_data")
local pfx = require("ingame/pfx")
local motion = require("platformer/motion")
local world = require("platformer/world")
local audio = require("resources/audio")
local visual = require("resources/visual_common")
-- we should require ingameadd-on in main, as early as possible

local player_char = new_class()

-- helper for spin dash dust
function player_char.size_ratio_over_lifetime(life_ratio)
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
-- ascending_slope_time     float           time before applying full slope factor, when ascending a slope (s)
-- (#original_slope_features)
-- spin_dash_rev            float           spin dash charge (aka revving) value (float to allow drag over time)

-- move_intention           vector          current move intention (binary cardinal)
-- jump_intention           bool            current intention to start jump or spin dash (consumed on jump or spin dash)
-- hold_jump_intention      bool            current intention to hold jump (always true when jump_intention is true)
-- should_jump              bool            should the character jump when next frame is entered? used to delay variable jump/hop by 1 frame
-- has_jumped_this_frame    bool            has the character started a jump/hop this frame?
-- can_interrupt_jump       bool            can the character interrupted his jump once?

-- anim_spr                 animated_sprite animated sprite component
-- anim_run_speed           float           Walk/Run animation playback speed. Reflects ground_speed, but preserves value even when falling.
-- continuous_sprite_angle  float           Sprite angle with high precision used internally. Reflects slope_angle when standing, but gradually moves toward 0 (upward) when airborne.
--                                          To avoid ugly sprite rotations, only a few angle steps are actually used on render.
-- should_play_spring_jump  bool            Set to true when sent upward in the air thanks to spring, and not falling down yet
-- brake_anim_phase         int             0: no braking anim. 1: brake start. 2: brake reverse.

-- smoke_pfx                pfx             particle system used to render smoke during spin dash charge

-- last_emerald_warp_nb (cheat)     int     number of last emerald character warped to
-- debug_rays (debug_character)     {...}   rays to draw for debug render this frame
function player_char:init()
--#if cheat
  self.debug_move_max_speed = pc_data.debug_move_max_speed
  self.debug_move_accel = pc_data.debug_move_accel
  self.debug_move_decel = pc_data.debug_move_decel
  self.debug_move_friction = pc_data.debug_move_friction
--#endif

  self.anim_spr = animated_sprite(pc_data.sonic_animated_sprite_data_table)
  self.smoke_pfx = pfx(pc_data.spin_dash_dust_spawn_period_frames,
    pc_data.spin_dash_dust_spawn_count,
    pc_data.spin_dash_dust_lifetime_frames,
    pc_data.spin_dash_dust_base_init_velocity,
    pc_data.spin_dash_dust_max_deviation,
    pc_data.spin_dash_dust_base_max_size,
    size_ratio_over_lifetime)

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

  -- impossible value makes sure that first set_ground_tile_location
  --  will trigger change event
  self.ground_tile_location = location(-1, -1)
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

  self.anim_spr:play("idle")
  self.anim_run_speed = 0
  self.continuous_sprite_angle = 0
  self.should_play_spring_jump = false
  self.brake_anim_phase = 0

--#if debug_character
  self.debug_rays = {}
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

-- return quadrant tangent right (forward) unit vector
function player_char:get_quadrant_right()
  return dir_vectors[(self.quadrant - 1) % 4]
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

  -- character is initialized standing, but let him fall if he is spawned in the air
  -- if grounded, also allows to set ground tile properly
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

-- set slope angle and update quadrant
-- if force_upward_sprite is true, set sprite angle to 0
-- else, set sprite angle to angle (if not nil)
function player_char:set_slope_angle_with_quadrant(angle, force_upward_sprite)
  assert(angle == nil or 0 <= angle and angle <= 1, "player_char:set_slope_angle_with_quadrant: angle is "..tostr(angle)..", should be nil or between 0 and 1 (apply % 1 is needed)")

  self.slope_angle = angle

  -- only set sprite angle with true grounded angle, do not set it to 0 when nil
  -- this is to prevent character sprite from switching straight upward immediately
  --  on fall
  if force_upward_sprite then
    self.continuous_sprite_angle = 0
  elseif angle then
    self.continuous_sprite_angle = angle
  end

  self.quadrant = world.angle_to_quadrant(angle)
end

function player_char:update()
-- in stage_intro cartridge, we want Sonic to stay idle, so no input
--  but update physics and render as usual
--#if ingame

--#if busted
  if flow.curr_state.type == ':stage' then
--#endif
    self:handle_input()
--#if busted
  end
--#endif

--(ingame)
--#endif
  self:update_motion()
  self:update_anim()
  self.anim_spr:update()
  self.smoke_pfx:update()
end

--#if ingame

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
      --  in a normal update method not _handle_input, but since we know
      --  that both are updated at 60FPS, it shouldn't be a problem here
      self.horizontal_control_lock_timer = self.horizontal_control_lock_timer - 1
    end

    -- vertical input (used for debug motion, crouch/roll, and possibly look up/down in the future)
    if input:is_down(button_ids.up) then
      player_move_intention:add_inplace(vector(0, -1))
    elseif input:is_down(button_ids.down) then
      player_move_intention:add_inplace(vector(0, 1))
    end

    self.move_intention = player_move_intention

    -- jump
    local is_jump_input_down = input:is_down(button_ids.o)  -- convenient var for optional pre-check
    -- set jump intention each frame, don't set it to true for later consumption to avoid sticky input
    --  without needing a reset later during update
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

  -- ignore subpixels from center position in qx (collision checks use Sonic's integer position,
  -- but we keep exact qy coordinate to get the exact ground sensor qy, and thus exact distance to ground)
  local x = center_position.x
  local y = center_position.y

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
  -- brutal way to floor coordinates are rotation, without having to extract qx, recreating (qx, 0) vector and rotating again
  offset_qx_vector = vector(flr(offset_qx_vector.x), flr(offset_qx_vector.y))

  return qx_floored_bottom_center + offset_qx_vector
end

-- helper method for compute_closest_ground_query_info and is_blocked_by_ceiling_at
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

  assert(world.get_quadrant_x_coord(sensor_position, collision_check_quadrant) % 1 == 0, "iterate_over_collision_tiles: sensor_position qx must be floored, found "..sensor_position)

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

--#if ingame

--#if busted
    if flow.curr_state.type == ':stage' then
--#endif
      -- we now check for ignored tiles:
      --  a. ramps just after launching
      --  b. loops on inactive layer from PC's point-of-view
      --  c. one-way platforms unless we check collision downward
      if pc.ignore_launch_ramp_timer > 0 and visual_tile_id == visual.launch_ramp_last_tile_id or
          pc.active_loop_layer == 1 and curr_stage_state:is_tile_in_loop_exit(curr_global_tile_loc) or
          pc.active_loop_layer == 2 and curr_stage_state:is_tile_in_loop_entrance(curr_global_tile_loc) or
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
    end

    -- a q-column height of 0 doesn't mean that there is ground just below relative offset qy = 0,
    --  but that the q-column is empty and we don't know what is more below
    -- so don't do anything yet but check for the tile one level lower
    --  (unless we've reached end of iteration with the last tile, in which case
    --  the next tile would be too far to snap down anyway)
    if qcolumn_height > 0 then
      -- get q-bottom of tile to compare heights
      -- when iterating q-upward (ceiling check) this is actually a q-top from character's perspective
      local current_tile_qbottom = world.get_tile_qbottom(curr_global_tile_loc, collision_check_quadrant)

      -- signed distance to closest ground/ceiling is positive when q-above ground/q-below ceiling
      -- PICO-8 Y sign is positive up, so to get the current relative height of the sensor
      --  in the current tile, you need the opposite of (quadrant-signed) (sensor_position.qy - current_tile_qbottom)
      -- then subtract qcolumn_height and you get the signed distance to the current ground q-column
      local signed_distance_to_closest_collider = world.sub_qy(current_tile_qbottom, world.get_quadrant_y_coord(sensor_position, collision_check_quadrant), collision_check_quadrant) - qcolumn_height

      -- even when checking downward, we cannot detect one-way platforms from below their surface (signed distance < 0)
      -- this way, we don't step up or get blocked by them as ceiling inadvertently, but can still just land on them
      if is_oneway and signed_distance_to_closest_collider < -1 then
        signed_distance_to_closest_collider = pc_data.max_ground_snap_height + 1
      end

      -- callback returns ground query info, let it decide how to handle presence of collider
      local result = collider_distance_callback(curr_global_tile_loc, signed_distance_to_closest_collider, slope_angle)

      -- we cannot 2x return from a called function directly, so instead, we check if a result was returned
      --  if so, we return from the caller
      if result then
--#if debug_character
        -- ceiling only returns true, and we are only interested in debugging ground sensor rays anyway,
        --  so only consider ground sensor result which should be a proper ground_query_info
        if type(result) == "table" then
          add(pc.debug_rays, {start = sensor_position, direction = collision_check_quadrant_down, distance = result.signed_distance, hit = result.tile_location ~= nil})
        end
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

    -- check fo end of iteration (reached last tile)
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
        -- see similar code above with collider_distance_callback call
        if type(result) == "table" then
          add(pc.debug_rays, {start = sensor_position, direction = collision_check_quadrant_down, distance = result.signed_distance, hit = result.tile_location ~= nil})
        end
--#endif

      -- this is the final check so return the result whatever it is
      return result
    end

    curr_global_tile_loc = curr_global_tile_loc + tile_loc_step
  end
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
    -- by convention, we will set ground tile location to nil
    -- the reason is that we don't need to pass tile_location since when character is inside ground
    --  we don't expect tile surface effect like loop layer trigger or spike damage to happen
    return motion.ground_query_info(nil, -pc_data.max_ground_escape_height - 1, 0)
  elseif signed_distance_to_closest_ground <= pc_data.max_ground_snap_height then
    -- ground found, and close enough to snap up/down, return ground query info
    --  to allow snapping + set slope angle
    return motion.ground_query_info(tile_location, signed_distance_to_closest_ground, slope_angle)
  end
end

-- actual body of compute_closest_ground_query_info passed to iterate_over_collision_tiles
--  as no_collider_callback
local function ground_check_no_collider_callback()
  -- end of iteration, and no ground found or too far below to snap q-down
  -- return edge case for ground considered too far below
  --  (pc_data.max_ground_snap_height + 1, nil)
  return motion.ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil)
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

-- verifies if character is inside ground, and push him upward outside if inside but not too deep inside
-- if ground is detected and the character can escape, update the slope angle with the angle of the new ground
-- if the character cannot escape or is in the air, still reset all values to be safe
--  (e.g. on initial warp it allows us to set ground_tile_location to a proper value instead of default location(0, 0))
-- finally, enter standing state if the character was either touching the ground or inside it (even too deep),
--  else enter falling state
function player_char:check_escape_from_ground()
  local query_info = self:compute_ground_sensors_query_info(self.position)
  local signed_distance_to_closest_ground, next_slope_angle = query_info.signed_distance, query_info.slope_angle
  if signed_distance_to_closest_ground <= 0 then
    -- character is either just touching ground (signed_distance_to_closest_ground == 0)
    --  or inside ground, so check how deep he is inside ground
    if - signed_distance_to_closest_ground <= pc_data.max_ground_escape_height then
      -- close to surface enough to escape
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
    else
      -- too deep to escape, stay there
      -- by convention, set ground tile location to nil (see ground_check_collider_distance_callback)
      -- by slope angle to 0 to stand upward
      self.ground_tile_location = nil
      self:set_slope_angle_with_quadrant(0)
    end
    self:enter_motion_state(motion_states.standing)
  else
    -- character in the air, reset
    self:enter_motion_state(motion_states.falling)
  end
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
    self.brake_anim_phase = 0
  elseif next_motion_state == motion_states.standing then
    if not was_grounded then
      -- Momentum: transfer part of airborne velocity tangential to slope to ground speed (self.slope_angle must have been set previously)
      -- do not clamp ground speed! this allows us to spin dash, fall a bit, land and run at high speed!
      -- SPG (https://info.sonicretro.org/SPG:Slope_Physics#Reacquisition_Of_The_Ground) says original calculation either preserves vx or
      --  uses vy * sin * some factor depending on angle range (possibly to reduce CPU)
      --  but for now we keep this as it's physically logical and feels good enough
      self.ground_speed = self.velocity:dot(vector.unit_from_angle(self.slope_angle))

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
      self.brake_anim_phase = 0
    end

    -- prepare spritesheet reload for rolling sprites
    self:reload_rolling_vs_spin_dash_sprites(--[[spin_dashing: nil]])
  else  -- next_motion_state == motion_states.spin_dashing
    -- prepare spritesheet reload for spin dash sprites
    self:reload_rolling_vs_spin_dash_sprites(--[[spin_dashing:]] true)
  end
end

function player_char:update_collision_timer()
  if self.ignore_launch_ramp_timer > 0 then
    self.ignore_launch_ramp_timer = self.ignore_launch_ramp_timer - 1
  end
end

-- update velocity, position and state based on current motion state
function player_char:update_platformer_motion()
--#if debug_character
  -- clear the debug rays to start anew for this frame (don't clear them after rendering
  --  so you can continue seeing them during debug pause)
  -- OPTIMIZE: pool the rays instead (you can also make them proper structs)
  clear_table(self.debug_rays)
--#endif

  -- check for jump before apply motion, so character can jump at the beginning of the motion
  --  (as in classic Sonic), but also apply an initial impulse if character starts idle and
  --  left/right is pressed just when jumping (to fix classic Sonic missing a directional input frame there)
  -- In the original game, pressing down and jump at the same time gives priority to jump.
  --  Releasing down and pressing jump during crouch gives also priority to spin dash.
  --  So checking jump before crouching is the correct order (you need 2 frames to crouch, then spin dash)
  if self:is_grounded() then
    self:check_jump()  -- this may change the motion state to air_spin and affect branching below
    self:check_spin_dash()  -- this is exclusive with jumping, so there is no order conflict
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

      -- prepare spritesheet reload for crouch sprites
      self:reload_rotated_walk_and_crouch_sprites(--[[rotated_by_45_or_crouching:]] true)
    end
  elseif self.motion_state ~= motion_states.standing then
    self:enter_motion_state(motion_states.standing)

    -- prepare spritesheet reload for standing sprites (esp. idle)
    -- note that if Sonic stands up on a slope 45-degrees, render will immediately reload the
    --  rotated walk sprites...
    self:reload_rotated_walk_and_crouch_sprites(--[[rotated_by_45_or_crouching: nil]])
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
  self.velocity = self.ground_speed * vector.unit_from_angle(self.slope_angle)

  -- update position
  self.position = ground_motion_result.position

  -- character falls by default if finds no ground to stick to
  local should_fall = ground_motion_result.is_falling

  -- SPG: Falling and Sliding Off Of Walls And Ceilings
  if self.quadrant ~= directions.down and abs(self.ground_speed) < pc_data.ceiling_adherence_min_ground_speed then
    -- Only falling when on straight wall, wall-ceiling or ceiling
    -- Note that at this point, we haven't set slope angle and we were grounded so it should not be nil
    if self.slope_angle >= 0.25 and self.slope_angle <= 0.75 then
      should_fall = true
    end
    self.horizontal_control_lock_timer = pc_data.fall_off_horizontal_control_lock_duration
  end

  if should_fall then
    local new_state
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

    -- only allow jump preparation for next frame if not already falling
    self:check_jump_intention()
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

-- return {next_position: vector, is_blocked: bool, is_falling: bool} where
--  - next_position is the position of the character next frame considering his current ground speed
--  - is_blocked is true iff the character encounters a wall during this motion
--  - is_falling is true iff the character leaves the ground just by running during this motion
function player_char:compute_ground_motion_result()
  -- if character is not moving, he is not blocked nor falling (we assume the environment is static)
  if self.ground_speed == 0 then
    return motion.ground_motion_result(
      self.ground_tile_location,
      self.position,
      self.slope_angle,
      false,
      false
    )

  end

  -- from here we will be considering positions, velocities, angles relatively
  --  to the current quadrant to allow Sonic to walk on walls and ceilings
  -- when quadrant is rotated by 0.25 (90 degrees CCW), the following transformations occur:
  -- - ground move intention x <-> y (+x -> -y, -x -> +y, +y -> +x, -y -> -x)
  --   ("intention" matters because we apply a forward rotation as Sonic will try to run on walls and ceilings
  --    this is different from transposing an *existing* vector to another frame, which would have the backward (reverse)
  --    transformation such as +x -> +y)
  --   because the sign of x/y changes, the way we add values also matter, so in some cases
  --    x + dx would become y - dy and a simple transposition is not enough
  --   therefore, it is more reliable to add rotated vectors, even if only one component is non-zero,
  --    and then extract x/y from this vector
  --   we then call these coordinates "quadrant x" and "quadrant y", but note that they still
  --    follow the positive axis sense of PICO-8 (only ground_speed and ground_based_signed_distance_qx are
  --    based on ground orientation, CCW positive)
  -- - existing slope angle -> slope angle - 0.25
  -- when quadrant is rotated by 0.5 (e.g. floor to ceiling), x <-> -x and y <-> -y
  --   and slope angle -> slope angle - 0.5 (these ops are reflective so we don't need to care about reverse transformation as above)
  -- a few examples of quadrant variables:
  -- - quadrant horizontal direction: is it left or right from Sonic's point of view?
  --   (on a left wall, moving up is "left" and moving down is "right"
  --    on the ceiling, moving left is "right" and moving right is "left")
  -- - quadrant horizontal axis: horizontal for quadrants up and down, vertical for quadrants left and right
  --   (we also define the forward as the counter-clockwise direction in any case, e.g. right on quadrant down
  --    and down on quadrant left)
  -- - quadrant vertical axis: orthogonal to quadrant horizontal axis
  --   (we also define "up" as the direction pointing outside the quadrant interior)
  -- - quadrant height: the collision mask column height, in the quadrant's own frame
  --   (when quadrant is left or right, this is effectively a row width, where the row extends from left/right resp.)
  -- - quadrant slope angle: the slope angle subtracted by the quadrant's angle (quadrant down having angle 0, then steps of 0.25 counter-clockwise)
  -- - quadrant columns are rows on walls
  -- we prefix values with "q" or "q-" for "quadrant", e.g. "qx" and "qy"
  -- we even name floors, walls and ceilings "q-wall" to express the fact they are blocking Sonic's motion
  --  relatively to his current quadrant, acting as walls, but may be any solid tile

  -- initialise result with floored coords, it's not to easily visualize
  --  pixel by pixel motion at integer coordinates (we will reinject subpixels
  --  if character didn't touch a wall)
  -- we do this on both coordinates to simplify, but note that Sonic always snaps
  --  to the ground quadrant height, so the quadrant vertical coordinate (qy) is already integer,
  --  so it really matters for qx (but to reduce tokens we don't add a condition based on quadrant)
  -- note that quadrant left and right motion is not completely symmetrical
  --  since flr is asymmetrical so there may be up to a 1px difference in how we hit stuff on
  --  the left or right (Classic Sonic has a collider with odd width, it may be actually symmetrical
  --  on collision checks)
  local floored_x = flr(self.position.x)
  local floored_y = flr(self.position.y)
  local motion_result = motion.ground_motion_result(
    self.ground_tile_location,
    vector(floored_x, floored_y),
    self.slope_angle,
    false,
    false
  )

  local quadrant = self.quadrant
  local quadrant_horizontal_dir = signed_speed_to_dir(self.ground_speed)
  local qx = world.get_quadrant_x_coord(self.position, quadrant)

  -- only full pixels matter for collisions, but subpixels (of last position + delta motion)
  --  may sum up to a full pixel,
  --  so first estimate how many full pixel columns the character may actually explore this frame
  local ground_based_signed_distance_qx = self.ground_speed * cos(self.slope_angle - world.quadrant_to_right_angle(quadrant))
  -- but ground_based_signed_distance_qx is positive when walking a right wall up or ceiling left,
  --  which is opposite of the x/y sign convention; project on quadrant right unit vector to get vector
  --  with x/y with the correct sign for addition to x/y position later
  local ground_velocity_projected_on_quadrant_right = ground_based_signed_distance_qx * self:get_quadrant_right()
  -- equivalent to dot expression below, but more compact than it:
  -- local ground_velocity_projected_on_quadrant_right = quadrant_right:dot(self.ground_speed * vector.unit_from_angle(self.slope_angle)) * quadrant_right
  local projected_velocity_qx = world.get_quadrant_x_coord(ground_velocity_projected_on_quadrant_right, quadrant)

  -- max_distance_qx is always integer
  local max_distance_qx = player_char.compute_max_pixel_distance(qx, projected_velocity_qx)

  -- iterate pixel by pixel on the qx direction until max possible distance is reached
  --  only stopping if the character is blocked by a q-wall (not if falling, since we want
  --  him to continue moving in the air as far as possible; in edge cases, he may even
  --  touch the ground again some pixels farther)
  local qhorizontal_distance_before_step = 0
  while qhorizontal_distance_before_step < max_distance_qx and not motion_result.is_blocked do
    self:next_ground_step(quadrant_horizontal_dir, motion_result)
    qhorizontal_distance_before_step = qhorizontal_distance_before_step + 1
  end

  -- check if we need to add or cut subpixels
  if not motion_result.is_blocked then
    -- since subpixels are always counted to the right/down, the subpixel test below is asymmetrical
    --   but this is correct, we will simply move backward a bit when moving left/up
    local are_subpixels_left = qx + projected_velocity_qx > world.get_quadrant_x_coord(motion_result.position, quadrant)

    if are_subpixels_left then
      -- character has not been blocked and has some subpixels left to go
      -- unlike Classic Sonic, and *only* when moving right/down, we decide to check if those
      --   subpixels would leak to hitting a q-wall on the right/down, and cut them if so,
      --   blocking the character on the spot (we just reuse the result of the extra step,
      --   since is_falling doesn't change if is_blocked is true)
      -- when moving left/up, the subpixels are a small "backward" motion to the right/down and should
      --  never hit a wall back
      local is_blocked_by_extra_step = false
      if projected_velocity_qx > 0 then
        local extra_step_motion_result = motion_result:copy()
        self:next_ground_step(quadrant_horizontal_dir, extra_step_motion_result)
        if extra_step_motion_result.is_blocked then
          motion_result = extra_step_motion_result
          is_blocked_by_extra_step = true
        end
      end

      -- unless moving right/down and hitting a q-wall due to subpixels, apply the remaining subpixels
      --   as they cannot affect collision anymore. when moving left/up, they go a little backward
      if not is_blocked_by_extra_step then
        -- character has not touched a q-wall at all, so add the remaining subpixels
        --   (it's simpler to just recompute the full motion in qx; don't touch qy though,
        --   as it depends on the shape of the ground - we floored it earlier but it should
        --   have been integer from the start so it shouldn't have changed anything)
        -- do not apply other changes (like slope) since technically we have not reached
        --   the next tile yet, only advanced of some subpixels
        world.set_position_quadrant_x(motion_result.position, qx + projected_velocity_qx, quadrant)
      end
    end
  end

  return motion_result
end

-- return the number of new pixel q-columns explored when moving from initial_position_coord (x or y)
--  over velocity_coord (x or y) * 1 frame. consider full pixel motion starting at floored coord,
--  even when moving in the negative direction
-- this is either flr(velocity_coord)
--  or flr(velocity_coord) + 1 (if subpixels from initial position coord and speed sum up to 1.0 or more)
-- note that for negative motion, we must go a bit beyond the next integer to count a full pixel motion,
--  and that is intended
function player_char.compute_max_pixel_distance(initial_position_coord, velocity_coord)
  return abs(flr(initial_position_coord + velocity_coord) - flr(initial_position_coord))
end

-- update ref_motion_result: motion.ground_motion_result for a character trying to move
--  by 1 pixel step in quadrant_horizontal_dir, taking obstacles into account
-- if character is blocked, it doesn't update the position and flag is_blocked
-- if character is falling, it updates the position and flag is_falling
-- ground_motion_result.position's qx should be floored for these steps
--  (some functions assert when giving subpixel coordinates)
function player_char:next_ground_step(quadrant_horizontal_dir, ref_motion_result)
  log("  next_ground_step: "..joinstr(", ", quadrant_horizontal_dir, ref_motion_result), "trace2")

  -- compute candidate position on next step. only flat slopes supported
  local step_vec = self:quadrant_rotated(horizontal_dir_vectors[quadrant_horizontal_dir])
  local next_position_candidate = ref_motion_result.position + step_vec

  log("step_vec: "..step_vec, "trace2")
  log("next_position_candidate: "..next_position_candidate, "trace2")

  -- check if next position is inside/above ground
  local query_info = self:compute_ground_sensors_query_info(next_position_candidate)
  local signed_distance_to_closest_ground = query_info.signed_distance

  log("signed_distance_to_closest_ground: "..signed_distance_to_closest_ground, "trace2")

  -- signed distance is useful, but for quadrant vector ops we need actual vectors
  --  to get the right signs (e.g. on floor, signed distance > 0 <=> offset dy < 0 from ground,
  --  but on left wall, signed distance > 0 <=> offset dx > 0)
  -- signed distance is from character to ground, so get unit vector for quadrant down
  local vector_to_closest_ground = signed_distance_to_closest_ground * self:get_quadrant_down()

  -- merge < 0 and == 0 cases together to spare tokens
  -- when 0, next_position_candidate.y will simply not change
  if signed_distance_to_closest_ground < 0 then
    -- position is inside ground, check if we can step up during this step
    -- (note that we kept the name max_ground_escape_height but in quadrant left and right,
    --  the escape is done on the X axis so technically we escape row width)
    -- refactor: code is similar to check_escape_from_ground and above all next_air_step
    if - signed_distance_to_closest_ground <= pc_data.max_ground_escape_height then
      -- step up or step flat
      next_position_candidate:add_inplace(vector_to_closest_ground)
      -- if we left the ground during a previous step, cancel that
      --  (fall, then touch ground or step up to land, very rare)
      ref_motion_result.is_falling = false
    else
      -- step blocked: step up is too high, character is blocked
      -- if character left the ground during a previous step, let it this way;
      --  character will simply hit the wall, then fall
      ref_motion_result.is_blocked = true
    end
  elseif signed_distance_to_closest_ground >= 0 then
    -- position is above ground, check if we can step down during this step
    -- (step down is during ground motion only)
    if signed_distance_to_closest_ground <= pc_data.max_ground_snap_height then
      -- if character has fallen during previous step, prevent step down AND no need to check for angle take-off
      --  note he can still re-land, but only by entering the ground i.e. signed distance to ground < 0, as in block above
      -- otherwise, character is still grounded, so check for angle take-off, and if not taking off, step down
      if not ref_motion_result.is_falling then
        -- Original slope feature: Take-Off Angle Difference
        -- When character falls when running from to ground, he could normally step down,
        --  but the new ground is a descending slope too steep compared to previous slope angle.
        -- Exceptionally not inside --#if original_slope_features because it really fixes glitches
        --  when character moves at low speed from flat ground to steep descending slope
        -- In the original, Sonic just runs on the steep descending slope as if nothing, and also exceptionally
        --  preserves his sprite angle, but that would have required extra code.
        -- Make sure to check if we are not already falling so slope angle exists (alternatively check that ref_motion_result.slope_angle is not nil)
        -- When running toward the left, angle diff has opposite sign, so multiply by horizontal sign to counter this
        -- Note that character is not falling, so grounded (during step), so ref_motion_result.slope_angle is not nil
        local signed_angle_delta = compute_signed_angle_between(query_info.slope_angle, ref_motion_result.slope_angle)
        if horizontal_dir_signs[quadrant_horizontal_dir] * signed_angle_delta > pc_data.take_off_angle_difference then
          -- step fall due to angle difference aka angle-based Take-Off
          ref_motion_result.is_falling = true
        else
          -- step down
          next_position_candidate:add_inplace(vector_to_closest_ground)
        end
      end
    else
      -- step fall: step down is too low, character will fall
      -- in some rare instances, character may find ground again farther, so don't stop the outside loop yet
      --  (but he'll need to really enter the ground i.e. signed distance to ground < 0)
      -- caution: we are not updating qy at all, which means the character starts
      --  "walking horizontally in the air". in sonic games, we would expect
      --  momentum to take over and send the character along qy, preserving
      --  velocity qvy from last frame (e.g. when running off a slope)
      -- consider reusing the last delta qy (e.g. vector_to_closest_ground qy)
      --  and applying it this frame
      -- but we tested and since we lose a single frame of step max, it's not perceptible:
      --  on the next airborne frames, the velocity and full air motion is more important and works
      --  as expected when running off a slope
      ref_motion_result.is_falling = true
    end
  end

  if not ref_motion_result.is_blocked then
    -- character is not blocked by a steep q-step up/q-wall, but we need to check if it is
    --  blocked by a q-ceiling too low; in the extreme case, a diagonal tile pattern
    --  ->X
    --   X
    --  is also considered a ceiling and ignoring it will let Sonic go through and fall
    -- (unlike Classic Sonic, we do check for ceilings even when Sonic is grounded;
    --  this case rarely happens in normally constructed levels though; and q-ceilings
    --  even more rare)
    ref_motion_result.is_blocked = self:is_blocked_by_ceiling_at(next_position_candidate)

    -- only advance if character is still not blocked (else, preserve previous position,
    --  which should be floored)
    -- this only works because the q-wall sensors are 1px farther from the character center
    --  than the ground sensors; if there were even farther, we'd even need to
    --  move the position backward by hypothetical wall_sensor_extent_x - ground_sensor_extent_x - 1
    --  when ref_motion_result.is_blocked (and adapt y)
    -- in addition, because a step is no more than 1px, if we were blocked this step
    --  we have not moved at all and therefore there is no need to update slope angle
    if not ref_motion_result.is_blocked then
      ref_motion_result.position = next_position_candidate
      if ref_motion_result.is_falling then
        ref_motion_result.tile_location = nil
        ref_motion_result.slope_angle = nil
      else
        ref_motion_result.tile_location = query_info.tile_location
        ref_motion_result.slope_angle = query_info.slope_angle
      end
    end
  end
end

-- return true iff the character cannot stand in his full height (based on ground_sensor_extent_x)
--  at position because of the ceiling (or a full tile if standing at the top of a tile)
function player_char:is_blocked_by_ceiling_at(center_position)

  -- note: we could use compute_ceiling_sensors_query_info and check for negative distance since it finds
  --  the closest ceiling, but it's slightly more optimal to stop as soon as first true collision is found
  -- if we lack characters in cartridge space, it's worth trying the other way though

  -- check ceiling from both ground sensors. if any finds one, return true
  for i in all({horizontal_dirs.left, horizontal_dirs.right}) do

    -- check if ground sensor #i has ceiling closer than a character's height
    local sensor_position = self:get_ground_sensor_position_from(center_position, i)
    local ceiling_query_info = self:compute_closest_ceiling_query_info(sensor_position)
    -- distance to ceiling is always negative or 0 as we never "step q-down" onto ceiling
    -- but we must still exclude the case of distance == 0 is case we are just touching ceiling, not blocked
    if ceiling_query_info.signed_distance < 0 then
      return true
    end

  end

  return false
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
    return nil
  end
end

-- actual body of _compute_signed_distance_to_closest_ceiling passed to iterate_over_collision_tiles
--  as no_collider_callback
local function ceiling_check_no_collider_callback()
  -- end of iteration, and no ceiling found
  return motion.ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil)
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
  return iterate_over_collision_tiles(self, oppose_dir(self.quadrant), pc_data.max_ground_escape_height + 1 - full_height, 0, sensor_position, full_height, ceiling_check_collider_distance_callback, ceiling_check_no_collider_callback, --[[ignore_reverse_on_start_tile:]] true)
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
    --  via _check_hold_jump (we don't do it here so we centralize the check and
    --  don't apply gravity during such a frame)
    -- to support slopes, we use the ground normal (rotate right tangent ccw)
    -- we don't have double jumps yet so we assume we are grounded here and
    --  self.slope_angle is not nil
    local jump_impulse = pc_data.initial_var_jump_speed_frame * vector.unit_from_angle(self.slope_angle):rotated_90_ccw()
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

      -- fill spin dash rev formula from SPG
      self.spin_dash_rev = min(self.spin_dash_rev + pc_data.spin_dash_rev_increase_step, pc_data.spin_dash_rev_max)

      -- visual
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

  -- apply air motion

  local air_motion_result = self:compute_air_motion_result()

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
  if flr(air_motion_result.position.x) < pc_data.ground_sensor_extent_x then
    -- clamp position to stage left edge and clamp velocity x to 0
    -- note that in theory we should update the air motion result
    --  tile location and slope angle to match the new position,
    --  but in practice we know that speeds are low and besides there is
    --  nothing on the left of the stage so basically we already have
    --  the ground info we need, worst case character will fall 1 extra frame
    --  then land
    air_motion_result.position.x = ceil(pc_data.ground_sensor_extent_x)
    self.velocity.x = max(0, self.velocity.x)
  end

  self.position = air_motion_result.position

  if air_motion_result.is_landing then
    -- register new ground tile, update slope angle and enter standing state
    self:set_ground_tile_location(air_motion_result.tile_location)
    self:set_slope_angle_with_quadrant(air_motion_result.slope_angle)
    -- always stand on ground, if we want to roll we'll switch to rolling on next frame
    self:enter_motion_state(motion_states.standing)
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

-- return {next_position: vector, is_blocked_by_ceiling: bool, is_blocked_by_wall: bool, is_landing: bool} where
--  - next_position is the position of the character next frame considering his current (air) velocity
--  - is_blocked_by_ceiling is true iff the character encounters a ceiling during this motion
--  - is_blocked_by_wall is true iff the character encounters a wall during this motion
--  - is_landing is true iff the character touches a ground from above during this motion
function player_char:compute_air_motion_result()
  -- if character is not moving, he is not blocked nor landing (we assume the environment is static)
  -- this is pretty rare in the air, but could happen when being pushed upward by fans
  if self.velocity:is_zero() then
    return motion.air_motion_result(
      nil,  -- start in air, so no ground tile
      self.position,
      false,
      false,
      false,
      nil
    )
  end

  -- initialize air motion result (do not floor coordinates, _advance_in_air_along will do it)
  local motion_result = motion.air_motion_result(
    nil,  -- start in air, so no ground tile
    vector(self.position.x, self.position.y),
    false,
    false,
    false,
    nil
  )

  -- from here, unlike ground motion, there are 3 ways to iterate:
  -- a. describe a Bresenham's line, stepping on x and y, for the best precision
  -- b. step on x until you reach the max distance x, then step on y (may hit wall you wouldn't have with a. or c.)
  -- c. step on y until you reach the max distance y, then step on x (may hit ceiling you wouldn't have with a. or b.)
  -- and 1 way without iteration:
  -- d. compute final position of air motion at the end of the frame, and escape from x and y if needed

  -- We choose b. which is precise enough while always finishing with a potential landing
  -- Initially we used c., but Sonic tended to fly above descending slopes as the X motion was applied
  --  after Y motion, including snapping, causing a ladder-shaped motion above the slope where the final position
  --  was always above the ground.
  -- Note, however, that this is a temporary fix: where we add quadrants, X and Y will have more symmetrical roles
  --  and we can expect similar issues when trying to land with high speed adherence on a 90-deg wall.
  -- Ultimately, I think it will work better with either d. or an Unreal-style multi-mode step approach
  --  (i.e. if landing in the middle of the Y move, finish the remaining part of motion as standing,
  --  following the ground as usual).
  self:advance_in_air_along(motion_result, self.velocity, "x")
  log("=> "..motion_result, "trace2")
  self:advance_in_air_along(motion_result, self.velocity, "y")
  log("=> "..motion_result, "trace2")

  return motion_result
end

-- TODO: factorize with compute_ground_motion_result?
-- modifies ref_motion_result in-place, setting it to the result of an air motion from ref_motion_result.position
--  over velocity:get(coord) px, where coord is "x" or "y"
function player_char:advance_in_air_along(ref_motion_result, velocity, coord)
  log("_advance_in_air_along: "..joinstr(", ", ref_motion_result, velocity, coord), "trace2")

  if velocity:get(coord) == 0 then return end

  -- only full pixels matter for collisions, but subpixels may sum up to a full pixel
  --  so first estimate how many full pixel columns the character may actually explore this frame
  local initial_position_coord = ref_motion_result.position:get(coord)
  local max_pixel_distance = player_char.compute_max_pixel_distance(initial_position_coord, velocity:get(coord))

  -- floor coordinate to simplify step by step pixel detection (mostly useful along x to avoid
  --  flooring every time we query column heights)
  -- since initial_position_coord is storing the original position with subpixels, we are losing information
  ref_motion_result.position:set(coord, flr(ref_motion_result.position:get(coord)))

  -- iterate pixel by pixel on the x direction until max possible distance is reached
  --  only stopping if the character is blocked by a wall (not if falling, since we want
  --  him to continue moving in the air as far as possible; in edge cases, he may even
  --  touch the ground again some pixels farther)
  local direction
  if coord == "x" then
    direction = directions.right
  else
    direction = directions.down
  end
  if velocity:get(coord) < 0 then
    direction = oppose_dir(direction)
  end

  local pixel_distance_before_step = 0
  while pixel_distance_before_step < max_pixel_distance and not ref_motion_result:is_blocked_along(direction) do
    self:next_air_step(direction, ref_motion_result)
    log("  => "..ref_motion_result, "trace2")
    pixel_distance_before_step = pixel_distance_before_step + 1
  end

  -- check if we need to add or cut subpixels
  if not ref_motion_result:is_blocked_along(direction) then
    -- since subpixels are always counted to the right, the subpixel test below is asymmetrical
    --   but this is correct, we will simply move backward a bit when moving left
    local are_subpixels_left = initial_position_coord + velocity:get(coord) > ref_motion_result.position:get(coord)
    -- local are_subpixels_left = initial_position_coord + max_pixel_distance > ref_motion_result.position:get(coord)
    if are_subpixels_left then
      -- character has not been blocked and has some subpixels left to go
      --  *only* when moving in the positive sense (right/up),
      --  as a way to clean the subpixels unlike classic sonic,
      --  we check if character is theoretically colliding a wall with those subpixels
      --  (we need an extra step to "ceil" the subpixels)
      -- when moving in the negative sense, the subpixels are a small "backward" motion
      --  to the positive sense and should
      --  never hit a wall back
      local is_blocked_by_extra_step = false
      if velocity:get(coord) > 0 then
        local extra_step_motion_result = ref_motion_result:copy()
        self:next_air_step(direction, extra_step_motion_result)
        log("  => "..ref_motion_result, "trace2")
        if extra_step_motion_result:is_blocked_along(direction) then
          -- character has just reached a wall, plus a few subpixels
          -- unlike classic sonic, we decide to cut the subpixels and block the character
          --  on the spot (we just reuse the result of the extra step, since is_falling doesn't change if is_blocked is true)
          -- it's very important to keep the reference and assign member values instead
          ref_motion_result:copy_assign(extra_step_motion_result)
          is_blocked_by_extra_step = true
        end
      end

      if not is_blocked_by_extra_step then
        -- character has not touched a wall at all, so add the remaining subpixels
        --  (it's simpler to just recompute the full motion in x; don't touch y tough,
        --  as it depends on the shape of the ground)
        -- do not apply other changes (like slope) since technically we have not reached
        --  the next tile yet, only advanced of some subpixels
        -- note that this calculation equivalent to adding to ref_motion_result.position:get(coord)
        --  sign(velocity:get(coord)) * (max_distance - distance_to_floored_coord)
        ref_motion_result.position:set(coord, initial_position_coord + velocity:get(coord))
        log("  => (after adding remaining subpx) "..ref_motion_result, "trace2")
      end
    end
  end
end

-- update ref_motion_result: motion.air_motion_result for a character trying to move
--  by 1 pixel step in direction in the air, taking obstacles into account
-- if character is blocked by wall, ceiling or landing when moving toward left/right, up or down resp.,
--  it doesn't update the position and the corresponding flag is set
-- air_motion_result.position.x/y should be floored for these steps
function player_char:next_air_step(direction, ref_motion_result)
  log("  next_air_step: "..joinstr(", ", direction, ref_motion_result), "trace2")

  local step_vec = dir_vectors[direction]
  local next_position_candidate = ref_motion_result.position + step_vec

  log("direction: "..direction, "trace2")
  log("step_vec: "..step_vec, "trace2")
  log("next_position_candidate: "..next_position_candidate, "trace2")

  -- we can only hit walls or the ground when stepping left, right or down
  -- (horizontal step of diagonal upward motion is OK)
  if direction ~= directions.up then
    -- query ground to check for obstacles (we only care about distance, not slope angle)
    -- note that we reuse the ground sensors for air motion, because they are good at finding
    --  collisions around the bottom left/right corners
    local query_info = self:compute_ground_sensors_query_info(next_position_candidate)
    local signed_distance_to_closest_ground = query_info.signed_distance

    log("signed_distance_to_closest_ground: "..signed_distance_to_closest_ground, "trace2")

    -- Check if the character has hit a ground or a wall
    -- First, following SPG (http://info.sonicretro.org/SPG:Solid_Tiles#Ceiling_Sensors_.28C_and_D.29),
    --  allow jump from an ascending sheer angle directly onto a platform. This includes moving horizontally.
    -- This must be combined with a step up (snap to ground top, but directly from the air) to really work
    if self.velocity.y > 0 or abs(self.velocity.x) > abs(self.velocity.y) then
      -- check if we are entering ground
      -- NOTE: for solid ground we could also consider *touching* as landing, by checking <= 0,
      --  then we'd need to move signed_distance_to_closest_ground definition outside direction ~= directions.up block
      --  and in the bottom block of this method, check if not ref_motion_result:is_blocked_along(direction) or
      --  signed_distance_to_closest_ground == 0, instead of just is_blocked_along, since when landing
      --  we are technically blocked along q-down, but must still update position to avoid getting stuck above ground
      if signed_distance_to_closest_ground < 0 then
        -- Just like during ground step, check the step height: if too high, we hit a wall and stay airborne
        --  else, we land
        -- This step up check is really important, even for low slopes:
        --  if not done, when Sonic lands on an ascending slope, it will consider the few pixels up
        --  to be a wall!
        -- I used to check direction == directions.down only, and indeed if you step 1px down,
        --  the penetration distance will be no more than 1 and you will always snap to ground.
        -- But this didn't work when direction left/right hit the slope.
        -- refactor: code is similar to check_escape_from_ground and above all next_ground_step
        if - signed_distance_to_closest_ground <= pc_data.max_ground_escape_height then
          next_position_candidate.y = next_position_candidate.y + signed_distance_to_closest_ground
          -- landing: the character has just set foot on ground, flag it and initialize slope angle
          -- note that we only consider the character to touch ground when it is about to enter it
          -- below deprecated if we <= 0 check
          -- therefore, if he exactly reaches signed_distance_to_closest_ground == 0 this frame,
          --  it is still technically considered in the air
          -- if this step is blocked by landing, there is no extra motion,
          --  but character will enter standing state
          ref_motion_result.is_landing, ref_motion_result.slope_angle = true, query_info.slope_angle
          -- WALL LANDING ADJUSTMENT OFFSET
          -- as part of the bigger adherence system, but for now very simplified
          --  to fix #129 BUG MOTION curve_run_up_fall_in_wall:
          --  if the quadrant changed (from the air default, down), we must adjust the character
          --  center position to stabilize his bottom position, so that his feet are just touching the new ground
          --  instead of entering it
          -- world.angle_to_quadrant will be called later as part of player_char:set_slope_angle_with_quadrant
          --  on the final air motion result, but we prefer adjusting the position now
          local new_quadrant = world.angle_to_quadrant(ref_motion_result.slope_angle)
          -- we only care about left and right wall, as character center is *centered* in the collision rectangle,
          --  if character becomes upside down (e.g. with ceiling adherence system) his feet will be placed
          --  where his head was when it hit the ceiling, so they will also touch the ceiling
          -- (currently character can only adhere to bottom-left or bottom-right slopes anyway, but if very steep
          --  they are turn the quadrant to the side)
          if new_quadrant % 2 == 0 then  -- equivalent to (new_quadrant == directions.left or new_quadrant == directions.right)
            -- unfortunaly, check_escape_from_ground even with the new quadrant code proved either unable to push
            --  the character out (already too deep in ground), or pushing the character out too much (when increasing escape threshold just there)
            --  when called after taking final air motion result into account and detecting landing
            -- so instead we manually adjust the position here, without being sure of how close to the ground
            --  we are due to the complex case of rotating near a slope, but as an estimation we consider that
            --  Sonic being a rectangle (almost a square when compact due to ground sensor 2.5 ~= compact center height 4 though,
            --  being the reason for bug #129 only showing when falling standing), by adding the difference ground/wall sensor
            --  vs center height we can somewhat escape from the ground and let next updates do the final adjustments
            --  (leaving ground again and falling again on flatter ground, or escaping ground on next full pixel ground motion
            --  so this time Sonic really steps exactly on the ground)
            local new_quadrant_down = dir_vectors[new_quadrant]
            local qupward_offset = - ceil(self:get_center_height() - pc_data.ground_sensor_extent_x) * new_quadrant_down
            ref_motion_result.position:add_inplace(qupward_offset)
          end
          -- to simplify we keep the tile location, even though in theory we should readjust it to the adjusted position,
          --  as we consider the position close enough, and if it sent us airborne then we'll just reland in a few frames anyway
          -- note that at this point, it would be good to return some signal to the caller (advance_in_air_along)
          --  to tell them to stop iterating because moving on XY after landing is not consistent,
          --  plus we may have started adjusting the position above (if quadrant is left or right)
          --  causing a weird result if we go on; but there are currently no visible issues in game
          ref_motion_result.tile_location = query_info.tile_location
          log("is landing at adjusted y: "..next_position_candidate.y..", setting slope angle to "..query_info.slope_angle, "trace2")
        else
          ref_motion_result.is_blocked_by_wall = true
          log("is blocked by wall", "trace2")
        end
      else
        -- in the air: the most common case, in general requires nothing to do
        -- in rare cases, the character has landed on a previous step, and we must cancel that now
        ref_motion_result.is_landing, ref_motion_result.slope_angle = false--, nil
        ref_motion_result.tile_location = nil
      end
    end
  end

  -- Ceiling check
  -- It is necessary during horizontal motion to complement
  --  ground sensors, the edge case being when the bottom of the character matches
  --  the bottom of a collision tile, ground sensors could only detect the tile below
  -- if we have already found a blocker above and are still in left/right direction
  --  then there is no need to check further, though.
  -- But, as in the case of a jump into a ceiling corner, we may have an old is_blocked_by_wall flag from a previous
  --  x motion step and now doing a y motion (in particular upward) that is unrelated.
  -- We definitely want to detect the wall on the side AND the ceiling, so if direction is up, ALSO check
  --  the ceiling even if wall was found in previous step.

  -- The SPG (http://info.sonicretro.org/SPG:Solid_Tiles#Ceiling_Sensors_.28C_and_D.29)
  --  remarks that ceiling detection is done when moving upward or when moving faster horizontally than vertically
  --  (this includes moving horizontally)
  -- Since it's just for this extra test, we check self.velocity directly instead of passing it as argument
  -- Note that we don't check the exact step direction, if we happen to hit the ceiling during
  --  the X motion, that's fine.
  -- In practice, when approaching a ceiling from a descending direction with a sheer horizontal angle,
  --  we will hit the block as a wall first; but that's because we consider blocks as wall and ceilings at the same time.
  -- If we wanted to be symmetrical with floor check above, we would need to call some check_escape_from_ceiling
  --  to snap Sonic slightly down when only hitting the wall by a few pixels, so character can continue moving horizontally
  --  under the ceiling, touching it at the beginning. But it doesn't seem to happen in Classic Sonic so we don't implement
  --  it unless our stage has ceilings where this often happens and it annoys the player.
  -- UPDATE: it doesn't seem to reliable as itest platformer slope ceiling block right
  --  would fail by considering character blocked by ascending slope above nothing
  --  I'm not sure why that itest used to work, but if having issues with this,
  --  add an extra check on ground step if no pixel is found (and exactly at a tile bottom)
  --  to see if there is not a collision pixel 1px above (should be on another tile above)
  --  and from here compute the actual ground distance... of course, always add supporting ground
  --  tile under a ground tile when possible
  -- UPDATE after adding landing on ceiling: the condition should still work with ceiling adherence catch,
  --  although the SPG doesn't mention it again in Slope Physics
  if not ref_motion_result.is_blocked_by_wall and
      (self.velocity.y < 0 or abs(self.velocity.x) > abs(self.velocity.y)) or direction == directions.up then
    local ceiling_query_info = self:compute_ceiling_sensors_query_info(next_position_candidate)

    -- if there is touch/collision with ceiling, tile_location is set
    if ceiling_query_info.tile_location then
      -- note that angles inclusive/exclusive are not exactly like SPG says, because the comparisons were asymmetrical,
      --  which must have made sense in terms of coding at the time, but we prefer symmetrical angles. Besides, we actually
      --  have ceiling slopes at 45 degrees which we'd like to adhere onto

--#if assert
      assert(ceiling_query_info.signed_distance <= 0, "player_char:next_air_step: touch/collision detected with ceiling "..
        "but signed distance is positive: "..ceiling_query_info.signed_distance)
      assert(ceiling_query_info.slope_angle > 0.25 and ceiling_query_info.slope_angle < 0.75,
        "player_char:next_air_step: touch/collision detected with ceiling and quadrant is always down when airborne, yet "..
        "ceiling_query_info.slope_angle is not between 0.25 and 0.75, it is: "..ceiling_query_info.slope_angle)
--#endif

      -- ceiling adherence
      -- https://info.sonicretro.org/SPG:Slope_Physics#When_Going_Upward
      if ceiling_query_info.slope_angle <= 0.25 + pc_data.ceiling_adherence_catch_range_from_vertical or
          ceiling_query_info.slope_angle >= 0.75 - pc_data.ceiling_adherence_catch_range_from_vertical then
        -- character lands on ceiling aka ceiling adherence catch (touching is enough, and no extra condition on velocity)
        ref_motion_result.tile_location = ceiling_query_info.tile_location
        -- no need to set position, we are not blocked by wall and should not be blocked along direction
        --  (mostly up for ceiling, and rarely left/right when entering this block with the sheer angle condition)
        --  so we'll enter the final block at the bottom which sets ref_motion_result.position to next_position_candidate
        ref_motion_result.is_landing = true
        ref_motion_result.slope_angle = ceiling_query_info.slope_angle
      elseif ceiling_query_info.signed_distance < 0 then
        -- character hit the hard (almost horizontal) ceiling and cannot adhere: just blocked by ceiling,
        --  or, if moving to the side, blocked by wall
        -- note that above we check for going inside ceiling to be exact, since just touching it should not block you,
        --  while landing on ceiling can happen just when touching ceiling (but difference is hard to see in game,
        --  as you rarely jump and just touch the ceiling anyway)
        if direction == directions.up then
          ref_motion_result.is_blocked_by_ceiling = true
          log("is blocked by ceiling", "trace2")
        else
          -- we would be blocked by ceiling on the next position, but since we can't even go there,
          --  we are actually blocked by the wall preventing the horizontal move
          -- 4-quadrant note: if moving diagonally downward, this will actually correspond to the SPG case
          --  mentioned above where ysp >= 0 but abs(xsp) > abs(ysp)
          -- in this case, we are really detecting the *ceiling*, but Sonic can also start running on it
          -- we should actually test the penetration distance is a symmetrical way to ground, not just the direction
          ref_motion_result.is_blocked_by_wall = true
          log("is blocked by ceiling as wall", "trace2")
        end
      end
    end
  end

  -- only advance if character is still not blocked (else, preserve previous position,
  --  which should be floored)
  if not ref_motion_result:is_blocked_along(direction) then
    -- this only works because the wall sensors are 1px farther from the character center
    --  than the ground sensors; if there were even farther, we'd even need to
    --  move the position backward by hypothetical wall_sensor_extent_x - ground_sensor_extent_x - 1
    --  when ref_motion_result:is_blocked_along() (and adapt y)
    ref_motion_result.position = next_position_candidate
    log("not blocked, setting motion result position to next candidate: "..next_position_candidate, "trace2")
  end
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

    -- reload spring jump top sprite cells
    self:reload_rotated_walk_and_crouch_sprites(--[[rotated_by_45_or_crouching: nil]])
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

  self.velocity = new_speed * vector.unit_from_angle(pc_data.launch_ramp_velocity_angle)
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
    self.anim_spr:play("brake_start")

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
    self.anim_spr:play("brake_reverse")

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
      self.anim_spr:play("idle")
    else
      -- standing and moving: play walk cycle at low speed, run cycle at high speed
      -- we have access to self.ground_speed but self.anim_run_speed is shorter than
      --  abs(self.ground_speed), and the values are the same for normal to high speeds
      if self.anim_run_speed < pc_data.run_cycle_min_speed_frame then
        self.anim_spr:play("walk", false, max(pc_data.walk_anim_min_play_speed, self.anim_run_speed))
      else
        self.anim_spr:play("run", false, self.anim_run_speed)
      end
    end
  elseif self.motion_state == motion_states.falling then
    -- stop spring jump anim when falling down again
    if self.should_play_spring_jump and self.velocity.y > 0 then
      self.should_play_spring_jump = false
    end

    if self.should_play_spring_jump then
      self.anim_spr:play("spring_jump")
    else
      -- normal fall -> run in the air (even if not working, just to avoid having Sonic falling idle
      --  e.g. when crumbling floor breaks beneath his feet; what Classic Sonic does, but we don't mind)
      -- we don't have access to previous ground speed as unlike original game, we clear it when airborne
      --  but we can use the stored anim_run_speed, which is the same except for very low speed
      -- (and we don't mind them as we are checking run cycle for high speeds)
      if self.anim_run_speed < pc_data.run_cycle_min_speed_frame then
        self.anim_spr:play("walk", false, max(pc_data.walk_anim_min_play_speed, self.anim_run_speed))
      else
        -- run_cycle_min_speed_frame > walk_anim_min_play_speed so no need to clamp here
        self.anim_spr:play("run", false, self.anim_run_speed)
      end
    end
  elseif self.motion_state == motion_states.crouching then
    -- we don't mind about speed here, character can totally slide at low speed due to momentum or slope
    self.anim_spr:play("crouch")
  elseif self.motion_state == motion_states.spin_dashing then
    -- TODO: restart spin dash on each rev
    self.anim_spr:play("spin_dash")
  else -- self.motion_state == motion_states.rolling and self.motion_state == motion_states.air_spin
    local min_play_speed = self.motion_state == motion_states.rolling and
      pc_data.rolling_spin_anim_min_play_speed or pc_data.air_spin_anim_min_play_speed
    self.anim_spr:play("spin", false, max(min_play_speed, self.anim_run_speed))
  end
end

-- update sprite angle (falling only)
function player_char:check_update_sprite_angle()
  local angle = self.continuous_sprite_angle
  assert(0 <= angle and angle < 1, "player_char:update_sprite_angle: expecting modulo angle, got: "..angle)

  if self.motion_state == motion_states.falling and angle ~= 0 then
    if angle < 0.5 then
      -- just apply friction calculation as usual
      self.continuous_sprite_angle = max(0, abs(angle) - pc_data.sprite_angle_airborne_reset_speed_frame)
    else
      -- problem is we must rotate counter-clockwise toward 1 which is actually 0 modulo 1
      --  so we increase angle, clamp to 1 and % 1 so if we reached 1, we now have 0 instead
      self.continuous_sprite_angle = min(1, abs(angle) + pc_data.sprite_angle_airborne_reset_speed_frame) % 1
    end
  end
end

-- replace all Sonic walk sprites that have a 45-degree rotation variant
--  with either the non-rotated or the 45-degree rotation variant
-- also replace the idle + spring_jump (top) vs crouch sprites since they are
--  on the same row so it allows a single big copy operation
-- this is OK as Sonic only shows one sprite at a time (and there is no rotated
--  crouch sprite)
-- requirement: stage_state:reload_runtime_data must have been called
function player_char:reload_rotated_walk_and_crouch_sprites(rotated_by_45_or_crouching)
  -- see stage_state:reload_runtime_data for address explanation
  -- basically we are copying sprites general memory (with the correct
  --  address offset if rotated), back into the current spritesheet memory
  -- following stage_state:reload_runtime_data, offset between built-in and runtime sprites
  --  is 0x880
  local addr_offset = rotated_by_45_or_crouching and 0x880 or 0

  -- copy 6 walk sprites + idle + spring_jump top (if not rotated_by_45_or_crouching)
  --  or 6 walk sprites (rotated) + crouch sprites from general memory to
  --  current spritesheet memory
  memcpy(0x1000, 0x4b00 + addr_offset, 0x400)  -- next address: 0x5700
end

-- same as reload_rotated_sprites_walk, but for run sprites
function player_char:reload_rotated_run_sprites(rotated_by_45)
  local addr_offset = rotated_by_45 and 0x880 or 0

  -- same as reload_rotated_sprites_walk, but we must iterate over partial lines
  for i = 0, 15 do
    -- 4 run cycle sprites
    memcpy(0x1400 + i * 0x40, 0x4f00 + addr_offset + i * 0x20, 0x20)
  end
end

-- same as reload_rotated_run_sprites, but for rolling/spin dash sprites
function player_char:reload_rolling_vs_spin_dash_sprites(spin_dashing)
  local addr_offset = spin_dashing and 0x880 or 0

  -- same as reload_rotated_sprites_walk, but we must iterate over partial lines
  for i = 0, 15 do
    -- 5 rolling / spin dashing sprites
    memcpy(0x1800 + i * 0x40, 0x5100 + addr_offset + i * 0x28, 0x28)
  end
end

-- render the player character sprite at its current position
function player_char:render()
  -- floor position to avoid jittering when running on ceiling due to
  --  partial pixel position being sometimes one more pixel on the right due after 180-deg rotation
  local floored_position = vector(flr(self.position.x), flr(self.position.y))
  local flip_x = self.orientation == horizontal_dirs.left
  local sprite_angle = 0

  -- only walk and run can use rotated sprite
  if contains({"walk", "run"}, self.anim_spr.current_anim_key) then
    -- snap render angle to a few set of values (45 degrees steps), classic style
    --  (unlike Freedom Planet and Sonic Mania)
    -- 45 degrees is 0.125 = 1/8, so by multiplying by 8, each integer represent a 45-degree step
    --  we just need to add 0.5 before flooring to effectively round to the closest step, then go back
    sprite_angle = flr(8 * self.continuous_sprite_angle + 0.5) / 8

    -- TODO OPTIMIZATION: store which sprite rows were loaded last, and only reload if needed

    -- an computed rotation of 45 degrees would result in an ugly sprite
    --  so we only use rotations multiple of 90 degrees, using handmade 45-degree
    --  sprites when we want a better angle resolution
    if sprite_angle % 0.25 == 0 then
      -- closest 45-degree angle is already cardinal, we can safely rotate
      -- still make sure we use non-rotated sprites in case we changed them earlier
      if self.anim_spr.current_anim_key == "walk" then
        self:reload_rotated_walk_and_crouch_sprites(--[[rotated_by_45_or_crouching: nil]])
      else  -- self.anim_spr.current_anim_key == "run"
        self:reload_rotated_run_sprites(--[[rotated_by_45: nil]])
      end
    else
      -- closest 45-degree angle is diagonal, reload 45-degree sprite variants
      if self.anim_spr.current_anim_key == "walk" then
        self:reload_rotated_walk_and_crouch_sprites(--[[rotated_by_45_or_crouching:]] true)
      else  -- self.anim_spr.current_anim_key == "run"
        self:reload_rotated_run_sprites(--[[rotated_by_45:]] true)
      end

      -- rotated sprite embeds a rotation of 45 degrees, so if not flipped, rotate by angle - 45 degrees
      -- if flipped, the sprite is 45 degrees *behind* the horizontal left, so we must add 45 degrees instead
      sprite_angle = sprite_angle + (flip_x and 1 or -1) * 0.125
    end
  else
    if self.anim_spr.current_anim_key == "idle" then
      -- idle sprite is never rotated, and we need to reload it after a spin dash -> rolling -> standing again
      --  as in this case we leave crouching without reloading the idle sprite in check_crouch_and_roll_start
      self:reload_rotated_walk_and_crouch_sprites(--[[rotated_by_45_or_crouching: nil]])
    end
  end

  self.anim_spr:render(floored_position, flip_x, false, sprite_angle)
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
function player_char:debug_draw_rays()
  -- debug "raycasts"
  for debug_ray in all(self.debug_rays) do
    local start = debug_ray.start
    local end_pos = debug_ray.start + debug_ray.distance * debug_ray.direction
    if debug_ray.distance <= 0 then
      -- inside ground, ray will be all read up to surface
      line(start.x, start.y, end_pos.x, end_pos.y, colors.red)
    else
      -- q-above ground, ray will be blue except the last pixel (subtract direction which is
      --  a cardinal unit vector to get the penultimate pixel)
      local before_end_pos = end_pos - debug_ray.direction
      line(start.x, start.y, before_end_pos.x, before_end_pos.y, colors.pink)
      mset(end_pos.x, end_pos.y, colors.red)
    end
  end
end

function player_char:debug_print_info()
  -- debug info
  api.print("state: "..self.motion_state, 8, 94, colors.white)
  api.print("quadrant: "..tostr(self.quadrant), 8, 100, colors.white)
  api.print("slope: "..tostr(self.slope_angle), 8, 106, colors.white)
  api.print("x: "..self.position.x, 8, 112, colors.white)
  api.print("y: "..self.position.y, 8, 118, colors.white)
end
--#endif

return player_char

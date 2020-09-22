--#if log
local _logging = require("engine/debug/logging")
--#endif
local flow = require("engine/application/flow")
local input = require("engine/input/input")
local animated_sprite = require("engine/render/animated_sprite")

local collision_data = require("data/collision_data")
local pc_data = require("data/playercharacter_data")
local motion = require("platformer/motion")
local world = require("platformer/world")
local audio = require("resources/audio")
local visual = require("resources/visual")

-- enum for character control
control_modes = {
  human = 1,      -- player controls character
  ai = 2,         -- ai controls character
  puppet = 3      -- itest script controls character
}

-- motion_modes and motion_states are accessed dynamically via variant name in itest_dsl
--  so we don't strip them away from pico8 builds
-- it is only used for debug and expectations, though, so it could be #if cheat/test only,
--  but the dsl may be used for attract mode later (dsl) so unless we distinguish
--  parsable types like motion_states that are only used for expectations (and cheat actions)
--  as opposed to actions, we should keep this in the release build

-- enum for character motion mode
motion_modes = {
  platformer = 1, -- normal in-game
  debug = 2       -- debug "fly" mode
}

-- enum for character motion state in platformer mode
motion_states = {
  grounded = 1,  -- character is idle or running on the ground
  falling  = 2,  -- character is falling in the air, but not spinning
  air_spin = 3   -- character is in the air after a jump
}


local player_char = new_class()

-- parameters

-- spr_data               {string: sprite_data}   sprite data for this character
-- debug_move_max_speed   float                   move max speed in debug mode
-- debug_move_accel       float                   move acceleration in debug mode
-- debug_move_decel       float                   move deceleration in debug mode


-- components

-- anim_spr               animated_sprite controls sprite animation, responsible for sprite rendering


-- state vars

-- control_mode             control_modes   control mode: human (default) or ai
-- motion_mode   (cheat)    motion_modes    motion mode: platformer (under gravity) or debug (fly around)
-- motion_state             motion_states   motion state (platformer mode only)
-- quadrant                 directions      down vector of quadrant where character is located (down on floor, up on ceiling, left/right on walls)
-- orientation              horizontal_dirs direction faced by character
-- active_loop_layer        int             currently active loop layer (1 for entrance, 2 for exit)

-- ground_tile_location     location|nil    location of current ground tile character is on (nil if airborne)
-- position                 vector          current position (character center "between" pixels)
-- ground_speed             float           current speed along the ground (~px/frame)
-- horizontal_control_lock_timer    float   time left before regaining horizontal control after fall/slide off
-- velocity                 vector          current velocity in platformer mode (px/frame)
-- debug_velocity           vector          current velocity in debug mode (m/s)
-- slope_angle              float           slope angle of the current ground (clockwise turn ratio)
-- ascending_slope_time     float           time before applying full slope factor, when ascending a slope (s)

-- move_intention           vector          current move intention (normalized)
-- jump_intention           bool            current intention to start jump (consumed on jump)
-- hold_jump_intention      bool            current intention to hold jump (always true when jump_intention is true)
-- should_jump              bool            should the character jump when next frame is entered? used to delay variable jump/hop by 1 frame
-- has_jumped_this_frame    bool            has the character started a jump/hop this frame?
-- has_interrupted_jump     bool            has the character already interrupted his jump once?

-- anim_spr                 animated_sprite animated sprite component
-- anim_run_speed           float           Walk/Run animation playback speed. Reflects ground_speed, but preserves value even when falling.
-- continuous_sprite_angle  float           Sprite angle with high precision used internally. Reflects slope_angle when grounded, but gradually moves toward 0 (upward) when airborne.
--                                          To avoid ugly sprite rotations, only a few angle steps are actually used on render.
-- should_play_spring_jump  bool            Set to true when sent upward in the air thanks to spring, and not falling down yet
function player_char:init()
  self.spr_data = pc_data.sonic_sprite_data
  self.debug_move_max_speed = pc_data.debug_move_max_speed
  self.debug_move_accel = pc_data.debug_move_accel
  self.debug_move_decel = pc_data.debug_move_decel

  self.anim_spr = animated_sprite(pc_data.sonic_animated_sprite_data_table)

  self:setup()
end

function player_char:setup()
  self.control_mode = control_modes.human
--#if cheat
  self.motion_mode = motion_modes.platformer
--#endif
  self.motion_state = motion_states.grounded
  self.quadrant = directions.down
  self.orientation = horizontal_dirs.right
  self.active_loop_layer = 1

  -- impossible value makes sure that first set_ground_tile_location
  --  will trigger change event
  self.ground_tile_location = location(-1, -1)
  self.position = vector(-1, -1)
  self.ground_speed = 0.
  self.horizontal_control_lock_timer = 0.
  self.velocity = vector.zero()
  self.debug_velocity = vector.zero()
  -- slope_angle starts at 0 instead of nil to match grounded state above
  -- (if spawning in the air, fine, next update will reset angle to nil)
  self.slope_angle = 0.
  self.ascending_slope_time = 0.

  self.move_intention = vector.zero()
  self.jump_intention = false
  self.hold_jump_intention = false
  self.should_jump = false
  self.has_jumped_this_frame = false
  self.has_interrupted_jump = false

  self.anim_spr:play("idle")
  self.anim_run_speed = 0.
  self.continuous_sprite_angle = 0.
  self.should_play_spring_jump = false
end

function player_char:is_grounded()
  return self.motion_state == motion_states.grounded
end

function player_char:is_compact()
  return self.motion_state == motion_states.air_spin
end

function player_char:get_center_height()
  return self:is_compact() and pc_data.center_height_compact or pc_data.center_height_standing
end

function player_char:get_full_height()
  return self:is_compact() and pc_data.full_height_compact or pc_data.full_height_standing
end

-- return quadrant tangent right (forward) unit vector
function player_char:get_quadrant_right()
  return dir_vectors[rotate_dir_90_ccw(self.quadrant)]
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

-- spawn character at given bottom position, with same post-process as spawn_at
function player_char:spawn_bottom_at(bottom_position)
  self:spawn_at(bottom_position - vector(0, self:get_center_height()))
end

-- warp character to specific position, and update motion state (grounded/falling)
-- while escaping from ground if needed
--  use this when you don't want to reset the character state as spawn_at does
function player_char:warp_to(position)
  self.position = position

  -- character is initialized grounded, but let him fall if he is spawned in the air
  -- if grounded, also allows to set ground tile properly
  self:check_escape_from_ground()
end

-- same as warp_to, but with bottom position
function player_char:warp_bottom_to(bottom_position)
  self:warp_to(bottom_position - vector(0, self:get_center_height()))
end

-- move the player character so that the bottom center is at the given position
--#if itest
function player_char:get_bottom_center()
  return self.position + self:get_center_height() * self:get_quadrant_down()
end
--#endif

--#if busted
-- move the player character so that the bottom center is at the given position
function player_char:set_bottom_center(bottom_center_position)
  self.position = bottom_center_position - self:get_center_height() * self:get_quadrant_down()
end
--#endif

-- set ground tile location and apply any trigger if it changed
function player_char:set_ground_tile_location(tile_loc)
  if self.ground_tile_location ~= tile_loc then
    self.ground_tile_location = tile_loc

    -- gradually switching to visual tile flag convention:
    -- flags should now be placed on visual sprites, not collision masks,
    --  so collision masks can be reused for tiles and items with very different behaviors,
    --  e.g. half-tile vs spring
    -- to complete switching, replace all mask_tile_id with visual_tile_id,
    --  remove redundant mask tiles made for curves that are like loops but without
    --  loop flags, and move the loop flags back to loop visual tiles

    -- when touching loop entrance trigger, enable entrance (and disable exit) layer
    --  and reversely
    -- we are now checking loop triggers directly from stage data
    local stage_state = flow.curr_state
    assert(stage_state.type == ':stage')

    if stage_state:is_tile_loop_entrance_trigger(tile_loc) then
      -- note that active loop layer may already be 1
      log("set active loop layer: 1", 'loop')
      self.active_loop_layer = 1
    elseif stage_state:is_tile_loop_exit_trigger(tile_loc) then
      -- note that active loop layer may already be 2
      log("set active loop layer: 2", 'loop')
      self.active_loop_layer = 2
    end
  end
end

-- set slope angle and update quadrant
-- if force_upward_sprite is true, set sprite angle to 0
-- else, set sprite angle to angle (if not nil)
function player_char:set_slope_angle_with_quadrant(angle, force_upward_sprite)
  assert(angle == nil or 0. <= angle and angle <= 1., "player_char:set_slope_angle_with_quadrant: angle is "..tostr(angle)..", should be nil or between 0 and 1 (apply % 1 is needed)")

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
  self:handle_input()
  self:update_motion()
  self:update_anim()
  self.anim_spr:update()
end

-- update intention based on current input
function player_char:handle_input()
  if self.control_mode == control_modes.human then
    -- move
    local player_move_intention = vector.zero()

    -- ignore horizontal input when *grounded* with control lock timer is active
    -- checking == 0 is enough, <= 0 is just for safety
    if self.motion_state ~= motion_states.grounded or self.horizontal_control_lock_timer <= 0 then

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
    --  but in pico-sonic we prefer decrementing timer when airborne, so after a long fall or jump you
    --  can immediately get control back
    -- to restore original game behavior, uncomment the line below and comment out the 2nd line below
    -- if self.horizontal_control_lock_timer > 0 and self.motion_state == motion_states.grounded then
    if self.horizontal_control_lock_timer > 0 then
      -- decrement control lock frame timer
      -- normally it's better to update non-intention state vars
      --  in a normal update method not _handle_input, but since we know
      --  that both are updated at 60FPS, it shouldn't be a problem here
      self.horizontal_control_lock_timer = self.horizontal_control_lock_timer - 1
    end

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
  end
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
    self:spawn_at(self.position)
  else  -- self.motion_mode == motion_modes.debug
    self.debug_velocity = vector.zero()
  end
end
--#endif

-- update player position
function player_char:update_motion()
--#if cheat
  if self.motion_mode == motion_modes.debug then
    self:update_debug()
    return
  end
  -- else: self.motion_mode == motion_modes.platformer
--#endif

  self:update_platformer_motion()
end

-- return (signed_distance, slope_angle) where:
--  - signed_distance is the signed distance to the highest ground when character center is at center_position,
--   either negative when (in abs, penetration height)
--   or positive (actual distance to ground), always abs clamped to tile_size+1
--  - slope_angle is the slope angle of the highest ground. in case of tie,
--   the character's velocity x sign, then his horizontal direction determines which ground is chosen
-- if both sensors have different signed distances,
--  the lowest signed distance is returned (to escape completely or to have just 1 sensor snapping to the ground)
function player_char:compute_ground_sensors_query_info(center_position)

  -- initialize with negative value to return if the character is not intersecting ground
  local min_signed_distance = 1 / 0  -- max (32768 in pico-8, but never enter it manually as it would be negative)
  local highest_ground_query_info = nil

  -- check both ground sensors for ground
  for i=1,2 do
  -- equivalent to:
  -- for i in all({horizontal_dirs.left, horizontal_dirs.right}) do

    -- check that ground sensor #i is on top of or below the mask column
    local sensor_position = self:get_ground_sensor_position_from(center_position, i)
    local query_info = self:compute_closest_ground_query_info(sensor_position)
    local signed_distance = query_info.signed_distance

    -- apply ground priority rule: highest ground, then ground speed (velocity X in the air) sign breaks tie,
    --  then q-horizontal direction breaks tie

    -- store the biggest penetration height among sensors
    -- case a: this ground is higher than the previous one, store new height and slope angle
    -- case b: this ground has the same height as the previous one, but character orientation
    --  makes him stand on that one rather than the previous one, so we use its slope
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
  local offset_qx_vector = self:quadrant_rotated(vector(horizontal_dir_signs[quadrant_horizontal_dir] * pc_data.ground_sensor_extent_x, 0))
  -- brutal way to floor coordinates are rotation, without having to extract qx, recreating (qx, 0) vector and rotating again
  offset_qx_vector = vector(flr(offset_qx_vector.x), flr(offset_qx_vector.y))

  return qx_floored_bottom_center + offset_qx_vector
end

-- helper method for _compute_closest_ground_query_info and _is_blocked_by_ceiling_at
-- for given player character pc, it iterates over tiles from start to last (defined via offset from sensor position), providing distance from sensor_position_base + sensor_offset_qy along q-down (foot or head)
--  to q-column q-top (with reverse tile support) to custom callbacks which should return ground query info to closest ground/ceiling in quadrant direction
-- pass it a quadrant of interest (direction used to check collisions), iteration start and last tile locations
local function iterate_over_collision_tiles(pc, collision_check_quadrant, start_tile_offset_qy, last_tile_offset_qy, sensor_position_base, sensor_offset_qy, collider_distance_callback, no_collider_callback, ignore_reverse_on_start_tile)
  -- get check quadrant down vector (for ceiling check, it's actually up relative to character quadrant)
  local collision_check_quadrant_down = dir_vectors[collision_check_quadrant]

  -- apply sensor offset along check quadrant down (only used for ceiling, so actually upward to get head top position)
  local sensor_position = sensor_position_base + sensor_offset_qy * collision_check_quadrant_down

  assert(world.get_quadrant_x_coord(sensor_position, collision_check_quadrant) % 1 == 0, "iterate_over_collision_tiles: sensor_position qx must be floored, found "..sensor_position)

  -- deduce start and last tile from offset from the sensor position
  --  always oriented with check quadrant (by convention we check from q-top to q-bottom)
  -- p8tool has a bug that prevents support of (complex expression):method() syntax (although PICO-8 does support it)
  --  so we play on the fact that method = function bound to self and just write the .static_method(self) syntax (same token count)
  local start_tile_loc = vector.to_location(sensor_position + start_tile_offset_qy * collision_check_quadrant_down)
  local last_tile_loc = vector.to_location(sensor_position + last_tile_offset_qy * collision_check_quadrant_down)

  -- precompute start tile topleft (we're actually only interested in sensor location topleft,
  --  and both have the same qx)
  local start_tile_topleft = start_tile_loc:to_topleft_position()

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

  -- start iteration from start_tile_loc
  local curr_tile_loc = start_tile_loc:copy()

  -- keep looping until callback is satisfied (in general we found a collision or neary ground)
  --  or we've reached the last tile
  while true do
    local qcolumn_height, slope_angle

    -- check for tile collision special cases (world.compute_qcolumn_height_at
    --  does *not* check for this since it requires player character state)

    local ignore_tile = false

    local stage_state = flow.curr_state
    assert(stage_state.type == ':stage')

    -- we now check loop layer belonging directly from stage data
    if pc.active_loop_layer == 1 and stage_state:is_tile_in_loop_exit(curr_tile_loc) or
        pc.active_loop_layer == 2 and stage_state:is_tile_in_loop_entrance(curr_tile_loc) then
      ignore_tile = true
    end

    if ignore_tile then
        -- tile is on layer with disabled collision, return emptiness
        qcolumn_height, slope_angle = 0--, nil
    else
      -- Ceiling ignore reverse full tiles on first tile. Comment from _is_column_blocked_by_ceiling_at
      --  before extracting iterate_over_collision_tiles
      -- on the first tile, we don't cannot really be blocked by a ground
      --  with the same interior direction as quadrant <=> opposite to quadrant_opp
      --  (imagine Sonic standing on a half-tile; this definitely cannot be ceiling)
      --  so we do not consider the reverse collision with full tile_size q-height with them
      -- if you're unsure, try to force-set this to false and you'll see utests like
      --  '(1 ascending slope 45) should return false for sensor position on the left of the tile'
      --  failing
      local ignore_reverse = ignore_reverse_on_start_tile and start_tile_loc == curr_tile_loc

      -- check for ground (by q-column) in currently checked tile, at sensor qX
      qcolumn_height, slope_angle = world.compute_qcolumn_height_at(curr_tile_loc, qcolumn_index0, collision_check_quadrant, ignore_reverse)
    end

    -- a q-column height of 0 doesn't mean that there is ground just below relative offset qy = 0,
    --  but that the q-column is empty and we don't know what is more below
    -- so don't do anything yet but check for the tile one level lower
    --  (unless we've reached end of iteration with the last tile, in which case
    --  the next tile would be too far to snap down anyway)
    if qcolumn_height > 0 then
      -- get q-bottom of tile to compare heights
      -- when iterating q-upward (ceiling check) this is actually a q-top from character's perspective
      local current_tile_qbottom = world.get_tile_qbottom(curr_tile_loc, collision_check_quadrant)

      -- signed distance to closest ground/ceiling is positive when q-above ground/q-below ceiling
      -- PICO-8 Y sign is positive up, so to get the current relative height of the sensor
      --  in the current tile, you need the opposite of (quadrant-signed) (sensor_position.qy - current_tile_qbottom)
      -- then subtract qcolumn_height and you get the signed distance to the current ground q-column
      local signed_distance_to_closest_collider = world.sub_qy(current_tile_qbottom, world.get_quadrant_y_coord(sensor_position, collision_check_quadrant), collision_check_quadrant) - qcolumn_height

      -- let caller decide how to handle the presence of collider
      local result = collider_distance_callback(curr_tile_loc, signed_distance_to_closest_collider, slope_angle)

      -- we cannot 2x return from a called function directly, so instead, we check if a result was returned
      --  if so, we return from the caller
      if result then
        return result
      end

      -- else (can only happen in _compute_closest_ground_query_info): ground has been found, but it is too far below character's q-feet
      --  to snap q-down. This can only happen on the last tile we iterate on
      --  (since it was computed to be at the snap q-down limit),
      --  which means we will enter the "end of iteration" block below
      assert(curr_tile_loc == last_tile_loc)
    end

    -- since we only iterate on qj, we really only care about qj (which is i when quadrant is horizontal)
    --  but it costed more token to define get_quadrant_j_coord than to just compare both coords
    if curr_tile_loc == last_tile_loc then
      -- let caller decide how to handle the end of iteration without finding any collider
      return no_collider_callback()
    end

    curr_tile_loc = curr_tile_loc + tile_loc_step
  end
end

-- actual body of _compute_closest_ground_query_info passed to iterate_over_collision_tiles
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

-- actual body of _compute_closest_ground_query_info passed to iterate_over_collision_tiles
--  as no_collider_callback
local function ground_check_no_collider_callback()
  -- end of iteration, and no ground found or too far below to snap q-down
  -- return edge case for ground considered too far below
  --  (pc_data.max_ground_snap_height + 1, nil)
  return motion.ground_query_info(nil, pc_data.max_ground_snap_height + 1, nil)
end

-- return (signed_distance, slope_angle) where:
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
-- finally, enter grounded state if the character was either touching the ground or inside it (even too deep),
--  else enter falling state
function player_char:check_escape_from_ground()
  local query_info = self:compute_ground_sensors_query_info(self.position)
  local signed_distance_to_closest_ground, next_slope_angle = query_info.signed_distance, query_info.slope_angle
  if signed_distance_to_closest_ground <= 0 then
    if - signed_distance_to_closest_ground <= pc_data.max_ground_escape_height then
      -- character is either just touching ground (signed_distance_to_closest_ground == 0)
      --  or inside ground, so:
      -- snap character up to ground top (it does nothing if already touching ground)
      self.position.y = self.position.y + signed_distance_to_closest_ground
      -- register ground tile for later
      self:set_ground_tile_location(query_info.tile_location)
      -- set slope angle to new ground
      self:set_slope_angle_with_quadrant(next_slope_angle)
    else
      -- by convention, set ground tile location to nil (see ground_check_collider_distance_callback)
      -- by slope angle to 0 to stand upward
      self.ground_tile_location = nil
      self:set_slope_angle_with_quadrant(0)
    end
    self:enter_motion_state(motion_states.grounded)
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
  -- store previous compact state before changing motion state
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
  elseif next_motion_state == motion_states.air_spin then
    -- we have just jumped, enter air_spin state
    --  and since ground speed is now unused, reset it for clarity
    self.ground_tile_location = nil
    self:set_slope_angle_with_quadrant(nil, --[[force_upward_sprite:]] true)
    self.ground_speed = 0
    self.should_jump = false
    self.should_play_spring_jump = false
  elseif next_motion_state == motion_states.grounded then
    -- Momentum: transfer part of velocity tangential to slope to ground speed (self.slope_angle must have been set previously)
    self.ground_speed = self.velocity:dot(vector.unit_from_angle(self.slope_angle))
    self:clamp_ground_speed()
    -- we have just reached the ground (and possibly escaped),
    --  reset values airborne vars
    self.has_jumped_this_frame = false  -- optional since consumed immediately in _update_platformer_motion_airborne
    self.has_interrupted_jump = false
    self.should_play_spring_jump = false
  end
end

-- update velocity, position and state based on current motion state
function player_char:update_platformer_motion()
  -- check for jump before apply motion, so character can jump at the beginning of the motion
  --  (as in classic Sonic), but also apply an initial impulse if character starts idle and
  --  left/right is pressed just when jumping (to fix classic Sonic missing a directional input frame there)
  if self.motion_state == motion_states.grounded then
    self:check_jump()  -- this may change the motion state to air_spin and affect branching below
  end

  if self:is_grounded() then
    self:update_platformer_motion_grounded()
  else
    self:update_platformer_motion_airborne()
  end

  self:check_spring()
  self:check_emerald()
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
    self.horizontal_control_lock_timer = pc_data.horizontal_control_lock_duration
  end

  if should_fall then
    self:enter_motion_state(motion_states.falling)
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
  --  will be considered for the move intention effect, such as decelerating
  --  when moving forward on an ascending slope if it started make you move down.
  -- Also, if ground speed is 0 and we start trying to ascend slope,
  --  Progressive Ascending Steep Slope Factor feature won't be applied the first frame.
  -- But it should be OK overall.
  -- Note that this order is supported by the SPG (http://info.sonicretro.org/SPG:Solid_Tiles)
  self:update_ground_speed_by_slope()
  self:update_ground_speed_by_intention()
  self:clamp_ground_speed()
end

-- update ground speed based on current slope
function player_char:update_ground_speed_by_slope()
  local is_ascending_slope = false

  if self.slope_angle ~= 0 then
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
    end

    -- slope angle is mostly defined with atan2(dx, dy) which follows top-left origin BUT counter-clockwise angle convention
    -- sin also follows this convention, so ultimately + is OK
    self.ground_speed = self.ground_speed + ascending_slope_factor * pc_data.slope_accel_factor_frame2 * sin(self.slope_angle)
  end

  if not is_ascending_slope then
    -- reset ascending slope time
    self.ascending_slope_time = 0
  end
end

-- update ground speed based on current move intention
function player_char:update_ground_speed_by_intention()
  if self.move_intention.x ~= 0 then

    if self.ground_speed == 0 or sgn(self.ground_speed) == sgn(self.move_intention.x) then
      -- accelerate
      self.ground_speed = self.ground_speed + self.move_intention.x * pc_data.ground_accel_frame2
      -- face move direction if not already
      self.orientation = signed_speed_to_dir(self.move_intention.x)
    else
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
      self.ground_speed = self.ground_speed + self.move_intention.x * ground_decel_factor * pc_data.ground_decel_frame2
      -- check if speed has switched sign this frame, i.e. character has turned around
      local has_changed_sign = self.ground_speed ~= 0 and sgn(self.ground_speed) == sgn(self.move_intention.x)

      if has_changed_sign then
        -- clamp speed after turn around by ground accel in absolute value to prevent exploit of
        --  moving back 1 frame then forward to gain an initial speed boost (mentioned in Sonic Physics Guide as a bug)
        if abs(self.ground_speed) > pc_data.ground_accel_frame2 then
          self.ground_speed = sgn(self.ground_speed) * pc_data.ground_accel_frame2
        end
        -- turn around
        self.orientation = signed_speed_to_dir(self.move_intention.x)
      end
    end

  elseif self.ground_speed ~= 0 then
    -- no move intention, character is passive

    -- Original feature (not in SPG): No Friction on Steep Descending Slope
    --  Do not apply friction when character is descending a steep slope passively;
    --  In other words, apply it only on flat ground, low slope and only steep slopes if ascending
    -- Effect: the character will automatically run down a steep slope and accumulate acceleration downward
    --  without friction
    -- Resolves: the character was moving down a steep slope very slowly because of friction
    -- make sure to compare sin in abs value (steep_slope_min_angle is between 0 and 0.25 so we know its sin is negative)
    --  since slope angle is module 1 and cannot be directly compared (and you'd need to use (slope_angle + 0.5) % 1 - 0.5 to be sure)
    if abs(sin(self.slope_angle)) <= sin(-pc_data.steep_slope_min_angle) or sgn(self.ground_speed) ~= sgn(sin(self.slope_angle)) then
      self.ground_speed = sgn(self.ground_speed) * max(0, abs(self.ground_speed) - pc_data.ground_friction_frame2)
    end
  end

end

-- clamp ground speed to max
function player_char:clamp_ground_speed()
  if abs(self.ground_speed) > pc_data.max_ground_speed then
    self.ground_speed = sgn(self.ground_speed) * pc_data.max_ground_speed
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
  log("  _next_ground_step: "..joinstr(", ", quadrant_horizontal_dir, ref_motion_result), "trace2")

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
  if signed_distance_to_closest_ground <= 0 then
    -- position is inside ground, check if we can step up during this step
    -- (note that we kept the name max_ground_escape_height but in quadrant left and right,
    --  the escape is done on the X axis so technically we escape row width)
    -- refactor: code is similar to _check_escape_from_ground and above all _next_air_step
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
  elseif signed_distance_to_closest_ground > 0 then
    -- position is above ground, check if we can step down during this step
    -- (step down is during ground motion only)
    if signed_distance_to_closest_ground <= pc_data.max_ground_snap_height then
      -- step down
      next_position_candidate:add_inplace(vector_to_closest_ground)
      -- if character left the ground during a previous step, cancel that (step down land, very rare)
      ref_motion_result.is_falling = false
    else
      -- step fall: step down is too low, character will fall
      -- in some rare instances, character may find ground again farther, so don't stop the outside loop yet
      -- caution: we are not updating qy at all, which means the character starts
      --  "walking horizontally in the air". in sonic games, we would expect
      --  momentum to take over and send the character along qy, preserving
      --  velocity qvy from last frame
      -- so when adding momentum, consider reusing the last delta qy (e.g. vector_to_closest_ground.y)
      --  and applying it this frame
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

  -- check ceiling from both ground sensors. if any finds one, return true
  for i in all({horizontal_dirs.left, horizontal_dirs.right}) do

    -- check if ground sensor #i has ceiling closer than a character's height
    local sensor_position = self:get_ground_sensor_position_from(center_position, i)
    if self:is_column_blocked_by_ceiling_at(sensor_position) then
      return true
    end

  end

  return false
end


-- actual body of _is_column_blocked_by_ceiling_at passed to iterate_over_collision_tiles
--  as collider_distance_callback
-- return nil if no clear result and we must continue to iterate (until the last tile)
-- slope_angle is not used, so we aggressively remove it to gain 1 token
-- note that curr_tile_loc is unused in this implementation
local function ceiling_check_collider_distance_callback(curr_tile_loc, signed_distance_to_closest_ceiling) --, slope_angle)
  if signed_distance_to_closest_ceiling < 0 then
    -- head (or body) inside ceiling
    return true
  else
    -- head far touching ceiling or has some gap from ceiling
    return false
  end
end

-- actual body of _compute_signed_distance_to_closest_ceiling passed to iterate_over_collision_tiles
--  as no_collider_callback
local function ceiling_check_no_collider_callback()
  -- end of iteration, and no ceiling found
  return false
end

-- return true iff there is a ceiling above in the column of sensor_position, in a tile above
--  sensor_position's tile, within a height lower than a character's height
-- note that we return true even if the detected obstacle is lower than one step up's height,
--  because we assume that if the character could step this up, it would have and the passed
--  sensor_position would be the resulting position, so only higher tiles will be considered
--  so the step up itself will be ignored (e.g. when moving from a flat ground to an ascending slope)
function player_char:is_column_blocked_by_ceiling_at(sensor_position)
  assert(world.get_quadrant_x_coord(sensor_position, self.quadrant) % 1 == 0, "player_char:is_column_blocked_by_ceiling_at: sensor_position qx must be floored")

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
  --  because it allows us to effectively check the q-higher pixels not already checked in _compute_closest_ground_query_info)

  -- finally, we check actual collision at head top position, so we pass an offset of self:get_full_height() (argument 5)
  --  from here, we need:
  --  - (max_ground_escape_height + 1 - full_height) offset for first tile according to explanation above + the fact that we consider this offset from sensor_position base + offset (full_height)
  --  - no offset for last tile since we end checking at head top exactly, so argument 3 is 0
  local full_height = self:get_full_height()
  return iterate_over_collision_tiles(self, oppose_dir(self.quadrant), pc_data.max_ground_escape_height + 1 - full_height, 0, sensor_position, full_height, ceiling_check_collider_distance_callback, ceiling_check_no_collider_callback, --[[ignore_reverse_on_start_tile:]] true)
end

-- if character intends to jump, prepare jump for next frame
-- this extra frame allows us to detect if the player wants a variable jump or a hop
--  depending whether input is hold or not
function player_char:check_jump_intention()
  if self.jump_intention then
    -- consume intention so puppet control mode (which is sticky) also works
    self.jump_intention = false
    self.should_jump = true
  end
end

-- if character intends to jump, apply jump velocity from current ground
--  and enter the air_spin state
-- return true iff jump was applied
function player_char:check_jump()
  if self.should_jump then
    self.should_jump = false

    -- apply initial jump speed for variable jump
    -- note: if the player is doing a hop, the vertical speed will be reset
    --  to the interrupt speed during the same frame in _update_platformer_motion_airborne
    --  via _check_hold_jump (we don't do it here so we centralize the check and
    --  don't apply gravity during such a frame)
    -- to support slopes, we use the ground normal (rotate right tangent ccw)
    -- we don't have double jumps yet so we assume we are grounded here and
    --  self.slope_angle is not nil
    local jump_impulse = pc_data.initial_var_jump_speed_frame * vector.unit_from_angle(self.slope_angle):rotated_90_ccw()
    self.velocity:add_inplace(jump_impulse)
    self:enter_motion_state(motion_states.air_spin)
    self.has_jumped_this_frame = true

    sfx(audio.sfx_ids.jump)

    return true
  end
  return false
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
    self.velocity.x = self.velocity.x + self.move_intention.x * pc_data.air_accel_x_frame2

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
  -- see _update_platformer_motion_grounded
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
    -- register new ground tile, update slope angle and enter grounded state
    self:set_ground_tile_location(air_motion_result.tile_location)
    self:set_slope_angle_with_quadrant(air_motion_result.slope_angle)
    self:enter_motion_state(motion_states.grounded)
  end

  log("self.position: "..self.position, "trace")
  log("self.velocity: "..self.velocity, "trace")
end

-- check if character wants to interrupt jump by not holding anymore,
--  and set vertical speed to interrupt speed if so
function player_char:check_hold_jump()
  if not self.has_interrupted_jump and not self.hold_jump_intention then
    -- character has not interrupted jump yet and wants to
    -- flag jump as interrupted even if it's too late, so we don't enter this block anymore
    self.has_interrupted_jump = true

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
  --  (i.e. if landing in the middle of the Y move, finish the remaining part of motion as grounded,
  --  following the ground as usual).
  self:advance_in_air_along(motion_result, self.velocity, "x")
  log("=> "..motion_result, "trace2")
  self:advance_in_air_along(motion_result, self.velocity, "y")
  log("=> "..motion_result, "trace2")

  return motion_result
end

-- TODO: factorize with _compute_ground_motion_result
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
  log("  _next_air_step: "..joinstr(", ", direction, ref_motion_result), "trace2")

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
      -- check if we are touching or entering ground
      if signed_distance_to_closest_ground < 0 then
        -- Just like during ground step, check the step height: if too high, we hit a wall and stay airborne
        --  else, we land
        -- This step up check is really important, even for low slopes:
        --  if not done, when Sonic lands on an ascending slope, it will consider the few pixels up
        --  to be a wall!
        -- I used to check direction == directions.down only, and indeed if you step 1px down,
        --  the penetration distance will be no more than 1 and you will always snap to ground.
        -- But this didn't work when direction left/right hit the slope.
        -- refactor: code is similar to _check_escape_from_ground and above all _next_ground_step
        if - signed_distance_to_closest_ground <= pc_data.max_ground_escape_height then
          next_position_candidate.y = next_position_candidate.y + signed_distance_to_closest_ground
          -- landing: the character has just set foot on ground, flag it and initialize slope angle
          -- note that we only consider the character to touch ground when it is about to enter it
          -- below deprecated if we <= 0 check
          -- therefore, if he exactly reaches signed_distance_to_closest_ground == 0 this frame,
          --  it is still technically considered in the air
          -- if this step is blocked by landing, there is no extra motion,
          --  but character will enter grounded state
          ref_motion_result.is_landing, ref_motion_result.slope_angle = true, query_info.slope_angle
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
  -- if we have already found a blocker above (only possible for left and right),
  --  then there is no need to check further, though
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
  --  add an extra check on ground step if no pixel is found (and extactly at a tile bottom)
  --  to see if there is not a collision pixel 1px above (should be on another tile above)
  --  and from here compute the actual ground distance... of course, always add supporting ground
  --  tile under a ground tile when possible
  if not ref_motion_result.is_blocked_by_wall and
      (self.velocity.y < 0 or abs(self.velocity.x) > abs(self.velocity.y)) then
    local is_blocked_by_ceiling_at_next = self:is_blocked_by_ceiling_at(next_position_candidate)
    if is_blocked_by_ceiling_at_next then
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

-- item checks
function player_char:check_spring()
  if self.ground_tile_location then
    -- follow new convention of putting flags on the visual sprite
    -- of course since we know visual.spring_left_id we could check if tile id is
    --  spring_left_id or spring_left_id + 1 directly, but flag is more convenient for 1st check
    local ground_visual_tile_id = mget(self.ground_tile_location.i, self.ground_tile_location.j)
    if fget(ground_visual_tile_id, sprite_flags.spring) then
      log("character triggers spring", 'spring')
      -- to get spring left part location we still need to check exact tile id
      -- note that we only check for non-extended sprite, so make sure not to flag
      --  extended visual spring sprites as "springs" (in practice, in 1P it's impossible
      --  for player to hit spring twice in a row unless ceiling is very low, but safer)
      local spring_left_loc = self.ground_tile_location:copy()
      assert(visual.spring_left_id <= ground_visual_tile_id and ground_visual_tile_id <= visual.spring_left_id + 1, "player_char:check_spring: ground_visual_tile_id "..ground_visual_tile_id.." has flag spring but is not left nor right spring visual tile")
      if ground_visual_tile_id == visual.spring_left_id + 1 then
        -- we are on right part of spring, so representative tile is just on the left
        spring_left_loc.i = spring_left_loc.i - 1
      end
      self:trigger_spring(spring_left_loc)
    end
  end
end

function player_char:trigger_spring(spring_left_loc)
  self.velocity.y = -pc_data.spring_jump_speed_frame
  self:enter_motion_state(motion_states.falling)
  self.should_play_spring_jump = true

  local stage_state = flow.curr_state
  assert(stage_state.type == ':stage')
  stage_state:extend_spring(spring_left_loc)
end

function player_char:check_emerald()
  local stage_state = flow.curr_state
  assert(stage_state.type == ':stage')

  local em = stage_state:check_emerald_pick_area(self.position)
  if em then
    stage_state:character_pick_emerald(em)
  end
end

--#if cheat

-- update the velocity and position of the character following debug motion rules
function player_char:update_debug()
  self:update_velocity_debug()
  -- it's much more complicated to access app from here (e.g. via flow.curr_state)
  -- just to get delta_time, so we just use the constant as we know we are at 60 FPS
  -- otherwise we'd have to change utests to init app+flow each time
  self.position = self.position + self.debug_velocity
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
  if self.move_intention:get(coord) ~= 0 then
    -- some input => accelerate (direction may still change or be opposed)
    local clamped_move_intention_comp = mid(-1, self.move_intention:get(coord), 1)
    self.debug_velocity:set(coord, self.debug_velocity:get(coord) + self.debug_move_accel * clamped_move_intention_comp)
    self.debug_velocity:set(coord, mid(-self.debug_move_max_speed, self.debug_velocity:get(coord), self.debug_move_max_speed))
  else
    -- no input => decelerate
    if self.debug_velocity:get(coord) ~= 0 then
      self.debug_velocity:set(coord, sgn(self.debug_velocity:get(coord)) * max(abs(self.debug_velocity:get(coord)) - self.debug_move_decel, 0))
    end
  end
end

--#endif

-- update sprite animation state
function player_char:update_anim()
  self:check_play_anim()
  self:check_update_sprite_angle()
end

-- play appropriate sprite animation based on current state
function player_char:check_play_anim()
  if self.motion_state == motion_states.grounded then
    -- update ground animation based on speed
    if self.ground_speed == 0 then
      self.anim_spr:play("idle")
    else
      -- grounded and moving: play walk cycle at low speed, run cycle at high speed
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
      -- normal fall -> run in the air
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
  else -- self.motion_state == motion_states.air_spin
    if self.anim_run_speed < pc_data.spin_fast_min_speed_frame then
      self.anim_spr:play("spin_slow", false, max(pc_data.spin_anim_min_play_speed, self.anim_run_speed))
    else
      -- spin_fast_min_speed_frame > spin_anim_min_play_speed so no need to clamp here
      self.anim_spr:play("spin_fast", false, self.anim_run_speed)
    end
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

-- render the player character sprite at its current position
function player_char:render()
  local flip_x = self.orientation == horizontal_dirs.left
  -- snap render angle to a few set of values (45 degrees steps), classic style
  --  (unlike Freedom Planet and Sonic Mania)
  -- 45 degrees is 0.125 = 1/8, so by multiplying by 8, each integer represent a 45-degree step
  --  we just need to add 0.5 before flooring to effectively round to the closest step, then go back
  local sprite_angle = flr(8 * self.continuous_sprite_angle + 0.5) / 8
  -- floor position to avoid jittering when running on ceiling due to
  --  partial pixel position being sometimes one more pixel on the right due after 180-deg rotation
  local floored_position = vector(flr(self.position.x), flr(self.position.y))
  self.anim_spr:render(floored_position, flip_x, false, sprite_angle)
end

return player_char

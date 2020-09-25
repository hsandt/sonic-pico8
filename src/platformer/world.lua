local tile_collision_data = require("data/tile_collision_data")
local collision_data = require("data/collision_data")

local world = {}

-- return quadrant in which angle is contained (non-injective)
function world.angle_to_quadrant(angle)
  -- priority to vertical quadrants at the boundaries like Classic Sonic
  -- (so 45-deg slope is recognized as up/down)
  -- note that in those edge cases, the tiles should always be a rectangle to avoid confusion
  --  of which side the columns/rows are defined from
  -- nil angle (airborne) defaults to down so Sonic will try to "stand up" in the air
  if not angle or angle >= 0.875 or angle <= 0.125 then
    return directions.down
  elseif angle < 0.375 then
    return directions.right
  elseif angle <= 0.625 then
    return directions.up
  else  -- 0.625 < angle < 0.875
    return directions.left
  end
end

-- return quadrant tangent right angle
--  (not reciprocal of angle_to_quadrant since it is not injective)
-- down -> 0, right -> 0.25, up -> 0.5, left -> 0.75
function world.quadrant_to_right_angle(quadrant)
  -- a math trick to transform direction enum value to angle
  -- make sure not to change directions enum values order!
  return 0.25 * (3-quadrant) % 4
end

-- return the horizontal coordinate of a vector in given quadrant
--  (x if down/up, y if right/left)
-- make sure to always extract quadrant coordinates after doing operations
--  with quadrant-rotated vectors, to always have matching contribution signs
function world.get_quadrant_x_coord(pos, quadrant)
  -- directions value-dependent trick: left and right are 0 and 2 (even)
  --  whereas up and down are 1 and 3 (odd), so check for parity
  return quadrant % 2 == 0 and pos.y or pos.x
end

-- same, but for qy
function world.get_quadrant_y_coord(pos, quadrant)
  return quadrant % 2 == 1 and pos.y or pos.x
end

-- set the horizontal coordinate of a position vector in current quadrant
--  (x if down/up, y if right/left) to value
function world.set_position_quadrant_x(pos, value, quadrant)
  -- directions value-dependent trick: left and right are 0 and 2 (even)
  --  whereas up and down are 1 and 3 (odd), so check for parity
  if quadrant % 2 == 0 then
    pos.y = value
  else
    pos.x = value
  end
end

-- return the difference from qy1 to qy2,
--  but apply sign change to respect q-up,
--  i.e. if qy1 represents a value higher in quadrant frame than qy2,
--  result should be positive
function world.sub_qy(qy1, qy2, quadrant)
  -- directions value-dependent trick: up and left are 0 and 1 (< 2)
  --  and only those have a reversed qy
  -- quadrant down has the normal operation, as usual
  if quadrant < 2 then
    return qy2 - qy1
  else
    return qy1 - qy2
  end
end

-- return the qy of the q-bottom edge of a tile for a given quadrant
-- e.g. left edge x if quadrant is left, bottom edge y if quadrant is down
function world.get_tile_qbottom(tile_loc, quadrant)
  -- to avoid if/elseif and handle everything in one formula:
  -- - start from tile center
  -- - move in quadrant (down) direction by a half-tile
  -- - get qy
  -- tile_size / 2 = 4
  return world.get_quadrant_y_coord(tile_loc:to_center_position() + 4 * dir_vectors[quadrant], quadrant)
end

-- proxy for compute_qcolumn_height_at that converts tile location to region tile location
--  by taking region origin into account
function world.compute_qcolumn_height_at_region(region_topleft_uv, tile_location, qcolumn_index0, quadrant, ignore_reverse)
  -- with the extended map system, mget has a different meaning based on the current region
  -- a clean approach would probably to have a region-independent world instance,
  --  and a world_scroller that is region-aware and referenced by the stage_state
  -- but since the region offset is easy to get, in this case we'll just access stage state via flow
  --  as we do from PC and check the regions directly, although it adds a reverse dependency
  --  and complexity utests
  -- use same trick as in draw_onscreen_tiles to offset tiles by region topleft uv
  local region_tile_location = location(tile_location.i - region_topleft_uv.i, tile_location.j - region_topleft_uv.j)

  return world.compute_qcolumn_height_at(region_tile_location, qcolumn_index0, quadrant, ignore_reverse)
end

-- return (qcolumn_height, slope_angle) where:
--  - qcolumn_height is the qcolumn height at region_tile_location on qcolumn_index0, or 0 if there is no colliding tile
--    (if quadrant is horizontal, qcolum = row, but indices are always top to bottom, left to right)
--  - slope_angle is the slope angle of the corresponding tile, or nil if there is no colliding tile
-- if ignore_reverse is true, return 0, nil if the tile interior is opposed to quadrant interior direction
-- this is useful for ceiling check on character's current tile and actually matches Classic Sonic behavior better
function world.compute_qcolumn_height_at(region_tile_location, qcolumn_index0, quadrant, ignore_reverse)
  assert(0 <= qcolumn_index0 and qcolumn_index0 < 8, "world.compute_qcolumn_height_at: invalid qcolumn_index0 "..qcolumn_index0)

  -- only consider valid tiles; consider there are no colliding tiles outside the map area
  if region_tile_location.i >= 0 and region_tile_location.i < 128 and region_tile_location.j >= 0 and region_tile_location.j < 32 then

    -- check if that tile at region_tile_location has a collider (mget will return 0 if there is no tile,
    --  so we must make sure the the "empty" sprite 0 has no flags set)
    local current_tile_id = mget(region_tile_location.i, region_tile_location.j)
    local current_tile_collision_flag = fget(current_tile_id, sprite_flags.collision)
    if current_tile_collision_flag then

      -- get the tile collision mask
      local tcd = collision_data.get_tile_collision_data(current_tile_id)
      assert(tcd, "collision_data.tiles_collision_data does not contain entry for sprite id: "..current_tile_id..", yet it has the collision flag set")

      if tcd then
        -- if quadrant matches interior (h or v) direction, use q-column
        --  (character is walking on the "normal" side of the tile)
        -- if quadrant is opposed to interior (h or v) direction, use all-or-nothing
        --  (character is walking on the "reverse" side of the tile, which is flat
        --   on square edge (q-height = 8) except when q-column is completely empty)
        --  in addition, the slope_angle is always the quadrant right angle (0, 0.25, 0.5, 0.75)
        --   to simulate flat ground
        --  full tiles must have an arbitrary angle multiple of 0.25, typically 0, and will be associated
        --   to interiors based on angle_to_quadrant (one of the interiors will be arbitrarily chosen
        --   since an angle edge case), then the algo will cover the reverse side cases, so 8, 0.25x will always be returned
        -- ex: interior right-down, character quadrant left
        -- ........
        -- ........ <- sensor here finds nothing (angle still 0.75)
        -- ........
        -- ......## <- sensor here finds immediate ground as if row was ######## (and angle 0.75)
        -- .....###
        -- ....####
        -- ...#####
        -- ...#####

        -- walking on the flat part of a tile on the normal side does *not* set
        -- the slope to quadrant right angle
        -- ........
        -- #.......
        -- ###.....
        -- #####... <- A
        -- ######..
        -- ########
        -- ######## <- the inclined angle used at A will be considered
        -- ########

        -- however, if the tile is made *only* of full columns or full rows
        --  (this includes the full tile), quadrant right angle is always used
        --  (similarly to reverse sides, because we consider it's an edge case anyway)
        -- ........
        -- ........
        -- ........
        -- ........ <- (0, 0.75)
        -- ........
        -- ########
        -- ######## <- (8, 0.75) (flat side of rectangle)
        -- ########

        local is_full_vertical_rectangle = tcd:is_full_vertical_rectangle()
        local is_full_horizontal_rectangle = tcd:is_full_horizontal_rectangle()
        local is_full_rectangle = is_full_vertical_rectangle or is_full_horizontal_rectangle

        if quadrant % 2 == 1 then
          -- floor/ceiling (quadrant down/up)
          local height = tcd:get_height(qcolumn_index0)
          if tcd.interior_v == vertical_dirs.down and quadrant == directions.up or
              tcd.interior_v == vertical_dirs.up and quadrant == directions.down then
            -- reverse side, all-or-nothing with right angle
            --  unless we ignore reverse (still at sensor tile during ceiling check)
            --  and the tile is not covering fully spanned vertically,
            --  in which case reverse doesn't make sense as angle-to-quadrant conversion
            --  is arbitrary on square angles, so the tile interior_v could be up or down
            if ignore_reverse and not is_full_vertical_rectangle then
              return 0--, nil
            end
            -- return all-or-nothing, always with angle
            --  (not nil even if nothing, let ground motion set slope angle appropriately when falling)
            return height > 0 and tile_size or 0, world.quadrant_to_right_angle(quadrant)
          elseif is_full_rectangle then
            -- flat side of rectangle (or empty region near flat side)
            return height, world.quadrant_to_right_angle(quadrant)
          end
          -- normal side
          return height, tcd.slope_angle
        else
          -- right wall/left wall (quadrant right/left)
          local width = tcd:get_width(qcolumn_index0)
          if tcd.interior_h == horizontal_dirs.right and quadrant == directions.left or
              tcd.interior_h == horizontal_dirs.left and quadrant == directions.right then
            if ignore_reverse and not is_full_horizontal_rectangle then
              return 0--, nil
            end
            return width > 0 and tile_size or 0, world.quadrant_to_right_angle(quadrant)
          elseif is_full_rectangle then
            -- flat side of rectangle (or empty region near flat side)
            return width, world.quadrant_to_right_angle(quadrant)
          end
          -- normal side
          return width, tcd.slope_angle
        end
      end

    end

  end

  return 0--, nil

end

return world

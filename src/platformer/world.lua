local tile_collision_data = require("data/tile_collision_data")
local collision_data = require("data/collision_data")

local world = {}

-- return (qcolumn_height, slope_angle) where:
--  - qcolumn_height is the qcolumn height at tile_location on qcolumn_index0, or 0 if there is no colliding tile
--    (if quadrant is horizontal, qcolum = row, but indices are always top to bottom, left to right)
--  - slope_angle is the slope angle of the corresponding tile, or nil if there is no colliding tile
function world._compute_qcolumn_height_at(tile_location, qcolumn_index0, quadrant)

  -- only consider valid tiles; consider there are no colliding tiles outside the map area
  if tile_location.i >= 0 and tile_location.i < 128 and tile_location.j >= 0 and tile_location.j < 64 then

    -- check if that tile at tile_location has a collider (mget will return 0 if there is no tile,
    --  so we must make the "empty" sprite 0 has no flags set)
    local current_tile_id = mget(tile_location.i, tile_location.j)
    local current_tile_collision_flag = fget(current_tile_id, sprite_flags.collision)
    if current_tile_collision_flag then

      -- get the tile collision mask
      local tcd = collision_data.get_tile_collision_data(current_tile_id)
      assert(tcd, "collision_data.tiles_collision_data does not contain entry for sprite id: "..current_tile_id..", yet it has the collision flag set")

      if tcd then
        -- up (1) and down (3) are odd
        if quadrant % 2 == 1 then
          return tcd:get_height(qcolumn_index0), tcd.slope_angle
        else
          return tcd:get_width(qcolumn_index0), tcd.slope_angle
        end
      end

    end

  end

  return 0--, nil

end

-- DEPRECATED, remove to spare tokens
-- return (true, slope_angle) if there is a collision pixel at (x, y),
--  where slope_angle is the slope angle in this tile (even if (x, y) is inside ground),
--  and (false, nil) if there is no collision
function world.get_pixel_collision_info(x, y)
  assert(flr(x) == x, "world.get_pixel_collision_info: x must be floored")

  -- queried position
  local location = vector(x, y):to_location()
  local location_topleft = location:to_topleft_position()
  local left, top = location_topleft.x, location_topleft.y
  local bottom = top + tile_size

  -- environment
  local column_index0 = x - left  -- from 0 to tile_size - 1
  local ground_array_height, slope_angle = world._compute_qcolumn_height_at(location, column_index0, directions.down)

  -- if column is empty, there cannot be any pixel collision
  if ground_array_height > 0 then
    local column_top = bottom - ground_array_height

    -- there is a collision pixel at (x, y) if the column at x rises at least until y
    if y >= column_top then
      return true, slope_angle
    end
  end

  return false, nil
end

return world

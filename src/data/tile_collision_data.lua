local tile = {}

-- struct that contains directly usable data on tile collision
-- semantically, it is almost equivalent to raw_tile_collision_data
--  (technically it loses the mask sprite id location) and redundant,
--  but by precomputing more detailed data using PICO-8 spritesheet / busted mocks,
--  tile_collision_data makes it possible to check for collision with ground very easily
local tile_collision_data = new_struct()

-- height_array  [int]    sequence of column heights of a tile collision mask per column index,
--                          counting index from the left
--                         if tile vertical interior is down, a column rises from the bottom (floor)
--                         if tile vertical interior is up, a column falls from the top (ceiling)
-- width_array   [int]    sequence of row widths of a tile collision mask per row index,
--                          counting index from the top
--                         if tile horizontal interior is left, a row is filled from the left (left wall or desc slope)
--                         if tile horizontal interior is up, a row is filled from the right (right wall or asc slope)
--                        note: knowing height_array and knowing width_array is equivalent (reciprocity)
--                         we simply store both for faster access
-- slope_angle   float    slope angle in turn ratio (0.0 to 1.0 excluded, positive clockwise)
--                         it also determines the interior:
--                         0    to 0.25: horizontal interior right, vertical interior down (flat or asc slope)
--                         0.25 to 0.5:  horizontal interior right, vertical interior up   (ceiling right corner or flat)
--                         0.5  to 0.75: horizontal interior left,  vertical interior up   (ceiling flat or left corner)
--                         0.75 to 1:    horizontal interior left,  vertical interior down (desc slope or flat)
-- interior_v    vertical_dirs     vertical direction of the tile's interior
--                                 (up for ceiling, down for floor)
-- interior_h    horizontal_dirs   horizontal direction of the tile's interior
--                                 (left for desc slope or left ceiling, asc slope or right ceiling)
function tile_collision_data:_init(height_array, width_array, slope_angle, interior_v, interior_h)
  self.height_array = height_array
  self.width_array = width_array
  self.slope_angle = slope_angle
  self.interior_v = interior_v
  self.interior_h = interior_h
end

-- return the height for a column index starting at 0, from left to right
function tile_collision_data:get_height(column_index0)
  return self.height_array[column_index0 + 1]  -- adapt 0-index to 1-index
end

-- return the width for a row index starting at 0, from top to bottom
function tile_collision_data:get_width(row_index0)
  return self.width_array[row_index0 + 1]  -- adapt 0-index to 1-index
end

-- helper function: return true iff array only contains 0 or 8
local function is_full_or_empty(array)
  -- check if all values in array are 8 / any value is not 8
  --  (there are no any/all helper functions yet, only contains with is any + ==)

  -- check columns first
  for v in all(array) do
    if v ~= 0 and v ~= 8 then
      return false
    end
  end

  return true
end

-- return true iff tile is made of empty/full columns only
--  (height array only contains 0 or 8)
--  in practice, those columns should be contiguous (else the row widths cannot be defined)
--  and the tile is a rectangle of height 8
function tile_collision_data:is_full_vertical_rectangle()
  return is_full_or_empty(self.height_array)
end

-- return true iff tile is made of empty/full columns only
--  (height array only contains 0 or 8)
--  in practice, those columns should be contiguous (else the row widths cannot be defined)
--  and the tile is a rectangle of height 8
function tile_collision_data:is_full_horizontal_rectangle()
  return is_full_or_empty(self.width_array)
end

-- return tuple (interior_v, interior_h) for a slope angle
function tile_collision_data.slope_angle_to_interiors(slope_angle)
  local interior_v = (slope_angle < 0.25 or slope_angle > 0.75) and vertical_dirs.down or vertical_dirs.up
  local interior_h = slope_angle < 0.5 and horizontal_dirs.right or horizontal_dirs.left
  return interior_v, interior_h
end

function tile_collision_data.from_raw_tile_collision_data(raw_data)
  assert(raw_data.slope_angle >= 0 and raw_data.slope_angle < 1, "tile_collision_data.from_raw_tile_collision_data: raw_data.slope_angle is "..raw_data.slope_angle..", apply `% 1` before passing")
  -- we don't mind edge cases (slope angle at 0, 0.25, 0.5 or 0.75 exactly)
  --  and assume the code will handle any arbitrary decision on interior_h/v
  local interior_v, interior_h = tile_collision_data.slope_angle_to_interiors(raw_data.slope_angle)

  return tile_collision_data(
    tile_collision_data.read_height_array(raw_data.mask_tile_id_loc, interior_v),
    tile_collision_data.read_width_array(raw_data.mask_tile_id_loc, interior_h),
    raw_data.slope_angle,
    interior_v,
    interior_h
  )
end

-- return a stateful range iterator
-- this function is generic enough to be in picoboots helper
--  but right now it's only used in this script so it is local
-- normally we should make it accessible from other modules
--  and test it, but it's likely to be correct since it was copied from
-- http://lua-users.org/wiki/RangeIterator and this module's tests are passing
local function range(from, to, step)
  step = step or 1
  return function(_, lastvalue)
    local nextvalue = lastvalue + step
    if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
       step == 0
    then
      return nextvalue
    end
  end, nil, from - step  -- from - step: trick to start at from on the first step
end

-- check for collision pixel at tile_mask_x + dx, tile_mask_y + dy,
--  and if one is found, return the length of the mask strip segment (height or width that constitutes
--  a collision array0) in the direction we were iterating on in calling context, thanks to segment_length_evaluator
--  (it is needed because height is read on y, width on x, and depending on the interior's
--  direction, we iterated from a different side and measure the length differently)
-- if no collision pixel at this position, return nil
function tile_collision_data.check_collision_pixel(tile_mask_x, tile_mask_y, dx, dy, interior_v, interior_h, segment_length_evaluator)
  local tile_mask_color = sget(tile_mask_x + dx, tile_mask_y + dy)
  -- we use black (0) as transparent mask color
  if tile_mask_color ~= 0 then
    -- segment_length_evaluator will either use dx & interior_v or dy & interior_h,
    --  but we don't know from here so pass both
    return segment_length_evaluator(dx, dy, interior_v, interior_h)
  end
end

-- return height to fill collision height array when finding first collision pixel at dy,
--  vertical interior on interior_v side
function tile_collision_data.evaluate_collision_height(dx, dy, interior_v, interior_h)
  if interior_v == vertical_dirs.down then
    -- we were iterating from the sky to the floor
    --  so the height is complementary to our iteration distance
    -- if we hit a collision pixel on first iteration (dy == 0),
    --  then the column is full (return tile_size), so no offset
    return tile_size - dy
  else
    -- we were iterating from the bottom to the ceiling, but backward,
    --  so our iteration index tells us how far from the top we are
    -- if we hit a collision pixel on first iteration (dy == tile_size - 1)
    --  then the column is full (return tile_size), so need offset +1
    return dy + 1
  end
end

-- return height to fill collision width array when finding first collision pixel at dx,
--  horizontal interior on interior_h side
function tile_collision_data.evaluate_collision_width(dx, dy, interior_v, interior_h)
  -- see comments in evaluate_collision_height and transpose everything
  if interior_h == horizontal_dirs.right then
    return tile_size - dx
  else
    return dx + 1
  end
end

-- Read tile mask collision height array located at tile_mask_id_location: sprite_id_location
-- We assume that the tile mask is only compounded or white (more exactly non-black)
--  vertical segments aka "columns" touching the top (if interior is up) or bottom (if interior is down)
--  of the tile.
function tile_collision_data.read_height_array(tile_mask_id_location, interior_v)
  local array = {}

  local tile_mask_topleft_position = tile_mask_id_location:to_topleft_position()

  -- range returns a tuple so we need to pack and unpack later
  local y_range = interior_v == vertical_dirs.down and {range(0, tile_size - 1)} or {range(tile_size - 1, 0, -1)}

  -- iterate over columns from left to right (order doesn't matter as long as we fill the height array in the same order)
  for dx = 0, tile_size - 1 do
    -- iterate from the opposite side of the vertical interior (e.g. bottom if interior is ceiling)
    --  so we can find the collision pixel the farthest from the interior, which really represents the column height
    for dy in unpack(y_range) do
      -- no need to pass interior_h (but we need dx to check pixel at this position)
      column_height = tile_collision_data.check_collision_pixel(tile_mask_topleft_position.x, tile_mask_topleft_position.y, dx, dy, interior_v, nil, tile_collision_data.evaluate_collision_height)
      if column_height then
        -- collision pixel found at column_height
        -- break so we can immediately store the column_height in the array
        break
      end
    end
    if not column_height then
      -- no pixel found at all, so column width is 0
      column_height = 0
    end
    add(array, column_height)
  end
  return array
end

-- see read_height_array and transpose everything for comments:
-- height -> width
-- x <-> y
-- interior_v -> interior_h
-- up -> left and down -> right
function tile_collision_data.read_width_array(tile_mask_id_location, interior_h)
  local array = {}
  local tile_mask_topleft_position = tile_mask_id_location:to_topleft_position()
  local x_range = interior_h == horizontal_dirs.right and {range(0, tile_size - 1)} or {range(tile_size - 1, 0, -1)}

  for dy = 0, tile_size - 1 do
    for dx in unpack(x_range) do
      row_width = tile_collision_data.check_collision_pixel(tile_mask_topleft_position.x, tile_mask_topleft_position.y, dx, dy, nil, interior_h, tile_collision_data.evaluate_collision_width)
      if row_width then
        break
      end
    end
    if not row_width then
      row_width = 0
    end
    add(array, row_width)
  end
  return array
end

return tile_collision_data

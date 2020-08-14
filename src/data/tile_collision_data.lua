local tile = {}

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
function tile_collision_data:_init(height_array, width_array, slope_angle)
  self.height_array = height_array
  self.width_array = width_array
  self.slope_angle = slope_angle
end

-- return the height for a column index starting at 0, from left to right
function tile_collision_data:get_height(column_index0)
  return self.height_array[column_index0 + 1]  -- adapt 0-index to 1-index
end

-- return the width for a row index starting at 0, from top to bottom
function tile_collision_data:get_width(row_index0)
  return self.width_array[row_index0 + 1]  -- adapt 0-index to 1-index
end

function tile_collision_data.from_raw_tile_collision_data(raw_data)
  return tile_collision_data(
    tile_collision_data.read_height_array(raw_data.id_loc, slope_angle),
    tile_collision_data.read_width_array(raw_data.id_loc, slope_angle),
    raw_data.slope_angle
  )
end

-- Read tile mask located at tile_mask_id_location: sprite_id_location
-- We assume that the tile mask is only compounded or white (more exactly non-black)
--  vertical segments aka "columns" touching the top (if interior is up) or bottom (if interior is down)
--  of the tile.
function tile_collision_data.read_height_array(tile_mask_id_location, slope_angle)
  local array = {}
  -- todo: support ceiling
  local tile_mask_topleft_position = tile_mask_id_location:to_topleft_position()
  -- iterate over columns from left to right, searching for the highest filled pixel
  for dx = 0, tile_size - 1 do
    -- iterate from the top of the column and stop at the first filled pixel (we assume
    -- lower pixels are also filled for readability of the tile mask, but not enforced)
    local mask_height = 0
    for dy = 0, tile_size - 1 do
      local tile_mask_color = sget(tile_mask_topleft_position.x + dx, tile_mask_topleft_position.y + dy)
      -- we use black (0) as transparent mask color
      if tile_mask_color ~= 0 then
        mask_height = tile_size - dy
        break
      end
    end
    add(array, mask_height)
  end
  return array
end

function tile_collision_data.read_width_array(tile_mask_id_location, slope_angle)
  -- todo: probably make a unique function read_array and pass some parameter x/y
  -- to distinguish height and width parsing
  return {}
end

return tile_collision_data

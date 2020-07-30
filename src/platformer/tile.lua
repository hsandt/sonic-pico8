local tile = {}

local tile_data = new_struct()
tile.tile_data = tile_data

-- id_loc         sprite_id_location    sprite location on the spritesheet
-- slope_angle    float                 slope angle in turn ratio (0.0 to 1.0, positive clockwise)
function tile_data:_init(id_loc, slope_angle)
  self.id_loc = id_loc
  self.slope_angle = slope_angle
end

--#if log
function tile_data:_tostring()
  return "tile_data("..joinstr(", ", self.id_loc:_tostring(), self.slope_angle)..")"
end
--#endif


local height_array = new_struct()
tile.height_array = height_array

-- tile_data_value    tile_data              tile data to generate the height array from
-- _array             [int]                  sequence of heights of a tile collision mask column per index,
--                                            counting index from the left, height from the bottom
--                                            it is filled based on tile_mask_id_location
-- slope_angle        float                  slope angle in turn ratio (0.0 to 1.0)
function height_array:_init(tile_data_value)
  self._array = {}
  self._fill_array(self._array, tile_data_value.id_loc)
  self.slope_angle = tile_data_value.slope_angle
end

--#if log
function height_array:_tostring()
  return "height_array("..joinstr(", ", "{"..joinstr_table(", ", self._array).."}", self.slope_angle)..")"
end
--#endif

-- return the height for a column index starting at 0, from left to right
function height_array:get_height(column_index0)
  return self._array[column_index0 + 1]  -- adapt 0-index to 1-index
end


-- fill the passed array with height data based on the sprite mask
--  located at tile_mask_id_location: sprite_id_location
-- pass an empty array so it is only filled with the computed values
-- the tile mask must represent the collision mask of a tile, with columns
--  of non-transparent (black) pixels filled from the bottom,
--  or at least the upper edge of said mask (we don't check what is below
--  the edge once we found the first non-transparent pixel from top to bottom)
function height_array._fill_array(array, tile_mask_id_location)
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
end

return tile

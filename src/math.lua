require("class")

-- tile_vector class: a pair of integer coords (i, j) that represents a position
-- on either a spritesheet or a tilemap of 8x8 squares (8 is the "tile size")
-- for sprite locations and tilemap locations, use sprite_id_location and location resp.
-- for sprite span (sprite size on the spritesheet), use tile_vector directly
tile_vector = new_class()

-- i       int     horizontal coordinate in tile size
-- j       int     vertical   coordinate in tile size
function tile_vector:_init(i, j)
  self.i = i
  self.j = j
end

function tile_vector:_tostring()
  return "tile_vector("..self.i..", "..self.j..")"
end

function tile_vector.__eq(lhs, rhs)
  return lhs.i == rhs.i and lhs.j == rhs.j
end


-- sprite location is a special tile_vector with the semantics of a spritesheet location
-- and associated conversion methods
sprite_id_location = derived_class(tile_vector)

-- return the sprite id  corresponding to a sprite location on a spritesheet
function sprite_id_location:to_sprite_id()
  return 16 * j + i
end

function sprite_id_location.__eq(lhs, rhs)
  return tile_vector.__eq(lhs, rhs)
end

-- location is a special tile_vector with the semantics of a tilemap location
-- and associated conversion methods
location = derived_class(tile_vector)

-- return the position corresponding to a location
function location:to_position()
  return vector(8 * self.i, 8 * self.j)
end

function location.__eq(lhs, rhs)
  return tile_vector.__eq(lhs, rhs)
end

-- vector class: a pair of pixel coordinates (x, y) that represents a 2d vector
-- in the space (position, displacement, speed, acceleration...)
vector = new_class()

-- x       int     horizontal coordinate in pixels
-- y       int     vertical   coordinate in pixels
function vector:_init(x, y)
  self.x = x
  self.y = y
end

function vector.__eq(lhs, rhs)
    return lhs.x == rhs.x and lhs.y == rhs.y
end

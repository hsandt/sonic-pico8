require("engine/core/class")

-- numeric helpers

function almost_eq(lhs, rhs, eps)
  eps = eps or 0.01
  assert(lhs, "lhs is nil")
  assert(rhs, "rhs")
  if type(lhs) == "number" and type(rhs) == "number" then
    return abs(lhs - rhs) <= eps
  elseif lhs.almost_eq then
    return lhs:almost_eq(rhs, eps)
  else
    assert(false, "almost_eq cannot compare "..lhs.." and "..rhs)
  end
end

-- geometry/data grid helpers

-- tile_vector struct: a pair of integer coords (i, j) that represents a position
-- on either a spritesheet or a tilemap of 8x8 squares (8 is the "tile size")
-- for sprite locations and tilemap locations, use sprite_id_location and location resp.
-- for sprite span (sprite size on the spritesheet), use tile_vector directly
tile_vector = new_struct()

-- i       int     horizontal coordinate in tile size
-- j       int     vertical   coordinate in tile size
function tile_vector:_init(i, j)
  self.i = i
  self.j = j
end

--#if log
function tile_vector:_tostring()
  return "tile_vector("..self.i..", "..self.j..")"
end
--#endif

-- return the topleft position corresponding to a tile location
function tile_vector:to_topleft_position()
  return vector(8 * self.i, 8 * self.j)
end

-- sprite location is a special tile_vector with the semantics of a spritesheet location
-- and associated conversion methods
sprite_id_location = derived_struct(tile_vector)

--#if log
function sprite_id_location:_tostring()
  return "sprite_id_location("..self.i..", "..self.j..")"
end
--#endif

-- return the sprite id  corresponding to a sprite location on a spritesheet
function sprite_id_location:to_sprite_id()
  return 16 * self.j + self.i
end


-- location is a special tile_vector with the semantics of a tilemap location
-- and associated conversion methods
location = derived_struct(tile_vector)

--#if log
function location:_tostring()
  return "location("..self.i..", "..self.j..")"
end
--#endif

-- return the center position corresponding to a tile location
function location:to_center_position()
  return vector(8 * self.i + 4, 8 * self.j + 4)
end


-- vector struct: a pair of pixel coordinates (x, y) that represents a 2d vector
-- in the space (position, displacement, speed, acceleration...)
vector = new_struct()

-- x       int     horizontal coordinate in pixels
-- y       int     vertical   coordinate in pixels
function vector:_init(x, y)
  self.x = x
  self.y = y
end

--#if log
function vector:_tostring()
  return "vector("..self.x..", "..self.y..")"
end
--#endif

-- almost_eq can be used as static function of method, since self would simply replace lhs
function vector.almost_eq(lhs, rhs, eps)
  assert(getmetatable(lhs) == vector and getmetatable(rhs) == vector, "vector.almost_eq: lhs and rhs are not both vectors (lhs: "..dump(lhs)..", rhs: "..dump(rhs)..")")
  return almost_eq(lhs.x, rhs.x, eps) and almost_eq(lhs.y, rhs.y, eps)
end

function vector.__add(lhs, rhs)
  assert(getmetatable(lhs) == vector and getmetatable(rhs) == vector, "vector.__add: lhs and rhs are not both vectors (lhs: "..dump(lhs)..", rhs: "..dump(rhs)..")")
  return vector(lhs.x + rhs.x, lhs.y + rhs.y)
end

-- in-place operation as native lua replacements for pico-8 +=
function vector:add_inplace(other)
  self.x = self.x + other.x
  self.y = self.y + other.y
end

function vector.__sub(lhs, rhs)
  assert(getmetatable(lhs) == vector and getmetatable(rhs) == vector, "vector.__sub: lhs and rhs are not both vectors (lhs: "..dump(lhs)..", rhs: "..dump(rhs)..")")
  return vector(lhs.x - rhs.x, lhs.y - rhs.y)
end

-- in-place operation as native lua replacements for pico-8 -=
function vector:sub_inplace(other)
  self.x = self.x - other.x
  self.y = self.y - other.y
end

function vector.__unm(v)
  return vector(-v.x, -v.y)
end

function vector.__mul(lhs, rhs)
  if type(lhs) == "number" then
    return vector(lhs * rhs.x, lhs * rhs.y)
  elseif type(rhs) == "number" then
    return vector(rhs * lhs.x, rhs * lhs.y)
  else
--#if assert
    assert(false, "vector multiplication is only supported with a scalar, "..
      "tried to multiply "..lhs:_tostring().." and "..rhs:_tostring())
--#endif
  end
end

-- in-place operation as native lua replacements for pico-8 *=
function vector:mul_inplace(number)
  local product = self * number
  self.x = product.x
  self.y = product.y
end

function vector.__div(lhs, rhs)
  if type(rhs) == "number" then
    assert(rhs ~= 0, "cannot divide vector "..lhs:_tostring().." by zero")
    return vector(lhs.x / rhs, lhs.y / rhs)
  else
--#if assert
    assert(false, "vector division is only supported with a scalar as rhs, "..
      "tried to multiply "..stringify(lhs).." and "..rhs)
--#endif
  end
end

-- in-place operation as native lua replacements for pico-8 /=
function vector:div_inplace(number)
  local product = self / number
  self.x = product.x
  self.y = product.y
end

function vector.zero()
  return vector(0, 0)
end

function vector:is_zero()
  return self.x == 0 and self.y == 0
end

function vector:sqr_magnitude()
  return self.x ^ 2 + self.y ^ 2
end

function vector:magnitude()
  return sqrt(self:sqr_magnitude())
end

-- return a normalized vector is non-zero, else a zero vector
function vector:normalized()
  local magnitude = self:magnitude()
  if magnitude > 0 then
    return self / magnitude
  else
    return vector.zero()
  end
end

-- normalize vector in-place
function vector:normalize()
  local magnitude = self:magnitude()
  if magnitude > 0 then
    self.x = self.x / magnitude
    self.y = self.y / magnitude
  end
end

-- return copy of vector with magnitude clamped by max_magnitude
function vector:with_clamped_magnitude(max_magnitude)
  assert(max_magnitude >= 0)
  local magnitude = self:magnitude()
  if magnitude > max_magnitude then
      return max_magnitude * self / magnitude
  end
  return self
end

-- clamp magnitude in-place
function vector:clamp_magnitude(max_magnitude)
  assert(max_magnitude >= 0)
  local magnitude = self:magnitude()
  if magnitude > max_magnitude then
    self.x = self.x * max_magnitude / magnitude
    self.y = self.y * max_magnitude / magnitude
  end
end

-- return copy of vector with magnitude clamped by max_magnitude in cardinal directions
function vector:with_clamped_magnitude_cardinal(max_magnitude_x, max_magnitude_y)
  -- if 1 arg is passed, use the same max for x and y
  max_magnitude_y = max_magnitude_y or max_magnitude_x
  assert(max_magnitude_x >= 0 and max_magnitude_y >= 0)
  return vector(mid(-max_magnitude_x, self.x, max_magnitude_x), mid(-max_magnitude_y, self.y, max_magnitude_y))
end

-- clamp magnitude in cardinal directions in-place
function vector:clamp_magnitude_cardinal(max_magnitude_x, max_magnitude_y)
  -- if 1 arg is passed, use the same max for x and y
  max_magnitude_y = max_magnitude_y or max_magnitude_x
  assert(max_magnitude_x >= 0 and max_magnitude_y >= 0)
  self.x = mid(-max_magnitude_x, self.x, max_magnitude_x)
  self.y = mid(-max_magnitude_y, self.y, max_magnitude_y)
end

-- mirror the vector horizontally in-place
function vector:mirror_x()
  self.x = -self.x
end

-- mirror the vector vertically in-place
function vector:mirror_y()
  self.y = -self.y
end

-- return copy of vector rotated by 90 degrees clockwise (for top-left origin)
function vector:rotated_90_cw()
  return vector(-self.y, self.x)
end

-- rotate vector by 90 degrees clockwise in-place
function vector:rotate_90_cw_inplace()
  local old_x = self.x
  self.x = -self.y
  self.y = old_x
end

-- return copy of vector rotated by 90 degrees counter-clockwise (for top-left origin)
function vector:rotated_90_ccw()
  return vector(self.y, -self.x)
end

-- rotate by 90 degrees counter-clockwise in-place
function vector:rotate_90_ccw_inplace()
  local old_x = self.x
  self.x = self.y
  self.y = -old_x
end

-- return the tile location containing this vector position (non-injective)
function vector:to_location()
  return location(flr(self.x / tile_size), flr(self.y / tile_size))
end

-- enums data

--#ifn pico8
directions = {
  left = 0,
  up = 1,
  right = 2,
  down = 3
}
--#endif

dir_vectors = {
  [0] = vector(-1., 0.),
  vector(0., -1.),
  vector(1., 0.),
  vector(0., 1.)
}

-- we are not stripping this enum as we need dynamic string-to-value
--  conversion for itest dsl; we don't need it for normal build
--  though, so when 'or' is supported in preprocessing, it will
--  be better to surround this in --#if ~pico8 or itest
horizontal_dirs = {
  left = 1,
  right = 2
}

horizontal_dir_vectors = {
  vector(-1., 0.),  -- to left
  vector(1., 0.)    -- to right
}

horizontal_dir_signs = {
  -1,               -- left sign
  1                 -- right sign
}

-- return left if signed speed is negative, right if positive. ub unless signed speed is not 0
function signed_speed_to_dir(signed_speed)
  assert(signed_speed ~= 0)
  return signed_speed < 0 and horizontal_dirs.left or horizontal_dirs.right
end

function oppose_dir(direction)
  return (direction + 2) % 4
end

function mirror_dir_x(direction)
  if direction == directions.left then
    return directions.right
  elseif direction == directions.right then
    return directions.left
  else
    return direction
  end
end

function mirror_dir_y(direction)
  if direction == directions.up then
    return directions.down
  elseif direction == directions.down then
    return directions.up
  else
    return direction
  end
end

function rotate_dir_90_cw(direction)
  return (direction + 1) % 4
end

function rotate_dir_90_ccw(direction)
  return (direction - 1) % 4
end

require("engine/core/class")

-- numeric helpers
function almost_eq(lhs, rhs, eps)
  eps = eps or 0.01
  if type(lhs) == "number" and type(rhs) == "number" then
    return abs(lhs - rhs) <= eps
  elseif lhs.almost_eq then
    return lhs:almost_eq(rhs, eps)
  else
    assert(false, "almost_eq cannot compare "..lhs.." and "..rhs)
  end
end



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

function sprite_id_location:_tostring()
  return "sprite_id_location("..self.i..", "..self.j..")"
end

function sprite_id_location.__eq(lhs, rhs)
  return tile_vector.__eq(lhs, rhs)
end

-- return the sprite id  corresponding to a sprite location on a spritesheet
function sprite_id_location:to_sprite_id()
  return 16 * self.j + self.i
end


-- location is a special tile_vector with the semantics of a tilemap location
-- and associated conversion methods
location = derived_class(tile_vector)

function location:_tostring()
  return "location("..self.i..", "..self.j..")"
end

function location.__eq(lhs, rhs)
  return tile_vector.__eq(lhs, rhs)
end

-- return the topleft position corresponding to a tile location
function location:to_topleft_position()
  return vector(8 * self.i, 8 * self.j)
end

-- return the center position corresponding to a tile location
function location:to_center_position()
  return vector(8 * self.i + 4, 8 * self.j + 4)
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

function vector:_tostring()
  return "vector("..self.x..", "..self.y..")"
end

function vector.__eq(lhs, rhs)
  return lhs.x == rhs.x and lhs.y == rhs.y
end

-- almost_eq can be used as static function of method, since self would simply replace lhs
function vector.almost_eq(lhs, rhs, eps)
  assert(getmetatable(lhs) == vector and getmetatable(rhs) == vector, "vector.almost_eq: lhs and rhs are not both vectors (lhs: "..dump(lhs)..", rhs: "..dump(rhs)..")")
  return almost_eq(lhs.x, rhs.x, eps) and almost_eq(lhs.y, rhs.y, eps)
end

function vector.__add(lhs, rhs)
  return vector(lhs.x + rhs.x, lhs.y + rhs.y)
end

-- in-place operation as native lua replacements for pico-8 +=
function vector:add_inplace(other)
  self.x = self.x + other.x
  self.y = self.y + other.y
end

function vector.__sub(lhs, rhs)
  return vector(lhs.x - rhs.x, lhs.y - rhs.y)
end

-- in-place operation as native lua replacements for pico-8 -=
function vector:sub_inplace(other)
  self.x = self.x - other.x
  self.y = self.y - other.y
end

function vector.__mul(lhs, rhs)
  if type(lhs) == "number" then
    return vector(lhs * rhs.x, lhs * rhs.y)
  elseif type(rhs) == "number" then
    return vector(rhs * lhs.x, rhs * lhs.y)
  else
    assert(false, "vector multiplication is only supported with a scalar, "..
      "tried to multiply "..lhs:_tostring().." and "..rhs:_tostring())
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
    assert(false, "vector division is only supported with a scalar as rhs, "..
      "tried to multiply "..stringify(lhs).." and "..rhs)
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

function vector:with_clamped_magnitude(max_magnitude)
  assert(max_magnitude >= 0)
  local magnitude = self:magnitude()
  if magnitude > max_magnitude then
      return max_magnitude * self / magnitude
  end
  return self
end

function vector:clamp_magnitude(max_magnitude)
  assert(max_magnitude >= 0)
  local magnitude = self:magnitude()
  if magnitude > max_magnitude then
    self.x = self.x * max_magnitude / magnitude
    self.y = self.y * max_magnitude / magnitude
  end
end

function vector:with_clamped_magnitude_cardinal(max_magnitude_x, max_magnitude_y)
  -- if 1 arg is passed, use the same max for x and y
  max_magnitude_y = max_magnitude_y or max_magnitude_x
  assert(max_magnitude_x >= 0 and max_magnitude_y >= 0)
  return vector(mid(-max_magnitude_x, self.x, max_magnitude_x), mid(-max_magnitude_y, self.y, max_magnitude_y))
end

function vector:clamp_magnitude_cardinal(max_magnitude_x, max_magnitude_y)
  -- if 1 arg is passed, use the same max for x and y
  max_magnitude_y = max_magnitude_y or max_magnitude_x
  assert(max_magnitude_x >= 0 and max_magnitude_y >= 0)
  self.x = mid(-max_magnitude_x, self.x, max_magnitude_x)
  self.y = mid(-max_magnitude_y, self.y, max_magnitude_y)
end

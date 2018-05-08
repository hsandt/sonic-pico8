require("class")

-- location class
location = new_class()

-- i       int     horizontal coordinate in tile steps
-- j       int     vertical   coordinate in tile steps
function location:_init(i, j)
  self.i = i
  self.j = j
end

function location:_tostring()
  return "location("..self.i..", "..self.j..")"
end

function location.__eq(lhs, rhs)
  return lhs.i == rhs.i and lhs.j == rhs.j
end

-- return the position corresponding to a location
function location:to_position()
  return vector(8 * self.i, 8 * self.j)
end

-- vector class
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

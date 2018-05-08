picotest = require("picotest")
math = require("math")

function test_math(desc,it)

  desc('tile_vector._init', function ()
    it('should create a new tile vector with the right coordinates', function ()
      local loc = tile_vector(2, -6)
      return loc.i == 2 and loc.j == -6
    end)
  end)

  desc('tile_vector._tostring', function ()
    it('should return a string representation with the right coordinates', function ()
      local loc = tile_vector(2, -6)
      return loc:_tostring() == "tile_vector(2, -6)"
    end)
  end)

  desc('tile_vector.__eq', function ()
    it('should return true if tile vectors have the same coordinates', function ()
      local loc1 = tile_vector(1, -4)
      local loc2 = tile_vector(1, -4)
      return loc1 == loc2
    end)
    it('should return false if tile vectors have different coordinates', function ()
      local loc1 = tile_vector(1, -4)
      local loc2 = tile_vector(1, -5)
      return loc1 ~= loc2
    end)
  end)

  desc('sprite_id_location.__eq', function ()
    it('should return true if sprite locations have the same coordinates', function ()
      local loc1 = sprite_id_location(1, -4)
      local loc2 = sprite_id_location(1, -4)
      return loc1 == loc2
    end)
    it('should return false if sprite locations have different coordinates', function ()
      local loc1 = sprite_id_location(1, -4)
      local loc2 = sprite_id_location(1, -5)
      return loc1 ~= loc2
    end)
  end)

  desc('sprite_id_location.to_sprite_id', function ()
    it('(2 2) => 34', function ()
      return sprite_id_location(2, 2):to_sprite_id() == 34
    end)
    it('(15 1) => 31', function ()
      return sprite_id_location(15, 1):to_sprite_id() == 31
    end)
  end)

  desc('location.__eq', function ()
    it('should return true if locations have the same coordinates', function ()
      local loc1 = location(1, -4)
      local loc2 = location(1, -4)
      return loc1 == loc2
    end)
    it('should return false if locations have different coordinates', function ()
      local loc1 = location(1, -4)
      local loc2 = location(1, -5)
      return loc1 ~= loc2
    end)
  end)

  desc('location.to_topleft_position', function ()
    it('(1 2) => (8 16)', function ()
      return location(1, 2):to_topleft_position() == vector(8, 16)
    end)
  end)

  desc('location.to_center_position', function ()
    it('(1 2) => (12 20)', function ()
      return location(1, 2):to_center_position() == vector(12, 20)
    end)
  end)

  desc('vector._init', function ()
    it('should create a new vector with the right coordinates', function ()
      local vec = vector(2, -6)
      return vec.x == 2 and vec.y == -6
    end)
  end)

  desc('vector.__eq', function ()
    it('should return true if vectors have the same coordinates', function ()
      local vec1 = vector(1, -4)
      local vec2 = vector(1, -4)
      return vec1 == vec2
    end)
    it('should return false if vectors have different coordinates', function ()
      local vec1 = vector(1, -4)
      local vec2 = vector(1, -5)
      return vec1 ~= vec2
    end)
  end)

  desc('vector.__sub', function ()
    it('(3 2) - (5 3) => (-2 -1)', function ()
      return vector(3, 2) - vector(5, 3) == vector(-2, -1)
    end)
  end)

end

add(picotest.test_suite, test_math)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('math', test_math)
end

-- empty update allows to close test window with ctrl+c
function _update()
end

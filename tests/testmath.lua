picotest = require("picotest")
math = require("math")

function test_math(desc,it)

  desc('almost_eq', function ()
    it('2.506 ~ 2.515', function ()
      return almost_eq(2.506, 2.515)
    end)
    it('2.505 ~! 2.516', function ()
      return not almost_eq(2.505, 2.516)
    end)
    it('-5.984 ~ -5.9835 with eps=0.001', function ()
      return almost_eq(-5.984, -5.9835, 0.001)
    end)
    it('-5.984 !~ -5.9828 with eps=0.001', function ()
      return not almost_eq(-5.984, -5.9828, 0.001)
    end)
  end)

  desc('tile_vector._init', function ()
    it('should create a new tile vector with the right coordinates', function ()
      local loc = tile_vector(2, -6)
      return loc.i == 2 and loc.j == -6
    end)
  end)

  desc('tile_vector._tostring', function ()
    it('should return a string representation with the right coordinates', function ()
      local tile_vec = tile_vector(2, -6)
      return tile_vec:_tostring() == "tile_vector(2, -6)"
    end)
  end)

  desc('tile_vector.__eq', function ()
    it('should return true if tile vectors have the same coordinates', function ()
      local tile_vec1 = tile_vector(1, -4)
      local tile_vec2 = tile_vector(1, -4)
      return tile_vec1 == tile_vec2
    end)
    it('should return false if tile vectors have different coordinates', function ()
      local tile_vec1 = tile_vector(1, -4)
      local tile_vec2 = tile_vector(1, -5)
      return tile_vec1 ~= tile_vec2
    end)
  end)

  desc('sprite_id_location._tostring', function ()
    it('should return a string representation with the right coordinates', function ()
      local sprite_id_loc = sprite_id_location(2, -6)
      return sprite_id_loc:_tostring() == "sprite_id_location(2, -6)"
    end)
  end)

  desc('sprite_id_location.__eq', function ()
    it('should return true if sprite locations have the same coordinates', function ()
      local tile_vec1 = sprite_id_location(1, -4)
      local tile_vec2 = sprite_id_location(1, -4)
      return tile_vec1 == tile_vec2
    end)
    it('should return false if sprite locations have different coordinates', function ()
      local tile_vec1 = sprite_id_location(1, -4)
      local tile_vec2 = sprite_id_location(1, -5)
      return tile_vec1 ~= tile_vec2
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

  desc('location._tostring', function ()
    it('should return a string representation with the right coordinates', function ()
      local loc = location(2, -6)
      return loc:_tostring() == "location(2, -6)"
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

  desc('vector._tostring', function ()
    it('should return a string representation with the right coordinates', function ()
      local vec = vector(2, -6)
      return vec:_tostring() == "vector(2, -6)"
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

  desc('vector._almost_eq and vector:almost_eq', function ()
    it('vector(2.50501 5.8) ~ vector(2.515 5.79) (static version)', function ()
      -- due to precision issues, 2.505 !~ 2.515 with default eps=0.01!
      return vector._almost_eq(vector(2.50501, 5.8), vector(2.515, 5.79))
    end)
    it('vector(2.50501 5.8) ~ vector(2.515 5.79)', function ()
      return vector(2.50501, 5.8):almost_eq(vector(2.515, 5.79))
    end)
    it('vector(2.505 5.8) !~ vector(2.515 5.788)', function ()
      return not vector(2.505, 5.8):almost_eq(vector(2.515, 5.788))
    end)
    it('vector(2.505 5.8) ~ vector(2.5049 5.799) with eps=0.001', function ()
      return vector(2.505, 5.8):almost_eq(vector(2.5049, 5.799), 0.001)
    end)
    it('vector(2.505 5.8) !~ vector(2.5047 5.789) with eps=0.001', function ()
      return not vector(2.505, 5.8):almost_eq(vector(2.5047, 5.789), 0.001)
    end)
  end)

  desc('vector.__add', function ()
    it('(3 2) + (5 3) => (8 5)', function ()
      return vector(3, 2) + vector(5, 3) == vector(8, 5)
    end)
  end)

  desc('vector.__sub', function ()
    it('(3 2) - (5 3) => (-2 -1)', function ()
      return vector(3, 2) - vector(5, 3) == vector(-2, -1)
    end)
  end)

  desc('vector.__mul', function ()
    it('(3 2) * -2 => (-6 -4)', function ()
      return vector(3, 2) * -2 == vector(-6, -4)
    end)
    it('4 * (-3 2) => (-12 8)', function ()
      return 4 * vector(-3, 2) == vector(-12, 8)
    end)
  end)

  desc('vector.sqr_magnitude', function ()
    it('(4 3) => 25', function ()
      return vector(4, 3):sqr_magnitude() == 25
    end)
    it('(-4 3) => 25', function ()
      return vector(-4, 3):sqr_magnitude() == 25
    end)
    it('(9 -14.2) => 282.64', function ()
      return almost_eq(vector(9, -14.2):sqr_magnitude(), 282.64)
    end)
    it('(0 0) => 0', function ()
      return vector(0, 0):sqr_magnitude() == 0
    end)
  end)

  desc('vector.magnitude', function ()
    it('(4 3) => 5', function ()
      return almost_eq(vector(4, 3):magnitude(), 5)
    end)
    it('(-4 3) => 5', function ()
      return almost_eq(vector(-4, 3):magnitude(), 5)
    end)
    it('(9 -14.2) => 16.811900547', function ()
      return almost_eq(vector(9, -14.2):magnitude(), 16.811900547)
    end)
    it('(0 0) => 0', function ()
      return vector(0, 0):magnitude() == 0
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

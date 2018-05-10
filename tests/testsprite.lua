picotest = require("picotest")
sprite = require("sprite")

function test_sprite(desc,it)

  desc('sprite._init', function ()
    it('should init a sprite with an id_loc', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3))
      return spr_data.id_loc == sprite_id_location(1, 3)
    end)
    it('should init a sprite with the passed span', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(4, 5))
      return spr_data.span == tile_vector(4, 5)
    end)
    it('should init a sprite with a span of (1 1) by default', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3))
      return spr_data.span == tile_vector(1, 1)
    end)
    it('should init a sprite with the passed pivot', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), nil, vector(2, 4))
      return spr_data.pivot == vector(2, 4)
    end)
    it('should init a sprite with a pivot of (0 0) by default', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), nil)
      return spr_data.pivot == vector.zero()
    end)
    it('should init a sprite with the correct values', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))
      return spr_data.id_loc == sprite_id_location(1, 3) and
        spr_data.span == tile_vector(2, 3) and
        spr_data.pivot == vector(2, 4)
    end)
  end)

  desc('sprite._tostring', function ()

    it('sprite_data(sprite_id_location(1, 3), ...) => "sprite_data(sprite_id_location(1, 3), ...)"', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))
      return spr_data:_tostring() == "sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))"
    end)

  end)

  desc('sprite.__eq', function ()

    local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))
    local spr_data2 = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))
    local spr_data3 = sprite_data(sprite_id_location(1, 5), tile_vector(2, 3), vector(2, 4))

    it('sprite_data(sprite_id_location(1, 3), ...) == sprite_data(sprite_id_location(1, 3), ...)', function ()
      return spr_data == spr_data2
    end)

    it('sprite_data(sprite_id_location(1, 3), ...) == sprite_data(sprite_id_location(1, 5), ...)', function ()
      return spr_data ~= spr_data3
    end)

  end)

end

add(picotest.test_suite, test_sprite)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('sprite', test_sprite)
end

-- empty update allows to close test window with ctrl+c
function _update()
end

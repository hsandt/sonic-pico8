picotest = require("picotest")
sprite = require("sprite")

function test_sprite(desc,it)

  desc('sprite._init', function ()
    it('should init a sprite with the correct values', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3))
      return spr_data.sprite_id_loc == sprite_id_location(1, 3) and spr_data.sprite_span == tile_vector(2, 3)
    end)
    it('should init a sprite with a sprite_span of (1 1) by default', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3))
      return spr_data.sprite_id_loc == sprite_id_location(1, 3) and spr_data.sprite_span == tile_vector(1, 1)
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

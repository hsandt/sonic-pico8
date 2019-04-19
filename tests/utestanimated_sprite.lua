require("bustedhelper")
local sprite_data = require("engine/render/sprite_data")
animated_sprite_data = require("engine/render/animated_sprite_data")

describe('animated_sprite', function ()

  local spr_data1 = sprite_data(sprite_id_location(1, 0), tile_vector(1, 2), vector(4, 6))
  local spr_data2 = sprite_data(sprite_id_location(2, 0), tile_vector(1, 2), vector(4, 6))

  describe('_init', function ()
    it('should init a sprite with all parameters', function ()
      local anim_spr_data = animated_sprite_data({spr_data1, spr_data2}, 2, true)
      assert.are_same({{spr_data1, spr_data2}, 2, true},
        {anim_spr_data.sprites, anim_spr_data.step_frames, anim_spr_data.looping})
    end)
    it('should init a sprite with looping false by default', function ()
      local anim_spr_data = animated_sprite_data({spr_data1, spr_data2}, 2)
      assert.is_false(anim_spr_data.looping)
    end)
  end)

  describe('_tostring', function ()

    it('sprite_data((1, 3) ...) => "sprite_data(sprite_id_location(1, 3) ...)"', function ()
      local anim_spr_data = animated_sprite_data({spr_data1, spr_data2}, 2, true)
      assert.are_equal("animated_sprite_data([2 sprites], 2, true)", anim_spr_data:_tostring())
    end)

  end)

end)

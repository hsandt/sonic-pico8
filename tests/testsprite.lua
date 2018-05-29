require("bustedhelper")
sprite = require("engine/render/sprite")

describe('sprite', function ()

  describe('_init', function ()
    it('should init a sprite with an id_loc', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3))
      assert.are_equal(sprite_id_location(1, 3), spr_data.id_loc)
    end)
    it('should init a sprite with the passed span', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(4, 5))
      assert.are_equal(tile_vector(4, 5), spr_data.span)
    end)
    it('should init a sprite with a span of (1, 1) by default', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3))
      assert.are_equal(tile_vector(1, 1), spr_data.span)
    end)
    it('should init a sprite with the passed pivot', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), nil, vector(2, 4))
      assert.are_equal(vector(2, 4), spr_data.pivot)
    end)
    it('should init a sprite with a pivot of (0, 0) by default', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), nil)
      assert.are_equal(vector.zero(), spr_data.pivot)
    end)
    it('should init a sprite with the correct values', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))
      assert.are_same({sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4)}, {spr_data.id_loc, spr_data.span, spr_data.pivot})
    end)
  end)

  describe('_tostring', function ()

    it('sprite_data((1, 3) ...) => "sprite_data(sprite_id_location(1, 3) ...)"', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))
      assert.are_equal("sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))", spr_data:_tostring())
    end)

  end)

  describe('__eq', function ()

    local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))
    local spr_data2 = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))
    local spr_data3 = sprite_data(sprite_id_location(1, 5), tile_vector(2, 3), vector(2, 4))

    it('sprite_data((1 3) ...) == sprite_data((1 3) ...)', function ()
      assert.are_equal(spr_data2, spr_data)
    end)

    it('sprite_data((1 3) ...) == sprite_data((1 5), ...)', function ()
      assert.are_not_equal(spr_data3, spr_data)
    end)

  end)

  describe('render', function ()

    local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4))
    local spr_stub

    setup(function ()
      spr_stub = stub(_G, "spr")
    end)

    teardown(function ()
      spr_stub:revert()
    end)

    after_each(function ()
      spr_stub:clear()
    end)

    it('should render the sprite from the id location, at the draw position minus pivot, with correct span and flip', function ()
      spr_data:render(vector(4, 8), false, true)
      assert.spy(spr_stub).was.called(1)
      assert.spy(spr_stub).was.called_with(49, 2, 4, 2, 3, false, true)
    end)

  end)

end)

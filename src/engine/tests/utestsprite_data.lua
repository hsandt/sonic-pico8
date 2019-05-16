require("engine/test/bustedhelper")
local sprite_data = require("engine/render/sprite_data")

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

  describe('render', function ()

    local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(11, 10))
    local spr_data2 = sprite_data(sprite_id_location(1, 3), tile_vector(2, 1), vector(8, 4))
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

    it('should render the sprite from the id location, at the draw position minus pivot, with correct span when not flipping', function ()
      spr_data:render(vector(41, 80), false, false)

      assert.spy(spr_stub).was_called(1)
      assert.spy(spr_stub).was_called_with(49, 30, 70, 2, 3, false, false)
    end)

    it('should render the sprite from the id location, at the draw position minus pivot itself flipped on x, with correct span when flipping x', function ()
      spr_data:render(vector(41, 80), true, false)

      assert.spy(spr_stub).was_called(1)
      -- flip pivot (11, 10) around center x axis which is at 8 * span.x / 2 = 8 -> flipped pivot (5, 10)
      assert.spy(spr_stub).was_called_with(49, 36, 70, 2, 3, true, false)
    end)

    it('should render the sprite from the id location, at the draw position minus pivot itself flipped on y, with correct span when flipping y', function ()
      spr_data:render(vector(41, 80), false, true)

      assert.spy(spr_stub).was_called(1)
      -- flip pivot (11, 10) around center y axis which is at 8 * span.y / 2 = 12 -> flipped pivot (11, 14)
      assert.spy(spr_stub).was_called_with(49, 30, 66, 2, 3, false, true)
    end)

    it('should render the sprite from the id location, at the draw position minus pivot itself flipped on x and y, with correct span when flipping x and y', function ()
      spr_data:render(vector(41, 80), true, true)

      assert.spy(spr_stub).was_called(1)
      assert.spy(spr_stub).was_called_with(49, 36, 66, 2, 3, true, true)
    end)

    it('should render the sprite from the id location, at the draw position minus pivot located at center, with correct span when flipping x and y', function ()
      spr_data2:render(vector(8, 4), true, true)

      assert.spy(spr_stub).was_called(1)
      -- pivot is already at center, so flip has no effect on it
      -- and since position == pivot, it draws at the origin
      assert.spy(spr_stub).was_called_with(49, 0, 0, 2, 1, true, true)
    end)

  end)

end)

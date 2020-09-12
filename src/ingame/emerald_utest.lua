require("test/bustedhelper")
local emerald = require("ingame/emerald")

local sprite_data = require("engine/render/sprite_data")

local visual = require("resources/visual")

describe('emerald', function ()

  describe('_init', function ()

    it('should create an emerald with a number', function ()
      local em = emerald(7, location(2, 1))
      assert.are_same({7, location(2, 1)}, {em.number, em.location})
    end)

  end)

  describe('_tostring', function ()

    it('emerald(7, location(2, 1)) => "emerald(7, location(2, 1))"', function ()
      local em = emerald(7, location(2, 1))
      assert.are_equal("emerald(7, location(2, 1))", em:_tostring())
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(sprite_data, "render")
    end)

    teardown(function ()
      sprite_data.render:revert()
    end)

    after_each(function ()
      sprite_data.render:clear()
    end)

    it('should draw emerald sprite data at tile center', function ()
      local em = emerald(7, location(2, 1))

      em:render()

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.emerald), vector(20, 12))
    end)

  end)

end)

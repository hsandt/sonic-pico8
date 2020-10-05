require("test/bustedhelper")
local emerald = require("ingame/emerald")

local sprite_data = require("engine/render/sprite_data")

local visual = require("resources/visual")

describe('emerald', function ()

  describe('init', function ()

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

  describe('get_center', function ()

    it('emerald(7, location(2, 1)) => "emerald(7, location(2, 1))"', function ()
      local em = emerald(7, location(2, 1))
      assert.are_same(vector(20, 12), em:get_center())
    end)

  end)

  describe('draw (static)', function ()

    setup(function ()
      stub(sprite_data, "render")
      stub(_G, "pal")
    end)

    teardown(function ()
      sprite_data.render:revert()
      pal:revert()
    end)

    after_each(function ()
      sprite_data.render:clear()
      pal:clear()
    end)

    it('should draw emerald sprite data at tile center', function ()
      emerald.draw(3, vector(20, 12))

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.emerald), vector(20, 12))
    end)

    it('should call pal with emerald colors matcing number, then clear palette change', function ()
      emerald.draw(3, vector(20, 12))

      -- unfortunately we cannot really test call order between pal and render,
      --  so at least we check the call arguments
      assert.spy(pal).was_called(3)
      assert.spy(pal).was_called_with(colors.red, visual.emerald_colors[3][1])
      assert.spy(pal).was_called_with(colors.dark_purple, visual.emerald_colors[3][2])
      assert.spy(pal).was_called_with()
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(emerald, "draw")
    end)

    teardown(function ()
      emerald.draw:revert()
    end)

    after_each(function ()
      emerald.draw:clear()
    end)

    it('should delegate to emerald.draw with emerald number and center position', function ()
      local em = emerald(7, location(2, 1))

      em:render()

      assert.spy(emerald.draw).was_called(1)
      assert.spy(emerald.draw).was_called_with(7, vector(20, 12))
    end)

  end)

end)

-- emerald is drawn in both ingame and titlemenu,
--  so exceptionally both bustedhelper work, as long as one of the two
--  visual add-ons are loaded
require("test/bustedhelper_ingame")

local emerald_common = require("render/emerald_common")

local sprite_data = require("engine/render/sprite_data")

local visual = require("resources/visual_common")

describe('emerald_common', function ()

  describe('set_color_palette (static)', function ()

    -- now all is done via swap_colors, but this utest was written before so we kept the test
    --  checking actual pal() calls inside

    setup(function ()
      stub(_G, "pal")
    end)

    teardown(function ()
      pal:revert()
    end)

    after_each(function ()
      pal:clear()
    end)

    it('should call pal with emerald colors matching number, then clear palette change', function ()
      emerald_common.draw(3, vector(20, 12))

      -- unfortunately we cannot really test call order between pal and render,
      --  so at least we check the call arguments
      assert.spy(pal).was_called(3)
      assert.spy(pal).was_called_with(colors.red, visual.emerald_colors[3][1])
      assert.spy(pal).was_called_with(colors.dark_purple, visual.emerald_colors[3][2])
      assert.spy(pal).was_called_with()
    end)

    it('(brightness 1) should call pal with emerald brighter colors matching number, then clear palette change', function ()
      emerald_common.draw(3, vector(20, 12), 1)

      -- unfortunately we cannot really test call order between pal and render,
      --  so at least we check the call arguments
      assert.spy(pal).was_called(3)
      assert.spy(pal).was_called_with(colors.red, colors.white)
      assert.spy(pal).was_called_with(colors.dark_purple, visual.emerald_colors[3][1])
      assert.spy(pal).was_called_with()
    end)

    it('(brightness 2) should call pal with white colors, then clear palette change', function ()
      emerald_common.draw(3, vector(20, 12), 2)

      -- unfortunately we cannot really test call order between pal and render,
      --  so at least we check the call arguments
      assert.spy(pal).was_called(3)
      assert.spy(pal).was_called_with(colors.red, colors.white)
      assert.spy(pal).was_called_with(colors.dark_purple, colors.white)
      assert.spy(pal).was_called_with()
    end)

  end)

  describe('draw (static)', function ()

    setup(function ()
      stub(sprite_data, "render")
      stub(emerald_common, "set_color_palette")
      stub(_G, "pal")
    end)

    teardown(function ()
      sprite_data.render:revert()
      emerald_common.set_color_palette:revert()
      pal:revert()
    end)

    after_each(function ()
      sprite_data.render:clear()
      emerald_common.set_color_palette:clear()
      pal:clear()
    end)

    it('should draw emerald sprite data at tile center', function ()
      emerald_common.draw(3, vector(20, 12))

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.emerald), vector(20, 12))
    end)

    it('should call set_color_palette with number, then clear palette change', function ()
      emerald_common.draw(3, vector(20, 12))

      assert.spy(emerald_common.set_color_palette).was_called(1)
      -- was_called_with can see optional argument brightness passed as nil, we must mention it!
      assert.spy(emerald_common.set_color_palette).was_called_with(3, nil)
      assert.spy(pal).was_called(1)
      assert.spy(pal).was_called_with()
    end)

    it('should call set_color_palette with number, optional brightness, then clear palette change', function ()
      emerald_common.draw(3, vector(20, 12), 2)

      assert.spy(emerald_common.set_color_palette).was_called(1)
      assert.spy(emerald_common.set_color_palette).was_called_with(3, 2)
      assert.spy(pal).was_called(1)
      assert.spy(pal).was_called_with()
    end)

  end)

end)

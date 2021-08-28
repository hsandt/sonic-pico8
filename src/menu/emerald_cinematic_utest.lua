-- emerald is drawn in both ingame and titlemenu,
--  so exceptionally both bustedhelper work, as long as one of the two
--  visual add-ons are loaded
require("test/bustedhelper_ingame")

local emerald_cinematic = require("menu/emerald_cinematic")
local emerald_common = require("render/emerald_common")

local sprite_data = require("engine/render/sprite_data")

local visual = require("resources/visual_common")

describe('emerald', function ()

  describe('init', function ()

    it('should create an emerald with a number and position on screen, default scale 1', function ()
      local em = emerald_cinematic(7, vector(20, 10))
      assert.are_same({7, vector(20, 10), 1}, {em.number, em.position, em.scale})
    end)

    it('should create an emerald with a number and position on screen, and scale', function ()
      local em = emerald_cinematic(7, vector(20, 10), 2)
      assert.are_same({7, vector(20, 10), 2}, {em.number, em.position, em.scale})
    end)

  end)

  describe('_tostring', function ()

    it('emerald(7, vector(2, 1)) => "emerald(7, vector(20, 10))"', function ()
      local em = emerald_cinematic(7, vector(20, 10), 2)
      assert.are_equal("emerald(7, vector(20, 10), 2)", em:_tostring())
    end)

  end)

  describe('draw', function ()

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

    it('should delegate to emerald_common.set_color_palette with emerald number, sprite data render with position and scale, pal()', function ()
      local em = emerald_cinematic(7, vector(20, 10), 2)

      em:draw()

      assert.spy(emerald_common.set_color_palette).was_called(1)
      assert.spy(emerald_common.set_color_palette).was_called_with(7)
      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.emerald), vector(20, 10), false, false, 0, 2)
      assert.spy(pal).was_called(1)
      assert.spy(pal).was_called_with()
    end)

  end)

end)

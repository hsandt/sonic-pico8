-- cinematic emerald drawn in titlemenu, so just use bustedhelper for titlemenu
require("test/bustedhelper_titlemenu")

local postprocess = require("engine/render/postprocess")

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

    it('should delegate to emerald_common.set_color_palette with emerald number and brightness, sprite data render with position and scale, pal()', function ()
      local em = emerald_cinematic(7, vector(20, 10), 2)
      em.brightness = 2

      em:draw()

      assert.spy(emerald_common.set_color_palette).was_called(1)
      assert.spy(emerald_common.set_color_palette).was_called_with(7, 2)
      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.emerald), vector(20, 10), false, false, 0, 2)
      assert.spy(pal).was_called(1)
      assert.spy(pal).was_called_with()
    end)

    it('should delegate to pal with postprocess.swap_palette_by_darkness with emerald number and brightness < 0, sprite data render with position and scale, pal()', function ()
      local em = emerald_cinematic(7, vector(20, 10), 2)
      em.brightness = -2

      em:draw()

      -- called twice to swap the light and dark color of the emerald, then once to clear swapping
      assert.spy(pal).was_called(3)
      local light_color, dark_color = unpack(visual.emerald_colors[7])
      assert.spy(pal).was_called_with(colors.red, postprocess.swap_palette_by_darkness[light_color][2])
      assert.spy(pal).was_called_with(colors.dark_purple, postprocess.swap_palette_by_darkness[dark_color][2])
      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.emerald), vector(20, 10), false, false, 0, 2)
      assert.spy(pal).was_called_with()
    end)

  end)

end)

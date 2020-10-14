require("test/bustedhelper")
local emerald_fx = require("ingame/emerald_fx")

local sprite_data = require("engine/render/sprite_data")

local emerald = require("ingame/emerald")
local fx = require("ingame/fx")
local visual = require("resources/visual_common")

describe('emerald_fx', function ()

  describe('init', function ()

    setup(function ()
      stub(fx, "init")
    end)

    teardown(function ()
      fx.init:revert()
    end)

    after_each(function ()
      fx.init:clear()
    end)

    it('should call base constructor with common arguments', function ()
      local emerald_fx1 = emerald_fx(3, vector(12, 2), {["once"] = "dummy_sprite_data"})

      assert.spy(fx.init).was_called(1)
      assert.spy(fx.init).was_called_with(match.ref(emerald_fx1), vector(12, 2), visual.animated_sprite_data_t.emerald_pick_fx)
    end)

    it('should set number', function ()
      local emerald_fx1 = emerald_fx(3, vector(12, 2), {["once"] = "dummy_sprite_data"})

      assert.are_equal(3, emerald_fx1.number)
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(emerald, "set_color_palette")
      stub(sprite_data, "render")
      stub(_G, "pal")
    end)

    teardown(function ()
      emerald.set_color_palette:revert()
      sprite_data.render:revert()
      pal:revert()
    end)

    after_each(function ()
      emerald.set_color_palette:clear()
      sprite_data.render:clear()
      pal:clear()
    end)

    it('should call emerald.set_color_palette, then anim_spr:render and finally clear palette"', function ()
      local emerald_fx1 = emerald_fx(3, vector(12, 2), {["once"] = "dummy_sprite_data"})

      emerald_fx1:render()

      assert.spy(emerald.set_color_palette).was_called(1)
      assert.spy(emerald.set_color_palette).was_called_with(3)
      assert.spy(pal).was_called(1)
      assert.spy(pal).was_called_with()
    end)

  end)

end)

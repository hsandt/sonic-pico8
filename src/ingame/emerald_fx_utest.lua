require("test/bustedhelper_ingame")
local emerald_fx = require("ingame/emerald_fx")

local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")

local fx = require("ingame/fx")
local emerald_common = require("render/emerald_common")
local visual = require("resources/visual_common")

describe('emerald_fx', function ()

  local spr_data1 = sprite_data(sprite_id_location(1, 0), tile_vector(1, 2), vector(4, 6))
  local spr_data2 = sprite_data(sprite_id_location(2, 0), tile_vector(1, 2), vector(4, 6))

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
      local anim_spr_data = animated_sprite_data({spr_data1, spr_data2}, 2, anim_loop_modes.clear)
      local emerald_fx1 = emerald_fx(3, vector(12, 2), anim_spr_data)

      assert.spy(fx.init).was_called(1)
      assert.spy(fx.init).was_called_with(match.ref(emerald_fx1), vector(12, 2), match.ref(anim_spr_data))
    end)

    it('should set number', function ()
      local emerald_fx1 = emerald_fx(3, vector(12, 2), anim_spr_data)

      assert.are_equal(3, emerald_fx1.number)
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(emerald_common, "set_color_palette")
      stub(sprite_data, "render")
      stub(_G, "pal")
    end)

    teardown(function ()
      emerald_common.set_color_palette:revert()
      sprite_data.render:revert()
      pal:revert()
    end)

    after_each(function ()
      emerald_common.set_color_palette:clear()
      sprite_data.render:clear()
      pal:clear()
    end)

    it('should call emerald_common.set_color_palette, then anim_spr:render and finally clear palette"', function ()
      local anim_spr_data = animated_sprite_data({spr_data1, spr_data2}, 2, anim_loop_modes.clear)
      local emerald_fx1 = emerald_fx(3, vector(12, 2), anim_spr_data)

      emerald_fx1:render()

      assert.spy(emerald_common.set_color_palette).was_called(1)
      assert.spy(emerald_common.set_color_palette).was_called_with(3)
      assert.spy(pal).was_called(1)
      assert.spy(pal).was_called_with()
    end)

  end)

end)

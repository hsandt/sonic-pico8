require("test/bustedhelper")
local fx = require("ingame/fx")

local animated_sprite = require("engine/render/animated_sprite")

describe('fx', function ()

  describe('init', function ()

    setup(function ()
      stub(animated_sprite, "play")
    end)

    teardown(function ()
      animated_sprite.play:revert()
    end)

    after_each(function ()
      animated_sprite.play:clear()
    end)

    it('should create an fx with a position and animated sprite data, and play "once" anim immediately', function ()
      local fx1 = fx(vector(12, 2), {["once"] = "dummy_sprite_data"})
      assert.are_same({vector(12, 2), animated_sprite({["once"] = "dummy_sprite_data"})},
        {fx1.position, fx1.anim_spr})

      assert.spy(animated_sprite.play).was_called(1)
      assert.spy(animated_sprite.play).was_called_with(match.ref(fx1.anim_spr), "once")
    end)

  end)

  describe('is_active', function ()

    it('should return true after construction, as anim is still playing"', function ()
      local fx1 = fx(vector(12, 2), {["once"] = "dummy_sprite_data"})
      assert.is_true(fx1:is_active())
    end)

    it('should return false after stopping, as anim is still playing"', function ()
      local fx1 = fx(vector(12, 2), {["once"] = "dummy_sprite_data"})
      -- simulate anim end, since we only have dummy sprite data and cannot really end it with update
      fx1.anim_spr.playing = false

      assert.is_false(fx1:is_active())
    end)

  end)

  describe('update', function ()

    setup(function ()
      stub(animated_sprite, "update")
    end)

    teardown(function ()
      animated_sprite.update:revert()
    end)

    after_each(function ()
      animated_sprite.update:clear()
    end)

    it('should call update on anim_spr"', function ()
      local fx1 = fx(vector(12, 2), {["once"] = "dummy_sprite_data"})

      fx1:update()

      assert.spy(animated_sprite.update).was_called(1)
      assert.spy(animated_sprite.update).was_called_with(match.ref(fx1.anim_spr))
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(animated_sprite, "render")
    end)

    teardown(function ()
      animated_sprite.render:revert()
    end)

    after_each(function ()
      animated_sprite.render:clear()
    end)

    it('should call render on anim_spr"', function ()
      local fx1 = fx(vector(12, 2), {["once"] = "dummy_sprite_data"})

      fx1:render()

      assert.spy(animated_sprite.render).was_called(1)
      assert.spy(animated_sprite.render).was_called_with(match.ref(fx1.anim_spr), vector(12, 2))
    end)

  end)

end)

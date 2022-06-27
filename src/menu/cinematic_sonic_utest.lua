require("test/bustedhelper_titlemenu")

local cinematic_sonic = require("menu/cinematic_sonic")

local animated_sprite = require("engine/render/animated_sprite")

-- local sprite_data = require("engine/render/sprite_data")

local visual = require("resources/visual_common")

describe('cinematic_sonic', function ()

  describe('init', function ()

    it('should create a cinematic sonic with a position on screen, cinematic sonic animated sprite data and playing "run" animation', function ()
      local cs = cinematic_sonic(vector(20, 10))
      assert.are_equal(vector(20, 10), cs.position)
      assert.are_equal(visual.animated_sprite_data_t.cinematic_sonic, cs.anim_spr.data_table)
      assert.are_equal("run", cs.anim_spr.current_anim_key)
    end)

  end)

  describe('_tostring', function ()

    setup(function ()
      stub(animated_sprite, "_tostring", function (self)
        return "animated_sprite(...)"
      end)
    end)

    teardown(function ()
      animated_sprite._tostring:revert()
    end)

    after_each(function ()
      animated_sprite._tostring:clear()
    end)

    it('cinematic_sonic(vector(20, 10)) => "cinematic_sonic(vector(20, 10), animated_sprite(...))"', function ()
      local cs = cinematic_sonic(vector(20, 10))
      assert.are_equal("cinematic_sonic(vector(20, 10), animated_sprite(...))", cs:_tostring())
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

    it('should delegate to animated sprite update', function ()
      local cs = cinematic_sonic(vector(20, 10))

      cs:update()

      assert.spy(animated_sprite.update).was_called(1)
      assert.spy(animated_sprite.update).was_called_with(match.ref(cs.anim_spr))
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(animated_sprite, "render")
    end)

    teardown(function ()
      animated_sprite.render:revert()
    end)

    after_each(function ()
      animated_sprite.render:clear()
    end)

    it('should delegate to animated sprite render', function ()
      local cs = cinematic_sonic(vector(20, 10))

      cs:draw()

      assert.spy(animated_sprite.render).was_called(1)
      assert.spy(animated_sprite.render).was_called_with(match.ref(cs.anim_spr), vector(20, 10), false, false, 0, 2)
    end)

  end)

end)

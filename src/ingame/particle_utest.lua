require("test/bustedhelper_ingame")
local particle = require("ingame/particle")

local animated_sprite = require("engine/render/animated_sprite")

describe('particle', function ()

  describe('init', function ()

    it('should create an particle with lifetime, initial_position, initial_velocity, initial_size', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3)
      assert.are_same({2, vector(12, 2), vector(-2, 3), 3},
        {particle1.lifetime, particle1.position, particle1.frame_velocity, particle1.size})
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

    it('should update position with frame_velocity"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3)

      particle1:update()

      assert.are_same(vector(10, 5), particle1.position)
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(_G, "circfill")
    end)

    teardown(function ()
      circfill:revert()
    end)

    after_each(function ()
      circfill:clear()
    end)

    it('should call circfill at particle position, with size, white (hardcoded)"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3)

      particle1:render()

      assert.spy(circfill).was_called(1)
      assert.spy(circfill).was_called_with(12, 2, 3, colors.white)
    end)

  end)

end)

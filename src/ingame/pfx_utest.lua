require("test/bustedhelper_ingame")
local pfx = require("ingame/pfx")

local particle = require("ingame/particle")

describe('pfx', function ()

  describe('init', function ()

    it('should create an pfx with an empty sequence of particles', function ()
      local pfx1 = pfx()
      assert.are_same({}, pfx1.particles)
    end)

  end)

  describe('update', function ()

    setup(function ()
      stub(particle, "update")
    end)

    teardown(function ()
      particle.update:revert()
    end)

    after_each(function ()
      particle.update:clear()
    end)

    it('should call update on each particle"', function ()
      local pfx1 = pfx()
      add(pfx1.particles, particle(2, vector(12, 2), vector(-2, 3), 3))
      add(pfx1.particles, particle(2, vector(20, 2), vector(-2, 3), 3))

      pfx1:update()

      assert.spy(particle.update).was_called(2)
      assert.spy(particle.update).was_called_with(match.ref(pfx1.particles[1]))
      assert.spy(particle.update).was_called_with(match.ref(pfx1.particles[2]))
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(particle, "render")
    end)

    teardown(function ()
      particle.render:revert()
    end)

    after_each(function ()
      particle.render:clear()
    end)

    it('should call render on each anim_spr"', function ()
      local pfx1 = pfx()
      add(pfx1.particles, particle(2, vector(12, 2), vector(-2, 3), 3))
      add(pfx1.particles, particle(2, vector(20, 2), vector(-2, 3), 3))

      pfx1:render()

      assert.spy(particle.render).was_called(2)
      assert.spy(particle.render).was_called_with(match.ref(pfx1.particles[1]))
      assert.spy(particle.render).was_called_with(match.ref(pfx1.particles[2]))
    end)

  end)

end)

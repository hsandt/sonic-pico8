require("test/bustedhelper_ingame")
local pfx = require("ingame/pfx")

local particle = require("ingame/particle")

describe('pfx', function ()

  describe('init', function ()

    it('should create an pfx with passed frame period, and an empty sequence of particles', function ()
      local pfx1 = pfx(10, 60, vector(2, 3))
      assert.are_same({10, 60, vector(2, 3), {}, false},
        {pfx1.frame_period, pfx1.base_frame_lifetime, pfx1.base_init_velocity, pfx1.particles, pfx1.is_emitting})
    end)

  end)

  describe('start', function ()

    it('should set is_emitting to true and reset frame_time to 0', function ()
      local pfx1 = pfx(10)
      pfx1:start()
      assert.are_same({true, 0}, {pfx1.is_emitting, pfx1.frame_time})
    end)

  end)

  describe('stop', function ()

    it('should set is_emitting to false', function ()
      local pfx1 = pfx(10)
      pfx1:stop()
      assert.is_false(pfx1.is_emitting)
    end)

  end)

  describe('spawn_particle', function ()

    it('should add a new particle to the sequence', function ()
      local pfx1 = pfx(10, 5, vector(0, 0), 3)
      pfx1.position = vector(10, 20)

      pfx1:spawn_particle()

      assert.are_same({particle(5, vector(10, 20), vector(0, 0), 3)}, pfx1.particles)
    end)

  end)

  describe('update', function ()

    setup(function ()
      -- we don't want to rewrite the behavior of incrementing elapsed_frames and checking lifetime,
      --  so spy.on instead of stubbing
      spy.on(particle, "update_and_check_alive")
      stub(pfx, "spawn_particle")
    end)

    teardown(function ()
      particle.update_and_check_alive:revert()
      pfx.spawn_particle:revert()
    end)

    after_each(function ()
      particle.update_and_check_alive:clear()
      pfx.spawn_particle:clear()
    end)

    it('should call update_and_check_alive on each particle', function ()
      local pfx1 = pfx()
      add(pfx1.particles, particle(2, vector(10, 2), vector(-2, 3), 3))
      add(pfx1.particles, particle(2, vector(20, 2), vector(-2, 3), 3))
      add(pfx1.particles, particle(2, vector(30, 2), vector(-2, 3), 3))

      pfx1:update()

      assert.spy(particle.update_and_check_alive).was_called(3)
      assert.spy(particle.update_and_check_alive).was_called_with(match.ref(pfx1.particles[1]))
      assert.spy(particle.update_and_check_alive).was_called_with(match.ref(pfx1.particles[2]))
      assert.spy(particle.update_and_check_alive).was_called_with(match.ref(pfx1.particles[3]))
    end)

    it('should delete particles that reached end of lifetime from the particles sequence', function ()
      local pfx1 = pfx()
      add(pfx1.particles, particle(2, vector(10, 2), vector(-2, 3), 3))
      add(pfx1.particles, particle(2, vector(20, 2), vector(0, 0), 3))  -- no velocity to simplify update check
      add(pfx1.particles, particle(2, vector(30, 2), vector(-2, 3), 3))
      pfx1.particles[1].elapsed_frames = 1
      pfx1.particles[3].elapsed_frames = 1

      pfx1:update()

      assert.are_equal(1, #pfx1.particles)
      -- any test to identify the 2nd particle is fine (no vleocity so position hasn't changed)
      assert.are_equal(20, pfx1.particles[1].position.x)
    end)

    it('(not emitting) should not spawn particle', function ()
      local pfx1 = pfx(10)
      add(pfx1.particles, particle(2, vector(12, 2), vector(-2, 3), 3))
      add(pfx1.particles, particle(2, vector(20, 2), vector(-2, 3), 3))

      pfx1:update()

      assert.spy(pfx.spawn_particle).was_not_called()
    end)

    it('(emitting, more than one frame before period end) should not spawn particle', function ()
      local pfx1 = pfx(10)
      pfx1.is_emitting = true
      pfx1.frame_time = 8

      pfx1:update()

      assert.spy(pfx.spawn_particle).was_not_called()
    end)

    it('(emitting, one frame before period end) should spawn new particle', function ()
      local pfx1 = pfx(10)
      pfx1.is_emitting = true
      pfx1.frame_time = 9

      pfx1:update()

      assert.spy(pfx.spawn_particle).was_called(1)
      assert.spy(pfx.spawn_particle).was_called_with(match.ref(pfx1))
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

    it('should call render on each particle"', function ()
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

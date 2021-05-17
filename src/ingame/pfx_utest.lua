require("test/bustedhelper_ingame")
local pfx = require("ingame/pfx")

local particle = require("ingame/particle")

describe('pfx', function ()

  local function dummy_size_ratio_over_lifetime(life_ratio)
    return life_ratio
  end

  describe('init', function ()

    it('should create an pfx with passed frame period, and an empty sequence of particles', function ()
      local pfx1 = pfx(10, 4, 60, vector(2, 3), 0.5, 5.5, dummy_size_ratio_over_lifetime)
      assert.are_same({10, 4, 60, vector(2, 3), 0.5, 5.5, dummy_size_ratio_over_lifetime, {}, false},
        {pfx1.spawn_period_frames, pfx1.spawn_count, pfx1.base_lifetime_frames,
        pfx1.base_velocity, pfx1.max_deviation, pfx1.base_size, pfx1.size_ratio_over_lifetime,
        pfx1.particles, pfx1.is_emitting})
    end)

  end)

  describe('start', function ()

    it('should set is_emitting to true, reset frame_time to 0, set position and mirror_x', function ()
      local pfx1 = pfx(10, 4, 60, vector(2, 3), 0.5, 5.5, dummy_size_ratio_over_lifetime)
      pfx1:start(vector(2, 4), true)
      assert.are_same({true, 0, vector(2, 4), true}, {pfx1.is_emitting, pfx1.frame_time, pfx1.position, pfx1.mirror_x})
    end)

  end)

  describe('stop', function ()

    it('should set is_emitting to false', function ()
      local pfx1 = pfx(10, 4, 60, vector(2, 3), 0.5, 5.5, dummy_size_ratio_over_lifetime)
      pfx1:stop()
      assert.is_false(pfx1.is_emitting)
    end)

  end)

  describe('spawn_particle', function ()

    it('should add a new particle to the sequence', function ()
      -- max deviation 0 to avoid trickiness of testing random
      local pfx1 = pfx(10, 4, 60, vector(2, 3), 0, 5.5, dummy_size_ratio_over_lifetime)
      pfx1.position = vector(10, 20)

      pfx1:spawn_particle()

      assert.are_same({particle(60, vector(10, 20), vector(2, 3), vector(0, 0), 5.5, dummy_size_ratio_over_lifetime)}, pfx1.particles)
    end)

    it('(mirror_x: true) should add a new particle with velocity mirrored od X', function ()
      local pfx1 = pfx(10, 5, 60, vector(10, 5), 0, 3, dummy_size_ratio_over_lifetime)
      pfx1.position = vector(10, 20)
      pfx1.mirror_x = true

      pfx1:spawn_particle()

      -- vector(10, 5) -> vector(-10, 5)
      assert.are_same({particle(60, vector(10, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime)}, pfx1.particles)
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
      local pfx1 = pfx(10, 4, 60, vector(2, 3), 0, 5.5, dummy_size_ratio_over_lifetime)
      add(pfx1.particles, particle(60, vector(10, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime))
      add(pfx1.particles, particle(60, vector(20, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime))
      add(pfx1.particles, particle(60, vector(30, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime))

      pfx1:update()

      assert.spy(particle.update_and_check_alive).was_called(3)
      assert.spy(particle.update_and_check_alive).was_called_with(match.ref(pfx1.particles[1]))
      assert.spy(particle.update_and_check_alive).was_called_with(match.ref(pfx1.particles[2]))
      assert.spy(particle.update_and_check_alive).was_called_with(match.ref(pfx1.particles[3]))
    end)

    it('should delete particles that reached end of lifetime from the particles sequence', function ()
      local pfx1 = pfx(10, 4, 60, vector(2, 3), 0, 5.5, dummy_size_ratio_over_lifetime)
      add(pfx1.particles, particle(2, vector(10, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime))
      -- no velocity to simplify update check
      add(pfx1.particles, particle(2, vector(20, 20), vector(  0, 0), vector(0, 0), 3, dummy_size_ratio_over_lifetime))
      add(pfx1.particles, particle(2, vector(30, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime))
      pfx1.particles[1].elapsed_frames = 1
      pfx1.particles[3].elapsed_frames = 1

      pfx1:update()

      assert.are_equal(1, #pfx1.particles)
      -- any test to identify the 2nd particle is fine (no velocity so position hasn't changed)
      assert.are_equal(20, pfx1.particles[1].position.x)
    end)

    it('(not emitting) should not spawn particle', function ()
      local pfx1 = pfx(10, 4, 60, vector(2, 3), 0, 5.5, dummy_size_ratio_over_lifetime)
      add(pfx1.particles, particle(2, vector(10, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime))
      add(pfx1.particles, particle(2, vector(20, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime))

      pfx1:update()

      assert.spy(pfx.spawn_particle).was_not_called()
    end)

    it('(emitting, more than one frame before period end) should not spawn particle', function ()
      local pfx1 = pfx(10, 4, 60, vector(2, 3), 0, 5.5, dummy_size_ratio_over_lifetime)
      pfx1.is_emitting = true
      pfx1.frame_time = 8

      pfx1:update()

      assert.spy(pfx.spawn_particle).was_not_called()
    end)

    it('(emitting, one frame before period end) should spawn new particle', function ()
      local pfx1 = pfx(10, --[[spawn_count:]] 3, 60, vector(2, 3), 0, 5.5, dummy_size_ratio_over_lifetime)
      pfx1.is_emitting = true
      pfx1.frame_time = 9

      pfx1:update()

      assert.spy(pfx.spawn_particle).was_called(3)
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
      add(pfx1.particles, particle(2, vector(10, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime))
      add(pfx1.particles, particle(2, vector(10, 20), vector(-10, 5), vector(0, 0), 3, dummy_size_ratio_over_lifetime))

      pfx1:render()

      assert.spy(particle.render).was_called(2)
      assert.spy(particle.render).was_called_with(match.ref(pfx1.particles[1]))
      assert.spy(particle.render).was_called_with(match.ref(pfx1.particles[2]))
    end)

  end)

end)

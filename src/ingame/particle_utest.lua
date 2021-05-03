require("test/bustedhelper_ingame")
local particle = require("ingame/particle")

describe('particle', function ()

  describe('init', function ()

    it('should create an particle with frame_lifetime, initial_position, initial_velocity, max_size', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3, vector(-2, 2))
      assert.are_same({2, 0, vector(12, 2), vector(-2, 3), 3,
          vector(-2, 2)},
        {particle1.frame_lifetime, particle1.elapsed_frames, particle1.position, particle1.frame_velocity, particle1.max_size,
          particle1.frame_accel})
    end)

  end)

  describe('update_and_check_alive', function ()

    setup(function ()
      stub(particle, "update")
    end)

    teardown(function ()
      particle.update:revert()
    end)

    after_each(function ()
      particle.update:clear()
    end)

    it('should increment elapsed_frames"', function ()
      local particle1 = particle(10, vector(12, 2), vector(-2, 3), 3, vector(-2, 2))
      particle1.elapsed_frames = 5

      particle1:update_and_check_alive()

      assert.are_same(6, particle1.elapsed_frames)
    end)

    it('(elapsed_frames is just before frame_lifetime) should increment elapsed_frames"', function ()
      local particle1 = particle(10, vector(12, 2), vector(-2, 3), 3, vector(-2, 2))
      particle1.elapsed_frames = 9  -- 10 - 1

      local result = particle1:update_and_check_alive()

      -- semantically false, but for character optimization reasons, we return nil
      assert.is_nil(result)
    end)

    it('(elapsed_frames not just before frame_lifetime) should call update and return true"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3, vector(-2, 2))

      local result = particle1:update_and_check_alive()

      assert.spy(particle.update).was_called(1)
      assert.spy(particle.update).was_called_with(match.ref(particle1))

      assert.is_true(result)
    end)

    it('(elapsed_frames is just before frame_lifetime) should not call update as we returned earlier"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3, vector(-2, 2))
      particle1.elapsed_frames = 9  -- 10 - 1

      particle1:update_and_check_alive()

      assert.spy(particle.update).was_not_called()
    end)

  end)

  describe('update', function ()

    it('should update position with frame_velocity and return true"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3, vector(-2, 2))

      particle1:update()

      assert.are_same(vector(10, 5), particle1.position)
    end)

    it('should update velocity"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3, vector(-2, 2))

      particle1:update()

      assert.are_same(vector(-4, 5), particle1.frame_velocity)
    end)

    it('should update size"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3, vector(-2, 2))

      particle1:update()

      -- formula is a bit complex and hardcoded now, but try your bast
      assert.are_equal(9.8, particle1.size)  -- must update with final data
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(_G, "rectfill")
      stub(_G, "circfill")
    end)

    teardown(function ()
      rectfill:revert()
      circfill:revert()
    end)

    after_each(function ()
      rectfill:clear()
      circfill:clear()
    end)

    it('(size = 2..3) should call circfill at particle position, with size, white (hardcoded)"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 2.5)
      particle1.size = 2.5

      particle1:render()

      assert.spy(rectfill).was_called(1)
      assert.spy(rectfill).was_called_with(12, 2, 13, 3, colors.white)
    end)

    it('(size not in 2..3) should call circfill at particle position, with size, white (hardcoded)"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 5)
      particle1.size = 5

      particle1:render()

      assert.spy(circfill).was_called(1)
      assert.spy(circfill).was_called_with(12, 2, 2.5, colors.white)
    end)

  end)

end)

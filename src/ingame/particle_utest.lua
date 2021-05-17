require("test/bustedhelper_ingame")
local particle = require("ingame/particle")

describe('particle', function ()

  local function dummy_size_ratio_over_lifetime(life_ratio)
    return life_ratio
  end

  describe('init', function ()

    it('should create an particle with frame_lifetime, initial_position, initial_frame_velocity, frame_accel, base_size, size_ratio_over_lifetime', function ()
      local particle1 = particle(60, vector(10, 20), vector(2, 3), vector(0, 0), 5.5, dummy_size_ratio_over_lifetime)
      assert.are_same(          {60, vector(10, 20), vector(2, 3), vector(0, 0), 5.5, dummy_size_ratio_over_lifetime, 0, 0},
        {particle1.frame_lifetime, particle1.position, particle1.frame_velocity, particle1.frame_accel,
        particle1.base_size, particle1.size_ratio_over_lifetime, particle1.elapsed_frames, particle1.size})
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

    it('should increment elapsed_frames', function ()
      local particle1 = particle(10, vector(10, 20), vector(2, 3), vector(0, 0), 5.5, dummy_size_ratio_over_lifetime)
      particle1.elapsed_frames = 5

      particle1:update_and_check_alive()

      assert.are_same(6, particle1.elapsed_frames)
    end)

    it('(elapsed_frames is just before frame_lifetime) should increment elapsed_frames', function ()
      local particle1 = particle(10, vector(10, 20), vector(2, 3), vector(0, 0), 5.5, dummy_size_ratio_over_lifetime)
      particle1.elapsed_frames = 9  -- 10 - 1

      local result = particle1:update_and_check_alive()

      -- semantically false, but for character optimization reasons, we return nil
      assert.is_nil(result)
    end)

    it('(elapsed_frames not just before frame_lifetime) should call update and return true', function ()
      local particle1 = particle(10, vector(10, 20), vector(2, 3), vector(0, 0), 5.5, dummy_size_ratio_over_lifetime)
      particle1.elapsed_frames = 5

      local result = particle1:update_and_check_alive()

      assert.spy(particle.update).was_called(1)
      assert.spy(particle.update).was_called_with(match.ref(particle1))

      assert.is_true(result)
    end)

    it('(elapsed_frames is just before frame_lifetime) should not call update as we returned earlier', function ()
      local particle1 = particle(10, vector(10, 20), vector(2, 3), vector(0, 0), 5.5, dummy_size_ratio_over_lifetime)
      particle1.elapsed_frames = 9  -- 10 - 1

      particle1:update_and_check_alive()

      assert.spy(particle.update).was_not_called()
    end)

  end)

  describe('update', function ()

    it('should update position by adding frame_velocity', function ()
      local particle1 = particle(10, vector(10, 20), vector(2, 3), vector(0, 0), 5.5, dummy_size_ratio_over_lifetime)

      particle1:update()

      assert.are_same(vector(12, 23), particle1.position)
    end)

    it('should update velocity by adding frame_accel', function ()
      local particle1 = particle(10, vector(10, 20), vector(-2, 3), vector(-2, 2), 5.5, dummy_size_ratio_over_lifetime)

      particle1:update()

      assert.are_same(vector(-4, 5), particle1.frame_velocity)
    end)

    it('should update size', function ()
      local particle1 = particle(10, vector(10, 20), vector(-2, 3), vector(-2, 2), 3, dummy_size_ratio_over_lifetime)
      -- dummy_size_ratio_over_lifetime is linear from 0 to 1, so by picking half the lifetime (5/10 = 0.5)
      --  we know the particle size will be half of base size 3, so 1.5
      particle1.elapsed_frames = 5

      particle1:update()

      assert.are_equal(1.5, particle1.size)
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

    it('(size = 2..3) should call circfill at particle position, with size, white (hardcoded)', function ()
      local particle1 = particle(10, vector(12, 2), vector(-2, 3), vector(-2, 2), 5, dummy_size_ratio_over_lifetime)
      particle1.size = 2.5

      particle1:render()

      assert.spy(rectfill).was_called(1)
      assert.spy(rectfill).was_called_with(12, 2, 13, 3, colors.white)
    end)

    it('(size not in 2..3) should call circfill at particle position, with size, white (hardcoded)', function ()
      local particle1 = particle(10, vector(12, 2), vector(-2, 3), vector(-2, 2), 10, dummy_size_ratio_over_lifetime)
      particle1.size = 5

      particle1:render()

      assert.spy(circfill).was_called(1)
      assert.spy(circfill).was_called_with(12, 2, 2.5, colors.white)
    end)

  end)

end)

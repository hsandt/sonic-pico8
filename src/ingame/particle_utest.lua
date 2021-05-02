require("test/bustedhelper_ingame")
local particle = require("ingame/particle")

describe('particle', function ()

  describe('init', function ()

    it('should create an particle with frame_lifetime, initial_position, initial_velocity, initial_size', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3)
      assert.are_same({2, 0, vector(12, 2), vector(-2, 3), 3},
        {particle1.frame_lifetime, particle1.elapsed_frames, particle1.position, particle1.frame_velocity, particle1.size})
    end)

  end)

  describe('update_and_check_alive', function ()

    it('should increment elapsed_frames"', function ()
      local particle1 = particle(10, vector(12, 2), vector(-2, 3), 3)
      particle1.elapsed_frames = 5

      particle1:update_and_check_alive()

      assert.are_same(6, particle1.elapsed_frames)
    end)

    it('(elapsed_frames is just before frame_lifetime) should increment elapsed_frames"', function ()
      local particle1 = particle(10, vector(12, 2), vector(-2, 3), 3)
      particle1.elapsed_frames = 9  -- 10 - 1

      local result = particle1:update_and_check_alive()

      -- semantically false, but for character optimization reasons, we return nil
      assert.is_nil(result)
    end)

    it('(elapsed_frames not just before frame_lifetime) should update position with frame_velocity and return true"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3)

      local result = particle1:update_and_check_alive()

      assert.are_same(vector(10, 5), particle1.position)
      assert.is_true(result)
    end)

    it('(elapsed_frames is just before frame_lifetime) should not update position as we returned earlier"', function ()
      local particle1 = particle(2, vector(12, 2), vector(-2, 3), 3)
      particle1.elapsed_frames = 9  -- 10 - 1

      particle1:update_and_check_alive()

      assert.are_same(vector(12, 2), particle1.position)
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

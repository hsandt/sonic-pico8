require("engine/test/bustedhelper")
local motion = require("game/platformer/motion")
local ground_query_info = motion.ground_query_info
local ground_motion_result,   air_motion_result = get_members(motion,
     "ground_motion_result", "air_motion_result")

describe('motion', function ()

  describe('ground_query_info', function ()

    describe('_init', function ()

      it('should create a ground_query_info with signed_distance, slope_angle', function ()
        local info = ground_query_info(-2.0, 0.25)
        assert.are_same({-2.0, 0.25}, {info.signed_distance, info.slope_angle})
      end)

    end)

    describe('_tostring', function ()

      it('should return "ground_query_info({self.signed_distance}, 0.125)"', function ()
        local info = ground_query_info(-2.0, 0.25)
        assert.are_equal("ground_query_info(-2.0, 0.25)", info:_tostring())
      end)

      it('should return "ground_query_info({self.signed_distance}, [nil])"', function ()
        local info = ground_query_info(-2.0, nil)
        assert.are_equal("ground_query_info(-2.0, [nil])", info:_tostring())
      end)

    end)

  end)

  describe('ground_motion_result', function ()

    describe('_init', function ()

      it('should create a ground_motion_result with position, slope_angle, is_blocked, is_falling', function ()
        local gmr = ground_motion_result(vector(2, 3), 0.25, true, false)
        assert.are_same({vector(2, 3), 0.25, true, false}, {gmr.position, gmr.slope_angle, gmr.is_blocked, gmr.is_falling})
      end)

    end)

    describe('_tostring', function ()

      it('should return "ground_motion_result(vector(2, 3), 0.25, true, false)"', function ()
        local gmr = ground_motion_result(vector(2, 3), 0.25, true, false)
        assert.are_equal("ground_motion_result(vector(2, 3), 0.25, true, false)", gmr:_tostring())
      end)

    end)

  end)

  describe('air_motion_result', function ()

    describe('_init', function ()

      it('should create a air_motion_result with position, is_blocked_by_wall, is_blocked_by_ceiling, is_landing, slope_angle', function ()
        local gmr = air_motion_result(vector(2, 3), true, false, true, -0.25)
        assert.are_same({vector(2, 3), true, false, true, -0.25}, {gmr.position, gmr.is_blocked_by_wall, gmr.is_blocked_by_ceiling, gmr.is_landing, gmr.slope_angle})
      end)

    end)

    describe('is_blocked_along', function ()

      it('return false if direction is left and is_blocked_by_wall is false', function ()
        local gmr = air_motion_result(vector(2, 3), false, false, false)
        assert.is_false(gmr:is_blocked_along(directions.left))
      end)

      it('return true if direction is left and is_blocked_by_wall is true', function ()
        local gmr = air_motion_result(vector(2, 3), true, false, false)
        assert.is_true(gmr:is_blocked_along(directions.left))
      end)

      it('return false if direction is right and is_blocked_by_wall is false', function ()
        local gmr = air_motion_result(vector(2, 3), false, false, false)
        assert.is_false(gmr:is_blocked_along(directions.right))
      end)

      it('return true if direction is right and is_blocked_by_wall is true', function ()
        local gmr = air_motion_result(vector(2, 3), true, false, false)
        assert.is_true(gmr:is_blocked_along(directions.right))
      end)

      it('return false if direction is up and is_blocked_by_ceiling is false', function ()
        local gmr = air_motion_result(vector(2, 3), false, false, false)
        assert.is_false(gmr:is_blocked_along(directions.up))
      end)

      it('return true if direction is up and is_blocked_by_ceiling is true', function ()
        local gmr = air_motion_result(vector(2, 3), false, true, false)
        assert.is_true(gmr:is_blocked_along(directions.up))
      end)

      it('return false if direction is down and is_landing is false', function ()
        local gmr = air_motion_result(vector(2, 3), false, false, false)
        assert.is_false(gmr:is_blocked_along(directions.down))
      end)

      it('return true if direction is down and is_landing is true', function ()
        local gmr = air_motion_result(vector(2, 3), false, false, true)
        assert.is_true(gmr:is_blocked_along(directions.down))
      end)

    end)

    describe('_tostring', function ()

      it('should return "air_motion_result(vector(2, 3), true, false, true, -0.25)"', function ()
        local gmr = air_motion_result(vector(2, 3), true, false, true, -0.25)
        assert.are_equal("air_motion_result(vector(2, 3), true, false, true, -0.25)", gmr:_tostring())
      end)

    end)

  end)

end)

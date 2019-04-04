require("bustedhelper")
require("engine/application/constants")
require("engine/core/math")
local collision = require("engine/physics/collision")
local aabb = collision.aabb
local tile_data = collision.tile_data
local height_array = collision.height_array
local ground_query_info = collision.ground_query_info
local ground_motion_result,   air_motion_result = get_members(collision,
     "ground_motion_result", "air_motion_result")

-- retrieve the filter arguments so we can optimize by only generating tests we will need
local cli = require('busted.modules.cli')()
local cli_args, cli_err = cli:parse(arg)
-- we are testing "all" in module iff we are using empty filters
local is_testing_all = #cli_args["filter"] == 0 and #cli_args["filter-out"] == 0

-- create variants of an original test with 2 aabb and
-- an expected result for collides, touches and intersects, with prioritized escape direction
-- by applying various transformations, and register them all
local function describe_all_test_variants(original_bb1, original_bb2,
  original_escape_vector, original_touches_result, intersects_result, original_prioritized_escape_direction)

  -- generate 32 variants of this configuration by:
  -- - swapping boxes
  -- - applying horizontal and vertical symmetry (not both, this is already done via 180 rotation)
  -- - rotation by 0, 90, 180, 270 degrees
  -- every time, apply the corresponding transformations to the escape vector, if any
  for role_swap in all({false, true}) do
    for symmetry_x in all({false, true}) do
      for symmetry_y in all({false, true}) do
        for quadrant = 0, 3 do

          local should_describe_test = true

          -- except when testing all in module (typically in ci), ignore extra test variants for faster local unit tests
          local is_extra_test = role_swap or symmetry_y or quadrant > 1
          if is_extra_test and not is_testing_all then
            should_describe_test = false
          end

          if should_describe_test then

            local bb1 = original_bb1:copy()
            local bb2 = original_bb2:copy()

            -- copy results if not nil
            local escape_vector = original_escape_vector and original_escape_vector:copy()
            local prioritized_escape_direction = original_prioritized_escape_direction

            -- if boxes are swapped, collision works the same but escape vector is opposite
            if role_swap then
              local temp = bb1
              bb1 = bb2
              bb2 = temp

              if escape_vector then
                escape_vector:mul_inplace(-1)
              end
              if prioritized_escape_direction then
                prioritized_escape_direction = oppose_direction(prioritized_escape_direction)
              end
            end

            -- if boxes are mirrored, collision works the same but escape vector is mirrored

            if symmetry_x then
              bb1:mirror_x()
              bb2:mirror_x()

              if escape_vector then
                escape_vector:mirror_x()
              end
              if prioritized_escape_direction then
                prioritized_escape_direction = mirror_direction_x(prioritized_escape_direction)
              end
            end

            if symmetry_y then
              bb1:mirror_y()
              bb2:mirror_y()

              if escape_vector then
                escape_vector:mirror_y()
              end
              if prioritized_escape_direction then
                prioritized_escape_direction = mirror_direction_y(prioritized_escape_direction)
              end
            end

            -- if boxes are rotates, collision works the same but escape vector is rotated
            for i = 1, quadrant do
              bb1:rotate_90_cw_inplace()
              bb2:rotate_90_cw_inplace()

              if escape_vector then
                escape_vector:rotate_90_cw_inplace()
              end
              if prioritized_escape_direction then
                prioritized_escape_direction = rotate_direction_90_cw(prioritized_escape_direction)
              end
            end

            local transformation_description = '(~ role_swap: '..tostr(role_swap)..', '..
              '+ symmetry_x: '..tostr(symmetry_x)..', '..
              '+ symmetry_y: '..tostr(symmetry_y)..', '..
              '+~~ rotation: '..tostr(90 * quadrant)..')'

            local test_description = transformation_description..' (compute_escape_vector, collides, touches, . intersects) should return ('..joinstr(', ', escape_vector, original_touches_result,
                intersects_result)..')'

            -- we test all the public methods that than private helper _compute_signed_distance_and_escape_direction
            -- but we could also test _compute_signed_distance_and_escape_direction, then the public methods
            -- with simple unit test that doesn't recheck the whole thing (e.g. with api call checks or by mocking the helper result)
            it(test_description, function ()
              assert.are_same({escape_vector, escape_vector ~= nil, original_touches_result, intersects_result},
                {bb1:compute_escape_vector(bb2, prioritized_escape_direction), bb1:collides(bb2), bb1:touches(bb2), bb1:intersects(bb2)})
            end)

          end

        end
      end
    end
  end

end

describe('collision', function ()

  describe('aabb', function ()

    describe('_init', function ()

      it('should create an AABB with center and extents', function ()
        local bb = aabb(vector(-3., 4.), vector(2., 6.))
        assert.are_same({vector(-3., 4.), vector(2., 6.)}, {bb.center, bb.extents})
      end)

    end)

    describe('_tostring', function ()

      it('should return "aabb({self.center}, {self.extents})"', function ()
        local bb = aabb(vector(-3., 4.), vector(2., 6.))
        assert.are_equal("aabb(vector(-3.0, 4.0), vector(2.0, 6.0))", bb:_tostring())
      end)

    end)

    describe('rotated_90_cw', function ()
      it('aabb((-4, 6), (2, 3)) => aabb((-6, -4), (3, 2))"', function ()
        assert.are_equal(aabb(vector(-6., -4.), vector(3., 2.)), aabb(vector(-4, 6), vector(2, 3)):rotated_90_cw())
      end)
    end)

    describe('rotate_90_cw_inplace', function ()
      it('aabb((-4, 6), (2, 3)) => aabb((-6, -4), (3, 2))"', function ()
        local bb = aabb(vector(-4, 6), vector(2, 3))
        bb:rotate_90_cw_inplace()
        assert.are_equal(aabb(vector(-6., -4.), vector(3., 2.)), bb)
      end)
    end)

    describe('rotated_90_ccw', function ()
      it('aabb((-4, 6), (2, 3)) => aabb((6, 4), (3, 2))"', function ()
        assert.are_equal(aabb(vector(6., 4.), vector(3., 2.)), aabb(vector(-4, 6), vector(2, 3)):rotated_90_ccw())
      end)
    end)

    describe('rotate_90_ccw_inplace', function ()
      it('aabb((-4, 6), (2, 3)) => aabb((6, 4), (3, 2))"', function ()
        local bb = aabb(vector(-4, 6), vector(2, 3))
        bb:rotate_90_ccw_inplace()
        assert.are_equal(aabb(vector(6., 4.), vector(3., 2.)), bb)
      end)
    end)

    describe('mirror_x', function ()
      it('aabb((-4, 6), (2, 3)) => aabb((4, 6), (2, 3))"', function ()
        local bb = aabb(vector(-4, 6), vector(2, 3))
        bb:mirror_x()
        assert.are_equal(aabb(vector(4., 6.), vector(2., 3.)), bb)
      end)
    end)

    describe('mirror_y', function ()
      it('aabb((-4, 6), (2, 3)) => aabb((-4, -6), (2, 3))"', function ()
        local bb = aabb(vector(-4, 6), vector(2, 3))
        bb:mirror_y()
        assert.are_equal(aabb(vector(-4., -6.), vector(2., 3.)), bb)
      end)
    end)

    describe('collision methods', function ()

      describe('+ Case 1: Diagonal opposite', function ()

        describe_all_test_variants(
          aabb(vector(-2., -2.), vector(1., 1.)),
          aabb(vector(2., 2.), vector(1., 1.)),
          nil,
          false,
          false
        )
      end)

      describe('Case 2: 1-axis overlap', function ()

        describe_all_test_variants(
          aabb(vector(-2., 1.), vector(1., 1.)),
          aabb(vector(2., 2.), vector(1., 1.)),
          nil,
          false,
          false
        )
      end)

      describe('Case 3: Full 1-axis overlap', function ()

        describe_all_test_variants(
          aabb(vector(-2., 2.), vector(1., 1.)),
          aabb(vector(2., 2.), vector(1., 1.)),
          nil,
          false,
          false
        )
      end)

      describe('Case 4: 1-axis inside', function ()

        describe_all_test_variants(
          aabb(vector(-2., 2.), vector(1., 0.5)),
          aabb(vector(2., 2.), vector(1., 1.)),
          nil,
          false,
          false
        )
      end)

      describe('Case 5: 1-axis cover', function ()

        describe_all_test_variants(
          aabb(vector(-2., 2.), vector(1., 2.)),
          aabb(vector(2., 2.), vector(1., 1.)),
          nil,
          false,
          false
        )
      end)

      describe('Case 6: Touch corner', function ()

        describe_all_test_variants(
          aabb(vector(-1., -1.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          true
        )
      end)

      describe('Case 7: Touch partial edge', function ()

        describe_all_test_variants(
          aabb(vector(-1., 0.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          true
        )
      end)

      describe('Case 8: Touch full edge', function ()

        describe_all_test_variants(
          aabb(vector(-1., 1.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          true
        )
      end)

      describe('. Case 9: Touch inside', function ()

        describe_all_test_variants(
          aabb(vector(-1., 1.), vector(1., 0.5)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          true
        )
      end)

      describe('Case 10: Touch cover', function ()

        describe_all_test_variants(
          aabb(vector(-1., 0.), vector(1., 2.)),
          aabb(vector(1., 0.), vector(1., 1.)),
          nil,
          true,
          true
        )
      end)

      describe('+ Case 11a: Overlap corner, priority left', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-1., 0.),
          false,
          true,
          directions.left
        )
      end)

      describe('+ Case 11b: Overlap corner, priority up', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -1.),
          false,
          true,
          directions.up
        )
      end)

      describe('+ Case 12: Overlap corner clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(1., 2.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-1., 0.),
          false,
          true
        )
      end)

      describe('Case 13: Overlap full side', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-1., 0.),
          false,
          true
        )
      end)

      describe('Case 14: Overlap inside side', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(1., 0.5)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-1., 0.),
          false,
          true
        )
      end)

      describe('Case 15: Overlap cover side', function ()

        describe_all_test_variants(
          aabb(vector(0., 2.), vector(1., 2.)),
          aabb(vector(1., 2.), vector(1., 1.)),
          vector(-1., 0.),
          false,
          true
        )
      end)

      describe('. Case 16a: Cover from corner, priority left', function ()
        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-2., 0.),
          false,
          true,
          directions.left
        )
      end)

      describe('. Case 16b: Cover from corner, priority up', function ()
        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -2.),
          false,
          true,
          directions.up
        )
      end)

      describe('. Case 17a: Cover from side, priority up', function ()
        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -2.),
          false,
          true,
          directions.up
        )
      end)

      describe('. Case 17b: Cover from side, priority down', function ()
        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., 2.),
          false,
          true,
          directions.down
        )
      end)

      describe('. Case 18a: Cover from both sides, priority up', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -2.),
          false,
          true,
          directions.up
        )
      end)

      describe('. Case 18b: Cover from both sides, priority down', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., 2.),
          false,
          true,
          directions.down
        )
      end)

      describe('Case 19: Cover from 3 sides escape top', function ()

        describe_all_test_variants(
          aabb(vector(1., 0.), vector(3., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -2.),
          false,
          true
        )
      end)

      describe('. Case 20: Cover over, priority left', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-3., 0.),
          false,
          true,
          directions.left
        )
      end)

      describe('. Case 20: Cover over, priority right', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(3., 0.),
          false,
          true,
          directions.right
        )
      end)

      describe('. Case 20: Cover over, priority up', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -3.),
          false,
          true,
          directions.up
        )
      end)

      describe('. Case 20: Cover over, priority down', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., 3.),
          false,
          true,
          directions.down
        )
      end)

      describe('Case 21: Cover from corner clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(2., 3.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-2., 0.),
          false,
          true
        )
      end)

      describe('Case 22: Cover from side clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 2.), vector(2., 2.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-2., 0.),
          false,
          true
        )
      end)

      describe('Case 23: Cover from both sides  clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 2.), vector(3., 2.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-3., 0.),
          false,
          true
        )
      end)

      describe('Case 24: Cover from 3 sides escape lateral', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(3., 3.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-3., 0.),
          false,
          true
        )
      end)

      describe('Case 25: Cover over clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(3., 3.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-3., 0.),
          false,
          true
        )
      end)

      describe('. Case 26: Pierce over side', function ()

        describe_all_test_variants(
          aabb(vector(0., -0.5), vector(2., 0.5)),
          aabb(vector(0., 0.), vector(1., 1.)),
          vector(0., -1.),
          false,
          true
        )
      end)

      describe('Case 27: Pierce over side thin', function ()

        describe_all_test_variants(
          aabb(vector(-1, 2.), vector(3., 2.)),
          aabb(vector(0., 0.), vector(1., 4.)),
          vector(-3., 0.),
          false,
          true
        )
      end)

      describe('Case 28: Pierce through', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 0.5)),
          aabb(vector(0., 1.), vector(1., 2.)),
            vector(0., -1.5),
            false,
          true
        )
      end)

      describe('Case 29: Pierce through thin', function ()

        describe_all_test_variants(
          aabb(vector(-1., 0.), vector(3., 0.5)),
          aabb(vector(0., 0.), vector(1., 4.)),
          vector(-3., 0.),
          false,
          true
        )
      end)

      describe('Case 30: Pierce stop', function ()

        describe_all_test_variants(
          aabb(vector(-1., 0.), vector(2., 0.5)),
          aabb(vector(0., 0.), vector(1., 4.)),
          vector(-2., 0.),
          false,
          true
        )
      end)

      describe('. Case 31: Perfect overlap, priority up', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 1.)),
          aabb(vector(0., 0.), vector(2., 1.)),
          vector(0., -2.),
          false,
          true,
          directions.up
        )
      end)

      describe('. Case 31: Perfect overlap, priority down', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 1.)),
          aabb(vector(0., 0.), vector(2., 1.)),
          vector(0., 2.),
          false,
          true,
          directions.down
        )
      end)

      describe('Case 32: Point outside', function ()

        describe_all_test_variants(
          aabb(vector(-2., -2.), vector(0., 0.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          false,
          false
        )
      end)

      describe('Case 33: Point at corner', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(0., 0.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          true
        )
      end)

      describe('Case 34: Point on edge', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(0., 0.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          true
        )
      end)

      describe('Case 35: Point inside', function ()

        describe_all_test_variants(
          aabb(vector(1., 2.), vector(0., 0.)),
          aabb(vector(2., 2.), vector(2., 2.)),
          vector(-1., 0.),
          false,
          true
        )
      end)

    end)

  end)

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

    end)

  end)

  describe('ground_motion_result', function ()

    describe('_init', function ()

      it('should create a ground_motion_result with position, slope_angle, is_blocked, is_falling', function ()
        local gmr = ground_motion_result(vector(2, 3), 0.25, false, true)
        assert.are_same({vector(2, 3), 0.25, false, true}, {gmr.position, gmr.slope_angle, gmr.is_blocked, gmr.is_falling})
      end)

    end)

    describe('_tostring', function ()

      it('should return "ground_motion_result(vector(2, 3), 0.25, false, true)"', function ()
        local gmr = ground_motion_result(vector(2, 3), 0.25, false, true)
        assert.are_equal("ground_motion_result(vector(2, 3), 0.25, false, true)", gmr:_tostring())
      end)

    end)

  end)

  describe('air_motion_result', function ()

    describe('_init', function ()

      it('should create a air_motion_result with position, is_blocked_by_wall, is_blocked_by_ceiling, is_landing', function ()
        local gmr = air_motion_result(vector(2, 3), true, false, true)
        assert.are_same({vector(2, 3), true, false, true}, {gmr.position, gmr.is_blocked_by_wall, gmr.is_blocked_by_ceiling, gmr.is_landing})
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

      it('should return "air_motion_result(vector(2, 3), false, false, true)"', function ()
        local gmr = air_motion_result(vector(2, 3), false, false, true)
        assert.are_equal("air_motion_result(vector(2, 3), false, false, true)", gmr:_tostring())
      end)

    end)

  end)

  describe('tile_data', function ()

    describe('_init', function ()

      it('should create a tile data setting the sprite id location and the slope angle', function ()
        local td = tile_data(sprite_id_location(1, 2), 0.125)
        assert.are_same({sprite_id_location(1, 2), 0.125}, {td.id_loc, td.slope_angle})
      end)

    end)

    describe('_tostring', function ()

      it('should return "height_array({4, 5, 6, 7, 8, 9, 10, 11}, 0.125)"', function ()
        local td = tile_data(sprite_id_location(1, 2), 0.125)
        assert.are_equal("tile_data(sprite_id_location(1, 2), 0.125)", td:_tostring())
      end)

    end)

  end)

  describe('height_array', function ()

    describe("mocking _fill_array", function ()

      local fill_array_mock

      setup(function ()
        fill_array_mock = stub(height_array, "_fill_array", function (array, tile_mask_sprite_id_location)
          for i = 1, tile_size do
            array[i] = tile_mask_sprite_id_location.i + tile_mask_sprite_id_location.j + i
          end
        end)
      end)

      teardown(function ()
        fill_array_mock:revert()
      end)

      after_each(function ()
        fill_array_mock:clear()
      end)

      describe('_init', function ()

        it('should create a height array using fill_array and setting the slope angle', function ()
          local h_array = height_array(tile_data(sprite_id_location(1, 2), 0.125))
          assert.are_same({{4, 5, 6, 7, 8, 9, 10, 11}, 0.125}, {h_array._array, h_array.slope_angle})
        end)

      end)

      describe('_tostring', function ()

        it('should return "height_array({4, 5, 6, 7, 8, 9, 10, 11}, 0.125)"', function ()
          local h_array = height_array(tile_data(sprite_id_location(1, 2), 0.125))
          assert.are_equal("height_array({4, 5, 6, 7, 8, 9, 10, 11}, 0.125)", h_array:_tostring())
        end)

      end)

      describe('get_height', function ()

        it('should return the height at the given column index', function ()
          local h_array = height_array(tile_data(sprite_id_location(1, 2), 0.125))
          assert.are_equal(6, h_array:get_height(2))
        end)

      end)

    end)

    describe('_fill_array', function ()

      local sget_mock

      setup(function ()
        -- simulate an sget that would return the pixel of a tile mask
        --  if coordinates fall in the sprite at location (1, 2), i.e. [8-15] x [16-23],
        --  where mock_height_array contains the respective height of the mask columns
        --  for each column from left to right
        local mock_height_array = {2, 3, 5, 6, 0, 1, 4, 2}
        sget_mock = stub(_G, "sget", function (x, y)
          if x >= 8 and x <= 15 and y >= 16 and y <= 23 then
            -- return filled pixel color iff below mask height on this column
            local height = mock_height_array[x - 7]
            if y - 16 >= tile_size - height then
              return 1
            else
              return 0
            end
          end
        end)
      end)

      teardown(function ()
        sget_mock:revert()
      end)

      it('should fill the array with ', function ()
        local array = {}
        height_array._fill_array(array, sprite_id_location(1, 2))
        assert.are_same({2, 3, 5, 6, 0, 1, 4, 2}, array)
      end)

    end)

  end)

end)

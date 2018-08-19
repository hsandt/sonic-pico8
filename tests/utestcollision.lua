require("bustedhelper")
require("engine/core/math")
local collision = require("engine/physics/collision")
local aabb = collision.aabb

-- create variants of an original test with 2 aabb and
-- an expected result for collides, touches and intersects, with prioritized escape direction
-- by applying various transformations, and register them all
local function describe_all_test_variants(original_bb1, original_bb2,
  original_collides_result, original_touches_result, original_intersects_result, original_prioritized_escape_direction)

  -- generate 32 variants of this configuration by:
  -- - swapping boxes
  -- - applying horizontal and vertical symmetry (not both, this is already done via 180 rotation)
  -- - rotation by 0, 90, 180, 270 degrees
  -- every time, apply the corresponding transformations to the escape vector, if any
  for role_swap in all({false, true}) do
    for symmetry_x in all({false, true}) do
      for symmetry_y in all({false, true}) do
        for quadrant = 0, 3 do
          local bb1 = original_bb1:copy()
          local bb2 = original_bb2:copy()

          -- copy results if not nil
          local collides_result = original_collides_result and original_collides_result:copy()
          local intersects_result = original_intersects_result and original_intersects_result:copy()
          local prioritized_escape_direction = original_prioritized_escape_direction

          -- if boxes are swapped, collision works the same but escape vector is opposite
          if role_swap then
            local temp = bb1
            bb1 = bb2
            bb2 = temp

            if collides_result then
              collides_result:mul_inplace(-1)
            end
            if intersects_result then
              intersects_result:mul_inplace(-1)
            end
            if prioritized_escape_direction then
              prioritized_escape_direction = oppose_direction(prioritized_escape_direction)
            end
          end

          -- if boxes are mirrored, collision works the same but escape vector is mirrored

          if symmetry_x then
            bb1:mirror_x()
            bb2:mirror_x()

            if collides_result then
              collides_result:mirror_x()
            end
            if intersects_result then
              intersects_result:mirror_x()
            end
            if prioritized_escape_direction then
              prioritized_escape_direction = mirror_direction_x(prioritized_escape_direction)
            end
          end

          if symmetry_y then
            bb1:mirror_y()
            bb2:mirror_y()

            if collides_result then
              collides_result:mirror_y()
            end
            if intersects_result then
              intersects_result:mirror_y()
            end
            if prioritized_escape_direction then
              prioritized_escape_direction = mirror_direction_y(prioritized_escape_direction)
            end
          end

          -- if boxes are rotates, collision works the same but escape vector is rotated
          for i = 1, quadrant do
            bb1:rotate_90_cw_inplace()
            bb2:rotate_90_cw_inplace()

            if collides_result then
              collides_result:rotate_90_cw_inplace()
            end
            if intersects_result then
              intersects_result:rotate_90_cw_inplace()
            end
            if prioritized_escape_direction then
              prioritized_escape_direction = rotate_direction_90_cw(prioritized_escape_direction)
            end
          end

          local transformation_description = '(~ role_swap: '..tostr(role_swap)..', '..
            '+ symmetry_x: '..tostr(symmetry_x)..', '..
            '+ symmetry_y: '..tostr(symmetry_y)..', '..
            '+~~ rotation: '..tostr(90 * quadrant)..')'

          -- mute heavy tests, we will only test them on all (e.g. during ci)
          if role_swap or quadrant > 1 then
            transformation_description = '#mute '..transformation_description
          end

          local test_description = transformation_description..' (collides, touches, intersects) should return ('..joinstr(', ', collides_result, original_touches_result,
              intersects_result)..')'

          it(test_description, function ()
            assert.are_same({collides_result, original_touches_result, intersects_result},
              {bb1:collides(bb2, prioritized_escape_direction), bb1:touches(bb2), bb1:intersects(bb2, prioritized_escape_direction)})
          end)

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
          nil
        )
      end)

      describe('Case 2: 1-axis overlap', function ()

        describe_all_test_variants(
          aabb(vector(-2., 1.), vector(1., 1.)),
          aabb(vector(2., 2.), vector(1., 1.)),
          nil,
          false,
          nil
        )
      end)

      describe('Case 3: Full 1-axis overlap', function ()

        describe_all_test_variants(
          aabb(vector(-2., 2.), vector(1., 1.)),
          aabb(vector(2., 2.), vector(1., 1.)),
          nil,
          false,
          nil
        )
      end)

      describe('Case 4: 1-axis inside', function ()

        describe_all_test_variants(
          aabb(vector(-2., 2.), vector(1., 0.5)),
          aabb(vector(2., 2.), vector(1., 1.)),
          nil,
          false,
          nil
        )
      end)

      describe('Case 5: 1-axis cover', function ()

        describe_all_test_variants(
          aabb(vector(-2., 2.), vector(1., 2.)),
          aabb(vector(2., 2.), vector(1., 1.)),
          nil,
          false,
          nil
        )
      end)

      describe('Case 6: Touch corner', function ()

        describe_all_test_variants(
          aabb(vector(-1., -1.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          vector:zero()
        )
      end)

      describe('Case 7: Touch partial edge', function ()

        describe_all_test_variants(
          aabb(vector(-1., 0.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          vector:zero()
        )
      end)

      describe('Case 8: Touch full edge', function ()

        describe_all_test_variants(
          aabb(vector(-1., 1.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          vector:zero()
        )
      end)

      describe('. Case 9: Touch inside', function ()

        describe_all_test_variants(
          aabb(vector(-1., 1.), vector(1., 0.5)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          vector:zero()
        )
      end)

      describe('Case 10: Touch cover', function ()

        describe_all_test_variants(
          aabb(vector(-1., 0.), vector(1., 2.)),
          aabb(vector(1., 0.), vector(1., 1.)),
          nil,
          true,
          vector:zero()
        )
      end)

      describe('+ Case 11a: Overlap corner, priority left', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-1., 0.),
          false,
          vector(-1., 0.),
          directions.left
        )
      end)

      describe('+ Case 11b: Overlap corner, priority up', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -1.),
          false,
          vector(0., -1.),
          directions.up
        )
      end)

      describe('+ Case 12: Overlap corner clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(1., 2.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-1., 0.),
          false,
          vector(-1., 0.)
        )
      end)

      describe('Case 13: Overlap full side', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(1., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-1., 0.),
          false,
          vector(-1., 0.)
        )
      end)

      describe('Case 14: Overlap inside side', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(1., 0.5)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-1., 0.),
          false,
          vector(-1., 0.)
        )
      end)

      describe('Case 15: Overlap cover side', function ()

        describe_all_test_variants(
          aabb(vector(0., 2.), vector(1., 2.)),
          aabb(vector(1., 2.), vector(1., 1.)),
          vector(-1., 0.),
          false,
          vector(-1., 0.)
        )
      end)

      describe('. Case 16a: Cover from corner, priority left', function ()
        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-2., 0.),
          false,
          vector(-2., 0.),
          directions.left
        )
      end)

      describe('. Case 16b: Cover from corner, priority up', function ()
        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -2.),
          false,
          vector(0., -2.),
          directions.up
        )
      end)

      describe('. Case 17a: Cover from side, priority up', function ()
        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -2.),
          false,
          vector(0., -2.),
          directions.up
        )
      end)

      describe('. Case 17b: Cover from side, priority down', function ()
        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., 2.),
          false,
          vector(0., 2.),
          directions.down
        )
      end)

      describe('. Case 18a: Cover from both sides, priority up', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -2.),
          false,
          vector(0., -2.),
          directions.up
        )
      end)

      describe('. Case 18b: Cover from both sides, priority down', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 1.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., 2.),
          false,
          vector(0., 2.),
          directions.down
        )
      end)

      describe('Case 19: Cover from 3 sides escape top', function ()

        describe_all_test_variants(
          aabb(vector(1., 0.), vector(3., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -2.),
          false,
          vector(0., -2.)
        )
      end)

      describe('. Case 20: Cover over, priority left', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-3., 0.),
          false,
          vector(-3., 0.),
          directions.left
        )
      end)

      describe('. Case 20: Cover over, priority right', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(3., 0.),
          false,
          vector(3., 0.),
          directions.right
        )
      end)

      describe('. Case 20: Cover over, priority up', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., -3.),
          false,
          vector(0., -3.),
          directions.up
        )
      end)

      describe('. Case 20: Cover over, priority down', function ()

        describe_all_test_variants(
          aabb(vector(1., 1.), vector(2., 2.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(0., 3.),
          false,
          vector(0., 3.),
          directions.down
        )
      end)

      describe('Case 21: Cover from corner clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(2., 3.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-2., 0.),
          false,
          vector(-2., 0.)
        )
      end)

      describe('Case 22: Cover from side clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 2.), vector(2., 2.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-2., 0.),
          false,
          vector(-2., 0.)
        )
      end)

      describe('Case 23: Cover from both sides  clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 2.), vector(3., 2.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-3., 0.),
          false,
          vector(-3., 0.)
        )
      end)

      describe('Case 24: Cover from 3 sides escape lateral', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(3., 3.)),
          aabb(vector(1., 2.), vector(1., 2.)),
          vector(-3., 0.),
          false,
          vector(-3., 0.)
        )
      end)

      describe('Case 25: Cover over clear', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(3., 3.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          vector(-3., 0.),
          false,
          vector(-3., 0.)
        )
      end)

      describe('. Case 26: Pierce over side', function ()

        describe_all_test_variants(
          aabb(vector(0., -0.5), vector(2., 0.5)),
          aabb(vector(0., 0.), vector(1., 1.)),
          vector(0., -1.),
          false,
          vector(0., -1.)
        )
      end)

      describe('Case 27: Pierce over side thin', function ()

        describe_all_test_variants(
          aabb(vector(-1, 2.), vector(3., 2.)),
          aabb(vector(0., 0.), vector(1., 4.)),
          vector(-3., 0.),
          false,
          vector(-3., 0.)
        )
      end)

      describe('Case 28: Pierce through', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 0.5)),
          aabb(vector(0., 1.), vector(1., 2.)),
            vector(0., -1.5),
            false,
            vector(0., -1.5)
        )
      end)

      describe('Case 29: Pierce through thin', function ()

        describe_all_test_variants(
          aabb(vector(-1., 0.), vector(3., 0.5)),
          aabb(vector(0., 0.), vector(1., 4.)),
          vector(-3., 0.),
          false,
          vector(-3., 0.)
        )
      end)

      describe('Case 30: Pierce stop', function ()

        describe_all_test_variants(
          aabb(vector(-1., 0.), vector(2., 0.5)),
          aabb(vector(0., 0.), vector(1., 4.)),
          vector(-2., 0.),
          false,
          vector(-2., 0.)
        )
      end)

      describe('. Case 31: Perfect overlap, priority up', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 1.)),
          aabb(vector(0., 0.), vector(2., 1.)),
          vector(0., -2.),
          false,
          vector(0., -2.),
          directions.up
        )
      end)

      describe('. Case 31: Perfect overlap, priority down', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(2., 1.)),
          aabb(vector(0., 0.), vector(2., 1.)),
          vector(0., 2.),
          false,
          vector(0., 2.),
          directions.down
        )
      end)

      describe('Case 32: Point outside', function ()

        describe_all_test_variants(
          aabb(vector(-2., -2.), vector(0., 0.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          false,
          nil
        )
      end)

      describe('Case 33: Point at corner', function ()

        describe_all_test_variants(
          aabb(vector(0., 0.), vector(0., 0.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          vector:zero()
        )
      end)

      describe('Case 34: Point on edge', function ()

        describe_all_test_variants(
          aabb(vector(0., 1.), vector(0., 0.)),
          aabb(vector(1., 1.), vector(1., 1.)),
          nil,
          true,
          vector:zero()
        )
      end)

      describe('Case 35: Point inside', function ()

        describe_all_test_variants(
          aabb(vector(1., 2.), vector(0., 0.)),
          aabb(vector(2., 2.), vector(2., 2.)),
          vector(-1., 0.),
          false,
          vector(-1., 0.)
        )
      end)

    end)

  end)

end)

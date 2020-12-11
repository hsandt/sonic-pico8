require("test/bustedhelper_ingame")
require("resources/visual_ingame_addon")

local world = require("platformer/world")

local collision_data = require("data/collision_data")
local tile_test_data = require("test_data/tile_test_data")
local tile_repr = require("test_data/tile_representation")

describe('world (with mock tiles data setup)', function ()

  setup(function ()
    tile_test_data.setup()
  end)

  teardown(function ()
    tile_test_data.teardown()
  end)

  after_each(function ()
    pico8:clear_map()
  end)

  describe('angle_to_quadrant', function ()

    it('should return quadrant down for slope_angle: nil', function ()
      assert.are_equal(directions.down, world.angle_to_quadrant(nil))
    end)

    it('should return quadrant down for slope_angle: 1-0.125', function ()
      assert.are_equal(directions.down, world.angle_to_quadrant(1-0.125))
    end)

    it('should return quadrant down for slope_angle: 0', function ()
      assert.are_equal(directions.down, world.angle_to_quadrant(0))
    end)

    it('should return quadrant down for slope_angle: 0.124', function ()
      assert.are_equal(directions.down, world.angle_to_quadrant(0.124))
    end)

    it('should return quadrant down for slope_angle: 0.25-0.125', function ()
      assert.are_equal(directions.down, world.angle_to_quadrant(0.25-0.125))
    end)

    it('should return quadrant right for slope_angle: 0.25-0.124', function ()
      assert.are_equal(directions.right, world.angle_to_quadrant(0.25-0.124))
    end)

    it('should return quadrant right for slope_angle: 0.25+0.124', function ()
      assert.are_equal(directions.right, world.angle_to_quadrant(0.25+0.124))
    end)

    it('should return quadrant up for slope_angle: 0.5-0.125', function ()
      assert.are_equal(directions.up, world.angle_to_quadrant(0.5-0.125))
    end)

    it('should return quadrant to up for slope_angle: 0.5+0.125', function ()
      assert.are_equal(directions.up, world.angle_to_quadrant(0.5+0.125))
    end)

    it('should return quadrant to left for slope_angle: 0.75-0.124', function ()
      assert.are_equal(directions.left, world.angle_to_quadrant(0.75-0.124))
    end)

    it('should return quadrant to left for slope_angle: 0.75+0.124', function ()
      assert.are_equal(directions.left, world.angle_to_quadrant(0.75+0.124))
    end)

  end)

  describe('quadrant_to_right_angle', function ()

    -- we had already written utests before extracting world.quadrant_to_right_angle
    -- so we kept the tests checking final result instead of spy call

    it('should return 0 when quadrant is down', function ()
      assert.are_equal(0, world.quadrant_to_right_angle(directions.down))
    end)

    it('should return 0.25 when quadrant is right', function ()
      assert.are_equal(0.25, world.quadrant_to_right_angle(directions.right))
    end)

    it('should return 0.5 when quadrant is up', function ()
      assert.are_equal(0.5, world.quadrant_to_right_angle(directions.up))
    end)

    it('should return 0.75 when quadrant is left', function ()
      assert.are_equal(0.75, world.quadrant_to_right_angle(directions.left))
    end)

  end)


  describe('get_quadrant_x_coord', function ()

    it('should return pos.x when quadrant is down', function ()

      assert.are_equal(10, world.get_quadrant_x_coord(vector(10, 20), directions.down))
    end)

    it('should return pos.x when quadrant is up', function ()

      assert.are_equal(10, world.get_quadrant_x_coord(vector(10, 20), directions.up))
    end)

    it('should return pos.y when quadrant is right', function ()

      assert.are_equal(20, world.get_quadrant_x_coord(vector(10, 20), directions.right))
    end)

    it('should return pos.y when quadrant is left', function ()

      assert.are_equal(20, world.get_quadrant_x_coord(vector(10, 20), directions.left))
    end)

  end)

  describe('get_quadrant_y_coord', function ()

    it('should return pos.y when quadrant is down', function ()
      assert.are_equal(20, world.get_quadrant_y_coord(vector(10, 20), directions.down))
    end)

    it('should return pos.y when quadrant is up', function ()
      assert.are_equal(20, world.get_quadrant_y_coord(vector(10, 20), directions.up))
    end)

    it('should return pos.y when quadrant is right', function ()
      assert.are_equal(10, world.get_quadrant_y_coord(vector(10, 20), directions.right))
    end)

    it('should return pos.y when quadrant is left', function ()
      assert.are_equal(10, world.get_quadrant_y_coord(vector(10, 20), directions.left))
    end)

  end)

  describe('get_quadrant_j_coord', function ()

    it('should return loc.j when quadrant is down', function ()
      assert.are_equal(2, world.get_quadrant_j_coord(location(1, 2), directions.down))
    end)

    it('should return loc.j when quadrant is up', function ()
      assert.are_equal(2, world.get_quadrant_j_coord(location(1, 2), directions.up))
    end)

    it('should return loc.j when quadrant is right', function ()
      assert.are_equal(1, world.get_quadrant_j_coord(location(1, 2), directions.right))
    end)

    it('should return loc.j when quadrant is left', function ()
      assert.are_equal(1, world.get_quadrant_j_coord(location(1, 2), directions.left))
    end)

  end)

  describe('set_position_quadrant_x', function ()

    it('should set pos.x when quadrant is down', function ()
      local p = vector(10, 20)
      world.set_position_quadrant_x(p, 30, directions.down)
      assert.are_same(vector(30, 20), p)
    end)

    it('should set pos.x when quadrant is up', function ()
      local p = vector(10, 20)
      world.set_position_quadrant_x(p, 30, directions.up)
      assert.are_same(vector(30, 20), p)
    end)

    it('should set pos.y when quadrant is right', function ()
      local p = vector(10, 20)
      world.set_position_quadrant_x(p, 30, directions.right)
      assert.are_same(vector(10, 30), p)
    end)

    it('should set pos.y when quadrant is left', function ()
      local p = vector(10, 20)
      world.set_position_quadrant_x(p, 30, directions.left)
      assert.are_same(vector(10, 30), p)
    end)

  end)

  describe('sub_qy', function ()

    it('should return qy1 - qy2 when quadrant is down', function ()
      assert.are_equal(7, world.sub_qy(10, 3, directions.down))
    end)

    it('should return qy2 - qy1 when quadrant is up', function ()
      assert.are_equal(7, world.sub_qy(3, 10, directions.up))
    end)

    it('should return qy1 - qy2 when quadrant is right', function ()
      assert.are_equal(7, world.sub_qy(10, 3, directions.right))
    end)

    it('should return qy2 - qy1 when quadrant is left', function ()
      assert.are_equal(7, world.sub_qy(3, 10, directions.left))
    end)

  end)

  describe('get_tile_qbottom', function ()

    it('should return tile world bottom when quadrant is down', function ()
      assert.are_equal(24, world.get_tile_qbottom(location(1, 2), directions.down))
    end)

    it('should return tile world top when quadrant is up', function ()
      assert.are_equal(16, world.get_tile_qbottom(location(1, 2), directions.up))
    end)

    it('should return world right when quadrant is right', function ()
      assert.are_equal(16, world.get_tile_qbottom(location(1, 2), directions.right))
    end)

    it('should return world left when quadrant is left', function ()
      assert.are_equal(8, world.get_tile_qbottom(location(1, 2), directions.left))
    end)

  end)

  describe('_compute_qcolumn_height_at', function ()

    it('should return (0, nil) if tile location is outside map area except on the left (any quadrant)', function ()
      assert.are_same({0, nil}, {world.compute_qcolumn_height_at(location(128, 2), 0, directions.down)})
    end)

    it('should return (0, nil) if tile has collision flag unset (any quadrant)', function ()
      assert.are_same({0, nil}, {world.compute_qcolumn_height_at(location(1, 1), 0, directions.right)})
    end)

    describe('with invalid tile', function ()

      setup(function ()
        -- hopefully something big enough so it falls on character spritesheet and we can
        --  set and clear collision without modifying legit data
        fset(128, sprite_flags.collision, true)
      end)

      teardown(function ()
        fset(128, sprite_flags.collision, false)
      end)

      before_each(function ()
        -- create an invalid tile with a collision flag but no collision mask associated
        mock_mset(1, 1, 128)
      end)

      it('should assert if tile has collision flag set but no collision mask id associated (any quadrant)', function ()
        assert.has_error(function ()
          world.compute_qcolumn_height_at(location(1, 1), 0, directions.up)
        end,
        "collision_data.tiles_collision_data does not contain entry for sprite id: 128, yet it has the collision flag set")
      end)

    end)

    -- this unrealistic tile is useful to check all-or-nothing in both horizontal and vertical dirs
    -- more realistically, you could have an ascending slope that only occupies the bottom-right corner of the tile
    describe('with tile_repr.bottom_right_quarter_tile_id offset by 2', function ()

      before_each(function ()
        -- create an ascending slope 22.5 at (1, 1), i.e. (8, 14) to (15, 11) px
        mock_mset(1, 1, tile_repr.bottom_right_quarter_tile_id)
      end)

      it('should return 0 on column 3 (quadrant down)', function ()
        assert.are_same({0, 0}, {world.compute_qcolumn_height_at(location(1, 1), 3, directions.down)})
      end)

      it('should return 4 on column 4 (quadrant down)', function ()
        assert.are_same({4, 0}, {world.compute_qcolumn_height_at(location(1, 1), 4, directions.down)})
      end)

      it('should return 0 (reverse: nothing) on column 3 (quadrant up)', function ()
        assert.are_same({0, 0.5}, {world.compute_qcolumn_height_at(location(1, 1), 3, directions.up)})
      end)

      it('should return 8 (reverse: all) on column 4 (quadrant up)', function ()
        assert.are_same({8, 0.5}, {world.compute_qcolumn_height_at(location(1, 1), 4, directions.up)})
      end)

      it('should return 0 (ignore reverse) on column 3 (quadrant up)', function ()
        assert.are_same({0, nil}, {world.compute_qcolumn_height_at(location(1, 1), 3, directions.up, true)})
      end)

      it('should return 0 (ignore reverse) on column 4 (quadrant up)', function ()
        assert.are_same({0, nil}, {world.compute_qcolumn_height_at(location(1, 1), 4, directions.up, true)})
      end)

      it('should return 0 on row 3 (quadrant right)', function ()
        assert.are_same({0, 0}, {world.compute_qcolumn_height_at(location(1, 1), 3, directions.right)})
      end)

      it('should return 4 on row 3 (quadrant right)', function ()
        assert.are_same({4, 0}, {world.compute_qcolumn_height_at(location(1, 1), 4, directions.right)})
      end)

      it('should return 0 (reverse: nothing) on row 3 (quadrant left)', function ()
        assert.are_same({0, 0.75}, {world.compute_qcolumn_height_at(location(1, 1), 3, directions.left)})
      end)

      it('should return 8 (reverse: all) on row 4 (quadrant left)', function ()
        assert.are_same({8, 0.75}, {world.compute_qcolumn_height_at(location(1, 1), 4, directions.left)})
      end)

      it('should return 0 (ignore reverse) on row 3 (quadrant left)', function ()
        assert.are_same({0, nil}, {world.compute_qcolumn_height_at(location(1, 1), 3, directions.left, true)})
      end)

      it('should return 0 (ignore reverse) on row 4 (quadrant left)', function ()
        assert.are_same({0, nil}, {world.compute_qcolumn_height_at(location(1, 1), 4, directions.left, true)})
      end)

    end)

    describe('with loop top-left tile', function ()

      before_each(function ()
        mock_mset(1, 1, tile_repr.visual_loop_topleft)
      end)

      it('should return 8 on column 6 (quadrant down)', function ()
        assert.are_same({8, 0}, {world.compute_qcolumn_height_at(location(1, 1), 6, directions.down)})
      end)

      it('should return 4 on column 6 (quadrant up)', function ()
        assert.are_same({4, atan2(-8, 5)}, {world.compute_qcolumn_height_at(location(1, 1), 6, directions.up)})
      end)

      it('should return 8 on row 6 (quadrant right)', function ()
        assert.are_same({8, 0.25}, {world.compute_qcolumn_height_at(location(1, 1), 6, directions.right)})
      end)

      it('should return 2 on row 6 (quadrant left)', function ()
        assert.are_same({2, atan2(-8, 5)}, {world.compute_qcolumn_height_at(location(1, 1), 6, directions.left)})
      end)

    end)

    describe('with half-tile', function ()

      before_each(function ()
        mock_mset(1, 1, tile_repr.half_tile_id)
      end)

      -- half-tile allows us to test is_rectangle case
      -- in principle we should also have a vertically-split half-tile
      --  because we are only testing the quadrant left/right + is_rectangle case
      --  and not up/down... but that would only be a hypothetical tile, we don't have such a thing
      --  right now in the game
      it('should return 4 (rectangle) on column 6 (quadrant down)', function ()
        assert.are_same({4, 0}, {world.compute_qcolumn_height_at(location(1, 1), 6, directions.down)})
      end)

      it('should return 8 (reverse all) on column 6 (quadrant up)', function ()
        assert.are_same({8, 0.5}, {world.compute_qcolumn_height_at(location(1, 1), 6, directions.up)})
      end)

      it('should return 0 (ignore reverse) on column 6 (quadrant up)', function ()
        assert.are_same({0, nil}, {world.compute_qcolumn_height_at(location(1, 1), 6, directions.up, true)})
      end)

      it('should return 0 (rectangle) on row 3 (quadrant right)', function ()
        assert.are_same({0, 0.25}, {world.compute_qcolumn_height_at(location(1, 1), 3, directions.right)})
      end)

      it('should return 0 (rectangle) on row 4 (quadrant right)', function ()
        assert.are_same({8, 0.25}, {world.compute_qcolumn_height_at(location(1, 1), 4, directions.right)})
      end)

      it('should return 0 (rectangle) on row 3 (quadrant left)', function ()
        assert.are_same({0, 0.75}, {world.compute_qcolumn_height_at(location(1, 1), 3, directions.left)})
      end)

      it('should return 8 (rectangle) on row 4 (quadrant left)', function ()
        assert.are_same({8, 0.75}, {world.compute_qcolumn_height_at(location(1, 1), 4, directions.left)})
      end)

    end)

  end)

end)

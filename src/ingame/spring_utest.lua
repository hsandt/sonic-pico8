require("test/bustedhelper_ingame")

local spring = require("ingame/spring")

local sprite_data = require("engine/render/sprite_data")

local stage_common_data = require("data/stage_common_data")
local visual = require("resources/visual_common")

describe('spring', function ()

  describe('init', function ()

    it('should create a spring with a direction and global location', function ()
      local spring_obj = spring(directions.up, location(2, 1))
      assert.are_same({directions.up, location(2, 1), 0},
        {spring_obj.direction, spring_obj.global_loc, spring_obj.extended_timer})
    end)

  end)

  describe('_tostring', function ()

    it('spring(directions.up, location(2, 1)) => "spring(directions.up, location(2, 1))"', function ()
      local spring_obj = spring(directions.up, location(2, 1))
      assert.are_equal("spring(1, location(2, 1))", spring_obj:_tostring())
    end)

  end)

  describe('extend', function ()

    it('should reset extended_timer to spring extend duration"', function ()
      local spring_obj = spring(directions.up, location(2, 1))
      spring_obj:extend()
      assert.are_equal(stage_common_data.spring_extend_duration, spring_obj.extended_timer)
    end)

  end)

  describe('update', function ()

    it('should countdown extended timer', function ()
      local spring_obj = spring(directions.up, location(2, 1))
      spring_obj.extended_timer = 2 * delta_time60

      spring_obj:update()

      assert.are_equal(delta_time60, spring_obj.extended_timer)
    end)

    it('should countdown extended timer and clamp it to 0', function ()
      local spring_obj = spring(directions.up, location(2, 1))
      spring_obj.extended_timer = delta_time60 / 2

      spring_obj:update()

      assert.are_equal(0, spring_obj.extended_timer)
    end)

  end)

  describe('get_adjusted_pivot', function ()

    it('should return standard pivot for spring up', function ()
      local spring_obj = spring(directions.up, location(2, 1))
      assert.are_same(vector(26, 10), spring_obj:get_adjusted_pivot())
    end)

    it('should return topleft + (2, 2) for spring left', function ()
      local spring_obj = spring(directions.left, location(2, 1))
      assert.are_same(vector(16 + 2, 8 + 2), spring_obj:get_adjusted_pivot())
    end)

    it('should return topleft + (6, 2) for spring left', function ()
      local spring_obj = spring(directions.right, location(2, 1))
      assert.are_same(vector(16 + 6, 8 + 2), spring_obj:get_adjusted_pivot())
    end)

  end)

  describe('get_render_bounding_corners', function ()

    it('should return standard pivot for spring (direction doesn\'t matter)', function ()
      local spring_obj = spring(directions.up, location(2, 1))
      assert.are_same({vector(16, 0), vector(32, 16)}, {spring_obj:get_render_bounding_corners()})
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(sprite_data, "render")
    end)

    teardown(function ()
      sprite_data.render:revert()
    end)

    after_each(function ()
      sprite_data.render:clear()
    end)

    -- tests below have been written before defining get_adjusted_pivot instead of get_pivot
    --  and rely on get_adjusted_pivot being correct

    it('(up, extended_timer == 0) should draw spring normal sprite data from top-left location', function ()
      local spring_obj = spring(directions.up, location(2, 1))

      spring_obj:render()

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.spring), vector(26, 10), false, false, 0)
    end)

    it('(up, extended_timer > 0) should draw spring extended sprite data from top-left location', function ()
      local spring_obj = spring(directions.up, location(2, 1))
      spring_obj.extended_timer = 1

      spring_obj:render()

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.spring_extended), vector(26, 10), false, false, 0)
    end)

    it('(left, extended_timer == 0) should draw spring normal sprite data from top-left location, rotated to left with offset adjustment', function ()
      local spring_obj = spring(directions.left, location(2, 1))

      spring_obj:render()

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.spring), vector(18, 10), false, false, 0.25)
    end)

    it('(left, extended_timer > 0) should draw spring extended sprite data from top-left location, rotated to left with offset adjustment', function ()
      local spring_obj = spring(directions.left, location(2, 1))
      spring_obj.extended_timer = 1

      spring_obj:render()

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.spring_extended), vector(18, 10), false, false, 0.25)
    end)

    it('(right, extended_timer == 0) should draw spring normal sprite data from top-left location, flipped y and rotated by 90 with offset adjustment', function ()
      local spring_obj = spring(directions.right, location(2, 1))

      spring_obj:render()

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.spring), vector(22, 10), false, true, 0.25)
    end)

    it('(right, extended_timer > 0) should draw spring extended sprite data from top-left location, flipped y and rotated by 90 with offset adjustment', function ()
      local spring_obj = spring(directions.right, location(2, 1))
      spring_obj.extended_timer = 1

      spring_obj:render()

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.spring_extended), vector(22, 10), false, true, 0.25)
    end)

  end)

end)

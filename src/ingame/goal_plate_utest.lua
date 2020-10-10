require("test/bustedhelper")
local goal_plate = require("ingame/goal_plate")

local sprite_data = require("engine/render/sprite_data")

local visual = require("resources/visual")

describe('goal_plate', function ()

  describe('init', function ()

    it('should create an goal_plate with a location', function ()
      local goal = goal_plate(location(2, 33))
      assert.are_same({location(2, 33)}, {goal.global_loc})
    end)

  end)

  describe('_tostring', function ()

    it('goal_plate(location(2, 33)) => "goal_plate(location(2, 33))"', function ()
      local goal = goal_plate(location(2, 33))
      assert.are_equal("goal_plate(location(2, 33))", goal:_tostring())
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(sprite_data, "render")
    end)

    teardown(function ()
      sprite_data.render:revert()
    end)

    after_each(function ()
      sprite_data.render:clear()
    end)

    it('should draw goal_plate sprite data at tile center', function ()
      local goal = goal_plate(location(2, 33))

      goal:render()

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.goal_plate_goal), vector(2 * 8 + 4, 33 * 8))
    end)

  end)

end)

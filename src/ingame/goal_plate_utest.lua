require("test/bustedhelper")
local goal_plate = require("ingame/goal_plate")

local animated_sprite = require("engine/render/animated_sprite")

local visual = require("resources/visual_common")  -- just to use ingame add-on
require("resources/visual_ingame_addon")

describe('goal_plate', function ()

  describe('init', function ()

    setup(function ()
      spy.on(animated_sprite, "play")
    end)

    teardown(function ()
      animated_sprite.play:revert()
    end)

    it('should create an goal_plate with a location, a sprite anim, and play "goal" anim', function ()
      local goal = goal_plate(location(2, 33))
      assert.are_same({location(2, 33)}, {goal.global_loc})

      assert.spy(animated_sprite.play).was_called(1)
      assert.spy(animated_sprite.play).was_called_with(match.ref(goal.anim_spr), "goal")
    end)

  end)

  describe('_tostring', function ()

    it('goal_plate(location(2, 33)) => "goal_plate(location(2, 33))"', function ()
      local goal = goal_plate(location(2, 33))
      assert.are_equal("goal_plate(location(2, 33))", goal:_tostring())
    end)

  end)

  describe('update', function ()

    setup(function ()
      stub(animated_sprite, "update")
    end)

    teardown(function ()
      animated_sprite.update:revert()
    end)

    after_each(function ()
      animated_sprite.update:clear()
    end)

    it('should draw goal_plate sprite data at tile center', function ()
      local goal = goal_plate(location(2, 33))

      goal:update()

      assert.spy(animated_sprite.update).was_called(1)
      assert.spy(animated_sprite.update).was_called_with(match.ref(goal.anim_spr))
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(animated_sprite, "render")
    end)

    teardown(function ()
      animated_sprite.render:revert()
    end)

    after_each(function ()
      animated_sprite.render:clear()
    end)

    it('should draw goal_plate sprite data at tile center', function ()
      local goal = goal_plate(location(2, 33))

      goal:render()

      assert.spy(animated_sprite.render).was_called(1)
      assert.spy(animated_sprite.render).was_called_with(match.ref(goal.anim_spr), vector(2 * 8 + 4, 33 * 8))
    end)

  end)

end)

-- this emerald is drawn in ingame, so just use bustedhelper for ingame
require("test/bustedhelper_ingame")

local emerald = require("ingame/emerald")
local emerald_common = require("render/emerald_common")

local sprite_data = require("engine/render/sprite_data")

local visual = require("resources/visual_common")

describe('emerald', function ()

  describe('init', function ()

    it('should create an emerald with a number and global location', function ()
      local em = emerald(7, location(2, 1))
      assert.are_same({7, location(2, 1)}, {em.number, em.location})
    end)

  end)

  describe('_tostring', function ()

    it('emerald(7, location(2, 1)) => "emerald(7, location(2, 1))"', function ()
      local em = emerald(7, location(2, 1))
      assert.are_equal("emerald(7, location(2, 1))", em:_tostring())
    end)

  end)

  describe('get_center', function ()

    it('emerald(1~7, location(2, 1)) => vector(20, 12)', function ()
      local em = emerald(7, location(2, 1))
      assert.are_same(vector(20, 12), em:get_center())
    end)

    it('emerald(8, location(2, 1)) => vector(25, 12)', function ()
      local em = emerald(8, location(2, 1))
      assert.are_same(vector(25, 12), em:get_center())
    end)

  end)

  describe('get_render_bounding_corners', function ()

    it('should return standard pivot for spring (direction doesn\'t matter)', function ()
      local em = emerald(7, location(2, 1))
      assert.are_same({vector(16, 8), vector(24, 16)}, {em:get_render_bounding_corners()})
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(emerald_common, "draw")
    end)

    teardown(function ()
      emerald_common.draw:revert()
    end)

    after_each(function ()
      emerald_common.draw:clear()
    end)

    it('should delegate to emerald_common.draw with emerald number and center position', function ()
      local em = emerald(7, location(2, 1))

      em:render()

      assert.spy(emerald_common.draw).was_called(1)
      assert.spy(emerald_common.draw).was_called_with(7, vector(20, 12))
    end)

  end)

end)

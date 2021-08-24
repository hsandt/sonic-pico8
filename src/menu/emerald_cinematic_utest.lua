-- emerald is drawn in both ingame and titlemenu,
--  so exceptionally both bustedhelper work, as long as one of the two
--  visual add-ons are loaded
require("test/bustedhelper_ingame")

local emerald_cinematic = require("menu/emerald_cinematic")
local emerald_common = require("render/emerald_common")

local sprite_data = require("engine/render/sprite_data")

local visual = require("resources/visual_common")

describe('emerald', function ()

  describe('init', function ()

    it('should create an emerald with a number and position on screen', function ()
      local em = emerald_cinematic(7, vector(20, 10))
      assert.are_same({7, vector(20, 10)}, {em.number, em.position})
    end)

  end)

  describe('_tostring', function ()

    it('emerald(7, vector(2, 1)) => "emerald(7, vector(20, 10))"', function ()
      local em = emerald_cinematic(7, vector(20, 10))
      assert.are_equal("emerald(7, vector(20, 10))", em:_tostring())
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(emerald_common, "draw")
    end)

    teardown(function ()
      emerald_common.draw:revert()
    end)

    after_each(function ()
      emerald_common.draw:clear()
    end)

    it('should delegate to emerald_common.draw with emerald number and position', function ()
      local em = emerald_cinematic(7, vector(20, 10))

      em:draw()

      assert.spy(emerald_common.draw).was_called(1)
      assert.spy(emerald_common.draw).was_called_with(7, vector(20, 10))
    end)

  end)

end)

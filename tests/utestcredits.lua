require("bustedhelper")
require("game/application/gamestates")
credits = require("game/menu/credits")

describe('credits.state', function ()

  describe('type', function ()
    it('should be gamestate_types.credits', function ()
      assert.are_equal(gamestate_types.credits, credits.state.type)
    end)
  end)

  describe('state._tostring', function ()
    it('should return [credits state]', function ()
      assert.are_equal("[credits state]", credits.state._tostring())
    end)
  end)

  describe('on_enter', function ()
  end)

  describe('on_exit', function ()
  end)

  describe('update', function ()
  end)

  describe('render', function ()

    local api_print_stub

    setup(function ()
      api_print_stub = stub(api, "print")
    end)

    teardown(function ()
      api_print_stub:revert()
    end)

    after_each(function ()
      api_print_stub:clear()
    end)

    it('should print "credits state" in white', function ()
      credits.state:render()
      assert.are_equal(colors.white, pico8.color)
      assert.spy(api_print_stub).was_called(1)
      assert.spy(api_print_stub).was_called_with("credits state", 4*11, 6*12)
    end)

  end)

end)

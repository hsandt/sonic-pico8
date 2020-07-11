require("engine/test/bustedhelper")

local picosonic_app = require("application/picosonic_app")
local credits = require("menu/credits")

describe('credits', function ()

  describe('static members', function ()

    it('type is :stage', function ()
      assert.are_equal(':credits', credits.type)
    end)

  end)

  describe('(with instance)', function ()

    local state

    before_each(function ()
      local app = picosonic_app()
      state = credits()
        -- no need to register gamestate properly, just add app member to pass tests
      state.app = app
    end)

    it('type is ":stage"', function ()
      assert.are_equal(':credits', credits.type)
    end)

    -- describe('on_enter', function ()
    -- end)

    -- describe('on_exit', function ()
    -- end)

    -- describe('update', function ()
    -- end)

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
        credits:render()
        assert.are_equal(colors.white, pico8.color)
        assert.spy(api_print_stub).was_called(1)
        assert.spy(api_print_stub).was_called_with("credits state", 4*11, 6*12)
      end)

    end)

  end)  -- (with instance)

end)

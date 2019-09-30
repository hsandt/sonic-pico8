require("engine/test/bustedhelper")
local dummy_gamestate = require("application/dummy_gamestate")

describe('dummy_gamestate', function ()

  describe('_init', function ()
    it('should create a dummy gamestate with passed type', function ()
      local dgs = dummy_gamestate("credits")
      assert.is_not_nil(dgs)
      assert.are_equal("credits", dgs.type)
    end)
  end)

  describe('on_enter', function ()

    it('should do nothing', function ()

      assert.has_no_errors(function ()
        local dgs = dummy_gamestate("credits")
        dgs:on_enter()
      end)

    end)

  end)

  describe('on_exit', function ()
    it('should do nothing', function ()
      assert.has_no_errors(function ()
        local dgs = dummy_gamestate("credits")
        dgs:on_exit()
      end)
    end)
  end)

  describe('update', function ()
    it('should do nothing', function ()
      assert.has_no_errors(function ()
        local dgs = dummy_gamestate("credits")
        dgs:update()
      end)
    end)
  end)

  describe('render', function ()

    local api_print_stub

    setup(function ()
      api_print_stub = stub(api, "print")
    end)

    teardown(function ()
      api_print_stub:revert()
    end)

    it('should print the gamestate name', function ()
      local dgs = dummy_gamestate("credits")
      dgs:render()
      assert.spy(api_print_stub).was_called(1)
      assert.spy(api_print_stub).was_called_with("credits state", match.is_number(), match.is_number())
    end)

  end)

end)

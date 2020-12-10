require("test/bustedhelper_ingame")
local picosonic_app_ingame = require("application/picosonic_app_ingame")

local stage_state = require("ingame/stage_state")

describe('picosonic_app_ingame', function ()

  local app

  before_each(function ()
    app = picosonic_app_ingame()
  end)

  describe('instantiate_gamestates', function ()

    it('should return all gamestates', function ()
      assert.are_same({stage_state()}, picosonic_app_ingame:instantiate_gamestates())
    end)

  end)

  describe('on_post_start', function ()

    setup(function ()
      stub(_G, "menuitem")
    end)

    teardown(function ()
      menuitem:revert()
    end)

    it('should load cartridge: picosonic_titlemenu.p8', function ()
      app:on_post_start()
      assert.spy(menuitem).was_called(1)
      -- no reference to lambda passed to menuitem, so don't test was_called_with
    end)

  end)

end)

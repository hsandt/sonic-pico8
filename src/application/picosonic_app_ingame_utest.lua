require("test/bustedhelper_ingame")
local picosonic_app_ingame = require("application/picosonic_app_ingame")

local picosonic_app_base = require("application/picosonic_app_base")
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
      stub(picosonic_app_base, "on_post_start")
      stub(_G, "menuitem")
    end)

    teardown(function ()
      picosonic_app_base.on_post_start:revert()
      menuitem:revert()
    end)

    after_each(function ()
      picosonic_app_base.on_post_start:clear()
      menuitem:clear()
    end)

    it('should call base implementation', function ()
      app:on_post_start()
      assert.spy(picosonic_app_base.on_post_start).was_called(1)
      assert.spy(picosonic_app_base.on_post_start).was_called_with(match.ref(app))
    end)

    it('should initialize late_jump_max_delay to default', function ()
      app:on_post_start()
      assert.is_true(app.get_enable_late_jump_feature())
    end)

    it('should create 4 menu items', function ()
      app:on_post_start()
      assert.spy(menuitem).was_called(4)
      -- no reference to lambda passed to menuitem, so don't test was_called_with
    end)

  end)

end)

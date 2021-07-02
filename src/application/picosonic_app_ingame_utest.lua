require("test/bustedhelper_ingame")
local picosonic_app_ingame = require("application/picosonic_app_ingame")

local picosonic_app_base = require("application/picosonic_app_base")
local pc_data = require("data/playercharacter_data")
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
      stub(picosonic_app_ingame, "create_late_jump_delay_menuitem")
      stub(_G, "menuitem")
    end)

    teardown(function ()
      picosonic_app_base.on_post_start:revert()
      picosonic_app_ingame.create_late_jump_delay_menuitem:revert()
      menuitem:revert()
    end)

    after_each(function ()
      picosonic_app_base.on_post_start:clear()
      picosonic_app_ingame.create_late_jump_delay_menuitem:clear()
      menuitem:clear()
    end)

    it('should call base implementation', function ()
      app:on_post_start()
      assert.spy(picosonic_app_base.on_post_start).was_called(1)
      assert.spy(picosonic_app_base.on_post_start).was_called_with(match.ref(app))
    end)

    it('should initialize late_jump_max_delay to default', function ()
      app:on_post_start()
      assert.are_equal(pc_data.max_late_jump_max_delay, app.get_late_jump_max_delay())
    end)

    it('should call create_late_jump_delay_menuitem', function ()
      app:on_post_start()
      assert.spy(picosonic_app_ingame.create_late_jump_delay_menuitem).was_called(1)
      assert.spy(picosonic_app_ingame.create_late_jump_delay_menuitem).was_called_with(match.ref(app))
    end)

    it('should create 3 menu items', function ()
      app:on_post_start()
      -- note that we create 4, but create_late_jump_delay_menuitem is stubbed so we don't catch that 4th call
      assert.spy(menuitem).was_called(3)
      -- no reference to lambda passed to menuitem, so don't test was_called_with
    end)

  end)

end)

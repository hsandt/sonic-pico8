require("test/bustedhelper_titlemenu")
local picosonic_app_titlemenu = require("application/picosonic_app_titlemenu")

local picosonic_app_base = require("application/picosonic_app_base")
local titlemenu = require("menu/titlemenu")
local credits = require("menu/credits")
local memory = require("resources/memory")

describe('picosonic_app_titlemenu', function ()

  local app

  before_each(function ()
    app = picosonic_app_titlemenu()
  end)

  describe('instantiate_gamestates', function ()

    it('should return all gamestates', function ()
      assert.are_same({titlemenu(), credits()}, picosonic_app_titlemenu:instantiate_gamestates())
    end)

  end)

  describe('on_pre_start', function ()

    setup(function ()
      stub(picosonic_app_base, "on_pre_start")
      stub(_G, "dset")
    end)

    teardown(function ()
      picosonic_app_base.on_pre_start:revert()
      dset:revert()
    end)

    after_each(function ()
      picosonic_app_base.on_pre_start:clear()
      dset:clear()
    end)

    it('should call base implementation', function ()
      app:on_pre_start()
      assert.spy(picosonic_app_base.on_pre_start).was_called(1)
      assert.spy(picosonic_app_base.on_pre_start).was_called_with(match.ref(app))
    end)

    it('should clear picked emerald data in persistent memory', function ()
      app:on_pre_start()
      assert.spy(dset).was_called(1)
      assert.spy(dset).was_called_with(memory.persistent_picked_emerald_index, 0)
    end)

  end)

end)

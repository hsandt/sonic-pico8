require("engine/test/bustedhelper")  -- no specific cartridge, so just use the engine version
local picosonic_app_base = require("application/picosonic_app_base")

local flow = require("engine/application/flow")
local codetuner = require("engine/debug/codetuner")
local profiler = require("engine/debug/profiler")
local vlogger = require("engine/debug/visual_logger")
local input = require("engine/input/input")
local mouse = require("engine/ui/mouse")
local visual = require("resources/visual_common")

describe('picosonic_app_base', function ()

  local app

  before_each(function ()
    app = picosonic_app_base()
  end)

  describe('on_pre_start', function ()

    setup(function ()
      stub(_G, "extcmd")
      stub(_G, "cartdata")
      stub(input, "toggle_mouse")
      stub(mouse, "set_cursor_sprite_data")
    end)

    teardown(function ()
      extcmd:revert()
      cartdata:revert()
      input.toggle_mouse:revert()
      mouse.set_cursor_sprite_data:revert()
    end)

    after_each(function ()
      clear_table(pico8.poked_addresses)

      extcmd:clear()
      cartdata:clear()
      input.toggle_mouse:clear()
      mouse.set_cursor_sprite_data:clear()
    end)

    it('should set title to "Pico Sonic" using extcmd', function ()
      app:on_pre_start()
      assert.spy(extcmd).was_called(1)
      assert.spy(extcmd).was_called_with("set_title", "Pico Sonic")
    end)

    it('should cartdata name to "komehara_picosonic"', function ()
      app:on_pre_start()
      assert.spy(cartdata).was_called(1)
      assert.spy(cartdata).was_called_with("komehara_picosonic")
    end)

    it('should disable input auto-repeat by poking 0x5f5c = 255 (-1)', function ()
      app:on_pre_start()
      assert.are_equal(-1, pico8.poked_addresses[0x5f5c])
    end)

    it('should toggle mouse cursor', function ()
      app:on_pre_start()
      assert.spy(input.toggle_mouse).was_called(1)
      assert.spy(input.toggle_mouse).was_called_with(match.ref(input), true)
    end)

    it('should set the mouse cursor sprite data', function ()
      app:on_pre_start()
      assert.spy(mouse.set_cursor_sprite_data).was_called(1)
      assert.spy(mouse.set_cursor_sprite_data).was_called_with(match.ref(mouse), match.ref(visual.sprite_data_t.cursor))
    end)

  end)

  describe('on_reset', function ()

    setup(function ()
      stub(mouse, "set_cursor_sprite_data")
    end)

    teardown(function ()
      mouse.set_cursor_sprite_data:revert()
    end)

    after_each(function ()
      mouse.set_cursor_sprite_data:clear()
    end)

    it('should reset the mouse cursor sprite data', function ()
      picosonic_app_base:on_reset()
      local s = assert.spy(mouse.set_cursor_sprite_data)
      s.was_called(1)
      s.was_called_with(match.ref(mouse), nil)
    end)

  end)

  describe('on_update', function ()

    setup(function ()
      stub(vlogger.window, "update")
      stub(profiler.window, "update")
      stub(codetuner, "update_window")
    end)

    teardown(function ()
      vlogger.window.update:revert()
      profiler.window.update:revert()
      codetuner.update_window:revert()
    end)

    after_each(function ()
      vlogger.window.update:clear()
      profiler.window.update:clear()
      codetuner.update_window:clear()
    end)

    it('should update the vlogger window', function ()
      picosonic_app_base:on_update()
      local s = assert.spy(vlogger.window.update)
      s.was_called(1)
      s.was_called_with(match.ref(vlogger.window))
    end)

    it('should update the profiler window', function ()
      picosonic_app_base:on_update()
      local s = assert.spy(profiler.window.update)
      s.was_called(1)
      s.was_called_with(match.ref(profiler.window))
    end)

    it('should update the codetuner window', function ()
      picosonic_app_base:on_update()
      local s = assert.spy(codetuner.update_window)
      s.was_called(1)
      s.was_called_with(match.ref(codetuner))
    end)

  end)

  describe('on_render', function ()

    setup(function ()
      stub(vlogger.window, "render")
      stub(profiler.window, "render")
      stub(codetuner, "render_window")
      stub(mouse, "render")
    end)

    teardown(function ()
      vlogger.window.render:revert()
      profiler.window.render:revert()
      codetuner.render_window:revert()
      mouse.render:revert()
    end)

    after_each(function ()
      vlogger.window.render:clear()
      profiler.window.render:clear()
      codetuner.render_window:clear()
      mouse.render:clear()
    end)

    it('should render the vlogger window', function ()
      picosonic_app_base:on_render()
      local s = assert.spy(vlogger.window.render)
      s.was_called(1)
      s.was_called_with(match.ref(vlogger.window))
    end)

    it('should render the profiler window', function ()
      picosonic_app_base:on_render()
      local s = assert.spy(profiler.window.render)
      s.was_called(1)
      s.was_called_with(match.ref(profiler.window))
    end)

    it('should render the codetuner window', function ()
      picosonic_app_base:on_render()
      local s = assert.spy(codetuner.render_window)
      s.was_called(1)
      s.was_called_with(match.ref(codetuner))
    end)

    it('should render the mouse', function ()
      picosonic_app_base:on_render()
      local s = assert.spy(mouse.render)
      s.was_called(1)
      s.was_called_with(match.ref(mouse))
    end)

  end)

end)

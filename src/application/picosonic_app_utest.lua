require("test/bustedhelper")
local picosonic_app = require("application/picosonic_app")

local flow = require("engine/application/flow")
local codetuner = require("engine/debug/codetuner")
local profiler = require("engine/debug/profiler")
local vlogger = require("engine/debug/visual_logger")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")
local titlemenu = require("menu/titlemenu")
local credits = require("menu/credits")
local stage_state = require("ingame/stage_state")
local visual = require("resources/visual")

describe('picosonic_app', function ()

  local app

  before_each(function ()
    app = picosonic_app()
  end)

  describe('instantiate_gamestates', function ()

    it('should return all gamestates', function ()
      assert.are_same({titlemenu(), credits(), stage_state()}, picosonic_app:instantiate_gamestates())
    end)

  end)

  describe('on_post_start', function ()

    setup(function ()
      stub(input, "toggle_mouse")
      stub(ui, "set_cursor_sprite_data")
    end)

    teardown(function ()
      input.toggle_mouse:revert()
      ui.set_cursor_sprite_data:revert()
    end)

    after_each(function ()
      input.toggle_mouse:clear()
      ui.set_cursor_sprite_data:clear()
    end)

    it('should toggle mouse cursor', function ()
      app:on_post_start()
      local s = assert.spy(input.toggle_mouse)
      s.was_called(1)
      s.was_called_with(match.ref(input), true)
    end)

    it('should set the ui cursor sprite data', function ()
      app:on_post_start()
      local s = assert.spy(ui.set_cursor_sprite_data)
      s.was_called(1)
      s.was_called_with(match.ref(ui), match.ref(visual.sprite_data_t.cursor))
    end)

  end)

  describe('on_reset', function ()

    setup(function ()
      stub(ui, "set_cursor_sprite_data")
    end)

    teardown(function ()
      ui.set_cursor_sprite_data:revert()
    end)

    after_each(function ()
      ui.set_cursor_sprite_data:clear()
    end)

    it('should reset the ui cursor sprite data', function ()
      picosonic_app:on_reset()
      local s = assert.spy(ui.set_cursor_sprite_data)
      s.was_called(1)
      s.was_called_with(match.ref(ui), nil)
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
      picosonic_app:on_update()
      local s = assert.spy(vlogger.window.update)
      s.was_called(1)
      s.was_called_with(match.ref(vlogger.window))
    end)

    it('should update the profiler window', function ()
      picosonic_app:on_update()
      local s = assert.spy(profiler.window.update)
      s.was_called(1)
      s.was_called_with(match.ref(profiler.window))
    end)

    it('should update the codetuner window', function ()
      picosonic_app:on_update()
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
      stub(ui, "render_mouse")
    end)

    teardown(function ()
      vlogger.window.render:revert()
      profiler.window.render:revert()
      codetuner.render_window:revert()
      ui.render_mouse:revert()
    end)

    after_each(function ()
      vlogger.window.render:clear()
      profiler.window.render:clear()
      codetuner.render_window:clear()
      ui.render_mouse:clear()
    end)

    it('should render the vlogger window', function ()
      picosonic_app:on_render()
      local s = assert.spy(vlogger.window.render)
      s.was_called(1)
      s.was_called_with(match.ref(vlogger.window))
    end)

    it('should render the profiler window', function ()
      picosonic_app:on_render()
      local s = assert.spy(profiler.window.render)
      s.was_called(1)
      s.was_called_with(match.ref(profiler.window))
    end)

    it('should render the codetuner window', function ()
      picosonic_app:on_render()
      local s = assert.spy(codetuner.render_window)
      s.was_called(1)
      s.was_called_with(match.ref(codetuner))
    end)

    it('should render the mouse', function ()
      picosonic_app:on_render()
      local s = assert.spy(ui.render_mouse)
      s.was_called(1)
      s.was_called_with(match.ref(ui))
    end)

  end)

end)

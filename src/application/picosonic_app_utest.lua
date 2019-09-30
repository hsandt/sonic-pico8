require("engine/test/bustedhelper")
local picosonic_app = require("application/picosonic_app")

local flow = require("engine/application/flow")
local codetuner = require("engine/debug/codetuner")
local profiler = require("engine/debug/profiler")
local vlogger = require("engine/debug/visual_logger")
local ui = require("engine/ui/ui")
local gamestate_proxy = require("application/gamestate_proxy")
local titlemenu = require("menu/titlemenu_dummy")
local credits = require("menu/credits_dummy")
local stage = require("ingame/stage")
local visual = require("resources/visual")

describe('picosonic_app', function ()

  local app

  before_each(function ()
    app = picosonic_app()
  end)

  describe('register_gamestates', function ()

    it('should add all gamestates', function ()
      -- require the real stage (as we required "stage" not "stage_dummy" at the top
      -- but leave the other states as dummy
      gamestate_proxy:require_gamestates({"stage"})
      picosonic_app:register_gamestates()

      -- interface
      assert.are_equal(titlemenu.state, flow.gamestates[titlemenu.state.type])
      assert.are_equal(credits.state, flow.gamestates[credits.state.type])
      assert.are_equal(stage.state, flow.gamestates[stage.state.type])
    end)

  end)

  describe('on_start', function ()

    setup(function ()
      stub(ui, "set_cursor_sprite_data")
    end)

    teardown(function ()
      ui.set_cursor_sprite_data:revert()
    end)

    after_each(function ()
      ui.set_cursor_sprite_data:clear()
    end)

    it('should set the ui cursor sprite data', function ()
      app.on_start()
      local s = assert.spy(ui.set_cursor_sprite_data)
      s.was_called(1)
      s.was_called_with(match.ref(ui), match.ref(visual.sprite_data_t.cursor))
    end)

  end)

  describe('on_reset (#utest only)', function ()

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

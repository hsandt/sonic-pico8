require("bustedhelper")
local gameapp = require("game/application/gameapp")

local flow = require("engine/application/flow")
local input = require("engine/input/input")
local titlemenu = require("game/menu/titlemenu_dummy")
local credits = require("game/menu/credits_dummy")
local stage = require("game/ingame/stage")
local ui = require("engine/ui/ui")
local gamestate_proxy = require("game/application/gamestate_proxy")

describe('gameapp', function ()

  describe('init', function ()

    setup(function ()
      ui_set_cursor_sprite_data_stub = stub(ui, "set_cursor_sprite_data")
      spy.on(gamestate_proxy, "require_gamestates")
    end)

    teardown(function ()
      ui_set_cursor_sprite_data_stub:revert()
      gamestate_proxy.require_gamestates:revert()
    end)

    after_each(function ()
      gameapp.reinit_modules()
      ui_set_cursor_sprite_data_stub:clear()
      gamestate_proxy.require_gamestates:clear()
    end)

    it('should assert if active_gamestates is nil (for non-pico8 build)', function ()
      assert.has_error(function ()
        gameapp.init()
      end)
    end)

    it('should set the ui cursor sprite data', function ()
      local visual = require("game/resources/visual")
      gameapp.init({})
      assert.spy(ui_set_cursor_sprite_data_stub).was_called(1)
      assert.spy(ui_set_cursor_sprite_data_stub).was_called_with(match.ref(ui), match.ref(visual.sprite_data_t.cursor))
    end)

    it('should require active gamestates via gamestate proxy', function ()
      gameapp.init({'stage'})

      -- implementation
      assert.spy(gamestate_proxy.require_gamestates).was_called(1)
      assert.spy(gamestate_proxy.require_gamestates).was_called_with(match.ref(gamestate_proxy), {'stage'})
    end)

    it('should add all gamestates', function ()
      gameapp.init({'stage'})  -- needed because we require the stage at the top, not a dummy

      -- interface
      assert.are_equal(titlemenu.state, flow.gamestates[titlemenu.state.type])
      assert.are_equal(credits.state, flow.gamestates[credits.state.type])
      assert.are_equal(stage.state, flow.gamestates[stage.state.type])
    end)

    it('should query titlemenu as initial state', function ()
      gameapp.init({})
      assert.are_equal(titlemenu.state, flow.next_gamestate)
    end)

  end)

  describe('renit_modules (#utest only)', function ()

    setup(function ()
      ui_set_cursor_sprite_data_stub = stub(ui, "set_cursor_sprite_data")
      gamestate_proxy_init = stub(gamestate_proxy, "init")
      flow_init_stub = stub(flow, "init")
    end)

    teardown(function ()
      ui_set_cursor_sprite_data_stub:revert()
      gamestate_proxy_init:revert()
      flow_init_stub:revert()
    end)

    after_each(function ()
      ui_set_cursor_sprite_data_stub:clear()
      gamestate_proxy_init:clear()
      flow_init_stub:clear()
    end)

    it('should reset the ui cursor sprite data', function ()
      gameapp.reinit_modules()
      assert.spy(ui_set_cursor_sprite_data_stub).was_called(1)
      assert.spy(ui_set_cursor_sprite_data_stub).was_called_with(match.ref(ui), nil)
    end)

    it('should reinit gamestate_proxy', function ()
      gameapp.reinit_modules()
      assert.spy(gamestate_proxy_init).was_called(1)
      assert.spy(gamestate_proxy_init).was_called_with(match.ref(gamestate_proxy))
    end)

    it('should reinit flow', function ()
      gameapp.reinit_modules()
      assert.spy(flow_init_stub).was_called(1)
      assert.spy(flow_init_stub).was_called_with(match.ref(flow))
    end)

  end)

  describe('update', function ()

    local process_players_inputs_stub
    local flow_update_stub

    setup(function ()
      gameapp.init({})
      process_players_inputs_stub = stub(input, "process_players_inputs")
      flow_update_stub = stub(flow, "update")
    end)

    teardown(function ()
      process_players_inputs_stub:revert()
      flow_update_stub:revert()
    end)

    after_each(function ()
      process_players_inputs_stub:clear()
      flow_update_stub:clear()
    end)

    it('should update the input', function ()
      gameapp.update()
      assert.spy(process_players_inputs_stub).was_called(1)
      assert.spy(process_players_inputs_stub).was_called_with(match.ref(input))
    end)

    it('should update the flow', function ()
      gameapp.update()
      assert.spy(flow_update_stub).was_called(1)
      assert.spy(flow_update_stub).was_called_with(match.ref(flow))
    end)

  end)

  describe('draw', function ()

    local cls_stub
    local flow_render_stub

    setup(function ()
      gameapp.init({})
      gameapp.update()
      cls_stub = stub(_G, "cls")
      flow_render_stub = stub(flow, "render")
    end)

    teardown(function ()
      cls_stub:revert()
      flow_render_stub:revert()
    end)

    after_each(function ()
      cls_stub:clear()
      flow_render_stub:clear()
    end)

    it('should clear screen and delegate rendering to flow', function ()
      gameapp.draw()
      assert.spy(flow_render_stub).was_called(1)
      assert.spy(flow_render_stub).was_called_with(match.ref(flow))
      assert.spy(cls_stub).was_called(1)
    end)

  end)


end)

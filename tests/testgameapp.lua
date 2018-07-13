require("bustedhelper")
local gameapp = require("game/application/gameapp")

local flow = require("engine/application/flow")
local titlemenu = require("game/menu/titlemenu")
local credits = require("game/menu/credits")
local stage = require("game/ingame/stage")

describe('gameapp', function ()

  describe('init', function ()

    setup(function ()
      gameapp.init()
    end)

    teardown(function ()
      clear_table(flow.gamestates)
      flow.next_gamestate = nil
    end)

    it('should add all gamestates', function ()
      assert.are_equal(credits.state, flow.gamestates[credits.state.type])
    end)

    it('should query titlemenu as initial state', function ()
      assert.are_equal(titlemenu.state, flow.next_gamestate)
    end)

  end)

  describe('update', function ()

    local flow_update_stub

    setup(function ()
      gameapp.init()
      flow_update_stub = stub(flow, "update")
    end)

    teardown(function ()
      flow_update_stub:revert()
    end)

    after_each(function ()
      flow_update_stub:clear()
    end)

    it('should update the flow', function ()
      gameapp.update()
      assert.spy(flow_update_stub).was_called(1)
      assert.spy(flow_update_stub).was_called_with(flow)
    end)

  end)

  describe('draw', function ()

    local cls_stub
    local flow_render_stub

    setup(function ()
      gameapp.init()
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
      assert.spy(flow_render_stub).was_called_with(flow)
      assert.spy(cls_stub).was_called(1)
    end)

  end)


end)

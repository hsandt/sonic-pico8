require("bustedhelper")
titlemenu = require("game/menu/titlemenu")
flow = require("engine/application/flow")
require("game/application/gamestates")
credits = require("game/menu/credits")
stage = require("game/ingame/stage")

describe('titlemenu', function ()

  describe('state.type', function ()
    it('should be gamestate_types.titlemenu', function ()
      assert.are_equal(gamestate_types.titlemenu, titlemenu.state.type)
    end)
  end)

  describe('(stage states added)', function ()

    setup(function ()
      flow:add_gamestate(titlemenu.state)
      flow:add_gamestate(credits.state)
      flow:add_gamestate(stage.state)
    end)

    teardown(function ()
      clear_table(flow.gamestates)
    end)

    describe('(titlemenu state entered)', function ()

      setup(function ()
        flow:_change_gamestate(titlemenu.state)
      end)

      teardown(function ()
        flow.current_gamestate:on_exit()
        flow.current_gamestate = nil
      end)

      describe('state.current_cursor_index', function ()
        it('should be set to 0', function ()
          assert.are_equal(0, titlemenu.state.current_cursor_index)
        end)
      end)

      describe('(cursor start at index 0)', function ()

        before_each(function ()
          titlemenu.state.current_cursor_index = 0
        end)

        after_each(function ()
          titlemenu.state.current_cursor_index = 0
        end)

        describe('state:move_cursor_up', function ()

          it('should not change current_cursor_index due to clamping', function ()
            titlemenu.state:move_cursor_up()
            assert.are_equal(0, titlemenu.state.current_cursor_index)
          end)

        end)

        describe('state:move_cursor_down', function ()

          it('should increase current_cursor_index', function ()
            titlemenu.state:move_cursor_down()
            assert.are_equal(1, titlemenu.state.current_cursor_index)
          end)

        end)

      end)

      describe('(cursor start at index 1)', function ()

        before_each(function ()
          titlemenu.state.current_cursor_index = 1
        end)

        after_each(function ()
          titlemenu.state.current_cursor_index = 0
        end)

        describe('state:move_cursor_up', function ()

          it('should decrease current_cursor_index', function ()
            titlemenu.state:move_cursor_up()
            assert.are_equal(0, titlemenu.state.current_cursor_index)
          end)

        end)

        describe('state:move_cursor_down', function ()

          it('should not change current_cursor_index due to clamping', function ()
            titlemenu.state:move_cursor_down()
            assert.are_equal(1, titlemenu.state.current_cursor_index)
          end)

        end)

      end)

    end)  -- (titlemenu state entered)

    describe('(enter titlemenu state each time)', function ()

      before_each(function ()
        flow:_change_gamestate(titlemenu.state)
      end)

      after_each(function ()
        flow.current_gamestate:on_exit()  -- whatever the current gamestate is
        flow.current_gamestate = nil
      end)

      describe('state:confirm_current_selection', function ()

        it('should have queried stage state', function ()
          titlemenu.state.current_cursor_index = 0
          titlemenu.state:confirm_current_selection()
          assert.are_equal(gamestate_types.stage, flow.next_gamestate.type)
        end)

      end)

      describe('state:confirm_current_selection', function ()

        it('should have queried credits state', function ()
          titlemenu.state.current_cursor_index = 1
          titlemenu.state:confirm_current_selection()
          assert.are_equal(gamestate_types.credits, flow.next_gamestate.type)
        end)

      end)

    end)  -- (enter titlemenu state each time)

  end)  -- (stage states added)

end)

require("bustedhelper")
input = require("engine/input/input")
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

  describe('state._tostring', function ()
    it('should return [titlemenu state]', function ()
      assert.are_equal("[titlemenu state]", titlemenu.state._tostring())
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


    describe('state:on_enter', function ()

      setup(function ()
        titlemenu.state:on_enter()
      end)

      teardown(function ()
        input:toggle_mouse(false)
        titlemenu.state.current_cursor_index = 0
      end)

      it('should show the mouse', function ()
        titlemenu.state:on_enter()
        assert.is_true(input.mouse_active)
      end)

      it('should initialize cursor at index 0', function ()
        titlemenu.state:on_enter()
        assert.are_equal(0, titlemenu.state.current_cursor_index)
      end)

    end)

    describe('state:on_exit', function ()

      it('should hide the mouse', function ()
        titlemenu.state:on_exit()
        assert.is_false(input.mouse_active)
      end)

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

      describe('state:update', function ()

        local move_cursor_up_stub

        setup(function ()
          move_cursor_up_stub = stub(titlemenu.state, "move_cursor_up")
          move_cursor_down_stub = stub(titlemenu.state, "move_cursor_down")
          confirm_current_selection_stub = stub(titlemenu.state, "confirm_current_selection")
        end)

        teardown(function ()
          move_cursor_up_stub:revert()
          move_cursor_down_stub:revert()
          confirm_current_selection_stub:revert()
        end)

        after_each(function ()
          input.players_button_states[0][input.button_ids.up] = input.button_state.released
          input.players_button_states[0][input.button_ids.down] = input.button_state.released
          input.players_button_states[0][input.button_ids.x] = input.button_state.released

          move_cursor_up_stub:clear()
          move_cursor_down_stub:clear()
          confirm_current_selection_stub:clear()
        end)

        describe('(when input is inactive)', function ()

          setup(function ()
            input.active = false
          end)

          teardown(function ()
            input.active = true
          end)

          it('should do nothing', function ()
            input.players_button_states[0][input.button_ids.up] = input.button_state.just_pressed
            titlemenu.state:update()
            input.players_button_states[0][input.button_ids.up] = input.button_state.released
            input.players_button_states[0][input.button_ids.down] = input.button_state.just_pressed
            titlemenu.state:update()
            input.players_button_states[0][input.button_ids.down] = input.button_state.released
            input.players_button_states[0][input.button_ids.x] = input.button_state.just_pressed
            titlemenu.state:update()
            assert.spy(move_cursor_up_stub).was_called(0)
            assert.spy(confirm_current_selection_stub).was_called(0)
          end)

        end)

        it('(when input up in down) it should be move cursor up', function ()
          input.players_button_states[0][input.button_ids.up] = input.button_state.just_pressed
          titlemenu.state:update()
          assert.spy(move_cursor_up_stub).was_called(1)
          assert.spy(move_cursor_up_stub).was_called_with(titlemenu.state)
        end)

        it('(when input down in down) it should be move cursor down', function ()
          input.players_button_states[0][input.button_ids.down] = input.button_state.just_pressed
          titlemenu.state:update()
          assert.spy(move_cursor_down_stub).was_called(1)
          assert.spy(move_cursor_down_stub).was_called_with(titlemenu.state)
        end)

        it('(when input x in down) it should be move cursor x', function ()
          input.players_button_states[0][input.button_ids.x] = input.button_state.just_pressed
          titlemenu.state:update()
          assert.spy(confirm_current_selection_stub).was_called(1)
          assert.spy(confirm_current_selection_stub).was_called_with(titlemenu.state)
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

        describe('render', function ()

          local api_print_stub

          setup(function ()
            api_print_stub = stub(api, "print")
          end)

          teardown(function ()
            api_print_stub:revert()
          end)

          after_each(function ()
            api_print_stub:clear()
          end)

          it('should print "starts", "credits" and cursor ">" in front of start in white', function ()
            titlemenu.state:render()
            assert.are_equal(colors.white, pico8.color)
            assert.spy(api_print_stub).was_called(3)
            assert.spy(api_print_stub).was_called_with("start", 4*11, 6*12)
            assert.spy(api_print_stub).was_called_with("credits", 4*11, 6*13)
            assert.spy(api_print_stub).was_called_with(">", 4*10, 6*12)
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


        describe('render', function ()

          local api_print_stub

          setup(function ()
            api_print_stub = stub(api, "print")
          end)

          teardown(function ()
            api_print_stub:revert()
          end)

          after_each(function ()
            api_print_stub:clear()
          end)

          it('should print "starts", "credits" and cursor ">" in front of credits in white', function ()
            titlemenu.state:render()
            assert.are_equal(colors.white, pico8.color)
            assert.spy(api_print_stub).was_called(3)
            assert.spy(api_print_stub).was_called_with("start", 4*11, 6*12)
            assert.spy(api_print_stub).was_called_with("credits", 4*11, 6*13)
            assert.spy(api_print_stub).was_called_with(">", 4*10, 6*13)
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

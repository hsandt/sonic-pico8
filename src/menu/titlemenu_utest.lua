require("engine/test/bustedhelper")
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")

local picosonic_app = require("application/picosonic_app")
local titlemenu = require("menu/titlemenu")

local dummy_stage_state = derived_class(gamestate)
dummy_stage_state.type = ':stage'

local dummy_credits_state = derived_class(gamestate)
dummy_credits_state.type = ':credits'

describe('titlemenu', function ()

  describe('static members', function ()

    it('type is :stage', function ()
      assert.are_equal(':titlemenu', titlemenu.type)
    end)

  end)

  describe('(stage states added)', function ()

    before_each(function ()
      flow:add_gamestate(titlemenu)
      flow:add_gamestate(dummy_credits_state)
      flow:add_gamestate(dummy_stage_state)
    end)

    after_each(function ()
      flow:init()
    end)

    describe('(with instance)', function ()

      local state

      before_each(function ()
        local app = picosonic_app()
        state = titlemenu()
          -- no need to register gamestate properly, just add app member to pass tests
        state.app = app
      end)

      describe('state:on_enter', function ()

        before_each(function ()
          state:on_enter()
        end)

        it('should initialize cursor at index 0', function ()
          state:on_enter()
          assert.are_equal(0, state.current_cursor_index)
        end)

      end)

      describe('state:on_exit', function ()
      end)

      describe('(titlemenu state entered)', function ()

        before_each(function ()
          flow:_change_state(state)
        end)

        describe('state.current_cursor_index', function ()
          it('should be set to 0', function ()
            assert.are_equal(0, state.current_cursor_index)
          end)
        end)

        describe('state:update', function ()

          setup(function ()
            stub(titlemenu, "move_cursor_up")
            stub(titlemenu, "move_cursor_down")
            stub(titlemenu, "confirm_current_selection")
          end)

          teardown(function ()
            titlemenu.move_cursor_up:revert()
            titlemenu.move_cursor_down:revert()
            titlemenu.confirm_current_selection:revert()
          end)

          after_each(function ()
            input:init()

            titlemenu.move_cursor_up:clear()
            titlemenu.move_cursor_down:clear()
            titlemenu.confirm_current_selection:clear()
          end)

          it('(when input up in down) it should be move cursor up', function ()
            input.players_btn_states[0][button_ids.up] = btn_states.just_pressed
            state:update()
            assert.spy(titlemenu.move_cursor_up).was_called(1)
            assert.spy(titlemenu.move_cursor_up).was_called_with(match.ref(state))
          end)

          it('(when input down in down) it should be move cursor down', function ()
            input.players_btn_states[0][button_ids.down] = btn_states.just_pressed
            state:update()
            assert.spy(titlemenu.move_cursor_down).was_called(1)
            assert.spy(titlemenu.move_cursor_down).was_called_with(match.ref(state))
          end)

          it('(when input x in down) it should be move cursor x', function ()
            input.players_btn_states[0][button_ids.x] = btn_states.just_pressed
            state:update()
            assert.spy(titlemenu.confirm_current_selection).was_called(1)
            assert.spy(titlemenu.confirm_current_selection).was_called_with(match.ref(state))
          end)

        end)

        describe('(cursor start at index 0)', function ()

          before_each(function ()
            state.current_cursor_index = 0
          end)

          after_each(function ()
            state.current_cursor_index = 0
          end)

          describe('state:move_cursor_up', function ()

            it('should not change current_cursor_index due to clamping', function ()
              state:move_cursor_up()
              assert.are_equal(0, state.current_cursor_index)
            end)

          end)

          describe('state:move_cursor_down', function ()

            it('should increase current_cursor_index', function ()
              state:move_cursor_down()
              assert.are_equal(1, state.current_cursor_index)
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
              state:render()
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
            state.current_cursor_index = 1
          end)

          after_each(function ()
            state.current_cursor_index = 0
          end)

          describe('state:move_cursor_up', function ()

            it('should decrease current_cursor_index', function ()
              state:move_cursor_up()
              assert.are_equal(0, state.current_cursor_index)
            end)

          end)

          describe('state:move_cursor_down', function ()

            it('should not change current_cursor_index due to clamping', function ()
              state:move_cursor_down()
              assert.are_equal(1, state.current_cursor_index)
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
              state:render()
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
          flow:_change_state(state)
        end)

        after_each(function ()
          flow.curr_state:on_exit()  -- whatever the current gamestate is
          flow.curr_state = nil
        end)

        describe('state:confirm_current_selection', function ()

          it('should have queried stage state', function ()
            state.current_cursor_index = 0
            state:confirm_current_selection()
            assert.are_equal(':stage', flow.next_state.type)
          end)

        end)

        describe('state:confirm_current_selection', function ()

          it('should have queried credits state', function ()
            state.current_cursor_index = 1
            state:confirm_current_selection()
            assert.are_equal(':credits', flow.next_state.type)
          end)

        end)

      end)  -- (enter titlemenu state each time)

    end)  -- (with instance)

  end)  -- (stage states added)

end)

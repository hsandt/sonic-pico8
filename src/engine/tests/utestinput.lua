require("engine/test/bustedhelper")
local input = require("engine/input/input")

describe('input', function ()

  describe('generate_initial_btn_states', function ()

    it('should return a table of released button states for each input key', function ()
      assert.are_same({
          [button_ids.left] = btn_states.released,
          [button_ids.right] = btn_states.released,
          [button_ids.up] = btn_states.released,
          [button_ids.down] = btn_states.released,
          [button_ids.o] = btn_states.released,
          [button_ids.x] = btn_states.released
        },
        generate_initial_btn_states())
    end)

  end)

  describe('input.players_btn_states', function ()

    it('should contain 2 tables of released button states, one per player', function ()
      assert.are_same({
          [0] = {
            [button_ids.left] = btn_states.released,
            [button_ids.right] = btn_states.released,
            [button_ids.up] = btn_states.released,
            [button_ids.down] = btn_states.released,
            [button_ids.o] = btn_states.released,
            [button_ids.x] = btn_states.released
          },
          [1] = {
            [button_ids.left] = btn_states.released,
            [button_ids.right] = btn_states.released,
            [button_ids.up] = btn_states.released,
            [button_ids.down] = btn_states.released,
            [button_ids.o] = btn_states.released,
            [button_ids.x] = btn_states.released
          }
        },
        input.players_btn_states)
    end)

  end)

  describe('toggle_mouse', function ()

    describe('(mouse devkit inactive)', function ()

      before_each(function ()
        input.mouse_active = false
        poke(0x5f2d, 0)
      end)

      after_each(function ()
        input.mouse_active = false
        poke(0x5f2d, 0)
      end)

      it('(true) => activate mouse devkit', function ()
        input:toggle_mouse(true)
        assert.are_same({1, true}, {peek(0x5f2d), input.mouse_active})
      end)

      it('(false) => deactivate mouse devkit', function ()
        input:toggle_mouse(false)
        assert.are_same({0, false}, {peek(0x5f2d), input.mouse_active})
      end)

      it('() => toggle to active', function ()
        input:toggle_mouse()
        assert.are_same({1, true}, {peek(0x5f2d), input.mouse_active})
      end)

    end)

    describe('(mouse devkit active)', function ()

      before_each(function ()
        input.mouse_active = true
        poke(0x5f2d, 1)
      end)

      after_each(function ()
        input.mouse_active = false
        poke(0x5f2d, 0)
      end)

      it('(true) => activate mouse devkit', function ()
        input:toggle_mouse(true)
        assert.are_same({1, true}, {peek(0x5f2d), input.mouse_active})
      end)

      it('(false) => deactivate mouse devkit', function ()
        input:toggle_mouse(false)
        assert.are_same({0, false}, {peek(0x5f2d), input.mouse_active})
      end)

      it('() => toggle to inactive', function ()
        input:toggle_mouse()
        assert.are_same({0, false}, {peek(0x5f2d), input.mouse_active})
      end)

    end)

  end)

end)

describe('(mouse toggled)', function ()

  setup(function ()
    pico8.mousepos = vector(24, 36)
  end)

  teardown(function ()
    pico8.mousepos = vector.zero()
  end)

  describe('get_cursor_position', function ()

    it('should return the current cursor position (sign test)', function ()
      local cursor_position = input.get_cursor_position()
      assert.are_equal(24, cursor_position.x)
      assert.are_equal(36, cursor_position.y)
    end)

  end)

  describe('(when both players have some input)', function ()

    setup(function ()
      input.players_btn_states = {
        [0] = {
          [button_ids.left] = btn_states.released,
          [button_ids.right] = btn_states.just_pressed,
          [button_ids.up] = btn_states.released,
          [button_ids.down] = btn_states.just_pressed,
          [button_ids.o] = btn_states.pressed,
          [button_ids.x] = btn_states.just_released
        },
        [1] = {
          [button_ids.left] = btn_states.just_pressed,
          [button_ids.right] = btn_states.pressed,
          [button_ids.up] = btn_states.just_released,
          [button_ids.down] = btn_states.released,
          [button_ids.o] = btn_states.pressed,
          [button_ids.x] = btn_states.pressed
        }
      }
    end)

    teardown(function ()
      input.players_btn_states = {
        [0] = generate_initial_btn_states(),
        [1] = generate_initial_btn_states()
      }
    end)

    describe('get_button_state', function ()

      it('should return a button state for player 0 by default', function ()
        assert.are_equal(btn_states.released, input:get_button_state(button_ids.left))
      end)

      it('should return a button state for player 0', function ()
        assert.are_equal(btn_states.just_released, input:get_button_state(button_ids.x, 0))
      end)

      it('should return a button state for player 1', function ()
        assert.are_equal(btn_states.released, input:get_button_state(button_ids.down, 1))
      end)

    end)

    describe('is_up', function ()

      it('should return true if button is released for player 0 by default', function ()
        assert.is_true(input:is_up(button_ids.left))
      end)

      it('should return true if button is just released for player 0 by default', function ()
        assert.is_true(input:is_up(button_ids.x))
      end)

      it('should return true if button is released for player 0', function ()
        assert.is_true(input:is_up(button_ids.left, 0))
      end)

      it('should return true if button is released for player 0', function ()
        assert.is_true(input:is_up(button_ids.x, 0))
      end)

      it('should return false if button is pressed for player 0', function ()
        assert.is_false(input:is_up(button_ids.o, 0))
      end)

      it('should return false if button is just pressed for player 0', function ()
        assert.is_false(input:is_up(button_ids.right, 0))
      end)

      it('should return true if button is released for player 1', function ()
        assert.is_true(input:is_up(button_ids.down, 1))
      end)

      it('should return true if button is released for player 1', function ()
        assert.is_true(input:is_up(button_ids.up, 1))
      end)

      it('should return false if button is pressed for player 1', function ()
        assert.is_false(input:is_up(button_ids.o, 1))
      end)

      it('should return false if button is just pressed for player 1', function ()
        assert.is_false(input:is_up(button_ids.right, 1))
      end)

    end)

    describe('is_down', function ()

      it('should return the opposite of is_up', function ()
        assert.is_true(input:is_down(button_ids.left) == not input:is_up(button_ids.left))
        assert.is_true(input:is_down(button_ids.up, 0) == not input:is_up(button_ids.up, 0))
        assert.is_true(input:is_down(button_ids.x, 1) == not input:is_up(button_ids.x, 1))
      end)

    end)

    describe('is_just_released', function ()

      it('should return true if the button was just released', function ()
        assert.is_true(input:is_just_released(button_ids.x, 0))
      end)

      it('should return false if the button was not just released', function ()
        assert.are_same({false, false, false},
          {
            input:is_just_released(button_ids.up, 0),
            input:is_just_released(button_ids.left, 1),
            input:is_just_released(button_ids.right, 1)
          })
      end)

    end)

    describe('is_just_pressed', function ()

      it('should return true if the button was just released', function ()
        assert.is_true(input:is_just_pressed(button_ids.down, 0))
      end)

      it('should return false if the button was not just released', function ()
        assert.are_same({false, false, false},
          {
            input:is_just_pressed(button_ids.up, 0),
            input:is_just_pressed(button_ids.up, 1),
            input:is_just_pressed(button_ids.right, 1)
          })
      end)

    end)

  end)

  describe('process_players_inputs', function ()

    local _process_player_inputs_stub

    setup(function ()
      _process_player_inputs_stub = stub(input, "_process_player_inputs")
    end)

    teardown(function ()
      _process_player_inputs_stub:revert()
    end)

    after_each(function ()
      _process_player_inputs_stub:clear()
    end)

    it('should call _process_player_inputs on each player', function ()
      input:process_players_inputs()
      assert.spy(_process_player_inputs_stub).was_called(2)
      assert.spy(_process_player_inputs_stub).was_called_with(match.ref(input), 0)
      assert.spy(_process_player_inputs_stub).was_called_with(match.ref(input), 1)
    end)

  end)

  describe('_process_player_inputs', function ()

    after_each(function ()
      -- reset all button states
      clear_table(pico8.keypressed[0])
      clear_table(pico8.keypressed[1])

      input.players_btn_states = {
        [0] = generate_initial_btn_states(),
        [1] = generate_initial_btn_states()
      }

      pico8.keypressed.counter = 0
    end)

    describe('(when input mode is native)', function ()

      describe('(when player 0 has button left & up: released, right & down: just pressed, o & x: pressed)', function ()

        before_each(function ()
          input.players_btn_states[0] = {
            [button_ids.left] = btn_states.released,
            [button_ids.right] = btn_states.just_pressed,
            [button_ids.up] = btn_states.released,
            [button_ids.down] = btn_states.just_pressed,
            [button_ids.o] = btn_states.pressed,
            [button_ids.x] = btn_states.pressed
          }
          pico8.keypressed[0] = {
            [0] = false,  -- left
            false,        -- right
            true,         -- up
            true,         -- down
            false,        -- o
            true          -- x
          }
          -- counter should be 1 (or a multiple of the repeat period) if a button is supposed to be just pressed this frame
          pico8.keypressed.counter = 1
        end)

        it('should update all button states for player 0 in parallel', function ()
          input:_process_player_inputs(0)
          assert.are_same({
              [button_ids.left] = btn_states.released,
              [button_ids.right] = btn_states.just_released,
              [button_ids.up] = btn_states.just_pressed,
              [button_ids.down] = btn_states.pressed,
              [button_ids.o] = btn_states.just_released,
              [button_ids.x] = btn_states.pressed
            },
            input.players_btn_states[0])
        end)

      end)

      describe('(when player 1 has button left & up: released, right & down: just released, o & x: pressed)', function ()

        before_each(function ()
          input.players_btn_states[1] = {
            [button_ids.left] = btn_states.released,
            [button_ids.right] = btn_states.just_released,
            [button_ids.up] = btn_states.released,
            [button_ids.down] = btn_states.just_released,
            [button_ids.o] = btn_states.pressed,
            [button_ids.x] = btn_states.pressed
          }
          pico8.keypressed[1] = {
            [0] = false,  -- left
            false,        -- right
            true,         -- up
            true,         -- down
            false,        -- o
            true          -- x
          }
          -- counter should be 1 (or a multiple of the repeat period) if a button is supposed to be just pressed this frame
          pico8.keypressed.counter = 1
        end)

        it('should update all button states for player 1 in parallel', function ()
          input:_process_player_inputs(1)
          assert.are_same({
              [button_ids.left] = btn_states.released,
              [button_ids.right] = btn_states.released,
              [button_ids.up] = btn_states.just_pressed,
              [button_ids.down] = btn_states.just_pressed,
              [button_ids.o] = btn_states.just_released,
              [button_ids.x] = btn_states.pressed
            },
            input.players_btn_states[1])
        end)

      end)

      describe('(when button has just been pressed but is incorrect state because btnp counter is wrong)', function ()

        before_each(function ()
          input.players_btn_states[0][button_ids.left] = btn_states.released
          pico8.keypressed[0][button_ids.left] = true
          -- leave pico8.keypressed.counter at 0
        end)

        it('should detect and assert if btnp returns false while our model says it should be true', function ()
          assert.has_error(function()
              input:_process_player_inputs(0)
            end,
            "input:_update_button_state: button 0 was released and is now pressed, but btnp(0) returns false")
        end)

      end)

    end)

    describe('(when input mode is simulated)', function ()

      setup(function ()
        input.mode = input_modes.simulated
      end)

      teardown(function ()
        input.mode = input_modes.native
      end)

      describe('(when player 0 has some simulated input)', function ()

        setup(function ()
          input.players_btn_states[0][button_ids.up] = btn_states.just_pressed
          input.simulated_buttons_down[0][button_ids.left] = true
          input.simulated_buttons_down[0][button_ids.up] = true
        end)

        teardown(function ()
          input.players_btn_states[0][button_ids.up] = btn_states.released
          input.simulated_buttons_down[0][button_ids.left] = false
          input.simulated_buttons_down[0][button_ids.up] = false
        end)

        it('should update the buttons states for player 0 based on the simulated button static states', function ()
          input:_process_player_inputs(0)
          assert.are_same({
              btn_states.just_pressed,
              btn_states.pressed,
            },
            {
              input.players_btn_states[0][button_ids.left],
              input.players_btn_states[0][button_ids.up],
            })
        end)

      end)

      describe('(when player 1 has some simulated input)', function ()

        setup(function ()
          input.players_btn_states[1][button_ids.down] = btn_states.just_released
          input.players_btn_states[1][button_ids.o] = btn_states.pressed
          input.simulated_buttons_down[1][button_ids.down] = true
        end)

        teardown(function ()
          input.players_btn_states[1][button_ids.down] = btn_states.released
          input.players_btn_states[1][button_ids.o] = btn_states.released
          input.simulated_buttons_down[1][button_ids.down] = false
        end)

        it('should update the buttons states for player 1 based on the simulated button static states', function ()
          input:_process_player_inputs(1)
          assert.are_same({
              btn_states.just_pressed,
              btn_states.just_released
            },
            {
              input.players_btn_states[1][button_ids.down],
              input.players_btn_states[1][button_ids.o]
            })
        end)

      end)

    end)

  end)

  describe('_btn_proxy', function ()

    after_each(function ()
    end)

    describe('(when input mode is native)', function ()

      setup(function ()
        pico8.keypressed[0][button_ids.up] = true
        pico8.keypressed[1][button_ids.o] = true
      end)

      teardown(function ()
        clear_table(pico8.keypressed[0])
        clear_table(pico8.keypressed[1])
      end)

      it('should return btn(button_id, player_id)', function ()
        assert.are_same(
          {
            false,
            false,
            true,
            true,
            false,
            true
          },
          {
            input:_btn_proxy(button_ids.left),
            input:_btn_proxy(button_ids.left, 0),
            input:_btn_proxy(button_ids.up),
            input:_btn_proxy(button_ids.up, 0),
            input:_btn_proxy(button_ids.down, 1),
            input:_btn_proxy(button_ids.o, 1),
          })
      end)

    end)

    describe('(when input mode is simulated)', function ()

      describe('(in initial state)', function ()

        it('should return false for all buttons', function ()
          assert.are_same(
            {
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false
            },
            {
              input:_btn_proxy(button_ids.left),
              input:_btn_proxy(button_ids.left, 0),
              input:_btn_proxy(button_ids.up),
              input:_btn_proxy(button_ids.up, 0),
              input:_btn_proxy(button_ids.x, 0),
              input:_btn_proxy(button_ids.down, 1),
              input:_btn_proxy(button_ids.o, 1),
              input:_btn_proxy(button_ids.x, 1),
            })
        end)

      end)

      describe('(when some simulated buttons are down)', function ()

        setup(function ()
          input.mode = input_modes.simulated
          input.simulated_buttons_down[0][button_ids.up] = true
          input.simulated_buttons_down[1][button_ids.o] = true
        end)

        teardown(function ()
          input.mode = input_modes.native
          input.simulated_buttons_down[0][button_ids.up] = false
          input.simulated_buttons_down[1][button_ids.o] = false
        end)

        it('should return true if simulated input is down', function ()

          assert.are_same(
            {
              false,
              false,
              true,
              true,
              false,
              true
            },
            {
              input:_btn_proxy(button_ids.left),
              input:_btn_proxy(button_ids.left, 0),
              input:_btn_proxy(button_ids.up),
              input:_btn_proxy(button_ids.up, 0),
              input:_btn_proxy(button_ids.down, 1),
              input:_btn_proxy(button_ids.o, 1),
            })
        end)

      end)

    end)

  end)

  describe('_compute_next_button_state', function ()

    it('was released & now up => released', function ()
      assert.are_equal(btn_states.released,
        input:_compute_next_button_state(btn_states.released, false))
    end)

    it('was released & now down => just pressed', function ()
      assert.are_equal(btn_states.just_pressed,
        input:_compute_next_button_state(btn_states.released, true))
    end)

    it('was just_pressed & now up => just_released', function ()
      assert.are_equal(btn_states.just_released,
        input:_compute_next_button_state(btn_states.just_pressed, false))
    end)

    it('was just_pressed & now down => pressed', function ()
      assert.are_equal(btn_states.pressed,
        input:_compute_next_button_state(btn_states.just_pressed, true))
    end)

    it('was pressed & now up => just_released', function ()
      assert.are_equal(btn_states.just_released,
        input:_compute_next_button_state(btn_states.pressed, false))
    end)

    it('was pressed & now down => pressed', function ()
      assert.are_equal(btn_states.pressed,
        input:_compute_next_button_state(btn_states.pressed, true))
    end)

    it('was just_released & now up => released', function ()
      assert.are_equal(btn_states.released,
        input:_compute_next_button_state(btn_states.just_released, false))
    end)

    it('was just_released & now down => just pressed', function ()
      assert.are_equal(btn_states.just_pressed,
        input:_compute_next_button_state(btn_states.just_released, true))
    end)

  end)

end)

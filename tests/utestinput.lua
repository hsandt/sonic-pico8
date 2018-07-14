require("bustedhelper")
local input = require("engine/input/input")

describe('input', function ()

  describe('generate_initial_button_states', function ()

    it('should return a table of released button states for each input key', function ()
      assert.are_same({
          [input.button_ids.left] = input.button_state.released,
          [input.button_ids.right] = input.button_state.released,
          [input.button_ids.up] = input.button_state.released,
          [input.button_ids.down] = input.button_state.released,
          [input.button_ids.o] = input.button_state.released,
          [input.button_ids.x] = input.button_state.released
        },
        generate_initial_button_states())
    end)

  end)

  describe('input.players_button_states', function ()

    it('should contain 2 tables of released button states, one per player', function ()
      assert.are_same({
          [0] = {
            [input.button_ids.left] = input.button_state.released,
            [input.button_ids.right] = input.button_state.released,
            [input.button_ids.up] = input.button_state.released,
            [input.button_ids.down] = input.button_state.released,
            [input.button_ids.o] = input.button_state.released,
            [input.button_ids.x] = input.button_state.released
          },
          [1] = {
            [input.button_ids.left] = input.button_state.released,
            [input.button_ids.right] = input.button_state.released,
            [input.button_ids.up] = input.button_state.released,
            [input.button_ids.down] = input.button_state.released,
            [input.button_ids.o] = input.button_state.released,
            [input.button_ids.x] = input.button_state.released
          }
        },
        input.players_button_states)
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
    input:toggle_mouse(true)
  end)

  teardown(function ()
    input:toggle_mouse(false)
  end)

  describe('get_cursor_position', function ()

    it('should return the current cursor position (sign test)', function ()
      local cursor_position = input.get_cursor_position()
      -- in headless mode, we cannot predict the mouse position
      -- (it seems to start at (0, 15097) but this may change)
      -- so we just do a simple sign test
      assert.is_true(cursor_position.x >= 0)
      assert.is_true(cursor_position.y >= 0)
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
      assert.spy(_process_player_inputs_stub).was_called_with(input, 0)
      assert.spy(_process_player_inputs_stub).was_called_with(input, 1)
    end)

  end)

  describe('_process_player_inputs', function ()

    after_each(function ()
      -- reset all button states
      clear_table(pico8.keypressed[0])
      clear_table(pico8.keypressed[1])

      input.players_button_states = {
        [0] = generate_initial_button_states(),
        [1] = generate_initial_button_states()
      }

      pico8.keypressed.counter = 0
    end)

    describe('(when player 0 has button left & up: released, right & down: just pressed, o & x: pressed)', function ()

      before_each(function ()
        input.players_button_states[0] = {
          [input.button_ids.left] = input.button_state.released,
          [input.button_ids.right] = input.button_state.just_pressed,
          [input.button_ids.up] = input.button_state.released,
          [input.button_ids.down] = input.button_state.just_pressed,
          [input.button_ids.o] = input.button_state.pressed,
          [input.button_ids.x] = input.button_state.pressed
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
            [input.button_ids.left] = input.button_state.released,
            [input.button_ids.right] = input.button_state.just_released,
            [input.button_ids.up] = input.button_state.just_pressed,
            [input.button_ids.down] = input.button_state.pressed,
            [input.button_ids.o] = input.button_state.just_released,
            [input.button_ids.x] = input.button_state.pressed
          },
          input.players_button_states[0])
      end)

    end)

    describe('(when player 1 has button left & up: released, right & down: just released, o & x: pressed)', function ()

      before_each(function ()
        input.players_button_states[1] = {
          [input.button_ids.left] = input.button_state.released,
          [input.button_ids.right] = input.button_state.just_released,
          [input.button_ids.up] = input.button_state.released,
          [input.button_ids.down] = input.button_state.just_released,
          [input.button_ids.o] = input.button_state.pressed,
          [input.button_ids.x] = input.button_state.pressed
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
            [input.button_ids.left] = input.button_state.released,
            [input.button_ids.right] = input.button_state.released,
            [input.button_ids.up] = input.button_state.just_pressed,
            [input.button_ids.down] = input.button_state.just_pressed,
            [input.button_ids.o] = input.button_state.just_released,
            [input.button_ids.x] = input.button_state.pressed
          },
          input.players_button_states[1])
      end)

    end)

    describe('(when button has just been pressed but is incorrect state because btnp counter is wrong)', function ()

      before_each(function ()
        input.players_button_states[0][input.button_ids.left] = input.button_state.released
        pico8.keypressed[0][input.button_ids.left] = true
        -- leave pico8.keypressed.counter at 0
      end)

      it('should update the different button states in parallel', function ()
        assert.has_error(function() input:_process_player_inputs(0) end)
      end)

    end)

  end)

  describe('_compute_next_button_state', function ()

    it('was released & now up => released', function ()
      assert.are_equal(input.button_state.released,
        input:_compute_next_button_state(input.button_state.released, false))
    end)

    it('was released & now down => just pressed', function ()
      assert.are_equal(input.button_state.just_pressed,
        input:_compute_next_button_state(input.button_state.released, true))
    end)

    it('was just_pressed & now up => just_released', function ()
      assert.are_equal(input.button_state.just_released,
        input:_compute_next_button_state(input.button_state.just_pressed, false))
    end)

    it('was just_pressed & now down => pressed', function ()
      assert.are_equal(input.button_state.pressed,
        input:_compute_next_button_state(input.button_state.just_pressed, true))
    end)

    it('was pressed & now up => just_released', function ()
      assert.are_equal(input.button_state.just_released,
        input:_compute_next_button_state(input.button_state.pressed, false))
    end)

    it('was pressed & now down => pressed', function ()
      assert.are_equal(input.button_state.pressed,
        input:_compute_next_button_state(input.button_state.pressed, true))
    end)

    it('was just_released & now up => released', function ()
      assert.are_equal(input.button_state.released,
        input:_compute_next_button_state(input.button_state.just_released, false))
    end)

    it('was just_released & now down => just pressed', function ()
      assert.are_equal(input.button_state.just_pressed,
        input:_compute_next_button_state(input.button_state.just_released, true))
    end)

  end)

end)

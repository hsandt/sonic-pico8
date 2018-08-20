require("bustedhelper")
require("game/ingame/playercharacter")
require("engine/core/math")

describe('player_character', function ()

  describe('_init', function ()

    it('should create a player character at the given position', function ()
      local player_character = player_character(vector(4, -4))
      assert.is_not_nil(player_character)
      assert.are_equal(vector(4, -4), player_character.position)
    end)

    it('should create a player character with 0 velocity and move_intention', function ()
      local player_character = player_character(vector(4, -4))
      assert.is_not_nil(player_character)
      assert.are_same({vector.zero(), vector.zero()},
        {player_character.velocity, player_character.move_intention})
    end)

    it('should create a player character with control mode: human and motion mode: platformer', function ()
      local player_character = player_character(vector(4, -4))
      assert.is_not_nil(player_character)
      assert.are_same({control_modes.human, motion_modes.platformer},
        {player_character.control_mode, player_character.motion_mode})
    end)

  end)

  describe('(with player character at (4, -4), speed 60, debug accel 480)', function ()
    local player_char

    setup(function ()
      player_char = player_character(vector(4, -4))
      player_char.debug_move_max_speed = 60.
      player_char.debug_move_accel = 480.
      player_char.debug_move_decel = 480.
    end)

    after_each(function ()
      player_char.control_mode = control_modes.human
      player_char.motion_mode = motion_modes.platformer
      player_char.position = vector(4, -4)
      player_char.velocity = vector(0, 0)
      player_char.move_intention = vector(0, 0)
    end)

    describe('_tostring', function ()
      it('should return "[player_character at vector(4, -4)]"', function ()
        assert.are_equal("[player_character at vector(4, -4)]", player_char:_tostring())
      end)
    end)

    describe('move', function ()
      it('at (4 -4) move (-5 4) => at (-1 0)', function ()
        player_char:move(vector(-5, 4))
        assert.are_equal(vector(-1, 0), player_char.position)
      end)
    end)

    describe('_update', function ()

      setup(function ()
        update_velocity_mock = stub(player_char, "_update_velocity", function (self)
          self.velocity = 11
        end)
        move_stub = stub(player_char, "move")
      end)

      teardown(function ()
        update_velocity_mock:revert()
        move_stub:revert()
      end)

      it('should call _update_velocity, then move using the new velocity', function ()
        player_char:update()
        assert.spy(update_velocity_mock).was_called()
        assert.spy(update_velocity_mock).was_called_with(match.ref(player_char))
        assert.spy(move_stub).was_called()
        assert.spy(move_stub).was_called_with(match.ref(player_char), 11 * delta_time)
      end)

    end)

    describe('_update_velocity', function ()

      local update_velocity_platformer_stub
      local update_velocity_debug_stub

      setup(function ()
        update_velocity_platformer_stub = stub(player_char, "_update_velocity_platformer")  -- native print
        update_velocity_debug_stub = stub(player_char, "_update_velocity_debug")  -- native print
      end)

      teardown(function ()
        update_velocity_platformer_stub:revert()
        update_velocity_debug_stub:revert()
      end)

      it('should call _update_velocity_platformer', function ()
        player_char:_update_velocity()
        assert.spy(update_velocity_platformer_stub).was_called()
        assert.spy(update_velocity_platformer_stub).was_called_with(match.ref(player_char))
      end)

      it('should call _update_velocity_debug', function ()
        player_char.motion_mode = motion_modes.debug
        player_char:_update_velocity()
        assert.spy(update_velocity_debug_stub).was_called()
        assert.spy(update_velocity_debug_stub).was_called_with(match.ref(player_char))
      end)

    end)

    describe('_update_velocity_platformer', function ()

      pending('should ...', function ()
        player_char:_update_velocity_platformer()
      end)

    end)

    describe('_update_velocity_debug', function ()

      local update_velocity_component_debug_stub

      setup(function ()
        update_velocity_component_debug_stub = stub(player_char, "_update_velocity_component_debug")  -- native print
      end)

      teardown(function ()
        update_velocity_component_debug_stub:revert()
      end)

      it('should call _update_velocity_component_debug on each component', function ()
        player_char:_update_velocity_debug()
        assert.spy(update_velocity_component_debug_stub).was_called(2)
        assert.spy(update_velocity_component_debug_stub).was_called_with(match.ref(player_char), "x")
        assert.spy(update_velocity_component_debug_stub).was_called_with(match.ref(player_char), "y")
      end)

    end)

    describe('_update_velocity_component_debug', function ()

      it('should accelerate when there is some input', function ()
        player_char.move_intention = vector(-1, 1)
        player_char:_update_velocity_component_debug("x")
        assert.is_true(almost_eq_with_message(
          vector(- player_char.debug_move_accel * delta_time, 0),
          player_char.velocity))
        player_char:_update_velocity_component_debug("y")
        assert.is_true(almost_eq_with_message(
          vector(- player_char.debug_move_accel * delta_time, player_char.debug_move_accel * delta_time),
          player_char.velocity))
      end)

    end)

    -- integration test as utest kept here for the moment, but prefer itests for this
    describe('_update_velocity_debug and move', function ()

      after_each(function ()
        player_char.move_intention = vector(-1, 1)
      end)

      it('when move intention is (-1, 1), update 1 frame => at (3.867 -3.867)', function ()
        player_char.move_intention = vector(-1, 1)
        player_char:_update_velocity_debug()
        player_char:move(player_char.velocity * delta_time)
        assert.is_true(almost_eq_with_message(vector(3.8667, -3.8667), player_char.position))
      end)

      it('when move intention is (-1, 1), update 11 frame => at (−2.73 2.73)', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector(-2.73, 2.73), player_char.position))
        assert.is_true(almost_eq_with_message(vector(-60, 60), player_char.velocity))  -- at max speed
      end)

      it('when move intention is (0, 0) after 11 frames, update 16 frames more => character should have decelerated', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        player_char.move_intention = vector.zero()
        for i=1,5 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector(-20, 20), player_char.velocity, 0.01))
      end)

      it('when move intention is (0, 0) after 11 frames, update 19 frames more => character should have stopped', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        player_char.move_intention = vector.zero()
        for i=1,8 do
          player_char:_update_velocity_debug()
          player_char:move(player_char.velocity * delta_time)
        end
        assert.is_true(almost_eq_with_message(vector.zero(), player_char.velocity))
      end)

    end)

    describe('render', function ()

      local spr_data_render_stub

      before_each(function ()
        spr_data_render_stub = stub(player_char.spr_data, "render")
      end)

      after_each(function ()
        spr_data_render_stub:revert()
      end)

      after_each(function ()
        spr_data_render_stub:clear()
      end)

      it('should call spr_data:render with the character\'s position', function ()
        player_char:render()
        assert.spy(spr_data_render_stub).was_called(1)
        assert.spy(spr_data_render_stub).was_called_with(match.ref(player_char.spr_data), player_char.position)
      end)
    end)

  end)

end)

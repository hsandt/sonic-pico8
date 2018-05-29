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


    describe('update_velocity_component', function ()

      it('should accelerate when there is some input', function ()
        player_char.move_intention = vector(-1, 1)
        player_char:update_velocity_component("x")
        assert.is_true(almost_eq_with_message(
          vector(- player_char.debug_move_accel * delta_time, 0),
          player_char.velocity))
        player_char:update_velocity_component("y")
        assert.is_true(almost_eq_with_message(
          vector(- player_char.debug_move_accel * delta_time, player_char.debug_move_accel * delta_time),
          player_char.velocity))
      end)

    end)

    describe('update ()', function ()

      after_each(function ()
        player_char.move_intention = vector(-1, 1)
      end)

      it('when move intention is (-1, 1), update 1 frame => at (3.867 -3.867)', function ()
        player_char.move_intention = vector(-1, 1)
        player_char:update()
        assert.is_true(almost_eq_with_message(vector(3.8667, -3.8667), player_char.position))
      end)

      it('when move intention is (-1, 1), update 11 frame => at (−2.73 2.73)', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:update()
        end
        assert.is_true(almost_eq_with_message(vector(-2.73, 2.73), player_char.position))
        assert.is_true(almost_eq_with_message(vector(-60, 60), player_char.velocity))  -- at max speed
      end)

      it('when move intention is (0, 0) after 11 frames, update 16 frames more => character should have decelerated', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:update()
        end
        player_char.move_intention = vector.zero()
        for i=1,5 do
          player_char:update()
        end
        assert.is_true(almost_eq_with_message(vector(-20, 20), player_char.velocity, 0.01))
      end)

      it('when move intention is (0, 0) after 11 frames, update 19 frames more => character should have stopped', function ()
        player_char.move_intention = vector(-1, 1)
        for i=1,10 do
          player_char:update()
        end
        player_char.move_intention = vector.zero()
        for i=1,8 do
          player_char:update()
        end
        assert.is_true(almost_eq_with_message(vector.zero(), player_char.velocity))
      end)

    end)

  end)

end)

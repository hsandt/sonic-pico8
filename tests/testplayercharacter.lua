picotest = require("picotest")
require("game/ingame/playercharacter")
require("engine/core/math")

function test_player_character(desc,it)

  desc('player_character:_init', function ()
    it('should create a player character with the right state', function ()
      -- test only passed parameters since we cannot access local data from the module
      local player_character = player_character(vector(4, -4))
      return player_character ~= nil,
        player_character ~= nil and player_character.position == vector(4, -4)
    end)
  end)

  desc('player_character:_tostring', function ()
    it('=> [player_character at vector(45comma 2)]', function ()
      local player_character = player_character(vector(45, 2))
      return player_character:_tostring() == "[player_character at vector(45, 2)]"
    end)
  end)

  desc('player_character:move', function ()
    it('at (4 -4) move (-5 4) => at (-1 0)', function ()
      local player_character = player_character(vector(4, -4))
      player_character:move(vector(-5, 4))
      return player_character.position == vector(-1, 0)
    end)
  end)

  desc('player_character:update', function ()

    local player_character = player_character(vector(4, -4))
    player_character.debug_move_max_speed = 60
    player_character.debug_move_accel = 480.
    player_character.debug_move_decel = 480.

    it('at (4 -4) intent (-1 1) spd 60 accel 480 update 1 => at (3.867 -3.867)', function ()
      player_character.move_intention = vector(-1, 1)
      player_character:update()
      return player_character.position:almost_eq(vector(3.8667, -3.8667))
    end)

    player_character.position = vector(4, -4)
    player_character.velocity = vector.zero()

    it('... update 10 frame => at (−2.73 2.73)', function ()
      player_character.move_intention = vector(-1, 1)
      for i=1,10 do
        player_character:update()
      end
      return player_character.position:almost_eq(vector(-2.73, 2.73)),
        player_character.velocity:almost_eq(vector(-60, 60))  -- at max speed
    end)

    it('from here no intent => character should have decelerated', function ()
      player_character.move_intention = vector(0, 0)
      for i=1,5 do
        player_character:update()
      end
      return almost_eq(player_character.velocity.x, -20, 0.01),
        almost_eq(player_character.velocity.y, 20, 0.01)
    end)

    it('sill no intent => character should have stopped', function ()
      player_character.move_intention = vector(0, 0)
      for i=1,3 do
        player_character:update()
      end
      return player_character.velocity:almost_eq(vector(0, 0))
    end)

  end)

end

add(picotest.test_suite, test_player_character)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('player_character', test_player_character)
end

-- empty update allows to close test window with ctrl+c
function _update()
end

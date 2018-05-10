picotest = require("picotest")
require("playercharacter")
require("math")

function test_player_character(desc,it)

  desc('player_character:_init', function ()
    it('should create a player character with the right state', function ()
      -- test only passed parameters since we cannot access local data from the module
      local player_character = player_character(vector(4, -4))
      return player_character ~= nil and player_character.position == vector(4, -4)
    end)
  end)

  desc('player_character:_tostring', function ()
    it('=> [player_character at vector(45comma 2)]', function ()
      -- test only passed parameters since we cannot access local data from the module
      local player_character = player_character(vector(45, 2))
      return player_character:_tostring() == "[player_character at vector(45, 2)]"
    end)
  end)

  desc('player_character:move', function ()
    it('at (4 -4) move (-5 4) => at (-1 0)', function ()
      -- test only passed parameters since we cannot access local data from the module
      local player_character = player_character(vector(4, -4))
      player_character:move(vector(-5, 4))
      return player_character.position == vector(-1, 0)
    end)
  end)

  desc('player_character:update', function ()
    it('at (4 -4) move intention (-5 4) speed 60 update 1 frame => at (-1 0)', function ()
      -- test only passed parameters since we cannot access local data from the module
      local player_character = player_character(vector(4, -4))
      player_character.debug_move_speed = 60
      player_character.move_intention = vector(-5, 4)
      player_character:update()
      return player_character.position:almost_eq(vector(-1, 0))
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

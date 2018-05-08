picotest = require("picotest")
require("playercharacter")
require("math")

function test_player_character(desc,it)

  desc('player_character._init', function ()
    it('should create a player character with the right state', function ()
      local player_character = player_character(vector(4, -4))
      return player_character ~= nil and player_character.position == vector(4, -4)
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

local gameapp = require("game/application/gameapp")

-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  gameapp.init()
end

function _update60()
  gameapp.update60()
end

function _draw()
  gameapp.draw()
end

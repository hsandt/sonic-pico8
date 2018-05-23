require("test")
require("game/application/gamestates")
credits = require("game/menu/credits")

describe('credits.state.type', function ()
  it('should be gamestate_types.credits', function ()
    assert.are_equal(gamestate_types.credits, credits.state.type)
  end)
end)

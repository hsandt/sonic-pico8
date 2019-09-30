require("engine/test/bustedhelper")
local gamestate_proxy = require("application/gamestate_proxy")

describe('gamestate_proxy', function ()

  after_each(function ()
    gamestate_proxy:init()
  end)

  describe('require_gamestates', function ()


    it('should require gamestates from the active_gamestates sequence', function ()
      gamestate_proxy:require_gamestates({"titlemenu", "stage"})

      -- implementation
      assert.are_same({
          titlemenu = require("menu/titlemenu"),
          credits = require("menu/credits_dummy"),
          stage = require("ingame/stage")
        },
        gamestate_proxy._state_modules)
    end)

  end)

  describe('get', function ()

    it('should assert if module_name is invalid or require_gamestates has not been called (member is nil)', function ()
      assert.has_error(function ()
          gamestate_proxy:get("invalid")
        end,
        "gamestate_proxy:get: self._state_modules['invalid'] is nil, make sure you have called gamestate_proxy:require_gamestates before")
    end)

  describe('(when modules have been required)', function ()

    before_each(function ()
      gamestate_proxy:require_gamestates({"titlemenu", "stage"})
    end)

      it('should return a dummy gamestate when require_gamestates has been called', function ()
        -- interface
        assert.are_same({
            require("menu/titlemenu").state,
            require("menu/credits_dummy").state,
            require("ingame/stage").state
          },
          {
            gamestate_proxy:get("titlemenu"),
            gamestate_proxy:get("credits"),
            gamestate_proxy:get("stage")
          })
      end)

    end)

  end)

end)

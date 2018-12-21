local gamestate = {}

gamestate.types = {
  titlemenu = 'titlemenu',
  credits = 'credits',
  stage = 'stage',
}

-- abstract gamestate singleton
-- type        string       gamestate type name
-- on_enter    function()   gamestate enter callback
-- on_exit     function()   gamestate exit callback
-- update      function()   gamestate update callback
-- render      function()   gamestate render callback

return gamestate

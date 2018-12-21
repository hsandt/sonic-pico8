require("engine/core/class")

coroutine_curry = new_class()

-- coroutine       thread     coroutine created with cocreate
-- ...             any        arguments to pass to coresume
function coroutine_curry:_init(coroutine, ...)
  self.coroutine = coroutine
  self.args = {...}  -- almost a lua table.pack, just without n = select("#", ...)
end

--#if log
function coroutine_curry:_tostring()
  return "[coroutine_curry] ("..costatus(self.coroutine)..") ("..joinstr_table(", ", self.args)..")"
end
--#endif

-- game application for states: titlemenu, credits
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local titlemenu = require("menu/titlemenu")
local credits = require("menu/credits")
local memory = require("resources/memory")

local picosonic_app_titlemenu = derived_class(picosonic_app_base)

function picosonic_app_titlemenu:instantiate_gamestates() -- override
  return {titlemenu(), credits()}
end

function picosonic_app_titlemenu:on_pre_start() -- override
  picosonic_app_base.on_pre_start(self)

  -- Immediately clear picked emerald data in persistent memory
  --  this is because we exploit persistent memory as cross-cartridge transient memory for now,
  --  general memory being used at 100% by ingame, but we don't want to make it really persistent
  --  across game launches, which means we go through the title menu, hence clearing data here
  -- Note that in practice, we dset memory before loading another cartridge/reloading ingame,
  --  then immediately consume the data with dget/dset(..., 0). So persistent memory is almost
  --  always cleared, the only way to keep it is to close the app during the cartridge loading
  --  (rotating cart animation). In this case, the statement below will be useful indeed.
--#ifn itest
  -- itests do not save (do not call cartdata), so do not call this to avoid error
  --  "dset called before cardata()"
  dset(memory.persistent_picked_emerald_index, 0)
--#endif
end

return picosonic_app_titlemenu

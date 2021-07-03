-- game application for state: stage
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local pc_data = require("data/playercharacter_data")
local stage_state = require("ingame/stage_state")

local picosonic_app_ingame = derived_class(picosonic_app_base)

function picosonic_app_ingame:instantiate_gamestates() -- override (mandatory)
  return {stage_state()}
end

-- made local (equivalent of file static in C++) so the static menuitem callback late_jump_feature_callback,
--  which doesn't take a self parameter, can access it without accessing singleton flow.curr_state.app...
-- this is OK because there is only one picosonic app (and seriously this could be a singleton anyway)
-- in counterpart, you need to provide a getter to it
local enable_late_jump_feature

function picosonic_app_ingame.get_enable_late_jump_feature()
  return enable_late_jump_feature
end

-- to allow circular referencing, we must declare the second function before defining it
local create_late_jump_feature_menuitem

local function late_jump_feature_callback(b)
  -- normally we should check bitmask with band/&, but to spare characters we exploit the undocumented
  --  fact that only the last button press mask is used
  if b == 1 or b == 2 then
    -- pressing left or right -> toggle feature
    enable_late_jump_feature = not enable_late_jump_feature

    -- update menuitem label (we have no choice but to recreate the whole menuitem)
    create_late_jump_feature_menuitem()

    -- don't close pause menu after that
    return true
  end
end

create_late_jump_feature_menuitem = function()
  -- create/replace menuitem to update the label, as PICO-8 doesn't have a native way to show a variable
  menuitem(1, "late jump: <"..(enable_late_jump_feature and " on" or "off")..">", late_jump_feature_callback)
end

function picosonic_app_ingame:on_post_start() -- override (optional)
  picosonic_app_base.on_post_start(self)

  -- Original feature: late jump
  -- Enable by default (see playercharacter_data > late_jump_max_delay)
  -- Note that it's not currently stored as player preference, so it resets each time you restart ingame
  enable_late_jump_feature = true
  create_late_jump_feature_menuitem()

  menuitem(3, "warp to start", function()
    assert(flow.curr_state.type == ':stage')
    flow.curr_state:store_picked_emerald_data()
    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_ingame')
  end)

  menuitem(4, "retry from zero", function()
    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_ingame')
  end)

  menuitem(5, "back to title", function()
    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_titlemenu')
  end)
end

return picosonic_app_ingame

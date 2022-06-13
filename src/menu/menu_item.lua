-- a single menu item leading to a gamestate on confirm
local menu_item = new_struct()

-- label: string                           text displayed in the menu
-- confirm_callback: function(gameapp)     callback applied when confirming item selection
-- select_callback: function(gameapp)|nil  optional callback applied when selecting item via navigation
function menu_item:init(label, confirm_callback, select_callback)
  self.label = label
  self.confirm_callback = confirm_callback
  self.select_callback = select_callback
end

return menu_item

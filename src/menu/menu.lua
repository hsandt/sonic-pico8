-- this script was copied and adapted from Wit Fighter
-- some leftovers like pagination are not used but kept in case
--  I add more menu items later (e.g. Sonic 2 use pagination for the VS menu)
-- for now only the page arrows are not drawn, and related data doesn't exist

local input = require("engine/input/input")
local ui = require("engine/ui/ui")

local visual = require("resources/visual")

--[[
Class representing a menu with labels and arrow-based scrolling navigation

External references
  app               gameapp       game app, provided to ease object access in item callbacks

Instance parameters
  items_count_per_page      int         number of items displayed per page
  alignment                 alignments  text alignment to use for item display
  text_color                colors      item text color
  prev_page_arrow_offset    vector      where to draw previous/next page arrow
                                        from top-left (in left alignment) or
                                        top-center (in center alignment)
                                        next page arrow is drawn symmetrically

Instance dynamic parameters
  items             {menu_item}   sequence of items to display

Instance state
  active                    bool        if true, the text menu is shown and receives input
  selection_index           int         index of the item currently selected
  anim_time                 float       time elapsed since showing items, modulo anim period
  prev_page_arrow_extra_y   float       animated y property to add to arrow offset
                                        next page arrow is drawn symmetrically
--]]

local menu = new_class()
function menu:_init(app, items_count_per_page, alignment, text_color, prev_page_arrow_offset)
  -- external references
  self.app = app

  -- parameters
  self.items_count_per_page = items_count_per_page
  self.alignment = alignment
  self.text_color = text_color
  self.prev_page_arrow_offset = prev_page_arrow_offset or vector.zero()

  -- dynamic parameters (set once per menu prompt)
  self.items = {}

  -- state
  self.active = false
  self.selection_index = 0

  -- visual state
  self.anim_time = 0
  self.prev_page_arrow_extra_y = 0
end

-- idea: make a uniform_action_menu which takes a single function,
--   and one generic parameter (or more) per item, and always calls
--   the function(parameter) on confirm, since most menus apply the same function

-- Activate the menu, fill items with given sequence and initialise selection
--
-- We deep copy the sequence content to avoid referencing the passed sequence,
--   which may change later.
function menu:show_items(items)
  assert(#items > 0)
  self.active = true

  -- deep copy of menu items to be safe on future change
  clear_table(self.items)
  for item in all(items) do
    add(self.items, item:copy())
  end

  -- we prefer direct calls to change_selection() because the latter would not call
  --   try_select_callback if the index was already 1 on the previously shown items
  --   (and we didn't clear), and we don't want to call on_selection_changed either
  self.selection_index = 1
  self:try_select_callback(1)

  -- visual
  self.anim_time = 0
  self.prev_page_arrow_extra_y = 0
end

-- deactivate the menu and remove items
function menu:clear(items)
  self.active = false
  clear_table(self.items)
  -- raw set instead of self:set_selection/change_selection(0) which have side effects
  self.selection_index = 0
end

-- handle navigation input
function menu:update()
  if self.active then
    if input:is_just_pressed(button_ids.up) then
      self:select_previous()
    elseif input:is_just_pressed(button_ids.down) then
      self:select_next()
    elseif input:is_just_pressed(button_ids.o) then
      self:confirm_selection()
    end

    -- visual
    -- no vertical arrow graphics in pico-sonic, and no paginated menu for now anyway,
    -- so replaced visual_data.menu_arrow_anim_period with some number 2
    self.anim_time = (self.anim_time + self.app.delta_time) % 2
    local anim_time_ratio = self.anim_time / 2
    if anim_time_ratio < 0.5 then
      self.prev_page_arrow_extra_y = 0
    else
      self.prev_page_arrow_extra_y = -1  -- prev arrow goes up during anim
    end
  end
end

-- like set_selection, but also calls on_selection_changed
function menu:change_selection(index)
  if self.selection_index ~= index then
    self.selection_index = index
    self:try_select_callback(index)
    self:on_selection_changed()
  end
end

function menu:select_previous()
  -- clamp selection
  if self.selection_index > 1 then
    self:change_selection(self.selection_index - 1)
  end
end

function menu:select_next()
  -- clamp selection
  if self.selection_index < #self.items then
    self:change_selection(self.selection_index + 1)
  end
end

-- apply select callback for this item if any
-- unlike on_selection_changed, it is item-specific
function menu:try_select_callback(index)
  local select_callback = self.items[index].select_callback
  if select_callback then
    select_callback(self.app)
  end
end

function menu:on_selection_changed()  -- virtual
end

function menu:confirm_selection()
  -- just deactivate menu, so we can reuse the items later if menu is static
  -- (by setting self.active = true), else next time show_items to refill the items

  -- todo: not all menus should close after confirm! (think a sound test)
  --   so this should be true for prompt menus only, and we should have a generic
  --   confirm_selection method that only calls the callbacks
  self.active = false

  -- we must call the callback *after* deactivating the menu, in case it immediately
  -- shows new choices itself, so it is not hidden after filling the items
  self.items[self.selection_index].confirm_callback(self.app)

  -- callback
  self:on_confirm_selection()
end

function menu:on_confirm_selection()  -- virtual
end

-- render menu, starting at top y, with text centered on x
function menu:draw(x, top)
  local items = self.items

  if #items == 0 then
    return
  end

  assert(self.selection_index > 0, "self.selection_index is "..self.selection_index..", should be > 0")
  assert(self.selection_index <= #items, "self.selection_index is "..self.selection_index..", should be <= item count: "..#items)

  local y = top

  -- identify which page is currently shown from the current selection
  -- unlike other indices in Lua, page starts at 0
  local items_count_per_page = self.items_count_per_page
  local page_count = ceil(#items / items_count_per_page)
  local page_index0 = flr((self.selection_index - 1) / items_count_per_page)
  local first_index0 = page_index0 * items_count_per_page
  local last_index0 = min(first_index0 + items_count_per_page - 1, #items - 1)
  for i = first_index0 + 1, last_index0 + 1 do
    -- for current selection, surround with "> <" like this: "> selected item <"
    local label = items[i].label
    local item_x = x

    if i == self.selection_index then
      if self.alignment == alignments.left then
        label = "> "..label
      else  -- self.alignment is alignments.horizontal_center or alignments.center
        label = "> "..label.." <"
      end
    else
      -- if left aligned, move non-selected items to the right to align with selected item
       if self.alignment == alignments.left then
         item_x = item_x + 2 * character_width  -- "> " has 2 characters
       end
    end

    ui.print_aligned(label, item_x, y, self.alignment, self.text_color)
    y = y + character_height
  end

  -- only used if enter one of the blocks below,
  -- but precomputed as useful for both blocks
  local arrow_x = x + self.prev_page_arrow_offset.x

  -- if previous/next page exists, show arrow hint
  if page_index0 > 0 then
    -- show previous page arrow hint
    -- y offset of -2 to have 1px of space between text top and arrow
    local previous_arrow_y = top - 2 + self.prev_page_arrow_offset.y + self.prev_page_arrow_extra_y
    -- no vertical arrow graphics in pico-sonic, and no paginated menu for now anyway
    -- visual.sprite_data_t.previous_arrow:render(vector(arrow_x, previous_arrow_y))
  end
  if page_index0 < page_count - 1 then
    -- show next page arrow hint
    -- character_height * items_count_per_page already contains the extra 1px spacing from text bottom
    -- however, because partial sprites are not supported,
    --   flipping always occur relative to the central tile axis,
    --   and for a sprites with an odd height we need to add 1px offset y again
    -- unfortunately this means we are dependent on exact visual data here,
    --   but it wouldn't be needed if custom sprite size was supported
    -- make sure to reverse sign of all offsets to make arrow initial position and animation symmetrical on y
    local next_arrow_y = top + character_height * items_count_per_page - self.prev_page_arrow_offset.y - self.prev_page_arrow_extra_y + 1
    -- no vertical arrow graphics in pico-sonic, and no paginated menu for now anyway
    -- visual.sprite_data_t.previous_arrow:render(vector(arrow_x, next_arrow_y), false, --[[flip_y:]] true)
  end
end

return menu

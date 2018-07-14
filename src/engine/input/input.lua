require("engine/core/math")
-- require("engine/ui/ui")

local input = {
  active = true,          -- is global input active? true when playing, false during itests
  mouse_active = false    -- is the mouse specifically active? only useful when active is true
}

local mouse_devkit_address = 0x5f2d
local cursor_x_stat = 32
local cursor_y_stat = 33

input.button_ids = {
  left = 0,
  right = 1,
  up = 2,
  down = 3,
  o = 4,
  x = 5
}

input.button_state = {
  released = 0,
  just_pressed = 1,
  pressed = 2,
  just_released = 3
}

-- generate the initial button_states table for a player
function generate_initial_button_states()
  return {
    [input.button_ids.left] = input.button_state.released,
    [input.button_ids.right] = input.button_state.released,
    [input.button_ids.up] = input.button_state.released,
    [input.button_ids.down] = input.button_state.released,
    [input.button_ids.o] = input.button_state.released,
    [input.button_ids.x] = input.button_state.released
  }
end

-- button_states tables, indexed by played ID
input.players_button_states = {
  [0] = generate_initial_button_states(),
  [1] = generate_initial_button_states()
}

-- activate mouse devkit
function input:toggle_mouse(active)
  if active == nil then
    -- no argument => reverse value
    active = not self.mouse_active
  end
  value = active and 1 or 0
  self.mouse_active = active
  poke(mouse_devkit_address, value)
end

-- return the current cursor position
function input.get_cursor_position()
  return vector(stat(cursor_x_stat), stat(cursor_y_stat))
end

-- update button states for each player based on previous and current button states
function input:process_players_inputs()
  for player_id = 0, 1 do
    self:_process_player_inputs(player_id)
  end
end

-- update button states for a specific player based on previous and current button states
function input:_process_player_inputs(player_id)
  local button_states = self.players_button_states[player_id]
  for button_id, _ in pairs(button_states) do
    -- note that btnp should always return true when just pressed, but the reverse is not true because pico8
    -- has a repeat input feature, that we are not reproducing
    assert(button_states[button_id] ~= input.button_state.released and button_states[button_id] ~= input.button_state.just_released or
      not btn(button_id, player_id) or btnp(button_id, player_id), "input:_update_button_state: button "..button_id.." was released and is now pressed, but btnp("..button_id..") returns false")
    button_states[button_id] = self:_compute_next_button_state(button_states[button_id], btn(button_id, player_id))
  end
end

-- return the next button state of a button based on its previous dynamic state (stored) and current static state (pico8 input)
function input:_compute_next_button_state(previous_button_state, is_down)
  if previous_button_state == input.button_state.released then
    if is_down then
      return input.button_state.just_pressed
    end
  elseif previous_button_state == input.button_state.just_pressed then
    if is_down then
      return input.button_state.pressed
    else
      return input.button_state.just_released
    end
  elseif previous_button_state == input.button_state.pressed then
    if not is_down then
      return input.button_state.just_released
    end
  else  -- previous_button_state == input.button_state.just_released
    if is_down then
      return input.button_state.just_pressed
    else
      return input.button_state.released
    end
  end

  -- no change detected
  return previous_button_state
end

return input

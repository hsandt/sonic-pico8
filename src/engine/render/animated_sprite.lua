-- stateful animated sprite compounded of an animated_sprite_data table and an animation state
-- it can be used as component of an object rendered with some animation
-- for objects with a single animation, use a data table containing a single element
animated_sprite = new_class()

-- data_table        {string: animated_sprite_data}  table of animated sprite data, indexed by animation key (unique name)
-- playing           bool                            is the animation playing? false if the animation has reached the end and stopped
-- current_anim_key  string|nil                      key in data_table of animation currently played / paused, or nil if no animation is set at all
-- current_step      int|nil                         index of the current sprite shown in the animation sequence, starting at 1, or nil if no animation is set at all
-- local_frame       int|nil                         current frame inside the current step, starting at 0, or nil if no animation is set at all
function animated_sprite:_init(data_table)
  self.data_table = data_table
  self.playing = false
  self.current_anim_key = nil  -- the sprite will be invisible until we start an animation
  self.current_step = nil
  self.local_frame = nil
end

--#if log
function animated_sprite:_tostring()
  return "animated_sprite("..joinstr(", ", nice_dump(self.data_table, true), self.playing, self.current_anim_key, self.current_step, self.local_frame)..")"
end
--#endif

-- start animation with given key: string
function animated_sprite:play(anim_key)
  assert(self.data_table[anim_key] ~= nil, "animated_sprite:play: self.data_table['"..anim_key.."'] doesn't exist")
  self.playing = true
  self.current_anim_key = anim_key
  self.current_step = 1
  self.local_frame = 0
end

-- update the sprite animation
-- this must be called once per update at 60 fps, before the render phase
function animated_sprite:update()
  if self.playing then
    local anim_spr_data = self.data_table[self.current_anim_key]
    -- check if we have reached the end of this step
    if self.local_frame + 1 < anim_spr_data.step_frames then
      -- keep same sprite and increment local frame counter
      self.local_frame = self.local_frame + 1
    else
      -- end of step reached, check if there is another sprite afterward
      if self.current_step < #anim_spr_data.sprites then
        -- show next sprite and reset local frame counter
        self.current_step = self.current_step + 1
        self.local_frame = 0
      else
        -- end of last step reached, should we loop?
        if anim_spr_data.looping then
          -- continue playing from start
          self.current_step = 1
          self.local_frame = 0
        else
          -- stop playing
          self.playing = false
        end
      end
    end
  end
end

-- render the current sprite data with passed arguments
function animated_sprite:render(position, flip_x, flip_y)
  if self.current_anim_key then
    -- an animation is set, render even if not playing since we want to show the last frame
    --   of a non-looped anim as a still frame
    local anim_spr_data = self.data_table[self.current_anim_key]
    local current_sprite_data = anim_spr_data.sprites[self.current_step]
    current_sprite_data:render(position, flip_x, flip_y)
  end
end

return animated_sprite

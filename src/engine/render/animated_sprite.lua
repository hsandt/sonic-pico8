-- stateful animated sprite compounded of an animated_sprite_data and an animation state
-- can be used as component of an object rendered with some animation
-- data can be swept for another data to easily switch sprite animation
animated_sprite = new_class()

-- data          animated_sprite_data  associated data
-- playing       bool                  is the animation playing?
-- current_step  int                   index of the current sprite shown in the animation sequence, starting at 1
-- local_frame   int                   current frame inside the current step, starting at 0
function animated_sprite:_init(data)
  self.data = data
  self.playing = true
  self.current_step = 1
  self.local_frame = 0
end

--#if log
function animated_sprite:_tostring()
  return "animated_sprite("..joinstr(", ", self.data, self.playing, self.current_step, self.local_frame)..")"
end
--#endif

-- update the sprite animation
-- this must be called once per update at 60 fps, before the render phase
function animated_sprite:update()
  -- check if we have reached the end of this step
  if self.local_frame + 1 < self.data.step_frames then
    -- keep same sprite and increment local frame counter
    self.local_frame = self.local_frame + 1
  else
    -- end of step reached, check if there is another sprite afterward
    if self.current_step < #self.data.sprites then
      -- show next sprite and reset local frame counter
      self.current_step = self.current_step + 1
      self.local_frame = 0
    else
      -- end of last step reached, should we loop?
      if self.data.looping then
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

-- render the current sprite data with passed arguments
function animated_sprite:render(position, flip_x, flip_y)
  local current_sprite_data = self.data.sprites[self.current_step]
  current_sprite_data:render(position, flip_x, flip_y)
end



return animated_sprite
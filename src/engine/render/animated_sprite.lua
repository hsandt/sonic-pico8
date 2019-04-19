-- stateful animated sprite compounded of an animated_sprite_data and an animation state
-- can be used as component of an object rendered with some animation
animated_sprite = new_class()

-- data  animated_sprite_data  associated data
-- current_step  int           index of the current sprite shown in the animation sequence, starting at 1
-- local_frame   int           current frame inside the current step, starting at 0
function animated_sprite:_init(data)
  self.data = data
  self.current_step = 1
  self.local_frame = 0
end

--#if log
function animated_sprite:_tostring()
  return "animated_sprite("..joinstr(", ", self.data, self.current_step, self.local_frame)..")"
end
--#endif

return animated_sprite

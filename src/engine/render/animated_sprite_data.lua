-- struct containing data on animated sprite: sprite references and timing
animated_sprite_data = new_struct()

-- sprites      {sprite_data}  sequence of sprites to play in order
-- step_frames  int            how long a single sprite (step) is displayed, in frames
-- looping      bool           true iff animation should loop
function animated_sprite_data:_init(sprites, step_frames, looping)
  self.sprites = sprites
  self.step_frames = step_frames
  self.looping = looping or false
end

--#if log
function animated_sprite_data:_tostring()
  return "animated_sprite_data("..joinstr(", ", "["..#self.sprites.." sprites]", self.step_frames, self.looping)..")"
end
--#endif

return animated_sprite_data

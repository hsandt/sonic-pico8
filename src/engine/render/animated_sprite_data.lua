-- struct containing data on animated sprite: sprite references and timing
animated_sprite_data = new_struct()

-- sprites      {sprite_data}  sequence of sprites to play in order
-- step_frames  int            how long a single sprite (step) is displayed, in frames
-- looping      bool           true iff animation should loop
function animated_sprite_data:_init(sprites, step_frames, looping)
  assert(#sprites > 0)
  assert(step_frames > 0)
  self.sprites = sprites
  self.step_frames = step_frames
  if looping == nil then
    looping = false
  end
  self.looping = looping
end

-- factory function to create animated sprite data from a table
--   of sprite data, and a sequence of keys
function animated_sprite_data.create(sprite_data_table, sprite_keys, step_frames, looping)
  local sprites = {}
  for sprite_key in all(sprite_keys) do
    add(sprites, sprite_data_table[sprite_key])
  end
  return animated_sprite_data(sprites, step_frames, looping)
end

--#if log
function animated_sprite_data:_tostring()
  return "animated_sprite_data("..joinstr(", ", "["..#self.sprites.." sprites]", self.step_frames, self.looping)..")"
end
--#endif

return animated_sprite_data

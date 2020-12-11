local ui_animation = {}

-- helper: move drawable (position member, draw method) linearly along coord ("x" or "y")
--  from a to b over n frames
-- coord_offsets allow to offset drawables relatively to a and b while keeping drawable motions in sync
--  (coord_offsets list is indexed by index of drawable in drawables)
function ui_animation.move_drawables_on_coord_async(coord, drawables, coord_offsets, a, b, n)
  for frame = 1, n do
    yield()
    local alpha = frame / n

    for i, dr in ipairs(drawables) do
      dr.position:set(coord, (1 - alpha) * a + alpha * b + coord_offsets[i])
    end
  end
end

return ui_animation

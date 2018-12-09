require("engine/core/class")

local tilemap = new_struct()

-- content    {{int}}     2-dimensional sequence of tile ids, by row, then column
function tilemap:_init(content)
  self.content = content
end

return tilemap

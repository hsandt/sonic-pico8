require("engine/core/class")
-- engine > game reference to clean
require("game/data/tile_data")

local tilemap = new_struct()

-- content    {{int}}     2-dimensional sequence of tile ids, by row, then column
function tilemap:_init(content)
  self.content = content
end

-- load the content into the current map
function tilemap:load(content)
  clear_map()
  for i = 1, #self.content do
    local row = self.content[i]
    for j = 1, #row do
      mset(j - 1, i - 1, row[j])
    end
  end
end

return tilemap

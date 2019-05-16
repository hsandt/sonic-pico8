require("engine/core/class")

local tilemap = new_struct()

-- content    {{int}}     2-dimensional sequence of tile ids, by row, then column
function tilemap:_init(content)
  self.content = content
end

-- load the content into the current map
function tilemap:load(content)
  tilemap.clear_map()
  for i = 1, #self.content do
    local row = self.content[i]
    for j = 1, #row do
      mset(j - 1, i - 1, row[j])
    end
  end
end

-- clear map, using appropriate interface (pico8 or busted pico8api)
function tilemap.clear_map()
--#ifn pico8
  pico8:clear_map()
--#endif

--[[#pico8
  -- clear map data
  memset(0x2000, 0, 0x1000)
--#pico8]]
end

return tilemap

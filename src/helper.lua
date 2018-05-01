-- clear a table
function clear_table(t)
 for k in pairs(t) do
  t[k] = nil
 end
end

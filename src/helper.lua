-- clear a table
function clear_table(t)
 for k in pairs(t) do
  t[k] = nil
 end
end

-- unpack from munpack at https://gist.github.com/josefnpat/bfe4aaa5bbb44f572cd0
function unpack(t, from, to)
  from = from or 1
  to = to or #t
  if from > to then return end
  return t[from], unpack(t, from+1, to)
end

function tostring(value)
  if type(value) == "table" and value._tostring then
    return value:_tostring()
  else
    return tostr(value)
  end
end

-- circular buffer implementation. useful to represent fixed size queue
--   adapted from https://gist.github.com/johndgiese/3e1c6d6e0535d4536692
-- we are defining our own __eq, don't need copy and may contain reference
-- to fully-fledged objects, so we don't use a struct
circular_buffer = new_class()

-- params
-- max_length      int       max length of the buffer
-- state vars
-- _buffer          [any]    data content, with length at most max_length
-- _start_index    into      index of the oldest inserted entry, and where the circular buffer semantically starts
function circular_buffer:_init(max_length)
  assert(max_length >= 1, "circular_buffer:_init: max_length must be a positive integer")
  self.max_length = max_length
  self._buffer = {}
  self._start_index = 1
end

--#if log
function circular_buffer:_tostring()
  return "circular_buffer("..self.max_length..", {"..joinstr_table(", ", self._buffer).."})"
end
--#endif

-- two circular buffers are considered equal when they have the same max length,
--  the same buffer size and their reordered content is the same
-- this means two circular buffers may be equal if their contents are circularly
--  the same, but the start index is different
-- if you want to compare a buffer content to a sequence of arbitrary size,
--  you'll need to examine self._buffer itself
function circular_buffer.__eq(lhs, rhs)
  if not (getmetatable(lhs) == getmetatable(rhs) and
    lhs.max_length == rhs.max_length and
    #lhs._buffer == #rhs._buffer) then
    return false
  end
  for i = 1, #lhs._buffer do
    -- rely on get to rotate correctly
    if lhs:get(i) ~= rhs:get(i) then
      return false
    end
  end
  return true
end

function circular_buffer:__len()
    return #(self._buffer)
end

function circular_buffer:__ipairs()
  -- return iterator function, table, and starting point
  return self._stateless_iter, self, 0
end

function circular_buffer:_stateless_iter(i)
  i = i + 1
  local v = self:get(i)
  if v then return i, v end
end

function circular_buffer._rotate_indice(i, n)
    return ((i - 1) % n) + 1
end

-- positive values index from oldest to newest, in normal sense (starting with 1)
-- negative values index from newest to oldest, in reverse sense (starting with -1)
function circular_buffer:get(i)
    local history_length = #(self._buffer)
    if i == 0 or math.abs(i) > history_length then
        return nil
    elseif i > 0 then
        local i_rotated = self._rotate_indice(self._start_index - 1 + i, history_length)
        return self._buffer[i_rotated]
    else  -- i < 0
        -- i is increasing in the negative sense, so it's really +i
        local i_rotated = self._rotate_indice(self._start_index + i, history_length)
        return self._buffer[i_rotated]
    end
end

function circular_buffer:is_filled()
    return #self._buffer == self.max_length
end

-- push a new element to the buffer and return true iff an old element was replaced
function circular_buffer:push(value)
    if self:is_filled() then
        local value_to_be_removed = self._buffer[self._start_index]
        self._buffer[self._start_index] = value
        self._start_index = self._start_index == self.max_length and 1 or self._start_index + 1
        return true
    else
        self._buffer[#(self._buffer) + 1] = value
        return false
    end
end

function circular_buffer:clear(value)
  clear_table(self._buffer)
  self._start_index = 1
end

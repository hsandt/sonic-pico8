require("engine/test/bustedhelper")
require("engine/core/datastruct")

describe('circular_buffer', function ()

  describe('_init', function ()

    it('should create an empty circular buffer with given max length', function ()
      local cb = circular_buffer(3)
      -- interface
      assert.is_not_nil(cb)
      assert.are_equal(0, #cb)
      -- implementation
      assert.are_equal(3, cb.max_length)
      assert.are_same({}, cb._buffer)
      assert.are_equal(1, cb._start_index)
    end)

    describe('_tostring', function ()

      it('should return circular_buffer({self,max_length}, {} for an empty buffer)', function ()
        local cb = circular_buffer(3)
        assert.are_equal("circular_buffer(3, {})", cb:_tostring())
      end)

      it('should return circular_buffer({self,max_length}, {content, ...})', function ()
        local cb = circular_buffer(3)
        cb:push(1)
        cb:push(2)
        cb:push(10)
        assert.are_equal("circular_buffer(3, {1, 2, 10})", cb:_tostring())
      end)

    end)

  end)

  describe('__eq', function ()

    it('should return true when the buffer have exactly the same content for the same max length', function ()
      local cb1 = circular_buffer(3)
      cb1:push(1)
      cb1:push(2)
      cb1:push(10)
      local cb2 = circular_buffer(3)
      cb2:push(1)
      cb2:push(2)
      cb2:push(10)
      assert.is_true(cb1:__eq(cb2))
    end)

    it('should return true when the buffer have the same circular content for the same max length', function ()
      local cb1 = circular_buffer(3)
      cb1:push(1)
      cb1:push(2)
      cb1:push(10)
      local cb2 = circular_buffer(3)
      cb2:push(999)
      cb2:push(999)
      cb2:push(1)
      cb2:push(2)
      cb2:push(10)
      assert.is_true(cb1:__eq(cb2))
    end)

    it('should return false when the contents are different for the same buffer size', function ()
      local cb1 = circular_buffer(3)
      cb1:push(1)
      cb1:push(2)
      cb1:push(10)
      local cb2 = circular_buffer(3)
      cb2:push(1)
      cb2:push(2)
      cb2:push(999)
      assert.is_false(cb1:__eq(cb2))
    end)

    it('should return false when the buffer sizes are different', function ()
      local cb1 = circular_buffer(4)
      cb1:push(1)
      cb1:push(2)
      cb1:push(10)
      local cb2 = circular_buffer(4)
      cb2:push(1)
      cb2:push(2)
      cb2:push(10)
      cb2:push(999)
      assert.is_false(cb1:__eq(cb2))
    end)

    it('should return false when the max lengths are different', function ()
      local cb1 = circular_buffer(3)
      cb1:push(1)
      cb1:push(2)
      cb1:push(10)
      local cb2 = circular_buffer(4)
      cb2:push(1)
      cb2:push(2)
      cb2:push(10)
      cb2:push(999)
      assert.is_false(cb1:__eq(cb2))
    end)

    it('should return false when the other member is not a circular buffer', function ()
      local cb1 = circular_buffer(3)
      cb1:push(1)
      cb1:push(2)
      cb1:push(10)
      local cb2 = {
        max_length = 3,
        buffer = {1, 2, 10},
        get = function (self, i)
            -- circular_buffer.__eq won't even try to compare cb1 and cb2,
            -- so this will actually never be called
            return self._buffer[i]
          end
      }
      assert.is_false(cb1:__eq(cb2))
    end)

  end)

  describe('__len', function ()

    it('#(^) => 0', function ()
      local cb = circular_buffer(2)
      assert.are_equal(0, #cb)
    end)

    it('#(^1, 2) => 2', function ()
    local cb = circular_buffer(2)
      cb:push(1)
      cb:push(2)
      assert.are_equal(2, #cb)
    end)

    it('#(3, ^2) => 2', function ()
    local cb = circular_buffer(2)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      assert.are_equal(2, #cb)
    end)

  end)

  describe('__ipairs', function ()

    it('(^): no iteration at all', function ()
      local cb = circular_buffer(2)
      for i, v in ipairs(cb) do
        -- should never be called
        assert.is_true(false)
      end
    end)

    it('(^1): 1 iteration', function ()
      local cb = circular_buffer(2)
      cb:push(10)
      local count = 0
      local result_ipairs = {}
      for i, v in ipairs(cb) do
        count = count + 1
        result_ipairs[count] = {i, v}
      end
      assert.are_same({{1, 10}}, result_ipairs)
    end)

    it('(4, ^2, 3): iterate 3 times from 2 to 4, cycling', function ()
      local cb = circular_buffer(3)
      cb:push(10)
      cb:push(20)
      cb:push(30)
      cb:push(40)
      local count = 0
      local result_ipairs = {}
      for i, v in ipairs(cb) do
        count = count + 1
        result_ipairs[count] = {i, v}
      end
      assert.are_same({{1, 20}, {2, 30}, {3, 40}}, result_ipairs)
    end)

  end)

  describe('_stateless_iter', function ()

    it('(^):_stateless_iter() => nil', function ()
      local cb = circular_buffer(2)
      assert.is_nil(cb:_stateless_iter(0))
    end)

    it('(^1):_stateless_iter() => 1, nil', function ()
      local cb = circular_buffer(2)
      cb:push(1)
      assert.are_same({1, 1}, {cb:_stateless_iter(0)})
      assert.is_nil(cb:_stateless_iter(1))
    end)

    it('(4, ^2, 3):_stateless_iter() => 2, 3, 4, nil', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      cb:push(4)
      assert.are_same({1, 2}, {cb:_stateless_iter(0)})
      assert.are_same({2, 3}, {cb:_stateless_iter(1)})
      assert.are_same({3, 4}, {cb:_stateless_iter(2)})
      assert.is_nil(cb:_stateless_iter(3))
    end)

  end)

  describe('_rotate_indice', function ()

    it('_rotate_indice(-2, 3) => 1', function ()
      assert.are_equal(1, circular_buffer._rotate_indice(-2, 3))
    end)

    it('_rotate_indice(-1, 3) => 2', function ()
      assert.are_equal(2, circular_buffer._rotate_indice(-1, 3))
    end)

    it('_rotate_indice(0, 3) => 3', function ()
      assert.are_equal(3, circular_buffer._rotate_indice(0, 3))
    end)

    it('_rotate_indice(1, 3) => 1', function ()
      assert.are_equal(1, circular_buffer._rotate_indice(1, 3))
    end)

    it('_rotate_indice(2, 3) => 2', function ()
      assert.are_equal(2, circular_buffer._rotate_indice(2, 3))
    end)

    it('_rotate_indice(3, 3) => 3', function ()
      assert.are_equal(3, circular_buffer._rotate_indice(3, 3))
    end)

    it('_rotate_indice(4, 3) => 1', function ()
      assert.are_equal(1, circular_buffer._rotate_indice(4, 3))
    end)

  end)

  describe('get (oldest indicated by ^)', function ()

    it('(^1, 2, 3):get(1) => 1', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      assert.are_equal(1, cb:get(1))
    end)

    it('(^1, 2, 3):get(3) => 3', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      assert.are_equal(3, cb:get(3))
    end)

    it('(4, ^2, 3):get(1) => 2', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      cb:push(4)
      assert.are_equal(2, cb:get(1))
    end)

    it('(4, ^2, 3):get(3) => 4', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      cb:push(4)
      assert.are_equal(4, cb:get(3))
    end)

    it('(^1, 2):get(-1) => 2', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      assert.are_equal(2, cb:get(-1))
    end)

    it('(^1, 2):get(-2) => 1', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      assert.are_equal(1, cb:get(-2))
    end)

    it('(4, ^2, 3):get(-1) => 4', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      cb:push(4)
      assert.are_equal(4, cb:get(-1))
    end)

    it('(^1, 2, 3):get(0) => nil', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      assert.is_nil(cb:get(0))
    end)

    it('(^1, 2, 3):get(4) => nil', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      assert.is_nil(cb:get(4))
    end)

    it('(^1, 2, 3):get(-4) => nil', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(3)
      assert.is_nil(cb:get(-4))
    end)

  end)

  describe('is_filled', function ()

    it('should return true when the max length has been reached', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(10)
      assert.is_true(cb:is_filled())
    end)

    it('should return true when the max length has been reached and some data overriden', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      cb:push(10)
      cb:push(999)
      assert.is_true(cb:is_filled())
    end)

    it('should return false when the buffer is empty', function ()
      local cb = circular_buffer(3)
      assert.is_false(cb:is_filled())
    end)

    it('should return false when the buffer has some elements but max length is not reached', function ()
      local cb = circular_buffer(3)
      cb:push(1)
      cb:push(2)
      assert.is_false(cb:is_filled())
    end)

  end)

  describe('push', function ()

    local cb = circular_buffer(3)

    after_each(function ()
      cb:clear()
    end)

    describe('(when buffer is empty)', function ()

      it('should add a new element at index 1', function ()
        local has_replaced = cb:push(1)
        -- interface
        assert.is_false(has_replaced)
        assert.are_equal(1, #cb)
        assert.are_equal(1, cb:get(1))
        -- implementation
        assert.are_same({1}, cb._buffer)
        assert.are_equal(1, cb._start_index)
      end)

    end)

    describe('(when buffer has some entries but is not full)', function ()

      setup(function ()
        cb:push(1)
        cb:push(2)
      end)

      it('should add a new element at the next index', function ()
        local has_replaced = cb:push(3)
        -- interface
        assert.is_false(has_replaced)
        assert.are_equal(3, #cb)
        assert.are_equal(1, cb:get(1))
        assert.are_equal(2, cb:get(2))
        assert.are_equal(3, cb:get(3))
        -- implementation
        assert.are_same({1, 2, 3}, cb._buffer)
        assert.are_equal(1, cb._start_index)
      end)

    end)

    describe('(when buffer is full)', function ()

      setup(function ()
        cb:push(1)
        cb:push(2)
        cb:push(3)
      end)

      it('should replace the oldest element, moving oldest to the next element ', function ()
        local has_replaced = cb:push(4)
        -- interface
        assert.is_true(has_replaced)
        assert.are_equal(3, #cb)
        assert.are_equal(2, cb:get(1))
        assert.are_equal(3, cb:get(2))
        assert.are_equal(4, cb:get(3))
        -- implementation
        assert.are_same({4, 2, 3}, cb._buffer)
        assert.are_equal(2, cb._start_index)
      end)

    end)

    describe('(when buffer is full again)', function ()

      setup(function ()
        cb:push(1)
        cb:push(2)
        cb:push(3)
        cb:push(4)
        cb:push(5)
        cb:push(6)
      end)

      it('should replace the 1st, oldest element again, moving oldest to the next element ', function ()
        local has_replaced = cb:push(7)
        -- interface
        assert.is_true(has_replaced)
        assert.are_equal(3, #cb)
        assert.are_equal(5, cb:get(1))
        assert.are_equal(6, cb:get(2))
        assert.are_equal(7, cb:get(3))
        -- implementation
        assert.are_same({7, 5, 6}, cb._buffer)
        assert.are_equal(2, cb._start_index)
      end)

    end)

  end)

  describe('clear', function ()

    describe('(when buffer is empty)', function ()

      it('should do nothing', function ()
        local cb = circular_buffer(3)
        cb:clear()
        -- interface
        assert.are_equal(0, #cb)
        -- implementation
        assert.are_same({}, cb._buffer)
        assert.are_equal(1, cb._start_index)
      end)

    end)

    describe('(when buffer has some entries but is not full)', function ()

      it('should clear the elements and oldest index', function ()
        local cb = circular_buffer(3)
        cb:push(1)
        cb:clear()
        -- interface
        assert.are_equal(0, #cb)
        -- implementation
        assert.are_same({}, cb._buffer)
        assert.are_equal(1, cb._start_index)
      end)

    end)

    describe('(when buffer is full)', function ()

      it('should clear all elements and oldest index', function ()
        local cb = circular_buffer(3)
        cb:push(1)
        cb:push(2)
        cb:push(3)
        cb:clear()
        -- interface
        assert.are_equal(0, #cb)
        -- implementation
        assert.are_same({}, cb._buffer)
        assert.are_equal(1, cb._start_index)
      end)

    end)

  end)

end)

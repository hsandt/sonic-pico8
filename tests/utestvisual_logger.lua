require("bustedhelper")
local visual_logger = require("engine/debug/visual_logger")
local logging = require("engine/debug/logging")
local wtk = require("engine/wtk/pico8wtk")

describe('visual_logger', function ()

  local log_message = logging.log_message
  local logger = logging.logger
  local window = visual_logger.window

  describe('window (with buffer size 3)', function ()

    local old_buffer_size

    setup(function ()
      -- to make sure that we control buffer size in test code,
      -- we set it here and reinit the visual logger window
      old_buffer_size = visual_logger.buffer_size
      visual_logger.buffer_size = 3
      window:init()
    end)

    teardown(function ()
      visual_logger.buffer_size = old_buffer_size
      window:init()
    end)

    after_each(function ()
      window:init()
    end)

    describe('init', function ()

      it('should initialize a message queue of size 3', function ()
        -- implementation
        assert.are_equal(3, window._message_queue.max_length)
        assert.are_equal(0, #window._message_queue)
      end)

      it('should create a vertical layout to put the messages in', function ()
        assert.are_equal(1, #window.gui.children)
        assert.are_equal(wtk.vertical_layout, getmetatable(window.gui.children[1]))
      end)
    end)

    describe('push_message', function ()

      local message_queue

      setup(function ()
        spy.on(window, "_on_message_pushed")
        spy.on(window, "_on_message_popped")
      end)

      teardown(function ()
        window._on_message_pushed:revert()
        window._on_message_popped:revert()
      end)

      before_each(function ()
        -- we don't clear the _message_queue but rather reconstruct it on each test in init()
        -- therefore a new instance is created each time and we need to respy that new instance
        message_queue = window._message_queue
        spy.on(message_queue, "push")
      end)

      after_each(function ()
        message_queue.push:revert()  -- just in case
      end)

      describe('(when queue is empty)', function ()

        it('#solo should push a message to queue and vertical layout', function ()
          local lm = log_message(logging.level.info, "flow", "enter stage state")
          window:push_message(lm)
          assert.spy(message_queue.push).was_called(1)
          assert.spy(message_queue.push).was_called_with(match.ref(window._message_queue), lm)
          assert.spy(window._on_message_pushed).was_called(1)
          assert.spy(window._on_message_pushed).was_called_with(match.ref(window), lm)
          assert.spy(window._on_message_popped).was_not_called()
        end)

      end)

      describe('(when queue has 2 entries (not full))', function ()

        before_each(function ()
          window:push_message(log_message(logging.level.info, "flow", "enter stage state"))
          window:push_message(log_message(logging.level.warning, "player", "player character spawner"))
          message_queue.push:clear()
          window._on_message_pushed:clear()
          window._on_message_popped:clear()
        end)

        it('should push a message to queue and vertical layout', function ()
          local lm = log_message(logging.level.warning, "default", "danger")
          window:push_message(lm)

          assert.spy(message_queue.push).was_called(1)
          assert.spy(message_queue.push).was_called_with(match.ref(message_queue), lm)
          assert.spy(window._on_message_pushed).was_called(1)
          assert.spy(window._on_message_pushed).was_called_with(match.ref(window), lm)
          assert.spy(window._on_message_popped).was_not_called()
        end)

      end)

      describe('(when queue has 3 entries (full))', function ()

        before_each(function ()
          for i = 1, visual_logger.buffer_size do
            window:push_message(log_message(logging.level.info, "flow", "enter stage state"))
          end
          message_queue.push:clear()
          window._on_message_pushed:clear()
          window._on_message_popped:clear()
        end)

        it('should push a message to queue and vertical layout, detect overwriting and pop the oldest label', function ()
          local lm = log_message(logging.level.warning, "default", "danger")
          window:push_message(lm)

          assert.spy(message_queue.push).was_called(1)
          assert.spy(message_queue.push).was_called_with(match.ref(message_queue), lm)
          assert.spy(window._on_message_pushed).was_called(1)
          assert.spy(window._on_message_pushed).was_called_with(match.ref(window), lm)
          assert.spy(window._on_message_popped).was_called(1)
          assert.spy(window._on_message_popped).was_called_with(match.ref(window))
        end)

      end)

    end)

    describe('_on_message_pushed', function ()

      local add_child_stub = stub(window.v_layout, "add_child")

      setup(function ()
        add_child_stub = stub(window.v_layout, "add_child")
      end)

      teardown(function ()
        add_child_stub:revert()
      end)

      it('should call add_label with a white label([{category}] {message})', function ()
        window:_on_message_pushed(log_message(logging.level.info, "flow", "enter stage state"))

        local log_label = wtk.label.new("[flow] enter stage state", colors.white)
        assert.spy(add_child_stub).was_called(1)
        assert.spy(add_child_stub).was_called_with(match.ref(window.v_layout), log_label)
      end)

    end)

    describe('_on_message_popped', function ()

      local remove_child_stub

      setup(function ()
        -- add a message to avoid assertion in _on_message_popped
        window:_on_message_pushed(log_message(logging.level.info, "flow", "enter stage state"))

        remove_child_stub = stub(window.v_layout, "remove_child")
      end)

      teardown(function ()
        remove_child_stub:revert()
      end)

      it('should call add_label with a white label([{category}] {message})', function ()
        window:_on_message_popped()
        assert.spy(remove_child_stub).was_called(1)
        assert.spy(remove_child_stub).was_called_with(match.ref(window.v_layout), window.v_layout.children[1])
      end)

    end)

  end)

  describe('visual_log_stream', function ()

    local push_message_stub

    setup(function ()
      push_message_stub = stub(window, "push_message")
    end)

    teardown(function ()
      push_message_stub:revert()
    end)

    it('should call window.push_message', function ()
      local lm = log_message(logging.level.info, "flow", "enter stage state")
      visual_logger.visual_log_stream:on_log(lm)
      assert.spy(push_message_stub).was_called(1)
      assert.spy(push_message_stub).was_called_with(match.ref(window), lm)
    end)

  end)

end)

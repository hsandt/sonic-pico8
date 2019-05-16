require("engine/test/bustedhelper")
local wtk = require("engine/wtk/pico8wtk")

describe('wtk', function ()

  describe('vertical_layout', function ()

    describe('new', function ()

      it('should create a new vertical layout', function ()
        local vl = wtk.vertical_layout.new(10, 3)
        assert.is_not_nil(vl)
        assert.are_equal(10, vl.w)
        assert.are_equal(0, vl.h)
        assert.are_equal(3, vl.c)
      end)

    end)

    describe('add_child', function ()

      local vl

      before_each(function ()
        vl = wtk.vertical_layout.new(10, 3)
      end)

      describe('(when no children)', function ()

        it('should add a child at the origin ', function ()
          local label = wtk.label.new("hello", 4)  -- width: 19, height: 5
          vl:add_child(label)

          assert.are_equal(1, #vl.children)
          assert.are_equal(label, vl.children[1])
          assert.are_same({0, 0}, {vl.children[1].x, vl.children[1].y})
        end)

        it('should expand size to the max width and by child height', function ()
          local label = wtk.label.new("hello", 4)  -- width: 19, height: 5
          vl:add_child(label)

          assert.are_equal(19, vl.w)
          assert.are_equal(5, vl.h)
        end)

      end)

      describe('(when some children)', function ()

        before_each(function ()
          local label = wtk.label.new("hello", 4)  -- width: 19, height: 5
          vl:add_child(label)
        end)

        it('should add a child under the previous one', function ()
          local label2 = wtk.label.new("hello again", 4)  -- width: 43, height: 5
          vl:add_child(label2)

          assert.are_equal(2, #vl.children)
          assert.are_equal(label2, vl.children[2])
          assert.are_same({0, 6}, {vl.children[2].x, vl.children[2].y})
        end)

        it('should expand size to the max width and by vertical padding + child height', function ()
          local label2 = wtk.label.new("hello again", 4)  -- width: 43, height: 5
          vl:add_child(label2)

          assert.are_equal(43, vl.w)
          assert.are_equal(11, vl.h)
        end)

        it('should adapt to new lines via label height', function ()
          local label2 = wtk.label.new("hello\nagain", 4)  -- width: 19, height: 11
          vl:add_child(label2)
          local label3 = wtk.label.new("more\nlines", 4)  -- width: 19, height: 11
          vl:add_child(label3)

          assert.are_equal(3, #vl.children)
          assert.are_equal(label2, vl.children[2])
          assert.are_same({0, 6}, {vl.children[2].x, vl.children[2].y})
          assert.are_equal(label3, vl.children[3])
          assert.are_same({0, 18}, {vl.children[3].x, vl.children[3].y})

          assert.are_equal(19, vl.w)
          assert.are_equal(29, vl.h)
        end)

      end)

    end)

    describe('remove_child', function ()

      local vl
      local widget_remove_child_stub

      setup(function ()
        widget_remove_child_stub = stub(wtk.widget, "remove_child")
      end)

      teardown(function ()
        widget_remove_child_stub:revert()
      end)

      before_each(function ()
        vl = wtk.vertical_layout.new(10, 3, 2)  -- padding of 2
      end)

      after_each(function ()
        widget_remove_child_stub:clear()
      end)

      it('should call base method implementation', function ()
        local some_icon = wtk.icon.new(2, 3)
        vl:remove_child(some_icon)
        assert.spy(widget_remove_child_stub).was_called(1)
        assert.spy(widget_remove_child_stub).was_called_with(vl, some_icon)
      end)

      it('should do nothing when trying to remove a non-child element (except unsetting its parent due to base method implementation)', function ()
        local icon_not_here = wtk.icon.new(2, 3)
        assert.has_no_errors(function ()
          vl:remove_child(icon_not_here)
        end)
      end)

      describe('(when some children)', function ()

        local label1, label2, label3, icon1, icon2

        before_each(function ()
          icon1 = wtk.icon.new(2, 3)  -- height: 8
          icon2 = wtk.icon.new(3, 4)  -- height: 8
          label1 = wtk.label.new("hello1", 4)  -- height: 5
          label2 = wtk.label.new("hello2", 4)  -- height: 5
          vl:add_child(icon1)   -- y: 0
          vl:add_child(icon2)   -- y: 9
          vl:add_child(label1)  -- y: 15
          vl:add_child(label2)  -- y: 21
        end)

        it('should move all children below that child up', function ()
          assert.are_same(
            {0,              10,       20,       27},
            {icon1.y, icon2.y, label1.y, label2.y})
          vl:remove_child(icon2)
          assert.are_same(
            {0,              10,       17},
            {icon1.y, label1.y, label2.y})
        end)

      end)

    end)

    describe('draw', function ()

      local rectfill_stub

      setup(function ()
        rectfill_stub = stub(_G, "rectfill")
      end)

      teardown(function ()
        rectfill_stub:revert()
      end)

      it('should call rectfill', function ()
        local vl = wtk.vertical_layout.new(10, 3)
        vl:draw(5, 8)
        assert.spy(rectfill_stub).was_called()
        assert.spy(rectfill_stub).was_called_with(5, 8, 14, 7, 3)
      end)

    end)

  end)

  describe('label', function ()

    describe('new', function ()

      it('should create a new label', function ()
        local label = wtk.label.new("fixed", 4)
        assert.are_equal(wtk.label, getmetatable(label))
      end)
      it('should create a new label with fixed text', function ()
        local label = wtk.label.new("fixed", 4)
        assert.are_equal("fixed", label.text)
      end)
      it('should create a new label with fixed text from concatenable type (at least on the right)', function ()
        local concatenable = {}
        setmetatable(concatenable, {__concat = function (lhs, rhs)
          return lhs.."100"
        end})
        local label = wtk.label.new(concatenable, 4)
        assert.are_equal("100", label.text)
      end)
      it('should create a new label with dynamic text method', function ()
        local text_callback = function () return "fixed dynamic text" end
        local label = wtk.label.new(text_callback, 4)
        assert.are_equal("fixed dynamic text", label.text())
      end)
      it('should create a new label with dynamic text method using self (not recommended because object it not fully created yet)', function ()
        local text_callback = function (self) return tostr(self.c) end
        local label = wtk.label.new(text_callback, 4)
        assert.are_equal("4", label:text())
      end)
      it('should create a new label with color 0 by default', function ()
        local label = wtk.label.new("fixed")
        assert.are_equal(0, label.c)
      end)
      it('should create a new label with color', function ()
        local label = wtk.label.new("fixed", 4)
        assert.are_equal(4, label.c)
      end)
      it('should create a new label with optional function that wants mouse', function ()
        local func = function () end
        local label = wtk.label.new("fixed", 4, func)
        assert.are_same({true, func}, {label.wants_mouse, label.func})
      end)
      it('should create a new label with width based on text', function ()
        local label = wtk.label.new("12345", 4)
        assert.are_same(19, label.w)
      end)
      it('should create a new label with height based on text', function ()
        local label = wtk.label.new("12345", 4)
        assert.are_same(5, label.h)
      end)
      it('should create a new label with width based on dynamic text method', function ()
        local text_callback = function (self) return "123"..tostr(self.c) end
        local label = wtk.label.new(text_callback, 4)
        assert.are_same(15, label.w)
      end)
      it('should create a new label with height based on dynamic text method', function ()
        local text_callback = function (self) return "123"..tostr(self.c) end
        local label = wtk.label.new(text_callback, 4)
        assert.are_same(5, label.h)
      end)
      it('should create a new label with width based on multiline text', function ()
        local label = wtk.label.new("shorter\nvery long string\nshort", 4)
        assert.are_same(63, label.w)
      end)
      it('should create a new label with height based on multiline text', function ()
        local label = wtk.label.new("shorter\nvery long string\nshort", 4)
        assert.are_same(17, label.h)
      end)

    end)

    describe('compute_size', function ()

      it('"" => 0, 5', function ()
        assert.are_same({0, 5}, {wtk.label.compute_size("")})
      end)
      it('"hello" => 19, 5', function ()
        assert.are_same({19, 5}, {wtk.label.compute_size("hello")})
      end)
      it('"hello\n" => 19, 11', function ()
        assert.are_same({19, 11}, {wtk.label.compute_size("hello\n")})
      end)
      it('"hello\nworld" => 23, 11', function ()
        assert.are_same({23, 11}, {wtk.label.compute_size("short\nlonger")})
      end)
      it('"hello\nworld" => 23, 11', function ()
        assert.are_same({23, 11}, {wtk.label.compute_size("longer\nshort")})
      end)
      it('"\n\n\n" => 0, 23', function ()
        assert.are_same({0, 23}, {wtk.label.compute_size("\n\n\n")})
      end)

    end)

  end)

end)

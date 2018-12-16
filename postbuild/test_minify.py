import unittest
from . import minify

from os import path
import shutil, tempfile


class TestMinify(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_clean_lua(self):
        lua_code = """if true then print("ok") end
if true then
  print("ok")
end
if (l[p]==nil) l[p]=package._c[p]()
if (l[p]==nil) l[p]=true

"""

        expected_clean_lua_code = """if true then print("ok") end
if true then
  print("ok")
end
if l[p]==nil then l[p]=package._c[p]() end
if l[p]==nil then l[p]=true end

"""
        lua_filepath = path.join(self.test_dir, 'lua.p8')
        clean_lua_filepath = path.join(self.test_dir, 'clean_lua.p8')
        with open(lua_filepath, 'w') as l:
            l.write(lua_code)

        with open(lua_filepath, 'r') as l, open(clean_lua_filepath, 'w') as cl:
            minify.clean_lua(l, cl)

        with open(clean_lua_filepath, 'r') as cl:
            self.assertEqual(cl.read(), expected_clean_lua_code)

    def test_inject_minified_lua_in_p8(self):
        source_text = """pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
package={loaded={},_c={}}
package._c["module"]=function()
require("another_module")
local long_name = 5
end
__gfx__
eeeeeeeee5eeeeeeeeee
__label__
55222222222222222222
__gff__
00000000000000000000
__map__
45454545eeeeeeeeeeee
__sfx__
010c00002d340293402d
__music__
01 00010203

"""

        min_lua_code = """package={loaded={},_c={}} package._c["module"]=function()require("another_module")local a=5 end"""

        expected_target_text = """pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
package={loaded={},_c={}} package._c["module"]=function()require("another_module")local a=5 end
__gfx__
eeeeeeeee5eeeeeeeeee
__label__
55222222222222222222
__gff__
00000000000000000000
__map__
45454545eeeeeeeeeeee
__sfx__
010c00002d340293402d
__music__
01 00010203

"""

        source_filepath = path.join(self.test_dir, 'source.p8')
        target_filepath = path.join(self.test_dir, 'target.p8')
        min_lua_filepath = path.join(self.test_dir, 'min_lua.lua')
        with open(source_filepath, 'w') as s:
            s.write(source_text)
        with open(min_lua_filepath, 'w') as l:
            l.write(min_lua_code)

        with open(source_filepath, 'r') as s, open(target_filepath, 'w') as t, open(min_lua_filepath, 'r') as l:
            minify.inject_minified_lua_in_p8(s, t, l)

        with open(target_filepath, 'r') as t:
            self.assertEqual(t.read(), expected_target_text)


if __name__ == '__main__':
    unittest.main()

# -*- coding: utf-8 -*-

# LEGACY: use test_preprocess.py to test preprocess.py in pico-boots now

import unittest
from . import replace_strings

import logging
from os import path
import shutil, tempfile


class TestParsing(unittest.TestCase):

    def test_parse_arg_substitutes(self):
        test_arg_substitutes = ['itest=character', 'optimization=3']
        self.assertEqual(replace_strings.parse_arg_substitutes(test_arg_substitutes), {'itest': 'character', 'optimization': '3'})

    def test_parse_arg_substitutes_parsing_error(self):
        test_arg_substitutes = ['itest character']
        self.assertRaises(ValueError, replace_strings.parse_arg_substitutes, test_arg_substitutes)


class TestReplaceStrings(unittest.TestCase):

    def test_replace_all_glyphs_in_string(self):
        test_string = '##d and ##x ##d'
        self.assertEqual(replace_strings.replace_all_glyphs_in_string(test_string), '⬇️ and ❎ ⬇️')

    def test_replace_all_symbols_in_string_function(self):
        test_string = 'api.print("hello")'
        self.assertEqual(replace_strings.replace_all_symbols_in_string(test_string), 'print("hello")')

    def test_replace_all_symbols_in_string_enum(self):
        test_string = 'local c = colors.dark_purple'
        self.assertEqual(replace_strings.replace_all_symbols_in_string(test_string), 'local c = 2')

    def test_replace_all_symbols_in_string_missing_member(self):
        test_string = 'local c = colors.unknown'
        # this will trigger a warning, hide by setting logging level to ERROR in main
        self.assertEqual(replace_strings.replace_all_symbols_in_string(test_string), 'local c = assert(false, "UNSUBSTITUTED colors.unknown")')

    def test_replace_all_args_in_string(self):
        test_string = 'require("itest_$itest")'
        self.assertEqual(replace_strings.replace_all_args_in_string(test_string, {'itest': 'character'}), 'require("itest_character")')

    def test_replace_default_args_in_string(self):
        test_string = 'require("titlemenu$titlemenu_ver")'
        self.assertEqual(replace_strings.replace_all_args_in_string(test_string, {}), 'require("titlemenu")')

    def test_replace_default_args_overridden_in_string(self):
        test_string = 'require("titlemenu$titlemenu_ver")'
        self.assertEqual(replace_strings.replace_all_args_in_string(test_string, {'titlemenu_ver': '_dummy'}), 'require("titlemenu_dummy")')


class TestReplaceStringsInFile(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_replace_strings(self):
        """^ Test replacing strings in a whole file, with substitutes being shorter or longer than original symbol to test if file is truncated"""
        test_filepath = path.join(self.test_dir, 'test.lua')
        with open(test_filepath, 'w', encoding='utf-8') as f:
            f.write('require("itest_$itest")\nrequire("$symbol_is_much_longer")\n##d or ##u\nand ##x\napi.print("press ##x")')
        replace_strings.replace_all_strings_in_file(test_filepath, {'itest': 'character', 'symbol_is_much_longer': 'short'})
        with open(test_filepath, 'r', encoding='utf-8') as f:
            self.assertEqual(f.read(), 'require("itest_character")\nrequire("short")\n⬇️ or ⬆️\nand ❎\nprint("press ❎")')

class TestReplaceStringsInDir(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_replace_all_strings_in_dir(self):
        test_filepath1 = path.join(self.test_dir, 'test1.lua')
        with open(test_filepath1, 'w', encoding='utf-8') as f:
            f.write('require("itest_$itest")\n##d or ##u\nand ##x\napi.print("press ##x")')
        test_filepath2 = path.join(self.test_dir, 'test2.lua')
        with open(test_filepath2, 'w', encoding='utf-8') as f:
            f.write('require("itest_$itest")\n##l or ##r\nand ##o\napi.print("press ##o")')
        replace_strings.replace_all_strings_in_dir(self.test_dir, {'itest': 'character'})
        with open(test_filepath1, 'r', encoding='utf-8') as f:
            self.assertEqual(f.read(), 'require("itest_character")\n⬇️ or ⬆️\nand ❎\nprint("press ❎")')
        with open(test_filepath2, 'r', encoding='utf-8') as f:
            self.assertEqual(f.read(), 'require("itest_character")\n⬅️ or ➡️\nand 🅾️\nprint("press 🅾️")')

if __name__ == '__main__':
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()

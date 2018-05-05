import unittest
from . import replace_glyphs

from os import path
import shutil, tempfile


class TestReplaceGlyphsInString(unittest.TestCase):

    def test_replace_glyphs_in_string(self):
        test_string = '##d and ##x ##d'
        self.assertEqual(replace_glyphs.replace_glyphs_in_string(test_string, 'd'), '⬇️ and ##x ⬇️')

    def test_replace_all_glyphs_in_string(self):
        test_string = '##d and ##x ##d'
        self.assertEqual(replace_glyphs.replace_all_glyphs_in_string(test_string), '⬇️ and ❎ ⬇️')


class TestReplaceGlyphsInFile(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_replace_glyphs(self):
        test_filepath = path.join(self.test_dir, 'test.txt')
        with open(test_filepath, 'w') as f:
            f.write('##d or ##u\nand ##x')
        replace_glyphs.replace_all_glyphs_in_file(test_filepath)
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), '⬇️ or ⬆️\nand ❎')

if __name__ == '__main__':
    unittest.main()

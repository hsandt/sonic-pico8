import unittest
from . import add_metadata

from os import path
import shutil, tempfile


class TestAddMetadata(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_add_title_author_info(self):
        test_lines = [
            'pico-8 cartridge // http://www.pico-8.com',
            'version 8',
            '__lua__',
            'package={loaded={},_c={}}',
            'package._c["module"]=function()'
        ]
        expected_new_lines = [
            'pico-8 cartridge // http://www.pico-8.com',
            'version 16',
            '__lua__',
            '-- test game',
            '-- by tas',
            'package={loaded={},_c={}}',
            'package._c["module"]=function()'
        ]
        test_filepath = path.join(self.test_dir, 'test.p8')
        with open(test_filepath, 'w') as f:
            f.write('\n'.join(test_lines))
        add_metadata.add_title_author_info(test_filepath, 'test game', 'tas')
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), '\n'.join(expected_new_lines))

    def test_add_label_info(self):
        test_lines = [
            'before',
            '__label__',
            '0000',
            '0000',
            '',
            '__gff__'
        ]
        label_lines = [
            '__label__',
            '1234',
            '5678'
        ]
        expected_new_lines = [
            'before',
            '__label__',
            '1234',
            '5678',
            '__gff__'
        ]
        test_filepath = path.join(self.test_dir, 'test.p8')
        with open(test_filepath, 'w') as f:
            f.write('\n'.join(test_lines))
        label_filepath = path.join(self.test_dir, 'label.p8')
        with open(label_filepath, 'w') as f:
            f.write('\n'.join(label_lines))
        add_metadata.add_label_info(test_filepath, label_filepath)
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), '\n'.join(expected_new_lines))


if __name__ == '__main__':
    unittest.main()

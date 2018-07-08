import unittest
from . import preprocess

from os import path
import shutil, tempfile


class TestPreprocess(unittest.TestCase):

    def test_preprocess_no_directives(self):
        test_lines = [
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines = [
            'if true:',
            '    print("hello")'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_if_debug_in_debug(self):
        test_lines = [
            'print("always")',
            '--#if debug',
            'print("debug")',
            '--#endif',
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines = [
            'print("always")',
            'print("debug")',
            'if true:',
            '    print("hello")'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_if_debug_in_release(self):
        test_lines = [
            'print("always")',
            '--#if debug',
            'print("debug")',
            '--#endif',
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines = [
            'print("always")',
            'if true:',
            '    print("hello")'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_2nd_if_ignored(self):
        test_lines = [
            '--#if debug',
            '--#if debug',
            'print("debug")',
            '--#endif',
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines = [
            'print("debug")',
            'if true:',
            '    print("hello")'
        ]
        # this will also trigger a warning, but we don't test it
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_immediate_endif_ignored(self):
        test_lines = [
            '--#endif',
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines = [
            'if true:',
            '    print("hello")'
        ]
        # this will also trigger a warning, but we don't test it
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_missing_endif_ignored(self):
        test_lines = [
            '--#if debug',
            'print("debug")',
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines = [
        ]
        # this will also trigger a warning, but we don't test it
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)


class TestPreprocessFile(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_preprocess_file_in_debug(self):
        test_lines = [
            'print("always")',
            '--#if debug',
            'print("debug")',
            '--#endif',
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines = [
            'print("always")',
            'print("debug")',
            'if true:',
            '    print("hello")'
        ]
        test_filepath = path.join(self.test_dir, 'test.lua')
        with open(test_filepath, 'w') as f:
            f.write('\n'.join(test_lines))
        preprocess.preprocess_file(test_filepath, 'debug')
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), '\n'.join(expected_processed_lines))

    def test_preprocess_file_in_release(self):
        test_lines = [
            'print("always")',
            '--#if debug',
            'print("debug")',
            '--#endif',
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines = [
            'print("always")',
            'if true:',
            '    print("hello")'
        ]
        test_filepath = path.join(self.test_dir, 'test.lua')
        with open(test_filepath, 'w') as f:
            f.write('\n'.join(test_lines))
        preprocess.preprocess_file(test_filepath, 'release')
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), '\n'.join(expected_processed_lines))

class TestPreprocessDir(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_preprocess_dir_in_debug(self):
        test_lines1 = [
            'print("file1")',
            '--#if debug',
            'print("debug1")',
            '--#endif',
            'if true:',
            '    print("hello")'
        ]
        test_lines2 = [
            'print("file2")',
            '--#if debug',
            'print("debug2")',
            '--#endif',
            'if true:',
            '    print("hello2")'
        ]
        expected_processed_lines1 = [
            'print("file1")',
            'print("debug1")',
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines2 = [
            'print("file2")',
            'print("debug2")',
            'if true:',
            '    print("hello2")'
        ]
        # files must end with .lua to be processed
        test_filepath1 = path.join(self.test_dir, 'test1.lua')
        with open(test_filepath1, 'w') as f1:
            f1.write('\n'.join(test_lines1))
        test_filepath2 = path.join(self.test_dir, 'test2.lua')
        with open(test_filepath2, 'w') as f2:
            f2.write('\n'.join(test_lines2))
        preprocess.preprocess_dir(self.test_dir, 'debug')
        with open(test_filepath1, 'r') as f1:
            self.assertEqual(f1.read(), '\n'.join(expected_processed_lines1))
        with open(test_filepath2, 'r') as f2:
            self.assertEqual(f2.read(), '\n'.join(expected_processed_lines2))

    def test_preprocess_dir_in_debug(self):
        test_lines1 = [
            'print("file1")',
            '--#if debug',
            'print("debug1")',
            '--#endif',
            'if true:',
            '    print("hello")'
        ]
        test_lines2 = [
            'print("file2")',
            '--#if debug',
            'print("debug2")',
            '--#endif',
            'if true:',
            '    print("hello2")'
        ]
        expected_processed_lines1 = [
            'print("file1")',
            'if true:',
            '    print("hello")'
        ]
        expected_processed_lines2 = [
            'print("file2")',
            'if true:',
            '    print("hello2")'
        ]
        # files must end with .lua to be processed
        test_filepath1 = path.join(self.test_dir, 'test1.lua')
        with open(test_filepath1, 'w') as f1:
            f1.write('\n'.join(test_lines1))
        test_filepath2 = path.join(self.test_dir, 'test2.lua')
        with open(test_filepath2, 'w') as f2:
            f2.write('\n'.join(test_lines2))
        preprocess.preprocess_dir(self.test_dir, 'release')
        with open(test_filepath1, 'r') as f1:
            self.assertEqual(f1.read(), '\n'.join(expected_processed_lines1))
        with open(test_filepath2, 'r') as f2:
            self.assertEqual(f2.read(), '\n'.join(expected_processed_lines2))

if __name__ == '__main__':
    unittest.main()

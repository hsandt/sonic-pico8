import unittest
from . import preprocess

import logging
from os import path
import shutil, tempfile


class TestPreprocess(unittest.TestCase):

    def test_strip_comments_full_line(self):
        test_line = '-- my comment\n'
        self.assertEqual(preprocess.strip_comments(test_line), '\n')

    def test_strip_comments_after_code(self):
        test_line = 'print("hi") -- prints hi\n'
        self.assertEqual(preprocess.strip_comments(test_line), 'print("hi") \n')

    def test_strip_comments_outside_quotes(self):
        test_line = 'print("hi  -- this is \"not\" a comment") -- prints hi\n'
        self.assertEqual(preprocess.strip_comments(test_line), 'print("hi  -- this is \"not\" a comment") \n')

    def test_strip_comments_after_code(self):
        test_line = '"some \\"text" print("hi  -- this is \"not\" a comment") -- prints hi  "more text"  -- more comment\n'
        self.assertEqual(preprocess.strip_comments(test_line), '"some \\"text" print("hi  -- this is "not" a comment") \n')

    def test_strip_function_calls_no_change(self):
        test_line = 'log(5)\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'debug'), test_line)

    def test_strip_function_calls_empty_string(self):
        test_line = 'log("character moves", "[character]")\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'release'), '')

    def test_strip_function_calls_tricky_bracket(self):
        test_line = 'log("inside quotes )", "[character]")\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'release'), '')

    def test_strip_function_calls_embedded_brackets(self):
        test_line = 'log(value.evaluate(with.style()), "[character]")\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'release'), '')

    def test_strip_function_calls_tricky_quotes(self):
        test_line = 'log("inside quotes )\\"", "[character]")\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'release'), '')

    def test_strip_function_after_something_else(self):
        test_line = 'dont strip log(this)\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'release'), test_line)

    def test_strip_function_after_something_else(self):
        test_line = 'log(this) shouldnt be stripped\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'release'), test_line)

    def test_strip_function_calls_not_alone(self):
        test_line = 'log("inside quotes", "[character]") or a = 3\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'release'), test_line)

    def test_strip_function_calls_not_alone2(self):
        test_line = 'log("inside quotes )\\"", "[character]") or a = 3\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'release'), test_line)

    @unittest.skip("regex is not good enough to detect last bracket does not belong to the log")
    def test_strip_function_calls_not_alone_end_bracket(self):
        test_line = 'log("inside quotes )\\"", "[character]") or fancy_side_effect()\n'
        self.assertEqual(preprocess.strip_function_calls(test_line, 'release'), test_line)

    def test_strip_line_content_debug(self):
        test_line = '    log("character moves", "[character]")  -- logging\n'
        expected_processed_line = 'log("character moves", "[character]")'
        self.assertEqual(preprocess.strip_line_content(test_line, 'debug'), expected_processed_line)

    def test_strip_line_content_release(self):
        test_line = '    log("character moves", "[character]")  -- logging\n'
        expected_processed_lines = ''
        self.assertEqual(preprocess.strip_line_content(test_line, 'release'), '')

    def test_preprocess_strip_blanks_after_comments(self):
        test_lines = [
            'print ("hi")  \n',
            '\n',
            'if true:  \n',
            '    -- prints hello\n',
            '    print("hello")  -- comment\n',
            '\n'
        ]
        expected_processed_lines = [
            'print ("hi")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_no_directives(self):
        test_lines = [
            'if true:\n',
            '    print("hello")\n'
        ]
        expected_processed_lines = [
            'if true:\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_if_log_in_debug(self):
        test_lines = [
            'print("always")\n',
            '\n',
            '--#if log\n',
            'print("debug")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n'
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("debug")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_if_log_in_release(self):
        test_lines = [
            'print("always")\n',
            '\n',
            '--#if log\n',
            'print("debug")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            'print("hello")  -- prints hello\n'
        ]
        expected_processed_lines = [
            'print("always")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_2nd_if_refused(self):
        test_lines = [
            '--#if log\n',
            'print("debug")\n',
            '--#if never\n',
            'print("never")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            'print("hello")  -- prints hello\n'
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("debug")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_3rd_if_still_ignore(self):
        test_lines = [
            '--#if log\n',
            'print("debug")\n',
            '--#if never\n',
            'print("never")\n',
            '--#if never\n',
            'print("never2")\n',
            '--#endif\n',
            'print("never3")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            'print("hello")  -- prints hello\n'
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("debug")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_3rd_if_ignored_even_if_true(self):
        test_lines = [
            '--#if log\n',
            'print("debug")\n',
            '--#if never\n',
            'print("never")\n',
            '--#if log\n',
            'print("debug2")\n',
            '--#endif\n',
            'print("never3")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            'print("hello")  -- prints hello\n'
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("debug")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_ifn(self):
        test_lines = [
            'print("always")\n',
            '--#ifn log\n',
            'print("no log")\n',
            '--#endif\n',
            'print("hello")\n'
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_if_and_ifn(self):
        test_lines = [
            'print("always")\n',
            '--#if log\n',
            'print("log")\n',
            '--#endif\n',
            '--#ifn log\n',
            'print("no log")\n',
            '--#endif\n',
            'print("hello")\n'
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("log")\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_ifn_inside_if(self):
        test_lines = [
            'print("always")\n',
            '--#if log\n',
            'print("log")\n',
            '--#ifn log\n',
            'print("no log")\n',
            '--#endif\n',
            'print("log 2")\n',
            '--#endif\n',
            'print("hello")\n'
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("log")\n',
            'print("log 2")\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_if_inside_ifn(self):
        test_lines = [
            'print("always")\n',
            '--#ifn log\n',
            'print("no log")\n',
            '--#if log\n',
            'print("log")\n',
            '--#endif\n',
            'print("no log 2")\n',
            '--#endif\n',
            'print("hello")\n'
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_ifn_log_in_release(self):
        test_lines = [
            'print("always")\n',
            '--#ifn log\n',
            'print("no log")\n',
            '--#endif\n',
            'print("hello")\n'
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("no log")\n',
            'print("hello")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_immediate_endif_ignored(self):
        test_lines = [
            '--#endif\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n'
        ]
        expected_processed_lines = [
            'if true:\n',
            'print("hello")\n'
        ]
        # this will also trigger a warning, but we don't test it
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'debug'), expected_processed_lines)

    def test_preprocess_missing_endif_ignored(self):
        test_lines = [
            '--#if log\n',
            'print("debug")\n',
            '\n',
            'if true:\n',
            'print("hello")  -- prints hello\n'
        ]
        expected_processed_lines = [
        ]
        # this will also trigger a warning, but we don't test it
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_comment_block(self):
        test_lines = [
            'print("start")\n',
            '--[[ comment start\n',
            'more comment\n',
            '--]]\n',
            'print("end")\n'
        ]
        expected_processed_lines = [
            'print("start")\n',
            'print("end")\n'
        ]
        logging.info("NOW")
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_comment_block_in_the_middle(self):
        test_lines = [
            'print("start")\n',
            'some code --[[ comment start\n',
            'more comment\n',
            'end comment ]] more core\n',
            'print("end")\n'
        ]
        expected_processed_lines = [
            'print("start")\n',
            'some code\n',
            'more core\n',
            'print("end")\n'
        ]
        logging.info("NOW")
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_stop_comment_outside_comment_block(self):
        test_lines = [
            'print("start")\n',
            'legit ]] code\n',
            'print("end")\n'
        ]
        expected_processed_lines = [
            'print("start")\n',
            'legit ]] code\n',  # warning, ignore
            'print("end")\n'
        ]
        logging.info("NOW")
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_pico8_block(self):
        test_lines = [
            'print("start")\n',
            '--[[#pico8 pico8 start\n',
            'real pico8 code\n',
            '--#pico8]] exceptionally ignored\n',
            'print("end")\n'
        ]
        expected_processed_lines = [
            'print("start")\n',
            'real pico8 code\n',
            'print("end")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_pico8_comment_block(self):
        test_lines = [
            'print("start")\n',
            '--[[#pico8 pico8 start\n',
            'real pico8 code\n',
            'and --[[ comment inside\n',
            'more comment\n',
            'and ]] over\n',
            'more pico8 code',
            '--#pico8]] exceptionally ignored\n',
            'print("end")\n'
        ]
        expected_processed_lines = [
            'print("start")\n',
            'real pico8 code\n',
            'and\n',
            'over\n',
            'more pico8 code\n',
            'print("end")\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_comment_pico8_block(self):
        test_lines = [
            '--[[ comment\n',
            '--[[#pico8\n',  # warning here, ignored
            'comment\n',
            ']] over\n'
        ]
        expected_processed_lines = [
            'over\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_stop_pico8_inside_comment_block(self):
        test_lines = [
            '--[[#pico8\n',
            '--[[ comment\n',
            'comment\n',
            '--#pico8]]\n',  # warning here, will still close
            'still comment\n',  # warning here, will still close
            ']] code is back\n'
        ]
        expected_processed_lines = [
            'code is back\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_stop_pico8_outside_pico8_block(self):
        test_lines = [
            '--#pico8]]\n',  # warning here, ignored
            'code\n'
        ]
        expected_processed_lines = [
            'code\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    @unittest.skip("we don't use a perfect regex able to detect start and end of block comment on the same line")
    def test_preprocess_comment_block_start_end_in_the_middle(self):
        test_lines = [
            'print("start")\n',
            '--[[ --]] outside comment\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'outside comment\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    @unittest.skip("we don't use a perfect regex able to detect end and start of block comment on the same line")
    def test_preprocess_comment_block_end_start_in_the_middle(self):
        test_lines = [
            'print("start")\n',
            '--[[\n',
            ']] outside comment --[[\n',
            ']]\n'
        ]
        expected_processed_lines = [
            'print("start")\n',
            'outside comment\n'
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, 'release'), expected_processed_lines)

    def test_preprocess_with_unknown_config(self):
        test_lines = []
        self.assertRaises(ValueError, preprocess.preprocess_lines, test_lines, 'unknown')


class TestPreprocessFile(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_preprocess_file_in_debug(self):
        test_lines = [
            'print("always")\n',
            '\n',
            '--#if log\n',
            'print("debug")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            'print("hello")  -- prints hello\n'
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("debug")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        test_filepath = path.join(self.test_dir, 'test.lua')
        with open(test_filepath, 'w') as f:
            f.write('\n'.join(test_lines))
        preprocess.preprocess_file(test_filepath, 'debug')
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), ''.join(expected_processed_lines))

    def test_preprocess_file_in_release(self):
        test_lines = [
            'print("always")\n',
            '\n',
            '--#if log\n',
            'print("debug")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '   print("hello")  -- prints hello\n'
        ]
        expected_processed_lines = [
            'print("always")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        test_filepath = path.join(self.test_dir, 'test.lua')
        with open(test_filepath, 'w') as f:
            f.write('\n'.join(test_lines))
        preprocess.preprocess_file(test_filepath, 'release')
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), ''.join(expected_processed_lines))

class TestPreprocessDir(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_preprocess_dir_in_debug(self):
        test_lines1 = [
            'print("file1")\n',
            '\n',
            '--#if log\n',
            'print("debug1")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n'
        ]
        test_lines2 = [
            'print("file2")\n',
            '\n',
            '--#if log\n',
            'print("debug2")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '   print("hello2")  -- prints hello\n'
        ]
        expected_processed_lines1 = [
            'print("file1")\n',
            'print("debug1")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        expected_processed_lines2 = [
            'print("file2")\n',
            'print("debug2")\n',
            'if true:\n',
            'print("hello2")\n'
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
            'print("file1")\n',
            '\n',
            '--#if log\n',
            'print("debug1")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n'
        ]
        test_lines2 = [
            'print("file2")\n',
            '\n',
            '--#if log\n',
            'print("debug2")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '    print("hello2")  -- prints hello\n'
        ]
        expected_processed_lines1 = [
            'print("file1")\n',
            'if true:\n',
            'print("hello")\n'
        ]
        expected_processed_lines2 = [
            'print("file2")\n',
            'if true:\n',
            'print("hello2")\n'
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
            self.assertEqual(f1.read(), ''.join(expected_processed_lines1))
        with open(test_filepath2, 'r') as f2:
            self.assertEqual(f2.read(), ''.join(expected_processed_lines2))

if __name__ == '__main__':
    logging.basicConfig(level=logging.ERROR)
    unittest.main()

#!/usr/bin/python3.6
# -*- coding: utf-8 -*-
import argparse
import os

# This script replace glyph identifiers and some functions with the corresponding
# unicode characters and substitute function names.
# Set the glyphs and functions to replace in GLYPH_TABLE and FUNCTION_SUBSTITUTE_TABLE.

# input glyphs
# when using input functions (btn, btnp), prefer enum input.button_ids
GLYPH_UP = '⬆️'
GLYPH_DOWN = '⬇️'
GLYPH_LEFT = '⬅️'
GLYPH_RIGHT = '➡️'
GLYPH_X = '❎'
GLYPH_O = '🅾️'

# prefix of all glyph identifiers
GLYPH_PREFIX = '##'

# dict mapping an ascii glyph identifier suffix with a unicode glyph
GLYPH_TABLE = {
    'u': GLYPH_UP,
    'd': GLYPH_DOWN,
    'l': GLYPH_LEFT,
    'r': GLYPH_RIGHT,
    'x': GLYPH_X,
    'o': GLYPH_O,
}

FUNCTION_SUBSTITUTE_TABLE = {
    # api.print is useful for tests using native print but in runtime, just use print
    'api.print': 'print'
}

def replace_all_strings_in_dir(dirpath):
    """
    Replace all the glyph identifiers in all source files in a given directory

    """
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            if file.endswith(".lua"):
                replace_all_strings_in_file(os.path.join(root, file))


def replace_all_strings_in_file(filepath):
    """
    Replace all the glyph identifiers in a given file

    test.txt:
        ##d or ##u
        and ##x
        api.print("press ##x")

    >>> replace_all_glyphs_in_file('test.txt')

    test.txt:
        ⬇️ or ⬆️
        and ❎
        print("press ❎")

    """
    with open(filepath, 'r+') as f:
        data = f.read()
        data = replace_all_glyphs_in_string(data)
        data = replace_all_functions_in_string(data)
        # replace file content (this works because our string replacements
        # don't change the number of lines, so we don't need to truncate)
        f.seek(0)
        f.write(data)

def replace_all_glyphs_in_string(text):
    """
    Replace the glyph identifiers of a certain type with the corresponding glyph

    >>> replace_all_glyphs_in_string("##d and ##x ##d")
    '⬇️ and ❎ ⬇️'

    """
    for identifier_char, glyph in GLYPH_TABLE.items():
        text = text.replace(GLYPH_PREFIX + identifier_char, glyph)
    return text

def replace_all_functions_in_string(text):
    """
    Replace functions with the corresponding substitutes

    >>> replace_all_functions_in_string("api.print("hello")")
    'print("hello")'

    """
    for original_fun_name, substitute_fun_name in FUNCTION_SUBSTITUTE_TABLE.items():
        text = text.replace(original_fun_name, substitute_fun_name)
    return text



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Replace predetermined strings in all source files in a directory.')
    parser.add_argument('dirpath', type=str, help='path containing source files where strings should be replaced')
    args = parser.parse_args()
    replace_all_strings_in_dir(args.dirpath)
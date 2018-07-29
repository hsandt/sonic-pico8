#!/usr/bin/python3.6
# -*- coding: utf-8 -*-
import argparse
import os

# This script replace glyph identifiers, some functions and arg substitutes ($arg)
# with the corresponding unicode characters and substitute function names.
# Set the glyphs and functions to replace in GLYPH_TABLE and FUNCTION_SUBSTITUTE_TABLE.

# input glyphs
# (when using input functions (btn, btnp), prefer enum input.button_ids)
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

# prefix of all arg identifiers
ARG_PREFIX = '$'

# default arg substitutes
DEFAULT_ARG_SUBSTITUTES = {
    "titlemenu_ver": "",
    "credits_ver": "",
    "stage_ver": "",
}

def replace_all_strings_in_dir(dirpath, arg_substitutes_table):
    """
    Replace all the glyph identifiers, functions and arg substitutes in all source files in a given directory

    """
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            if file.endswith(".lua"):
                replace_all_strings_in_file(os.path.join(root, file), arg_substitutes_table)


def replace_all_strings_in_file(filepath, arg_substitutes_table):
    """
    Replace all the glyph identifiers, functions and arg substitutes in a given file

    test.txt:
        require('itest_$itest')
        ##d or ##u
        and ##x
        api.print("press ##x")

    >>> replace_all_glyphs_in_file('test.txt', {'itest': 'character'})

    test.txt:
        require('itest_character')
        ⬇️ or ⬆️
        and ❎
        print("press ❎")

    """
    with open(filepath, 'r+') as f:
        data = f.read()
        data = replace_all_glyphs_in_string(data)
        data = replace_all_functions_in_string(data)
        data = replace_all_args_in_string(data, arg_substitutes_table)
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

    >>> replace_all_functions_in_string("api.print(\"hello\")")
    'print("hello")'

    """
    for original_fun_name, substitute_fun_name in FUNCTION_SUBSTITUTE_TABLE.items():
        text = text.replace(original_fun_name, substitute_fun_name)
    return text


def replace_all_args_in_string(text, arg_substitutes_table):
    """
    Replace args with the corresponding substitutes.
    Use DEFAULT_ARG_SUBSTITUTES if arg_substitutes_table is not overriding a key.

    >>> replace_all_args_in_string("require('itest_$itest')", {"itest": "character"})
    'require("itest_character")'

    """
    full_arg_substitutes_table = {**DEFAULT_ARG_SUBSTITUTES, **arg_substitutes_table}
    for arg, substitute in full_arg_substitutes_table.items():
        text = text.replace(ARG_PREFIX + arg, substitute)
    return text


def parse_arg_substitutes(arg_substitutes):
    """Parse a list of arg substitutes in the format 'arg1=substitute1 arg2=substitute2 ...' into a dictionary of {arg: substitute}"""
    arg_substitutes_table = {}
    for arg_definition in arg_substitutes:
        # arg_definition should have format 'arg1=substitute1'
        members = arg_definition.split("=")
        if len(members) == 2:
            arg, substitute = arg_definition.split("=")
            # we do not support surrounding quotes which would be integrated in the names, so don't use names with spaces
            arg_substitutes_table[arg] = substitute
        else:
            raise ValueError(f"arg_substitutes contain definition with not exactly 2 '=' signs: {arg_definition.split}")
    return arg_substitutes_table

if __name__ == '__main__':
    import sys
    parser = argparse.ArgumentParser(description='Replace predetermined strings in all source files in a directory.')
    parser.add_argument('dirpath', type=str, help='path containing source files where strings should be replaced')
    parser.add_argument('--substitutes', type=str, nargs='*', default=[],
        help='extra substitutes table in the format "arg1=substitute1 arg2=substitute2 ...". \
            Does not support spaces in names because surrounding quotes would be part of the names')
    args = parser.parse_args()
    arg_substitutes_table = parse_arg_substitutes(args.substitutes)
    replace_all_strings_in_dir(args.dirpath, arg_substitutes_table)
    print(f"Replaced all strings in all files in {args.dirpath} with substitutes: {arg_substitutes_table}.")

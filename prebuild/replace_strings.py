#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import os

# This script replace glyph identifiers, some functions and symbols in general, and arg substitutes ($arg)
# with the corresponding unicode characters and substitute symbol names.
# Set the glyphs and symbols to replace in GLYPH_TABLE and SYMBOL_SUBSTITUTE_TABLE.

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

# functions and enum constants to substitute
# enums are only substituted for token/char limit reasons
SYMBOL_SUBSTITUTE_TABLE = {
    # Functions

    # api.print is useful for tests using native print but in runtime, just use print
    'api.print': 'print',

    # Enums

    # for every enum added here, surround enum definition with --#ifn pico8
    #   to strip it from the build, unless you need to map the enum string
    #   to its value dynamically
    # remember to update the values of any preprocessed enum modified

    # color
    'colors.black': 0,
    'colors.dark_blue': 1,
    'colors.dark_purple': 2,
    'colors.dark_green': 3,
    'colors.brown': 4,
    'colors.dark_gray': 5,
    'colors.light_gray': 6,
    'colors.white': 7,
    'colors.red': 8,
    'colors.orange': 9,
    'colors.yellow': 10,
    'colors.green': 11,
    'colors.blue': 12,
    'colors.indigo': 13,
    'colors.pink': 14,
    'colors.peach': 15,

    # math
    'directions.left': 0,
    'directions.right': 1,
    'directions.up': 2,
    'directions.down': 3,

    'horizontal_dirs.left': 1,
    'horizontal_dirs.right': 2,

    # input
    'button_ids.left': 0,
    'button_ids.right': 1,
    'button_ids.up': 2,
    'button_ids.down': 3,
    'button_ids.o': 4,
    'button_ids.x': 5,

    'btn_states.released': 0,
    'btn_states.just_pressed': 1,
    'btn_states.pressed': 2,
    'btn_states.just_released': 3,

    'input_modes.native': 0,
    'input_modes.simulated': 1,

    # playercharacter
    'control_modes.human': 1,
    'control_modes.ai': 2,
    'control_modes.puppet': 3,

    'motion_modes.platformer': 1,
    'motion_modes.debug': 2,

    'motion_states.grounded': 1,
    'motion_states.airborne': 2,

    # itest
    'itest_dsl_command_types.spawn':   1,
    'itest_dsl_command_types.move':    2,
    'itest_dsl_command_types.wait':   11,
    'itest_dsl_command_types.expect': 21,

    'itest_dsl_value_types.pc_pos':  1,
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
    Replace all the glyph identifiers, symbols and arg substitutes in all source files in a given directory

    """
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            if file.endswith(".lua"):
                replace_all_strings_in_file(os.path.join(root, file), arg_substitutes_table)


def replace_all_strings_in_file(filepath, arg_substitutes_table):
    """
    Replace all the glyph identifiers, symbols and arg substitutes in a given file

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
        data = replace_all_symbols_in_string(data)
        data = replace_all_args_in_string(data, arg_substitutes_table)
        # replace file content (truncate as the new content may be shorter)
        f.seek(0)
        f.truncate()
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

def replace_all_symbols_in_string(text):
    """
    Replace symbols with the corresponding substitutes
    Convert integer to string for replacement to support enum constants

    >>> replace_all_symbols_in_string("api.print(\"hello\")")
    'print("hello")'

    """
    for original_symbol, substitute_symbol in SYMBOL_SUBSTITUTE_TABLE.items():
        # enum constants are defined with integer substitutes for simplicity,
        # so convert them to string first
        if type(substitute_symbol) == int:
            substitute_symbol = str(substitute_symbol)
        text = text.replace(original_symbol, substitute_symbol)
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

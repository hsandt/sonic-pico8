#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re

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
# format: { namespace1: {name1: substitute1, name 2: substitute2, ...}, ... }
SYMBOL_SUBSTITUTE_TABLE = {
    # Functions

    # api.print is useful for tests using native print, but in runtime, just use print
    'api': {
        'print': 'print'
    },

    # Enums

    # for every enum added here, surround enum definition with --#ifn pico8
    #   to strip it from the build, unless you need to map the enum string
    #   to its value dynamically with enum_values[dynamic_string]
    # remember to update the values of any preprocessed enum modified

    # color
    'colors': {
        'black':        0,
        'dark_blue':    1,
        'dark_purple':  2,
        'dark_green':   3,
        'brown':        4,
        'dark_gray':    5,
        'light_gray':   6,
        'white':        7,
        'red':          8,
        'orange':       9,
        'yellow':       10,
        'green':        11,
        'blue':         12,
        'indigo':       13,
        'pink':         14,
        'peach':        15,
    },

    # math
    'directions': {
        'left':  0,
        'right': 1,
        'up':    2,
        'down':  3,
    },

    'horizontal_dirs': {
        'left':     1,
        'right':    2,
    },

    # input
    'button_ids': {
        'left':     0,
        'right':    1,
        'up':       2,
        'down':     3,
        'o':        4,
        'x':        5,
    },

    'btn_states': {
        'released':         0,
        'just_pressed':     1,
        'pressed':          2,
        'just_released':    3,
    },

    'input_modes': {
        'native':       0,
        'simulated':    1,
    },

    # playercharacter
    'control_modes': {
        'human':    1,
        'ai':       2,
        'puppet':   3,
    },

    'motion_modes': {
        'platformer':   1,
        'debug':        2,
    },

    'motion_states': {
        'grounded': 1,
        'airborne': 2,
    },

    # itest_dsl
    'parsable_types': {
        'none':             1,
        'number':           2,
        'vector':           3,
        'horizontal_dir':   4,
        'control_mode':     5,
        'motion_mode':      6,
        'motion_state':     7,
        'button_id':        8,
        'gp_value':         9,
    },

    'command_types': {
        'warp':             1,
        'set':              2,
        'set_control_mode': 3,
        'set_motion_mode':  4,
        'move':             5,
        'stop':             6,
        'jump':             7,
        'stop_jump':        8,
        'press':            9,
        'release':          10,
        'wait':             11,
        'expect':           12,
    },

    'gp_value_types': {
        'pc_bottom_pos':   1,
        'pc_velocity':     2,
        'pc_ground_spd':   3,
        'pc_motion_state': 4,
        'pc_slope':        5,
    },
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
    # make sure to open files as utf-8 so we can handle glyphs on any platform
    # (when locale.getpreferredencoding() and sys.getfilesystemencoding() are not "UTF-8" and "utf-8")
    # you can also set PYTHONIOENCODING="UTF-8" to visualize glyphs when debugging if needed
    with open(filepath, 'r+', encoding='utf-8') as f:
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

def generate_get_substitute_from_dict(substitutes):
    def get_substitute(match):
        member = match.group(1)  # "{member}"
        if member in substitutes:
            return str(substitutes[member])  # enums are substituted with integers, so convert
        else:
            original_symbol = match.group(0)  # "{namespace}.{member}"
            # in general, we should substitute all members of a namespace, especially enums
            logging.error(f'no substitute defined for {original_symbol}, but the namespace (first part) is present in SYMBOL_SUBSTITUTE_TABLE')
            # return something easy to debug in PICO-8, in case the user missed the error message
            return f'assert(false, "UNSUBSTITUTED {original_symbol}")'
    return get_substitute

def replace_all_symbols_in_string(text):
    """
    Replace symbols "namespace.member" defined in SYMBOL_SUBSTITUTE_TABLE
    with the corresponding substitutes
    Convert integer to string for replacement to support enum constants

    >>> replace_all_symbols_in_string("api.print(\"hello\")")
    'print("hello")'

    """
    for namespace, substitutes in SYMBOL_SUBSTITUTE_TABLE.items():
        SYMBOL_PATTERN = re.compile(rf"{namespace}\.(\w+)")
        text = SYMBOL_PATTERN.sub(generate_get_substitute_from_dict(substitutes), text)
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

    logging.basicConfig(level=logging.INFO)
    arg_substitutes_table = parse_arg_substitutes(args.substitutes)
    replace_all_strings_in_dir(args.dirpath, arg_substitutes_table)
    print(f"Replaced all strings in all files in {args.dirpath} with substitutes: {arg_substitutes_table}.")

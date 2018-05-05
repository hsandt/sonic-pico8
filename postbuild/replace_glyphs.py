#!/usr/bin/python3.6
# -*- coding: utf-8 -*-

import os
import re
import argparse

# unicode glyphs to replace the glyph identifiers with
GLYPH_UP = '⬆️'
GLYPH_DOWN = '⬇️'
GLYPH_LEFT = '⬅️'
GLYPH_RIGHT = '➡️'
GLYPH_X = '❎'
GLYPH_O = '🅾️'

# prefix of all glyph identifiers
PREFIX = '##'

# dict mapping an ascii glyph identifier suffix with a unicode glyph
GLYPH_TABLE = {
    'u': GLYPH_UP,
    'd': GLYPH_DOWN,
    'l': GLYPH_LEFT,
    'r': GLYPH_RIGHT,
    'x': GLYPH_X,
    'o': GLYPH_O,
}

def replace_all_glyphs_in_file(filepath):
    """
    Replace all the glyph identifiers

    test.txt:
        ##d or ##u
        and ##x

    >>> replace_all_glyphs_in_file('test.txt')

    test.txt:
        ⬇️ or ⬆️
        and ❎

    """
    with open(filepath, 'r+') as f:
        data = f.read()
        data = replace_all_glyphs_in_string(data)
        f.seek(0)
        f.write(data)

def replace_all_glyphs_in_string(text):
    """
    Replace of the glyph identifiers of a certain type with the corresponding glyph

    >>> replace_all_glyphs_in_string("##d and ##x ##d")
    '⬇️ and ❎ ⬇️'

    """
    for identifier_char in GLYPH_TABLE:
        text = replace_glyphs_in_string(text, identifier_char)
    return text

def replace_glyphs_in_string(text, identifier_char):
    """
    Replace of the glyph identifiers of a certain type with the corresponding glyph

    >>> replace_glyphs_in_string('##d and ##x ##d', 'd')
    '⬇️ and ##x ⬇️'

    """
    return text.replace(f'{PREFIX}{identifier_char}', f'{GLYPH_TABLE[identifier_char]}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('filepath', type=str,
                        help='path of the file where glyphs should be replaced')
    args = parser.parse_args()
    replace_all_glyphs_in_file(args.filepath)

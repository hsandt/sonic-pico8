#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re
from enum import Enum

# This script applies preprocessing and stripping to the code:
# 1. it will strip all code between #if [symbol] and #endif if symbol is not defined for this config.
# 2. it will enable all code between --[[#pico8 and --#pico8]] (unless stripped by 1.)
# 3. it will strip debug function calls like log() or assert() in configs that don't use those symbols

# Config for defined symbols (all configs have pico8, to distinguish from busted using the scripts directly)
# Remember that busted will not preprocess at all and will therefore go through all the blocks.
# For non-pico8 builds, we use --#ifn pico8 to indicate we won't have preprocessing,
# but for busted unit tests we prefer using --#if utest (which is never defined) to make clear that
# the code is only needed for a purpose of redundancy and unit test harnessing in general.

# assert
# If 'assert' is defined here, it should *not* be stripped in the next table.
# The 'assert' symbol if only here to only to strip multi-line asserts or blocks of functions only used inside assert calls.

# visual_logger
# 'visual_logger' requires 'log', the dependeency is not automatically solved.
defined_symbols_table = {
    'debug':       ['pico8', 'assert', 'log', 'visual_logger', 'tuner', 'profiler', 'mouse', 'cheat'],
    'assert':      ['pico8', 'assert', 'log', 'visual_logger'],
    'itest':       ['pico8', 'assert', 'log', 'test'],
    'itest_light': ['pico8', 'log', 'test'],
    'profiler':    ['pico8', 'log', 'visual_logger', 'profiler'],
    'visual_log':  ['pico8', 'log', 'visual_logger'],
    'pico8_utest': ['pico8', 'assert', 'log'],
    'log':         ['pico8', 'log'],
    'cheat':       ['pico8', 'cheat'],
    'release':     ['pico8']
}

# Functions to strip for each config (not all configs need to be present as keys)
# Make sure you never insert gameplay code inside a log or assert (such as assert(coresume(coroutine)))
# and always split gameplay/debug code in 2 lines
# Also make sure all your stripped function calls are on 1 line (multi-line regex catch is currently not supported)
# or that you surround them with the corresponding #if (e.g. #if assert for a multi-line assert)
stripped_functions_table = {
    'debug':       [],
    'assert':      [],
    'itest':       [],
    'itest_light': ['assert'],
    'profiler':    ['assert'],
    'visual_log':  ['assert'],
    'pico8_utest': [],
    'log':         ['assert'],
    'cheat':       ['assert', 'log'],
    'release':     ['assert', 'log', 'warn', 'err']
}

# Parsing mode of each individual #if block
class IfBlockMode(Enum):
    ACCEPTED = 1  # the condition was true
    REFUSED  = 2  # the condition was false
    IGNORED  = 3  # we were inside a false condition so we don't care, we are just waiting for #endif

# Parsing state machine modes
class ParsingMode(Enum):
    ACTIVE   = 1  # we are copying each line
    IGNORING = 2  # we are ignoring all content in the current if block

# Regex patterns

# tag to enter a pico8-only block (it's a comment block so that busted never runs it but preprocess reactivates it)
# unlike normal comment blocks, we expect to match from the line start
pico8_start_pattern = re.compile(r"--\[\[#pico8")
# closing tag for pico8-only block. Unlike normal comment blocks, we expect to match from the line start and we ignore anything after the block end!
pico8_end_pattern = re.compile(r"--#pico8]]")

if_pattern = re.compile(r"--#if (\w+)")    # ! ignore anything after 1st symbol
ifn_pattern = re.compile(r"--#ifn (\w+)")  # ! ignore anything after 1st symbol
endif_pattern = re.compile(r"--#endif")
stripped_function_call_patterns_table = {}
for config, stripped_functions in stripped_functions_table.items():
    # if there is nothing to strip, avoid creating a regex with just "(?:)\(\)" that would match a line starting with brackets
    if stripped_functions:
        # many good regex exist to match open and closing brackets, unfortunately they use PCRE features like ?> unsupported in Python re
        # so we use a very simple regex, but remember to never put anything fancy on a log/assert line that may have side effects, since they will be stripped on release
        # comments after call are ok
        # for better regex with PCRE to detect surrounding brackets and quotes, see:
        # https://stackoverflow.com/questions/2148587/finding-quoted-strings-with-escaped-quotes-in-c-sharp-using-a-regular-expression
        # https://stackoverflow.com/questions/4568410/match-comments-with-regex-but-not-inside-a-quote adapted to lua comments
        # https://stackoverflow.com/questions/546433/regular-expression-to-match-outer-brackets#546457
        # https://stackoverflow.com/questions/18906514/regex-for-matching-functions-and-capturing-their-arguments#18908330

        # ex: '(?:log|warn|err)'
        function_name_alternative_pattern = f"(?:{'|'.join(stripped_functions)})"
        # ex: '^\s*(?:log|warn|err)\(.*\)\s*(?:--.*)?$'
        stripped_function_call_patterns_table[config] = re.compile(rf'^\s*{function_name_alternative_pattern}\(.*\)\s*(?:--.*)?$')

def preprocess_dir(dirpath, config):
    """Apply preprocessor directives to all the source files inside the given directory, for the given config"""
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            if file.endswith(".lua"):
                preprocess_file(os.path.join(root, file), config)

def preprocess_file(filepath, config):
    """
    Apply preprocessor directives to a single file, for the given config

    test.lua:
        print("always")
        --#if log
        print("debug")
        --#endif
        if true:
            print("hello")

    >>> preprocess_file('test.lua', 'debug')

    test.lua:
        print("always")
        print("debug")
        if true:
            print("hello")

    or

    >>> preprocess_file('test.lua', 'release')

    test.lua:
        print("always")
        if true:
            print("hello")

    """
    with open(filepath, 'r+') as f:
        logging.debug(f"Preprocessing file {filepath}...")
        preprocessed_lines = preprocess_lines(f, config)
        # replace file content (truncate as the new content may be shorter)
        f.seek(0)
        f.truncate()
        f.writelines(preprocessed_lines)

def preprocess_lines(lines, config):
    """
    Apply stripping and preprocessor directives to iterable lines of source code, for the given config
    It is possible to pass a file as lines iterator

    """
    if config not in defined_symbols_table:
        raise ValueError(f"config '{config}' is not a key in defined_symbols_table ({list(defined_symbols_table.keys())})")
    defined_symbols = defined_symbols_table[config]

    preprocessed_lines = []

    inside_pico8_block = False

    # explore the tree of #if by storing the current stack of ifs encountered from top to bottom
    if_block_modes_stack = []  # can only be filled with [IfBlockMode.ACCEPTED*, IfBlockMode.REFUSED?, IfBlockMode.IGNORED* (only if 1 REFUSED)]
    current_mode = ParsingMode.ACTIVE  # it is ParsingMode.ACTIVE iff if_block_modes_stack is empty or if_block_modes_stack[-1] == IfBlockMode.ACCEPTED

    for line in lines:
        # 3. preprocess directives
        opt_match = None      # if or ifn match depending on which one succeeds, None if both fail
        negative_if = False   # True if we have #ifn, False else

        if_boundary_match = if_pattern.match(line)
        if not if_boundary_match:
            if_boundary_match = ifn_pattern.match(line)
            if if_boundary_match:
                negative_if = True

        if if_boundary_match:
            if current_mode is ParsingMode.ACTIVE:
                symbol = if_boundary_match.group(1)
                # for #if, you need to have symbol defined, for #ifn, you need to have it undefined
                if (symbol in defined_symbols) ^ negative_if:
                    # symbol is defined, so remain active and add that to the stack
                    if_block_modes_stack.append(IfBlockMode.ACCEPTED)
                    # still strip the preprocessor directives themselves (don't add it to accepted lines)
                else:
                    # symbol is not defined, enter ignoring mode and add that to the stack
                    if_block_modes_stack.append(IfBlockMode.REFUSED)
                    current_mode = ParsingMode.IGNORING
            else:
                # we are already in an unprocessed block so we don't care whether that subblock verifies the condition or not
                # continue ignoring lines but push to the stack so we can wait for #endif
                if_block_modes_stack.append(IfBlockMode.IGNORED)
        elif endif_pattern.match(line):
            if current_mode is ParsingMode.ACTIVE:
                # check that we had some #if in the stack
                if if_block_modes_stack:
                    # go one level up, remain active
                    if_block_modes_stack.pop()
                else:
                    logging.warning('an --#endif was encountered outside an --#if block. Make sure the block starts with an --#if directive')
            else:
                last_mode = if_block_modes_stack.pop()
                # if we left the refusing block, then the new last mode is ACCEPTED and we should be active again
                # otherwise, we have simply left an IGNORED mode and we remain IGNORING
                if last_mode is IfBlockMode.REFUSED:
                    current_mode = ParsingMode.ACTIVE
        elif current_mode is ParsingMode.ACTIVE:
            if pico8_start_pattern.match(line):
                # we detected a pico8 block and should continue appending the lines normally (since we are building for pico8)
                # the bool flag is only here to check that 1 end pattern will match 1 start pattern
                # since we don't really need embedded pico8 blocks, we assume only 1 level and don't use a stack here
                if not inside_pico8_block:
                    inside_pico8_block = True
                else:
                    logging.warning('a pico8 block start was encountered inside a pico8 block. It will be ignored')
            elif pico8_end_pattern.match(line):
                if inside_pico8_block:
                    inside_pico8_block = False
                else:
                    logging.warning('a pico8 block end was encountered outside a pico8 block. It will be ignored')
            else:
                if not is_function_call_to_strip(line, config):
                    preprocessed_lines.append(line)

    if if_block_modes_stack:
        logging.warning('file ended inside an --#if block. Make sure the block is closed by an --#endif directive')
    return preprocessed_lines


def is_function_call_to_strip(line, config):
    """Return true iff the line contains a function call (and optionally a comment) that should be stripped in the passed config"""
    return config in stripped_function_call_patterns_table and bool(stripped_function_call_patterns_table[config].match(line))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Apply preprocessor directives.')
    parser.add_argument('path', type=str, help='path containing source files to preprocess')
    parser.add_argument('config', type=str, help="config used: 'debug' or 'release'")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    preprocess_dir(args.path, args.config)
    print(f"Preprocessed all files in {args.path} with config {args.config}.")

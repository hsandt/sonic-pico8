#!/usr/bin/python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re
from enum import Enum

# This script applies preprocessing and stripping to the code:
# 1. it will strip leading and trailing whitespace, ignoring empty lines completely
# 2. it will remove all line comments (doesn't support block comments)
# 3. it will strip all code between #if [symbol] and #endif if symbol is not defined for this config.
# 4. it will strip debug function calls like log() or assert()

# Config for defined symbols
defined_symbols_table = {
    'debug':      ['assert', 'log', 'visual_logger', 'tuner', 'profiler', 'mouse'],
    'assert':     ['assert', 'log', 'visual_logger'],
    'visual_log': ['log', 'visual_logger'],
    'log':        ['log'],
    'release':    []
}

# Functions to strip for each config (not all configs need to be present as keys)
# Make sure you never insert gameplay code inside a log or assert (such as assert(coresume(coroutine)))
# and always split gameplay/debug code in 2 lines
stripped_functions_table = {
    'debug':      [],
    'assert':     [],
    'visual_log': ['assert'],
    'log':        ['assert'],
    'release':    ['assert', 'log', 'warn', 'err']
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
if_pattern = re.compile("--#if (\\w+)")    # ! ignore anything after 1st symbol
ifn_pattern = re.compile("--#ifn (\\w+)")  # ! ignore anything after 1st symbol
endif_pattern = re.compile("--#endif")
comment_pattern = re.compile('("[^"\\\\]*(?:\\\\.[^"\\\\]*)*")|(--.*)')
stripped_function_call_patterns_table = {}
for config, stripped_functions in stripped_functions_table.items():
    # many good regex exist to match open and closing brackets, unfortunately they use PCRE features like ?> unsupported in Python re
    # so we use a very simple regex, but remember to never put anything fancy on a log/assert line that may have side effects, since they will be stripped on release
    # ex: '^(?:log|warn|err)\(.*\)$'
    # for better regex with PCRE, see:
    # https://stackoverflow.com/questions/2148587/finding-quoted-strings-with-escaped-quotes-in-c-sharp-using-a-regular-expression
    # https://stackoverflow.com/questions/4568410/match-comments-with-regex-but-not-inside-a-quote adapted to lua comments
    # https://stackoverflow.com/questions/546433/regular-expression-to-match-outer-brackets#546457
    # https://stackoverflow.com/questions/18906514/regex-for-matching-functions-and-capturing-their-arguments#18908330
    function_name_alternative_pattern = f"(?:{'|'.join(stripped_functions)})"
    stripped_function_call_patterns_table[config] = re.compile(f'^{function_name_alternative_pattern}\\(.*\\)$')

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
        f.seek(0)
        f.truncate(0)  # after preprocessing, file tends to have fewer lines so it's important to remove previous content
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

    # explore the tree of #if by storing the current stack of ifs encountered from top to bottom
    if_block_modes_stack = []  # can only be filled with [IfBlockMode.ACCEPTED*, IfBlockMode.REFUSED?, IfBlockMode.IGNORED* (only if 1 REFUSED)]
    current_mode = ParsingMode.ACTIVE  # it is ParsingMode.ACTIVE iff if_block_modes_stack is empty or if_block_modes_stack[-1] == IfBlockMode.ACCEPTED

    for line in lines:
        # 3. preprocess directives

        opt_match = None         # if or ifn match depending on which one succeeds, None if both fail
        negative_if = False  # True if we have #ifn, False else

        if_match = if_pattern.match(line)
        if if_match:
            opt_match = if_match
        else:
            ifn_match = ifn_pattern.match(line)
            if ifn_match:
                opt_match = ifn_match
                negative_if = True

        if opt_match is not None:
            if current_mode is ParsingMode.ACTIVE:
                symbol = opt_match.group(1)
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
            line = strip_line_content(line, config)
            # if resulting line is empty, ignore it
            if line:
                # we stripped eol, so re-add it now
                preprocessed_lines.append(line + '\n')

    if if_block_modes_stack:
        logging.warning('file ended inside an --#if block. Make sure the block is closed by an --#endif directive')
    return preprocessed_lines

def strip_line_content(line, config):
    """Strip line content as much as possible. Return line without eol. May be empty."""
    # 2. strip comments first (so we can trim whitespace left by after-code comment afterward)
    line = strip_comments(line)
    # 1. strip blanks (this includes any remaining end of line)
    line = line.strip()
    # 4. strip debug function calls if not debug
    line = strip_function_calls(line, config)
    return line

def strip_comments(line):
    # this will keep trailing whitespaces as well as eol, but we count on strip to finish the job
    # \1 will preserve the original code
    return comment_pattern.sub('\\1', line)


def strip_function_calls(line, config):
    if config in stripped_function_call_patterns_table and stripped_function_call_patterns_table[config].match(line):
        return ''
    else:
        return line


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Apply preprocessor directives.')
    parser.add_argument('path', type=str, help='path containing source files to preprocess')
    parser.add_argument('config', type=str, help="config used: 'debug' or 'release'")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    preprocess_dir(args.path, args.config)
    print(f"Preprocessed all files in {args.path} with config {args.config}.")

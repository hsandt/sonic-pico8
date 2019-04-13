#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import shutil, tempfile
import re
from enum import Enum
from subprocess import Popen, PIPE


# This script minifies the __lua__ section of a cartridge {game}.p8:
# 1. It uses p8tool listlua A.p8 to quickly extract the __lua__ code into {game}.lua
# 2. Convert remaining bits of pico8 lua (generated by p8tool) into clean lua
# 3. It applies luamin to {game}.lua and outputs to {game}_min.lua
# 4. It reads the header (before __lua__) of {game}.p8 and copies it into {game}_min.p8
# 5. It appends {game}_min.lua's content to {game}_min.p8
# 6. It finishes reading {game}.p8's remaining sections and appends them into {game}_min.p8
# 7. It replaces {game}.p8 with {game}_min.p8


LUA_HEADER = b"__lua__\n"
# note that this pattern captures 1. condition 2. result of a "one-line if" if it is,
# but that it also matches a normal if-then, requiring a check before using the pattern
PICO8_ONE_LINE_IF_PATTERN = re.compile(r"if \(([^)]*)\) (.*)")


class Phase(Enum):
    CARTRIDGE_HEADER = 1  # copying header, from "pico-8 cartridge..." to "__lua__"
    LUA_SECTION      = 2  # found "__lua__", still copy the 2 author/version comment lines then appending minified lua all at once
    LUA_CATCHUP      = 3  # skipping the unused unminified lua until we reach the other sections
    OTHER_SECTIONS   = 4  # copying the last sections


def minify_lua_in_p8(cartridge_filepath):
    """
    Minifies the __lua__ section of a p8 cartridge, using luamin.

    """
    logging.debug(f"Minifying lua in cartridge {cartridge_filepath}...")

    root, ext = os.path.splitext(cartridge_filepath)
    if not ext.endswith(".p8"):
        logging.error(f"Cartridge filepath '{cartridge_filepath}' does not end with '.p8'")
        return

    min_cartridge_filepath = f"{root}_min.p8"
    lua_filepath = f"{root}.lua"
    min_lua_filepath = f"{root}_min.lua"

    # Step 1: extract lua code
    with open(lua_filepath, 'w') as lua_file:
        extract_lua(cartridge_filepath, lua_file)

    # Step 2: clean lua
    with open(lua_filepath, 'r') as lua_file:
        # create temporary file object (we still need to open it with mode to get file descriptor)
        temp_file_object, temp_filepath = tempfile.mkstemp()
        original_char_count = sum(len(line) for line in lua_file)
        print(f"Original lua code has {original_char_count} characters")
        lua_file.seek(0)
        clean_lua(lua_file, os.fdopen(temp_file_object, 'w'))
    os.remove(lua_filepath)
    shutil.move(temp_filepath, lua_filepath)

    # Step 3: apply luamin
    with open(min_lua_filepath, 'w+') as min_lua_file:
        minify_lua(lua_filepath, min_lua_file)
        min_lua_file.seek(0)
        min_char_count = sum(len(line) for line in min_lua_file)
        print(f"Minified lua code to {min_char_count} characters")
        if min_char_count > 65536:
            logging.warn(f"Maximum character count of 65536 has been exceeded, cartridge will be truncated in PICO-8")

    # Step 4-6: inject minified lua code
    phase = Phase.CARTRIDGE_HEADER
    with open(cartridge_filepath, 'r') as source_file,   \
         open(min_cartridge_filepath, 'w') as target_file,   \
         open(min_lua_filepath, 'r') as min_lua_file:
        inject_minified_lua_in_p8(source_file, target_file, min_lua_file)

    # Step 7: replace original p8 with minified p8, clean up intermediate files
    os.remove(cartridge_filepath)
    os.remove(lua_filepath)
    os.remove(min_lua_filepath)
    shutil.move(min_cartridge_filepath, cartridge_filepath)

def extract_lua(source_filepath, lua_file):
    """
    Extract lua from source_filepath (string) to lua_file (file descriptor: write)

    """
    # p8tool listrawlua has a bug (https://github.com/dansanderson/picotool/issues/59)
    # which prevents me from using it until it is fixed. listlua is safer,
    # but will take ~1s to parse the game .p8
    # note: p8tool listlua doesn't spawn a Zombie process, but we prefer to communicate()
    Popen(["p8tool", "listlua", source_filepath], stdout=lua_file, stderr=lua_file).communicate()


def clean_lua(lua_file, clean_lua_file):
    """
    Convert PICO-8 specific lines from to lua_file (file descriptor: read)
    to native Lua in clean_lua_file (file descriptor: write)

    """
    for line in lua_file:
        # we simplify things a lot thanks to our assumptions on the generated code
        # we know that the only pico8 one-line if will be generated for the require function
        #   and have the pattern "if (condition) [result]" without "then",
        #   and there are no edge cases like embedded conditions or continuing line with "\"
        if line.startswith("if (") and "then" not in line:
            # convert to "if [condition] then [result] end"
            clean_lua_file.write(PICO8_ONE_LINE_IF_PATTERN.sub("if \\1 then \\2 end", line))
        else:
            clean_lua_file.write(line)



def minify_lua(lua_filepath, min_lua_file):
    """
    Minify lua from lua_filepath (string)
    and send output to min_lua_file (file descriptor: write)

    """
    Popen(["npm/luamin_file", lua_filepath], stdout=min_lua_file, stderr=min_lua_file).communicate()


def inject_minified_lua_in_p8(source_file, target_file, min_lua_file):
    """
    Inject minified lua from min_lua_file (file descriptor: read)
    into a copy of source_file (file descriptor: read)
    producing target_file (file descriptor: write)

    """
    phase = Phase.CARTRIDGE_HEADER
    for line in source_file:
        if phase is Phase.CARTRIDGE_HEADER:
            # Step 4: copy header (also copy the "__lua__" line just after)
            target_file.write(line)
            if line == "__lua__\n":
                # enter lua section
                phase = Phase.LUA_SECTION

        elif phase is Phase.LUA_SECTION:
            # Step 5: copy minified lua
            target_file.writelines(min_lua_file.readlines())
            target_file.write("\n")  # newline required before other sections
            phase = Phase.LUA_CATCHUP

        elif phase is Phase.LUA_CATCHUP:
            # skip all lines until __gfx__
            if line == "__gfx__\n":
                # copy the __gfx__ line itself
                target_file.write(line)
                phase = Phase.OTHER_SECTIONS

        else:  # phase is Phase.CARTRIDGE_HEADER
            # Step 6: copy remaining sections
            target_file.write(line)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Minify lua code in cartridge.')
    parser.add_argument('path', type=str, help='path containing cartridge file to minify')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    print(f"Minifying lua code in {args.path}...")

    minify_lua_in_p8(args.path)

    print(f"Minified lua code in {args.path}")

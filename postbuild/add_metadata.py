#!/usr/bin/python3.6
# -*- coding: utf-8 -*-
import argparse
import os
import shutil, tempfile
import sys

# This script does 3 things:
# 1. Add game title and author at the top of source code for .p8.png
# 2. Add __label__ section from separate file for .p8.png if label_filepath is not '-' (to make up for the lack of --label option in p8tool)
# 3. Fix pico-8 version to 16 (instead of 8 with current p8tool behavior)

# Usage:
# add_metadata.py filepath label_filepath
# filepath:         built game path
# label_filepath:   path of file containing label data (pass '-' to preserve label from overwritten built game file if any)


def add_title_author_info(filepath, title, author):
    """
    Add game title and author at the top of source code
    Additionally it fixes the version to 16 (not required to save the game with correct metadata)

    test.p8:
        pico-8 cartridge // http://www.pico-8.com
        version 8
        __lua__
        package={loaded={},_c={}}
        package._c["module"]=function()

    >>> add_title_author_info('test.p8', 'test game', 'tas')

    test.txt:
        pico-8 cartridge // http://www.pico-8.com
        version 16
        __lua__
        -- test game
        -- by tas
        package={loaded={},_c={}}
        package._c["module"]=function()

    """
    with open(filepath, 'r') as f:
        # create a temporary file with the modified content before it replaces the original file
        temp_dir = tempfile.mkdtemp()
        try:
            temp_filepath = os.path.join(temp_dir, 'test.p8')
            with open(temp_filepath, 'w') as temp_f:
                for line in f:
                    if line.strip() == 'version 8':
                        temp_f.write('version 16\n')
                        continue
                    temp_f.write(line)
                    if line.strip() == '__lua__':
                        # lua block detected, add title and author after the tag line
                        temp_f.write(f'-- {title}\n')
                        temp_f.write(f'-- by {author}\n')
            shutil.copy(temp_filepath, filepath)
        finally:
            shutil.rmtree(temp_dir)


# This function is currently unused because preserving label from metadata template is easier
def add_label_info(filepath, label_filepath):
    """
    Replace label content inside the file with content from another line

    test.p8:
        __label__
        0000

    label.p8:
        __label__
        1234

    >>> add_label_info('test.p8', 'label.p8')

    test.p8:
        __label__
        1234

    """
    label_lines = []
    with open(label_filepath, 'r') as f:
        inside_label = False
        for line in f:
            stripped_line = line.strip()
            if not inside_label and stripped_line == '__label__':
                inside_label = True
            elif inside_label:
                # stop if blank line or next section starts
                if not stripped_line or line.startswith('__'):
                    break
                # save label content (in case it's the last line, force newline)
                label_lines.append(f'{stripped_line}\n')

    with open(filepath, 'r') as f:
        # create a temporary file with the modified content before it replaces the original file
        temp_dir = tempfile.mkdtemp()
        try:
            temp_filepath = os.path.join(temp_dir, 'test.p8')
            with open(temp_filepath, 'w') as temp_f:
                inside_label = False
                for line in f:
                    stripped_line = line.strip()
                    if inside_label:
                        # reset inside_label if blank line or next section starts
                        if not stripped_line or line.startswith('__'):
                            inside_label = False
                    else:
                        temp_f.write(line)
                        if stripped_line == '__label__':
                            inside_label = True
                            # immediately print all label lines
                            for label_line in label_lines:
                                temp_f.write(label_line)

            shutil.copy(temp_filepath, filepath)
        finally:
            shutil.rmtree(temp_dir)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Add metadata on a p8tool output file.')
    parser.add_argument('filepath', type=str, help='path of the file to process (.p8)')
    parser.add_argument('label_filepath', type=str, help='path of the file containing the label content to copy')
    parser.add_argument('title', type=str, help='game title')
    parser.add_argument('author', type=str, help='author')
    args = parser.parse_args()
    add_title_author_info(args.filepath, args.title, args.author)
    if args.label_filepath != '-':
        add_label_info(args.filepath, args.label_filepath)
    print(f"Added metadata (title: {args.title}, author: {args.author}) to {args.filepath} based on label {args.label_filepath}.")

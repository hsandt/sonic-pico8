#!/bin/bash
# Copy the source folder content to another (intermediate) location
# $1: source folder (from project root)
# $2: copy output folder (from project root)

if [[ $# -lt 2 ]] ; then
    echo 'copy_source_folder.sh takes 2 params, provided $#:
    $1: source folder (from project root)
    $2: copy output folder (from project root)'
    exit 1
fi

. helper/path_helper.sh

if is_unsafe_path "$1"; then
	echo "$0: source folder path is unsafe: '$1'"
	exit 1
fi

if is_unsafe_path "$2"; then
	echo "$0: copy output folder path is unsafe: '$2'"
	exit 1
fi

# clean any previous output folder and make a new one
# note that rm -r $2/* doesn't work inside a script like this, it will consider file "not found"
rm -rf "$2"
mkdir -p "$2"
# we need to enter the source folder first to avoid copying the source folder itself too
pushd "$1" > /dev/null
# activate recursive ** globbing (will be reset when leaving this script)
# https://stackoverflow.com/questions/9622883/recursive-copy-of-specific-files-in-unix-linux
shopt -s globstar
# copy the source folder content to the output location
# -u will only copy if the timestamp has changed, which is enough to check in our case
cp -u --parents **/*.lua "../$2" &&
echo "Copied folder '$1' to '$2'."
popd > /dev/null

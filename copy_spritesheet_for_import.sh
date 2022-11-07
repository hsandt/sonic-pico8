#!/bin/bash

# Copy spritesheets in the spritesheets folder to the local computer carts folder so we can import them
# inside the data cartridges

# Configuration: paths
spritesheets_path="$(dirname "$0")/spritesheets"
carts_path="$HOME/.lexaloffle/pico-8/carts"

help() {
  echo "Copy a spritesheet to the user carts folder."
  usage
}

usage() {
  echo "Usage: copy_spritesheet_for_import.sh SPRITESHEET_NAME

ARGUMENTS
  SPRITESHEET_NAME          Spritesheet base filename, without .png extension

  -h, --help                Show this help message
"
}

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help )
      help
      exit 0
      ;;
    -* )    # unknown option
      echo "Unknown option: '$1'"
      usage
      exit 1
      ;;
    * )     # store positional argument for later
      positional_args+=("$1")
      shift # past argument
      ;;
  esac
done

if ! [[ ${#positional_args[@]} -eq 1 ]]; then
  echo "Wrong number of positional arguments: found ${#positional_args[@]}, expected 1."
  echo "Passed positional arguments: ${positional_args[@]}"
  usage
  exit 1
fi

# Spritesheet name
spritesheet_name="${positional_args[0]}"

# Copy spritesheet to carts folder
cp "${spritesheets_path}/${spritesheet_name}.png" "$carts_path"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Copy spritesheet '${spritesheet_name}' failed, STOP."
  exit 1
fi

echo "Copied '${spritesheets_path}/${spritesheet_name}.png' to '$carts_path'"

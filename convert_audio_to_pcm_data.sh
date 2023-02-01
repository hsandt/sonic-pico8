#!/bin/bash

# Convert the audio file located in audio/ into PCM data readable by PICO-8 for direct replay
# Must be called offline once before build. This is not called on every build to avoid extra work,
# so make sure to call this manually each time you update the audio file.

# Configuration: paths
audio_path="$(dirname "$0")/audio"
game_src_path="$(dirname "$0")/src"
game_src_template_path="$(dirname "$0")/src_template"

help() {
  echo "Convert the audio file located in audio/ into PCM data readable by PICO-8 for direct replay.

Must be called offline once before build. This is not called on every build to avoid extra work,
so make sure to call this manually each time you update the audio file.

After running this, you must still build and run main_generate_gfx_sage_choir_pcm_data cartridge
to generate the corresponding data carts: gfx_sage_choir_pcm_data_part1.p8 and _part2.p8

The PCM pipeline goes this way:
audio/sage_choir.ogg -> sage_choir.raw -> sage_choir.raw.txt -> data/gfx_sage_choir_pcm_data_part1.p8 and _part2.p8
"

  usage
}

usage() {
  echo "Usage: convert_audio_to_pcm_data.sh AUDIO_FILE PCM_STRING_VAR [OPTIONS]

ARGUMENTS
  AUDIO_FILE                Path to the audio file to convert including extension, relative to audio/
                            The file should be placed in the audio/ folder
                            The format/extension must be supported by ffmpeg, we recommend .wav or .ogg

  PCM_STRING_VAR            Name of the variable stored in the pcm_data table, including underscore prefix if any
                            It will be used to locate where we should inject

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

if ! [[ ${#positional_args[@]} -eq 2 ]]; then
  echo "Wrong number of positional arguments: found ${#positional_args[@]}, expected 1."
  echo "Passed positional arguments: ${positional_args[@]}"
  usage
  exit 1
fi

# Required positional arguments
audio_file="${positional_args[0]}"
pcm_string_var="${positional_args[1]}"

# Construct full path
audio_file_fullpath="${audio_path}/${audio_file}"

# The commands below automate the PCM string generation process explained at:
# - https://www.lexaloffle.com/bbs/?tid=45013
# - https://colab.research.google.com/drive/1HyiciemxfCDS9DxE98UCtNXas5TrM-5e?usp=sharing

# The manual steps are like this:
# 1. Create the sound file you want to play, e.g. sound.wav
# 2. Generate raw bytes found the sound:
#    $ input_filepath="path/to/sound.wav"
#    $ output_name="exported_sound"
#    $ ffmpeg -i "$input_filepath" -f u8 -c:a pcm_u8 -ar 5512 -ac 1 "$output_name".raw
# 3. Encode to text for PICO-8:
#    $ p8scii-encoder "$output_name".raw
#    => outputs exported_sound.raw.txt
# 4. Copy the string in exported_sound.raw.txt below

# Below, we automate those steps, adapting them to our needs

# 1. Create the sound file you want to play, e.g. sound.wav, and place it in the audio/ folder
#    This step must be done before calling this script

# 2. Generate raw bytes found the sound using ffmpeg

# Extract file extension and replace it with "raw"
output_raw_filepath="${audio_file_fullpath%.*}.raw"

echo "# ffmpeg conversion"

# Convert to raw bytes intermediate file with ffmpeg
# Note the -y to overwrite output file without prompt so the script can work headlessly
ffmpeg -i "$audio_file_fullpath" -f u8 -c:a pcm_u8 -ar 5512 -ac 1 "$output_raw_filepath" -y

if [[ $? -ne 0 ]]; then
  echo ""
  echo "ffmpeg failed to convert '$audio_file_fullpath' to raw bytes, STOP."
  exit 1
fi

echo "# OK"

# 3. Encode intermediate raw file to text for PICO-8

echo "# p8scii-encoder"

# This will output to "$output_raw_filepath.txt"
p8scii-encoder "$output_raw_filepath"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "p8scii-encoder failed to encode '$output_raw_filepath', STOP."
  exit 1
fi

echo "# OK"

# 4. Inject PCM string into copy of template file

echo "# Copy template and inject PCM string"

pcm_data_filepath="$game_src_path/data/pcm_data.lua"
cp "$game_src_template_path/pcm_data_template.lua" "$pcm_data_filepath"
python3 -m pico-boots.scripts.replace_variable_with_file_content "$pcm_data_filepath" "$pcm_string_var" "${output_raw_filepath}.txt"

echo "# OK"

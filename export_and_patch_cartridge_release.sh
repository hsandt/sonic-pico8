#!/bin/bash

# Export and patch cartridge releases, then update existing archives with patched executables
# Also apply small tweaks to make release work completely:
# - rename HTML file to index.html to make it playable directly in browser (esp. on itch.io)
# - add '.png' to every occurrence of '.p8' in copy of game source before exporting to PNG
#   (to allow reload() to work with png cartridges)
# Make sure to first build full game in release

# Configuration: paths
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"
game_scripts_path="$(dirname "$0")"
data_path="$(dirname "$0")/data"
# Linux only
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"

# Configuration: cartridge
version=`cat "$data_path/version.txt"`
export_folder="$carts_dirpath/picosonic/v${version}_release"
cartridge_basename="picosonic_v${version}_release"

rel_p8_folder="${cartridge_basename}_cartridges"
rel_png_folder="${cartridge_basename}_png_cartridges"
rel_bin_folder="${cartridge_basename}.bin"
rel_web_folder="${cartridge_basename}_web"

p8_folder="${export_folder}/${rel_p8_folder}"
png_folder="${export_folder}/${rel_png_folder}"
bin_folder="${export_folder}/${rel_bin_folder}"
web_folder="${export_folder}/${rel_web_folder}"

# Cleanup p8 folder in case old extra cartridges remain that would not be overwritten
rm -rf "${p8_folder}/"*

# Cleanup png folder as PICO-8 will prompt before overwriting an existing cartridge with the same name,
# and we cannot reply "y" to prompt in headless script (and png tends to keep old label when overwritten)
# Note that we prefer deleting folder content than folder, to avoid file browser/terminal sometimes
# continuing to show old folder in system bin. Make sure to place blob * outside ""
rm -rf "${png_folder}/"*

# Cleanup bin folder as a bug in PICO-8 makes it accumulate files in .zip for each export (even homonymous files!)
# and we want to remove any extraneous files too
rm -rf "${bin_folder}/"*

# p8 cartridges can be distributed as such, so just copy them to the folder to zip later
mkdir -p "$p8_folder"
cp "${export_folder}/"*.p8 "$p8_folder"

# Create a variant of each non-data cartridge for PNG export, that reloads .p8.png instead of .p8
adapt_for_png_cmd="python3.6 \"$picoboots_scripts_path/adapt_for_png.py\" "${export_folder}/picosonic_*.p8
echo "> $adapt_for_png_cmd"
bash -c "$adapt_for_png_cmd"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Adapt for PNG step failed, STOP."
  exit 1
fi

# Export via PICO-8 editor: PNG cartridges, binaries, HTML
pico8 -x "$game_scripts_path/export_game_release.p8"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Export game release via PICO-8 step failed, STOP."
  exit 1
fi

# ingame is the biggest cartridge so if PNG export fails, this one will fail first
if [[ ! -f "${png_folder}/picosonic_ingame.p8.png" ]]; then
  echo ""
  echo "Exporting PNG cartridge for ingame via PICO-8 failed, STOP. Check that this cartridge compressed size <= 100% even after adding '.png' for reload."
  exit 1
fi

# Patch the runtime binaries in-place with 4x_token, fast_reload, fast_load (experimental) if available
if [[ ! $(ls -A "$bin_folder") ]]; then
  echo ""
  echo "Exporting game release binaries via PICO-8 failed, STOP. Check that each cartridge compressed size <= 100%."
  exit 1
fi

patch_bin_cmd="\"$picoboots_scripts_path/patch_pico8_runtime.sh\" --inplace \"$bin_folder\" \"$cartridge_basename\""
echo "> $patch_bin_cmd"
bash -c "$patch_bin_cmd"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Patch bin step failed, STOP."
  exit 1
fi

# Rename HTML file to index.html for direct play-in-browser
html_filepath="${web_folder}/${cartridge_basename}.html"
mv "$html_filepath" "${web_folder}/index.html"

# Patch the HTML export in-place with 4x_token, fast_reload
js_filepath="${web_folder}/${cartridge_basename}.js"
patch_js_cmd="python3.6 \"$picoboots_scripts_path/patch_pico8_js.py\" \"$js_filepath\" \"$js_filepath\""
echo "> $patch_js_cmd"
bash -c "$patch_js_cmd"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Patch JS step failed, STOP."
  exit 1
fi

# Archiving
# The archives we create here keep all the files under a folder with the full game name
#  to avoid extracting files "in the wild". They are meant for manual distribution and preservation.
# itch.io uses a diff system with butler to only upload minimal patches, but surprisingly works well
#  with folder structure changing slightly (renaming containing folder and executable), so don't worry
#  about providing those customized zip archives to butler.
# Note that for OSX, the .app folder is at the same time the app and the top-level element.
pushd "${export_folder}"

  # P8 cartridges archive (delete existing one to be safe)
  rm -f "${cartridge_basename}_cartridges.zip"
  zip -r "${cartridge_basename}_cartridges.zip" "$rel_p8_folder"

  # PNG cartridges archive (delete existing one to be safe)
  rm -f "${cartridge_basename}_png_cartridges.zip"
  zip -r "${cartridge_basename}_png_cartridges.zip" "$rel_png_folder"

  # PNG cartridges archive (delete existing one to be safe)
  rm -f "${cartridge_basename}_png_cartridges.zip"
  zip -r "${cartridge_basename}_png_cartridges.zip" "$rel_png_folder"

  # HTML archive (delete existing one to be safe)
  rm -f "${cartridge_basename}_web.zip"
  zip -r "${cartridge_basename}_web.zip" "${cartridge_basename}_web"

  # Bin archives
  pushd "${rel_bin_folder}"

    # Linux archive

    # Rename linux folder with full game name so our archive contains a self-explanatory folder ()
    mv "linux" "${cartridge_basename}_linux"

    # To minimize operations, do not recreate the archive, just replace the executable in the archive generated by PICO-8 export
    # with the patched executable. We still get some warnings about "Local Version Needed To Extract does not match CD"
    # on other files, so make the operation quiet (-q)
    zip -q "${cartridge_basename}_linux.zip" "${cartridge_basename}_linux/${cartridge_basename}"


    # OSX archive

    # Replace the executable in the archive generated by PICO-8 export with the patched executable
    zip -q "${cartridge_basename}_osx.zip" "${cartridge_basename}.app/Contents/MacOS/${cartridge_basename}"


    # Windows archive

    # Rename linux folder with full game name so our archive contains a self-explanatory folder as the initial archive
    mv "windows" "${cartridge_basename}_windows"

    # To minimize operations, do not recreate the archive, just replace the executable in the archive generated by PICO-8 export
    # with the patched executable. We still get some warnings about "Local Version Needed To Extract does not match CD"
    # on other files, so make the operation quiet (-q)
    zip -q "${cartridge_basename}_windows.zip" "${cartridge_basename}_windows/${cartridge_basename}.exe"

  popd

popd

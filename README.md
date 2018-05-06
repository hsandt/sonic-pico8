# Sonic PICO-8

A partial clone of classic Sonic the Hedgehog games made with PICO-8

## Build dependency

### picotool

* https://github.com/dansanderson/picotool

The build script (build.sh) only works on Unix platforms.

## Test dependency

### pico-test

* https://github.com/jozanza/pico-test
* npm install -g pico-test

The test script (test.sh) only works on Linux (it uses gnome-terminal).

## Build pipeline

The .sublime-project file contains the most used commands for building the game. It can be also be used to create a new game from a template.

If you use the scripts of this project to create a new game, in order to use *p8tool: edit data* you need to create a pico8 file at data/data.p8 first. To do this, open PICO-8, type *save data*, then copy the boilerplate file to data/data.p8.

## License

### Code

See LICENSE.md

### Assets

Most assets are derivative works of Sonic the Hedgehog, SEGA, adapted and used for the sole purpose of training with PICO-8, whichs uses an 8-bit palette. I only retain copyright for the work of adaptation.

Assets that are not derivative works are under CC BY 4.0.

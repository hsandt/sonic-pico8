# Check the representative file to deduce the main source file and the output path of a build
# arg 1: current file base name
#
# define up to 4 variables:
# MAIN_SOURCE_BASENAME: basename of main source file to build from
# OUTPUT_BASENAME: basename of build output file
# REPLACE_ARG_SUBSTITUTES: arg substitutes option string for replace_strings.py
# ITEST (optional): pure name of the itest, if building an integrated test for pico8
# UTEST (optional): pure name of the utest, if building a unit test for pico8
# "itest[name]" => build from itest_main.lua into itest[name]_[config].p8
# "sandbox" => build from sandbox.lua into sandbox_[config].p8
# else => build from main.lua into sonic-pico8_[config].p8
function define_build_vars {
    echo "Defining build vars..."

    define_output_basename $1

    REPLACE_ARG_SUBSTITUTES="--substitutes"  # try ' and "
    if [[ ${1::5} = "itest" ]] ; then
        ITEST=${1:5}  # extract itest name
        MAIN_SOURCE_BASENAME="itest_main"
        REPLACE_ARG_SUBSTITUTES="$REPLACE_ARG_SUBSTITUTES itest=$ITEST"

        # append dummy gamestates arg substitutes for unused gamestates
        DUMMY_GAMESTATES_ARG_SUBSTITUTES=$(get_dummy_gamestates_arg_substitutes "$ITEST")

        if [[ $? -ne 0 ]]; then
            echo "get_dummy_gamestates_arg_substitutes failed with: \"$DUMMY_GAMESTATES_ARG_SUBSTITUTES\""
            exit 1
        fi

        REPLACE_ARG_SUBSTITUTES="$REPLACE_ARG_SUBSTITUTES $DUMMY_GAMESTATES_ARG_SUBSTITUTES"
        echo "${REPLACE_ARG_SUBSTITUTES}"
    elif [[ ${1::5} = "utest" ]] ; then
        UTEST=${1:5}  # extract itest name
        MAIN_SOURCE_BASENAME="utest_main"
        REPLACE_ARG_SUBSTITUTES="$REPLACE_ARG_SUBSTITUTES utest=$UTEST"
        # only use dummy gamestates for now (most pico8 utests are date tests and don't need gamestates)
        REPLACE_ARG_SUBSTITUTES="$REPLACE_ARG_SUBSTITUTES titlemenu_ver=_dummy credits_ver=_dummy stage_ver=_dummy"
elif [[ $1 = "sandbox" ]]; then
        MAIN_SOURCE_BASENAME="sandbox"
        # only use dummy gamestates
        REPLACE_ARG_SUBSTITUTES="$REPLACE_ARG_SUBSTITUTES titlemenu_ver=_dummy credits_ver=_dummy stage_ver=_dummy"
    else
        MAIN_SOURCE_BASENAME="main"
        # only use default gamestates
        REPLACE_ARG_SUBSTITUTES="$REPLACE_ARG_SUBSTITUTES"
    fi

    # echo "MAIN_SOURCE_BASENAME: '$MAIN_SOURCE_BASENAME'"
    # echo "OUTPUT_BASENAME: '$OUTPUT_BASENAME'"
    # echo "REPLACE_ARG_SUBSTITUTES: '$REPLACE_ARG_SUBSTITUTES'"
    # echo "ITEST: '$ITEST'"
}

# OUTPUT_BASENAME is isolated because run.sh only needs this one
function define_output_basename {
    if [[ ${1::5} = "itest" ]] ; then
        OUTPUT_BASENAME="$1"
    elif [[ ${1::5} = "utest" ]] ; then
        OUTPUT_BASENAME="$1"
    elif [[ $1 = "sandbox" ]]; then
        OUTPUT_BASENAME="sandbox"
    else
        OUTPUT_BASENAME="sonic-pico8"
    fi
}

gamestates=(titlemenu credits stage);

# Return a string containing the dummy gamestates substitutes equality. For itests only
# arg 1: itest base name
function get_dummy_gamestates_arg_substitutes {
    DUMMY_GAMESTATES_ARG_SUBSTITUTES_ARRAY=()

    # retrieve the list of gamestates to activate on first line of the itest
    read -r first_line < "src/game/itests/itest$1.lua"
    if [[ $? -ne 0 ]]; then
        echo "Could not open 'tests/itests/itest$1.lua, cannot determine which gamestates to use, STOP.'"
        return 1
    fi

    # match regex to extract active gamestates string
    gamestates_re="-- gamestates: (.+)"
    if [[ $first_line =~ $gamestates_re ]]; then
        active_gamestates_string=${BASH_REMATCH[1]}
    else
        echo "File 'tests/itests/itest$1.lua doesn't start with '-- gamestates: (states, ...)', cannot determine which gamestates to use, STOP.'"
        return 1
    fi

    # split string by comma
    IFS=',' read -ra active_gamestates <<< $active_gamestates_string

    # mark any non-active gamestate to replace it with a dummy equivalent
    for gamestate in ${gamestates[*]}
    do
        find_in_array $gamestate "${active_gamestates[@]}" || DUMMY_GAMESTATES_ARG_SUBSTITUTES_ARRAY+=("${gamestate}_ver=_dummy")
    done

    echo "${DUMMY_GAMESTATES_ARG_SUBSTITUTES_ARRAY[*]}"
}

# https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value#3689445
# estani's answer
function find_in_array {
  local word=$1
  shift
  for e in "$@"; do [[ "$e" == "$word" ]] && return 0; done
}

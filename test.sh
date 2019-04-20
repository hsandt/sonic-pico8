#!/bin/bash
# $1: test name (module name)

if [[ $# -lt 1 ]] ; then
    echo "test.sh takes 1 mandatory param, 1 optional param and 1 option, provided $#:
    $1: test file pattern
    $2: test filter mode: (default 'standard') 'standard' to filter out all #mute, 'solo' to filter #solo, 'all' to include #mute
    -r or --render to enable rendering in the itest loop (used for $1=headless_itests only)"
    exit 1
fi

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

if [[ ${1::5} = "utest" ]] ; then
	MODULE=${1:5}
else
	MODULE=$1
fi

# shift arguments 1 position so we start reading options at $1
shift

TEST_FILTER_MODE="standard"

# if second argument is not an option, it means it's the positional argument "test filter mode"
# remember to check for "-" not "--" as the shortcut options only use a single hyphen
if [[ "${1::1}" != "-" ]] ; then
	TEST_FILTER_MODE=$1  # should be "all" or "solo"
	shift
fi

RENDER=false

while [[ "$1" != "" ]]; do
    case $1 in
        -r | --render )     shift
                            RENDER=true
                            ;;
        * )                 echo "unknown option: $1"
                            exit 1
    esac
    shift
done

if [[ $MODULE = "all" || -z $MODULE ]] ; then
	TEST_FILE_PATTERN="utest"  # all unit tests
	COVERAGE_OPTIONS="-c .luacov_all"  # we cannot just use default .luacov since it would also affect specific module tests
else
	# prepend "utest" again in case a module name contains another one (e.g. logger c visual_logger)
	TEST_FILE_PATTERN="utest$MODULE"
	COVERAGE_OPTIONS="-c .luacov_current \"/$MODULE\""
fi

if [[ $TEST_FILTER_MODE = "all" ]] ; then
	FILTER=""
	FILTER_OUT=""
	USE_COVERAGE=true
elif [[ $TEST_FILTER_MODE = "solo" ]]; then
	FILTER="--filter \"#solo\""
	FILTER_OUT=""
	# coverage on a file is not relevant when testing one or two functions
	USE_COVERAGE=false
else
	FILTER=""
	FILTER_OUT="--filter-out \"#mute\""
	USE_COVERAGE=true
fi

if [[ $USE_COVERAGE = true ]]; then
	PRE_TEST="rm -f luacov.stats.out luacov.report.out &&"
	POST_TEST="&& luacov $COVERAGE_OPTIONS && grep -C 3 -P \"(?:(?:^|[ *])\*0|\d+%)\" luacov.report.out"
else
	PRE_TEST=""
	POST_TEST=""
fi

EXTRA_ARGS=""

if [[ $RENDER = true ]]; then
	EXTRA_ARGS+="--render"
fi

LUA_PATH="src/?.lua;tests/?.lua"
CORE_TEST="busted tests --lpath=\"$LUA_PATH\" -p \"$TEST_FILE_PATTERN\" $FILTER $FILTER_OUT -c -v -- $EXTRA_ARGS"
TEST_COMMAND="$PRE_TEST $CORE_TEST $POST_TEST"

echo "Testing $1..."
echo "> $TEST_COMMAND"
# Generate luacov report and display all uncovered lines and cover percentages
bash -c "$TEST_COMMAND"

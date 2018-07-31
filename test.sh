#!/bin/bash
# $1: test name (module name)

if [[ $# -lt 1 ]] ; then
    echo "test.sh takes 1 mandatory param and 1 optional param, provided $#:
    $1: test file pattern
    $2: test filter mode: (default 'standard') 'standard' to filter out all #mute, 'solo' to filter #solo, 'all' to include #mute"
    exit 1
fi

if [[ ${1::5} = "utest" ]] ; then
	MODULE=${1:5}
else
	MODULE=$1
fi

if [[ $MODULE = "all" || -z $MODULE ]] ; then
	TEST_FILE_PATTERN="utest"  # all unit tests
	COVERAGE_OPTIONS=""  # default is -c .luacov
else
	# prepend "utest" again in case a module name contains another one (e.g. logger c visual_logger)
	TEST_FILE_PATTERN="utest$MODULE"
	COVERAGE_OPTIONS="-c .luacov_current \"^$MODULE\""
fi

if [[ $2 = "all" ]] ; then
	FILTER=""
	FILTER_OUT=""
	USE_COVERAGE=true
elif [[ $2 = "solo" ]]; then
	FILTER="--filter \"#solo\""
	FILTER_OUT=""
	# coverage on a file is not relevant when testing one or two functions
	USE_COVERAGE=false
else
	FILTER=""
	FILTER_OUT="--filter-out \"#mute\""
	USE_COVERAGE=true
fi

if [[ "$USE_COVERAGE" = true ]]; then
	PRE_TEST="rm -f luacov.stats.out luacov.report.out &&"
	POST_TEST="&& luacov $COVERAGE_OPTIONS && grep -C 3 -P \"(?:(?:^|[ *])\*0|\d+%)\" luacov.report.out"
else
	PRE_TEST=""
	POST_TEST=""
fi

LUA_PATH="src/?.lua;tests/?.lua"
CORE_TEST="busted tests --lpath=\"$LUA_PATH\" -p \"$TEST_FILE_PATTERN\" $FILTER $FILTER_OUT -c -v"
TEST_COMMAND="$PRE_TEST $CORE_TEST $POST_TEST"

echo "Testing $1..."
echo "> $TEST_COMMAND"
# Generate luacov report and display all uncovered lines and cover percentages
bash -c "$TEST_COMMAND"

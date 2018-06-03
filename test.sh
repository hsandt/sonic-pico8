#!/bin/bash
# $1: test name (module name)

if [[ $# -lt 1 ]] ; then
    echo "test.sh takes 1 mandatory param and 1 optional param:
    $1: test file pattern
    $2: test filter mode: (default 'standard') 'standard' to filter out all #mute, 'solo' to filter #solo, 'all' to include #mute"
    exit 1
fi

if [[ ${1::4} = "test" ]] ; then
	MODULE=${1:4}
else
	MODULE=$1
fi

if [[ $MODULE = "all" || -z $MODULE ]] ; then
	TEST_FILE_PATTERN="test"
	COVERAGE_OPTIONS=""
else
	TEST_FILE_PATTERN="$MODULE"
	COVERAGE_OPTIONS="-c .luacov_current \"$MODULE\""
fi

if [[ $2 = "all" ]] ; then
	FILTER=""
	FILTER_OUT=""
elif [[ $2 = "solo" ]]; then
	FILTER="--filter \"#solo\""
	FILTER_OUT=""
else
	FILTER=""
	FILTER_OUT="--filter-out \"#mute\""
fi

LUA_PATH="src/?.lua;tests/?.lua"
TEST_COMMAND="rm -f luacov.stats.out luacov.report.out && busted tests --lpath=\"$LUA_PATH\" -p \"$TEST_FILE_PATTERN\" $FILTER $FILTER_OUT -c -v && luacov $COVERAGE_OPTIONS && grep -P \"(?:[ *]\*0|%)\" luacov.report.out"

echo "Testing $1..."
echo "> $TEST_COMMAND"
# Generate luacov report and display all uncovered lines
bash -c "$TEST_COMMAND"

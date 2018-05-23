#!/bin/bash
# $1: test name (module name)

if [[ $# -lt 1 ]] ; then
    echo "test.sh takes 1 mandatory param and 1 optional param:
    $1: test file pattern
    $2: test filter mode: (default 'standard') 'standard' to filter out all #mute, 'solo' to filter #solo, 'all' to include #mute"
    exit 1
fi

TEST_FILE_PATTERN=32
if [[ $1 = "all" ]] ; then
	TEST_FILE_PATTERN="test"
else
	TEST_FILE_PATTERN="$1"
fi

if [[ $2 = "all" ]] ; then
	FILTER=""
	FILTER_OUT=""
elif [[ $2 = "solo" ]]; then
	FILTER="#solo"
	FILTER_OUT=""
else
	FILTER=""
	FILTER_OUT="--filter-out \"#mute\""
fi

LUA_PATH="src/?.lua;tests/?.lua"
TEST_COMMAND="busted tests --lpath=\"$LUA_PATH\" -p \"$TEST_FILE_PATTERN\" --filter \"$FILTER\" $FILTER_OUT -v"

echo "Testing $1..."
echo "> $TEST_COMMAND"
bash -c "$TEST_COMMAND"

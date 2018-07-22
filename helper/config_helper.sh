# check the representative file to deduce the main source file and the output path of a build
# define up to 4 variables:
# MAIN_SOURCE_BASENAME: basename of main source file to build from
# OUTPUT_BASENAME: basename of build output file
# REPLACE_ARG_SUBSTITUTES: arg substitutes option string for replace_strings.py
# ITEST (optional): pure name of the itest, if building an integrated test
# "itest[name]" => build from itest_main.lua into itest[name]_[config].p8
# "sandbox" => build from sandbox.lua into sandbox_[config].p8
# else => build from main.lua into sonic-pico8_[config].p8
function define_build_vars {
	REPLACE_ARG_SUBSTITUTES="--substitutes"  # try ' and "
	if [[ ${1::5} = "itest" ]] ; then
	    ITEST=${1:5}  # extract itest name
	    MAIN_SOURCE_BASENAME="itest_main"
	    OUTPUT_BASENAME="$1"
	    REPLACE_ARG_SUBSTITUTES="$REPLACE_ARG_SUBSTITUTES itest=$ITEST"
	elif [[ $1 = "sandbox" ]]; then
	    MAIN_SOURCE_BASENAME="sandbox"
	    OUTPUT_BASENAME="sandbox"
	else
	    MAIN_SOURCE_BASENAME="main"
	    OUTPUT_BASENAME="sonic-pico8"
	fi
}

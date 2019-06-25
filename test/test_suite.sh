#!/usr/bin/env bash
#/bin/bash -x

export DEBUG="--verbose"

. assert.sh


## define test helper, see https://github.com/lehmannro/assert.sh/issues/24
assert_statement(){
    # usage cmd exp_stout exp_stder exp_exit_code
    assert "$1" "$2"
    assert "( $1 ) 2>&1 >/dev/null" "$3"
    assert_raises "$1" "$4"
}
#assert_statment "echo foo; echo bar  >&2; exit 1" "foo" "bar" 1


assert_stderr(){
    assert "( $1 ) 2>&1 >/dev/null" "$2"
}
#assert_stderr "echo foo" "bar"

#http://stackoverflow.com/questions/3005963/how-can-i-have-a-newline-in-a-string-in-sh
#http://stackoverflow.com/questions/3005963/how-can-i-have-a-newline-in-a-string-in-sh
export NL=$'\n'

#########################################################################################################################
### script_input_modes

assert_raises "rend.R $RENDR_HOME/test/simple_report.R" 0


assert_end basic_reports


# examples kept as refernce
#########################################################################################################################
### script_input_modes
#
### make sure that scripts can be piped into kscript
#assert "source ${KSCRIPT_HOME}/test/resources/direct_script_arg.sh" "kotlin rocks"
#
### make sure that it runs with remote URLs
#assert "kscript https://raw.githubusercontent.com/holgerbrandl/kscript/master/test/resources/url_test.kts" "I came from the internet"
#assert "kscript https://git.io/fxHBv" "main was called"
#
### there are some dependencies which are not jar, but maybe pom, aar, ..
### make sure they work, too
#assert "kscript ${KSCRIPT_HOME}/test/resources/depends_on_with_type.kts" "getBigDecimal(1L): 1"
#
## repeated compilation of buggy same script should end up in error again
#assert_raises "kscript '1-'; kscript '1-'" 1
#
#assert_end script_input_modes
#
##assert "kscript --package test/resources/package_example.kts" "foo"
##assert "./package_example 1" "package_me_args_1_mem_4772593664"da
##assert "echo 1" "package_me_args_1_mem_4772593664"
##assert_statement 'rm -f kscriptlet* && kscript --package "println(args.size)"' "foo" "bar" 0
#
#
#kscript_nocall() { kotlin -classpath ${KSCRIPT_HOME}/build/libs/kscript.jar kscript.app.KscriptKt "$@";}
#export -f kscript_nocall
#
### temp projects with include symlinks
#assert_raises 'tmpDir=$(kscript_nocall --idea test/resources/includes/include_variations.kts | cut -f2 -d" " | xargs echo); cd $tmpDir && gradle build' 0
#
### Ensure relative includes with in shebang mode
#assert_raises resources/includes/shebang_mode_includes 0
#
### support diamond-shaped include schemes (see #133)
#assert_raises 'tmpDir=$(kscript_nocall --idea test/resources/includes/diamond.kts | cut -f2 -d" " | xargs echo); cd $tmpDir && gradle build' 0
#
### todo reenable interactive mode tests using kscript_nocall
#
#assert_end misc
#
#
#########################################################################################################################
###  run junit-test suite
#
## exit code of `true` is expected to be 0 (see https://github.com/lehmannro/assert.sh)
#assert_raises "./gradlew test"
#
#assert_end junit_tests


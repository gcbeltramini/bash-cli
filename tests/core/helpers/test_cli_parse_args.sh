#!/usr/bin/env bash
set -euo pipefail

test_get_help() {
  local result expected

  result=$(get_help "$MOCK_COMMAND_PATH")
  expected='This section will not be parsed, but the first line will be used by the zsh autocomplete function.

Usage:
  anything hello-world [<positional-param> --my-param=<x> --some-flag]
  anything hello-world many [<names>...]
  anything hello-world my-cmd <pos1> <pos2>
  anything hello-world (cmd1|cmd2) <pos1> <pos2>

Options:
  --my-param=<x>  Some parameter [default: 123]

Examples:
  This section will not be parsed, but the first line will be used by the zsh autocomplete function.'
  assertEquals "$expected" "$result"
}

test_parse_args() {
  local result expected help_text
  help_text=$(get_help "$MOCK_COMMAND_PATH")

  result=$(parse_args "$help_text" 'hello-world=' '--help')
  expected="$help_text"
  assertEquals "With the --help parameter, it returns the help text" "$expected" "$result"

  result=$(parse_args "$help_text" 'hello-world')
  expected='# <<-- docopt parsed arguments -->>
export cmd1="false"
export cmd2="false"
export hello_world="true"
export many="false"
export my_cmd="false"
export my_param="123"
export names=()
export pos1=""
export pos2=""
export positional_param=""
export some_flag="false"
# <<----------------------------->>'
  assertEquals "$expected" "$result"

  result=$(parse_args "$help_text" 'hello-world' 'John Doe' '--some-flag')
  expected='# <<-- docopt parsed arguments -->>
export cmd1="false"
export cmd2="false"
export hello_world="true"
export many="false"
export my_cmd="false"
export my_param="123"
export names=()
export pos1=""
export pos2=""
export positional_param="John Doe"
export some_flag="true"
# <<----------------------------->>'
  assertEquals "$expected" "$result"

  result=$(parse_args "$help_text" 'hello-world' 'many' 'Mr. Smith' 'Mrs. Smith')
  expected='# <<-- docopt parsed arguments -->>
export cmd1="false"
export cmd2="false"
export hello_world="true"
export many="true"
export my_cmd="false"
export my_param="123"
export names=("Mr. Smith" "Mrs. Smith")
export pos1=""
export pos2=""
export positional_param=""
export some_flag="false"
# <<----------------------------->>'
  assertEquals "$expected" "$result"

  result=$(parse_args "$help_text" 'hello-world' 'my-cmd' 12 34)
  expected='# <<-- docopt parsed arguments -->>
export cmd1="false"
export cmd2="false"
export hello_world="true"
export many="false"
export my_cmd="true"
export my_param="123"
export names=()
export pos1="12"
export pos2="34"
export positional_param=""
export some_flag="false"
# <<----------------------------->>'
  assertEquals "$expected" "$result"

  result=$(parse_args "$help_text" 'hello-world' 'cmd2' 45 567)
  expected='# <<-- docopt parsed arguments -->>
export cmd1="false"
export cmd2="true"
export hello_world="true"
export many="false"
export my_cmd="false"
export my_param="123"
export names=()
export pos1="45"
export pos2="567"
export positional_param=""
export some_flag="false"
# <<----------------------------->>'
  assertEquals "$expected" "$result"
}

test__is_str_to_eval() {
  # shellcheck disable=SC2034
  local -r multi_line_exports="# foo
export x=123
# bar
export abc=qwerty"
  # shellcheck disable=SC2034
  local -r multi_line_mixed="export x=123
abc=qwerty"

  assertTrue '_is_str_to_eval "export xyz=1234"'
  assertFalse '_is_str_to_eval "# export xyz=1234"'

  # shellcheck disable=SC2016
  assertTrue "multi-line all-export block is recognized" \
    '_is_str_to_eval "$multi_line_exports"'

  # shellcheck disable=SC2016
  assertFalse "block with non-export line is rejected" \
    '_is_str_to_eval "$multi_line_mixed"'

  # value contains a literal backslash-n (from safe quoting) — must not split the line
  assertTrue "_is_str_to_eval \"export name='\\\\n'\""
}

test_eval_args() {
  local result expected

  assertTrue "[ -z ${xyz:-} ] && [ -z ${a:-} ]"
  eval_args "# foo
export xyz=1234
 # bar
export a='bb'"
  assertTrue "[ \"${xyz:-}\" == \"1234\" ] && [ \"${a:-}\" == \"bb\" ]"
  unset xyz a

  assertTrue "[ -z ${xyz:-} ] && [ -z ${a:-} ]"
  result=$(eval_args "No variable to be exported")
  expected="No variable to be exported"
  assertEquals "$expected" "$result"
}

test_get_command_name() {
  local result expected

  result=$(get_command_name "foo/bar/qwerty.sh")
  expected="qwerty"
  assertEquals "$expected" "$result"

  result=$(get_command_name "foo/bar/")
  expected="bar"
  assertEquals "$expected" "$result"
}

test__parse_help_from_file() {
  local result expected

  result=$(_parse_help_from_file "$MOCK_COMMAND_PATH" 'Foo')
  expected='# <<-- docopt parsed arguments -->>
export cmd1="false"
export cmd2="false"
export hello_world="true"
export many="false"
export my_cmd="false"
export my_param="123"
export names=()
export pos1=""
export pos2=""
export positional_param="Foo"
export some_flag="false"
# <<----------------------------->>'
  assertEquals "$expected" "$result"

  result=$(_parse_help_from_file "$MOCK_COMMAND_PATH" 'many' 'Foo' 'Bar Baz')
  expected='# <<-- docopt parsed arguments -->>
export cmd1="false"
export cmd2="false"
export hello_world="true"
export many="true"
export my_cmd="false"
export my_param="123"
export names=("Foo" "Bar Baz")
export pos1=""
export pos2=""
export positional_param=""
export some_flag="false"
# <<----------------------------->>'
  assertEquals "$expected" "$result"
}

test_parse_help() {
  local result expected

  result=$("$MOCK_COMMAND_PATH" 'foo' '--my-param=42' '--some-flag')
  expected="--my-param='42'
--some-flag='true'"
  assertEquals "$expected" "$result"

  result=$("$MOCK_COMMAND_PATH" 'many' 'Foo Bar' 'Qwerty')
  expected="name 0 = 'Foo Bar'
name 1 = 'Qwerty'"
  assertEquals "$expected" "$result"

  result=$("$MOCK_COMMAND_PATH" 'my-cmd' 'Foo' 'Qwer ty')
  expected="pos1='Foo'
pos2='Qwer ty'"
  assertEquals "$expected" "$result"

  result=$("$MOCK_COMMAND_PATH" 'cmd2' 'Ab 12' 'CDE')
  expected="cmd1='false'
cmd2='true'
pos1='Ab 12'
pos2='CDE'"
  assertEquals "$expected" "$result"
}

oneTimeSetUp() {
  export CLI_DIR=$PWD
  MOCK_COMMAND_PATH="tests/resources/commands/hello/hello-world.sh"
  . core/helpers/cli_parse_args.sh
}

. scripts/shunit2

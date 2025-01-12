#!/usr/bin/env bash
set -euo pipefail

test__mycli_list_commands() {
  local result expected

  result=$(_mycli_list_commands "$TEST_COMMANDS_PATH")
  expected=$(
    cat <<-EOF
	update
	hello
	update
	version
EOF
  )
  assertEquals "$expected" "$result"
}

test__mycli_list_subcommands() {
  local result expected

  result=$(_mycli_list_subcommands "$TEST_COMMANDS_PATH" "update")
  expected=""
  assertEquals "$expected" "$result"

  result=$(_mycli_list_subcommands "$TEST_COMMANDS_PATH" "version")
  expected=""
  assertEquals "$expected" "$result"

  result=$(_mycli_list_subcommands "$TEST_COMMANDS_PATH" "hello")
  expected="hello-world"
  assertEquals "$expected" "$result"
}

test__mycli_extract_docopt_section() {
  local result expected

  result=$(_mycli_extract_docopt_section "$HELP" "usage")
  expected=$(
    cat <<-EOF
	  some-command hello-world [<positional-param> --my-param=<x> --some-flag]
	  some-command hello-world many [<names>...] [options]
	  some-command hello-world my-cmd <pos1> <pos2>
	  some-command hello-world (cmd1|cmd2) <pos1> <pos2>
	  foo bar --param=<x> --flag
EOF
  )
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_docopt_section "$HELP" "options")
  expected=$(
    cat <<-EOF
	  --my-param=<x>  Some parameter [default: 123]
	  --another-param
EOF
  )
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_docopt_section "$HELP" "no-section")
  expected=""
  assertEquals "$expected" "$result"
}

test__mycli_find_usage_lines() {
  local result expected

  result=$(_mycli_find_usage_lines "$HELP" "some-command" "hello-world")
  expected=$(
    cat <<-EOF
	  some-command hello-world [<positional-param> --my-param=<x> --some-flag]
	  some-command hello-world many [<names>...] [options]
	  some-command hello-world my-cmd <pos1> <pos2>
	  some-command hello-world (cmd1|cmd2) <pos1> <pos2>
EOF
  )
  assertEquals "$expected" "$result"

  result=$(_mycli_find_usage_lines "$HELP" "foo" "bar")
  expected="  foo bar --param=<x> --flag"
  assertEquals "$expected" "$result"
}

test__mycli_extract_parameters() {
  local result expected

  result=$(_mycli_extract_parameters "foo bar baz -q --v --qwe=1 --qwe-rty <some-param> [--some-param=<x> --my-flag]")
  expected=$(
    cat <<-EOF
	-q
	--v
	--qwe
	--qwe-rty
	--some-param
	--my-flag
EOF
  )
  assertEquals "$expected" "$result"

  # Concatenating the usage line and the "Options" section
  # (it doesn't get the parameter "-f" if it's directly preceded by "\n")
  result=$(_mycli_extract_parameters "$(echo -e "foo bar --foo Options:\n--bar  Some description\n -f, --foo")")
  expected=$(
    cat <<-EOF
	--foo
	--bar
	-f
	--foo
EOF
  )
  assertEquals "$expected" "$result"
}

test__mycli_extract_additional_commands() {
  local result expected

  result=$(_mycli_extract_additional_commands "foo bar [<positional-param> --my-param=<x> --some-flag]")
  expected=""
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_additional_commands "my program (run [--fast] | jump [--high])")
  expected=$(cat <<-EOF
	run
	jump
EOF
  )
  assertEquals "$expected" "$result"

  # The function works by removing everything after the commands, so let's test a few different cases
  result=$(_mycli_extract_additional_commands "foo bar qwerty asdf -x [-y <pos-param> --my-param=<x> --some-flag]")
  expected=$(cat <<-EOF
	qwerty
	asdf
EOF
  )
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_additional_commands "foo bar qwerty asdf [-y <pos-param> --my-param=<x> --some-flag]")
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_additional_commands "foo bar qwerty asdf <pos-param> [-y --my-param=<x> --some-flag]")
  assertEquals "$expected" "$result"

  # Test with multiple usage lines and spaces in the beginning
  result=$(_mycli_extract_additional_commands "$(echo -e "  foo bar qwe rty <pos-param>\n  foo bar qwerty asdf -y")")
  expected=$(cat <<-EOF
	qwe
	rty
	qwerty
	asdf
EOF
  )
  assertEquals "$expected" "$result"
}

test__mycli_extract_arguments() {
  local result expected

  result=$(_mycli_extract_arguments "$HELP" "some-command" "hello-world")
  expected=$(cat <<-EOF
	--my-param
	--some-flag
	--my-param
	--another-param
	many
	my-cmd
	cmd1
	cmd2
	--help
EOF
  )
  assertEquals "$expected" "$result"
}

oneTimeSetUp() {
  . core/cli_root/autocomplete.bash

  TEST_COMMANDS_PATH="tests/resources/commands"

  HELP=$(
    cat <<-EOF
	This section will not be parsed, but the first line will be used by the zsh autocomplete function.

	Usage:
	  some-command hello-world [<positional-param> --my-param=<x> --some-flag]
	  some-command hello-world many [<names>...] [options]
	  some-command hello-world my-cmd <pos1> <pos2>
	  some-command hello-world (cmd1|cmd2) <pos1> <pos2>
	  foo bar --param=<x> --flag

	Options:
	  --my-param=<x>  Some parameter [default: 123]
	  --another-param

	Examples:
	  This section will not be parsed, but the first line will be used by the zsh autocomplete function.
EOF
  )
}

. scripts/shunit2

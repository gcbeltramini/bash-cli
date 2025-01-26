#!/usr/bin/env bash
set -euo pipefail

# ==================================================================================================
# Common functions for bash and zsh
# ==================================================================================================

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
  local result expected usage

  usage=$(cat <<-EOF
	foo bar baz -q --v --qwe=1 --qwe-rty <some-param> -- [--some-param=<x> --my-flag]
	-f FILE  File name
	--some_param=FILE_NAME  Some parameter
EOF
  )
  result=$(_mycli_extract_parameters "$usage")
  expected=$(
    cat <<-EOF
	-q
	--v
	--qwe
	--qwe-rty
	--some-param
	--my-flag
	-f
	--some_param
EOF
  )
  assertEquals "$expected" "$result"

  # Concatenating the usage line and the "Options" section
  result=$(_mycli_extract_parameters "$(echo -e "foo bar --foo Options:\n--bar  Some description\n-f, --foo")")
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

  result=$(_mycli_extract_additional_commands "foo bar [<positional-param> --my-param=<x> --some-flag --fname=FILE_NAME]")
  expected=""
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_additional_commands "my program (run [--fast] | jump [--high] | walk_around)")
  expected=$(
    cat <<-EOF
	run
	jump
	walk_around
EOF
  )
  assertEquals "$expected" "$result"

  # The function works by removing everything after the commands, so let's test a few different cases
  result=$(_mycli_extract_additional_commands "foo bar qwerty asdf -x [-y <pos-param> --my-param=<x> --some-flag]")
  expected=$(
    cat <<-EOF
	qwerty
	asdf
EOF
  )
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_additional_commands "foo bar qwerty asdf [-y <pos-param> --my-param=<x> --some-flag]")
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_additional_commands "foo bar qwerty asdf <pos-param> [-y --my-param=<x> --some-flag]")
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_additional_commands "foo bar qwerty asdf <pos-param> [-y --my-param=<x> --some-flag] -f FILE")
  assertEquals "$expected" "$result"

  # Test with multiple usage lines and spaces in the beginning
  result=$(_mycli_extract_additional_commands "$(echo -e "  foo bar qwe rty <pos-param>\n  foo bar qwerty asdf -y")")
  expected=$(
    cat <<-EOF
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
  expected=$(
    cat <<-EOF
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

# ==================================================================================================
# Functions for zsh only
# ==================================================================================================

test__mycli_list_subcommands_and_description() {
  local result expected

  result=$(_mycli_list_subcommands_and_description "$TEST_COMMANDS_PATH" "hello")
  expected="hello-world:This section will not be parsed, but the first line will be used by the zsh autocomplete function."
  assertEquals "$expected" "$result"
}

test__mycli_extract_parameter_names() {
  local result expected

  result=$(_mycli_extract_parameter_names "$DOCOPT_OPTIONS")
  expected=$PARAMETER_NAMES_IN_OPTIONS
  assertEquals "$expected" "$result"
}

test__mycli_get_arg_description() {
  local result expected

  result=$(_mycli_get_arg_description "command-x" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="Some X command"
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "command_y" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="Some Y command"
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "-h" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="Show this screen."
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--help" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="Show this screen."
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--version" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="Show version."
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--my-param" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="Some parameter [default: 123]"
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--my" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected=""
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "x" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected=""
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--coefficient" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="The K coefficient [default: 2.95]"
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--another-param" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected=""
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "-f" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="File name"
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "-m" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="Some flag"
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--my-flag" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="Some flag"
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "-o" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected='without comma, with "=" sign'
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--output" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected='without comma, with "=" sign'
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "-i" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected='with comma, without "=" sign'
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--input" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected='with comma, without "=" sign'
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "--directory" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected="Some directory [default: ./]"
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "FILE" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected=""
  assertEquals "$expected" "$result"

  result=$(_mycli_get_arg_description "file" "$DOCOPT_OPTIONS" "$PARAMETER_NAMES_IN_OPTIONS")
  expected=""
  assertEquals "$expected" "$result"
}

test__mycli_get_args_description() {
  local result expected

  local args=$(
    cat <<-EOF
	-m
	--input
	--something-else
	--directory
EOF
  )
  result=$(_mycli_get_args_description "$args" "$DOCOPT_OPTIONS")
  expected=$(
    cat <<-EOF
	-m:Some flag
	--input:with comma, without "=" sign
	--something-else:<no description>
	--directory:Some directory [default: ./]
EOF
  )
  assertEquals "$expected" "$result"
}

test__mycli_extract_arguments_with_descriptions() {
  local result expected

  result=$(_mycli_extract_arguments_with_descriptions "$HELP_ZSH" "foo" "bar")
  expected=$(
    cat <<-EOF
	--directory:Some directory [default: ./]
	--coefficient:The K coefficient [default: 2.95]
	--help:Show help message
EOF
  )
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_arguments_with_descriptions "$HELP_ZSH" "some-command" "hello-world")
  expected=$(
    cat <<-EOF
	--my-param:Some parameter [default: 123]
	--my-flag:Some flag
	command_y:Some Y command
	cmd1:<no description>
	cmd2:<no description>
	--help:Show help message
EOF
  )
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_arguments_with_descriptions "$HELP_ZSH" "some-command" "with-opts")
  expected=$(
    cat <<-EOF
	-f:File name
	-h:Show this screen.
	--help:Show this screen.
	--version:Show version.
	--my-param:Some parameter [default: 123]
	--coefficient:The K coefficient [default: 2.95]
	--another-param:<no description>
	-m:Some flag
	--my-flag:Some flag
	-o:without comma, with "=" sign
	--output:without comma, with "=" sign
	-i:with comma, without "=" sign
	--input:with comma, without "=" sign
	--directory:Some directory [default: ./]
	command-x:Some X command
EOF
  )
  assertEquals "$expected" "$result"
}

# ==================================================================================================
# Setup
# ==================================================================================================

oneTimeSetUp() {
  . core/cli_root/autocomplete_helpers.sh

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
EOF
  )

  DOCOPT_OPTIONS=$(
    cat <<-EOF
	command-x     Some X command
  command_y     Some Y command
	-h --help     Show this screen.
	--version     Show version.
	--my-param=<x>  Some parameter [default: 123]
	--coefficient=K  The K coefficient [default: 2.95]
	--another-param
	-f FILE  File name
	-m, --my-flag  Some flag
	-o FILE_NAME --output=FILE_NAME       without comma, with "=" sign
	-i <file>, --input <file>   with comma, without "=" sign
	--directory=DIR  Some directory [default: ./]
EOF
  )

  PARAMETER_NAMES_IN_OPTIONS=$(
    cat <<-EOF
	command-x
	command_y
	-h --help
	--version
	--my-param
	--coefficient
	--another-param
	-f
	-m  --my-flag
	-o --output
	-i   --input
	--directory
EOF
  )
  HELP_ZSH=$(
    cat <<-EOF
	This section will not be parsed, but the first line will be used by the zsh autocomplete function.

	Usage:
	  foo bar --directory=<dir> --coefficient=K
	  some-command hello-world [<positional-param> --my-param=<x> --my-flag]
	  some-command with-opts command-x [<names>...] -f FILE_NAME [options]
	  some-command hello-world command_y <pos1> <pos2>
	  some-command hello-world (cmd1|cmd2) <pos1> <pos2>

	Options:
	$DOCOPT_OPTIONS
EOF
  )
}

. scripts/shunit2

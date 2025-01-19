#!/usr/bin/env bash
set -euo pipefail

test__mycli_list_subcommands_and_description() {
  local result expected

  result=$(_mycli_list_subcommands_and_description "$TEST_COMMANDS_PATH" "hello")
  expected="hello-world:This section will not be parsed, but the first line will be used by the zsh autocomplete function."
  assertEquals "$expected" "$result"
}

test__mycli_extract_parameter_names() {
  local result expected docopt_options

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

  result=$(_mycli_extract_arguments_with_descriptions "$HELP" "foo" "bar")
  expected=$(
    cat <<-EOF
	--directory:Some directory [default: ./]
	--coefficient:The K coefficient [default: 2.95]
	--help:Show help message
EOF
  )
  assertEquals "$expected" "$result"

  result=$(_mycli_extract_arguments_with_descriptions "$HELP" "some-command" "hello-world")
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

  result=$(_mycli_extract_arguments_with_descriptions "$HELP" "some-command" "with-opts")
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

oneTimeSetUp() {
  . core/cli_root/autocomplete.zsh

  TEST_COMMANDS_PATH="tests/resources/commands"
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
  HELP=$(
    cat <<-EOF
	Explanation about the command.

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

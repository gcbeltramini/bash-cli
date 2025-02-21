#!/usr/bin/env bash
set -o pipefail

# ==================================================================================================
# Common functions for bash and zsh
# ==================================================================================================

_mycli_list_commands() {
  # List all commands available in the CLI.
  #
  # Usage:
  #   _mycli_list_commands <commands_dir>
  #
  # Examples:
  #   _mycli_list_commands "$MYCLI_HOME/commands" # --> "hello update version"
  local -r commands_dir=$1

  find "$commands_dir" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -exec basename {} \;
  echo "update"
  echo "version"
}

_mycli_list_subcommands() {
  # List all subcommands available in the CLI.
  #
  # Usage:
  #   _mycli_list_subcommands <commands_dir> <command>
  #
  # Examples:
  #   _mycli_list_subcommands "$MYCLI_HOME/commands" "hello" # --> "world"
  local -r commands_dir=$1
  local -r command=$2

  # Part of this code is the same as the CLI function `list_commands`
  find "$commands_dir" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    -path "${commands_dir}/${command}*/*" \
    -name "*.sh" \
    -exec basename {} \; |
    sed "s:\.sh$::"
}

_mycli_extract_docopt_section() {
  # Extract a section from the help message of a command (the section name is not returned).
  #
  # Usage:
  #   _mycli_extract_docopt_section <help> <section>
  #
  # Examples:
  #   _mycli_extract_docopt_section "$help" "usage"
  #   _mycli_extract_docopt_section "$help" "options"
  local -r help=$1
  local -r section=$2
  echo "$help" | sed -n "/^$section:/I,/^$/p" | sed '/^[[:space:]]*$/d' | tail -n +2
}

_mycli_find_usage_lines() {
  # Find the usage line in the help message of a command.
  #
  # Usage:
  #   _mycli_find_usage_lines <help> <cmd1> <cmd2>
  #
  # Examples:
  #   _mycli_find_usage_lines "$help" "hello" "world" # --> "hello world ..."
  local -r help=$1
  local -r cmd1=$2
  local -r cmd2=$3

  local -r docopt_usage=$(_mycli_extract_docopt_section "$help" "usage")
  echo "$docopt_usage" | grep "^ *$cmd1  *$cmd2 " || :
}

_mycli_extract_parameters() {
  # Extract the parameters from the usage of a command.
  #
  # Usage:
  #   _mycli_extract_parameters <usage>
  #
  # Examples:
  #   _mycli_extract_parameters "$usage" # --> "--foo --help --some-flag"
  local -r usage=$1

  # Extract the parameters that:
  # - start with a dash ("-")
  # - are not preceded by any of "[a-zA-Z0-9_<" ("[" must appear in the beginning of the negation "[^...]")
  # - end before any of "] =,": "--foo --foo=42 --bar]" or "-f, --foo" (only appears in the options)
  # - exclude the 'parameter' "--"
  echo "$usage" |
    sed 's/^/ /' |
    grep -oE -- '[^[a-zA-Z0-9_<]-[^] =,]+' |
    sed 's/^[[:space:]]*//' |
    grep -vE '^--$' || :
}

_mycli_extract_additional_commands() {
  # Extract additional commands from the usage of a command.
  #
  # Usage:
  #   _mycli_extract_additional_commands <usage_lines>
  #
  # Examples:
  #   _mycli_extract_additional_commands "$usage_lines" # --> "foo ..."
  local -r usage_line=$1

  echo "$usage_line" |
    sed 's/^[[:space:]]*//' |                                # remove spaces from the beginning
    cut -d' ' -f3- |                                         # remove the first two words
    tr '[]()|' ' ' |                                         # replace brackets, parentheses and pipes with spaces
    grep -o -- '[^ A-Z]*' |                                  # extract words
    sed 's/^[<-].*$// ; /^_$/d ; s/^options$// ; /^$/d' || : # remove parameters and empty lines
}

_mycli_extract_arguments() {
  # Extract the arguments from the help message of a command. The help content must follow the
  # docopt format.
  #
  # Usage:
  #   _mycli_extract_arguments <help> <cmd1> <cmd2>
  #
  # Examples:
  #   _mycli_extract_arguments "$help" "hello" "world" # --> "--foo --help --some-flag abc"
  local -r help=$1
  local -r cmd1=$2
  local -r cmd2=$3

  # Add "--help" because it's always available and is normally not declared in the usage line
  local -r help_param="--help"

  # Extract usage from the help message
  local -r usage_lines=$(_mycli_find_usage_lines "$help" "$cmd1" "$cmd2")

  if [[ -z "$usage_lines" ]]; then
    echo "$help_param"
    return 0
  fi

  # Extract the "Options" section when "[options]" is declared in the usage line
  if grep -q '\[options\]' <<<"$usage_lines"; then
    local -r docopt_options=$(_mycli_extract_docopt_section "$help" "options")
  else
    local -r docopt_options=""
  fi

  # Extract parameters from the usage line and possibly the "Options" section
  local -r params=$(_mycli_extract_parameters "$usage_lines $docopt_options")

  # Extract additional commands from the usage line
  local -r additional_commands=$(_mycli_extract_additional_commands "$usage_lines")

  echo -e "$params\n$additional_commands\n$help_param"
}

# ==================================================================================================
# Functions for zsh only
# ==================================================================================================

_mycli_list_commands_and_description() {
  # List all commands and their descriptions available in the CLI.
  #
  # Usage:
  #   _mycli_list_commands_and_description <commands_dir>
  #
  # Examples:
  #   _mycli_list_commands_and_description "$MYCLI_HOME/commands" # --> "hello:Say hello\nupdate:Update mycli\nversion:Show mycli version"
  local -r commands_dir=$1

  find "$commands_dir" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -exec basename {} \; | while read -r command; do
    if [[ -s "$commands_dir/$command/README.md" ]]; then
      # first non-empty line not starting with "#" in the README file
      description=$(grep -m 1 -vE '^#|^[[:space:]]*$' "$commands_dir/$command/README.md")
    else
      description="<no description>"
    fi
    echo "$command:$description"
  done
  echo "update:Update mycli"
  echo "version:Show mycli version"
}

_mycli_list_subcommands_and_description() {
  # List all subcommands and their descriptions available in the CLI.
  #
  # Usage:
  #   _mycli_list_subcommands_and_description <commands_dir> <command>
  #
  # Examples:
  #   _mycli_list_subcommands_and_description "$MYCLI_HOME/commands" "hello" # --> "world:Say hello.\nfoo:Say bar"
  local -r commands_dir=$1
  local -r command=$2

  find "$commands_dir" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    -path "${commands_dir}/${command}*/*" \
    -name "*.sh" | while read -r file; do

    filename=$(basename "$file" ".sh")
    # first line starting with "##?":
    description=$(grep -m 1 '^##?' "$file" | sed 's/^##? *//')
    echo -e "$filename:$description"
  done
}

_mycli_extract_parameter_names() {
  # Remove the description of a parameter from the docopt options.
  #
  # 1. Remove leading spaces (up to 5; more than that is considered part of the description)
  # 2. Remove everything after the first two spaces and content inside "<>"
  # 3. Replace "=" and "," with spaces
  # 4. Remove trailing words starting with uppercase letters
  # 5. Remove trailing spaces
  # 6. Remove empty lines
  #
  # Usage:
  #   _mycli_extract_parameter_names <docopt_options>
  #
  # Examples:
  #   _mycli_extract_parameter_names "$docopt_options" # --> "--foo\n--help\n--some-flag"
  local -r docopt_options=$1

  # The number of spaces limited to 5 must be consistent with function `_mycli_get_arg_description`
  echo "$docopt_options" | sed -E '
    s/^[[:space:]]{0,5}// ;
    s/ {2,}.*// ; s/<[^>]+>//g ;
    s/[=,]/ /g ;
    s/[[:space:]]+[A-Z][^ ]*//g ;
    s/[[:space:]]+$//g ;
    /^[[:space:]]*$/d
  '
}

_mycli_get_arg_description() {
  # Get the description for a specific argument.
  #
  # Usage:
  #   _mycli_get_arg_description <arg> <docopt_options> <parameter_names_in_options>
  #
  # Examples:
  #   _mycli_get_arg_description "--foo" "$docopt_options" "$parameter_names_in_options" # --> "Foo description"
  local -r arg=$1
  local -r docopt_options=$2
  local -r parameter_names_in_options=$3
  local line_number

  # Remove lines with more than 5 leading spaces (description lines). This must be consistent with
  # the function `_mycli_extract_parameter_names`.
  local -r docopt_options_first_lines=$(sed -E '/^[[:space:]]{6,}/d' <<<"$docopt_options")

  if line_number=$(grep -nE -- "(^| )$arg( |$)" <<<"$parameter_names_in_options" | cut -d: -f1); then
    sed -n "${line_number}p" <<<"$docopt_options_first_lines" |
      sed 's/^[[:space:]]*//' |
      grep -Eo ' {2,}.*' |
      sed 's/^[[:space:]]*//' || :
  else
    echo ""
  fi
}

_mycli_get_args_description() {
  # Extract argument descriptions from docopt options.
  #
  # Usage:
  #   _mycli_get_args_description <args> <docopt_options>
  #
  # Examples:
  #   _mycli_get_args_description "--foo\n--some-flag" "$docopt_options" # --> "--foo:Foo description\n--some-flag:Some flag"
  local -r args=$1
  local -r docopt_options=$2
  local -r description_fallback="<no description>"
  local -r options_without_descriptions=$(_mycli_extract_parameter_names "$docopt_options")

  local args_description=""
  local description
  while IFS= read -r arg; do
    # Fetch the description for each argument
    description=$(_mycli_get_arg_description "$arg" "$docopt_options" "$options_without_descriptions")
    args_description+="$arg:${description:-$description_fallback}\n"
  done <<<"$args"

  echo -e "$args_description"
}

_mycli_extract_arguments_with_descriptions() {
  # Extract the arguments and possibly their description from the help message of a command. The
  # help content must follow the docopt format.
  #
  # Usage:
  #   _mycli_extract_arguments_with_descriptions <help> <cmd1> <cmd2>
  #
  # Examples:
  #   _mycli_extract_arguments_with_descriptions "$help" "hello" "world"
  #   # --> "--foo:Foo description\n--help:Show help message\n--some-flag:Some flag"
  local -r help=$1
  local -r cmd1=$2
  local -r cmd2=$3

  # Add "--help" because it's always available and is normally not declared in the usage line
  # (this will override the description of the "--help" parameter)
  local -r help_description="--help:Show help message"

  # Extract usage from the help message
  local -r usage_lines=$(_mycli_find_usage_lines "$help" "$cmd1" "$cmd2")

  if [[ -z "$usage_lines" ]]; then
    echo "$help_description"
    return 0
  fi

  # Extract the "Options" section to get the parameters description
  local -r docopt_options=$(_mycli_extract_docopt_section "$help" "options")

  # Extract parameters from the usage line and possibly the "Options" section
  if grep -q '\[options\]' <<<"$usage_lines"; then
    local -r params=$(_mycli_extract_parameters "$usage_lines $docopt_options")
  else
    local -r params=$(_mycli_extract_parameters "$usage_lines")
  fi

  local -r additional_commands=$(_mycli_extract_additional_commands "$usage_lines")
  local -r args=$(echo -e "$params\n$additional_commands" | sed '/^[[:space:]]*$/d')
  local -r args_description=$(_mycli_get_args_description "$args" "$docopt_options")

  echo -e "$args_description\n$help_description" |
    sed '/^[[:space:]]*$/d' |
    awk -F':' '!seen[$1]++'
}

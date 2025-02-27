#!/usr/bin/env bash
set -euo pipefail

show_env_vars() {
  # Show environment variable name and value.
  #
  # Usage:
  #   show_env_vars <pattern>
  #
  # Examples:
  #   show_env_vars "^HOMEBREW_"
  local -r regex_pattern=$1
  env | grep -E "$regex_pattern" || :
}

show_env_vars_name() {
  # Show environment variable name.
  #
  # Usage:
  #   show_env_vars_name <pattern>
  #
  # Examples:
  #   show_env_vars_name "^HOMEBREW_"
  local -r regex_pattern=$1
  env | grep -E "$regex_pattern" | cut -d= -f1 || :
}

is_set() {
  # Check if a variable is set.
  #
  # Usage:
  #   is_set <var_name>
  #
  # Examples:
  #   is_set x || echo "'x' is not set."
  #   declare x; is_set x || echo "'x' is not set."
  #   x=123; is_set x && echo "'x' is set."
  local -r var_name=$1
  [[ -n ${!var_name+x} ]]
}

is_array() {
  # Check if variable is an array.
  #
  # Usage:
  #   is_array <var>
  local -r var_name=$1
  declare -p "$var_name" 2>/dev/null | grep -q 'declare -[aA]'
}

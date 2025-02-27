#!/usr/bin/env bash
set -euo pipefail

to_uppercase() {
  # Convert string into all uppercase characters.
  #
  # Usage:
  #   to_uppercase <text>
  #
  # Examples:
  #   to_uppercase "Foo BaR" # --> "FOO BAR"
  local -r text=$1
  echo "$text" | tr '[:lower:]' '[:upper:]'
}

to_lowercase() {
  # Convert string into all lowercase characters.
  #
  # Usage:
  #   to_lowercase <text>
  #
  # Examples:
  #   to_lowercase "Foo BaR" # --> "foo bar"
  local -r text=$1
  echo "$text" | tr '[:upper:]' '[:lower:]'
}

repeat_char() {
  # Repeat a character N times.
  #
  # Usage:
  #   repeat_char <char> <count>
  #
  # Examples:
  #   repeat_char "x" "4" # --> "xxxx"
  local -r char=$1
  local -r count=$2
  if [[ $count -lt 1 ]]; then
    echo ''
  else
    printf -- "$char%.0s" $(seq 1 "$count")
  fi
}

surround_text() {
  # Surround text with repeated character until specified length.
  #
  # Usage:
  #   surround_text <text> <n_chars> <char_repeat>
  #
  # Examples:
  #   surround_text " Hello " 20 "-" # --> "------ Hello -------"
  local -r text=$1
  local -r n_chars=$2
  local -r char_repeat=$3

  local -r length=${#text}
  if [[ $n_chars -gt $((length + 2)) ]]; then
    local -r n_chars_beginning=$(((n_chars - length) / 2))
    local -r n_chars_end=$((n_chars - n_chars_beginning - length))
  else
    local -r n_chars_beginning=1
    local -r n_chars_end=1
  fi

  local -r beginning=$(repeat_char "$char_repeat" $n_chars_beginning)
  local -r end=$(repeat_char "$char_repeat" $n_chars_end)
  echo "${beginning}${text}${end}"
}

count_lines() {
  # Count number of non-empty lines in string.
  #
  # Usage:
  #   count_lines <text>
  local -r text=$1
  echo -n "$text" | grep -v '^ *$' | grep -c '^'
}

remove_from_list() {
  # Remove lines that match a list of regex.
  #
  # Usage:
  #   remove_from_list <list> <list_regex>
  local -r list=$1
  local -r list_regex=$2
  if [[ -z "$list_regex" ]]; then
    echo -e "$list"
  else
    echo -e "$list" | grep -vf <(echo -e "$list_regex") || :
  fi
}

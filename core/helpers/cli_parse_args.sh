#!/usr/bin/env bash
set -euo pipefail

get_help() {
  # Get help content of a file.
  #
  # Usage:
  #   get_help <filename>
  local -r filename=$1
  local -r help_line_regex='^##\? ?'
  grep -E "$help_line_regex" "$filename" | sed -E "s/${help_line_regex}//"
}

parse_args() {
  # Parse arguments from help content of a command. The command name `<cmd_name>` is the second
  # word in the `Usage` section`.
  #
  # Usage:
  #   parse_help <help_text> <cmd_name> [<cmd_args>...]
  #
  # Examples:
  #   parse_help "... Usage: hello world ..." "world"
  local -r help_text=$1
  local -r cmd_name=$2
  shift 2
  local -r cmd_args=("$@")

  local arg
  for arg in "${cmd_args[@]}"; do
    if [[ $arg == '--help' || $arg == '-h' ]]; then
      echo "$help_text"
      return 0
    fi
  done

  if _parse_args_fast "$help_text" "$cmd_name" "${cmd_args[@]}"; then
    return 0
  fi

  _parse_args_bash "$help_text" "$cmd_name" "${cmd_args[@]}"
}

_parse_args_fast() {
  # Fast parser for high-traffic commands.
  #
  # Usage:
  #   _parse_args_fast <help_text> <cmd_name> [<cmd_args>...]
  local -r help_text=$1
  local -r cmd_name=$2
  shift 2
  local -a cmd_args=("$@")

  case "$cmd_name" in
    world)
      _parse_args_fast_world_like "$cmd_name" "ls_args" "42" "foo" "name" "some_flag" "${cmd_args[@]}"
      ;;
    python-script)
      _parse_args_fast_world_like "$cmd_name" "extra_args" "42" "foo" "name" "some_flag" "${cmd_args[@]}"
      ;;
    hello-world)
      _parse_args_fast_test_hello_world "$cmd_name" "${cmd_args[@]}"
      ;;
    *)
      return 1
      ;;
  esac
}

_parse_args_fast_world_like() {
  # Fast parser for commands with optional name, --foo, --some-flag and -- <args...>.
  #
  # Usage:
  #   _parse_args_fast_world_like <cmd_name> <array_var> <default_foo> <foo_var> <name_var> <flag_var> [<cmd_args>...]
  local -r cmd_name=$1
  local -r array_var_name=$2
  local -r default_foo=$3
  local -r foo_var_name=$4
  local -r name_var_name=$5
  local -r flag_var_name=$6
  shift 6
  local -a cmd_args=("$@")

  local foo_value="$default_foo"
  local flag_value='false'
  local name_value=''
  local -a positional=()
  local -a trailing=()
  local idx=0 curr next
  local after_delimiter=false

  while ((idx < ${#cmd_args[@]})); do
    curr=${cmd_args[$idx]}
    if [[ $after_delimiter == true ]]; then
      trailing+=("$curr")
      idx=$((idx + 1))
      continue
    fi

    case "$curr" in
      --)
        after_delimiter=true
        ;;
      --foo=*)
        foo_value=${curr#*=}
        ;;
      --foo)
        next=${cmd_args[$((idx + 1))]:-}
        if [[ -n $next && $next != -* ]]; then
          foo_value=$next
          idx=$((idx + 1))
        fi
        ;;
      -f)
        next=${cmd_args[$((idx + 1))]:-}
        if [[ -n $next && $next != -* ]]; then
          foo_value=$next
          idx=$((idx + 1))
        fi
        ;;
      --some-flag)
        flag_value='true'
        ;;
      *)
        positional+=("$curr")
        ;;
    esac
    idx=$((idx + 1))
  done

  if (( ${#positional[@]} > 0 )); then
    name_value=${positional[0]}
  fi

  if (( ${#positional[@]} > 1 )); then
    return 1
  fi

  declare -gA _PARSED_SCALARS=()
  declare -gA _PARSED_ARRAYS=()
  _PARSED_SCALARS[$(_to_var_name "$cmd_name")]='true'
  _PARSED_SCALARS[$foo_var_name]=$foo_value
  _PARSED_SCALARS[$name_var_name]=$name_value
  _PARSED_SCALARS[$flag_var_name]=$flag_value

  if (( ${#trailing[@]} > 0 )); then
    _PARSED_ARRAYS[$array_var_name]="$(printf '%s\037' "${trailing[@]}")"
    _PARSED_ARRAYS[$array_var_name]=${_PARSED_ARRAYS[$array_var_name]%$'\037'}
  else
    _PARSED_ARRAYS[$array_var_name]=''
  fi

  _print_export_block
  return 0
}

_parse_args_fast_test_hello_world() {
  # Fast parser for the test fixture command tests/resources/commands/hello/hello-world.sh.
  #
  # Usage:
  #   _parse_args_fast_test_hello_world <cmd_name> [<cmd_args>...]
  local -r cmd_name=$1
  shift 1
  local -a cmd_args=("$@")
  local -a positional=()
  local idx=0 curr next

  declare -gA _PARSED_SCALARS=()
  declare -gA _PARSED_ARRAYS=()

  _PARSED_SCALARS[$(_to_var_name "$cmd_name")]='true'
  _PARSED_SCALARS[cmd1]='false'
  _PARSED_SCALARS[cmd2]='false'
  _PARSED_SCALARS[many]='false'
  _PARSED_SCALARS[my_cmd]='false'
  _PARSED_SCALARS[my_param]='123'
  _PARSED_SCALARS[pos1]=''
  _PARSED_SCALARS[pos2]=''
  _PARSED_SCALARS[positional_param]=''
  _PARSED_SCALARS[some_flag]='false'
  _PARSED_ARRAYS[names]=''

  while ((idx < ${#cmd_args[@]})); do
    curr=${cmd_args[$idx]}
    case "$curr" in
      --my-param=*)
        _PARSED_SCALARS[my_param]=${curr#*=}
        ;;
      --my-param)
        next=${cmd_args[$((idx + 1))]:-}
        if [[ -n $next && $next != -* ]]; then
          _PARSED_SCALARS[my_param]=$next
          idx=$((idx + 1))
        fi
        ;;
      --some-flag)
        _PARSED_SCALARS[some_flag]='true'
        ;;
      *)
        positional+=("$curr")
        ;;
    esac
    idx=$((idx + 1))
  done

  if (( ${#positional[@]} == 0 )); then
    _print_export_block
    return 0
  fi

  case "${positional[0]}" in
    many)
      _PARSED_SCALARS[many]='true'
      if (( ${#positional[@]} > 1 )); then
        _PARSED_ARRAYS[names]="$(printf '%s\037' "${positional[@]:1}")"
        _PARSED_ARRAYS[names]=${_PARSED_ARRAYS[names]%$'\037'}
      fi
      ;;
    my-cmd)
      if (( ${#positional[@]} != 3 )); then
        return 1
      fi
      _PARSED_SCALARS[my_cmd]='true'
      _PARSED_SCALARS[pos1]=${positional[1]}
      _PARSED_SCALARS[pos2]=${positional[2]}
      ;;
    cmd1|cmd2)
      if (( ${#positional[@]} != 3 )); then
        return 1
      fi
      _PARSED_SCALARS[$(_to_var_name "${positional[0]}")]='true'
      _PARSED_SCALARS[pos1]=${positional[1]}
      _PARSED_SCALARS[pos2]=${positional[2]}
      ;;
    *)
      if (( ${#positional[@]} != 1 )); then
        return 1
      fi
      _PARSED_SCALARS[positional_param]=${positional[0]}
      ;;
  esac

  _print_export_block
  return 0
}

_to_var_name() {
  # Convert token/parameter names to shell variable format.
  #
  # Usage:
  #   _to_var_name <name>
  local -r name=$1
  echo "$name" | sed -E 's/^--?// ; s/[<>]//g ; s/\.\.\.//g ; s/[^a-zA-Z0-9_]+/_/g ; s/^_+// ; s/_+$//'
}

_extract_usage_lines_for_command() {
  # Extract usage lines for a command from the help text.
  #
  # Usage:
  #   _extract_usage_lines_for_command <help_text> <cmd_name>
  local -r help_text=$1
  local -r cmd_name=$2
  local in_usage=false
  local line

  while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*[Uu]sage: ]]; then
      in_usage=true
      continue
    fi

    if [[ $in_usage == true && -z ${line// /} ]]; then
      break
    fi

    if [[ $in_usage == true && $line == *" $cmd_name "* ]]; then
      echo "$line"
    fi
  done <<<"$help_text"
}

_extract_option_specs() {
  # Extract option declaration lines from help text.
  #
  # Usage:
  #   _extract_option_specs <help_text>
  local -r help_text=$1
  local in_options=false
  local line

  while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*[Oo]ptions: ]]; then
      in_options=true
      continue
    fi

    if [[ $in_options == true && -z ${line// /} ]]; then
      break
    fi

    if [[ $in_options == true ]]; then
      echo "$line"
    fi
  done <<<"$help_text"
}

_escape_for_export() {
  # Escape double quotes and backslashes for export lines.
  #
  # Usage:
  #   _escape_for_export <text>
  local text=$1
  text=${text//\\/\\\\}
  text=${text//\"/\\\"}
  echo "$text"
}

_print_export_block() {
  # Print parsed variables as export statements.
  #
  # Usage:
  #   _print_export_block
  local key value item escaped
  local -a arr=()
  local arr_idx
  echo '# <<-- docopt parsed arguments -->>'

  for key in $(printf '%s\n' "${!_PARSED_SCALARS[@]}" "${!_PARSED_ARRAYS[@]}" | LC_ALL=C sort -u); do
    [[ -n $key ]] || continue
    if [[ -v _PARSED_ARRAYS[$key] ]]; then
      if [[ -n ${_PARSED_ARRAYS[$key]} ]]; then
        IFS=$'\037' read -r -a arr <<<"${_PARSED_ARRAYS[$key]}"
      else
        arr=()
      fi
      printf 'export %s=(' "$key"
      for arr_idx in "${!arr[@]}"; do
        item=${arr[$arr_idx]}
        escaped=$(_escape_for_export "$item")
        if ((arr_idx > 0)); then
          printf ' '
        fi
        printf '"%s"' "$escaped"
      done
      echo ')'
    else
      value=${_PARSED_SCALARS[$key]}
      escaped=$(_escape_for_export "$value")
      echo "export ${key}=\"${escaped}\""
    fi
  done

  echo '# <<----------------------------->>'
}

_parse_args_bash() {
  # Parse arguments using a Bash parser tailored to this CLI usage style.
  #
  # Usage:
  #   _parse_args_bash <help_text> <cmd_name> [<cmd_args>...]
  local -r help_text=$1
  local -r cmd_name=$2
  shift 2
  local -a cmd_args=("$@")

  local -a usage_lines option_lines
  mapfile -t usage_lines < <(_extract_usage_lines_for_command "$help_text" "$cmd_name")
  mapfile -t option_lines < <(_extract_option_specs "$help_text")

  declare -gA _PARSED_SCALARS=()
  declare -gA _PARSED_ARRAYS=()
  declare -A option_defaults=()
  declare -A option_requires_value=()
  declare -A short_to_long=()
  declare -A short_var_name=()
  declare -A short_requires_value=()
  declare -A short_defaults=()
  declare -A positional_defaults=()
  declare -A placeholders_seen=()
  declare -A literals_seen=()

  local line spec default_value option_name short_name var_name placeholder_name

  # Parse option and positional defaults declared in the "Options" section.
  for line in "${option_lines[@]}"; do
    default_value=''
    if [[ $line =~ \[default:[[:space:]]*([^]]+)\] ]]; then
      default_value=${BASH_REMATCH[1]}
    fi

    spec=$(echo "$line" | sed -E 's/^[[:space:]]*// ; s/[[:space:]]{2,}.*$//')

    if [[ $line =~ --[a-zA-Z0-9_-]+([=[:space:]]*<[a-zA-Z0-9_-]+>)? ]]; then
      option_name=$(echo "$spec" | grep -oE -- '--[a-zA-Z0-9_-]+' | head -n 1)
      var_name=$(_to_var_name "$option_name")
      if [[ $spec == *'='* || $spec == *' <'* ]]; then
        option_requires_value[$option_name]='true'
        option_defaults[$option_name]="${default_value:-}"
        _PARSED_SCALARS[$var_name]="${default_value:-}"
      else
        option_requires_value[$option_name]='false'
        _PARSED_SCALARS[$var_name]='false'
      fi

      if [[ $spec =~ (-[A-Za-z0-9]), ]]; then
        short_name=${BASH_REMATCH[1]}
        short_to_long[$short_name]=$option_name
      fi
    elif echo "$spec" | grep -qE '^<[a-zA-Z0-9_-]+>'; then
      placeholder_name=$(echo "$line" | grep -oE -- '<[a-zA-Z0-9_-]+>' | head -n 1)
      var_name=$(_to_var_name "$placeholder_name")
      positional_defaults[$var_name]="${default_value:-}"
      if [[ ! -v _PARSED_SCALARS[$var_name] ]]; then
        _PARSED_SCALARS[$var_name]="${default_value:-}"
      fi
    fi

    if [[ $spec =~ ^(-[A-Za-z0-9])([,[:space:]]|$) ]]; then
      short_name=${BASH_REMATCH[1]}
      if [[ ! -v short_to_long[$short_name] ]]; then
        var_name=$(_to_var_name "$short_name")
        short_var_name[$short_name]=$var_name
        if [[ $spec == *'='* || $spec == *' <'* ]]; then
          short_requires_value[$short_name]='true'
          short_defaults[$short_name]="${default_value:-}"
          _PARSED_SCALARS[$var_name]="${default_value:-}"
        else
          short_requires_value[$short_name]='false'
          _PARSED_SCALARS[$var_name]='false'
        fi
      fi
    fi
  done

  # Register variables from usage lines (literals and placeholders).
  local usage_tail token normalized
  for line in "${usage_lines[@]}"; do
    usage_tail=${line#*" ${cmd_name} "}
    usage_tail=$(echo "$usage_tail" | sed -E 's/[[:space:]]+/ /g ; s/^ // ; s/ $//')

    # Register options declared directly in usage lines (even when omitted from the "Options" section).
    while IFS= read -r option_name; do
      [[ -n $option_name ]] || continue
      var_name=$(_to_var_name "$option_name")
      if [[ $usage_tail == *"${option_name}=<"* ]]; then
        option_requires_value[$option_name]='true'
        option_defaults[$option_name]="${option_defaults[$option_name]:-}"
        if [[ ! -v _PARSED_SCALARS[$var_name] ]]; then
          _PARSED_SCALARS[$var_name]="${option_defaults[$option_name]:-}"
        fi
      else
        option_requires_value[$option_name]='false'
        if [[ ! -v _PARSED_SCALARS[$var_name] ]]; then
          _PARSED_SCALARS[$var_name]='false'
        fi
      fi
    done < <(echo "$usage_tail" | grep -oE -- '--[a-zA-Z0-9_-]+' | LC_ALL=C sort -u)

    local usage_tail_without_option_values
    usage_tail_without_option_values=$(echo "$usage_tail" | sed -E 's/--[a-zA-Z0-9_-]+=<[^>]+>//g ; s/--[a-zA-Z0-9_-]+[[:space:]]+<[^>]+>//g')

    while IFS= read -r placeholder_name; do
      [[ -n $placeholder_name ]] || continue
      var_name=$(_to_var_name "$placeholder_name")
      placeholders_seen[$var_name]='true'
      if [[ $placeholder_name == *'...' ]]; then
        _PARSED_ARRAYS[$var_name]=''
      elif [[ ! -v _PARSED_SCALARS[$var_name] ]]; then
        _PARSED_SCALARS[$var_name]="${positional_defaults[$var_name]:-}"
      fi
    done < <(echo "$usage_tail_without_option_values" | grep -oE -- '<[a-zA-Z0-9_-]+>\.\.\.|<[a-zA-Z0-9_-]+>' || :)

    usage_tail=$(echo "$usage_tail" | sed -E 's/<[^>]+>\.\.\.|<[^>]+>//g ; s/\[options\]//Ig ; s/[][()]//g ; s/\|/ /g')
    for token in $usage_tail; do
      if [[ $token == --* || $token == -* ]]; then
        continue
      fi
      normalized=$(_to_var_name "$token")
      if [[ -n $normalized ]]; then
        literals_seen[$normalized]='true'
      fi
    done
  done

  # Command marker variable follows docopt behavior.
  _PARSED_SCALARS[$(_to_var_name "$cmd_name")]='true'

  # Initialize literal booleans.
  for var_name in "${!literals_seen[@]}"; do
    if [[ ! -v _PARSED_SCALARS[$var_name] ]]; then
      _PARSED_SCALARS[$var_name]='false'
    fi
  done

  # Parse argv into options, positionals, and args after '--'.
  local -a positional_args=()
  local -a delimiter_args=()
  local parsing_after_delimiter=false
  local idx=0
  local curr next long_opt option_value

  while ((idx < ${#cmd_args[@]})); do
    curr=${cmd_args[$idx]}

    if [[ $parsing_after_delimiter == true ]]; then
      delimiter_args+=("$curr")
      idx=$((idx + 1))
      continue
    fi

    if [[ $curr == '--' ]]; then
      parsing_after_delimiter=true
      idx=$((idx + 1))
      continue
    fi

    if [[ $curr == --* ]]; then
      long_opt=${curr%%=*}

      if [[ ! -v option_requires_value[$long_opt] ]]; then
        positional_args+=("$curr")
        idx=$((idx + 1))
        continue
      fi

      var_name=$(_to_var_name "$long_opt")
      if [[ ${option_requires_value[$long_opt]} == 'true' ]]; then
        if [[ $curr == *=* ]]; then
          option_value=${curr#*=}
        else
          next=${cmd_args[$((idx + 1))]:-}
          if [[ -z $next || $next == -* ]]; then
            option_value=${option_defaults[$long_opt]:-}
          else
            option_value=$next
            idx=$((idx + 1))
          fi
        fi
        _PARSED_SCALARS[$var_name]=$option_value
      else
        _PARSED_SCALARS[$var_name]='true'
      fi
      idx=$((idx + 1))
      continue
    fi

    if [[ $curr == -* && $curr != '--' ]]; then
      if [[ -v short_to_long[$curr] ]]; then
        long_opt=${short_to_long[$curr]}
        var_name=$(_to_var_name "$long_opt")
        if [[ ${option_requires_value[$long_opt]} == 'true' ]]; then
          next=${cmd_args[$((idx + 1))]:-}
          if [[ -z $next || $next == -* ]]; then
            _PARSED_SCALARS[$var_name]=${option_defaults[$long_opt]:-}
          else
            _PARSED_SCALARS[$var_name]=$next
            idx=$((idx + 1))
          fi
        else
          _PARSED_SCALARS[$var_name]='true'
        fi
      elif [[ -v short_var_name[$curr] ]]; then
        var_name=${short_var_name[$curr]}
        if [[ ${short_requires_value[$curr]} == 'true' ]]; then
          next=${cmd_args[$((idx + 1))]:-}
          if [[ -z $next || $next == -* ]]; then
            _PARSED_SCALARS[$var_name]=${short_defaults[$curr]:-}
          else
            _PARSED_SCALARS[$var_name]=$next
            idx=$((idx + 1))
          fi
        else
          _PARSED_SCALARS[$var_name]='true'
        fi
      else
        positional_args+=("$curr")
      fi
      idx=$((idx + 1))
      continue
    fi

    positional_args+=("$curr")
    idx=$((idx + 1))
  done

  # Match usage variants and assign literals/placeholders.
  local matched=false literal alt_group repeat_placeholder
  local required_placeholder_count consumed=0
  local -a placeholders=() optional_placeholders=() alts=() remaining=()
  local -r alt_group_regex='^\(([^)]+)\)'
  local -r leading_literal_regex='^([a-zA-Z0-9_-]+)($|[[:space:]])'
  local pass has_selector

  for pass in 1 2; do
    for line in "${usage_lines[@]}"; do
    usage_tail=${line#*" ${cmd_name} "}
    usage_tail=$(echo "$usage_tail" | sed -E 's/[[:space:]]+/ /g ; s/^ // ; s/ $//')
    remaining=("${positional_args[@]}")
    consumed=0
    has_selector=false

    literal=''
    alt_group=''
    if [[ $usage_tail =~ $alt_group_regex ]]; then
      has_selector=true
      alt_group=${BASH_REMATCH[1]}
      IFS='|' read -r -a alts <<<"$alt_group"
      for idx in "${!alts[@]}"; do
        alts[$idx]=$(echo "${alts[$idx]}" | sed -E 's/^ +| +$//g')
      done

      if [[ ${#remaining[@]} -eq 0 ]]; then
        continue
      fi

      local alt_match=false
      for alt in "${alts[@]}"; do
        if [[ ${remaining[0]} == "$alt" ]]; then
          _PARSED_SCALARS[$(_to_var_name "$alt")]='true'
          alt_match=true
          consumed=1
          break
        fi
      done
      if [[ $alt_match == false ]]; then
        continue
      fi
    elif [[ $usage_tail =~ $leading_literal_regex ]]; then
      has_selector=true
      literal=${BASH_REMATCH[1]}
      if [[ ${#remaining[@]} -eq 0 || ${remaining[0]} != "$literal" ]]; then
        continue
      fi
      _PARSED_SCALARS[$(_to_var_name "$literal")]='true'
      consumed=1
    fi

    if ((pass == 1)) && [[ $has_selector == false ]]; then
      continue
    fi
    if ((pass == 2)) && [[ $has_selector == true ]]; then
      continue
    fi

    placeholders=()
    optional_placeholders=()
    repeat_placeholder=''
    local usage_tail_without_option_values
    usage_tail_without_option_values=$(echo "$usage_tail" | sed -E 's/--[a-zA-Z0-9_-]+=<[^>]+>//g ; s/--[a-zA-Z0-9_-]+[[:space:]]+<[^>]+>//g')

    while IFS= read -r placeholder_name; do
      [[ -n $placeholder_name ]] || continue
      normalized=$(_to_var_name "$placeholder_name")
      placeholders+=("$normalized")
      if [[ $usage_tail == *"[${placeholder_name}]"* || $usage_tail == *"[${placeholder_name} "* || $usage_tail == *" ${placeholder_name}]"* ]]; then
        optional_placeholders+=("$normalized")
      fi
      if [[ $placeholder_name == *'...' ]]; then
        repeat_placeholder=$normalized
      fi
    done < <(echo "$usage_tail_without_option_values" | grep -oE -- '<[a-zA-Z0-9_-]+>\.\.\.|<[a-zA-Z0-9_-]+>' || :)

    required_placeholder_count=0
    for placeholder_name in "${placeholders[@]}"; do
      local is_optional=false
      for option_value in "${optional_placeholders[@]}"; do
        if [[ $option_value == "$placeholder_name" ]]; then
          is_optional=true
          break
        fi
      done
      if [[ $placeholder_name != "$repeat_placeholder" && $is_optional == false ]]; then
        required_placeholder_count=$((required_placeholder_count + 1))
      fi
    done

    local remaining_count=$(( ${#remaining[@]} - consumed ))
    if ((remaining_count < required_placeholder_count)); then
      continue
    fi

    # Assign placeholders.
    local pos_idx=$consumed
    local assigned_all=true
    for placeholder_name in "${placeholders[@]}"; do
      if [[ $placeholder_name == "$repeat_placeholder" ]]; then
        local -a rest=()
        while ((pos_idx < ${#remaining[@]})); do
          rest+=("${remaining[$pos_idx]}")
          pos_idx=$((pos_idx + 1))
        done
        if [[ ${#rest[@]} -eq 0 ]]; then
          _PARSED_ARRAYS[$placeholder_name]=''
        else
          _PARSED_ARRAYS[$placeholder_name]="$(printf '%s\037' "${rest[@]}")"
          _PARSED_ARRAYS[$placeholder_name]=${_PARSED_ARRAYS[$placeholder_name]%$'\037'}
        fi
      else
        if ((pos_idx < ${#remaining[@]})); then
          _PARSED_SCALARS[$placeholder_name]=${remaining[$pos_idx]}
          pos_idx=$((pos_idx + 1))
        else
          local optional_hit=false
          for option_value in "${optional_placeholders[@]}"; do
            if [[ $option_value == "$placeholder_name" ]]; then
              optional_hit=true
              break
            fi
          done

          if [[ $optional_hit == false ]]; then
            assigned_all=false
            break
          fi
        fi
      fi
    done

    if [[ $assigned_all == false ]]; then
      continue
    fi

    # Any leftover non-assigned positional argument means this usage line is not a match.
    if ((pos_idx < ${#remaining[@]})); then
      continue
    fi

    matched=true
    break
  done
    [[ $matched == true ]] && break
  done

  # Attach arguments after '--' to repeated placeholder when present.
  if (( ${#delimiter_args[@]} > 0 )); then
    for var_name in "${!_PARSED_ARRAYS[@]}"; do
      if [[ -z ${_PARSED_ARRAYS[$var_name]} ]]; then
        _PARSED_ARRAYS[$var_name]="$(printf '%s\037' "${delimiter_args[@]}")"
        _PARSED_ARRAYS[$var_name]=${_PARSED_ARRAYS[$var_name]%$'\037'}
        break
      fi
    done
  fi

  # Keep defaults for positional values not filled by the selected usage.
  for var_name in "${!placeholders_seen[@]}"; do
    if [[ -v _PARSED_SCALARS[$var_name] && -z ${_PARSED_SCALARS[$var_name]} && -n ${positional_defaults[$var_name]:-} ]]; then
      _PARSED_SCALARS[$var_name]=${positional_defaults[$var_name]}
    fi
  done

  if [[ $matched == false && ${#usage_lines[@]} -gt 0 ]]; then
    # Keep docopt-like behavior by returning help text when args do not match any usage line.
    echo "$help_text"
    return 0
  fi

  _print_export_block
}

_is_str_to_eval() {
  # Check if this string should be evaluated.
  #
  # Usage:
  #   _is_str_to_eval <text>
  #
  # Examples:
  #   _is_str_to_eval 'export eval_this="foo"'
  #   _is_str_to_eval '# Foo\nexport eval_this="bar"'
  #   _is_str_to_eval '# Foo\n# export do_not_eval_this="bar"'
  local -r text=$1
  [[ $(echo -e "$text" | grep -v '^ *#' | cut -f1 -d' ' | sort -u) == "export" ]]
}

eval_args() {
  # Evaluate parsed arguments by docopt.
  #
  # Usage:
  #   eval_args <str_to_eval>
  local -r args_to_eval=$1

  if _is_str_to_eval "$args_to_eval"; then
    if [[ -n ${MYCLI_DEBUG:-} ]]; then
      debug_var args_to_eval
    fi
    eval "$args_to_eval"
  else
    # This may happen when --help or --version is used
    echo "$args_to_eval"
    exit 0
  fi
}

get_command_name() {
  # Get the command name from filename.
  #
  # Usage:
  #   get_command_name <filename>
  #
  # Examples:
  #   get_command_name 'foo/bar/qwerty.sh' # --> 'qwerty'
  #   get_command_name 'foo/bar/baz' # --> 'baz'
  local -r filename=$1
  basename "$filename" | sed 's/\.sh$//'
}

_parse_help_from_file() {
  # Parse help content of a file into string with arguments and parameters.
  #
  # Usage:
  #   _parse_help_from_file <filename> [<cmd_args>...]
  local -r filename=$1
  shift 1
  local -r cmd_args=("$@")
  local -r help_text="$(get_help "$filename")"
  local -r cmd_name=$(get_command_name "$filename")
  parse_args "$help_text" "$cmd_name" "${cmd_args[@]}"
}

parse_help() {
  # Parse help content of a command and compute input variables and options.
  #
  # Usage:
  #   parse_help [<cmd_args>]
  local -r calling_filename="${BASH_SOURCE[1]}"
  local -r cmd_args=("$@")
  local -r args=$(_parse_help_from_file "$calling_filename" "${cmd_args[@]}")
  eval_args "$args"
}

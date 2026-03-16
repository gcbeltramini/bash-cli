#!/usr/bin/env bash
set -euo pipefail

source "${CLI_DIR}/core/helpers.sh"

##? Update Homebrew and conda packages.
##?
##? Usage:
##?   setup update [--brew --conda]
##?
##? Options:
##?   --brew   Update Homebrew packages
##?   --conda  Update conda packages
##?
##? Examples:
##?   setup update --brew
##?   setup update --conda
##?   setup update --brew --conda

parse_help "$@"
declare brew conda

color="blue"

if $brew; then
  new_section_with_color "$color" "Update Homebrew packages"
  brew update
  brew upgrade
  brew cleanup -s
  echo_color \
    "yellow" \
    "List of installed Homebrew casks and formulae that have an updated version available \
(update with 'brew upgrade --cask ...'):"
  brew outdated --cask --greedy
  echo_done
fi

if $conda; then
  new_section_with_color "$color" "Update conda packages"
  conda update -yn base conda
  conda update -yn base --all
  conda clean -y --all
  echo_done
fi

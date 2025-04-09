#!/usr/bin/env bash
set -euo pipefail

test_git_current_branch() {
  true
}

oneTimeSetUp() {
  . core/helpers/git.sh
}

. scripts/shunit2

#!/bin/bash

# Sourcing Guard
[[ -n "${__DEPEND_CHECK_SH__:-}" ]] && {
    return 0
}
readonly __DEPEND_CHECK_SH__=1

# ensure_commands_present [--caller NAME] command1 command2 ...
# Returns 0 when all commands are available, 123 when one or more are missing.
# If --caller is omitted, the caller name is inferred from the sourcing script.
ensure_commands_present() {
  local caller=""
  if [[ "$1" == "--caller" ]]; then
    caller="$2"
    shift 2
  fi

  if [[ -z "$caller" ]]; then
    caller="$(basename "${BASH_SOURCE[1]:-unknown}")"
  fi

  if [[ $# -eq 0 ]]; then
    return 0
  fi

  local missing=()
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    printf 'Error: %s requires the following commands: %s\n' \
      "$caller" "${missing[*]}" >&2
    return 123
  fi

  return 0
}

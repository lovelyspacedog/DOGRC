#!/bin/bash
# Sourcing Guard - check if available function already exists
if declare -f available >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# List all bash functions currently defined in this shell, assuming
# ~/.bashrc (and its sourced modules) have already run.
__available_determine_mode() {
  local warn_mode="$1"
  shift || true
  local mode="filtered"
  for arg in "$@"; do
    case "$arg" in
      --hold|-h|--all|-a)
        mode="hold"
        ;;
      *)
        if [[ "$warn_mode" == "warn" ]]; then
          printf 'available: ignoring unknown option: %s\n' "$arg" >&2
        fi
        ;;
    esac
  done
  printf '%s' "$mode"
}

__available_filter_function_list() {
  local -n _funcs=$1
  local mode=$2
  if [[ "$mode" == "hold" ]]; then
    return
  fi

  local filtered=()
  for name in "${_funcs[@]}"; do
    [[ "$name" == _* ]] && continue
    filtered+=("$name")
  done
  _funcs=("${filtered[@]}")
}

__available_render_function_table() {
  local -n _funcs=$1

  if [[ ${#_funcs[@]} -eq 0 ]]; then
    echo "  (none)"
    return
  fi

  local cols=3
  local width=30
  local total=${#_funcs[@]}
  local rows=$(( (total + cols - 1) / cols ))

  for ((r = 0; r < rows; ++r)); do
    local line=""
    for ((c = 0; c < cols; ++c)); do
      local idx=$(( r + c * rows ))
      if (( idx < total )); then
        local name="${_funcs[idx]}"
        if (( ${#name} > width - 3 )); then
          name="${name:0:width-3}..."
        fi
        line+=$(printf '  %-*s' "$width" "$name")
      else
        line+=$(printf '  %-*s' "$width" "")
      fi
    done
    printf '%s\n' "$line"
  done
}

__available_print_functions() {
  local mode
  mode=$(__available_determine_mode warn "$@")

  echo "Functions available after sourcing ~/.bashrc (including sourced files):"
  local funcs=()
  while read -r func; do
    [[ "$func" =~ ^[[:alnum:]_]+$ ]] || continue
    funcs+=("$func")
  done < <(compgen -A function | sort)

  __available_filter_function_list funcs "$mode"
  __available_render_function_table funcs
}

available() {
  __available_print_functions "$@"
}

# If run directly, source ~/.bashrc in an interactive subshell first so
# that all functions are loaded before listing them.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  mode=$(__available_determine_mode warn "$@")
  mapfile -t raw_funcs < <(bash --noprofile -ic 'compgen -A function | sort' 2>/dev/null)
  funcs=()
  for func in "${raw_funcs[@]}"; do
    [[ "$func" =~ ^[[:alnum:]_]+$ ]] || continue
    funcs+=("$func")
  done
  __available_filter_function_list funcs "$mode"
  echo "Functions available after sourcing ~/.bashrc (including sourced files):"
  __available_render_function_table funcs
fi


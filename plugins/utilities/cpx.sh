#!/bin/bash

# Sourcing Guard - check if cpx function already exists
if declare -f cpx >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

cpx() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp cpx
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "cpx" g++ || {
        return $?
    }

    local arg="$1"
    [[ -z "$1" ]] && arg="main.cpp"
    [[ -f "$arg" ]] || {
        echo "Error: File $arg does not exist" >&2
        return 1
    }

    g++ "$arg" || {
        echo "Error: Failed to compile $arg" >&2
        return 2
    }
    ./"a.out"
    local exit_code=$?
    printf "\nExit Code: %d\n" "$exit_code"
    rm -f "a.out" || {
        echo "Error: Failed to remove a.out" >&2
        return 3
    }
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cpx "$@"
    exit $?
fi
#!/bin/bash
# Sourcing Guard - check if calc function already exists
if declare -f calc >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

calc() {
    # Handle help flags (case-insensitive)
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp calc
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "calc" bc || {
        return $?
    }

    [[ -z "$1" ]] && {
        echo "Usage: calc <expression>" >&2
        echo "Example: calc '2 + 3.5 * 4'" >&2
        return 1
    }

    local result
    if result=$(echo "scale=10; $1" | bc 2>/dev/null); then
        # Remove trailing zeros and decimal point if not needed
        echo "$result" | sed -e 's/\.0*$//' -e 's/\.$//'
        return 0
    else
        echo "Error: Invalid expression: $1" >&2
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    calc "$@"
    exit $?
fi
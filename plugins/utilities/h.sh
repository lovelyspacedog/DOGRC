#!/bin/bash
# Sourcing Guard - check if h function already exists
if declare -f h >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

h() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp h
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "h" grep || {
        return $?
    }

    [[ -z "$1" ]] && {
        history
        return 0
    }

    [[ "${1^^}" == "--EDIT" || "${1^^}" == "-E" ]] && {
        ensure_commands_present --caller "h edit" nvim || {
            return $?
        }
        nvim ~/.bash_history
        return 0
    }

    history | grep -i "$1"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    h "$@"
    exit $?
fi
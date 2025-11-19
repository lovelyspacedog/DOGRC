#!/bin/bash
# Sourcing Guard - check if pwd function already exists
if declare -f pwd >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# Copy the current directory to the clipboard if the first argument is "c" or "C"
pwd() {
    # Handle drchelp flags (preserve builtin --help, case-insensitive)
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--drchelp" ]] || [[ "${1,,}" == "--drc" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp pwd
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    [[ -n "$1" && "${1:0:1}" =~ [Cc] ]] && {
        ensure_commands_present --caller "pwd clipboard" wl-copy || {
            return $?
        }
        wl-copy <<<"$(builtin pwd)"
        echo "Working directory copied to clipboard."
        return 0
    }
    builtin pwd "$@"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pwd "$@"
    exit $?
fi


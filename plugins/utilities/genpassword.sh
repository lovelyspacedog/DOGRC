#!/bin/bash
# Sourcing Guard - check if genpassword function already exists
if declare -f genpassword >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

genpassword() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp genpassword
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    if ! ensure_commands_present --caller "genpassword" tr head xargs; then
        return 123
    fi

    local length=16
    local special=false
    local charset="A-Za-z0-9_"

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --special|-s)
                special=true
                charset='A-Za-z0-9_!@#$%^&*()+=\-\[\]{}|;:,.<>?'
                ;;
            *)
                if [[ "$arg" =~ ^[0-9]+$ ]]; then
                    length="$arg"
                fi
                ;;
        esac
    done

    tr -dc "$charset" </dev/urandom | head -c ${length} | xargs
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    genpassword "$@"
    exit $?
fi
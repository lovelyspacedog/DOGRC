#!/bin/bash
# Sourcing Guard - check if bashrc function already exists
if declare -f bashrc >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

bashrc() {
    if ! ensure_commands_present --caller "bashrc" nvim; then
        return 123
    fi

    local open_root=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --root|-r)
                open_root=true
                shift
                ;;
            --edit|-e)
                # Explicit flag for default behavior (opens ~/.bashrc)
                shift
                ;;
            *)
                echo "Error: Unknown option $1" >&2
                echo "Usage: bashrc [--root|-r|--edit|-e]" >&2
                return 1
                ;;
        esac
    done

    if [[ "$open_root" == true ]]; then
        nvim "${__DOGRC_DIR}"
    else
        nvim ~/.bashrc
    fi

    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bashrc "$@"
    exit $?
fi


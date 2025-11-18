#!/bin/bash
# Sourcing Guard - check if mkcd function already exists
if declare -f mkcd >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

mkcd() {
    mkdir -p "$1" || {
        printf "ERR: Failed to create directory '%s'\n" "$1"
        return 1
    }

    builtin cd "$1" || {
        printf "ERR: Failed to cd to '%s'\n" "$1"
        return 2
    }

    echo "📁 $(pwd)"

    command -v eza >/dev/null 2>&1 && {
        eza -lh --group-directories-first --icons=auto
        return 0
    }
    ls -Al --color=auto
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mkcd "$@"
    exit $?
fi
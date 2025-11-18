#!/bin/bash
# Sourcing Guard - check if swap function already exists
if declare -f swap >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# Swap two filenames safely
swap() {
    ensure_commands_present --caller "swap" mv || {
        return $?
    }

    [[ ! -f "$1" ]] && {
        echo "Error: '$1' does not exist"
        return 1
    }
    [[ ! -f "$2" ]] && {
        echo "Error: '$2' does not exist"
        return 1
    }

    # Check for different extensions and warn
    local ext1 ext2
    ext1="${1##*.}"
    ext2="${2##*.}"
    if [[ "$ext1" != "$ext2" ]] && [[ "$1" == *.* ]] && [[ "$2" == *.* ]]; then
        echo "Warning: Files have different extensions (.'$ext1' vs .'$ext2')"
    fi

    local TMPFILE=tmp.$$
    if mv "$1" "$TMPFILE" && mv "$2" "$1" && mv "$TMPFILE" "$2"; then
        echo "Successfully swapped '$1' and '$2'"
        return 0
    else
        echo "Error: Failed to swap '$1' and '$2'"
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    swap "$@"
    exit $?
fi


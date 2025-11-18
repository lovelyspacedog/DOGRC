#!/bin/bash
# Sourcing Guard - check if prepsh function already exists
if declare -f prepsh >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

prepsh() {
    local arg="$1"
    [[ -z "$1" ]] && arg="main.sh"

    [[ "$arg" != *.sh ]] && arg="$arg.sh"

    [[ -f "$arg" ]] && {
        printf "Can't create %s, file already exists\n" "$arg" >&2
        return 1
    }

    ensure_commands_present --caller "prepsh" chmod || {
        return $?
    }

    echo "#!/usr/bin/env bash" >"$arg"
    chmod +x "$arg"

    printf "Would you like to edit the file? (y/n): "
    read -n 1 -r ans
    echo

    if [[ $ans =~ ^[Yy]$ ]]; then
        local editor="${EDITOR:-nvim}"
        ensure_commands_present --caller "prepsh edit" "$editor" || {
            return $?
        }
        "$editor" "$arg"
        return 0
    fi

    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    prepsh "$@"
    exit $?
fi


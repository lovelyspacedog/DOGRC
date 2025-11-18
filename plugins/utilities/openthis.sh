#!/bin/bash
# Sourcing Guard - check if openthis function already exists
if declare -f openthis >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# xdg-open wrapper
openthis() {
    # If no arguments, just return
    [[ -z "$1" ]] && return 0

    # Check if the argument is a local file that exists
    if [[ -f "$1" ]]; then
        # Check if it's a script file first (open in neovim for editing)
        # This takes priority over executables - if it's both, we prefer editing
        if [[ "$1" =~ \.(sh|bash|zsh|fish|py|pl|rb|js|ts)$ ]]; then
            ensure_commands_present --caller "openthis" nvim kitty || {
                return $?
            }
            kitty --detach nvim "$@" >/dev/null 2>&1 & disown
            return 0
        fi
        
        # Check if it's an executable (run in new kitty window)
        if [[ -x "$1" ]]; then
            ensure_commands_present --caller "openthis" kitty || {
                return $?
            }
            kitty --detach "$@" >/dev/null 2>&1 & disown
            return 0
        fi
    fi

    # For everything else (URLs, non-executable files, etc.), use xdg-open
    ensure_commands_present --caller "openthis" xdg-open || {
        return $?
    }
    xdg-open "$@" >/dev/null 2>&1 & disown
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    openthis "$@"
    exit $?
fi


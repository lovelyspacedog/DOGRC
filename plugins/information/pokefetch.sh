#!/bin/bash
# Sourcing Guard - check if pokefetch function already exists
if declare -f pokefetch >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__INFORMATION_DIR:-}" ]] && readonly __INFORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__INFORMATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__INFORMATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__INFORMATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

pokefetch() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp pokefetch
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "pokefetch" pokemon-colorscripts fastfetch head sed mv || {
        return $?
    }

    pokemon-colorscripts -r 1-4 >/tmp/pokefetch.txt
    local pokemon_name
    pokemon_name="$(head -n 1 /tmp/pokefetch.txt)"
    sed '1d' /tmp/pokefetch.txt >/tmp/pokefetch.txt2
    mv /tmp/pokefetch.txt2 /tmp/pokefetch.txt
    fastfetch --logo-height 5 --logo /tmp/pokefetch.txt
    echo "[ ${pokemon_name^} ] Joins The Battle!"
    echo
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pokefetch "$@"
    exit $?
fi


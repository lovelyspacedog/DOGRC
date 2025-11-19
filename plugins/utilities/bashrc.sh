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
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp bashrc
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    if ! ensure_commands_present --caller "bashrc" nvim; then
        return 123
    fi

    local open_root=false
    local open_dogrc_bashrc=false
    local open_preamble=false
    local open_config=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --root|-r)
                open_root=true
                shift
                ;;
            --edit|-e)
                # Check if next argument is "dogrc", "preamble", or "config"
                if [[ -n "${2:-}" ]]; then
                    case "${2,,}" in
                        dogrc)
                            open_dogrc_bashrc=true
                            shift 2
                            ;;
                        preamble)
                            open_preamble=true
                            shift 2
                            ;;
                        config)
                            open_config=true
                            shift 2
                            ;;
                        *)
                            # Explicit flag for default behavior (opens ~/.bashrc)
                            shift
                            ;;
                    esac
                else
                    # Explicit flag for default behavior (opens ~/.bashrc)
                    shift
                fi
                ;;
            *)
                echo "Error: Unknown option $1" >&2
                echo "Usage: bashrc [--root|-r|--edit|-e [dogrc|preamble|config]]" >&2
                return 1
                ;;
        esac
    done

    if [[ "$open_root" == true ]]; then
        nvim "${__DOGRC_DIR}"
    elif [[ "$open_dogrc_bashrc" == true ]]; then
        nvim "${__DOGRC_DIR}/.bashrc"
    elif [[ "$open_preamble" == true ]]; then
        nvim "${__DOGRC_DIR}/config/preamble.sh"
    elif [[ "$open_config" == true ]]; then
        nvim "${__DOGRC_DIR}/config/DOGRC.json"
    else
        nvim ~/.bashrc
    fi

    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bashrc "$@"
    exit $?
fi


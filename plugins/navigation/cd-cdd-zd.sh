#!/bin/bash
# Sourcing Guard - check if cd or cdd or zd function already exists
if declare -f cd >/dev/null 2>&1 || declare -f cdd >/dev/null 2>&1 || declare -f zd >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__NAVIGATION_DIR:-}" ]] && readonly __NAVIGATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__NAVIGATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__NAVIGATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__NAVIGATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

cd() {
    # Handle drchelp flags (preserve builtin --help)
    [[ "$1" == "--drchelp" ]] || [[ "$1" == "--drc" ]] && {
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp cd
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    }
    
    if [[ -z "$1" ]]; then
        builtin cd "${HOME}"
    else
        builtin cd "$@"
    fi
    return 0
}

cdd() {
    # Handle help flags
    [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] && {
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp cdd
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    }
    
    [[ -d "$1" ]] && {
        builtin cd "$1" || {
            echo "Error: Failed to change to directory $1" >&2
            return 1
        }
        echo "📁 $(pwd)"
        command -v eza >/dev/null 2>&1 && {
            eza -lh --group-directories-first --icons=auto
            return 0
        }
        ls -Al --color=auto
        return 0
    }
    echo "Error: Directory $1 does not exist" >&2
    return 1
}

zd() {
    # Handle help flags
    [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] && {
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp zd
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    }
    
    # Try zoxide first if available
    if command -v z >/dev/null 2>&1; then
        if z "$@"; then
            echo "📁 $(pwd)"
            command -v eza >/dev/null 2>&1 && {
                eza -lh --group-directories-first --icons=auto
                return 0
            }
            ls -Al --color=auto
            return 0
        fi
    fi
    
    # Fallback to cd if zoxide fails or isn't available
    if [[ -z "$1" ]]; then
        builtin cd "${HOME}" || {
            echo "Error: Failed to change to directory ${HOME}" >&2
            return 1
        }
    else
        builtin cd "$@" || {
            echo "Error: Failed to change to directory $1" >&2
            return 1
        }
    fi
    
    echo "📁 $(pwd)"
    command -v eza >/dev/null 2>&1 && {
        eza -lh --group-directories-first --icons=auto
        return 0
    }
    ls -Al --color=auto
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 {cd|cdd|zd} [arguments...]" >&2
        exit 1
    fi
    
    func_name="$1"
    shift
    
    case "$func_name" in
        cd)
            cd "$@"
            exit $?
            ;;
        cdd)
            cdd "$@"
            exit $?
            ;;
        zd)
            zd "$@"
            exit $?
            ;;
        *)
            echo "Error: Unknown function '$func_name'. Use 'cd', 'cdd', or 'zd'." >&2
            exit 1
            ;;
    esac
fi
#!/bin/bash
# Sourcing Guard - check if slashback functions already exist
if declare -f / >/dev/null 2>&1 || declare -f // >/dev/null 2>&1 || declare -f /// >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__NAVIGATION_DIR:-}" ]] && readonly __NAVIGATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__NAVIGATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__NAVIGATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__NAVIGATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

__slashback() {
    local depth=${#FUNCNAME[1]}    # caller's name: '/', '//', etc.
    local target="."
    
    for ((i = 0; i < depth; i++)); do
        target+="/.."
    done
    
    cd "$target"
}

function /()    { __slashback; }
function //()   { __slashback; }
function ///()  { __slashback; }
function ////() { __slashback; }
function /////(){ __slashback; }
function //////(){ __slashback; }

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 {/|//|///|////|/////|//////}" >&2
        exit 1
    fi
    
    func_name="$1"
    shift
    
    case "$func_name" in
        /|//|///|////|/////|//////)
            "$func_name" "$@"
            exit $?
            ;;
        *)
            echo "Error: Unknown function '$func_name'. Use '/', '//', '///', etc." >&2
            exit 1
            ;;
    esac
fi


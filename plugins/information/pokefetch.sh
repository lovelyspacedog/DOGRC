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

    # Default file location
    local output_file="/tmp/pokefetch.txt"
    
    # Parse --relocate, --RELOCATE, -l, -L flags
    local args=()
    local i=0
    while [[ $i -lt $# ]]; do
        ((i++))
        local arg="${!i}"
        
        # Check for relocate flag (case-insensitive for long form, case-sensitive for short)
        if [[ "${arg}" == "--relocate" ]] || [[ "${arg}" == "--RELOCATE" ]] || \
           [[ "${arg}" == "-l" ]] || [[ "${arg}" == "-L" ]]; then
            # Get the next argument as the file path
            ((i++))
            if [[ $i -le $# ]]; then
                output_file="${!i}"
                # Validate that it's not another flag
                if [[ "$output_file" == --* ]] || [[ "$output_file" == -* ]]; then
                    echo "Error: --relocate requires a file path argument" >&2
                    return 1
                fi
            else
                echo "Error: --relocate requires a file path argument" >&2
                return 1
            fi
        else
            # Not a relocate flag, keep it in args (for future use)
            args+=("$arg")
        fi
    done
    
    # Derive the second file name from the output file
    # If output_file ends with .dat, use .dat2, otherwise use output_file2
    local output_file2
    if [[ "$output_file" == *.dat ]]; then
        output_file2="${output_file}2"
    else
        # For .txt or other extensions, add 2 before the extension
        local base="${output_file%.*}"
        local ext="${output_file##*.}"
        if [[ -n "$ext" ]] && [[ "$base" != "$output_file" ]]; then
            output_file2="${base}2.${ext}"
        else
            output_file2="${output_file}2"
        fi
    fi

    pokemon-colorscripts -r 1-4 >"$output_file"
    local pokemon_name
    pokemon_name="$(head -n 1 "$output_file")"
    sed '1d' "$output_file" >"$output_file2"
    mv "$output_file2" "$output_file"
    fastfetch --logo-height 5 --logo "$output_file"
    echo "[ ${pokemon_name^} ] Joins The Battle!"
    echo
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pokefetch "$@"
    exit $?
fi


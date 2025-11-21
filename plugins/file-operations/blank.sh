#!/bin/bash
# Sourcing Guard - check if blank function already exists
if declare -f blank >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

blank() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    # Check all arguments for help flags (needed for alias compatibility)
    local arg
    for arg in "$@"; do
        if [[ "${arg,,}" == "--help" ]] || [[ "${arg,,}" == "-h" ]]; then
            if declare -f drchelp >/dev/null 2>&1; then
                drchelp blank
                return 0
            else
                echo "Error: drchelp not available" >&2
                return 1
            fi
        fi
    done
    
    local touch_flag=false
    local skip_countdown=false
    local filename=""
    
    # Parse arguments
    local i=1
    while [[ $i -le $# ]]; do
        local arg="${!i}"
        case "${arg,,}" in
            --touch|-t)
                touch_flag=true
                ;;
            -x|--no-countdown|--skip-countdown)
                skip_countdown=true
                ;;
            *)
                # Not a flag, treat as filename (first non-flag argument)
                if [[ -z "$filename" ]] && [[ "$arg" != -* ]]; then
                    filename="$arg"
                fi
                ;;
        esac
        ((i++))
    done
    
    # Check if filename is provided
    if [[ -z "$filename" ]]; then
        echo "Error: blank requires a filename" >&2
        return 1
    fi
    
    # Check if file exists
    local file_exists=false
    if [[ -f "$filename" ]]; then
        file_exists=true
    fi
    
    # Handle file creation if touch flag is set
    if [[ "$touch_flag" == true ]] && [[ "$file_exists" == false ]]; then
        printf "Warning: $filename doesn't exist, creating new file: %s\n" "$filename" >&2
        touch "$filename" || {
            echo "Error: Failed to create $filename" >&2
            return 1
        }
    elif [[ "$file_exists" == false ]]; then
        echo "Error: $filename does not exist" >&2
        echo "Use --touch to create the file if it doesn't exist" >&2
        return 1
    fi
    
    # Countdown before clearing (only in interactive shells with stdin available, and if not skipped)
    if [[ "$skip_countdown" == false ]] && [[ -t 0 ]] && [[ "${-}" == *i* ]]; then
        printf "Emptying %s in 3 seconds... (press any key to cancel)\n" "$filename" >&2
        
        # Set terminal to raw mode for non-blocking key reading
        local saved_stty=""
        if command -v stty >/dev/null 2>&1; then
            saved_stty=$(stty -g 2>/dev/null) || saved_stty=""
            if [[ -n "$saved_stty" ]]; then
                stty raw -echo min 0 time 0 2>/dev/null || {
                    # Fallback to simpler settings if raw mode fails
                    stty -icanon -echo min 0 time 0 2>/dev/null || saved_stty=""
                }
            fi
        fi
        
        local countdown=3
        local cancelled=false
        
        # Countdown loop
        while [[ $countdown -gt 0 ]]; do
            printf "\r\033[KEmptying %s in %d... (press any key to cancel) " "$filename" "$countdown" >&2
            
            # Try to read a key (non-blocking, 1 second timeout)
            local key
            if read -t 1 -n 1 key 2>/dev/null; then
                cancelled=true
                break
            fi
            
            ((countdown--))
        done
        
        # Restore terminal settings
        if [[ -n "$saved_stty" ]] && command -v stty >/dev/null 2>&1; then
            stty "$saved_stty" 2>/dev/null || true
        fi
        
        echo >&2
        
        if [[ "$cancelled" == true ]]; then
            echo "Cancelled. File not modified." >&2
            return 0
        fi
    fi
    
    # Empty the file by redirecting nothing to it
    > "$filename"
    
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    blank "$@"
    exit $?
fi

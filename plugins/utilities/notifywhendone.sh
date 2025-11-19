#!/bin/bash
# Sourcing Guard - check if notifywhendone function already exists
if declare -f notifywhendone >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# Run a command and notify when it completes (success or error)
notifywhendone() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp notifywhendone
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "notifywhendone" notify-send || {
        return $?
    }

    # Build readable command string for display
    local cmd_str=""
    local arg
    for arg in "$@"; do
        # Quote argument if it contains spaces or special characters
        if [[ "$arg" =~ [[:space:]\"\'\\\$\`\|\;\&\<\>\(\)] ]]; then
            # Use single quotes if no single quotes in the argument (simpler)
            if [[ "$arg" != *"'"* ]]; then
                cmd_str+=" '$arg'"
            else
                # Use double quotes and escape internal quotes
                arg="${arg//\\/\\\\}"  # Escape backslashes
                arg="${arg//\"/\\\"}"  # Escape double quotes
                cmd_str+=" \"$arg\""
            fi
        else
            cmd_str+=" $arg"
        fi
    done
    cmd_str="${cmd_str# }"  # Remove leading space

    # Record start time
    local start_time
    start_time=$(date +%s)

    local ret_code=0
    if "$@"; then
        ret_code=0
    else
        ret_code=$?
    fi

    # Calculate elapsed time
    local end_time elapsed
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    
    # Format elapsed time
    local time_str
    if [[ $elapsed -lt 60 ]]; then
        time_str="${elapsed}s"
    elif [[ $elapsed -lt 3600 ]]; then
        local mins=$((elapsed / 60))
        local secs=$((elapsed % 60))
        time_str="${mins}m ${secs}s"
    else
        local hours=$((elapsed / 3600))
        local mins=$(((elapsed % 3600) / 60))
        local secs=$((elapsed % 60))
        time_str="${hours}h ${mins}m ${secs}s"
    fi

    # Build and send notification
    local msg
    if [[ $ret_code -eq 0 ]]; then
        msg="\"$cmd_str\" completed successfully in ${time_str}"
        notify-send -i "utilities-terminal" "Done" "$msg"
    else
        msg="\"$cmd_str\" completed with error code $ret_code in ${time_str}"
        notify-send -i "utilities-terminal" "Error" "$msg"
    fi
    echo "$msg" >&2
    return $ret_code
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    notifywhendone "$@"
    exit $?
fi


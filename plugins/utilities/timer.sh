#!/bin/bash
# Sourcing Guard - check if timer function already exists
if declare -f timer >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

timer() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp timer
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "timer" date read rm printf shopt || {
        return $?
    }

    local safe_name="${1:-Timer}"

    local -r -i MINUTES_IN_SEC=60
    local -r -i HOURS_IN_SEC=$((60*60))

    # Convert spaces to underscores first, then allow dots, underscores, and hyphens
    safe_name="${safe_name// /_}"
    safe_name="${safe_name//[^[:alnum:]._-]/}"
    safe_name="${safe_name:-Timer}"
    # Default to 'Timer' if no name provided

    if [[ "${1^^}" == "CLEAR" ]]; then
        # Check if stdin is a terminal for interactive prompt
        if [[ -t 0 ]]; then
            read -t 10 -n 1 -r -p "Are you sure you want to clear all timers? (y/N): " clear ||
                clear="N"
            printf "\n"
        else
            # Non-interactive: read from stdin directly
            read -t 10 -n 1 -r clear < /dev/stdin 2>/dev/null || clear="N"
        fi
        [[ "${clear^^}" == "Y" ]] && {
            if rm -f /tmp/timer-*.txt; then
                printf "All timers cleared!\n"
                return 0
            else
                printf "Error: Could not clear timers.\n" >&2
                return 4
            fi
        }
        printf "Timers not cleared.\n"
        return 0
    fi

    if [[ "${1^^}" == "LIST" ]]; then
        printf "Listing all timers:\n"

        shopt -s nullglob
        local timer_files=()
        local file
        for file in /tmp/timer-*.txt; do
            [[ -f "$file" ]] || continue
            timer_files+=("$file")
        done
        shopt -u nullglob

        if ((${#timer_files[@]} == 0)); then
            printf "  (no timers found)\n"
            return 0
        fi

        local now starttime elapsed hours minutes seconds name
        now="$(date +%s)"

        for file in "${timer_files[@]}"; do
            name="${file#/tmp/timer-}"
            name="${name%.txt}"

            if ! starttime="$(<"$file")"; then
                printf "  %s: error reading timer file\n" "$name" >&2
                continue
            fi

            elapsed=$(( now - starttime ))
            (( elapsed < 0 )) && elapsed=0
            hours=$(( elapsed / HOURS_IN_SEC ))
            minutes=$(( (elapsed % HOURS_IN_SEC) / MINUTES_IN_SEC ))
            seconds=$(( elapsed % MINUTES_IN_SEC ))
            printf "  %s: %03d:%02d:%02d\n" "$name" "$hours" "$minutes" "$seconds"
        done
        return 0
    fi

    local flagfile="/tmp/timer-$safe_name.txt"

    local -i starttime=0
    local -i endtime=0
    local -i elapsedtime=0

    local -i totalHours=0
    local -i totalMinutes=0
    local -i totalSeconds=0

    if ! [[ -f "$flagfile" ]]; then
        if ! printf "%s" "$(date +%s)" >"$flagfile"; then
            printf "Error: Could not create %s. No timer set.\n" "$flagfile" >&2
            return 1
        else
            printf "Timer set for %s!\n" "$safe_name"
            return 0
        fi
    else
        if ! starttime="$(cat "$flagfile")"; then
            printf "Error: Could not access %s.\n" "$flagfile" >&2
            return 2
        fi
        endtime="$(date +%s)"
        elapsedtime=$(( endtime - starttime ))
        while [[ $elapsedtime -ge $HOURS_IN_SEC ]]; do
            elapsedtime=$((elapsedtime - HOURS_IN_SEC))
            ((totalHours++))
        done
        while [[ $elapsedtime -ge $MINUTES_IN_SEC ]]; do
            elapsedtime=$((elapsedtime - MINUTES_IN_SEC))
            ((totalMinutes++))
        done
        totalSeconds="$elapsedtime"

        printf "Elapsed Time for %s: %03d:%02d:%02d\n" "$safe_name" "$totalHours" "$totalMinutes" "$totalSeconds"
        sleep 1
        # Check if stdin is a terminal for interactive prompt
        if [[ -t 0 ]]; then
            read -n 1 -p "Would you like to reset the timer? (y/N): " reset
            printf "\n"
        else
            # Non-interactive: read from stdin directly
            read -t 10 -n 1 -r reset < /dev/stdin 2>/dev/null || reset="N"
        fi
        [[ "${reset^^}" == "Y" ]] && {
            if ! rm -f "$flagfile"; then
                printf "Error: Could not delete %s. Timer for %s is still set.\n" "$flagfile" "$safe_name" >&2
                return 3
            fi
            printf "Timer for %s reset!\n" "$safe_name"
            return 0
        }
        printf "Timer for %s is still set.\nUse 'timer %s' to display the current time.\n" "$safe_name" "$safe_name"
        return 0
    fi
}

# Bash completion function for timer
_timer_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # If current word starts with a dash, complete with help flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
        return 0
    fi
    
    # Build list of completions: commands first, then timer names
    local command_completions=()
    local timer_completions=()
    
    # Add commands first (case-insensitive matching)
    local cur_upper="${cur^^}"
    if [[ -z "$cur" ]] || [[ "CLEAR" == "$cur_upper"* ]]; then
        command_completions+=("CLEAR")
    fi
    if [[ -z "$cur" ]] || [[ "LIST" == "$cur_upper"* ]]; then
        command_completions+=("LIST")
    fi
    
    # Extract timer names from /tmp/timer-*.txt files
    shopt -s nullglob
    local timer_files=()
    local file
    for file in /tmp/timer-*.txt; do
        [[ -f "$file" ]] || continue
        timer_files+=("$file")
    done
    shopt -u nullglob
    
    # Extract timer names from filenames
    local name
    for file in "${timer_files[@]}"; do
        name="${file#/tmp/timer-}"
        name="${name%.txt}"
        # Only add if it matches the current prefix (case-insensitive)
        if [[ -z "$cur" ]] || [[ "${name,,}" == "${cur,,}"* ]]; then
            timer_completions+=("$name")
        fi
    done
    
    # Combine: commands first, then timer names
    COMPREPLY=("${command_completions[@]}" "${timer_completions[@]}")
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _timer_completion timer 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    timer "$@"
    exit $?
fi


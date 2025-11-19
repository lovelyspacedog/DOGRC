#!/bin/bash
# Sourcing Guard - check if fastnote function already exists
if declare -f fastnote >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

is_pos_num() {
    [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -ge 0 ]]
    return $?
}

fastnote() {
    [[ ! -d "$HOME/.fastnotes" ]] && {
        ensure_commands_present --caller "fastnote (init)" mkdir || {
            return $?
        }
        if ! mkdir -p "$HOME/.fastnotes"; then
            echo "Error: Failed to create fastnotes directory." >&2
            return 1
        fi
    }

    local arg="${1:-0}"
    
    # Extract just the number if format is "number - preview" (from completion)
    if [[ "$arg" =~ ^([0-9]+)[[:space:]]*-[[:space:]]* ]]; then
        arg="${BASH_REMATCH[1]}"
    fi

    if [[ "${arg,,}" == "list" ]]; then
        ensure_commands_present --caller "fastnote list" basename sed head || {
            return $?
        }

        shopt -s nullglob
        local files=("$HOME"/.fastnotes/notes_*.txt)
        shopt -u nullglob

        if (( ${#files[@]} == 0 )); then
            echo "No notes found."
            return 0
        fi

        echo "Available notes:"
        local note_num preview first_line
        for file in "${files[@]}"; do
            # Extract note number from filename
            note_num="${file##*/notes_}"
            note_num="${note_num%.txt}"
            # Read first line for preview
            if [[ -f "$file" ]] && [[ -r "$file" ]]; then
                first_line=$(head -n 1 "$file" 2>/dev/null | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                # Truncate to 60 characters for display
                if [[ ${#first_line} -gt 60 ]]; then
                    preview="${first_line:0:57}..."
                else
                    preview="$first_line"
                fi
                # If preview is empty, use a placeholder
                [[ -z "$preview" ]] && preview="(empty note)"
                printf "  note %s - %s\n" "$note_num" "$preview"
            else
                printf "  note %s\n" "$note_num"
            fi
        done
        return 0
    fi

    if [[ "${arg,,}" == "clear" ]]; then
        ensure_commands_present --caller "fastnote clear" rm || {
            return $?
        }

        shopt -s nullglob
        local files=("$HOME"/.fastnotes/notes_*.txt)
        shopt -u nullglob

        if (( ${#files[@]} == 0 )); then
            echo "No notes found."
            return 0
        fi

        echo "This will delete all ${#files[@]} note(s)."
        echo -n "Are you sure? [y/N]: "
        read -r response

        if [[ ! "${response,,}" =~ ^y(es)?$ ]]; then
            echo "Cancelled."
            return 0
        fi

        local deleted=0
        for file in "${files[@]}"; do
            if rm -f "$file"; then
                ((deleted++))
            fi
        done

        if (( deleted == ${#files[@]} )); then
            echo "Deleted all ${deleted} note(s)."
            return 0
        else
            echo "Error: Failed to delete some notes. Deleted ${deleted} of ${#files[@]}." >&2
            return 1
        fi
    fi

    local digit action
    if ! is_pos_num "$arg"; then
        echo "Invalid argument." >&2
        echo "Note number must be a positive number or zero." >&2
        return 1
    fi

    digit="$arg"
    action="${2:-open}"

    local notes_file="$HOME/.fastnotes/notes_$digit.txt"

    if [[ "${action,,}" == d* ]]; then
        ensure_commands_present --caller "fastnote delete" rm || {
            return $?
        }

        if [[ -f "$notes_file" ]]; then
            rm -f "$notes_file" && {
                echo "Deleted note $digit."
                return 0
            }
            echo "Error: Failed to delete note $digit." >&2
            return 1
        else
            echo "Note $digit does not exist." >&2
            return 1
        fi
    fi

    if [[ "${action,,}" == c* ]] && [[ "${action,,}" != "clear" ]]; then
        ensure_commands_present --caller "fastnote cat" cat || {
            return $?
        }

        if [[ -f "$notes_file" ]]; then
            cat "$notes_file"
            return 0
        else
            echo "Note $digit does not exist." >&2
            return 1
        fi
    fi

    [[ ! -f "$notes_file" ]] && {
        echo "Note file does not exist."
        echo "Creating note file..."
        ensure_commands_present --caller "fastnote create" touch || {
            return $?
        }
        if ! touch "$notes_file"; then
            echo "Error: Failed to create note file." >&2
            return 1
        fi
    }

    local editor="${EDITOR:-nvim}"
    ensure_commands_present --caller "fastnote open" "$editor" || {
        return $?
    }

    if ! "$editor" "$notes_file"; then
        echo "Error: Failed to open note file." >&2
        return 1
    fi
}

# Bash completion function for fastnote
_fastnote_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # If we're on the second argument, check if first argument is a number (with or without preview)
    if [[ $cword -eq 2 ]]; then
        # Extract just the number - handle various formats:
        # - Plain number: "5"
        # - With preview: "5 - preview text"
        # - Quoted: "5 - preview text" or '5 - preview text'
        # - Escaped: 5\ -\ preview
        local prev_num="$prev"
        # Remove quotes if present
        prev_num="${prev_num#\"}"
        prev_num="${prev_num%\"}"
        prev_num="${prev_num#\'}"
        prev_num="${prev_num%\'}"
        # Extract number from start (handles escaped spaces and dashes)
        if [[ "$prev_num" =~ ^([0-9]+) ]]; then
            prev_num="${BASH_REMATCH[1]}"
        fi
        # Only complete actions if we extracted a valid number
        if [[ "$prev_num" =~ ^[0-9]+$ ]]; then
            local cur_lower="${cur,,}"
            local action_completions=()
            # Capitalize commands for visibility
            if [[ -z "$cur" ]] || [[ "open" == "$cur_lower"* ]]; then
                action_completions+=("OPEN")
            fi
            if [[ -z "$cur" ]] || [[ "delete" == "$cur_lower"* ]] || [[ "d" == "$cur_lower"* ]]; then
                action_completions+=("DELETE")
            fi
            if [[ -z "$cur" ]] || [[ "cat" == "$cur_lower"* ]] || [[ "c" == "$cur_lower"* ]]; then
                action_completions+=("CAT")
            fi
            COMPREPLY=("${action_completions[@]}")
            return 0
        fi
    fi

    # Build list of completions: commands first, then note numbers
    local command_completions=()
    local note_completions=()
    
    # Add commands (case-insensitive matching) - capitalize for visibility
    local cur_lower="${cur,,}"
    if [[ -z "$cur" ]] || [[ "list" == "$cur_lower"* ]]; then
        command_completions+=("LIST")
    fi
    if [[ -z "$cur" ]] || [[ "clear" == "$cur_lower"* ]]; then
        command_completions+=("CLEAR")
    fi
    
    # Extract note numbers from ~/.fastnotes/notes_*.txt files
    if [[ -d "$HOME/.fastnotes" ]]; then
        shopt -s nullglob
        local note_files=()
        local file
        for file in "$HOME"/.fastnotes/notes_*.txt; do
            [[ -f "$file" ]] || continue
            note_files+=("$file")
        done
        shopt -u nullglob
        
        # Extract note numbers from filenames and include note preview
        local note_num preview first_line
        for file in "${note_files[@]}"; do
            # Extract number from notes_*.txt filename
            note_num="${file##*/notes_}"
            note_num="${note_num%.txt}"
            # Only add if it's a valid number and matches the current prefix
            if [[ "$note_num" =~ ^[0-9]+$ ]]; then
                if [[ -z "$cur" ]] || [[ "$note_num" == "$cur"* ]]; then
                    # Read first line of note file for preview (limit to 50 chars)
                    if [[ -f "$file" ]] && [[ -r "$file" ]]; then
                        first_line=$(head -n 1 "$file" 2>/dev/null | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                        # Truncate to 50 characters and escape special chars
                        if [[ ${#first_line} -gt 50 ]]; then
                            preview="${first_line:0:47}..."
                        else
                            preview="$first_line"
                        fi
                        # If preview is empty, use a placeholder
                        [[ -z "$preview" ]] && preview="(empty note)"
                        # Format as "number - preview"
                        note_completions+=("$note_num - $preview")
                    else
                        # If we can't read the file, just show the number
                        note_completions+=("$note_num")
                    fi
                fi
            fi
        done
    fi
    
    # Combine: commands first, then note numbers
    COMPREPLY=("${command_completions[@]}" "${note_completions[@]}")
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _fastnote_completion fastnote 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    fastnote "$@"
    exit $?
fi


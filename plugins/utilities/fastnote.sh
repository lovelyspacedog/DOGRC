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

    if [[ "${arg,,}" == "list" ]]; then
        ensure_commands_present --caller "fastnote list" basename sed || {
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
        for file in "${files[@]}"; do
            basename "${file%.txt}" | sed 's/^notes_/  note /'
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    fastnote "$@"
    exit $?
fi


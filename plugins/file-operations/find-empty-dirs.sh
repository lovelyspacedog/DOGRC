#!/bin/bash
# Sourcing Guard - check if find-empty-dirs function already exists
if declare -f find-empty-dirs >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

find-empty-dirs() {
    # Handle help flags (case-insensitive)
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp find-empty-dirs
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "find-empty-dirs" find || {
        return $?
    }
    
    local delete_mode=false
    local search_dir="."
    local found_dirs=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --delete|-d)
                delete_mode=true
                shift
                ;;
            --)
                shift
                search_dir="$1"
                break
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                return 1
                ;;
            *)
                search_dir="$1"
                shift
                ;;
        esac
    done
    
    # Validate search directory
    if [[ ! -d "$search_dir" ]]; then
        echo "Error: $search_dir is not a directory or does not exist" >&2
        return 1
    fi
    
    # Resolve absolute path
    search_dir="$(cd "$search_dir" && pwd)" || {
        echo "Error: Failed to resolve path $search_dir" >&2
        return 1
    }
    
    # Find all empty directories
    # Using find with -type d -empty to find empty directories
    # -mindepth 1 to exclude the starting directory itself if it's empty
    while IFS= read -r -d '' dir; do
        found_dirs+=("$dir")
    done < <(find "$search_dir" -mindepth 1 -type d -empty -print0 2>/dev/null)
    
    # Check if any empty directories were found
    if [[ ${#found_dirs[@]} -eq 0 ]]; then
        echo "No empty directories found in $search_dir"
        return 0
    fi
    
    # Display found directories
    local dir_word="directories"
    [[ ${#found_dirs[@]} -eq 1 ]] && dir_word="directory"
    echo "Found ${#found_dirs[@]} empty $dir_word:"
    for dir in "${found_dirs[@]}"; do
        # Make path relative to search_dir for cleaner output
        local rel_path="${dir#$search_dir/}"
        [[ "$rel_path" == "$dir" ]] && rel_path="$(basename "$dir")"
        echo "  $rel_path"
    done
    
    # Handle delete mode
    if [[ "$delete_mode" == true ]]; then
        echo
        local dir_word="directories"
        [[ ${#found_dirs[@]} -eq 1 ]] && dir_word="directory"
        echo "Warning: You are about to delete ${#found_dirs[@]} empty $dir_word."
        
        # Interactive confirmation (only in interactive shells)
        if [[ -t 0 ]] && [[ "${-}" == *i* ]]; then
            read -p "Are you sure you want to continue? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Cancelled. No directories were deleted."
                return 0
            fi
        fi
        
        # Delete empty directories
        local deleted_count=0
        local failed_count=0
        
        for dir in "${found_dirs[@]}"; do
            if rmdir "$dir" 2>/dev/null; then
                ((deleted_count++))
            else
                echo "Warning: Failed to delete $dir" >&2
                ((failed_count++))
            fi
        done
        
        echo
        local dir_word="directories"
        [[ $deleted_count -eq 1 ]] && dir_word="directory"
        if [[ $failed_count -eq 0 ]]; then
            echo "Successfully deleted $deleted_count empty $dir_word."
        else
            echo "Deleted $deleted_count empty $dir_word, $failed_count failed."
            return 1
        fi
    fi
    
    return 0
}

# Tab completion function
_find_empty_dirs_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # If current word starts with dash, complete with flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--delete -d --help -h --" -- "$cur"))
        return 0
    fi
    
    # If previous word is --, complete with files/directories
    if [[ "$prev" == "--" ]]; then
        compopt -o default
        COMPREPLY=()
        return 0
    fi
    
    # Otherwise, complete with directories
    compopt -o default
    COMPREPLY=()
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _find_empty_dirs_completion find-empty-dirs 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    find-empty-dirs "$@"
    exit $?
fi


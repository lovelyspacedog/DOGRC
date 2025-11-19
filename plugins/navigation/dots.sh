#!/bin/bash
# Sourcing Guard - check if dots function already exists
if declare -f dots >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__NAVIGATION_DIR:-}" ]] && readonly __NAVIGATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__NAVIGATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__NAVIGATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__NAVIGATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# Dots (dots to list and cd to directories in .config)
dots() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp dots
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi

    # Show help if no argument provided
    if [[ -z "$1" ]]; then
        echo "Usage: dots <command> [directory]" >&2
        echo "" >&2
        echo "Manage and navigate .config directories" >&2
        echo "" >&2
        echo "Commands:" >&2
        echo "  ls [dir]  - List directories or contents" >&2
        echo "  <dir>     - Navigate to a .config directory" >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  dots ls           # List all .config directories" >&2
        echo "  dots ls hypr      # List contents of ~/.config/hypr" >&2
        echo "  dots hypr         # Navigate to ~/.config/hypr" >&2
        echo "  dots waybar       # Navigate to ~/.config/waybar" >&2
        echo "" >&2
        echo "Note: All operations work within ~/.config/" >&2
        return 1
    fi

    [[ "$1" == "ls" ]] && {
        if ! ensure_commands_present --caller "dots" find sort xargs ls; then
            return 123
        fi

        [[ -z "$2" ]] && {
            printf "Displaying .config: \n"
            local prev_letter=""
            local dir
            while IFS= read -r dir; do
                local first_letter="${dir:0:1}"
                first_letter="${first_letter^^}"  # Convert to uppercase for comparison
                if [[ "$first_letter" != "$prev_letter" ]]; then
                    printf "\e[1;34m%s\e[0m " "$dir"  # Blue color
                    prev_letter="$first_letter"
                else
                    printf "%s " "$dir"
                fi
            done < <(find "$HOME/.config" -maxdepth 1 -type d ! -name "." ! -name ".config" -exec basename {} \; | sort)
            printf "\n"
            return 0
        }
        
        # Handle .config as a special case to point to ~/.config itself
        local target_dir
        if [[ "$2" == ".config" ]]; then
            target_dir="$HOME/.config"
        else
            target_dir="$HOME/.config/$2"
        fi
        
        [[ -d "$target_dir" ]] || {
            printf "[%s] is not a valid directory.\n\n" "$target_dir" >&2
            return 2
        }
        echo "📁 Listing contents of $target_dir"
        if command -v eza >/dev/null 2>&1; then
            eza -Alh --group-directories-first --icons=auto "$target_dir"
        else
            ls -Al --color=auto "$target_dir"
        fi
        printf "\n"
        return 0
    }
    
    # Handle .config as a special case to point to ~/.config itself
    local target_dir
    if [[ "$1" == ".config" ]]; then
        target_dir="$HOME/.config"
    else
        target_dir="$HOME/.config/$1"
    fi
    
    [[ -d "$target_dir" ]] || {
        printf "[%s] is not a valid directory.\n\n" "$target_dir" >&2
        return 3
    }
    cd "$target_dir"
    echo "📁 $(pwd)"
    if command -v eza >/dev/null 2>&1; then
        eza -Alh --group-directories-first --icons=auto
    else
        ls -Al --color=auto
    fi
    printf "\n"
    return 0
}

# Bash completion function for dots
_dots_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    local config_dir="$HOME/.config"

    # If .config doesn't exist, no completion
    if [[ ! -d "$config_dir" ]]; then
        return 0
    fi

    # If previous word is "ls", complete with directory names (including .config)
    if [[ "$prev" == "ls" ]]; then
        local dirs
        mapfile -t dirs < <(find "$config_dir" -maxdepth 1 -type d ! -name "." -exec basename {} \; 2>/dev/null | sort)
        
        # Filter directories that match current prefix
        local completions=()
        # Add .config as a special option
        if [[ -z "$cur" || ".config" == "$cur"* ]]; then
            completions+=(".config")
        fi
        local dir
        for dir in "${dirs[@]}"; do
            if [[ -z "$cur" || "$dir" == "$cur"* ]]; then
                completions+=("$dir")
            fi
        done
        
        COMPREPLY=("${completions[@]}")
        return 0
    fi

    # If we're on the first argument (after "dots"), complete with commands and directories
    if [[ $cword -eq 1 ]]; then
        # Complete help flags if current word starts with dash
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
            return 0
        fi
        
        # Get directory names
        local dirs
        mapfile -t dirs < <(find "$config_dir" -maxdepth 1 -type d ! -name "." -exec basename {} \; 2>/dev/null | sort)
        
        # Build completions: commands first (if they match), then .config, then directories
        local completions=()
        if [[ -z "$cur" || "ls" == "$cur"* ]]; then
            completions+=("ls")
        fi
        # Add .config as a special option
        if [[ -z "$cur" || ".config" == "$cur"* ]]; then
            completions+=(".config")
        fi
        
        local dir
        for dir in "${dirs[@]}"; do
            if [[ -z "$cur" || "$dir" == "$cur"* ]]; then
                completions+=("$dir")
            fi
        done
        
        COMPREPLY=("${completions[@]}")
        return 0
    fi

    # For any other position, complete with directory names (including .config)
    local dirs
    mapfile -t dirs < <(find "$config_dir" -maxdepth 1 -type d ! -name "." -exec basename {} \; 2>/dev/null | sort)
    
    local completions=()
    # Add .config as a special option
    if [[ -z "$cur" || ".config" == "$cur"* ]]; then
        completions+=(".config")
    fi
    local dir
    for dir in "${dirs[@]}"; do
        if [[ -z "$cur" || "$dir" == "$cur"* ]]; then
            completions+=("$dir")
        fi
    done
    
    COMPREPLY=("${completions[@]}")
    return 0
}

# Register bash completion if available
if [[ -n "${BASH_VERSION:-}" ]] && command -v complete >/dev/null 2>&1; then
    complete -F _dots_completion dots
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    dots "$@"
    exit $?
fi


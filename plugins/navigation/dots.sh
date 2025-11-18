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
    # Show help if no argument provided or help is requested
    if [[ -z "$1" || "${1^^}" == "HELP" ]]; then
        echo "Usage: dots <command> [directory]"
        echo ""
        echo "Manage and navigate .config directories"
        echo ""
        echo "Commands:"
        echo "  ls [dir]  - List directories or contents"
        echo "  <dir>     - Navigate to a .config directory"
        echo "  help      - Show this help message"
        echo ""
        echo "Examples:"
        echo "  dots ls           # List all .config directories"
        echo "  dots ls hypr      # List contents of ~/.config/hypr"
        echo "  dots hypr         # Navigate to ~/.config/hypr"
        echo "  dots waybar       # Navigate to ~/.config/waybar"
        echo "  dots help         # Show this help"
        echo ""
        echo "Note: All operations work within ~/.config/"
        [[ -z "$1" ]] && return 1 || return 0
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
        # Get directory names
        local dirs
        mapfile -t dirs < <(find "$config_dir" -maxdepth 1 -type d ! -name "." -exec basename {} \; 2>/dev/null | sort)
        
        # Build completions: commands first (if they match), then .config, then directories
        local completions=()
        if [[ -z "$cur" || "ls" == "$cur"* ]]; then
            completions+=("ls")
        fi
        if [[ -z "$cur" || "help" == "$cur"* ]]; then
            completions+=("help")
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


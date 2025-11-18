#!/bin/bash

#    ____  ____  ______   ____  ______
#   / __ \/ __ \/ ____/  / __ \/ ____/
#  / / / / / / / / __   / /_/ / /     
# / /_/ / /_/ / /_/ /  / _, _/ /___   
#/_____/\____/\____/  /_/ |_|\____/   

# Add directory variables (must be defined first)
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__CONFIG_DIR:-}" ]] && readonly __CONFIG_DIR="$(cd "${__DOGRC_DIR}/config" && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__DOGRC_DIR}/core" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__DOGRC_DIR}/plugins" && pwd)"
[[ -z "${__USER_PLUGINS_DIR:-}" ]] && readonly __USER_PLUGINS_DIR="$(cd "${__DOGRC_DIR}/plugins/user-plugins" && pwd)"

# Set up preamble.sh for user-configurable content
# This .bashrc file will get overwritten by updates,
#   so we need to source the preamble.sh file.
if [[ $- != *i* ]]; then
    if [[ -f "${__CONFIG_DIR}/preamble.sh" ]]; then
        source "${__CONFIG_DIR}/preamble.sh" --non-interactive
    fi
    return 0
else
    if [[ -f "${__CONFIG_DIR}/preamble.sh" ]]; then
        source "${__CONFIG_DIR}/preamble.sh" --interactive
    fi
fi

# Import settings from DOGRC.json (excluding version)
if [[ -f "${__CONFIG_DIR}/DOGRC.json" ]]; then
    if command -v jq >/dev/null 2>&1; then
        # Use jq to extract all keys except version
        while IFS= read -r key; do
            [[ "$key" == "version" ]] && continue
            value=$(jq -r --arg k "$key" '.[$k] // true' "${__CONFIG_DIR}/DOGRC.json" 2>/dev/null)
            # Convert JSON boolean/null to bash boolean, default to true
            case "$value" in
                "true"|true) eval "${key}=true" ;;
                "false"|false) eval "${key}=false" ;;
                "null"|null|"") eval "${key}=true" ;;
                *) eval "${key}=true" ;;
            esac
        done < <(jq -r 'keys[]' "${__CONFIG_DIR}/DOGRC.json" 2>/dev/null)
    else
        # Fallback: simple grep-based parsing (less robust but works without jq)
        while IFS= read -r line; do
            # Extract key from "key": value pattern, skip version
            if [[ "$line" =~ \"([^\"]+)\"[[:space:]]*:[[:space:]]*(true|false) ]]; then
                key="${BASH_REMATCH[1]}"
                value="${BASH_REMATCH[2]}"
                [[ "$key" == "version" ]] && continue
                eval "${key}=${value}"
            fi
        done < <(grep -E '"[^"]+"[[:space:]]*:[[:space:]]*(true|false)' "${__CONFIG_DIR}/DOGRC.json" 2>/dev/null)
    fi
fi

# Source bash_completion if it exists
if [[ -f "/usr/share/bash-completion/bash_completion" ]]; then
    source "/usr/share/bash-completion/bash_completion"
fi

# Fix wl-copy for Hyprland if enabled
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    if [[ -n "${enable_hyprland_wlcopy:-true}" ]] && [[ "${enable_hyprland_wlcopy}" == true ]]; then
        if [[ -x "/usr/bin/wl-copy" ]]; then
            alias wl-copy="wl-copy -s Hyprland"
        fi
    fi
fi

# Source blesh if enabled
[[ "${enable_blesh:-true}" == true ]] && {
    [[ -f "$HOME/.local/share/blesh/ble.sh" ]] && {
        source "$HOME/.local/share/blesh/ble.sh" || {
            echo "Error: Failed to source ble.sh" >&2
            enable_blesh=false
        }
    }
}

# Source shell_mommy if enabled
[[ "${enable_shell_mommy:-true}" == true ]] && {
    [[ -f "$HOME/shell-mommy/shell-mommy.sh" ]] && {
        source "$HOME/shell-mommy/shell-mommy.sh" || {
            echo "Error: Failed to source shell-mommy.sh" >&2
            enable_shell_mommy=false
        }
        export PROMPT_COMMAND="mommy \\$\\(exit \$?\\); $PROMPT_COMMAND"
        export SHELL_MOMMYS_ONLY_NEGATIVE=true
    }
}

# Source starship if enabled
[[ "${enable_starship:-true}" == true ]] && {
    if command -v starship >/dev/null 2>&1; then
        eval "$(starship init bash)"
    else
        echo "Error: starship not found, disabling starship prompt" >&2
        enable_starship=false
    fi
}

# Disable drchelp if set to false
[[ "${enable_drchelp:-true}" == false ]] && {
    unset -f drchelp
}

# Enable zoxide if enabled
[[ "${enable_zoxide:-true}" == true ]] && {
    if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init bash)"
        alias cd="z"
        alias cdi="zi"
    else
        echo "Error: zoxide not found, disabling zoxide" >&2
        enable_zoxide=false
    fi
}

# Enable vimkeys if enabled
[[ "${enable_vimkeys:-true}" == true ]] && {
    set -o vi
}

# Project shell settings start here !!!
shopt -s histappend                             # Enable appending to the history file
export HISTSIZE=10000                           # Set the history size
export HISTFILESIZE=20000                       # Set the history file size
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "      # Set the history time format
export HISTCONTROL=erasedups                    # Set the history control
export HISTIGNORE="ls:ll:cd:pwd:clear:cls:exit" # Set the history ignore
shopt -s cmdhist                                # Enable history substitution
shopt -s lithist                                # Enable history expansion
shopt -s autocd                                 # Enable cd by typing directory name
shopt -s cdspell                                # Enable spell checking for cd
shopt -s cdable_vars                            # Enable cd to variable
shopt -s checkwinsize                           # Check window size changes
shopt -s dirspell                               # Enable spell checking for directory names
shopt -s globstar                               # Enable globstar
shopt -s direxpand                              # Enable directory expansion
shopt -s dirspell                               # Enable spell checking for directory names
shopt -s dotglob                                # Include dotfiles in globbing
shopt -s extglob                                # Extended globbing
shopt -s nocaseglob                             # Case-insensitive globbing

# Paths
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/bin"

# Enhanced Completion
bind 'set completion-ignore-case on'       # Ignore case in completion
bind 'set show-all-if-ambiguous on'        # Show all matches if ambiguous
bind 'set menu-complete-display-prefix on' # Show prefix in completion menu
bind 'TAB:menu-complete'                   # Tab to complete

# Better Key Bindings
bind '"\C-f":forward-word'       # Forward word (Ctrl + f)
bind '"\C-b":backward-word'      # Backward word (Ctrl + b)
bind '"\C-a":beginning-of-line'  # Beginning of line (Ctrl + a)
bind '"\C-e":end-of-line'        # End of line (Ctrl + e)
bind '"\C-u":kill-whole-line'    # Kill whole line (Ctrl + u)
bind '"\C-k":kill-line'          # Kill line (Ctrl + k)
bind '"\C-w":backward-kill-word' # Backward kill word (Ctrl + w)
bind '"\C-y":yank-last-arg'      # Yank last argument (Ctrl + y)

# Plugins and aliases (load last so they can use blesh, shell-mommy, starship, etc.)
# Source all .sh files in __PLUGINS_DIR and subdirectories except user plugins
while IFS= read -r -d '' plugin_file; do
    # Exclude files in user-plugins subdirectory
    [[ "$plugin_file" == "${__PLUGINS_DIR}/user-plugins/"* ]] && continue
    [[ -f "$plugin_file" ]] && source "$plugin_file"
done < <(find "${__PLUGINS_DIR}" -maxdepth 2 -name "*.sh" -type f -print0 2>/dev/null)

# Source user plugins if enabled
if [[ "${enable_user_plugins:-true}" == true ]]; then
    # Source all .sh files in user-plugins directory (but not subdirectories)
    while IFS= read -r -d '' user_plugin_file; do
        [[ -f "$user_plugin_file" ]] && source "$user_plugin_file"
    done < <(find "${__USER_PLUGINS_DIR}" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null)
fi

# Source aliases if enabled
if [[ "${enable_aliases:-true}" == true ]]; then
    # Only source aliases.sh if it exists in the core directory
    [[ -f "${__CORE_DIR}/aliases.sh" ]] && source "${__CORE_DIR}/aliases.sh"
fi
alias x="exit"

# Source preamble.sh after-loading
if [[ -f "${__CONFIG_DIR}/preamble.sh" ]]; then
    source "${__CONFIG_DIR}/preamble.sh" --after-loading
fi

# Auto-MOTD if enabled
[[ "${enable_automotd:-true}" == true ]] && {
    [[ -f "${__PLUGINS_DIR}/utilities/automotd.sh" ]] && {
        "${__PLUGINS_DIR}/utilities/automotd.sh"
    }
}

## STARTUP
type pokefetch >/dev/null 2>&1 && pokefetch
type motd >/dev/null 2>&1 && motd print
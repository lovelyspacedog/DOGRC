#!/bin/bash
# Sourcing Guard - check if navto function already exists
if declare -f navto >/dev/null 2>&1; then
    return 0
fi

# Use directory variables already set by .bashrc, or calculate from plugin location if not set
[[ -z "${__NAVIGATION_DIR:-}" ]] && readonly __NAVIGATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__NAVIGATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__NAVIGATION_DIR}/../../core" && pwd)"
# Only calculate __DOGRC_DIR if not already set (respects values from .bashrc in test environment)
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__NAVIGATION_DIR}/../.." && pwd)"
# Use __CONFIG_DIR from .bashrc if already set (respects test environment), otherwise calculate it
# IMPORTANT: Always use __CONFIG_DIR from .bashrc if it exists - never recalculate it!
# This ensures test environments use the correct config directory set by .bashrc
if [[ -z "${__CONFIG_DIR:-}" ]]; then
    # Only calculate if __DOGRC_DIR is set (either from .bashrc or calculated above)
    if [[ -n "${__DOGRC_DIR:-}" ]]; then
        readonly __CONFIG_DIR="${__DOGRC_DIR}/config"
    else
        # Fallback: calculate from navigation directory
        readonly __CONFIG_DIR="$(cd "${__NAVIGATION_DIR}/../../config" && pwd)"
    fi
else
    # __CONFIG_DIR is already set by .bashrc - don't touch it!
    # This is the expected case in all environments (installed, dev, test)
    :
fi

source "${__CORE_DIR}/dependency_check.sh"

__navto_remove_destination() {
    local del_key="$1"
    local mode="${2:-}"  # when set to --direct, remove without confirmation and adjust messages
    local json_file="${__CONFIG_DIR}/navto.json"

    ensure_commands_present --caller "navto remove" jq || {
        return $?
    }

    if [[ -z "$del_key" ]]; then
        printf "\e[1mUsage:\e[0m navto --remove <destination-key>\n"
        return 1
    fi

    if [[ ! -f "$json_file" ]]; then
        printf "\e[1;31mError:\e[0m No destinations file found: %s\n" "$json_file"
        return 1
    fi

    # Check existence
    if ! jq -e --arg k "${del_key^^}" 'has($k)' "$json_file" >/dev/null 2>&1; then
        printf "\e[1;31mError:\e[0m No destination found for key: \e[1;36m%s\e[0m\n" "${del_key^^}"
        return 1
    fi

    local name path
    name="$(jq -r --arg k "${del_key^^}" '.[ $k ].name // empty' "$json_file")"
    path="$(jq -r --arg k "${del_key^^}" '.[ $k ].path // empty' "$json_file")"

    if [[ "$mode" == "--direct" ]]; then
        printf "\e[1;35m🗑️  Removing stale destination (path missing):\e[0m\n"
        printf "  \e[1mKey :\e[0m \e[1;36m%s\e[0m\n" "${del_key^^}"
        printf "  \e[1mName:\e[0m %s\n" "$name"
        printf "  \e[1mPath:\e[0m %s\n" "$path"
    else
        printf "\e[1;35m🗑️  About to remove:\e[0m\n"
        printf "  \e[1mKey :\e[0m \e[1;36m%s\e[0m\n" "${del_key^^}"
        printf "  \e[1mName:\e[0m %s\n" "$name"
        printf "  \e[1mPath:\e[0m %s\n" "$path"
        local confirm
        # Check if stdin is a terminal for interactive prompt
        if [[ -t 0 ]]; then
            read -r -p $'\n\e[1mProceed with removal?\e[0m [y/N]: ' confirm
        else
            # Non-interactive: read from stdin directly (don't redirect, just read)
            read -t 10 -r confirm 2>/dev/null || confirm="N"
        fi
        case "${confirm:-N}" in
            [Yy]* ) ;;
            * ) printf "\e[2mCancelled.\e[0m\n"; return 1 ;;
        esac
    fi

    local tmpfile
    tmpfile="$(mktemp)" || return 1
    if ! jq --arg k "${del_key^^}" 'del(.[$k])' "$json_file" > "$tmpfile"; then
        printf "\e[1;31mError:\e[0m failed to update JSON.\n"
        rm -f "$tmpfile"
        return 1
    fi
    if ! mv "$tmpfile" "$json_file"; then
        printf "\e[1;31mError:\e[0m failed to write %s\n" "$json_file"
        rm -f "$tmpfile"
        return 1
    fi
    printf "\e[1;32m✅ Removed destination\e[0m \e[1;36m%s\e[0m.\n" "${del_key^^}"
    return 0
}

# These are the default destinations if no navto.json file exists
__navto_create_template() {
    local json_file="$1"
    if cat > "$json_file" <<'JSON_TMPL'
{
  "X": { "name": "Home",             "path": "$HOME" },
  "D": { "name": "Documents",        "path": "$HOME/Documents" },
  "P": { "name": "Pictures",         "path": "$HOME/Pictures" },
  "V": { "name": "Videos",           "path": "$HOME/Videos" },
  "M": { "name": "Music",            "path": "$HOME/Music" },
  "L": { "name": "Downloads",        "path": "$HOME/Downloads" },
  "C": { "name": "Code",             "path": "$HOME/Code" },
  ".": { "name": "Dotfiles",         "path": "$HOME/.config" },
  "T": { "name": "Temporary",        "path": "/tmp" }
}
JSON_TMPL
    then
        printf "\n\e[1;32m✅ Created template:\e[0m %s\n" "$json_file"
        printf "\e[2mTip:\e[0m run \e[1mnavto\e[0m to see available destinations.\n"
        return 0
    else
        printf "\e[1;31mError:\e[0m failed to write template to %s\n" "$json_file"
        return 1
    fi
}

__navto_add_destination() {
    local add_key="$1"
    local json_file="${__CONFIG_DIR}/navto.json"

    ensure_commands_present --caller "navto add" jq || {
        return $?
    }

    local name path confirm
    printf "\e[1mEnter display name for '\e[1;36m%s\e[0m\e[1m': \e[0m" "$add_key"
    while true; do
        # Check if stdin is a terminal for interactive prompt
        if [[ -t 0 ]]; then
            read -r name
        else
            # Non-interactive: read from stdin directly (don't redirect, just read)
            read -t 10 -r name 2>/dev/null || name=""
        fi
        if [[ -z "$name" ]]; then
            printf "\e[1;31mError:\e[0m Name cannot be empty. Please enter a valid name:\n"
            continue
        fi
        # Validate JSON safety by letting jq parse it as a string
        if jq -e -n --arg n "$name" '$n' >/dev/null 2>&1; then
            break
        else
            printf "\e[1;31mError:\e[0m Name contains invalid characters for JSON. Please try again:\n"
        fi
    done

    printf "\e[1mEnter path for '\e[1;36m%s\e[0m\e[1m' (you can use \$HOME): \e[0m" "$add_key"
    while true; do
        # Check if stdin is a terminal for interactive prompt
        if [[ -t 0 ]]; then
            read -r path
        else
            # Non-interactive: read from stdin directly (don't redirect, just read)
            read -t 10 -r path 2>/dev/null || path=""
        fi
        if [[ -z "$path" ]]; then
            printf "\e[1;31mError:\e[0m Path cannot be empty. Please enter a valid path:\n"
            continue
        fi
        # Normalize: convert leading ~ to literal $HOME for storage
        path="${path/#\~/\$HOME}"
        local __expanded
        __expanded="$(eval echo "$path")"
        if [[ -d "$__expanded" ]]; then
            break
        else
            printf "\e[1;31mError:\e[0m Path does not exist: %s\n" "$__expanded"
            printf "\e[1mEnter a valid existing path for '\e[1;36m%s\e[0m\e[1m': \e[0m" "$add_key"
        fi
    done

    printf "\e[1;35m➕ About to add:\e[0m\n"
    printf "  \e[1mKey :\e[0m \e[1;36m%s\e[0m\n" "$add_key"
    printf "  \e[1mName:\e[0m %s\n" "$name"
    printf "  \e[1mPath:\e[0m %s\n" "$path"
    # Check if stdin is a terminal for interactive prompt
    if [[ -t 0 ]]; then
        read -r -p $'\n\e[1mProceed?\e[0m [y/N]: ' confirm
    else
        # Non-interactive: read from stdin directly (don't redirect, just read)
        read -t 10 -r confirm 2>/dev/null || confirm="N"
    fi
    case "${confirm:-N}" in
        [Yy]* ) ;;
        * ) printf "\e[2mCancelled.\e[0m\n"; return 1 ;;
    esac

    # Ensure destinations file exists; initialize empty object if missing
    if [[ ! -f "$json_file" ]]; then
        echo "{}" > "$json_file" || { printf "\e[1;31mError:\e[0m cannot create %s\n" "$json_file"; return 1; }
    fi

    # Write updated JSON atomically
    local tmpfile
    tmpfile="$(mktemp)" || return 1
    if ! jq --arg k "$add_key" --arg n "$name" --arg p "$path" \
        '. + {($k): {name: $n, path: $p}}' \
        "$json_file" > "$tmpfile"; then
        printf "\e[1;31mError:\e[0m failed to update JSON.\n"
        rm -f "$tmpfile"
        return 1
    fi
    if ! mv "$tmpfile" "$json_file"; then
        printf "\e[1;31mError:\e[0m failed to write %s\n" "$json_file"
        rm -f "$tmpfile"
        return 1
    fi
    printf "\e[1;32m✅ Added destination\e[0m \e[1;36m%s\e[0m.\n" "$add_key"
    return 0
}

navto() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp navto
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    # Handle removal flag early
    if [[ "${1:-}" == "--remove" || "${1:-}" == "-r" || "${1:-}" == "--delete" || "${1:-}" == "-d" ]]; then
        shift
        local del_key="${1:-}"
        # Strip " - name" suffix if present (from tab completion showing "key - name")
        del_key="${del_key%% - *}"
        if [[ -z "$del_key" ]]; then
            echo "Usage: navto --remove|-r|--delete|-d <destination-key>"
            return 1
        fi
        __navto_remove_destination "$del_key"
        return $?
    fi

    local key="${1:-}"
    # Strip " - name" suffix if present (from tab completion showing "key - name")
    key="${key%% - *}"

    if [[ -z "$key" ]]; then
        printf "Usage: navto <destination-key>\n\n"
        printf "\e[1;35m🧭 Available destinations:\e[0m\n"
        if ensure_commands_present --caller "navto help" jq; then
            local json_file="${__CONFIG_DIR}/navto.json"
            if [[ -f "$json_file" ]]; then
                # Color legend: key (bold cyan), name (bold), arrow+path (faint)
                jq -r 'to_entries | sort_by(.key)[] | "\(.key)\t\(.value.name)\t\(.value.path)"' "$json_file" | \
                while IFS=$'\t' read -r __k __n __p; do
                    # Replace literal $HOME with ~ for readability (do not expand env yet)
                    __p="${__p//'$HOME'/~}"
                    printf "     \e[1;36m%-4s\e[0m - \e[1m%s\e[0m \e[2m-> %s\e[0m\n" "$__k" "$__n" "$__p"
                done
                #printf "\n"
            else
                printf "  \e[1;31m(destinations file not found: %s)\e[0m\n" "$json_file"
                # Check if stdin is a terminal for interactive prompt
                if [[ -t 0 ]]; then
                    read -r -p $'\n\e[1mCreate a starter template now?\e[0m [y/N]: ' __mk
                else
                    # Non-interactive: read from stdin directly (don't redirect, just read)
                    read -t 10 -r __mk 2>/dev/null || __mk="N"
                fi
                case "${__mk:-N}" in
                    [Yy]* )
                        if __navto_create_template "$json_file"; then
                            return 0
                        else
                            return 1
                        fi
                        ;;
                    * )
                        return 0
                        ;;
                esac
            fi
        else
            printf "  \e[2m(jq not available to display list)\e[0m\n"
        fi
        return 0
    fi

    ensure_commands_present --caller "navto" jq || {
        return $?
    }

    local json_file="${__CONFIG_DIR}/navto.json"
    if [[ ! -f "$json_file" ]]; then
        printf "\e[1;31mError:\e[0m destinations file not found: %s\n" "$json_file"
        # Check if stdin is a terminal for interactive prompt
        if [[ -t 0 ]]; then
            read -r -p $'\n\e[1mCreate a starter template now?\e[0m [y/N]: ' __mk
        else
            # Non-interactive: read from stdin directly (don't redirect, just read)
            read -t 10 -r __mk 2>/dev/null || __mk="N"
        fi
        case "${__mk:-N}" in
            [Yy]* )
                if __navto_create_template "$json_file"; then
                    return 0
                else
                    return 1
                fi
                ;;
            * )
                return 1
                ;;
        esac
    fi

    local ukey="${key^^}"

    local name path
    name="$(jq -r --arg k "$ukey" '.[ $k ].name // empty' "$json_file" 2>/dev/null)"
    path="$(jq -r --arg k "$ukey" '.[ $k ].path // empty' "$json_file" 2>/dev/null)"

    if [[ -z "$name" || -z "$path" ]]; then
        printf "\e[1;31mError:\e[0m destination not found for key: \e[1;36m%s\e[0m\n" "$key"
        # Check if stdin is a terminal for interactive prompt
        if [[ -t 0 ]]; then
            read -r -p "$(printf '\n\e[1mWould you like to add key \e[1;36m%s\e[0m?\e[0m [y/N]: ' "$ukey")" __ans
        else
            # Non-interactive: read from stdin directly (don't redirect, just read)
            read -t 10 -r __ans 2>/dev/null || __ans="N"
        fi
        case "${__ans:-N}" in
            [Yy]* )
                if __navto_add_destination "$ukey"; then
                    printf "\e[2mYou can now run:\e[0m navto \e[1;36m%s\e[0m\n" "$ukey"
                    return 0
                else
                    return 1
                fi
                ;;
            * )
                return 1
                ;;
        esac
    fi

    local expanded_path
    expanded_path="$(eval echo "$path")"

    # If destination directory no longer exists, confirm once here, then remove directly
    if [[ ! -d "$expanded_path" ]]; then
        printf "\e[1;31mError:\e[0m destination path no longer exists: %s\n" "$expanded_path"
        # Check if stdin is a terminal for interactive prompt
        if [[ -t 0 ]]; then
            read -r -p "$(printf '\n\e[1mWould you like to remove key \e[1;36m%s\e[0m from destinations? [y/N]: ' "$ukey")" __rm
        else
            # Non-interactive: read from stdin directly (don't redirect, just read)
            read -t 10 -r __rm 2>/dev/null || __rm="N"
        fi
        case "${__rm:-N}" in
            [Yy]* )
                __navto_remove_destination "$ukey" --direct
                return $?
                ;;
            * )
                return 1
                ;;
        esac
    fi

    if ! cd "$expanded_path" 2>/dev/null; then
        printf "\e[1;31mError:\e[0m failed to navigate to: %s\n" "$expanded_path"
        return 1
    fi

    printf "📁 \e[1;36m%s\e[0m   [\e[1m%s\e[0m]\n" "$(pwd)" "$name"
    if command -v eza >/dev/null 2>&1; then
        eza -lh --group-directories-first --icons=auto
    else
        ls -Al --color=auto
    fi
    return 0
}

# Bash completion function for navto
_navto_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    local json_file="${__CONFIG_DIR}/navto.json"

    # If jq is not available, no completion
    if ! command -v jq >/dev/null 2>&1; then
        return 0
    fi

    # If navto.json doesn't exist, no completion
    if [[ ! -f "$json_file" ]]; then
        return 0
    fi

    # If previous word is a removal flag, complete with destination keys (with names)
    if [[ "$prev" == "--remove" || "$prev" == "-r" || "$prev" == "--delete" || "$prev" == "-d" ]]; then
        # Get all keys and match manually (since we need to match on key but display "key - name")
        local keys
        mapfile -t keys < <(jq -r 'keys[]' "$json_file" 2>/dev/null | sort)
        
        # Build completions array with "key - name" format for display
        local completions=()
        local key name
        for key in "${keys[@]}"; do
            # Only include if key matches current prefix
            if [[ -z "$cur" || "$key" == "$cur"* ]]; then
                name="$(jq -r --arg k "$key" '.[$k].name' "$json_file" 2>/dev/null)"
                # Store as "key - name" but we'll need to extract key for matching
                completions+=("$key - $name")
            fi
        done
        
        # Use compopt to enable descriptions if available, otherwise just use the formatted strings
        compopt -o nosort 2>/dev/null || true
        COMPREPLY=("${completions[@]}")
        return 0
    fi

    # If current word starts with a dash, complete with flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--help -h --remove -r --delete -d" -- "$cur"))
        return 0
    fi

    # Otherwise, complete with destination keys (with names)
    # Get all keys and match manually (since we need to match on key but display "key - name")
    local keys
    mapfile -t keys < <(jq -r 'keys[]' "$json_file" 2>/dev/null | sort)
    
    # Build completions array with "key - name" format for display
    local completions=()
    local key name
    for key in "${keys[@]}"; do
        # Only include if key matches current prefix
        if [[ -z "$cur" || "$key" == "$cur"* ]]; then
            name="$(jq -r --arg k "$key" '.[$k].name' "$json_file" 2>/dev/null)"
            # Store as "key - name" for display
            completions+=("$key - $name")
        fi
    done
    
    # Use compopt to enable descriptions if available, otherwise just use the formatted strings
    compopt -o nosort 2>/dev/null || true
    COMPREPLY=("${completions[@]}")
    return 0
}

# Register the completion function
# Note: We show "key - name" in completions, and the navto function handles
# extracting just the key part if "key - name" format is passed
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _navto_completion navto 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    navto "$@"
    exit $?
fi


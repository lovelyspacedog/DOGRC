#!/bin/bash
# Sourcing Guard - check if drcupdate function already exists
if declare -f drcupdate >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# Semantic version comparison function (same as _UPDATE.sh)
# Returns: 0 if versions equal, 1 if v1 > v2, 2 if v1 < v2
# Supports versions with any number of parts (e.g., 0.1.5, 0.1.5.1, 0.1.5.9.2)
compare_versions() {
    local v1="$1"
    local v2="$2"
    
    # Remove 'v' prefix if present
    v1="${v1#v}"
    v2="${v2#v}"
    
    # Split version strings into arrays
    IFS='.' read -ra v1_parts <<< "$v1"
    IFS='.' read -ra v2_parts <<< "$v2"
    
    # Find the maximum number of parts
    local max_parts=${#v1_parts[@]}
    if [[ ${#v2_parts[@]} -gt $max_parts ]]; then
        max_parts=${#v2_parts[@]}
    fi
    
    # Ensure both arrays have at least 3 elements (pad with 0 if needed)
    while [[ ${#v1_parts[@]} -lt 3 ]]; do
        v1_parts+=("0")
    done
    while [[ ${#v2_parts[@]} -lt 3 ]]; do
        v2_parts+=("0")
    done
    
    # Compare all parts up to max_parts
    for ((i=0; i<max_parts; i++)); do
        local num1="${v1_parts[$i]//[!0-9]/0}"  # Remove non-numeric, default to 0
        local num2="${v2_parts[$i]//[!0-9]/0}"
        
        # If part doesn't exist, treat as 0
        num1=$((10#${num1:-0}))  # Force base-10 interpretation
        num2=$((10#${num2:-0}))
        
        if [[ $num1 -gt $num2 ]]; then
            return 1  # v1 > v2
        elif [[ $num1 -lt $num2 ]]; then
            return 2  # v1 < v2
        fi
    done
    
    return 0  # Versions equal
}

# Check if a DOGRC update is available
drcupdate() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp drcupdate
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    # Parse arguments first to check for --return-only
    local silent=false
    local ignore_this_version=false
    local return_only=false
    local yes_flag=false
    for arg in "$@"; do
        case "$arg" in
            --silent|-s)
                silent=true
                ;;
            --ignore-this-version|--ignore)
                ignore_this_version=true
                ;;
            --return-only)
                return_only=true
                ;;
            --yes|-y)
                yes_flag=true
                ;;
            *)
                # Ignore unknown arguments
                ;;
        esac
    done

    # Check dependencies (suppress output if --return-only)
    if [[ "$return_only" == "true" ]]; then
        ensure_commands_present --caller "drcupdate" curl jq >/dev/null 2>&1 || {
            return $?
        }
    else
        ensure_commands_present --caller "drcupdate" curl jq || {
            return $?
        }
    fi

    local installed_config="$HOME/DOGRC/config/DOGRC.json"
    local version_fake_file="$HOME/DOGRC/config/version.fake"
    local git_raw_base="https://raw.githubusercontent.com/lovelyspacedog/DOGRC"
    local branch="main"
    
    # Check if installed
    if [[ ! -f "$installed_config" ]]; then
        [[ "$return_only" != "true" ]] && echo "Error: DOGRC is not installed (DOGRC.json not found)" >&2
        return 1
    fi
    
    # Get installed version
    local installed_version
    installed_version=$(jq -r '.version // empty' "$installed_config" 2>/dev/null || echo "")
    # If a version.fake exists, use it instead of the installed version
    if [[ -f "$version_fake_file" ]]; then
        local fake_version
        fake_version="$(cat "$version_fake_file" 2>/dev/null | tr -d '[:space:]')"
        if [[ -n "$fake_version" ]]; then
            installed_version="$fake_version"
            [[ "$silent" != "true" ]] && [[ "$return_only" != "true" ]] && echo "Using fake version from $version_fake_file: $installed_version"
        fi
    fi
    if [[ -z "$installed_version" ]]; then
        [[ "$return_only" != "true" ]] && echo "Error: Could not read version from $installed_config" >&2
        return 1
    fi
    
    # Get remote version
    local remote_config_url="$git_raw_base/$branch/config/DOGRC.json"
    local temp_config
    temp_config=$(mktemp)
    
    if ! curl -sfL "$remote_config_url" -o "$temp_config" 2>/dev/null; then
        [[ "$return_only" != "true" ]] && echo "Error: Could not fetch remote version from repository" >&2
        rm -f "$temp_config"
        return 1
    fi
    
    local remote_version
    remote_version=$(jq -r '.version // empty' "$temp_config" 2>/dev/null || echo "")
    rm -f "$temp_config"
    
    if [[ -z "$remote_version" ]]; then
        [[ "$return_only" != "true" ]] && echo "Error: Could not read version from repository" >&2
        return 1
    fi

    # If --return-only is set, just compare and return exit code
    if [[ "$return_only" == "true" ]]; then
        compare_versions "$remote_version" "$installed_version"
        local cmp_result=$?
        case $cmp_result in
            0)
                # Versions equal - up-to-date
                return 0
                ;;
            1)
                # remote_version > installed_version - update available
                return 2
                ;;
            2)
                # remote_version < installed_version - downgrade possible
                return 3
                ;;
            *)
                # Invalid version format - error
                return 1
                ;;
        esac
    fi

    # If the user passed --ignore-this-version, offer to store the current remote version in version.fake
    if [[ "$ignore_this_version" == "true" ]]; then
        if [[ "$silent" == "true" ]]; then
            echo "Error: --ignore-this-version cannot be used with --silent" >&2
            return 1
        fi
        # If version.fake already exists, offer to delete it
        if [[ -f "$version_fake_file" ]]; then
            current_fake="$(cat "$version_fake_file" 2>/dev/null | tr -d '[:space:]')"
            echo ""
            echo "A version.fake file already exists at: $version_fake_file"
            echo "Current fake version: ${current_fake:-<empty>}"
            echo ""
            read -r -p "Delete existing version.fake? [y/N]: " __rfake
            case "${__rfake:-N}" in
                [Yy]* )
                    if rm -f "$version_fake_file"; then
                        echo "Removed existing version.fake. Re-run with --ignore-this-version to set a new one."
                        return 0
                    else
                        echo "Error: failed to remove $version_fake_file" >&2
                        return 1
                    fi
                    ;;
                * )
                    echo "Keeping existing version.fake. Cancelled."
                    return 1
                    ;;
            esac
        fi
        echo ""
        echo "Repository version available: $remote_version"
        echo
        read -r -p "Ignore this version for future update checks? [y/N]: " __ans
        case "${__ans:-N}" in
            [Yy]* )
                if printf "%s\n" "$remote_version" > "$version_fake_file"; then
                    echo "Saved ignored version to $version_fake_file"
                    echo "To restore normal checks, delete this file: rm -f \"$version_fake_file\""
                    return 0
                else
                    echo "Error: failed to write $version_fake_file" >&2
                    return 1
                fi
                ;;
            * )
                echo "Cancelled."
                return 1
                ;;
        esac
    fi
    
    # Compare versions using the same algorithm as _UPDATE.sh
    compare_versions "$remote_version" "$installed_version"
    local cmp_result=$?
    
    local update_available=false
    case $cmp_result in
        1)
            # remote_version > installed_version
            update_available=true
            ;;
        0)
            # Versions equal
            update_available=false
            ;;
        2)
            # remote_version < installed_version (downgrade available, but not an update)
            update_available=false
            ;;
        *)
            echo "Error: Invalid version format. Installed: $installed_version, Remote: $remote_version" >&2
            return 1
            ;;
    esac
    
    if [[ "$update_available" == "true" ]]; then
        echo "Update available!"
        echo "  Installed version: $installed_version"
        echo "  Repository version: $remote_version"
        echo ""
        
        # Determine if we should auto-update (either --yes flag or user confirms)
        local should_autoupdate=false
        if [[ "$yes_flag" == "true" ]]; then
            should_autoupdate=true
        elif [[ "$silent" != "true" ]]; then
            echo "Would you like to auto-update now? (This will clone the repository to /tmp and run the update)"
            read -r -p "Auto-update? [y/N]: " __autoupdate
            case "${__autoupdate:-N}" in
                [Yy]* )
                    should_autoupdate=true
                    ;;
                * )
                    echo ""
                    echo "Auto-update cancelled."
                    echo ""
                    echo "Tips:"
                    echo "  - To ignore this repository version in future checks, run: drcupdate --ignore-this-version"
                    echo ""
                    echo "To update manually:"
                    echo "  1. Navigate to your cloned DOGRC repository directory"
                    echo "  2. When in the repository directory, run: git pull"
                    echo "  3. Run: ./install/_UPDATE.sh"
                    echo ""
                    echo "⚠️  Important: Do NOT run _UPDATE.sh from ~/DOGRC/"
                    echo "   The update script must be run from your cloned git repository directory."
                    return 0
                    ;;
            esac
        fi
        
        # Perform auto-update if requested
        if [[ "$should_autoupdate" == "true" ]]; then
            # Check if git is available
            if ! command -v git >/dev/null 2>&1; then
                echo "Error: git is required for auto-update but is not installed" >&2
                echo ""
                echo "To update manually:"
                echo "  1. Navigate to your cloned DOGRC repository directory"
                echo "  2. When in the repository directory, run: git pull"
                echo "  3. Run: ./install/_UPDATE.sh"
                return 1
            fi
            
            # Create temporary directory for cloning
            local temp_repo
            temp_repo=$(mktemp -d "/tmp/DOGRC-update.XXXXXX" 2>/dev/null || echo "/tmp/DOGRC-update.$$")
            
            echo ""
            echo "Cloning repository to $temp_repo..."
            if ! git clone "https://github.com/lovelyspacedog/DOGRC.git" "$temp_repo" 2>/dev/null; then
                echo "Error: Failed to clone repository" >&2
                rm -rf "$temp_repo" 2>/dev/null
                return 1
            fi
            
            echo "Running update script..."
            if [[ -f "$temp_repo/install/_UPDATE.sh" ]] && [[ -x "$temp_repo/install/_UPDATE.sh" ]]; then
                # Run update script from temp directory
                if (cd "$temp_repo" && bash "./install/_UPDATE.sh"); then
                    echo ""
                    echo "Update completed successfully!"
                else
                    echo ""
                    echo "Error: Update script failed" >&2
                    rm -rf "$temp_repo" 2>/dev/null
                    return 1
                fi
            else
                echo "Error: Update script not found or not executable in cloned repository" >&2
                rm -rf "$temp_repo" 2>/dev/null
                return 1
            fi
            
            # Cleanup
            echo "Cleaning up temporary repository..."
            rm -rf "$temp_repo" 2>/dev/null
            echo "Done!"
            return 0
        else
            # Silent mode - just show update instructions
            echo "Tips:"
            echo "  - To ignore this repository version in future checks, run: drcupdate --ignore-this-version"
            echo "  - To begin auto-update, run: drcupdate --yes"
            echo ""
            echo "To update manually:"
            echo "  1. Navigate to your cloned DOGRC repository directory"
            echo "       Repository URL: https://github.com/lovelyspacedog/DOGRC"
            echo "  2. When in the repository directory, run: git pull"
            echo "  3. Run: ./install/_UPDATE.sh"
            echo ""
            echo "⚠️  Important: Do NOT run _UPDATE.sh from ~/DOGRC/"
            echo "   The update script must be run from your cloned git repository directory."
            return 0
        fi
    else
        if [[ "$silent" != "true" ]]; then
            echo "You are running the latest version: $installed_version"
        fi
        return 0
    fi
}

# Bash completion function for drcupdate
_drcupdate_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Complete with flags if:
    # 1. Current word starts with a dash, OR
    # 2. Current word is empty (after a space)
    if [[ "$cur" == -* ]] || [[ -z "$cur" ]]; then
        COMPREPLY=($(compgen -W "--help -h --silent -s --ignore-this-version --ignore --return-only --yes -y" -- "$cur"))
        return 0
    fi

    # No completion for non-flag arguments (drcupdate doesn't take positional args)
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _drcupdate_completion drcupdate 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    drcupdate "$@"
    exit $?
fi

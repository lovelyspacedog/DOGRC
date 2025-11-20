#!/bin/bash

# DOGRC Update Script
# This script updates DOGRC to the latest version from the install directory

# Exit on error, but allow functions to handle their own errors
set -o pipefail

# Ensure we're running in bash (not sh)
if [[ -z "${BASH_VERSION:-}" ]]; then
    echo "Error: This script requires bash. Please run with: bash $0" >&2
    exit 1  # Exit code 1: Bash version check failed
fi

# Prevent running from ~/BASHRC - must run from git repository
CHECK_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$CHECK_ROOT_DIR" == "$HOME/BASHRC" ]]; then
    echo "Error: This script cannot be run directly from ~/BASHRC" >&2
    echo "Please run this script from the git repository location (e.g., ~/Code/DOGRC)" >&2
    exit 2  # Exit code 2: Running from ~/BASHRC (not allowed)
fi
unset CHECK_ROOT_DIR

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Copyright splash screen
COPYRIGHT="${COPYRIGHT:-true}"
msg="Made by Tony Pup (c) 2025. All rights reserved.    Rarf~~! <3"

# Update changelog (current release changes only)
__UPDATE_CHANGELOG="$(cat <<'EOF'
Changes in this update (version 0.1.5):

### New Features
- **Unit Test Runner**: Added comprehensive test runner with tmux interface
  - Real-time progress tracking with split pane display (overview + live test output)
  - Elapsed time tracking for suite and individual tests
  - Auto-close after 5 seconds when tests complete
  - 'q' key binding to quit early
  - Helper functions for real-time test progress updates

- **Unit Test Infrastructure**: Added comprehensive unit test suite
  - Added `_TEST-ALL.sh`: Main test runner script
  - Added `_test-results-helper.sh`: Helper functions for test results
  - Added unit tests for all 25 plugins with real-time progress tracking
  - Enhanced test-weather.sh with N/A test handling (excludes N/A from percentage)

- **prepfile Utility**: Deprecated prepsh, added prepfile with multi-language support
  - Supports multiple programming languages (bash, python, rust, go, javascript, typescript, C, C++, java, ruby, perl, php, lua, zsh, fish)
  - Automatic file extension handling
  - Makes script files executable automatically

- **runtests Plugin**: Added new utility plugin to run unit test suite
  - Full drchelp documentation integration
  - Help flags delegate to drchelp

### Enhancements
- **motd.sh**: Added pager support for long messages (>20 lines)
  - Shows preview for long messages
  - Opens full content in read-only pager
  - Updated drchelp documentation

- **compress()**: Fixed exit code capture for gz and bz2 formats

- **Installation**: Added optional unit-tests installation prompt in _INSTALL.sh

- **Documentation**: 
  - Regenerated README.md based on current project state
  - Added comprehensive comparison report between DOGRC and BASHRC
  - Enhanced drchelp documentation for all utilities

### Testing
- Added comprehensive unit tests for all 25 plugins with real-time progress tracking

### Infrastructure
- Moved unit-tests from testing/unit-tests to root level
- Added runtests.sh to plugin check in _INSTALL.sh
EOF
)"

# Rollback tracking variables
__BACKUP_DOGRC=""
__BACKUP_BASHRC=""
__DOGRC_BACKED_UP=false
__BASHRC_REPLACED=false
__TIMESTAMP=""

# Get script directories
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly INSTALLED_DOGRC="$HOME/DOGRC"

# Semantic version comparison function
# Returns: 0 if versions equal, 1 if v1 > v2, 2 if v1 < v2, 3 on error
compare_versions() {
    local v1="$1"
    local v2="$2"
    
    # Remove 'v' prefix if present
    v1="${v1#v}"
    v2="${v2#v}"
    
    # Split version strings into arrays
    IFS='.' read -ra v1_parts <<< "$v1"
    IFS='.' read -ra v2_parts <<< "$v2"
    
    # Ensure both arrays have at least 3 elements (pad with 0 if needed)
    while [[ ${#v1_parts[@]} -lt 3 ]]; do
        v1_parts+=("0")
    done
    while [[ ${#v2_parts[@]} -lt 3 ]]; do
        v2_parts+=("0")
    done
    
    # Compare major, minor, patch
    for i in 0 1 2; do
        local num1="${v1_parts[$i]//[!0-9]/0}"  # Remove non-numeric, default to 0
        local num2="${v2_parts[$i]//[!0-9]/0}"
        
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

# Get version from DOGRC.json or version.fake
get_installed_version() {
    local version_file="${INSTALLED_DOGRC}/config/version.fake"
    local json_file="${INSTALLED_DOGRC}/config/DOGRC.json"
    
    # Check version.fake first
    if [[ -f "$version_file" ]]; then
        local version=$(cat "$version_file" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi
    
    # Fall back to DOGRC.json
    if [[ -f "$json_file" ]] && command -v jq >/dev/null 2>&1; then
        local version=$(jq -r '.version // empty' "$json_file" 2>/dev/null)
        if [[ -n "$version" ]] && [[ "$version" != "null" ]]; then
            echo "$version"
            return 0
        fi
    elif [[ -f "$json_file" ]]; then
        # Fallback: try to extract version with grep
        local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi
    
    # Default fallback
    echo "0.0.9"
    return 1
}

# Get version from install directory
get_install_dir_version() {
    local json_file="${INSTALL_DIR}/config/DOGRC.json"
    
    if [[ -f "$json_file" ]] && command -v jq >/dev/null 2>&1; then
        local version=$(jq -r '.version // empty' "$json_file" 2>/dev/null)
        if [[ -n "$version" ]] && [[ "$version" != "null" ]]; then
            echo "$version"
            return 0
        fi
    elif [[ -f "$json_file" ]]; then
        # Fallback: try to extract version with grep
        local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi
    
    return 1
}

# Extract preamble snippet for a specific case branch
extract_preamble_snippet() {
    local preamble_file="${INSTALLED_DOGRC}/config/preamble.sh"
    local branch="$1"  # --non-interactive, --interactive, or --after-loading
    
    if [[ ! -f "$preamble_file" ]]; then
        echo ""
        return 1
    fi
    
    # Find the case branch
    local in_branch=false
    local snippet=""
    local found_comment=false
    
    while IFS= read -r line; do
        # Check if we're entering the target branch
        if [[ "$line" =~ ^[[:space:]]*"$branch"[[:space:]]*\) ]]; then
            in_branch=true
            found_comment=false
            continue
        fi
        
        # If we hit another case branch or return, we're done
        if [[ "$in_branch" == true ]] && [[ "$line" =~ ^[[:space:]]*return[[:space:]]+0 ]]; then
            break
        fi
        
        # If we hit another case branch while in branch, we're done
        if [[ "$in_branch" == true ]] && [[ "$line" =~ ^[[:space:]]*--[a-z-]+\) ]]; then
            break
        fi
        
        # If we're in the branch, collect lines after comment
        if [[ "$in_branch" == true ]]; then
            # Check if this is a comment line (start of user content area)
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                found_comment=true
                continue
            fi
            
            # Collect content after comment (skip empty lines at start)
            if [[ "$found_comment" == true ]]; then
                # Skip leading empty lines
                if [[ -z "$snippet" ]] && [[ -z "$(echo "$line" | tr -d '[:space:]')" ]]; then
                    continue
                fi
                snippet+="$line"$'\n'
            fi
        fi
    done < "$preamble_file"
    
    # Trim trailing newlines
    echo -n "${snippet%%$'\n'}"
}

# Extract user aliases (aliases not in new version)
extract_user_aliases() {
    local old_aliases="${INSTALLED_DOGRC}/core/aliases.sh"
    local new_aliases="${INSTALL_DIR}/core/aliases.sh"
    
    if [[ ! -f "$old_aliases" ]] || [[ ! -f "$new_aliases" ]]; then
        echo ""
        return 1
    fi
    
    local user_aliases=""
    local in_user_section=false
    
    # Extract aliases from old file
    while IFS= read -r line; do
        # Skip comments and empty lines at start
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$(echo "$line" | tr -d '[:space:]')" ]]; then
            continue
        fi
        
        # Check if line is an alias definition
        if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+ ]]; then
            local alias_name=$(echo "$line" | sed -n 's/^[[:space:]]*alias[[:space:]]\+\([^=]*\)=.*/\1/p')
            
            # Check if this alias exists in new version
            if ! grep -q "^[[:space:]]*alias[[:space:]]\+${alias_name}=" "$new_aliases" 2>/dev/null; then
                user_aliases+="$line"$'\n'
            fi
        fi
    done < "$old_aliases"
    
    # Trim trailing newlines
    echo -n "${user_aliases%%$'\n'}"
}

# Store enable_ values from DOGRC.json
store_enable_values() {
    local json_file="${INSTALLED_DOGRC}/config/DOGRC.json"
    
    if [[ ! -f "$json_file" ]] || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi
    
    # Extract all enable_* keys and store them
    while IFS= read -r key; do
        if [[ "$key" =~ ^enable_ ]]; then
            local value=$(jq -r ".[\"$key\"] // false" "$json_file" 2>/dev/null)
            # Store as __ENABLE_<UPPERCASE_KEY> to avoid conflicts
            local var_name="__ENABLE_${key^^}"
            eval "${var_name}='$value'"
        fi
    done < <(jq -r 'keys[]' "$json_file" 2>/dev/null)
    
    return 0
}

# Restore enable_ values to new DOGRC.json
restore_enable_values() {
    local json_file="${INSTALLED_DOGRC}/config/DOGRC.json"
    
    if [[ ! -f "$json_file" ]] || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi
    
    # Build jq expression to update all enable_* values
    local jq_expr="."
    local has_updates=false
    
    # Get all enable_* variables from environment
    local var_name
    while IFS= read -r var_name; do
        # Match __ENABLE_ENABLE_* variables (e.g., __ENABLE_ENABLE_BLESH=true)
        if [[ "$var_name" =~ ^__ENABLE_(ENABLE_[A-Z_]+)=(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            key="${key,,}"  # Convert to lowercase
            local value="${BASH_REMATCH[2]}"
            
            if [[ "$value" == "true" ]] || [[ "$value" == "false" ]]; then
                jq_expr+=" | .[\"$key\"] = ${value}"
                has_updates=true
            fi
        fi
    done < <(set | grep "^__ENABLE_ENABLE_")
    
    # If no updates, nothing to do
    if [[ "$has_updates" != true ]]; then
        return 0
    fi
    
    # Apply updates (preserving version)
    local temp_file=$(mktemp)
    jq "$jq_expr" "$json_file" > "$temp_file" 2>/dev/null || {
        rm -f "$temp_file"
        return 1
    }
    
    mv "$temp_file" "$json_file" 2>/dev/null || {
        rm -f "$temp_file"
        return 1
    }
    
    return 0
}

# Restore preamble snippets
restore_preamble_snippets() {
    local preamble_file="${INSTALLED_DOGRC}/config/preamble.sh"
    local non_interactive_snippet="$1"
    local interactive_snippet="$2"
    local after_loading_snippet="$3"
    
    if [[ ! -f "$preamble_file" ]]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    local in_branch=false
    local current_branch=""
    
    while IFS= read -r line; do
        # Check if entering a case branch
        if [[ "$line" =~ ^[[:space:]]*--(non-interactive|interactive|after-loading)[[:space:]]*\) ]]; then
            current_branch="${BASH_REMATCH[1]}"
            in_branch=true
            echo "$line" >> "$temp_file"
            continue
        fi
        
        # If we hit return 0, insert snippet before it
        if [[ "$in_branch" == true ]] && [[ "$line" =~ ^[[:space:]]*return[[:space:]]+0 ]]; then
            # Insert appropriate snippet
            case "$current_branch" in
                non-interactive)
                    if [[ -n "$non_interactive_snippet" ]]; then
                        echo "$non_interactive_snippet" >> "$temp_file"
                        echo "" >> "$temp_file"
                    fi
                    ;;
                interactive)
                    if [[ -n "$interactive_snippet" ]]; then
                        echo "$interactive_snippet" >> "$temp_file"
                        echo "" >> "$temp_file"
                    fi
                    ;;
                after-loading)
                    if [[ -n "$after_loading_snippet" ]]; then
                        echo "$after_loading_snippet" >> "$temp_file"
                        echo "" >> "$temp_file"
                    fi
                    ;;
            esac
            in_branch=false
            current_branch=""
        fi
        
        # If we hit another case branch, reset
        if [[ "$in_branch" == true ]] && [[ "$line" =~ ^[[:space:]]*--[a-z-]+\) ]]; then
            in_branch=false
            current_branch=""
        fi
        
        echo "$line" >> "$temp_file"
    done < "$preamble_file"
    
    mv "$temp_file" "$preamble_file" 2>/dev/null || {
        rm -f "$temp_file"
        return 1
    }
    
    return 0
}

# Merge user aliases into new aliases.sh
merge_user_aliases() {
    local aliases_file="${INSTALLED_DOGRC}/core/aliases.sh"
    local user_aliases="$1"
    
    if [[ ! -f "$aliases_file" ]] || [[ -z "$user_aliases" ]]; then
        return 0  # Nothing to merge
    fi
    
    # Try to append user aliases
    {
        echo ""
        echo "# User custom aliases (merged from previous installation)"
        echo "$user_aliases"
    } >> "$aliases_file" 2>/dev/null || {
        echo -e "${YELLOW}Warning: Failed to merge aliases automatically.${NC}" >&2
        echo -e "${YELLOW}Please manually merge ${INSTALLED_DOGRC}/core/aliases.sh.backup into ${INSTALLED_DOGRC}/core/aliases.sh${NC}" >&2
        return 1
    }
    
    return 0
}

# Rollback function
rollback_update() {
    echo
    echo -e "${YELLOW}Attempting to rollback update...${NC}"
    echo
    
    # Remove lingering DOGRC directory
    if [[ -d "$INSTALLED_DOGRC" ]]; then
        echo -e "  ${BLUE}Removing partial installation...${NC}"
        rm -rf "$INSTALLED_DOGRC" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Removed $INSTALLED_DOGRC" || echo -e "  ${YELLOW}⚠${NC} Could not fully remove $INSTALLED_DOGRC" >&2
    fi
    
    # Restore DOGRC backup
    if [[ "$__DOGRC_BACKED_UP" == true ]] && [[ -n "$__BACKUP_DOGRC" ]] && [[ -d "$__BACKUP_DOGRC" ]]; then
        echo -e "  ${BLUE}Restoring DOGRC from backup...${NC}"
        if cp -r "$__BACKUP_DOGRC" "$INSTALLED_DOGRC" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Restored $INSTALLED_DOGRC from backup"
        else
            echo -e "  ${RED}✗${NC} Failed to restore DOGRC from backup" >&2
        fi
    fi
    
    # Restore .bashrc backup
    if [[ "$__BASHRC_REPLACED" == true ]] && [[ -n "$__BACKUP_BASHRC" ]] && [[ -f "$__BACKUP_BASHRC" ]]; then
        echo -e "  ${BLUE}Restoring ~/.bashrc from backup...${NC}"
        if cp "$__BACKUP_BASHRC" "$HOME/.bashrc" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Restored ~/.bashrc from backup"
        else
            echo -e "  ${RED}✗${NC} Failed to restore ~/.bashrc" >&2
        fi
    fi
    
    echo
    echo -e "${YELLOW}Rollback complete.${NC}"
    echo -e "${YELLOW}Note: Backup files were preserved:${NC}"
    [[ -n "$__BACKUP_DOGRC" ]] && [[ -d "$__BACKUP_DOGRC" ]] && echo -e "  • $__BACKUP_DOGRC"
    [[ -n "$__BACKUP_BASHRC" ]] && [[ -f "$__BACKUP_BASHRC" ]] && echo -e "  • $__BACKUP_BASHRC"
    echo
}

# Main update function
main() {
    # Copyright splash screen
    ! ! ! ! ! $COPYRIGHT || {
        clear
        for ((i = 0; i < ${#msg}; i++)); do
            printf "%s" "${msg:$i:1}"
            sleep 0.01
        done
        sleep 0.4 && rarf_text="Rarf~~! <3"
        if [[ "$msg" == *"$rarf_text" ]]; then
            rarf_start=$((${#msg} - ${#rarf_text}))
            printf "\033[%dD" ${#rarf_text}
            printf "%${#rarf_text}s" ""
            printf "\033[%dD" ${#rarf_text}
        fi
        printf "\n\n"
        sleep 0.03
    }
    
    echo -e "${BLUE}DOGRC Update Script${NC}"
    echo -e "${BLUE}==================${NC}"
    echo
    
    # Check if DOGRC is installed
    if [[ ! -d "$INSTALLED_DOGRC" ]] || [[ ! -f "${INSTALLED_DOGRC}/config/DOGRC.json" ]]; then
        echo -e "${YELLOW}DOGRC does not appear to be installed.${NC}"
        echo -e "${YELLOW}Please run ${BLUE}install/_INSTALL.sh${NC} to install DOGRC first.${NC}"
        echo
        exit 0
    fi
    
    # Get versions
    local old_version=$(get_installed_version)
    local new_version=$(get_install_dir_version)
    
    if [[ -z "$new_version" ]]; then
        echo -e "${RED}ERROR: Cannot determine version from install directory${NC}" >&2
        exit 3  # Exit code 3: Cannot determine version from install directory
    fi
    
    # Compare versions
    compare_versions "$new_version" "$old_version"
    local cmp_result=$?
    
    case $cmp_result in
        0)
            echo -e "${YELLOW}DOGRC is already at version ${BLUE}$old_version${NC}"
            echo -e "${YELLOW}No update needed.${NC}"
            echo
            exit 0
            ;;
        2)
            echo -e "${YELLOW}Installed version (${BLUE}$old_version${NC}) is newer than install directory version (${BLUE}$new_version${NC})${NC}"
            echo -e "${YELLOW}This appears to be a downgrade.${NC}"
            echo
            read -p "Continue with downgrade? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Update cancelled.${NC}"
                exit 0
            fi
            ;;
    esac
    
    # Prompt for upgrade
    echo -e "${YELLOW}Current version: ${BLUE}$old_version${NC}"
    echo -e "${YELLOW}New version:     ${BLUE}$new_version${NC}"
    echo
    read -p "Continue with update? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Update cancelled.${NC}"
        exit 0
    fi
    echo
    
    # Verify install scripts exist
    local install_script="${SCRIPT_DIR}/_INSTALL.sh"
    local generate_template="${INSTALL_DIR}/install/generate_template.sh"
    
    if [[ ! -f "$install_script" ]] || [[ ! -x "$install_script" ]]; then
        echo -e "${RED}ERROR: _INSTALL.sh not found or not executable: $install_script${NC}" >&2
        exit 4  # Exit code 4: _INSTALL.sh not found or not executable
    fi
    
    if [[ ! -f "$generate_template" ]] || [[ ! -x "$generate_template" ]]; then
        echo -e "${RED}ERROR: generate_template.sh not found or not executable: $generate_template${NC}" >&2
        exit 5  # Exit code 5: generate_template.sh not found or not executable
    fi
    
    # Create timestamp
    __TIMESTAMP="$(date +%Y%m%d%H%M%S)"
    
    # Backup DOGRC
    echo -e "${BLUE}Creating backups...${NC}"
    echo
    __BACKUP_DOGRC="${INSTALLED_DOGRC}.backup.${__TIMESTAMP}"
    if cp -r "$INSTALLED_DOGRC" "$__BACKUP_DOGRC" 2>/dev/null; then
        __DOGRC_BACKED_UP=true
        echo -e "  ${GREEN}✓${NC} Backed up DOGRC to $__BACKUP_DOGRC"
    else
        echo -e "  ${RED}✗${NC} Failed to backup DOGRC" >&2
        exit 6  # Exit code 6: Failed to backup DOGRC
    fi
    
    # Backup .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        __BACKUP_BASHRC="$HOME/.bashrc.backup.${__TIMESTAMP}"
        if cp "$HOME/.bashrc" "$__BACKUP_BASHRC" 2>/dev/null; then
            __BASHRC_REPLACED=true
            echo -e "  ${GREEN}✓${NC} Backed up ~/.bashrc to $__BACKUP_BASHRC"
        else
            echo -e "  ${YELLOW}⚠${NC} Failed to backup ~/.bashrc (continuing anyway)" >&2
        fi
    fi
    echo
    sleep 0.5
    
    # Store enable_ values
    echo -e "${BLUE}Storing configuration...${NC}"
    if ! store_enable_values; then
        echo -e "  ${YELLOW}⚠${NC} Could not store enable_ values (will continue anyway)" >&2
    else
        echo -e "  ${GREEN}✓${NC} Stored enable_ values"
    fi
    
    # Extract preamble snippets
    local non_interactive_snippet=$(extract_preamble_snippet "--non-interactive")
    local interactive_snippet=$(extract_preamble_snippet "--interactive")
    local after_loading_snippet=$(extract_preamble_snippet "--after-loading")
    echo -e "  ${GREEN}✓${NC} Extracted preamble snippets"
    
    # Validate extracted snippets
    local snippet_errors=0
    if [[ -n "$non_interactive_snippet" ]]; then
        if ! bash -n - <<< "$non_interactive_snippet" 2>/dev/null; then
            echo -e "  ${YELLOW}⚠${NC} Warning: --non-interactive snippet has syntax errors" >&2
            ((snippet_errors++))
        fi
    fi
    if [[ -n "$interactive_snippet" ]]; then
        if ! bash -n - <<< "$interactive_snippet" 2>/dev/null; then
            echo -e "  ${YELLOW}⚠${NC} Warning: --interactive snippet has syntax errors" >&2
            ((snippet_errors++))
        fi
    fi
    if [[ -n "$after_loading_snippet" ]]; then
        if ! bash -n - <<< "$after_loading_snippet" 2>/dev/null; then
            echo -e "  ${YELLOW}⚠${NC} Warning: --after-loading snippet has syntax errors" >&2
            ((snippet_errors++))
        fi
    fi
    
    if [[ $snippet_errors -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} Some preamble snippets have syntax errors. Update will continue but snippets may need manual fixes.${NC}" >&2
    fi
    echo
    sleep 0.5
    
    # Delete old DOGRC and install new
    echo -e "${BLUE}Installing new version...${NC}"
    echo
    if [[ -d "$INSTALLED_DOGRC" ]]; then
        rm -rf "$INSTALLED_DOGRC" 2>/dev/null || {
            echo -e "${RED}ERROR: Failed to remove old installation${NC}" >&2
            rollback_update
            exit 7  # Exit code 7: Failed to remove old installation
        }
    fi
    
    # Determine unit-tests preference
    local include_unit_tests="n"
    
    # Check if this is an upgrade from 0.1.4 or lower to 0.1.5 or higher
    # In this case, unit-tests are new, so we should prompt the user
    local should_prompt_for_unit_tests=false
    
    # Check if old version is < 0.1.5 (compare_versions returns 1 if 0.1.5 > old_version)
    compare_versions "0.1.5" "$old_version"
    local old_is_below_1_5=$?
    
    # Check if new version is >= 0.1.5 (compare_versions returns 1 if new_version > 0.1.5, 0 if equal)
    compare_versions "$new_version" "0.1.5"
    local new_is_at_least_1_5=$?
    
    # If old version is < 0.1.5 and new version is >= 0.1.5, prompt user
    if [[ $old_is_below_1_5 -eq 1 ]] && ([[ $new_is_at_least_1_5 -eq 1 ]] || [[ $new_is_at_least_1_5 -eq 0 ]]); then
        should_prompt_for_unit_tests=true
    fi
    
    if [[ "$should_prompt_for_unit_tests" == true ]]; then
        # Special case: upgrading to first version with unit-tests
        echo -e "  ${BLUE}Unit-tests are now available in DOGRC 0.1.5+${NC}"
        echo -e "  ${YELLOW}They can be used to verify DOGRC functionality.${NC}"
        echo
        read -p "Include unit-tests directory in installation? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            include_unit_tests="y"
            echo -e "  ${GREEN}Unit-tests will be included.${NC}"
        else
            include_unit_tests="n"
            echo -e "  ${YELLOW}Unit-tests will be excluded.${NC}"
        fi
        echo
    else
        # Normal case: check backup for existing preference
        if [[ "$__DOGRC_BACKED_UP" == true ]] && [[ -n "$__BACKUP_DOGRC" ]] && [[ -d "$__BACKUP_DOGRC" ]]; then
            if [[ -d "${__BACKUP_DOGRC}/unit-tests" ]] && [[ -n "$(ls -A "${__BACKUP_DOGRC}/unit-tests" 2>/dev/null)" ]]; then
                include_unit_tests="y"
                echo -e "  ${BLUE}Detected unit-tests in backup, will include in new installation${NC}"
            fi
        fi
    fi
    
    # Run installation script non-interactively
    # Input format: 
    #   - "y" (continue installation) - always needed (line 922)
    #   - "y" (continue with missing recommended deps if prompted) - only if recommended deps missing (line 215)
    #   - "y/n" (include unit-tests) - always needed (line 957)
    # 
    # Note: We need to provide all inputs even if some prompts might not appear,
    # because the script reads from stdin and will consume input in order.
    # Using printf with explicit newlines to ensure proper handling with read -n 1.
    
    # Check for recommended dependencies using the same logic as _INSTALL.sh
    local missing_recommended=false
    local recommended_commands=("nvim" "pokemon-colorscripts" "fastfetch" "yay" "flatpak")
    for cmd in "${recommended_commands[@]}"; do
        # Special handling for pokemon-colorscripts (file check, not command)
        if [[ "$cmd" == "pokemon-colorscripts" ]]; then
            if ! command -v "$cmd" >/dev/null 2>&1; then
                missing_recommended=true
                break
            fi
        else
            if ! command -v "$cmd" >/dev/null 2>&1; then
                missing_recommended=true
                break
            fi
        fi
    done
    
    # Build input string with explicit newlines
    # Each prompt uses read -n 1, so we need "y\n" or "n\n" for each
    # Note: We always pass "n" for unit-tests here, then copy the directory manually after installation
    # This avoids input piping issues with read -n 1
    local install_input="y"$'\n'  # First prompt: continue installation
    
    # Add "continue anyway" input if recommended deps are missing
    if [[ "$missing_recommended" == true ]]; then
        install_input+="y"$'\n'  # Second prompt: continue anyway with missing recommended deps
    fi
    
    # Always pass "n" for unit-tests - we'll copy the directory manually after installation if needed
    install_input+="n"$'\n'
    
    # Debug: Show what we're sending (commented out for production)
    # echo "DEBUG: Sending input: $(printf '%q' "$install_input")" >&2
    
    # Run installation with all inputs (always excluding unit-tests for now)
    if ! printf "%s" "$install_input" | COPYRIGHT=false bash "$install_script" 2>/dev/null; then
        echo -e "${RED}ERROR: Installation failed${NC}" >&2
        rollback_update
        exit 8  # Exit code 8: Installation failed
    fi
    
    echo -e "  ${GREEN}✓${NC} Installation completed"
    echo
    sleep 0.5
    
    # Copy unit-tests directory manually if requested
    # This avoids input piping issues with read -n 1 in _INSTALL.sh
    if [[ "$include_unit_tests" == "y" ]]; then
        local source_unit_tests="${INSTALL_DIR}/unit-tests"
        local dest_unit_tests="${INSTALLED_DOGRC}/unit-tests"
        
        if [[ -d "$source_unit_tests" ]]; then
            echo -e "${BLUE}Copying unit-tests directory...${NC}"
            if cp -r "$source_unit_tests" "$dest_unit_tests" 2>/dev/null; then
                # Set executable permissions on test scripts
                find "$dest_unit_tests" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
                echo -e "  ${GREEN}✓${NC} Copied unit-tests directory"
            else
                echo -e "  ${YELLOW}⚠${NC} Failed to copy unit-tests directory" >&2
            fi
            echo
        else
            echo -e "  ${YELLOW}⚠${NC} Source unit-tests directory not found: $source_unit_tests" >&2
        fi
    fi
    
    # Merge user aliases
    echo -e "${BLUE}Merging user customizations...${NC}"
    echo
    local user_aliases=$(extract_user_aliases)
    if [[ -n "$user_aliases" ]]; then
        if merge_user_aliases "$user_aliases"; then
            echo -e "  ${GREEN}✓${NC} Merged user aliases"
        else
            echo -e "  ${YELLOW}⚠${NC} Failed to merge aliases automatically (see warning above)" >&2
        fi
    else
        echo -e "  ${GREEN}✓${NC} No custom aliases to merge"
    fi
    
    # Restore enable_ values
    if restore_enable_values; then
        echo -e "  ${GREEN}✓${NC} Restored enable_ values"
    else
        echo -e "  ${YELLOW}⚠${NC} Failed to restore enable_ values" >&2
    fi
    
    # Restore navto.json if it exists in backup
    if [[ -f "${__BACKUP_DOGRC}/config/navto.json" ]]; then
        if cp "${__BACKUP_DOGRC}/config/navto.json" "${INSTALLED_DOGRC}/config/navto.json" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Restored config/navto.json"
        else
            echo -e "  ${YELLOW}⚠${NC} Failed to restore config/navto.json" >&2
        fi
    fi
    
    # Validate DOGRC.json
    if command -v jq >/dev/null 2>&1; then
        if jq empty "${INSTALLED_DOGRC}/config/DOGRC.json" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} DOGRC.json is valid JSON"
        else
            echo -e "  ${RED}✗${NC} DOGRC.json is not valid JSON" >&2
            rollback_update
            exit 9  # Exit code 9: DOGRC.json is not valid JSON
        fi
    fi
    
    # Restore preamble snippets
    if restore_preamble_snippets "$non_interactive_snippet" "$interactive_snippet" "$after_loading_snippet"; then
        echo -e "  ${GREEN}✓${NC} Restored preamble snippets"
    else
        echo -e "  ${YELLOW}⚠${NC} Failed to restore preamble snippets" >&2
    fi
    
    # Validate merged preamble
    if bash -n "${INSTALLED_DOGRC}/config/preamble.sh" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Merged preamble.sh has valid syntax"
    else
        echo -e "  ${RED}✗${NC} Merged preamble.sh has syntax errors" >&2
        echo -e "  ${YELLOW}Please manually fix ${INSTALLED_DOGRC}/config/preamble.sh${NC}" >&2
    fi
    
    # Copy user plugins
    if [[ -d "${__BACKUP_DOGRC}/plugins/user-plugins" ]]; then
        local user_plugin_count=0
        for plugin in "${__BACKUP_DOGRC}/plugins/user-plugins"/*.sh; do
            [[ -f "$plugin" ]] || continue
            local plugin_name=$(basename "$plugin")
            if [[ "$plugin_name" != "example.sh" ]]; then
                if cp "$plugin" "${INSTALLED_DOGRC}/plugins/user-plugins/" 2>/dev/null; then
                    ((user_plugin_count++))
                fi
            fi
        done
        if [[ $user_plugin_count -gt 0 ]]; then
            echo -e "  ${GREEN}✓${NC} Copied $user_plugin_count user plugin(s)"
        else
            echo -e "  ${GREEN}✓${NC} No user plugins to copy"
        fi
    fi
    echo
    sleep 0.5
    
    # Generate MOTD
    echo -e "${BLUE}Generating update summary...${NC}"
    echo
    local motd_file="$HOME/motd.txt"
    cat > "$motd_file" <<EOF
🎉 DOGRC has been successfully updated!
   Enter :q <enter> to exit the MOTD.
   Type 'motd shoo' in terminal to remove this message.

Update Details:
  • Previous version: $old_version
  • New version: $new_version
  • Location: $INSTALLED_DOGRC

$__UPDATE_CHANGELOG

Getting Started:
  1. Start a new shell session or run: source ~/.bashrc
  2. Check configuration: $INSTALLED_DOGRC/config/DOGRC.json
  3. Check available commands: drchelp

Customization:
  • Your custom aliases have been preserved
  • Your preamble snippets have been restored
  • Your user plugins have been copied over
  • Your enable_ settings have been preserved

Backup:
  • Old installation backed up to: $__BACKUP_DOGRC
  • You can safely remove this backup once you've verified everything works

Type 'motd shoo' to remove this message.
EOF
    
    if [[ -f "$motd_file" ]]; then
        echo -e "  ${GREEN}✓${NC} Created $motd_file"
    else
        echo -e "  ${YELLOW}⚠${NC} Failed to create MOTD" >&2
    fi
    echo
    sleep 0.5
    
    # Update complete
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}DOGRC Update Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Start a new shell session or run: ${BLUE}source ~/.bashrc${NC}"
    echo -e "  2. Check update summary: ${BLUE}cat ~/motd.txt${NC}"
    echo -e "  3. Verify installation: ${BLUE}drchelp${NC}"
    echo
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

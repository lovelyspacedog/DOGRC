#!/bin/bash

# DOGRC Installation Script
# This script installs DOGRC to the user's system

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

# Rollback tracking variables
__BACKUP_BASHRC=""
__BACKUP_BASH_PROFILE=""
__INSTALL_DIR_CREATED=false
__BASHRC_REPLACED=false
__MOTD_CREATED=false
__INCLUDE_UNIT_TESTS=false

# Dependency check function
check_dependencies() {
    local missing_required=()
    local missing_recommended=()
    local missing_optional=()
    local all_good=true

    # Core/Required dependencies (POSIX commands that should always be available)
    local required_commands=(
        "bash" "cat" "cp" "date" "basename" "mkdir" "mv" "rm" "grep" "sed"
        "head" "tail" "find" "sort" "xargs" "ls" "touch" "chmod" "printf"
        "shopt" "read" "tr" "wc" "stat" "du" "awk" "cut" "ps" "nohup"
        "tar" "gzip" "gunzip" "unzip" "jq" "kitty"  # jq required for DOGRC.json parsing, drcversion, automotd, navto; kitty required for openthis, xx
    )

    # Recommended dependencies (used by multiple plugins)
    local recommended_commands=(
        "nvim"  # Used in aliases, bashrc, openthis, n, h
        "pokemon-colorscripts"  # Used in pokefetch
        "fastfetch"  # Used in pokefetch
        "yay"  # Used in command-not-found, update (Arch-specific)
        "flatpak"  # Used in command-not-found, update
    )

    # Optional dependencies (plugin-specific, nice to have)
    local optional_commands=(
        "eza" "fortune" "curl" "bc" "g++" "yt-dlp" "ffmpeg"
        "notify-send" "wl-copy" "xdg-open" "unrar" "rar" "7z" "perl" "sha256sum"
        "bunzip2" "bzip2" "uncompress" "compress" "starship" "zoxide"
        "topgrade" "file"
    )

    echo -e "${BLUE}Checking dependencies...${NC}"
    echo

    # Check required commands
    echo -e "${BLUE}Required dependencies:${NC}"
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $cmd"
        else
            echo -e "  ${RED}✗${NC} $cmd ${RED}(MISSING)${NC}"
            missing_required+=("$cmd")
            all_good=false
        fi
    done
    echo

    # Check recommended commands (only show if there are any)
    if [[ ${#recommended_commands[@]} -gt 0 ]]; then
        echo -e "${BLUE}Recommended dependencies:${NC}"
        for cmd in "${recommended_commands[@]}"; do
            if command -v "$cmd" >/dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} $cmd"
            else
                echo -e "  ${YELLOW}⚠${NC} $cmd ${YELLOW}(RECOMMENDED)${NC}"
                missing_recommended+=("$cmd")
            fi
        done
        echo
    fi

    # Check optional commands (only show missing ones to reduce clutter)
    echo -e "${BLUE}Optional dependencies (showing missing only):${NC}"
    local optional_found=false
    for cmd in "${optional_commands[@]}"; do
        # Special handling for file-based checks (always check file, not command)
        case "$cmd" in
            "blesh")
                if [[ ! -f "$HOME/.local/share/blesh/ble.sh" ]]; then
                    missing_optional+=("$cmd")
                    optional_found=true
                fi
                ;;
            "shell-mommy")
                if [[ ! -f "$HOME/shell-mommy/shell-mommy.sh" ]]; then
                    missing_optional+=("$cmd")
                    optional_found=true
                fi
                ;;
            *)
                # Regular command check
                if ! command -v "$cmd" >/dev/null 2>&1; then
                    missing_optional+=("$cmd")
                    optional_found=true
                fi
                ;;
        esac
    done

    if [[ "$optional_found" == true ]]; then
        for cmd in "${missing_optional[@]}"; do
            echo -e "  ${YELLOW}○${NC} $cmd ${YELLOW}(OPTIONAL)${NC}"
        done
    else
        echo -e "  ${GREEN}All optional dependencies found!${NC}"
    fi
    echo

    # Summary and exit
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        echo -e "${RED}ERROR: Missing required dependencies:${NC}"
        printf "  %s\n" "${missing_required[@]}"
        echo
        echo -e "${RED}Installation cannot continue without these dependencies.${NC}"
        echo -e "${YELLOW}Please install the missing commands and try again.${NC}"
        echo
        # Provide installation hints for common missing dependencies
        for cmd in "${missing_required[@]}"; do
            case "$cmd" in
                "jq")
                    echo -e "${BLUE}Install jq:${NC}"
                    echo -e "  Arch:     sudo pacman -S jq"
                    echo -e "  Debian:   sudo apt install jq"
                    echo -e "  Fedora:   sudo dnf install jq"
                    echo -e "  macOS:    brew install jq"
                    echo
                    ;;
                "kitty")
                    echo -e "${BLUE}Install kitty:${NC}"
                    echo -e "  Arch:     sudo pacman -S kitty"
                    echo -e "  Debian:   sudo apt install kitty"
                    echo -e "  Fedora:   sudo dnf install kitty"
                    echo -e "  macOS:    brew install kitty"
                    echo -e "  Or visit: https://sw.kovidgoyal.net/kitty/"
                    echo
                    ;;
            esac
        done
        return 1
    fi

    if [[ ${#missing_recommended[@]} -gt 0 ]]; then
        echo -e "${YELLOW}WARNING: Missing recommended dependencies:${NC}"
        printf "  %s\n" "${missing_recommended[@]}"
        echo
        echo -e "${YELLOW}Some features may not work correctly without these.${NC}"
        echo -e "${YELLOW}Consider installing:${NC}"
        for cmd in "${missing_recommended[@]}"; do
            case "$cmd" in
                "nvim")
                    echo -e "  ${BLUE}- nvim:${NC} Text editor"
                    echo -e "     Arch:     sudo pacman -S neovim"
                    echo -e "     Debian:   sudo apt install neovim"
                    echo -e "     Fedora:   sudo dnf install neovim"
                    echo -e "     macOS:    brew install neovim"
                    ;;
                "pokemon-colorscripts")
                    echo -e "  ${BLUE}- pokemon-colorscripts:${NC} Pokemon terminal colorscripts"
                    echo -e "     Install:  yay -S pokemon-colorscripts-git  # Arch"
                    echo -e "     Or:       See https://github.com/kalkayan/pokemon-colorscripts"
                    ;;
                "fastfetch")
                    echo -e "  ${BLUE}- fastfetch:${NC} System information tool"
                    echo -e "     Arch:     sudo pacman -S fastfetch"
                    echo -e "     Debian:   sudo apt install fastfetch"
                    echo -e "     Fedora:   sudo dnf install fastfetch"
                    echo -e "     macOS:    brew install fastfetch"
                    ;;
                "yay")
                    echo -e "  ${BLUE}- yay:${NC} AUR helper (Arch Linux only)"
                    echo -e "     Install:  See https://github.com/Jguer/yay"
                    ;;
                "flatpak")
                    echo -e "  ${BLUE}- flatpak:${NC} Application sandboxing and distribution framework"
                    echo -e "     Arch:     sudo pacman -S flatpak"
                    echo -e "     Debian:   sudo apt install flatpak"
                    echo -e "     Fedora:   sudo dnf install flatpak"
                    ;;
            esac
        done
        echo
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation cancelled.${NC}"
            return 1
        fi
    fi

    if [[ "$all_good" == true ]]; then
        echo -e "${GREEN}All required dependencies are installed!${NC}"
        echo
        return 0
    fi

    return 1
}

# Backup existing configuration files
backup_config_files() {
    local timestamp
    timestamp="$(date +%Y%m%d%H%M%S)"
    local backup_count=0

    echo -e "${BLUE}Creating backups of existing configuration files...${NC}"
    echo

    # Backup ~/.bashrc if it exists
    if [[ -f "$HOME/.bashrc" ]]; then
        __BACKUP_BASHRC="$HOME/.bashrc.backup.${timestamp}"
        if cp "$HOME/.bashrc" "$__BACKUP_BASHRC" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Backed up $HOME/.bashrc to $__BACKUP_BASHRC"
            ((backup_count++))
        else
            echo -e "  ${RED}✗${NC} Failed to backup $HOME/.bashrc" >&2
            echo -e "${RED}ERROR: Cannot create backup of .bashrc${NC}" >&2
            return 1
        fi
    else
        echo -e "  ${YELLOW}○${NC} $HOME/.bashrc does not exist (skipping)"
    fi

    # Backup ~/.bash_profile if it exists
    if [[ -f "$HOME/.bash_profile" ]]; then
        __BACKUP_BASH_PROFILE="$HOME/.bash_profile.backup.${timestamp}"
        if cp "$HOME/.bash_profile" "$__BACKUP_BASH_PROFILE" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Backed up $HOME/.bash_profile to $__BACKUP_BASH_PROFILE"
            ((backup_count++))
        else
            echo -e "  ${RED}✗${NC} Failed to backup $HOME/.bash_profile" >&2
            echo -e "${RED}ERROR: Cannot create backup of .bash_profile${NC}" >&2
            return 1
        fi
    else
        echo -e "  ${YELLOW}○${NC} $HOME/.bash_profile does not exist (skipping)"
    fi

    if [[ $backup_count -gt 0 ]]; then
        echo
        echo -e "${GREEN}Successfully created ${backup_count} backup(s)${NC}"
    else
        echo
        echo -e "${YELLOW}No existing configuration files to backup${NC}"
    fi
    echo

    return 0
}

# Copy DOGRC directory structure to installation location
copy_dogrc_files() {
    local install_dir="$HOME/DOGRC"
    local source_dir
    source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    echo -e "${BLUE}Copying DOGRC files to installation location...${NC}"
    echo

    # Verify source directory exists and contains expected structure
    if [[ ! -d "$source_dir" ]]; then
        echo -e "${RED}ERROR: Source directory not found: $source_dir${NC}" >&2
        return 1
    fi

    if [[ ! -f "$source_dir/.bashrc" ]]; then
        echo -e "${RED}ERROR: Source directory does not appear to be DOGRC root (missing .bashrc)${NC}" >&2
        return 1
    fi

    # Create installation directory if it doesn't exist
    if [[ ! -d "$install_dir" ]]; then
        if ! mkdir -p "$install_dir" 2>/dev/null; then
            echo -e "${RED}ERROR: Cannot create installation directory: $install_dir${NC}" >&2
            return 1
        fi
        __INSTALL_DIR_CREATED=true
        echo -e "  ${GREEN}✓${NC} Created installation directory: $install_dir"
    else
        # Directory exists but should be empty (checked earlier)
        if [[ -n "$(ls -A "$install_dir" 2>/dev/null)" ]]; then
            echo -e "${RED}ERROR: Installation directory is not empty: $install_dir${NC}" >&2
            echo -e "${YELLOW}Please remove the directory or use _UPDATE.sh for upgrades${NC}" >&2
            return 1
        fi
    fi

    # Copy files using rsync if available, otherwise use cp
    if command -v rsync >/dev/null 2>&1; then
        echo -e "  ${BLUE}Using rsync to copy files...${NC}"
        if [[ "$__INCLUDE_UNIT_TESTS" == true ]]; then
        if rsync -av --exclude='.git' --exclude='*.backup.*' "$source_dir/" "$install_dir/" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Successfully copied DOGRC files using rsync"
        else
            echo -e "  ${YELLOW}rsync failed, trying cp...${NC}"
            # Fall back to cp
                # Enable dotglob to include hidden files
                local old_dotglob
                shopt -q dotglob && old_dotglob=1 || old_dotglob=0
                shopt -s dotglob
                
                # Copy all files including hidden ones
            if ! cp -r "$source_dir"/* "$source_dir"/.[!.]* "$install_dir/" 2>/dev/null; then
                    [[ $old_dotglob -eq 0 ]] && shopt -u dotglob
                echo -e "  ${RED}✗${NC} Failed to copy files" >&2
                return 1
            fi
                
                # Restore dotglob state
                [[ $old_dotglob -eq 0 ]] && shopt -u dotglob
            echo -e "  ${GREEN}✓${NC} Successfully copied DOGRC files using cp"
            fi
        else
            if rsync -av --exclude='.git' --exclude='*.backup.*' --exclude='unit-tests' "$source_dir/" "$install_dir/" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} Successfully copied DOGRC files using rsync"
            else
                echo -e "  ${YELLOW}rsync failed, trying cp...${NC}"
                # Fall back to cp
                # Enable dotglob to include hidden files
                local old_dotglob
                shopt -q dotglob && old_dotglob=1 || old_dotglob=0
                shopt -s dotglob
                
                # Copy everything except unit-tests
                for item in "$source_dir"/* "$source_dir"/.[!.]*; do
                    [[ ! -e "$item" ]] && continue
                    local basename_item=$(basename "$item")
                    if [[ "$basename_item" == "unit-tests" ]]; then
                        continue
                    fi
                    if ! cp -r "$item" "$install_dir/" 2>/dev/null; then
                        [[ $old_dotglob -eq 0 ]] && shopt -u dotglob
                        echo -e "  ${RED}✗${NC} Failed to copy files" >&2
                        return 1
                    fi
                done
                
                # Restore dotglob state
                [[ $old_dotglob -eq 0 ]] && shopt -u dotglob
                echo -e "  ${GREEN}✓${NC} Successfully copied DOGRC files using cp"
            fi
        fi
    else
        echo -e "  ${BLUE}Using cp to copy files...${NC}"
        # Enable dotglob to include hidden files
        local old_dotglob
        shopt -q dotglob && old_dotglob=1 || old_dotglob=0
        shopt -s dotglob
        
        # Copy all files including hidden ones, excluding unit-tests if needed
        if [[ "$__INCLUDE_UNIT_TESTS" == true ]]; then
        if ! cp -r "$source_dir"/* "$install_dir/" 2>/dev/null; then
            # Restore dotglob state
            [[ $old_dotglob -eq 0 ]] && shopt -u dotglob
            echo -e "  ${RED}✗${NC} Failed to copy files" >&2
            return 1
            fi
        else
            # Copy everything except unit-tests
            for item in "$source_dir"/*; do
                [[ ! -e "$item" ]] && continue
                local basename_item=$(basename "$item")
                if [[ "$basename_item" == "unit-tests" ]]; then
                    continue
                fi
                if ! cp -r "$item" "$install_dir/" 2>/dev/null; then
                    [[ $old_dotglob -eq 0 ]] && shopt -u dotglob
                    echo -e "  ${RED}✗${NC} Failed to copy files" >&2
                    return 1
                fi
            done
        fi
        
        # Restore dotglob state
        [[ $old_dotglob -eq 0 ]] && shopt -u dotglob
        echo -e "  ${GREEN}✓${NC} Successfully copied DOGRC files"
    fi

    # Verify essential files were copied
    local essential_files=(
        ".bashrc"
        "config/DOGRC.json"
        "core/dependency_check.sh"
        "install/generate_template.sh"
    )

    local missing_files=()
    for file in "${essential_files[@]}"; do
        if [[ ! -f "$install_dir/$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo -e "${RED}ERROR: Essential files missing after copy:${NC}" >&2
        printf "  %s\n" "${missing_files[@]}" >&2
        return 1
    fi

    # Set executable permissions on shell scripts
    echo -e "  ${BLUE}Setting executable permissions...${NC}"
    find "$install_dir" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    chmod +x "$install_dir/.bashrc" 2>/dev/null || true

    echo
    echo -e "${GREEN}Successfully copied DOGRC to: $install_dir${NC}"
    echo

    return 0
}

# Generate user-configurable files
generate_user_files() {
    local install_dir="$HOME/DOGRC"
    local source_dir
    source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local generate_template="$install_dir/install/generate_template.sh"

    echo -e "${BLUE}Generating user-configurable files...${NC}"
    echo

    # Verify generate_template.sh exists (try installed version first, then source)
    if [[ ! -f "$generate_template" ]]; then
        generate_template="$source_dir/install/generate_template.sh"
        if [[ ! -f "$generate_template" ]]; then
            echo -e "${RED}ERROR: generate_template.sh not found${NC}" >&2
            return 1
        fi
    fi

    # Get version from source DOGRC.json or use default
    local version="0.1.0"
    if [[ -f "$source_dir/config/DOGRC.json" ]]; then
        if command -v jq >/dev/null 2>&1; then
            version=$(jq -r '.version // "0.1.0"' "$source_dir/config/DOGRC.json" 2>/dev/null || echo "0.1.0")
        else
            # Fallback: try to extract version with grep
            version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$source_dir/config/DOGRC.json" 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"' || echo "0.1.0")
        fi
    fi

    # Generate core/aliases.sh
    echo -e "  ${BLUE}Generating core/aliases.sh...${NC}"
    if bash "$generate_template" aliases > "$install_dir/core/aliases.sh" 2>/dev/null; then
        chmod +x "$install_dir/core/aliases.sh" 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Created core/aliases.sh"
    else
        echo -e "  ${RED}✗${NC} Failed to generate core/aliases.sh" >&2
        return 1
    fi

    # Generate config/preamble.sh
    echo -e "  ${BLUE}Generating config/preamble.sh...${NC}"
    if bash "$generate_template" preamble > "$install_dir/config/preamble.sh" 2>/dev/null; then
        chmod +x "$install_dir/config/preamble.sh" 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Created config/preamble.sh"
    else
        echo -e "  ${RED}✗${NC} Failed to generate config/preamble.sh" >&2
        return 1
    fi

    # Generate config/DOGRC.json
    echo -e "  ${BLUE}Generating config/DOGRC.json...${NC}"
    if bash "$generate_template" DOGRC.json | sed "s/\"REPLACE\"/\"$version\"/" > "$install_dir/config/DOGRC.json" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Created config/DOGRC.json with version $version"
    else
        echo -e "  ${RED}✗${NC} Failed to generate config/DOGRC.json" >&2
        return 1
    fi

    # Generate config/disabled.json
    echo -e "  ${BLUE}Generating config/disabled.json...${NC}"
    if bash "$generate_template" disabled.json > "$install_dir/config/disabled.json" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Created config/disabled.json"
    else
        echo -e "  ${RED}✗${NC} Failed to generate config/disabled.json" >&2
        return 1
    fi

    # Generate plugins/user-plugins/example.sh
    echo -e "  ${BLUE}Generating plugins/user-plugins/example.sh...${NC}"
    # Ensure the directory exists
    mkdir -p "$install_dir/plugins/user-plugins" 2>/dev/null || {
        echo -e "  ${RED}✗${NC} Failed to create plugins/user-plugins directory" >&2
        return 1
    }
    if bash "$generate_template" example > "$install_dir/plugins/user-plugins/example.sh" 2>/dev/null; then
        chmod +x "$install_dir/plugins/user-plugins/example.sh" 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Created plugins/user-plugins/example.sh"
    else
        echo -e "  ${RED}✗${NC} Failed to generate plugins/user-plugins/example.sh" >&2
        return 1
    fi

    # Generate ~/.bashrc (redirect)
    echo -e "  ${BLUE}Generating ~/.bashrc (redirect to DOGRC)...${NC}"
    if bash "$generate_template" redirect > "$HOME/.bashrc" 2>/dev/null; then
        chmod +x "$HOME/.bashrc" 2>/dev/null || true
        __BASHRC_REPLACED=true
        echo -e "  ${GREEN}✓${NC} Created ~/.bashrc (redirects to DOGRC)"
    else
        echo -e "  ${RED}✗${NC} Failed to generate ~/.bashrc" >&2
        return 1
    fi

    echo
    echo -e "${GREEN}Successfully generated user-configurable files${NC}"
    echo

    return 0
}

# Verify installed DOGRC directory structure and files
verify_installation() {
    local install_dir="$HOME/DOGRC"
    local errors=0

    echo -e "${BLUE}Verifying DOGRC installation...${NC}"
    echo

    # Check root directory exists
    if [[ ! -d "$install_dir" ]]; then
        echo -e "  ${RED}✗${NC} Installation directory does not exist: $install_dir" >&2
        return 1
    fi

    # Required directories
    local required_dirs=(
        "config"
        "core"
        "plugins"
        "plugins/file-operations"
        "plugins/information"
        "plugins/navigation"
        "plugins/utilities"
        "plugins/user-plugins"
        "install"
    )

    echo -e "${BLUE}Checking directory structure:${NC}"
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$install_dir/$dir" ]]; then
            echo -e "  ${GREEN}✓${NC} $dir/"
        else
            echo -e "  ${RED}✗${NC} Missing directory: $dir/" >&2
            ((errors++))
        fi
    done
    echo

    # Required files
    local required_files=(
        ".bashrc"
        "config/DOGRC.json"
        "config/preamble.sh"
        "config/disabled.json"
        "core/dependency_check.sh"
        "core/aliases.sh"
        "install/generate_template.sh"
        "plugins/user-plugins/example.sh"
    )

    echo -e "${BLUE}Checking required files:${NC}"
    for file in "${required_files[@]}"; do
        if [[ -f "$install_dir/$file" ]]; then
            echo -e "  ${GREEN}✓${NC} $file"
        else
            echo -e "  ${RED}✗${NC} Missing file: $file" >&2
            ((errors++))
        fi
    done
    echo

    # Check file permissions (shell scripts should be executable)
    echo -e "${BLUE}Checking file permissions:${NC}"
    local script_files=(
        ".bashrc"
        "config/preamble.sh"
        "core/dependency_check.sh"
        "core/aliases.sh"
        "install/generate_template.sh"
        "plugins/user-plugins/example.sh"
    )

    for file in "${script_files[@]}"; do
        if [[ -f "$install_dir/$file" ]]; then
            if [[ -x "$install_dir/$file" ]]; then
                echo -e "  ${GREEN}✓${NC} $file (executable)"
            else
                echo -e "  ${YELLOW}⚠${NC} $file (not executable, attempting to fix...)"
                chmod +x "$install_dir/$file" 2>/dev/null || {
                    echo -e "  ${RED}✗${NC} Failed to make $file executable" >&2
                    ((errors++))
                }
            fi
        fi
    done
    echo

    # Verify ~/.bashrc exists and correctly sources DOGRC
    echo -e "${BLUE}Checking ~/.bashrc:${NC}"
    if [[ ! -f "$HOME/.bashrc" ]]; then
        echo -e "  ${RED}✗${NC} ~/.bashrc does not exist" >&2
        ((errors++))
    else
        # Check if it sources DOGRC/.bashrc
        local sources_dogrc=false
        local correct_path=false
        
        # Check for various possible source patterns
        # Pattern 1: source "$HOME/DOGRC/.bashrc" or source '$HOME/DOGRC/.bashrc'
        if grep -qE 'source\s+["'\'']?\$HOME/DOGRC/\.bashrc["'\'']?' "$HOME/.bashrc" 2>/dev/null; then
            sources_dogrc=true
            correct_path=true
        # Pattern 2: source "~/DOGRC/.bashrc" or source '~/DOGRC/.bashrc'
        elif grep -qE 'source\s+["'\'']?~/DOGRC/\.bashrc["'\'']?' "$HOME/.bashrc" 2>/dev/null; then
            sources_dogrc=true
            correct_path=true
        # Pattern 3: source with expanded $HOME path (escaped for regex)
        elif grep -qF "source \"$HOME/DOGRC/.bashrc\"" "$HOME/.bashrc" 2>/dev/null || \
             grep -qF "source '$HOME/DOGRC/.bashrc'" "$HOME/.bashrc" 2>/dev/null; then
            sources_dogrc=true
            correct_path=true
        # Pattern 4: . "$HOME/DOGRC/.bashrc" (dot command)
        elif grep -qE '\.\s+["'\'']?\$HOME/DOGRC/\.bashrc["'\'']?' "$HOME/.bashrc" 2>/dev/null; then
            sources_dogrc=true
            correct_path=true
        # Pattern 5: . "~/DOGRC/.bashrc" (dot command with tilde)
        elif grep -qE '\.\s+["'\'']?~/DOGRC/\.bashrc["'\'']?' "$HOME/.bashrc" 2>/dev/null; then
            sources_dogrc=true
            correct_path=true
        # Pattern 6: Any reference to DOGRC/.bashrc (fallback, path might be wrong)
        elif grep -qiE '(source|\.)\s+.*DOGRC.*\.bashrc' "$HOME/.bashrc" 2>/dev/null; then
            sources_dogrc=true
            # Path might be incorrect, but at least it references DOGRC
        fi

        if [[ "$sources_dogrc" == true ]]; then
            if [[ "$correct_path" == true ]]; then
                # Verify the target file exists and is readable
                if [[ -f "$install_dir/.bashrc" ]] && [[ -r "$install_dir/.bashrc" ]]; then
                    echo -e "  ${GREEN}✓${NC} ~/.bashrc exists and correctly sources $install_dir/.bashrc"
                else
                    echo -e "  ${RED}✗${NC} ~/.bashrc sources DOGRC/.bashrc but target file is missing or not readable" >&2
                    ((errors++))
                fi
            else
                echo -e "  ${YELLOW}⚠${NC} ~/.bashrc references DOGRC but path may be incorrect" >&2
                echo -e "     Expected: source \"\$HOME/DOGRC/.bashrc\"" >&2
            fi
        else
            echo -e "  ${RED}✗${NC} ~/.bashrc does not source DOGRC/.bashrc" >&2
            echo -e "     Expected: source \"\$HOME/DOGRC/.bashrc\"" >&2
            ((errors++))
        fi
    fi
    echo

    # Check DOGRC.json is valid JSON (if jq is available)
    if command -v jq >/dev/null 2>&1; then
        echo -e "${BLUE}Validating DOGRC.json:${NC}"
        if jq empty "$install_dir/config/DOGRC.json" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} config/DOGRC.json is valid JSON"
        else
            echo -e "  ${RED}✗${NC} config/DOGRC.json is not valid JSON" >&2
            ((errors++))
        fi
        echo
    fi

    # Check ~/DOGRC/.bashrc has valid syntax
    echo -e "${BLUE}Checking ~/DOGRC/.bashrc syntax:${NC}"
    if [[ -f "$install_dir/.bashrc" ]]; then
        if bash -n "$install_dir/.bashrc" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $install_dir/.bashrc has valid syntax"
        else
            echo -e "  ${RED}✗${NC} $install_dir/.bashrc has syntax errors" >&2
            # Show syntax errors
            bash -n "$install_dir/.bashrc" 2>&1 | head -5 | while IFS= read -r line; do
                echo -e "     $line" >&2
            done
            ((errors++))
        fi
    else
        echo -e "  ${RED}✗${NC} $install_dir/.bashrc does not exist" >&2
        ((errors++))
    fi
    echo

    # Verify plugins (warnings only, not errors)
    echo -e "${BLUE}Checking plugins:${NC}"
    local missing_plugins=0
    local plugin_files=(
        "plugins/drchelp.sh"
        "plugins/file-operations/archive.sh"
        "plugins/file-operations/backup.sh"
        "plugins/file-operations/blank.sh"
        "plugins/file-operations/dupefind.sh"
        "plugins/file-operations/mkcd.sh"
        "plugins/file-operations/swap.sh"
        "plugins/information/analyze-file.sh"
        "plugins/information/cpuinfo.sh"
        "plugins/information/drcfortune.sh"
        "plugins/information/drcversion.sh"
        "plugins/information/pokefetch.sh"
        "plugins/information/weather.sh"
        "plugins/navigation/cd-cdd-zd.sh"
        "plugins/navigation/dots.sh"
        "plugins/navigation/navto.sh"
        "plugins/navigation/slashback.sh"
        "plugins/utilities/automotd.sh"
        "plugins/utilities/available.sh"
        "plugins/utilities/bashrc.sh"
        "plugins/utilities/calc.sh"
        "plugins/utilities/command-not-found.sh"
        "plugins/utilities/cpx.sh"
        "plugins/utilities/dl-paper.sh"
        "plugins/utilities/fastnote.sh"
        "plugins/utilities/genpassword.sh"
        "plugins/utilities/h.sh"
        "plugins/utilities/motd.sh"
        "plugins/utilities/n.sh"
        "plugins/utilities/notifywhendone.sh"
        "plugins/utilities/openthis.sh"
        "plugins/utilities/prepfile.sh"
        "plugins/utilities/pwd.sh"
        "plugins/utilities/runtests.sh"
        "plugins/utilities/silent.sh"
        "plugins/utilities/timer.sh"
        "plugins/utilities/update.sh"
        "plugins/utilities/xx.sh"
    )

    for plugin in "${plugin_files[@]}"; do
        if [[ -f "$install_dir/$plugin" ]]; then
            echo -e "  ${GREEN}✓${NC} $plugin"
        else
            echo -e "  ${YELLOW}⚠${NC} Missing plugin: $plugin" >&2
            ((missing_plugins++))
        fi
    done

    if [[ $missing_plugins -gt 0 ]]; then
        echo
        echo -e "  ${YELLOW}WARNING: $missing_plugins plugin(s) are missing${NC}"
    fi
    echo

    # Summary
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}Installation verification passed!${NC}"
        echo
        return 0
    else
        echo -e "${RED}Installation verification failed with $errors error(s)${NC}" >&2
        echo
        return 1
    fi
}

# Generate MOTD with user instructions
generate_motd() {
    local install_dir="$HOME/DOGRC"
    local motd_file="$HOME/motd.txt"
    local version="0.1.0"
    
    # Try to get version from DOGRC.json
    if [[ -f "$install_dir/config/DOGRC.json" ]] && command -v jq >/dev/null 2>&1; then
        version=$(jq -r '.version // "0.1.0"' "$install_dir/config/DOGRC.json" 2>/dev/null || echo "0.1.0")
    fi

    echo -e "${BLUE}Generating installation summary...${NC}"
    echo

    cat > "$motd_file" <<EOF
🎉 DOGRC has been successfully installed!

Installation Details:
  • Version: $version
  • Location: $install_dir
  • Configuration: $install_dir/config/DOGRC.json

Getting Started:
  1. Start a new shell session or run: source ~/.bashrc
  2. Your old .bashrc was backed up with a timestamp
  3. Check available commands with: drchelp

Customization:
  • User aliases: Edit $install_dir/core/aliases.sh
  • User configuration: Edit $install_dir/config/preamble.sh
  • User plugins: Add scripts to $install_dir/plugins/user-plugins/
  • Feature flags: Edit $install_dir/config/DOGRC.json

Updating DOGRC:
  • Use the _UPDATE.sh script to upgrade DOGRC
  • Your customizations will be preserved

Documentation:
  • Run 'drchelp' to see all available commands
  • Check $install_dir/plugins/user-plugins/example.sh for plugin examples

Type 'motd shoo' to remove this message.
EOF

    if [[ -f "$motd_file" ]]; then
        __MOTD_CREATED=true
        echo -e "  ${GREEN}✓${NC} Created $motd_file"
        echo
        return 0
    else
        echo -e "  ${YELLOW}⚠${NC} Failed to create $motd_file" >&2
        return 1
    fi
}

# Rollback function to restore system state on failure
rollback_installation() {
    local install_dir="$HOME/DOGRC"
    
    echo
    echo -e "${YELLOW}Attempting to rollback installation...${NC}"
    echo

    # Restore ~/.bashrc from backup if it was replaced
    if [[ "$__BASHRC_REPLACED" == true ]] && [[ -n "$__BACKUP_BASHRC" ]] && [[ -f "$__BACKUP_BASHRC" ]]; then
        echo -e "  ${BLUE}Restoring ~/.bashrc from backup...${NC}"
        if cp "$__BACKUP_BASHRC" "$HOME/.bashrc" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Restored ~/.bashrc from backup"
        else
            echo -e "  ${RED}✗${NC} Failed to restore ~/.bashrc" >&2
        fi
    elif [[ "$__BASHRC_REPLACED" == true ]] && [[ ! -f "$__BACKUP_BASHRC" ]]; then
        # No backup exists, remove the new .bashrc if it was created
        if [[ -f "$HOME/.bashrc" ]]; then
            echo -e "  ${BLUE}Removing new ~/.bashrc (no backup found)...${NC}"
            rm -f "$HOME/.bashrc" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Removed ~/.bashrc" || echo -e "  ${RED}✗${NC} Failed to remove ~/.bashrc" >&2
        fi
    fi

    # Remove MOTD if it was created
    if [[ "$__MOTD_CREATED" == true ]] && [[ -f "$HOME/motd.txt" ]]; then
        echo -e "  ${BLUE}Removing ~/motd.txt...${NC}"
        rm -f "$HOME/motd.txt" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Removed ~/motd.txt" || echo -e "  ${YELLOW}⚠${NC} Failed to remove ~/motd.txt" >&2
    fi

    # Remove installation directory if it was created
    if [[ "$__INSTALL_DIR_CREATED" == true ]] && [[ -d "$install_dir" ]]; then
        echo -e "  ${BLUE}Removing installation directory...${NC}"
        if rm -rf "$install_dir" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Removed $install_dir"
        else
            echo -e "  ${RED}✗${NC} Failed to remove $install_dir (manual cleanup may be required)" >&2
        fi
    elif [[ -d "$install_dir" ]] && [[ -n "$(ls -A "$install_dir" 2>/dev/null)" ]]; then
        # Directory exists and has content, try to remove it anyway
        echo -e "  ${BLUE}Removing installation directory...${NC}"
        if rm -rf "$install_dir" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Removed $install_dir"
        else
            echo -e "  ${YELLOW}⚠${NC} Could not fully remove $install_dir (manual cleanup may be required)" >&2
        fi
    fi

    echo
    echo -e "${YELLOW}Rollback complete.${NC}"
    echo -e "${YELLOW}Note: Backup files were preserved:${NC}"
    [[ -n "$__BACKUP_BASHRC" ]] && [[ -f "$__BACKUP_BASHRC" ]] && echo -e "  • $__BACKUP_BASHRC"
    [[ -n "$__BACKUP_BASH_PROFILE" ]] && [[ -f "$__BACKUP_BASH_PROFILE" ]] && echo -e "  • $__BACKUP_BASH_PROFILE"
    echo
}

# Main installation function (placeholder for now)
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

    # Installation confirmation
    echo -e "${BLUE}DOGRC Installation Script${NC}"
    echo -e "${BLUE}========================${NC}"
    echo
    echo -e "${YELLOW}This script will install DOGRC to your system.${NC}"
    echo -e "${YELLOW}It will:${NC}"
    echo -e "  • Install DOGRC to ${BLUE}$HOME/DOGRC${NC}"
    echo -e "  • Replace ${BLUE}~/.bashrc${NC} (backup will be created)"
    echo -e "  • Generate user-configurable files"
    echo
    read -p "Continue with installation? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi
    echo

    # Check if DOGRC is already installed
    if [[ -d "$HOME/DOGRC" ]]; then
        # Check if directory is not empty
        if [[ -n "$(ls -A "$HOME/DOGRC" 2>/dev/null)" ]]; then
            echo -e "${YELLOW}DOGRC appears to already be installed at: $HOME/DOGRC${NC}"
            echo
            echo -e "${YELLOW}The directory exists and is not empty.${NC}"
            echo -e "${YELLOW}It is recommended that you use _UPDATE.sh to upgrade instead.${NC}"
            echo
            exit 0
        fi
    fi

    # Check dependencies first
    if ! check_dependencies; then
        echo -e "${RED}Dependency check failed. Exiting.${NC}"
        exit 3  # Exit code 3: Dependency check failed
    fi

    echo -e "${GREEN}Dependency check passed!${NC}"
    echo
    sleep 0.5

    # Prompt for unit-tests inclusion
    echo -e "${YELLOW}Unit tests are available but optional.${NC}"
    echo -e "${YELLOW}They can be used to verify DOGRC functionality.${NC}"
    echo
    read -p "Include unit-tests directory in installation? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        __INCLUDE_UNIT_TESTS=true
        echo -e "${GREEN}Unit-tests will be included.${NC}"
    else
        __INCLUDE_UNIT_TESTS=false
        echo -e "${YELLOW}Unit-tests will be excluded.${NC}"
    fi
    echo
    sleep 0.5

    # Create backups of existing configuration files
    if ! backup_config_files; then
        echo -e "${RED}Backup failed. Exiting.${NC}"
        exit 4  # Exit code 4: Backup failed
    fi
    sleep 0.5

    # Copy DOGRC files to installation location
    if ! copy_dogrc_files; then
        echo -e "${RED}File copy failed.${NC}"
        rollback_installation
        exit 5  # Exit code 5: File copy failed
    fi
    sleep 0.5

    # Generate user-configurable files
    if ! generate_user_files; then
        echo -e "${RED}Failed to generate user files.${NC}"
        rollback_installation
        exit 6  # Exit code 6: Failed to generate user files
    fi
    sleep 0.5

    # Verify installation
    if ! verify_installation; then
        echo -e "${RED}Installation verification failed.${NC}"
        rollback_installation
        exit 7  # Exit code 7: Installation verification failed
    fi
    sleep 0.5

    # Generate MOTD with user instructions
    if ! generate_motd; then
        # MOTD failure is non-critical, but we'll still log it
        echo -e "${YELLOW}Warning: Failed to generate MOTD, but installation is complete.${NC}"
    fi
    sleep 0.5

    # Installation complete
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}DOGRC Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Start a new shell session or run: ${BLUE}source ~/.bashrc${NC}"
    echo -e "  2. Check installation summary: ${BLUE}cat ~/motd.txt${NC}"
    echo -e "  3. Explore available commands: ${BLUE}drchelp${NC}"
    echo
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

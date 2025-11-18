#!/bin/bash
# Sourcing Guard - check if command_not_found_handle function already exists
if declare -f command_not_found_handle >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# command_not_found_handle is automatically called by bash when a command is not found
# $1 = command name
# $@ = all arguments passed to the command
command_not_found_handle() {
    local cmd="$1"
    shift
    local args=("$@")

    # Don't handle if running non-interactively
    [[ -t 1 ]] || {
        printf "bash: %s: command not found\n" "$cmd" >&2
        return 127
    }

    # Arrays to store found packages
    local -a yay_packages=()
    local -a flatpak_packages=()
    local found_any=false
    local __search_cancelled=0
    local __cancel_key=""
    
    # Helper: wait on PID while allowing user to cancel with any key
    wait_for_or_cancel() {
        local __pid="$1"
        while kill -0 "$__pid" >/dev/null 2>&1; do
            if read -t 0.05 -n 1 -s __cancel_key; then
                __search_cancelled=1
                kill "$__pid" >/dev/null 2>&1
                wait "$__pid" 2>/dev/null
                return 1
            fi
            sleep 0.05
        done
        wait "$__pid" 2>/dev/null
        return 0
    }

    printf "\nCommand '%s' not found. Searching for packages...\n\n" "$cmd"

    # Search yay (AUR and official repos)
    if command -v yay >/dev/null 2>&1; then
        printf "🔍 Searching yay (AUR + official)...\n"
        # Search for packages that might contain the command
        # yay output includes terminal escape sequences (OSC 8 hyperlinks)
        # We use regex to extract repo/package patterns directly, which works even with escape sequences
        # First try exact match (official repos often appear later), then broader search
        local yay_results
        local yay_tmp
        yay_tmp="$(mktemp)"
        # Run search fully detached to suppress job control messages
        YTMP="$yay_tmp" YCMD="$cmd" nohup bash -c '
            exact_match=$(yay -Ss "^${YCMD}$" 2>/dev/null | head -20)
            broad_results=$(yay -Ss "$YCMD" 2>/dev/null | head -100)
            printf "%s%s%s" "${exact_match}" "${exact_match:+$'\''\n'\''}" "${broad_results}" > "$YTMP"
        ' </dev/null >/dev/null 2>&1 &
        local yay_pid=$!
        disown "$yay_pid" >/dev/null 2>&1
        if ! wait_for_or_cancel "$yay_pid"; then
            rm -f "$yay_tmp"
            printf "bash: %s: command not found\n" "$cmd" >&2
            return 127
        fi
        yay_results="$(cat "$yay_tmp" 2>/dev/null)"
        rm -f "$yay_tmp"
        
        if [[ -n "$yay_results" ]]; then
            # Use associative array to track seen packages (remove duplicates)
            local -A seen_packages
            
            # Extract package names from yay output
            # yay uses OSC 8 hyperlinks: \033]8;;URL\033\\repo/package-name\033]8;;\033\\
            # Pattern: extract text between \033\\ and \033]8;;
            local extracted_pkgs=""
            
            # Try grep -oP first (PCRE lookahead/lookbehind) - test if it works
            # Extract more packages first (up to 30), then we'll prioritize and limit later
            if echo "$yay_results" | grep -oP '\033\\\K[a-z]+/[a-zA-Z0-9._-]+(?=\033]8;;)' >/dev/null 2>&1; then
                extracted_pkgs=$(echo "$yay_results" | grep -oP '\033\\\K[a-z]+/[a-zA-Z0-9._-]+(?=\033]8;;)' 2>/dev/null | head -30)
            fi
            
            # If grep -P not available or failed, try perl
            if [[ -z "$extracted_pkgs" ]] && command -v perl >/dev/null 2>&1; then
                # Match package name followed by \033]8;; (the package name is between \033\\ and \033]8;;)
                # Extract more packages first (up to 30), then we'll prioritize and limit later
                extracted_pkgs=$(echo "$yay_results" | perl -ne 'if (!/^\s/ && /([a-z]+\/[a-zA-Z0-9._-]+)\x1b\]8;;/) { print "$1\n"; }' 2>/dev/null | head -30)
            fi
            
            # If still empty, try extracting all matches and filter
            if [[ -z "$extracted_pkgs" ]]; then
                while IFS= read -r line; do
                    [[ -z "$line" ]] && continue
                    [[ "$line" =~ ^[[:space:]] ]] && continue
                    
                    # Extract all repo/package patterns
                    local all_matches
                    all_matches=$(echo "$line" | grep -oE '[a-z]+/[a-zA-Z0-9._-]+' 2>/dev/null)
                    
                    if [[ -n "$all_matches" ]]; then
                        # Find the one that's followed by version number (not in URL)
                        local valid_pkg=""
                        while IFS= read -r match; do
                            [[ "$match" =~ ^(www|http) ]] && continue
                            
                            # Get what comes after this match in the line
                            local after_match="${line#*$match}"
                            
                            # Valid if followed by escape sequence and version, or space and version
                            if echo "$after_match" | grep -qE '^(\x1b\]8;;|]8;;)[[:space:]]*[0-9]'; then
                                valid_pkg="$match"
                                break
                            elif [[ "$after_match" =~ ^[[:space:]]+[0-9] ]]; then
                                valid_pkg="$match"
                                break
                            fi
                        done <<< "$all_matches"
                        
                        if [[ -n "$valid_pkg" ]]; then
                            extracted_pkgs="${extracted_pkgs}${extracted_pkgs:+$'\n'}$valid_pkg"
                        fi
                    fi
                done <<< "$yay_results"
            fi
            
            # Process extracted packages - separate official from AUR and prioritize official
            local -a official_packages=()
            local -a aur_packages=()
            
            if [[ -n "$extracted_pkgs" ]]; then
                while IFS= read -r repo_pkg; do
                    [[ -z "$repo_pkg" ]] && continue
                    [[ "$repo_pkg" =~ ^[a-z]+/[a-zA-Z0-9._-]+$ ]] || continue
                    [[ -n "${seen_packages[$repo_pkg]:-}" ]] && continue
                    
                    seen_packages["$repo_pkg"]=1
                    
                    # Check if it's an official package (not AUR)
                    if [[ "$repo_pkg" =~ ^aur/ ]]; then
                        aur_packages+=("$repo_pkg")
                    else
                        official_packages+=("$repo_pkg")
                    fi
                done <<< "$extracted_pkgs"
            fi
            
            # Combine: official packages first, then AUR packages (limit to 10 total)
            for pkg in "${official_packages[@]}"; do
                yay_packages+=("$pkg")
                [[ ${#yay_packages[@]} -ge 10 ]] && break
            done
            # Add AUR packages if we haven't reached the limit
            if [[ ${#yay_packages[@]} -lt 10 ]]; then
                for pkg in "${aur_packages[@]}"; do
                    yay_packages+=("$pkg")
                    [[ ${#yay_packages[@]} -ge 10 ]] && break
                done
            fi
            
            if [[ ${#yay_packages[@]} -gt 0 ]]; then
                found_any=true
                printf "   Found %d package(s) in yay:\n" "${#yay_packages[@]}"
                local idx=1
                for pkg in "${yay_packages[@]}"; do
                    printf "   %2d) %s\n" "$idx" "$pkg"
                    ((idx++))
                done
                printf "\n"
            else
                printf "   No packages found in yay.\n\n"
            fi
        else
            printf "   No packages found in yay.\n\n"
        fi
    else
        printf "⚠️  yay not found (skipping AUR search)\n\n"
    fi

    # Search flatpak
    if command -v flatpak >/dev/null 2>&1; then
        printf "🔍 Searching flatpak...\n"
        local flatpak_results
        # flatpak search output: Application ID, Version, Branch, Origin, Summary
        # Output format can be tab-separated or space-separated
        local flatpak_tmp
        flatpak_tmp="$(mktemp)"
        # Run search fully detached to suppress job control messages
        FTMP="$flatpak_tmp" FCMD="$cmd" nohup bash -c '
            flatpak search "$FCMD" 2>/dev/null | head -20 > "$FTMP"
        ' </dev/null >/dev/null 2>&1 &
        local flatpak_pid=$!
        disown "$flatpak_pid" >/dev/null 2>&1
        if ! wait_for_or_cancel "$flatpak_pid"; then
            rm -f "$flatpak_tmp"
            printf "bash: %s: command not found\n" "$cmd" >&2
            return 127
        fi
        flatpak_results="$(cat "$flatpak_tmp" 2>/dev/null)"
        rm -f "$flatpak_tmp"
        
        if [[ -n "$flatpak_results" ]]; then
            local found_flatpak=false
            local -A seen_apps
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                # flatpak search output is tab-separated: Name<TAB>Description<TAB>AppID<TAB>Version<TAB>Branch<TAB>Origin
                # Extract app ID (third field)
                local app_id
                app_id=$(echo "$line" | awk -F'\t' '{print $3}')
                
                # Skip if empty or doesn't look like an app ID
                [[ -z "$app_id" ]] && continue
                # App IDs typically have format like: org.example.App or com.example-app
                [[ "$app_id" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*\.[a-zA-Z0-9][a-zA-Z0-9._-]*(\.[a-zA-Z0-9][a-zA-Z0-9._-]*)*$ ]] || continue
                [[ -n "${seen_apps[$app_id]:-}" ]] && continue
                
                seen_apps["$app_id"]=1
                flatpak_packages+=("$app_id")
                found_flatpak=true
                # Limit to 10 results
                [[ ${#flatpak_packages[@]} -ge 10 ]] && break
            done <<< "$flatpak_results"
            
            if [[ "$found_flatpak" == true ]]; then
                found_any=true
                printf "   Found %d package(s) in flatpak:\n" "${#flatpak_packages[@]}"
                local idx=1
                for pkg in "${flatpak_packages[@]}"; do
                    printf "   %2d) %s\n" "$idx" "$pkg"
                    ((idx++))
                done
                printf "\n"
            else
                printf "   No packages found in flatpak.\n\n"
            fi
        else
            printf "   No packages found in flatpak.\n\n"
        fi
    else
        printf "⚠️  flatpak not found (skipping flatpak search)\n\n"
    fi

    # If nothing found, show standard error and exit
    if [[ "$found_any" == false ]]; then
        printf "No packages found containing '%s'.\n" "$cmd"
        printf "bash: %s: command not found\n" "$cmd" >&2
        return 127
    fi

    # Prompt for installation
    local total_packages
    total_packages=$((${#yay_packages[@]} + ${#flatpak_packages[@]}))
    
    printf "Would you like to install one of these packages? [y/N]: "
    read -t 10 -n 1 -r response || response=""
    printf "\n"
    
    [[ "${response,,}" != "y" ]] && {
        printf "Installation cancelled.\n"
        printf "bash: %s: command not found\n" "$cmd" >&2
        return 127
    }

    # Choose which package to install
    printf "\nWhich package would you like to install?\n"
    
    # Show numbered list with source indicators
    local idx=1
    [[ ${#yay_packages[@]} -gt 0 ]] && {
        printf "\nYay packages:\n"
        for pkg in "${yay_packages[@]}"; do
            printf "  %2d) %s (yay)\n" "$idx" "$pkg"
            ((idx++))
        done
    }
    [[ ${#flatpak_packages[@]} -gt 0 ]] && {
        printf "\nFlatpak packages:\n"
        for pkg in "${flatpak_packages[@]}"; do
            printf "  %2d) %s (flatpak)\n" "$idx" "$pkg"
            ((idx++))
        done
    }
    
    printf "\nEnter a number (1-%d), or 'q' to quit: " "$total_packages"
    read -r choice
    
    [[ "${choice,,}" == "q" ]] && {
        printf "Installation cancelled.\n"
        printf "bash: %s: command not found\n" "$cmd" >&2
        return 127
    }

    # Validate and process choice
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local choice_num=$choice
        
        if [[ $choice_num -lt 1 || $choice_num -gt $total_packages ]]; then
            printf "Invalid choice. Number must be between 1 and %d.\n" "$total_packages" >&2
            return 127
        fi
        
        if [[ $choice_num -le ${#yay_packages[@]} ]]; then
            # Install from yay
            local selected_pkg="${yay_packages[$((choice_num - 1))]}"
            printf "\nInstalling '%s' using yay...\n" "$selected_pkg"
            if sudo -n true 2>/dev/null || sudo true; then
                yay -S --noconfirm "$selected_pkg" || {
                    printf "Error: Failed to install '%s'\n" "$selected_pkg" >&2
                    return 127
                }
                printf "\n✓ Successfully installed '%s'! You can now run '%s'.\n" "$selected_pkg" "$cmd"
                return 0
            else
                printf "Error: Cannot run yay without sudo privileges.\n" >&2
                return 127
            fi
        else
            # Install from flatpak
            local flatpak_idx=$((choice_num - ${#yay_packages[@]} - 1))
            local selected_app="${flatpak_packages[$flatpak_idx]}"
            printf "\nInstalling '%s' using flatpak...\n" "$selected_app"
            # Try to install - flatpak may need remote specified
            if flatpak install --assumeyes --noninteractive "$selected_app" 2>/dev/null; then
                printf "\n✓ Successfully installed '%s'! You can now run '%s'.\n" "$selected_app" "$cmd"
                return 0
            else
                # Try with flathub remote explicitly
                if flatpak install --assumeyes --noninteractive flathub "$selected_app" 2>/dev/null; then
                    printf "\n✓ Successfully installed '%s'! You can now run '%s'.\n" "$selected_app" "$cmd"
                    return 0
                else
                    printf "Error: Failed to install '%s'.\n" "$selected_app" >&2
                    printf "You may need to specify the remote manually:\n" >&2
                    printf "  flatpak search %s\n" "$cmd" >&2
                    printf "  flatpak install <remote> %s\n" "$selected_app" >&2
                    return 127
                fi
            fi
        fi
    else
        printf "Invalid choice. Please enter a number or 'q'.\n" >&2
        return 127
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: command_not_found_handle must be sourced, not executed directly." >&2
    echo "This function is automatically called by bash when a command is not found." >&2
    exit 1
fi


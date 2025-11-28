#!/bin/bash
# Sourcing Guard - check if update function already exists
if declare -f update >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

update() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp update
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "update" sudo || {
        return $?
    }
    
    sudo true
    if ! sudo -n true 2>/dev/null; then
        echo "Error: Cannot run update without sudo privileges." >&2
        return 2
    fi

    local yay_fail=0
    local flatpak_fail=0
    local topgrade_fail=0

    if command -v yay >/dev/null 2>&1; then
        yay -Syu --sudoloop --noconfirm || yay_fail=1
    else
        echo "Warning: yay not found; skipping AUR updates." >&2
        yay_fail=1
    fi

    if command -v flatpak >/dev/null 2>&1; then
        flatpak update --assumeyes || flatpak_fail=1
    else
        echo "Warning: flatpak not found; skipping Flatpak updates." >&2
        flatpak_fail=1
    fi

    if command -v topgrade >/dev/null 2>&1; then
        topgrade --yes --disable pacdef pacstall flatpak || topgrade_fail=1
    else
        echo "Warning: topgrade not found; skipping system-wide updates." >&2
        topgrade_fail=1
    fi

    # Check if hydecheck is enabled in DOGRC.json
    local hydecheck_enabled=false
    local config_file="${HOME}/DOGRC/config/DOGRC.json"
    if [[ -f "$config_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            hydecheck_enabled=$(jq -r '.enable_hydecheck // false' "$config_file" 2>/dev/null)
        else
            # Fallback to grep if jq is not available
            if grep -q '"enable_hydecheck"[[:space:]]*:[[:space:]]*true' "$config_file" 2>/dev/null; then
                hydecheck_enabled="true"
            fi
        fi
    fi

    # Debug: Check what value we got (remove this after debugging)
    #if [[ -n "${DEBUG_UPDATE:-}" ]]; then
    #    echo "DEBUG: config_file=$config_file" >&2
    #    echo "DEBUG: hydecheck_enabled=[$hydecheck_enabled]" >&2
    #    echo "DEBUG: comparison result=$([ "$hydecheck_enabled" == "true" ] && echo "match" || echo "no match")" >&2
    #fi

    if [[ "$hydecheck_enabled" == "true" ]]; then
        [[ -f "${HOME}/DOGRC/config/hydecheck.timestamp" ]] || {
            printf "%s" "$(($(date +%s) / 86400))" > "${HOME}/DOGRC/config/hydecheck.timestamp"
        }

        local hydecheck_timestamp="$(cat "${HOME}/DOGRC/config/hydecheck.timestamp")"
        local current_timestamp="$(($(date +%s) / 86400))"
        local days_since_last_check=$((current_timestamp - hydecheck_timestamp))

        if [[ $days_since_last_check -ge 90 ]]; then
            printf "\n\nIt's been over 90 days since last HyDE update.\n"
            printf "Would you like to update HyDE now? (y/N) "
            read -n 1 -r
            if [[ "${REPLY,,}" == "y" ]]; then
                while true; do
                    # Check if timeshift snapshot is enabled
                    local timeshift_enabled=false
                    if [[ -f "$config_file" ]]; then
                        if command -v jq >/dev/null 2>&1; then
                            timeshift_enabled=$(jq -r '.enable_hydecheck_include_timeshift // false' "$config_file" 2>/dev/null)
                        else
                            # Fallback to grep if jq is not available
                            if grep -q '"enable_hydecheck_include_timeshift"[[:space:]]*:[[:space:]]*true' "$config_file" 2>/dev/null; then
                                timeshift_enabled="true"
                            fi
                        fi
                    fi

                    if [[ "$timeshift_enabled" == "true" ]]; then
                        printf "Running timeshift snapshot! (sudo required)\n"
                        kitty bash -c "sudo timeshift --create --comments 'HyDE update'" || {
                            printf "WARNING: Failed to run timeshift snapshot\n"
                            printf "Press Enter to continue without a snapshot (i hope you know what you're doing)"
                            read -n 1 -r
                        }
                    fi

                    printf "Changing to HyDE scripts directory...\n"
                    cd "${HOME}/HyDE/Scripts" || {
                        printf "Error: Failed to change to HyDE scripts directory\n"
                        printf "Skipping HyDE update.\n"
                        printf "Delete DOGRC/config/hydecheck.timestamp to disable this check.\n\n"
                        break
                    }

                    printf "Pulling latest HyDE scripts...\n"
                    git pull origin master || {
                        printf "Error: Failed to pull latest HyDE scripts\n"
                        printf "Skipping HyDE update.\n"
                        printf "Delete DOGRC/config/hydecheck.timestamp to disable this check.\n\n"
                        break
                    }

                    printf "Displaying update information...\n"
                    cat <<'EOF'
HyDE update script found and updated!

Any configurations you made will be overwritten if listed to be done so as listed
  by Scripts/restore_cfg.psv. However, all replaced configs are backed up and may
  be recovered from in ~/.config/cfg_backups.

Confirm timeshift snapshot was created before proceeding.

Press Enter to continue...
EOF
                    read -n 1 -r

                    printf "Updating HyDE scripts...\n"
                    ./install.sh -r || {
                        printf "Error: Failed to update HyDE scripts\n"
                        printf "You may need to restore to a previous snapshot. :(\n"
                        break
                    }

                    printf "%s" "$(($(date +%s) / 86400))" > "${HOME}/DOGRC/config/hydecheck.timestamp"
                    printf "HyDE update complete! Timestamp updated.\n\n"
                    break
                done

            fi
        fi
    fi

    local result=$((yay_fail * 100 + flatpak_fail * 10 + topgrade_fail))
    return $result
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update "$@"
    exit $?
fi


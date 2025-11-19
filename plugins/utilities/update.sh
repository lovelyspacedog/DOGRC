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

    local result=$((yay_fail * 100 + flatpak_fail * 10 + topgrade_fail))
    return $result
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update "$@"
    exit $?
fi


#!/bin/bash
# Sourcing Guard - check if drcversion function already exists
if declare -f drcversion >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__INFORMATION_DIR:-}" ]] && readonly __INFORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__INFORMATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__INFORMATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__INFORMATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

drcversion() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp drcversion
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "drcversion" cat jq || {
        return $?
    }

    # Ensure __DOGRC_DIR is set
    [[ -z "${__DOGRC_DIR:-}" ]] && __DOGRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    # Check version.fake first (matches _UPDATE.sh behavior)
    local version_file="${__DOGRC_DIR}/config/version.fake"
    if [[ -f "$version_file" ]]; then
        local version=$(cat "$version_file" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$version" ]]; then
            local real_version=$(cat "${__DOGRC_DIR}/config/DOGRC.json" | jq -r '.version' 2>/dev/null || echo "unknown")
            echo "DOGRC Version $version (spoofed, real version: $real_version)"
            return 0
        fi
    fi
    
    # Fall back to DOGRC.json
    local real_version=$(cat "${__DOGRC_DIR}/config/DOGRC.json" | jq -r '.version' 2>/dev/null || echo "unknown")
    echo "DOGRC Version $real_version"
    
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    drcversion "$@"
    exit $?
fi
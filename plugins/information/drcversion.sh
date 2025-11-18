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
    ensure_commands_present --caller "drcversion" cat jq || {
        return $?
    }

    # Ensure __DOGRC_DIR and __CORE_DIR are set
    [[ -z "${__DOGRC_DIR:-}" ]] && __DOGRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    [[ -z "${__CORE_DIR:-}" ]] && __CORE_DIR="$(cd "${__DOGRC_DIR}/core" && pwd)"

    real_version=$(cat "${__DOGRC_DIR}/config/DOGRC.json" | jq -r '.version')
    
    if [[ -f "${__CORE_DIR}/version.fake" ]]; then
        spoofed_version=$(cat "${__CORE_DIR}/version.fake")
        echo "DOGRC Version $spoofed_version (spoofed, real version: $real_version)"
    else
        echo "DOGRC Version $real_version"
    fi
    
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    drcversion "$@"
    exit $?
fi
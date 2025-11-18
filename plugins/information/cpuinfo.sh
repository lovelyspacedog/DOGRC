#!/bin/bash
# Sourcing Guard - check if cpuinfo function already exists
if declare -f cpuinfo >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__INFORMATION_DIR:-}" ]] && readonly __INFORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__INFORMATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__INFORMATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__INFORMATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

cpuinfo() {
    ensure_commands_present --caller "cpuinfo" top grep awk cut ps head || {
        return $?
    }

    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    printf "\nTop CPU Processes:\n"
    ps aux --sort=-%cpu | head -10
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cpuinfo "$@"
    exit $?
fi
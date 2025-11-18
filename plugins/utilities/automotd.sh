#!/bin/bash

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

ensure_commands_present --caller "automotd" fortune jq || {
    return $? || exit $?
}

[ -f $HOME/motd.time ] || {
    printf "%s" "0" > $HOME/motd.time
}

motd_time=$(cat $HOME/motd.time)

# If the difference between current time and motd_time is greater than 1 day, then update motd_time
if [[ $(( $(date +%s) - motd_time )) -gt 86400 ]]; then
    motd_time=$(date +%s)
    printf "%s" "$motd_time" > $HOME/motd.time

    if [[ ! -f $HOME/motd.txt ]]; then
        cat <<EOF > $HOME/motd.txt
🥠 $(fortune)
--------------------------------
Type motd shoo to remove the message of the day file.
EOF
    fi
fi


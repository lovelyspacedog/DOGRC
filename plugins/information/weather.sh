#!/bin/bash
# Sourcing Guard - check if wttr or weather function already exists
if declare -f wttr >/dev/null 2>&1 || declare -f weather >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__INFORMATION_DIR:-}" ]] && readonly __INFORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__INFORMATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__INFORMATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__INFORMATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# Set default weather parameters if not already set
if [[ -z "$WTTR_PARAMS" ]]; then
    # Form localized URL parameters for curl
    if [[ -t 1 ]] && [[ "$(tput cols)" -lt 125 ]]; then
        WTTR_PARAMS+='n'
    fi 2>/dev/null
    
    for _token in $(locale LC_MEASUREMENT 2>/dev/null); do
        case $_token in
            1) WTTR_PARAMS+='m' ;;
            2) WTTR_PARAMS+='u' ;;
        esac
    done 2>/dev/null
    
    unset _token
    export WTTR_PARAMS
fi

# Wttr module
wttr() {
    ensure_commands_present --caller "wttr" curl || {
        return $?
    }

    local location="${1// /+}"
    test "$#" -gt 0 && shift
    local args=()

    for p in $WTTR_PARAMS "$@"; do
        args+=("--data-urlencode" "$p")
    done

    curl -fGsS -H "Accept-Language: ${LANG%_*}" "${args[@]}" --compressed "wttr.in/$location"
}

weather() {
    ensure_commands_present --caller "weather" curl head || {
        return $?
    }

    if [[ "${1^^}" == "HELP" ]]; then
        echo "Usage: weather [mode] [flags] [location...]"
        echo ""
        echo "Display weather information for the current location"
        echo "or a specified location. The current location is detected"
        echo "automatically using ipinfo.io."
        echo ""
        echo "Modes: (none)      Display both current weather and 3-day forecast"
        echo "        current     Show only current weather"
        echo "        forecast    Show only 3-day forecast"
        echo "        help        Show this help message"
        echo ""
        echo "Flags: --location/-l, --wttr/-w"
        echo ""
        echo "Examples:"
        echo "  weather current"
        echo "  weather forecast"
        echo "  weather current --wttr \"Orlando\" n"
        echo "  weather --location \"New York\""
        return 0
    fi

    local mode=""
    local wttr_args=()
    local use_custom_location=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --location|-l|--wttr|-w)
                shift
                use_custom_location=true
                # Collect all remaining arguments for wttr
                while [[ $# -gt 0 ]]; do
                    wttr_args+=("$1")
                    shift
                done
                break
                ;;
            current|CURRENT)
                mode="current"
                shift
                ;;
            forecast|FORECAST)
                mode="forecast"
                shift
                ;;
            help|HELP)
                weather help
                return 0
                ;;
            *)
                # Unknown argument, treat as mode if mode not set
                if [[ -z "$mode" ]]; then
                    mode="$1"
                fi
                shift
                ;;
        esac
    done

    local city
    if [[ "$use_custom_location" == true ]]; then
        # Use provided location arguments
        if [[ ${#wttr_args[@]} -eq 0 ]]; then
            echo "Error: No location provided after --location/--wttr flag" >&2
            return 1
        fi
        city="${wttr_args[0]}"
    else
        # Auto-detect location
        city=$(curl -s ipinfo.io/city 2>/dev/null)
        [[ -z "$city" ]] && {
            echo "Error: Could not detect location" >&2
            return 1
        }
    fi

    case "${mode^^}" in
    "CURRENT")
        echo -e "\n\033[36m🌤️  CURRENT WEATHER\033[0m"
        echo "=================="
        if [[ "$use_custom_location" == true ]]; then
            wttr "${wttr_args[@]}"
        else
            curl -s "wttr.in/$city?format=3"
        fi
        return 0
        ;;
    "FORECAST")
        echo -e "\n\033[36m📅 3-DAY FORECAST\033[0m"
        echo "=================="
        if [[ "$use_custom_location" == true ]]; then
            wttr "${wttr_args[@]}"
        else
            wttr "$city"
        fi
        return 0
        ;;
    "HELP")
        weather help
        return 0
        ;;
    *)
        echo -e "\n\033[36m🌤️  WEATHER FOR $city\033[0m"
        echo "========================"
        echo ""
        echo -e "\033[33m📍 Current Weather:\033[0m"
        if [[ "$use_custom_location" == true ]]; then
            wttr "${wttr_args[@]}"
        else
            curl -s "wttr.in/$city?format=3" | head -3
            echo ""
            echo -e "\033[33m📅 3-Day Forecast:\033[0m"
            wttr "$city"
        fi
        return 0
        ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    weather "$@"
    exit $?
fi


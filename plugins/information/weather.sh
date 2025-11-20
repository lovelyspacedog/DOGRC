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
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp wttr
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
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
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp weather
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "weather" curl head || {
        return $?
    }

    # Show help if no argument provided
    if [[ -z "$1" ]]; then
        echo "Usage: weather [mode] [flags] [location...]" >&2
        echo "" >&2
        echo "Display weather information for the current location" >&2
        echo "or a specified location. The current location is detected" >&2
        echo "automatically using ipinfo.io." >&2
        echo "" >&2
        echo "Modes: (none)      Display both current weather and 3-day forecast" >&2
        echo "        current     Show only current weather" >&2
        echo "        forecast    Show only 3-day forecast" >&2
        echo "        help        Show this help message" >&2
        echo "" >&2
        echo "Flags: --location/-l, --wttr/-w" >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  weather current" >&2
        echo "  weather forecast" >&2
        echo "  weather current --wttr \"Orlando\" n" >&2
        echo "  weather --location \"New York\"" >&2
        return 1
    fi

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
            wttr "${wttr_args[@]}" 2>/dev/null || true
        else
            curl -s "wttr.in/$city?format=3" 2>/dev/null || true
        fi
        return 0
        ;;
    "FORECAST")
        echo -e "\n\033[36m📅 3-DAY FORECAST\033[0m"
        echo "=================="
        if [[ "$use_custom_location" == true ]]; then
            wttr "${wttr_args[@]}" 2>/dev/null || true
        else
            wttr "$city" 2>/dev/null || true
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
            wttr "${wttr_args[@]}" 2>/dev/null || true
        else
            curl -s "wttr.in/$city?format=3" 2>/dev/null | head -3 || true
            echo ""
            echo -e "\033[33m📅 3-Day Forecast:\033[0m"
            wttr "$city" 2>/dev/null || true
        fi
        return 0
        ;;
    esac
}

# Bash completion function for weather
_weather_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Major cities for completion (includes more USA cities)
    local major_cities=(
        # USA cities
        "New York" "Los Angeles" "Chicago" "Houston" "Phoenix"
        "Philadelphia" "San Antonio" "San Diego" "Dallas" "San Jose"
        "Austin" "Jacksonville" "San Francisco" "Indianapolis" "Columbus"
        "Fort Worth" "Charlotte" "Seattle" "Denver" "Washington"
        "Boston" "El Paso" "Detroit" "Nashville" "Portland"
        "Oklahoma City" "Las Vegas" "Memphis" "Louisville" "Baltimore"
        "Milwaukee" "Albuquerque" "Tucson" "Fresno" "Sacramento" "Orlando"
        # International cities
        "London" "Tokyo" "Paris" "Sydney" "Berlin"
        "Moscow" "Dubai" "Singapore" "Toronto" "Mumbai"
        "Barcelona" "Rome" "Amsterdam" "Hong Kong" "Seoul"
        "Bangkok" "Istanbul"
    )

    # Check if we're completing after a location flag
    local has_location_flag=false
    local i
    for ((i=1; i < cword; i++)); do
        if [[ "${words[i]}" == "--location" ]] || [[ "${words[i]}" == "-l" ]] || \
           [[ "${words[i]}" == "--wttr" ]] || [[ "${words[i]}" == "-w" ]]; then
            has_location_flag=true
            break
        fi
    done

    # If we have a location flag, complete with city names
    if [[ "$has_location_flag" == "true" ]]; then
        local city_completions=()
        local city
        for city in "${major_cities[@]}"; do
            # Case-insensitive matching
            if [[ -z "$cur" ]] || [[ "${city,,}" == "${cur,,}"* ]]; then
                city_completions+=("$city")
            fi
        done
        COMPREPLY=("${city_completions[@]}")
        return 0
    fi

    # Check if current word starts with a dash (flag)
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--help -h --location -l --wttr -w" -- "$cur"))
        return 0
    fi

    # Check if previous word is a mode or flag
    if [[ "$prev" == "current" ]] || [[ "$prev" == "forecast" ]] || \
       [[ "$prev" == "help" ]] || [[ "$prev" == "--location" ]] || \
       [[ "$prev" == "-l" ]] || [[ "$prev" == "--wttr" ]] || \
       [[ "$prev" == "-w" ]]; then
        # If previous was a flag, complete with cities
        if [[ "$prev" == "--location" ]] || [[ "$prev" == "-l" ]] || \
           [[ "$prev" == "--wttr" ]] || [[ "$prev" == "-w" ]]; then
            local city_completions=()
            local city
            for city in "${major_cities[@]}"; do
                if [[ -z "$cur" ]] || [[ "${city,,}" == "${cur,,}"* ]]; then
                    city_completions+=("$city")
                fi
            done
            COMPREPLY=("${city_completions[@]}")
            return 0
        fi
        # Otherwise, no completion needed
        return 0
    fi

    # Default: complete with modes and flags only (not cities directly)
    local mode_completions=()
    local flag_completions=()

    # Complete modes
    local cur_lower="${cur,,}"
    if [[ -z "$cur" ]] || [[ "current" == "$cur_lower"* ]]; then
        mode_completions+=("current")
    fi
    if [[ -z "$cur" ]] || [[ "forecast" == "$cur_lower"* ]]; then
        mode_completions+=("forecast")
    fi
    if [[ -z "$cur" ]] || [[ "help" == "$cur_lower"* ]]; then
        mode_completions+=("help")
    fi

    # Complete flags
    if [[ "$cur" == -* ]]; then
        flag_completions=($(compgen -W "--help -h --location -l --wttr -w" -- "$cur"))
    fi

    COMPREPLY=("${mode_completions[@]}" "${flag_completions[@]}")
    return 0
}

# Bash completion function for wttr
_wttr_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Major cities for completion (includes more USA cities)
    local major_cities=(
        # USA cities
        "New York" "Los Angeles" "Chicago" "Houston" "Phoenix"
        "Philadelphia" "San Antonio" "San Diego" "Dallas" "San Jose"
        "Austin" "Jacksonville" "San Francisco" "Indianapolis" "Columbus"
        "Fort Worth" "Charlotte" "Seattle" "Denver" "Washington"
        "Boston" "El Paso" "Detroit" "Nashville" "Portland"
        "Oklahoma City" "Las Vegas" "Memphis" "Louisville" "Baltimore"
        "Milwaukee" "Albuquerque" "Tucson" "Fresno" "Sacramento" "Orlando"
        # International cities
        "London" "Tokyo" "Paris" "Sydney" "Berlin"
        "Moscow" "Dubai" "Singapore" "Toronto" "Mumbai"
        "Barcelona" "Rome" "Amsterdam" "Hong Kong" "Seoul"
        "Bangkok" "Istanbul"
    )

    # If current word starts with a dash, complete with help flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
        return 0
    fi

    # Complete with city names
    local city_completions=()
    local city
    for city in "${major_cities[@]}"; do
        # Case-insensitive matching
        if [[ -z "$cur" ]] || [[ "${city,,}" == "${cur,,}"* ]]; then
            city_completions+=("$city")
        fi
    done
    COMPREPLY=("${city_completions[@]}")
    return 0
}

# Register the completion functions
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _weather_completion weather 2>/dev/null || true
        complete -F _wttr_completion wttr 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    weather "$@"
    exit $?
fi


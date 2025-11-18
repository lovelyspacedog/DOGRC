#!/bin/bash
# Sourcing Guard - check if drcfortune function already exists
if declare -f drcfortune >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__INFORMATION_DIR:-}" ]] && readonly __INFORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__INFORMATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__INFORMATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__INFORMATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

drcfortune() {
    if ! ensure_commands_present --caller "drcfortune" fortune tput head; then
        return 123
    fi
    
    # Default typewriter effect speeds (in seconds per character)
    local default_title_speed=0.1    # Default speed for title typewriter effect
    local default_fortune_speed=0.01 # Default speed for fortune text typewriter effect
    
    # Parse arguments for --zero, --custom, --clear, --upper, --lower, and --no-a flags
    local zero_flag=false
    local custom_flag=false
    local clear_flag=false
    local upper_flag=false
    local lower_flag=false
    local no_a_flag=false
    local custom_title=""
    local custom_fortune=""
    local fortune_args=()
    local i=1
    local arg_count=$#
    
    while [[ $i -le $arg_count ]]; do
        local arg="${!i}"
        if [[ "$arg" == "--zero" ]]; then
            zero_flag=true
            ((i++))
        elif [[ "$arg" == "--clear" ]]; then
            clear_flag=true
            ((i++))
        elif [[ "$arg" == "--upper" ]]; then
            upper_flag=true
            ((i++))
        elif [[ "$arg" == "--lower" ]]; then
            lower_flag=true
            ((i++))
        elif [[ "$arg" == "--no-a" ]]; then
            no_a_flag=true
            ((i++))
        elif [[ "$arg" == "--custom" ]]; then
            custom_flag=true
            # Check if we have at least two more arguments
            if [[ $((i + 2)) -gt $arg_count ]]; then
                echo "Error: --custom requires two arguments (title_speed fortune_speed)" >&2
                return 1
            fi
            local next_idx=$((i + 1))
            local next_next_idx=$((i + 2))
            local custom_title_speed="${!next_idx}"
            local custom_fortune_speed="${!next_next_idx}"
            
            # Validate arguments: must be either "-" (use default) or positive floating point numbers
            # Pattern matches: digits optionally followed by decimal point and more digits,
            # or decimal point followed by digits (e.g., 0.5, 1.0, 0.01, 5, etc.)
            local float_pattern='^[0-9]+(\.[0-9]+)?$|^[0-9]*\.[0-9]+$'
            
            # Validate title_speed: must be "-" or a positive float
            if [[ "$custom_title_speed" != "-" ]] && [[ ! "$custom_title_speed" =~ $float_pattern ]]; then
                echo "Error: --custom title_speed must be '-' (use default) or a positive floating point number" >&2
                return 1
            fi
            
            # Validate fortune_speed: must be "-" or a positive float
            if [[ "$custom_fortune_speed" != "-" ]] && [[ ! "$custom_fortune_speed" =~ $float_pattern ]]; then
                echo "Error: --custom fortune_speed must be '-' (use default) or a positive floating point number" >&2
                return 1
            fi
            
            # Store the custom speeds (will be used later, "-" means use default)
            custom_title="$custom_title_speed"
            custom_fortune="$custom_fortune_speed"
            ((i += 3))  # Skip --custom and its two arguments
        else
            fortune_args+=("$arg")
            ((i++))
        fi
    done
    
    # Typewriter effect speeds (in seconds per character)
    local title_speed="$default_title_speed"    # Speed for title typewriter effect
    local fortune_speed="$default_fortune_speed" # Speed for fortune text typewriter effect
    
    # If --custom flag is set, use custom speeds (takes precedence over --zero)
    if [[ "$custom_flag" == true ]]; then
        # Echo expanded command if dashes were used
        if [[ "$custom_title" == "-" ]] || [[ "$custom_fortune" == "-" ]]; then
            local expanded_title="$custom_title"
            local expanded_fortune="$custom_fortune"
            [[ "$custom_title" == "-" ]] && expanded_title="$default_title_speed"
            [[ "$custom_fortune" == "-" ]] && expanded_fortune="$default_fortune_speed"
            local expanded_cmd="drcfortune --custom $expanded_title $expanded_fortune"
            if [[ ${#fortune_args[@]} -gt 0 ]]; then
                expanded_cmd="$expanded_cmd ${fortune_args[*]}"
            fi
            echo "$expanded_cmd" >&2
        fi
        
        # Use custom value or default if "-" is specified
        if [[ "$custom_title" != "-" ]]; then
            title_speed="$custom_title"
        fi
        if [[ "$custom_fortune" != "-" ]]; then
            fortune_speed="$custom_fortune"
        fi
    # If --zero flag is set, disable typewriter effect
    elif [[ "$zero_flag" == true ]]; then
        title_speed=0
        fortune_speed=0
    fi
    
    local fortune_output
    # Build fortune command: include -a unless --no-a flag is set
    local fortune_cmd_args=()
    [[ "$no_a_flag" != true ]] && fortune_cmd_args+=(-a)
    fortune_cmd_args+=(-c)
    fortune_output="$(fortune "${fortune_cmd_args[@]}" "${fortune_args[@]}")"
    
    # Separate title from fortune text (fortune cookies use "%" on its own line as separator)
    local title fortune_text
    # Check if output contains a "%" on its own line (standard fortune cookie separator)
    if [[ "$fortune_output" == *$'\n'%$'\n'* ]]; then
        # Split on "%" separator (on its own line)
        title="${fortune_output%%$'\n'%$'\n'*}"
        fortune_text="${fortune_output#*$'\n'%$'\n'}"
    elif [[ "$fortune_output" == *$'\n'---$'\n'* ]]; then
        # Split on "---" separator
        title="${fortune_output%%$'\n'---$'\n'*}"
        fortune_text="${fortune_output#*$'\n'---$'\n'}"
    else
        # No separator found, treat entire output as fortune text
        fortune_text="$fortune_output"
        title=""
    fi
    
    # Trim trailing whitespace from title and leading/trailing from fortune_text
    title="${title%"${title##*[![:space:]]}"}"
    fortune_text="${fortune_text#"${fortune_text%%[![:space:]]*}"}"
    fortune_text="${fortune_text%"${fortune_text##*[![:space:]]}"}"
    
    # Check for conflicting case flags
    if [[ "$upper_flag" == true ]] && [[ "$lower_flag" == true ]]; then
        echo "Error: --upper and --lower flags cannot be used together" >&2
        return 1
    fi
    
    # Apply case transformation to fortune text if flags are set
    if [[ "$upper_flag" == true ]]; then
        fortune_text="${fortune_text^^}"  # Convert to uppercase
    elif [[ "$lower_flag" == true ]]; then
        fortune_text="${fortune_text,,}"  # Convert to lowercase
    fi
    
    # Process title: remove parentheses, convert to all caps, and extract cookie name from path
    if [[ -n "$title" ]]; then
        title="${title//[()]/}"  # Remove all parentheses
        title="${title^^}"        # Convert to uppercase
        # If title contains a path separator, extract only the cookie name (basename)
        if [[ "$title" == */* ]]; then
            title="${title##*/}"  # Extract everything after the last '/'
        fi
    fi
    
    # Clear terminal if --clear flag is set
    if [[ "$clear_flag" == true ]]; then
        clear || printf '\033[2J\033[H'  # ANSI escape sequence: clear screen and move cursor to top-left
    fi
    
    # Display title in bold blue with typewriter effect (slower speed)
    if [[ -n "$title" ]]; then
        printf '🐾 '  # Dog paw emoji before title
        printf '\e[1;34m'  # Start bold blue
        local i
        local len="${#title}"
        for ((i=0; i<len; i++)); do
            printf '%s' "${title:$i:1}"
            sleep "$title_speed"
        done
        printf '\e[0m\n'  # Reset color and add newlines
    fi
    
    # Typewriter effect: print each character of fortune text with a small delay
    if [[ -n "$fortune_text" ]]; then
        local i
        local len="${#fortune_text}"
        for ((i=0; i<len; i++)); do
            printf '%s' "${fortune_text:$i:1}"
            sleep "$fortune_speed"
        done
        
        # Ensure final newline if fortune doesn't end with one
        [[ "${fortune_text: -1}" != $'\n' ]] && printf '\n'
    fi
    
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    drcfortune "$@"
    exit $?
fi


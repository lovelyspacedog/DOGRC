#!/bin/bash
# Sourcing Guard - check if url-shortener function already exists
if declare -f url-shortener >/dev/null 2>&1; then
    # If url-shortener exists, also define shorturl if it doesn't exist
    if ! declare -f shorturl >/dev/null 2>&1; then
        shorturl() {
            url-shortener "$@"
        }
    fi
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

url-shortener() {
    # Handle help flags (case-insensitive)
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp url-shortener
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "url-shortener" curl || {
        return $?
    }
    
    local url=""
    local service="is.gd"
    local show_service=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --service|-s)
                if [[ -n "${2:-}" ]]; then
                    service="$2"
                    shift 2
                else
                    echo "Error: --service requires a service name" >&2
                    return 1
                fi
                ;;
            --show-service)
                show_service=true
                shift
                ;;
            --)
                shift
                if [[ -n "${1:-}" ]]; then
                    url="$1"
                fi
                break
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                return 1
                ;;
            *)
                # First non-flag argument is the URL
                if [[ -z "$url" ]]; then
                    url="$1"
                else
                    echo "Error: Multiple URLs provided. Only one URL is supported." >&2
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate URL is provided
    if [[ -z "$url" ]]; then
        echo "Error: URL is required" >&2
        echo "Usage: url-shortener <url> [OPTIONS]" >&2
        echo "       url-shortener --help for more information" >&2
        return 1
    fi
    
    # Validate URL format (basic check)
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "Error: URL must start with http:// or https://" >&2
        return 1
    fi
    
    # Normalize service name to lowercase
    service="${service,,}"
    
    # Function to shorten URL using is.gd
    shorten_isgd() {
        local long_url="$1"
        local short_url
        
        # is.gd API: https://is.gd/create.php?format=json&url=<url>
        # Use --data-urlencode to properly encode the URL
        short_url=$(curl -s -G --data-urlencode "url=${long_url}" "https://is.gd/create.php?format=json" 2>/dev/null)
        
        if [[ -z "$short_url" ]]; then
            echo "Error: Failed to shorten URL with is.gd" >&2
            return 1
        fi
        
        # Check if response is JSON (success) or plain text (error)
        if [[ "$short_url" =~ ^\{ ]]; then
            # JSON response - extract shorturl field
            if command -v jq >/dev/null 2>&1; then
                local result=$(echo "$short_url" | jq -r '.shorturl // empty' 2>/dev/null)
                if [[ -n "$result" ]] && [[ "$result" != "null" ]]; then
                    echo "$result"
                    return 0
                fi
                # Check for error
                local error=$(echo "$short_url" | jq -r '.errormessage // empty' 2>/dev/null)
                if [[ -n "$error" ]] && [[ "$error" != "null" ]]; then
                    echo "Error: is.gd returned: $error" >&2
                    return 1
                fi
            else
                # Fallback: try to extract URL from JSON manually
                local result=$(echo "$short_url" | grep -o '"shorturl":"[^"]*"' | cut -d'"' -f4)
                if [[ -n "$result" ]]; then
                    echo "$result"
                    return 0
                fi
            fi
        else
            # Plain text response (usually an error message)
            echo "Error: is.gd returned: $short_url" >&2
            return 1
        fi
        
        echo "Error: Failed to parse response from is.gd" >&2
        return 1
    }
    
    # Function to shorten URL using tinyurl
    shorten_tinyurl() {
        local long_url="$1"
        local short_url
        
        # tinyurl.com API: https://tinyurl.com/api-create.php?url=<url>
        # Use --data-urlencode to properly encode the URL
        short_url=$(curl -s -G --data-urlencode "url=${long_url}" "https://tinyurl.com/api-create.php" 2>/dev/null)
        
        if [[ -z "$short_url" ]]; then
            echo "Error: Failed to shorten URL with tinyurl" >&2
            return 1
        fi
        
        # tinyurl returns the shortened URL directly, or an error message
        if [[ "$short_url" =~ ^https?:// ]]; then
            echo "$short_url"
            return 0
        else
            echo "Error: tinyurl returned: $short_url" >&2
            return 1
        fi
    }
    
    # Shorten the URL based on selected service
    local result=""
    local service_name=""
    
    case "$service" in
        is.gd|isgd)
            service_name="is.gd"
            result=$(shorten_isgd "$url")
            ;;
        tinyurl|tiny)
            service_name="tinyurl.com"
            result=$(shorten_tinyurl "$url")
            ;;
        *)
            echo "Error: Unknown service '$service'" >&2
            echo "Supported services: is.gd, tinyurl" >&2
            return 1
            ;;
    esac
    
    # Check if shortening was successful
    if [[ $? -ne 0 ]] || [[ -z "$result" ]]; then
        return 1
    fi
    
    # Display result
    if [[ "$show_service" == true ]]; then
        echo "$result ($service_name)"
    else
        echo "$result"
    fi
    
    # Copy to clipboard if available (optional feature)
    if command -v wl-copy >/dev/null 2>&1; then
        echo "$result" | wl-copy 2>/dev/null && echo "(Copied to clipboard)" >&2
    elif command -v xclip >/dev/null 2>&1; then
        echo "$result" | xclip -selection clipboard 2>/dev/null && echo "(Copied to clipboard)" >&2
    elif command -v pbcopy >/dev/null 2>&1; then
        echo "$result" | pbcopy 2>/dev/null && echo "(Copied to clipboard)" >&2
    fi
    
    return 0
}

# Alias function for convenience
shorturl() {
    url-shortener "$@"
}

# Tab completion function
_url_shortener_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # If current word starts with dash, complete with flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--service -s --show-service --help -h --" -- "$cur"))
        return 0
    fi
    
    # If previous word is --service, complete with service names
    if [[ "$prev" == "--service" ]] || [[ "$prev" == "-s" ]]; then
        COMPREPLY=($(compgen -W "is.gd tinyurl" -- "$cur"))
        return 0
    fi
    
    # Otherwise, no completion
    COMPREPLY=()
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _url_shortener_completion url-shortener 2>/dev/null || true
        complete -F _url_shortener_completion shorturl 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    url-shortener "$@"
    exit $?
fi


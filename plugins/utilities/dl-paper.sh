#!/bin/bash
# Sourcing Guard - check if dl-paper function already exists
if declare -f dl-paper >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# List formats or download a wallpaper clip with yt-dlp
dl-paper() {
    local all_args=("$@")
    
    [[ ${#all_args[@]} -eq 0 ]] && return 1

    # Check if any argument is "down"/"d"/"-" (download mode trigger)
    local download_mode=false
    local download_trigger=""
    local filtered_args=()
    
    for arg in "${all_args[@]}"; do
        if [[ "${arg^^}" == "DOWN" || "${arg^^}" == "D" || "$arg" == "-" ]]; then
            download_mode=true
            download_trigger="$arg"
            # Don't add the trigger to filtered_args
        else
            filtered_args+=("$arg")
        fi
    done

    [[ "$download_mode" == true ]] && {
        ensure_commands_present --caller "dl-paper" yt-dlp ffmpeg || {
            return $?
        }

        local cookies_file=""
        local format=""
        local url=""

        # Parse filtered arguments (download trigger already removed)
        local i=0
        while [[ $i -lt ${#filtered_args[@]} ]]; do
            case "${filtered_args[i]}" in
                --cookies)
                    if [[ $((i + 1)) -ge ${#filtered_args[@]} ]]; then
                        echo "Error: --cookies requires a file path" >&2
                        return 1
                    fi
                    cookies_file="${filtered_args[i+1]}"
                    ((i += 2))
                    ;;
                *)
                    # Treat non-flag arguments as format or URL
                    if [[ -z "$format" ]]; then
                        format="${filtered_args[i]}"
                    elif [[ -z "$url" ]]; then
                        url="${filtered_args[i]}"
                    else
                        echo "Error: Too many arguments" >&2
                        return 1
                    fi
                    ((i++))
                    ;;
            esac
        done

        if [[ -z "$format" ]] || [[ -z "$url" ]]; then
            echo "Error: Format and URL are required for download mode" >&2
            echo "Usage: dl-paper down [--cookies <file>] <format> <url>" >&2
            return 1
        fi

        # Build yt-dlp command
        local ytdlp_cmd=(
            yt-dlp
            --downloader ffmpeg
            --downloader-args "ffmpeg_i:-ss 60 -to 300 -an"
        )

        ytdlp_cmd+=(-f "$format")

        # Add cookies if provided
        [[ -n "$cookies_file" ]] && {
            ytdlp_cmd+=(--cookies "$cookies_file")
        }

        ytdlp_cmd+=("$url")

        "${ytdlp_cmd[@]}"
        return $?
    }

    ensure_commands_present --caller "dl-paper" yt-dlp || {
        return $?
    }

    # Format listing mode - parse arguments for cookies support
    local url=""
    local cookies_file=""

    # Parse filtered arguments (download trigger already removed if it existed)
    local i=0
    while [[ $i -lt ${#filtered_args[@]} ]]; do
        case "${filtered_args[i]}" in
            --cookies)
                if [[ $((i + 1)) -ge ${#filtered_args[@]} ]]; then
                    echo "Error: --cookies requires a file path" >&2
                    return 1
                fi
                cookies_file="${filtered_args[i+1]}"
                ((i += 2))
                ;;
            *)
                # Treat non-flag arguments as URL (use first one found)
                if [[ -z "$url" ]]; then
                    url="${filtered_args[i]}"
                fi
                ((i++))
                ;;
        esac
    done

    if [[ -z "$url" ]]; then
        echo "Error: URL is required" >&2
        return 1
    fi

    # Build yt-dlp command for format listing
    local ytdlp_cmd=(
        yt-dlp
        -F
    )

    # Add cookies if provided
    [[ -n "$cookies_file" ]] && {
        ytdlp_cmd+=(--cookies "$cookies_file")
    }

    ytdlp_cmd+=("$url")

    "${ytdlp_cmd[@]}"
    return $?
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    dl-paper "$@"
    exit $?
fi


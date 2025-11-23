#!/bin/bash
# Sourcing Guard - check if disk-usage function already exists
if declare -f disk-usage >/dev/null 2>&1 || declare -f diskusage >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__INFORMATION_DIR:-}" ]] && readonly __INFORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__INFORMATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__INFORMATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__INFORMATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

disk-usage() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp disk-usage
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi

    ensure_commands_present --caller "disk-usage" du sort || {
        return $?
    }

    local target_dir="."
    local top_count=0
    local clean_mode=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --top|-t)
                if [[ -n "${2:-}" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                    top_count="$2"
                    shift 2
                else
                    echo "Error: --top requires a numeric argument" >&2
                    return 1
                fi
                ;;
            --clean|-c)
                clean_mode=true
                shift
                ;;
            --)
                shift
                if [[ -n "${1:-}" ]]; then
                    target_dir="$1"
                fi
                break
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                return 1
                ;;
            *)
                # Check if it's a number (for --top shorthand)
                if [[ "$1" =~ ^[0-9]+$ ]] && [[ $top_count -eq 0 ]]; then
                    top_count="$1"
                else
                    target_dir="$1"
                fi
                shift
                ;;
        esac
    done

    # Validate target directory
    if [[ ! -d "$target_dir" ]]; then
        echo "Error: Directory '$target_dir' does not exist" >&2
        return 1
    fi

    # Get absolute path
    local abs_dir="$(cd "$target_dir" && pwd)"

    # Handle clean mode
    if [[ "$clean_mode" == true ]]; then
        echo -e "\033[36m🧹 CLEANUP SUGGESTIONS\033[0m"
        echo "===================="
        echo ""

        local total_cleanable=0
        local found_any=false

        # Common temp/cache locations
        local -a check_dirs=(
            "$HOME/.cache"
            "$HOME/.tmp"
            "$HOME/tmp"
            "/tmp"
            "/var/tmp"
            "$HOME/.local/share/Trash"
            "$HOME/.thumbnails"
            "$HOME/.npm"
            "$HOME/.yarn"
            "$HOME/.pip/cache"
            "$HOME/.m2/repository"
            "$HOME/.gradle/caches"
            "$HOME/.rustup"
            "$HOME/.cargo/registry"
            "$HOME/.go/pkg"
        )

        for check_dir in "${check_dirs[@]}"; do
            if [[ -d "$check_dir" ]]; then
                local dir_size
                dir_size=$(du -sh "$check_dir" 2>/dev/null | cut -f1)
                if [[ -n "$dir_size" ]] && [[ "$dir_size" != "0" ]]; then
                    local size_bytes
                    size_bytes=$(du -sb "$check_dir" 2>/dev/null | cut -f1)
                    if [[ -n "$size_bytes" ]] && [[ "$size_bytes" != "0" ]]; then
                        echo "  📁 $check_dir"
                        echo "     Size: $dir_size"
                        echo ""
                        found_any=true
                        # Add to total (approximate)
                        total_cleanable=$((total_cleanable + size_bytes))
                    fi
                fi
            fi
        done

        if [[ "$found_any" == false ]]; then
            echo "  No common temp/cache directories found with significant size."
            echo ""
        else
            # Convert total to human-readable
            local total_human
            if command -v numfmt >/dev/null 2>&1; then
                total_human=$(numfmt --to=iec-i --suffix=B "$total_cleanable" 2>/dev/null)
            elif command -v awk >/dev/null 2>&1; then
                total_human=$(echo "$total_cleanable" | awk '{
                    if ($1 >= 1073741824) printf "%.2fGiB", $1/1073741824
                    else if ($1 >= 1048576) printf "%.2fMiB", $1/1048576
                    else if ($1 >= 1024) printf "%.2fKiB", $1/1024
                    else printf "%dB", $1
                }')
            else
                total_human="$total_cleanable bytes"
            fi
            echo "  💡 Estimated total cleanable: ~$total_human"
            echo ""
            echo "  Note: Review these directories before deleting."
            echo "        Some may contain important cached data."
        fi

        return 0
    fi

    # Handle top N mode
    if [[ $top_count -gt 0 ]]; then
        echo -e "\033[36m📊 TOP $top_count LARGEST DIRECTORIES\033[0m"
        echo "======================================"
        echo "Directory: $abs_dir"
        echo ""

        # Use du to find largest directories
        du -h --max-depth=1 "$abs_dir" 2>/dev/null | \
            sort -rh | \
            head -n $((top_count + 1)) | \
            tail -n +2 | \
            nl -w2 -s'.  '

        return 0
    fi

    # Default mode: Show disk usage tree
    echo -e "\033[36m📊 DISK USAGE TREE\033[0m"
    echo "==================="
    echo "Directory: $abs_dir"
    echo ""

    # Check if tree command is available (optional dependency)
    if command -v tree >/dev/null 2>&1; then
        # Use tree with du integration if available
        if tree --version 2>/dev/null | grep -q "version"; then
            # Try to use tree with size display
            tree -h --du "$abs_dir" 2>/dev/null || \
            du -h --max-depth=2 "$abs_dir" 2>/dev/null | sort -h
        else
            du -h --max-depth=2 "$abs_dir" 2>/dev/null | sort -h
        fi
    else
        # Fallback to du with human-readable output
        du -h --max-depth=2 "$abs_dir" 2>/dev/null | sort -h
    fi

    return 0
}

# Alias for diskusage (no hyphen) for compatibility
diskusage() {
    disk-usage "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    disk-usage "$@"
    exit $?
fi


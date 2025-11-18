#!/bin/bash

# Sourcing Guard - check if backup function already exists
if declare -f backup >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

backup() {
    ensure_commands_present --caller "backup" cp date basename mkdir || {
        return $?
    }

    local store_backup=false
    local backup_directory=false
    local file_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --store|-s)
                store_backup=true
                shift
                ;;
            --directory|--dir|-d)
                backup_directory=true
                shift
                ;;
            --)
                shift
                file_path="$1"
                break
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                return 1
                ;;
            *)
                file_path="$1"
                shift
                ;;
        esac
    done

    local timestamp="$(date +%Y%m%d%H%M%S)"
    local backup_path

    if [[ "$backup_directory" == true ]]; then
        # Directory backup mode
        local current_dir="$(pwd)"
        local dir_name="$(basename "$current_dir")"
        local backup_dir_name="${dir_name}.bak.${timestamp}"

        if [[ "$store_backup" == true ]]; then
            local base_backup_dir="${HOME}/Documents/BAK"
            mkdir -p "$base_backup_dir" || {
                echo "Error: Failed to create backup directory $base_backup_dir" >&2
                return 3
            }
            backup_path="${base_backup_dir}/${backup_dir_name}"
        else
            backup_path="${current_dir}/${backup_dir_name}"
        fi

        mkdir -p "$backup_path" || {
            echo "Error: Failed to create backup directory $backup_path" >&2
            return 4
        }

        # Copy all files and subdirectories, preserving structure
        # Exclude the backup directory itself to avoid copying into itself
        local backup_basename="$(basename "$backup_path")"
        find . -mindepth 1 -maxdepth 1 ! -name "$backup_basename" -exec cp -r {} "$backup_path/" \; || {
            echo "Error: Failed to create backup of directory $current_dir" >&2
            return 5
        }

        echo "Backup created at $backup_path"
        return 0
    else
        # Single file backup mode
        [[ -f "$file_path" ]] || {
            echo "Error: $file_path is not a file or does not exist" >&2
            return 2
        }

        if [[ "$store_backup" == true ]]; then
            local base_backup_dir="${HOME}/Documents/BAK"
            mkdir -p "$base_backup_dir" || {
                echo "Error: Failed to create backup directory $base_backup_dir" >&2
                return 3
            }
            local filename="$(basename "$file_path")"
            backup_path="${base_backup_dir}/${filename}.bak.${timestamp}"
        else
            backup_path="${file_path}.bak.${timestamp}"
        fi

        cp "$file_path" "$backup_path" || {
            echo "Error: Failed to create backup of $file_path" >&2
            return 6
        }

        echo "Backup created at $backup_path"
        return 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup "$@"
    exit $?
fi
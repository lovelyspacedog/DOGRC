#!/bin/bash
# Sourcing Guard - check if sanitize-filenames function already exists
if declare -f sanitize-filenames >/dev/null 2>&1 || declare -f sanitize_filenames >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

sanitize-filenames() {
    # Handle help flags (case-insensitive) - delegate to drchelp
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp sanitize-filenames
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi

    ensure_commands_present --caller "sanitize-filenames" find mv || {
        return $?
    }

    # Color codes for output
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local NC='\033[0m' # No Color

    local target_path="."
    local dry_run=false
    local replace_spaces=false
    local processed_count=0
    local skipped_count=0
    local error_count=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run|-d)
                dry_run=true
                shift
                ;;
            --replace-spaces|-r)
                replace_spaces=true
                shift
                ;;
            --)
                shift
                if [[ -n "${1:-}" ]]; then
                    target_path="$1"
                fi
                break
                ;;
            -*)
                # Check if it's actually a file path starting with - (handle after option parsing)
                # If it exists as a file/directory, treat as path, not option
                if [[ -e "$1" ]]; then
                    target_path="$1"
                    shift
                else
                    echo "Error: Unknown option $1" >&2
                    return 1
                fi
                ;;
            *)
                target_path="$1"
                shift
                ;;
        esac
    done

    # Validate target path (handle default to current directory)
    if [[ -z "$target_path" ]] || [[ "$target_path" == "." ]]; then
        target_path="."
    fi
    
    # Check if path exists (handle paths starting with - by using ./ prefix)
    local check_path="$target_path"
    if [[ "$check_path" == -* ]]; then
        check_path="./$check_path"
    fi
    
    if [[ ! -e "$check_path" ]] && [[ ! -e "$target_path" ]]; then
        echo "Error: Path '$target_path' does not exist" >&2
        return 1
    fi

    # Function to sanitize a single filename
    sanitize_name() {
        local old_name="$1"
        local new_name="$old_name"
        local is_hidden=false
        
        # Check if it's a hidden file (starts with dot and has more than just dot)
        # Files with trailing dots (like ".file.txt.") are not treated as hidden
        # as they appear to be accidental dots rather than intentional hidden files
        if [[ "$new_name" == .* ]] && [[ ${#new_name} -gt 1 ]]; then
            # Check if it ends with a dot - if so, treat as non-hidden (remove both dots)
            if [[ "$new_name" == *. ]] && [[ "$new_name" != . ]] && [[ "$new_name" != .. ]]; then
                # Has both leading and trailing dot - not truly hidden, remove both
                is_hidden=false
                new_name="${new_name#.}"  # Remove leading dot
                new_name="${new_name%.}"  # Remove trailing dot
            elif [[ "$new_name" != . ]] && [[ "$new_name" != .. ]]; then
                # Only leading dot - truly hidden file
                is_hidden=true
                new_name="${new_name#.}"  # Remove leading dot temporarily
            fi
        fi
        
        # Replace spaces with underscores if flag is set
        if [[ "$replace_spaces" == true ]]; then
            new_name="${new_name// /_}"
        else
            # Normalize multiple spaces to single space
            while [[ "$new_name" =~ [[:space:]][[:space:]]+ ]]; do
                new_name="${new_name//  / }"
            done
        fi
        
        # Remove or replace special characters (keep alphanumeric, dots, hyphens, underscores, spaces)
        # Replace problematic characters with underscores
        new_name=$(echo "$new_name" | sed 's/[^a-zA-Z0-9._ -]/_/g')
        
        # Remove leading/trailing spaces, dots, and hyphens using sed
        new_name=$(echo "$new_name" | sed -e 's/^[[:space:]._-]*//' -e 's/[[:space:]._-]*$//')
        
        # Remove trailing hyphens/dots (but not underscores) before file extensions (e.g., file-.txt -> file.txt)
        # This preserves underscores that are part of the filename (e.g., file_name_.txt -> file_name_.txt)
        if [[ "$new_name" == *.* ]]; then
            # Has extension - remove trailing hyphens/dots/spaces (but not underscores) from the base name before the last dot
            local base="${new_name%.*}"
            local ext="${new_name##*.}"
            # Remove trailing hyphens/dots/spaces (but not underscores) from base
            base=$(echo "$base" | sed -e 's/[[:space:].-]*$//')
            # Reassemble if base is not empty
            if [[ -n "$base" ]] && [[ -n "$ext" ]]; then
                new_name="${base}.${ext}"
            elif [[ -n "$base" ]]; then
                new_name="$base"
            elif [[ -n "$ext" ]]; then
                new_name="$ext"
            fi
        fi
        
        # Replace multiple consecutive underscores/hyphens with single underscore
        while [[ "$new_name" == *__* ]] || [[ "$new_name" == *--* ]] || [[ "$new_name" == *_-* ]] || [[ "$new_name" == *-_* ]]; do
            new_name="${new_name//__/_}"
            new_name="${new_name//--/_}"
            new_name="${new_name//_-/_}"
            new_name="${new_name//-_/_}"
        done
        
        # Restore leading dot for hidden files (only if there's actual content after dot)
        if [[ "$is_hidden" == true ]]; then
            # Ensure hidden part is not empty and valid
            if [[ -n "$new_name" ]] && [[ "$new_name" != "." ]] && [[ "$new_name" != ".." ]]; then
                new_name=".$new_name"
            else
                # If hidden part is empty/invalid after sanitization, don't make it hidden
                # Use regular fallback name instead
                if [[ -z "$new_name" ]] || [[ "$new_name" == "." ]] || [[ "$new_name" == ".." ]]; then
                    new_name="sanitized_$(date +%s)_$$"
                fi
            fi
        fi
        
        # Ensure name is not empty after sanitization
        if [[ -z "$new_name" ]] || [[ "$new_name" == "." ]] || [[ "$new_name" == ".." ]]; then
            new_name="sanitized_$(date +%s)_$$"
        fi
        
        echo "$new_name"
    }

    # Function to sanitize a file or directory
    sanitize_item() {
        local item_path="$1"
        local item_dir
        local item_name
        local sanitized_name
        local new_path
        
        # Handle empty path (should not happen, but safety check)
        if [[ -z "$item_path" ]] || [[ "$item_path" == "." ]] || [[ "$item_path" == ".." ]]; then
            return 0
        fi
        
        # Use ./ prefix to prevent dirname/basename from interpreting - as option
        # Some systems don't support -- for dirname/basename, so always use ./ prefix for paths starting with -
        local safe_path="$item_path"
        # Check if path starts with - (more robust pattern matching)
        if [[ "${item_path:0:1}" == "-" ]] || [[ "$item_path" =~ ^- ]]; then
            # Path starts with -, use ./ prefix to prevent option parsing
            safe_path="./$item_path"
        fi
        
        item_dir="$(dirname "$safe_path" 2>/dev/null || echo ".")"
        item_name="$(basename "$safe_path" 2>/dev/null || echo "$item_path")"
        
        # Remove ./ prefix if it was added (dirname/basename might return paths with ./)
        item_dir="${item_dir#./}"
        item_name="${item_name#./}"
        
        # Safety check - if basename/dirname failed, skip
        if [[ -z "$item_name" ]] || [[ "$item_name" == "." ]] || [[ "$item_name" == ".." ]]; then
            return 0
        fi
        
        sanitized_name="$(sanitize_name "$item_name")"
        
        # Skip if name didn't change
        if [[ "$item_name" == "$sanitized_name" ]]; then
            ((skipped_count++))
            return 0
        fi
        
        new_path="$item_dir/$sanitized_name"
        
        # Check if target already exists
        if [[ -e "$new_path" ]]; then
            echo "  ${YELLOW}⚠${NC} Skip: '$item_name' -> '$sanitized_name' (target exists)" >&2
            ((skipped_count++))
            return 0
        fi
        
        if [[ "$dry_run" == true ]]; then
            echo "  ${BLUE}[DRY RUN]${NC} Would rename: '$item_name' -> '$sanitized_name'"
            ((processed_count++))
        else
            # Actually rename
            if mv -- "$item_path" "$new_path" 2>/dev/null; then
                echo "  ${GREEN}✓${NC} Renamed: '$item_name' -> '$sanitized_name'"
                ((processed_count++))
            else
                # Check if item still exists (might have been renamed by parent directory rename)
                if [[ ! -e "$item_path" ]] && [[ -e "$new_path" ]]; then
                    # Item was already renamed (probably by parent directory processing)
                    ((processed_count++))
                elif [[ -z "$item_name" ]]; then
                    # Skip empty filenames (shouldn't happen, but handle gracefully)
                    ((skipped_count++))
                else
                    echo "  ${RED}✗${NC} Failed to rename: '$item_name'" >&2
                    ((error_count++))
                    return 1
                fi
            fi
        fi
        
        return 0
    }

    # Determine if target is file or directory
    if [[ -f "$target_path" ]]; then
        # Single file mode
        echo -e "\033[36m🧹 SANITIZING FILENAMES\033[0m"
        echo "======================"
        echo "Mode: Single file"
        [[ "$dry_run" == true ]] && echo "Mode: DRY RUN (preview only)"
        [[ "$replace_spaces" == true ]] && echo "Mode: Replace spaces with underscores"
        echo ""
        
        sanitize_item "$target_path"
    elif [[ -d "$target_path" ]]; then
        # Directory mode - process all files recursively
        echo -e "\033[36m🧹 SANITIZING FILENAMES\033[0m"
        echo "======================"
        echo "Mode: Directory (recursive)"
        echo "Directory: $target_path"
        [[ "$dry_run" == true ]] && echo "Mode: DRY RUN (preview only)"
        [[ "$replace_spaces" == true ]] && echo "Mode: Replace spaces with underscores"
        echo ""
        
        # Find all files and directories, process them
        # Process files first (they don't have children, order doesn't matter)
        local files_found=false
        while IFS= read -r -d '' item; do
            if [[ -n "$item" ]]; then
                files_found=true
                sanitize_item "$item"
            fi
        done < <(find "$target_path" -type f -print0 2>/dev/null)
        
        # Now process directories from deepest to shallowest (to handle nested directories)
        # Collect all subdirectories first (exclude root), then sort by depth (deeper first)
        local -a dirs
        local root_dir_to_process=""
        local dirs_found=false
        while IFS= read -r -d '' item; do
            if [[ -z "$item" ]]; then
                continue
            fi
            dirs_found=true
            # Separate root directory from subdirectories
            if [[ "$item" == "$target_path" ]]; then
                # Store root directory to process last
                root_dir_to_process="$item"
            else
                dirs+=("$item")
            fi
        done < <(find "$target_path" -type d -print0 2>/dev/null)
        
        # Sort by depth (deeper first) - count path components as depth indicator
        # Use awk to count path separators and sort
        if command -v awk >/dev/null 2>&1 && command -v sort >/dev/null 2>&1; then
            local sorted_dirs
            mapfile -t sorted_dirs < <(printf '%s\n' "${dirs[@]}" | awk -F'/' '{print NF, $0}' | sort -rn | cut -d' ' -f2-)
            for item in "${sorted_dirs[@]}"; do
                sanitize_item "$item"
            done
        else
            # Fallback: process in any order (may cause issues with nested dirs)
            for item in "${dirs[@]}"; do
                sanitize_item "$item"
            done
        fi
        
        # Finally, process root directory itself if it's not "." (current directory)
        # Only sanitize the root directory name if it's not the current directory
        if [[ -n "$root_dir_to_process" ]] && [[ "$root_dir_to_process" != "." ]]; then
            # Get absolute paths for comparison
            local root_abs
            root_abs="$(cd "$root_dir_to_process" 2>/dev/null && pwd || echo "$root_dir_to_process")"
            local current_abs
            current_abs="$(pwd)"
            # Only process if it's not the current working directory
            if [[ "$root_abs" != "$current_abs" ]]; then
                sanitize_item "$root_dir_to_process"
            fi
        fi
    else
        echo "Error: '$target_path' is not a valid file or directory" >&2
        return 1
    fi
    
    # Summary
    echo ""
    if [[ "$dry_run" == true ]]; then
        echo "Summary:"
        echo "  Files that would be renamed: $processed_count"
        echo "  Files unchanged: $skipped_count"
        [[ $error_count -gt 0 ]] && echo "  Errors: $error_count"
    else
        echo "Summary:"
        echo "  Files renamed: $processed_count"
        echo "  Files unchanged: $skipped_count"
        [[ $error_count -gt 0 ]] && echo "  Errors: $error_count"
    fi
    
    # Return error code if there were any errors, even if some items were processed
    if [[ $error_count -gt 0 ]]; then
        return 1
    fi
    
    # Return success if no errors occurred
    return 0
}

# Alias for sanitize_filenames (with underscore) for compatibility
sanitize_filenames() {
    sanitize-filenames "$@"
}

# Quick alias for sanitize-filenames
fixnames() {
    sanitize-filenames "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    sanitize-filenames "$@"
    exit $?
fi


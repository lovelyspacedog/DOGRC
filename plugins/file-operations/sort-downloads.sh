#!/bin/bash
# Sourcing Guard - check if sort-downloads or sortdl function already exists
if declare -f sort-downloads >/dev/null 2>&1 || declare -f sortdl >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

sort-downloads() {
    # Handle help flags (case-insensitive)
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp sort-downloads
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    ensure_commands_present --caller "sort-downloads" find mkdir mv basename date file || {
        return $?
    }
    
    local downloads_dir="${HOME}/Downloads"
    local organize_by="extension"
    local dry_run=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --by-date|-d)
                organize_by="date"
                shift
                ;;
            --by-extension|-e)
                organize_by="extension"
                shift
                ;;
            --dry-run|-n)
                dry_run=true
                shift
                ;;
            --directory|--dir)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --directory requires a path argument" >&2
                    return 1
                fi
                downloads_dir="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                echo "Use --help or -h for usage information" >&2
                return 1
                ;;
            *)
                # Treat as directory path
                downloads_dir="$1"
                shift
                ;;
        esac
    done
    
    # Validate downloads directory
    if [[ ! -d "$downloads_dir" ]]; then
        echo "Error: Directory '$downloads_dir' does not exist" >&2
        return 2
    fi
    
    # Count files to organize
    local file_count=0
    while IFS= read -r -d '' file; do
        ((file_count++))
    done < <(find "$downloads_dir" -maxdepth 1 -type f -print0 2>/dev/null)
    
    if [[ $file_count -eq 0 ]]; then
        echo "No files found in $downloads_dir to organize."
        return 0
    fi
    
    echo "Found $file_count file(s) in $downloads_dir"
    
    if [[ "$dry_run" == true ]]; then
        echo "DRY RUN MODE - No files will be moved"
        echo ""
    fi
    
    local organized_count=0
    local skipped_count=0
    
    # Process each file
    while IFS= read -r -d '' file; do
        local filename=$(basename "$file")
        local target_dir=""
        
        if [[ "$organize_by" == "extension" ]]; then
            # Organize by file extension
            local ext="${filename##*.}"
            
            # Handle files without extension
            if [[ "$ext" == "$filename" ]]; then
                ext="no-extension"
            else
                ext="${ext,,}"  # Convert to lowercase
            fi
            
            target_dir="${downloads_dir}/${ext}"
        else
            # Organize by date (year-month)
            # Try Linux date command first, then BSD/macOS stat, fallback to unknown
            local file_date="unknown"
            if date -r "$file" +%Y-%m >/dev/null 2>&1; then
                # Linux
                file_date=$(date -r "$file" +%Y-%m 2>/dev/null)
            elif stat -f "%Sm" -t "%Y-%m" "$file" >/dev/null 2>&1; then
                # BSD/macOS
                file_date=$(stat -f "%Sm" -t "%Y-%m" "$file" 2>/dev/null)
            elif stat -c "%y" "$file" >/dev/null 2>&1; then
                # Linux stat (alternative)
                file_date=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1 | cut -d'-' -f1,2)
            fi
            target_dir="${downloads_dir}/${file_date}"
        fi
        
        # Create target directory if needed
        if [[ "$dry_run" == false ]]; then
            mkdir -p "$target_dir" || {
                echo "Error: Failed to create directory $target_dir" >&2
                ((skipped_count++))
                continue
            }
        fi
        
        # Move file to organized directory
        local target_file="${target_dir}/${filename}"
        
        # Check if target file already exists
        if [[ -e "$target_file" ]]; then
            # Generate unique filename
            local base_name="${filename%.*}"
            local ext_part="${filename##*.}"
            if [[ "$ext_part" == "$filename" ]]; then
                ext_part=""
            else
                ext_part=".${ext_part}"
            fi
            local counter=1
            while [[ -e "${target_dir}/${base_name}_${counter}${ext_part}" ]]; do
                ((counter++))
            done
            target_file="${target_dir}/${base_name}_${counter}${ext_part}"
        fi
        
        if [[ "$dry_run" == true ]]; then
            echo "Would move: $filename -> ${target_dir}/$(basename "$target_file")"
        else
            mv "$file" "$target_file" || {
                echo "Error: Failed to move $filename" >&2
                ((skipped_count++))
                continue
            }
        fi
        
        ((organized_count++))
    done < <(find "$downloads_dir" -maxdepth 1 -type f -print0 2>/dev/null)
    
    # Summary
    echo ""
    if [[ "$dry_run" == true ]]; then
        echo "Dry run complete: Would organize $organized_count file(s)"
    else
        echo "Organized $organized_count file(s)"
        if [[ $skipped_count -gt 0 ]]; then
            echo "Skipped $skipped_count file(s) due to errors"
        fi
    fi
    
    return 0
}

# Pass-through function: sortdl -> sort-downloads
sortdl() {
    sort-downloads "$@"
    return $?
}

# Bash completion function for sort-downloads
_sort-downloads_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    case "$prev" in
        --directory|--dir)
            # Complete directory paths
            COMPREPLY=($(compgen -d -- "$cur"))
            return 0
            ;;
        sort-downloads|sortdl)
            # Complete with options or directory paths
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--by-date -d --by-extension -e --dry-run -n --directory --dir --help -h" -- "$cur"))
            else
                COMPREPLY=($(compgen -d -- "$cur"))
            fi
            return 0
            ;;
    esac
    
    # Complete options or directories
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--by-date -d --by-extension -e --dry-run -n --directory --dir --help -h" -- "$cur"))
    else
        COMPREPLY=($(compgen -d -- "$cur"))
    fi
}

# Register completion for both function names
if declare -f _init_completion >/dev/null 2>&1 || declare -f complete >/dev/null 2>&1; then
    complete -F _sort-downloads_completion sort-downloads 2>/dev/null || true
    complete -F _sort-downloads_completion sortdl 2>/dev/null || true
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    sort-downloads "$@"
    exit $?
fi


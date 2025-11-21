#!/bin/bash
# Sourcing Guard - check if dupefind function already exists
if declare -f dupefind >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

dupefind() {
    # Handle help flags (case-insensitive)
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp dupefind
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    local hash_cmd=""
    local hash_algo="md5"
    local search_dir="."
    local delete_mode=false
    local interactive_mode=false
    local show_size=true
    local min_size="1"
    
    # Determine available hash command
    if command -v md5sum >/dev/null 2>&1 || command -v md5 >/dev/null 2>&1; then
        hash_cmd="md5"
        hash_algo="md5"
        if command -v md5sum >/dev/null 2>&1; then
            hash_algo="md5sum"
        elif command -v md5 >/dev/null 2>&1; then
            hash_algo="md5"
        fi
    fi
    
    if command -v sha256sum >/dev/null 2>&1 || command -v sha256 >/dev/null 2>&1; then
        hash_cmd="sha256"
        if command -v sha256sum >/dev/null 2>&1; then
            hash_algo="sha256sum"
        elif command -v sha256 >/dev/null 2>&1; then
            hash_algo="sha256"
        fi
    fi
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --md5|-m)
                if ! command -v md5sum >/dev/null 2>&1 && ! command -v md5 >/dev/null 2>&1; then
                    echo "Error: md5sum or md5 command not available" >&2
                    return 123
                fi
                hash_algo="md5sum"
                if ! command -v md5sum >/dev/null 2>&1; then
                    hash_algo="md5"
                fi
                shift
                ;;
            --sha256|-s)
                if ! command -v sha256sum >/dev/null 2>&1 && ! command -v sha256 >/dev/null 2>&1; then
                    echo "Error: sha256sum or sha256 command not available" >&2
                    return 123
                fi
                hash_algo="sha256sum"
                if ! command -v sha256sum >/dev/null 2>&1; then
                    hash_algo="sha256"
                fi
                shift
                ;;
            --delete|-d)
                delete_mode=true
                shift
                ;;
            --interactive|-i)
                interactive_mode=true
                shift
                ;;
            --no-size)
                show_size=false
                shift
                ;;
            --min-size)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --min-size requires a size argument" >&2
                    return 1
                fi
                min_size="$2"
                shift 2
                ;;
            --)
                shift
                search_dir="$1"
                break
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                return 1
                ;;
            *)
                search_dir="$1"
                shift
                ;;
        esac
    done
    
    # Validate search directory
    [[ ! -d "$search_dir" ]] && [[ ! -f "$search_dir" ]] && {
        echo "Error: '$search_dir' does not exist" >&2
        return 2
    }
    
    # Ensure we have a hash command
    if [[ -z "$hash_cmd" ]]; then
        echo "Error: No hash command available (md5sum, md5, sha256sum, or sha256 required)" >&2
        return 123
    fi
    
    # Ensure find command is available
    ensure_commands_present --caller "dupefind" find stat || {
        return $?
    }
    
    local hash_function=""
    case "$hash_algo" in
        md5sum)
            ensure_commands_present --caller "dupefind" md5sum || return $?
            hash_function="md5sum"
            ;;
        md5)
            ensure_commands_present --caller "dupefind" md5 || return $?
            hash_function="md5"
            ;;
        sha256sum)
            ensure_commands_present --caller "dupefind" sha256sum || return $?
            hash_function="sha256sum"
            ;;
        sha256)
            ensure_commands_present --caller "dupefind" sha256 || return $?
            hash_function="sha256"
            ;;
        *)
            echo "Error: Invalid hash algorithm: $hash_algo" >&2
            return 1
            ;;
    esac
    
    # Create temporary file for hash storage
    local tmp_file=""
    tmp_file=$(mktemp 2>/dev/null) || {
        echo "Error: Failed to create temporary file" >&2
        return 3
    }
    
    local cleanup_tmp=true
    
    # Function to get file hash
    get_file_hash() {
        local file="$1"
        local hash_result=""
        
        case "$hash_function" in
            md5sum)
                hash_result=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
                ;;
            md5)
                hash_result=$(md5 -q "$file" 2>/dev/null)
                ;;
            sha256sum)
                hash_result=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
                ;;
            sha256)
                hash_result=$(sha256 -q "$file" 2>/dev/null)
                ;;
        esac
        
        echo "$hash_result"
    }
    
    # Function to format file size
    format_size() {
        local size="$1"
        if [[ $size -lt 1024 ]]; then
            echo "${size}B"
        elif [[ $size -lt 1048576 ]]; then
            echo "$(echo "scale=2; $size / 1024" | bc 2>/dev/null || echo "$((size / 1024))")KB"
        elif [[ $size -lt 1073741824 ]]; then
            echo "$(echo "scale=2; $size / 1048576" | bc 2>/dev/null || echo "$((size / 1048576))")MB"
        else
            echo "$(echo "scale=2; $size / 1073741824" | bc 2>/dev/null || echo "$((size / 1073741824))")GB"
        fi
    }
    
    # Function to check minimum size
    check_min_size() {
        local file="$1"
        local file_size
        file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        
        # Parse min_size (supports K, M, G suffixes)
        local min_bytes="$min_size"
        if [[ "$min_size" == *[Kk] ]]; then
            min_bytes=$(echo "${min_size%[Kk]} * 1024" | bc 2>/dev/null || echo "$(( ${min_size%[Kk]} * 1024 ))")
        elif [[ "$min_size" == *[Mm] ]]; then
            min_bytes=$(echo "${min_size%[Mm]} * 1048576" | bc 2>/dev/null || echo "$(( ${min_size%[Mm]} * 1048576 ))")
        elif [[ "$min_size" == *[Gg] ]]; then
            min_bytes=$(echo "${min_size%[Gg]} * 1073741824" | bc 2>/dev/null || echo "$(( ${min_size%[Gg]} * 1073741824 ))")
        fi
        
        [[ $file_size -ge $min_bytes ]]
    }
    
    # Collect all files and their hashes
    echo "Scanning files..." >&2
    local file_count=0
    local hash_count=0
    
    # Find all files and calculate hashes
    if [[ -f "$search_dir" ]]; then
        # Single file mode - compare with other files in same directory
        local file_dir
        file_dir=$(dirname "$search_dir")
        local file_base
        file_base=$(basename "$search_dir")
        
        while IFS= read -r -d '' file; do
            [[ "$file" == "$search_dir" ]] && continue
            [[ -f "$file" ]] || continue
            
            check_min_size "$file" || continue
            
            local hash
            hash=$(get_file_hash "$file")
            [[ -z "$hash" ]] && continue
            
            local file_size
            file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            
            echo "$hash|$file|$file_size" >> "$tmp_file"
            ((file_count++))
        done < <(find "$file_dir" -type f -print0 2>/dev/null)
        
        # Add the target file itself
        if check_min_size "$search_dir"; then
            local hash
            hash=$(get_file_hash "$search_dir")
            if [[ -n "$hash" ]]; then
                local file_size
                file_size=$(stat -f%z "$search_dir" 2>/dev/null || stat -c%s "$search_dir" 2>/dev/null || echo "0")
                echo "$hash|$search_dir|$file_size" >> "$tmp_file"
                ((file_count++))
            fi
        fi
    else
        # Directory mode
        while IFS= read -r -d '' file; do
            [[ -f "$file" ]] || continue
            
            check_min_size "$file" || continue
            
            local hash
            hash=$(get_file_hash "$file")
            [[ -z "$hash" ]] && continue
            
            local file_size
            file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            
            echo "$hash|$file|$file_size" >> "$tmp_file"
            ((file_count++))
        done < <(find "$search_dir" -type f -print0 2>/dev/null)
    fi
    
    [[ $file_count -eq 0 ]] && {
        echo "No files found matching criteria." >&2
        rm -f "$tmp_file"
        return 0
    }
    
    echo "Found $file_count files. Analyzing duplicates..." >&2
    
    # Sort by hash to group duplicates
    sort "$tmp_file" > "${tmp_file}.sorted" 2>/dev/null || {
        echo "Error: Failed to sort hash file" >&2
        rm -f "$tmp_file"
        return 4
    }
    
    # Find duplicates
    local current_hash=""
    local duplicate_files=()
    local duplicates_found=false
    local total_size_wasted=0
    
    while IFS='|' read -r hash file_path file_size; do
        if [[ "$hash" == "$current_hash" ]]; then
            duplicate_files+=("$file_path|$file_size")
        else
            # Process previous group if it has duplicates
            if [[ ${#duplicate_files[@]} -gt 1 ]]; then
                duplicates_found=true
                
                if [[ "$delete_mode" == false ]] && [[ "$interactive_mode" == false ]]; then
                    # Just display duplicates
                    echo ""
                    echo "Duplicate group ($hash_algo: ${current_hash:0:16}...):"
                    local group_size=0
                    local first=true
                    for dup_entry in "${duplicate_files[@]}"; do
                        IFS='|' read -r dup_file dup_size <<< "$dup_entry"
                        group_size=$((group_size + dup_size))
                        
                        if [[ "$show_size" == true ]]; then
                            local formatted_size
                            formatted_size=$(format_size "$dup_size")
                            if [[ "$first" == true ]]; then
                                echo "  [KEEP]  $dup_file ($formatted_size)"
                                first=false
                            else
                                echo "  [DUP]   $dup_file ($formatted_size)"
                            fi
                        else
                            if [[ "$first" == true ]]; then
                                echo "  [KEEP]  $dup_file"
                                first=false
                            else
                                echo "  [DUP]   $dup_file"
                            fi
                        fi
                    done
                    
                    # Calculate wasted space (all but first file)
                    local wasted=$((group_size - ${duplicate_files[0]##*|}))
                    total_size_wasted=$((total_size_wasted + wasted))
                    
                    if [[ "$show_size" == true ]]; then
                        local wasted_formatted
                        wasted_formatted=$(format_size "$wasted")
                        echo "  Wasted space: $wasted_formatted"
                    fi
                elif [[ "$delete_mode" == true ]]; then
                    # Delete mode: keep first, delete rest
                    local first=true
                    for dup_entry in "${duplicate_files[@]}"; do
                        IFS='|' read -r dup_file dup_size <<< "$dup_entry"
                        if [[ "$first" == true ]]; then
                            echo "[KEEP] $dup_file"
                            first=false
                        else
                            if rm -f "$dup_file" 2>/dev/null; then
                                echo "[DELETED] $dup_file"
                                ((hash_count++))
                            else
                                echo "[ERROR] Failed to delete: $dup_file" >&2
                            fi
                        fi
                    done
                elif [[ "$interactive_mode" == true ]]; then
                    # Interactive mode
                    echo ""
                    echo "Duplicate group found:"
                    local index=0
                    for dup_entry in "${duplicate_files[@]}"; do
                        IFS='|' read -r dup_file dup_size <<< "$dup_entry"
                        local formatted_size
                        formatted_size=$(format_size "$dup_size")
                        printf "  [%d] %s (%s)\n" "$index" "$dup_file" "$formatted_size"
                        ((index++))
                    done
                    
                    echo ""
                    echo "Which files would you like to keep? (enter numbers separated by spaces, or 'all' to keep all, or 'skip' to skip this group):"
                    read -r response
                    
                    if [[ "${response,,}" == "skip" ]]; then
                        duplicate_files=()
                        current_hash="$hash"
                        duplicate_files=("$file_path|$file_size")
                        continue
                    fi
                    
                    local keep_indices=()
                    if [[ "${response,,}" == "all" ]]; then
                        keep_indices=($(seq 0 $((index - 1))))
                    else
                        keep_indices=($response)
                    fi
                    
                    local index=0
                    for dup_entry in "${duplicate_files[@]}"; do
                        IFS='|' read -r dup_file dup_size <<< "$dup_entry"
                        local should_keep=false
                        for keep_idx in "${keep_indices[@]}"; do
                            [[ $keep_idx -eq $index ]] && should_keep=true && break
                        done
                        
                        if [[ "$should_keep" == false ]]; then
                            echo "Delete $dup_file? (y/n):"
                            read -r confirm
                            if [[ "${confirm,,}" == "y" ]] || [[ "${confirm,,}" == "yes" ]]; then
                                if rm -f "$dup_file" 2>/dev/null; then
                                    echo "[DELETED] $dup_file"
                                    ((hash_count++))
                                else
                                    echo "[ERROR] Failed to delete: $dup_file" >&2
                                fi
                            fi
                        fi
                        ((index++))
                    done
                fi
            fi
            
            # Start new group
            current_hash="$hash"
            duplicate_files=("$file_path|$file_size")
        fi
    done < "${tmp_file}.sorted"
    
    # Process last group
    if [[ ${#duplicate_files[@]} -gt 1 ]]; then
        duplicates_found=true
        
        if [[ "$delete_mode" == false ]] && [[ "$interactive_mode" == false ]]; then
            echo ""
            echo "Duplicate group ($hash_algo: ${current_hash:0:16}...):"
            local group_size=0
            local first=true
            for dup_entry in "${duplicate_files[@]}"; do
                IFS='|' read -r dup_file dup_size <<< "$dup_entry"
                group_size=$((group_size + dup_size))
                
                if [[ "$show_size" == true ]]; then
                    local formatted_size
                    formatted_size=$(format_size "$dup_size")
                    if [[ "$first" == true ]]; then
                        echo "  [KEEP]  $dup_file ($formatted_size)"
                        first=false
                    else
                        echo "  [DUP]   $dup_file ($formatted_size)"
                    fi
                else
                    if [[ "$first" == true ]]; then
                        echo "  [KEEP]  $dup_file"
                        first=false
                    else
                        echo "  [DUP]   $dup_file"
                    fi
                fi
            done
            
            local wasted=$((group_size - ${duplicate_files[0]##*|}))
            total_size_wasted=$((total_size_wasted + wasted))
            
            if [[ "$show_size" == true ]]; then
                local wasted_formatted
                wasted_formatted=$(format_size "$wasted")
                echo "  Wasted space: $wasted_formatted"
            fi
        elif [[ "$delete_mode" == true ]]; then
            local first=true
            for dup_entry in "${duplicate_files[@]}"; do
                IFS='|' read -r dup_file dup_size <<< "$dup_entry"
                if [[ "$first" == true ]]; then
                    echo "[KEEP] $dup_file"
                    first=false
                else
                    if rm -f "$dup_file" 2>/dev/null; then
                        echo "[DELETED] $dup_file"
                        ((hash_count++))
                    else
                        echo "[ERROR] Failed to delete: $dup_file" >&2
                    fi
                fi
            done
        fi
    fi
    
    # Cleanup
    rm -f "$tmp_file" "${tmp_file}.sorted"
    
    # Summary
    if [[ "$delete_mode" == false ]] && [[ "$interactive_mode" == false ]]; then
        if [[ "$duplicates_found" == false ]]; then
            echo ""
            echo "No duplicates found."
        else
            echo ""
            if [[ "$show_size" == true ]]; then
                local total_wasted_formatted
                total_wasted_formatted=$(format_size "$total_size_wasted")
                echo "Summary: Found duplicate files. Total wasted space: $total_wasted_formatted"
            else
                echo "Summary: Found duplicate files."
            fi
            echo "Use --delete to automatically delete duplicates (keeps first file), or --interactive for manual selection."
        fi
    elif [[ "$delete_mode" == true ]] || [[ "$interactive_mode" == true ]]; then
        if [[ $hash_count -gt 0 ]]; then
            echo ""
            echo "Deleted $hash_count duplicate file(s)."
        else
            echo ""
            echo "No files deleted."
        fi
    fi
    
    return 0
}

# Bash completion function for dupefind
_dupefind_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # If current word starts with dash, complete with flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--md5 -m --sha256 -s --delete -d --interactive -i --no-size --min-size --help -h --" -- "$cur"))
        return 0
    fi
    
    # If previous word is --min-size, no completion needed (user must type size)
    if [[ "$prev" == "--min-size" ]]; then
        COMPREPLY=()
        return 0
    fi
    
    # If previous word is --, complete with files/directories
    if [[ "$prev" == "--" ]]; then
        compopt -o default
        COMPREPLY=()
        return 0
    fi
    
    # Otherwise, complete with directories/files
    compopt -o default
    COMPREPLY=()
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _dupefind_completion dupefind 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    dupefind "$@"
    exit $?
fi


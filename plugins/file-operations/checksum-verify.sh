#!/bin/bash
# Sourcing Guard - check if checksum-verify function already exists
if declare -f checksum-verify >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

checksum-verify() {
    # Handle help flags (case-insensitive)
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp checksum-verify
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    local generate_mode=false
    local recursive_mode=false
    local check_mode=false
    local algorithm="sha256"
    local file=""
    local checksum=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --generate|-g)
                generate_mode=true
                shift
                ;;
            --recursive|-r)
                recursive_mode=true
                shift
                ;;
            --check|-c)
                check_mode=true
                shift
                ;;
            --algorithm|-a)
                if [[ -n "${2:-}" ]]; then
                    algorithm="${2,,}"
                    shift 2
                else
                    echo "Error: --algorithm requires an algorithm name" >&2
                    return 1
                fi
                ;;
            --)
                shift
                if [[ -n "${1:-}" ]]; then
                    file="$1"
                fi
                if [[ -n "${2:-}" ]]; then
                    checksum="$2"
                fi
                break
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                return 1
                ;;
            *)
                # First non-flag argument is the file
                if [[ -z "$file" ]]; then
                    file="$1"
                # Second non-flag argument is the checksum (for verify mode)
                elif [[ -z "$checksum" ]] && [[ "$generate_mode" == false ]] && [[ "$check_mode" == false ]]; then
                    checksum="$1"
                else
                    echo "Error: Too many arguments" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate file is provided
    if [[ -z "$file" ]]; then
        echo "Error: File is required" >&2
        echo "Usage: checksum-verify <file> [checksum]" >&2
        echo "       checksum-verify --generate <file>" >&2
        echo "       checksum-verify --recursive <directory>" >&2
        echo "       checksum-verify --check <checksum_file>" >&2
        echo "       checksum-verify --help for more information" >&2
        return 1
    fi
    
    # Validate file/directory exists
    if [[ ! -e "$file" ]]; then
        echo "Error: '$file' does not exist" >&2
        return 1
    fi
    
    if [[ "$recursive_mode" == true ]] && [[ ! -d "$file" ]]; then
        echo "Error: --recursive requires a directory, but '$file' is not a directory" >&2
        return 1
    fi
    
    if [[ "$check_mode" == true ]] && [[ ! -f "$file" ]]; then
        echo "Error: --check requires a file, but '$file' is not a regular file" >&2
        return 1
    fi
    
    if [[ "$recursive_mode" == false ]] && [[ "$check_mode" == false ]] && [[ ! -f "$file" ]]; then
        echo "Error: '$file' is not a regular file (use --recursive for directories)" >&2
        return 1
    fi
    
    # Normalize algorithm name
    algorithm="${algorithm,,}"
    
    # Function to get checksum command based on algorithm
    get_checksum_command() {
        local algo="$1"
        case "$algo" in
            md5)
                if command -v md5sum >/dev/null 2>&1; then
                    echo "md5sum"
                elif command -v md5 >/dev/null 2>&1; then
                    echo "md5"
                else
                    echo ""
                fi
                ;;
            sha1)
                if command -v sha1sum >/dev/null 2>&1; then
                    echo "sha1sum"
                elif command -v shasum >/dev/null 2>&1; then
                    echo "shasum -a 1"
                else
                    echo ""
                fi
                ;;
            sha256)
                if command -v sha256sum >/dev/null 2>&1; then
                    echo "sha256sum"
                elif command -v shasum >/dev/null 2>&1; then
                    echo "shasum -a 256"
                else
                    echo ""
                fi
                ;;
            sha512)
                if command -v sha512sum >/dev/null 2>&1; then
                    echo "sha512sum"
                elif command -v shasum >/dev/null 2>&1; then
                    echo "shasum -a 512"
                else
                    echo ""
                fi
                ;;
            *)
                echo ""
                ;;
        esac
    }
    
    # Function to extract checksum from command output
    extract_checksum() {
        local output="$1"
        local cmd_type="$2"
        
        if [[ "$cmd_type" == "md5" ]]; then
            # md5 command outputs: MD5 (file) = checksum
            echo "$output" | awk '{print $NF}'
        else
            # md5sum/sha*sum output: checksum  file
            echo "$output" | awk '{print $1}'
        fi
    }
    
    # Get the checksum command
    local cmd=$(get_checksum_command "$algorithm")
    
    if [[ -z "$cmd" ]]; then
        echo "Error: Algorithm '$algorithm' is not supported or required command not found" >&2
        echo "Supported algorithms: md5, sha1, sha256, sha512" >&2
        echo "Required commands: md5sum/md5, sha1sum/shasum, sha256sum/shasum, sha512sum/shasum" >&2
        return 1
    fi
    
    # Recursive mode (directory checksums)
    if [[ "$recursive_mode" == true ]]; then
        local target_dir="$file"
        # Use find to list all files, then calculate checksum for each
        # We cd into the directory so the paths in the output are relative to it
        (
            cd "$target_dir" || exit 1
            find . -type f | sort | while read -r f; do
                # Remove leading ./
                local clean_path="${f#./}"
                # Generate checksum for this file
                local output
                if [[ "$cmd" =~ ^shasum ]]; then
                    output=$(eval "$cmd \"$clean_path\" 2>/dev/null")
                else
                    output=$($cmd "$clean_path" 2>/dev/null)
                fi
                
                if [[ $? -eq 0 ]] && [[ -n "$output" ]]; then
                    echo "$output"
                fi
            done
        )
        return $?
    fi

    # Check mode (verify against checksum file)
    if [[ "$check_mode" == true ]]; then
        local checksum_file="$file"
        local total=0
        local passed=0
        local failed=0
        local missing=0

        # Determine the base directory for the check (usually the directory containing the checksum file)
        local base_dir=$(dirname "$checksum_file")
        
        # Determine command type for output parsing
        local check_cmd_type=""
        if [[ "$cmd" == "md5" ]]; then
            check_cmd_type="md5"
        fi

        while read -r line; do
            [[ -z "$line" ]] && continue
            
            # Lines are expected to be "checksum  path"
            local line_checksum=$(echo "$line" | awk '{print $1}')
            local line_path=$(echo "$line" | cut -d' ' -f3-)
            # If no double space, try single space
            if [[ -z "$line_path" ]]; then
                line_path=$(echo "$line" | cut -d' ' -f2-)
            fi
            # trim leading/trailing spaces
            line_path=$(echo "$line_path" | xargs)

            ((total++))
            
            local full_path="$base_dir/$line_path"
            # If path not found relative to checksum file, try absolute if it looks absolute
            if [[ ! -f "$full_path" ]] && [[ -f "$line_path" ]]; then
                full_path="$line_path"
            fi

            if [[ ! -f "$full_path" ]]; then
                echo "✗ MISSING: $line_path"
                ((missing++))
                continue
            fi

            # Normalize checksum
            line_checksum=$(echo "$line_checksum" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

            # Generate checksum for the file
            local output
            if [[ "$cmd" =~ ^shasum ]]; then
                output=$(eval "$cmd \"$full_path\" 2>/dev/null")
            else
                output=$($cmd "$full_path" 2>/dev/null)
            fi

            local file_checksum=$(extract_checksum "$output" "$check_cmd_type")
            file_checksum=$(echo "$file_checksum" | tr '[:upper:]' '[:lower:]')

            if [[ "$file_checksum" == "$line_checksum" ]]; then
                echo "✓ OK: $line_path"
                ((passed++))
            else
                echo "✗ FAILED: $line_path"
                ((failed++))
            fi
        done < "$checksum_file"

        echo ""
        echo "Summary:"
        echo "  Total:   $total"
        echo "  Passed:  $passed"
        echo "  Failed:  $failed"
        [[ $missing -gt 0 ]] && echo "  Missing: $missing"
        
        if [[ $failed -eq 0 ]] && [[ $missing -eq 0 ]] && [[ $total -gt 0 ]]; then
            return 0
        else
            return 1
        fi
    fi
    
    # Generate mode
    if [[ "$generate_mode" == true ]]; then
        local output
        local cmd_type=""
        
        # Determine command type for output parsing
        if [[ "$cmd" == "md5" ]]; then
            cmd_type="md5"
        fi
        
        # Generate checksum
        if [[ "$cmd" =~ ^shasum ]]; then
            # shasum needs special handling
            output=$(eval "$cmd \"$file\" 2>/dev/null")
        else
            output=$($cmd "$file" 2>/dev/null)
        fi
        
        if [[ $? -ne 0 ]] || [[ -z "$output" ]]; then
            echo "Error: Failed to generate $algorithm checksum for '$file'" >&2
            return 1
        fi
        
        # Extract and display checksum
        local generated_checksum=$(extract_checksum "$output" "$cmd_type")
        echo "$generated_checksum"
        return 0
    fi
    
    # Verify mode
    if [[ -z "$checksum" ]]; then
        echo "Error: Checksum is required for verification" >&2
        echo "Usage: checksum-verify <file> <checksum>" >&2
        echo "       checksum-verify --help for more information" >&2
        return 1
    fi
    
    # Normalize checksum (remove spaces, convert to lowercase)
    checksum=$(echo "$checksum" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    
    # Generate checksum for file
    local output
    local cmd_type=""
    
    if [[ "$cmd" == "md5" ]]; then
        cmd_type="md5"
    fi
    
    if [[ "$cmd" =~ ^shasum ]]; then
        output=$(eval "$cmd \"$file\" 2>/dev/null")
    else
        output=$($cmd "$file" 2>/dev/null)
    fi
    
    if [[ $? -ne 0 ]] || [[ -z "$output" ]]; then
        echo "Error: Failed to generate $algorithm checksum for '$file'" >&2
        return 1
    fi
    
    local file_checksum=$(extract_checksum "$output" "$cmd_type")
    file_checksum=$(echo "$file_checksum" | tr '[:upper:]' '[:lower:]')
    
    # Compare checksums
    if [[ "$file_checksum" == "$checksum" ]]; then
        echo "✓ Checksums match"
        echo "  File: $file"
        echo "  Algorithm: $algorithm"
        echo "  Checksum: $file_checksum"
        return 0
    else
        echo "✗ Checksums do NOT match"
        echo "  File: $file"
        echo "  Algorithm: $algorithm"
        echo "  Expected: $checksum"
        echo "  Actual:   $file_checksum"
        return 1
    fi
}

# Tab completion function
_checksum_verify_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # If current word starts with dash, complete with flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--generate -g --recursive -r --check -c --algorithm -a --help -h --" -- "$cur"))
        return 0
    fi
    
    # If previous word is --algorithm, complete with algorithm names
    if [[ "$prev" == "--algorithm" ]] || [[ "$prev" == "-a" ]]; then
        COMPREPLY=($(compgen -W "md5 sha1 sha256 sha512" -- "$cur"))
        return 0
    fi
    
    # Otherwise, complete with files
    compopt -o default
    COMPREPLY=()
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _checksum_verify_completion checksum-verify 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    checksum-verify "$@"
    exit $?
fi


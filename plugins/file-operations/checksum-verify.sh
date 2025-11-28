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
                elif [[ -z "$checksum" ]] && [[ "$generate_mode" == false ]]; then
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
        echo "       checksum-verify --help for more information" >&2
        return 1
    fi
    
    # Validate file exists
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' does not exist or is not a regular file" >&2
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
        COMPREPLY=($(compgen -W "--generate -g --algorithm -a --help -h --" -- "$cur"))
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


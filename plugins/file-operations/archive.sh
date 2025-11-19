#!/bin/bash
# Sourcing Guard - check if extract or compress function already exists
if declare -f extract >/dev/null 2>&1 || declare -f compress >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__FILE_OPERATIONS_DIR:-}" ]] && readonly __FILE_OPERATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__FILE_OPERATIONS_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__FILE_OPERATIONS_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

extract() {
    [[ ! -f "$1" ]] && {
        echo "Error: '$1' does not exist or is not a file" >&2
        return 1
    }

    local result=0
    case "$1" in
        *.tar.bz2)
            ensure_commands_present --caller "extract" tar || {
                return $?
            }
            tar xjf "$1"
            result=$?
            ;;
        *.tar.gz)
            ensure_commands_present --caller "extract" tar || {
                return $?
            }
            tar xzf "$1"
            result=$?
            ;;
        *.bz2)
            ensure_commands_present --caller "extract" bunzip2 || {
                return $?
            }
            bunzip2 "$1"
            result=$?
            ;;
        *.rar)
            ensure_commands_present --caller "extract" unrar || {
                return $?
            }
            unrar x "$1"
            result=$?
            ;;
        *.gz)
            ensure_commands_present --caller "extract" gunzip || {
                return $?
            }
            gunzip "$1"
            result=$?
            ;;
        *.tar)
            ensure_commands_present --caller "extract" tar || {
                return $?
            }
            tar xf "$1"
            result=$?
            ;;
        *.tbz2)
            ensure_commands_present --caller "extract" tar || {
                return $?
            }
            tar xjf "$1"
            result=$?
            ;;
        *.tgz)
            ensure_commands_present --caller "extract" tar || {
                return $?
            }
            tar xzf "$1"
            result=$?
            ;;
        *.zip)
            ensure_commands_present --caller "extract" unzip || {
                return $?
            }
            unzip "$1"
            result=$?
            ;;
        *.Z)
            ensure_commands_present --caller "extract" uncompress || {
                return $?
            }
            uncompress "$1"
            result=$?
            ;;
        *.7z)
            ensure_commands_present --caller "extract" 7z || {
                return $?
            }
            7z x "$1"
            result=$?
            ;;
        *)
            echo "'$1' cannot be extracted via extract()" >&2
            return 1
            ;;
    esac
    
    return $result
}

compress() {
    local input="$1"
    local format="${2:-}"
    local output=""

    [[ ! -e "$input" ]] && {
        echo "Error: '$input' does not exist" >&2
        return 1
    }

    # Determine format and output filename
    if [[ -n "$format" ]]; then
        # Format specified as second argument
        case "$format" in
            tar.bz2|tbz2)
                format="tar.bz2"
                output="${input%/}.tar.bz2"
                ;;
            tar.gz|tgz)
                format="tar.gz"
                output="${input%/}.tar.gz"
                ;;
            bz2|rar|gz|tar|zip|Z|7z)
                output="${input%/}.${format}"
                ;;
            *)
                echo "Error: Unknown format '$format'" >&2
                echo "Supported formats: tar.bz2, tar.gz, bz2, rar, gz, tar, tbz2, tgz, zip, Z, 7z" >&2
                return 1
                ;;
        esac
    elif [[ -d "$input" ]]; then
        # Default for directories: tar.gz
        format="tar.gz"
        output="${input%/}.tar.gz"
    else
        # Default for files: gz
        format="gz"
        output="${input}.gz"
    fi

    # Check if output already exists
    [[ -e "$output" ]] && {
        echo "Error: Output file '$output' already exists" >&2
        return 1
    }

    # Create archive based on format
    case "$format" in
        tar.bz2|tbz2)
            ensure_commands_present --caller "compress" tar || {
                return $?
            }
            tar cjf "$output" "$input"
            ;;
        tar.gz|tgz)
            ensure_commands_present --caller "compress" tar || {
                return $?
            }
            tar czf "$output" "$input"
            ;;
        bz2)
            ensure_commands_present --caller "compress" bzip2 || {
                return $?
            }
            bzip2 -k "$input"
            # bzip2 creates input.bz2, so we need to rename if different
            [[ "$output" != "${input}.bz2" ]] && mv "${input}.bz2" "$output"
            ;;
        rar)
            ensure_commands_present --caller "compress" rar || {
                return $?
            }
            rar a "$output" "$input"
            ;;
        gz)
            ensure_commands_present --caller "compress" gzip || {
                return $?
            }
            gzip -k "$input"
            # gzip creates input.gz, so we need to rename if different
            [[ "$output" != "${input}.gz" ]] && mv "${input}.gz" "$output"
            ;;
        tar)
            ensure_commands_present --caller "compress" tar || {
                return $?
            }
            tar cf "$output" "$input"
            ;;
        zip)
            ensure_commands_present --caller "compress" zip || {
                return $?
            }
            if [[ -d "$input" ]]; then
                zip -r "$output" "$input"
            else
                zip "$output" "$input"
            fi
            ;;
        Z)
            ensure_commands_present --caller "compress" compress || {
                return $?
            }
            compress -c "$input" > "$output"
            ;;
        7z)
            ensure_commands_present --caller "compress" 7z || {
                return $?
            }
            7z a "$output" "$input"
            ;;
        *)
            echo "Error: Unsupported format '$format'" >&2
            return 1
            ;;
    esac

    local result=$?

    if [[ $result -eq 0 ]]; then
        echo "Created: $output"
        return 0
    else
        echo "Error: Failed to create archive" >&2
        return $result
    fi
}

# Bash completion function for extract
_extract_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Complete with archive files (supported extensions)
    # Filter files by supported archive extensions
    compopt -o filenames
    local files
    mapfile -t files < <(compgen -f -- "$cur" 2>/dev/null)
    local completions=()
    local file
    for file in "${files[@]}"; do
        # Check if file matches supported archive extensions
        case "$file" in
            *.tar.bz2|*.tar.gz|*.bz2|*.rar|*.gz|*.tar|*.tbz2|*.tgz|*.zip|*.Z|*.7z)
                completions+=("$file")
                ;;
        esac
    done
    COMPREPLY=("${completions[@]}")
    return 0
}

# Bash completion function for compress
_compress_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # If we're on the second argument, complete with supported formats
    if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "tar.bz2 tbz2 tar.gz tgz bz2 rar gz tar zip Z 7z" -- "$cur"))
        return 0
    fi

    # Otherwise, complete with files and directories (default completion)
    compopt -o default
    COMPREPLY=()
    return 0
}

# Register the completion functions
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _extract_completion extract 2>/dev/null || true
        complete -F _compress_completion compress 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 {extract|compress} [arguments...]" >&2
        exit 1
    fi
    
    func_name="$1"
    shift
    
    case "$func_name" in
        extract)
            extract "$@"
            exit $?
            ;;
        compress)
            compress "$@"
            exit $?
            ;;
        *)
            echo "Error: Unknown function '$func_name'. Use 'extract' or 'compress'." >&2
            exit 1
            ;;
    esac
fi


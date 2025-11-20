#!/bin/bash
# Sourcing Guard - check if motd function already exists
if declare -f motd >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__UTILITIES_DIR:-}" ]] && readonly __UTILITIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__UTILITIES_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__UTILITIES_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__UTILITIES_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# Message of the day (shoo to remove, make to edit)
motd() {
  # Handle help flags (case-insensitive) - delegate to drchelp
  if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
    if declare -f drchelp >/dev/null 2>&1; then
      drchelp motd
      return 0
    else
      echo "Error: drchelp not available" >&2
      return 1
    fi
  fi
  
  # Show help if no argument provided or if help is requested
  case "${1^^}" in
  "SHOO")
    ensure_commands_present --caller "motd shoo" rm || {
      return $?
    }
    if ! rm -f "$HOME/motd.txt"; then
      echo "Error: failed to remove message of the day file"
      return 1
    fi
    echo "MOTD file removed"
    return 0
    ;;
  "MAKE")
    # If stdin is not a terminal (i.e., data is being piped), write it to motd.txt.
    if [[ ! -t 0 ]]; then
      ensure_commands_present --caller "motd make (stdin)" cat || {
        return $?
      }
      if ! cat > "$HOME/motd.txt"; then
        echo "Error: failed to write message of the day from stdin"
        return 1
      else
        echo "Message of the day written to file"
      fi
      return 0
    fi

    # Otherwise, open the editor to edit/create motd.txt.
    local editor="${EDITOR:-nvim}"
    ensure_commands_present --caller "motd make" "$editor" || {
      return $?
    }
    "$editor" "$HOME/motd.txt"
    return
    ;;
  "PRINT")
    ensure_commands_present --caller "motd print" cat head wc || {
      return $?
    }
    [[ -f "$HOME/motd.txt" ]] && {
      local line_count
      line_count=$(wc -l < "$HOME/motd.txt" 2>/dev/null || echo "0")
      
      if [[ $line_count -gt 20 ]]; then
        # File is over 20 lines - show preview then open in pager
        printf "\nMESSAGE OF THE DAY (preview):\n"
        if ! head -5 "$HOME/motd.txt"; then
          echo "Error: failed to display message of the day preview"
          return 1
        fi
        printf "...\n\n"
        
        # Determine pager: nvim -> $EDITOR -> $PAGER -> less
        local pager=""
        local pager_args=()
        if command -v nvim >/dev/null 2>&1; then
          pager="nvim"
          pager_args=("-u" "NONE" "-R" "-")  # -u NONE: no config/plugins, -R: read-only, -: read from stdin
        elif [[ -n "${EDITOR:-}" ]] && command -v "$EDITOR" >/dev/null 2>&1; then
          pager="$EDITOR"
        elif [[ -n "${PAGER:-}" ]] && command -v "$PAGER" >/dev/null 2>&1; then
          pager="$PAGER"
        elif command -v less >/dev/null 2>&1; then
          pager="less"
        else
          echo "Error: no suitable pager found (tried: nvim, \$EDITOR, \$PAGER, less)" >&2
          return 1
        fi
        
        ensure_commands_present --caller "motd print (pager)" "$pager" || {
          return $?
        }
        
        # Pipe content through pager with prepended header (read-only)
        if [[ "$pager" == "nvim" ]]; then
          (printf "MESSAGE OF THE DAY:\n%s\n%s\n\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$(for i in {1..60}; do printf "-"; done)"; cat "$HOME/motd.txt") | "$pager" "${pager_args[@]}"
        else
          (printf "MESSAGE OF THE DAY:\n%s\n%s\n\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$(for i in {1..60}; do printf "-"; done)"; cat "$HOME/motd.txt") | "$pager"
        fi
        return $?
      else
        # File is 20 lines or less - display normally
        printf "\nMESSAGE OF THE DAY:\n"
        if ! cat "$HOME/motd.txt"; then
          echo "Error: failed to display message of the day"
          return 1
        fi
        printf "\n"
        sleep 1
      fi
    }
    return 0
    ;;
  *)
    cat <<'EOF'
Usage: motd [COMMAND]

Message of the Day - Display, create, or manage your daily message

Commands:
  (no args)  - Show this help message
  print      - Display the current message of the day
  make       - Create or edit the message of the day file
  shoo       - Remove the message of the day file

Examples:
  motd              # Show this help message
  motd print        # Display current message
  motd make         # Edit/create message in nvim
  motd shoo         # Delete message file

File location: ~/motd.txt
EOF
    return 0
  esac
}

# Bash completion function for motd
_motd_completion() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # If current word starts with a dash, complete with help flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
        return 0
    fi
    
    # Complete with subcommands (compgen handles prefix matching automatically)
    COMPREPLY=($(compgen -W "print make shoo" -- "$cur"))
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _motd_completion motd 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  motd "$@"
  exit $?
fi


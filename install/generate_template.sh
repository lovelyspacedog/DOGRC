#!/bin/bash

# Template generator for DOGRC installation
# Usage: generate_template.sh <template_name>
# Outputs template content to stdout

case "${1}" in
    "aliases"|"aliases.sh")
        cat <<'EOF'
#!/bin/bash
# This file is user-configurable and won't be overwritten by updates.

# Aliases
alias ++="cpx"
alias analyze="analyze-file"
alias brb="/usr/bin/systemctl reboot"
alias c="clear"
alias changelog="$EDITOR $__DOGRC_DIR/install/changelog.txt"
alias clss="clear && pokefetch"
alias cls="clear"
alias copy="rsync -rv --progress"
alias cx="chmod +x"
alias duu="find -maxdepth 1 -mindepth 1 -exec du -skh {} \;" # Get the size of the current directory
alias fzf="fzf --preview 'bat --style=numbers --color=always {}'"
alias gg="update"
alias grep="grep --color=auto"
alias hardware="inxi -Fza"
alias hyperctl="hyprctl"
alias hyperpm="hyprpm"
alias media="cd /run/media/$USER"
alias media-cd="media && cd"
alias mu="rmpc"
alias music="rmpc"
alias myip="curl ipinfo.io/ip ; echo"
alias nuke="pkill -9"
alias please="sudo"
alias plugins="cd $__PLUGINS_DIR && eza --tree || tree || ls -R"
alias aliases="cat $__CORE_DIR/aliases.sh"
alias pls="sudo"
alias prepsh="prepfile --bash"
alias ports="netstat -tulanp"
alias s="sudo"
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias tg="sudo true && topgrade --yes"
alias tmux="tmux -2"
alias tt="tmux -2"
alias uninst="yay -Rnsc" # Uninstall a package
alias xcx="chmod -x"
alias yayr="yay -Rnsc"   # Remove a package
alias zzz="/usr/bin/systemctl poweroff"

#Root Aliases
[[ $UID -eq 0 ]] && {
  alias rm="rm -i" # Ask for confirmation before removing
  alias cp="cp -i" # Ask for confirmation before copying
  alias mv="mv -i" # Ask for confirmation before moving
}

#LS/EZA Aliases
command -v eza >/dev/null 2>&1 && {
  alias ls="eza -lh --group-directories-first --icons=auto"
  alias lsa="eza -a"
  alias lt="eza --tree --level=2 --long --icons --git"
  alias lta="lt -a"
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
}

# Neovim Aliases
command -v nvim >/dev/null 2>&1 && {
  alias vi="nvim"
  alias vim="nvim"
  alias svi="sudo nvim"
  alias svim="sudo nvim"
  alias edit="nvim"
  alias hardware="inxi -Fza | nvim"
}

# Print the aliases if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cat "${BASH_SOURCE[0]}"
  exit 0
fi
EOF
        ;;
    "preamble"|"preamble.sh")
        cat <<'EOF'
#!/bin/bash
# This file is user-configurable and won't be overwritten by updates.

case "${1}" in
    --non-interactive)
        # Add non-interactive content here

        return 0
        ;;
    --interactive)
        # Add interactive content here

        return 0
        ;;
    --after-loading)
        # Add content to be executed after loading bashrc

        return 0
        ;;
esac

return 1
EOF
        ;;
    "example"|"example.sh")
        cat <<'EOF'
#!/bin/bash

# This is an example of a user-plugin.
# Thus, we'll stop execution here to keep it from
# polluting the plugins directory.
return 0 || exit 0

# Sourcing Guard - check if example function already exists
# Replace "example" with your function name
if declare -f example >/dev/null 2>&1; then
    return 0
fi

# Directory variable setup
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__PLUGINS_DIR}/../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__PLUGINS_DIR}/.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

# Replace "example" with your function name
example() {
    # Check for required commands (replace with your dependencies)
    ensure_commands_present --caller "example" command1 command2 || {
        return $?
    }

    # Your function logic here
    echo "Processing: $*"

    return 0
}

# Run the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    example "$@"
    exit $?
fi
EOF
        ;;
    "DOGRC.json"|"dogrc.json"|"config.json")
        cat <<'EOF'
{
    "version": "REPLACE",
    "enable_update_check": true,
    "enable_user_plugins": true,
    "enable_aliases": true,
    "enable_blesh": true,
    "enable_hyprland_wlcopy": true,
    "enable_shell_mommy": true,
    "enable_starship": true,
    "enable_vimkeys": true,
    "enable_drchelp": true,
    "enable_zoxide": true,
    "enable_automotd": true
}
EOF
        ;;
    "redirect"|"redirect.sh")
        cat <<'EOF'
#!/bin/bash

# Redirect to DOGRC bashrc
source "$HOME/DOGRC/.bashrc"
EOF
        ;;
    "disabled.json"|"disabled")
        cat <<'EOF'
{
    "do_not_source_these_plugins": [
        "plugins/example.sh"
    ],
    "do_not_enable_these_functions": [
        "example_function",
        "another_example_function"
    ],
    "do_not_source_these_aliases": [
        "example_alias"
    ]
}
EOF
        ;;
    *)
        echo "Error: Unknown template '$1'" >&2
        echo "Available templates: aliases, preamble, example, DOGRC.json, redirect, disabled.json" >&2
        exit 1
        ;;
esac

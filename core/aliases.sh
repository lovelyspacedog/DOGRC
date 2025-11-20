#!/bin/bash

# Aliases
alias ++="cpx"
alias analyze="analyze-file"
alias brb="/usr/bin/systemctl reboot"
alias c="clear"
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
alias tt="tmux"
alias uninst="yay -Rnsc" # Uninstall a package
alias us="dots userScripts"
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

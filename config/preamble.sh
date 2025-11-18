#!/bin/bash
# This file is user-configurable and won't be overwritten by updates.

case "${1}" in
    --non-interactive)
        # Add non-interactive content here
        return 0
        ;;
    --interactive)
        # Add interactive content here
        alias exelog="$HOME/.config/userScripts/logExplorer.sh"
        alias ssh1="ssh tonypup@expedition.whatbox.ca"
        alias mc="mc --nosubshell"
        
        export SHELL_MOMMYS_LITTLE="script puppy/pup/puppy/cub/dog/doggie/mutt"
        export SHELL_MOMMYS_PRONOUNS="their/his"
        export SHELL_MOMMYS_ROLES="alpha/daddy/papa/master"
        export SHELL_MOMMYS_COLOR="\e[36m"
        return 0
        ;;
    --after-loading)
        # Add content to be executed after loading bashrc

        return 0
        ;;
esac

return 1
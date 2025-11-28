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
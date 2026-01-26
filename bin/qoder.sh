#!/bin/bash

# detect wsl remote if available and open qoder in the current directory
# I personally use this as EDITOR wrapper for `workspace-manager open` command

is_wsl() {
    if uname -r | grep -q microsoft; then
        return 0
    else
        return 1
    fi
}

if is_wsl; then
	exec qoder --remote "wsl+${WSL_DISTRO_NAME}" "$(wslpath -a .)" "$@"
else
	exec qoder . "$@"
fi


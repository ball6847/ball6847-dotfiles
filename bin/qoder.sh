#!/bin/bash

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

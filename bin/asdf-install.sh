#!/bin/bash

# This script installs asdf and plugins I personally use
# For more information, visit https://asdf-vm.com/

# NOTE: this script assumes you have git and curl installed on your system, if not, just do `apt install curl git`. And asdf should be enabled in your shell

# dependencies
# - ruby (require upon installation, and must have rustc installed): 
#   $ apt install build-essential autoconf libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev
# - neovim (require when MasonInstallAll, and fzf by some plugin):
#   $ apt install python3-venv
# - tmux requires bison byacc to build from source:
#   $ apt install bison byacc

# =============================================================================
# TMUX INSTALLATION GUIDANCE
# =============================================================================
# For tmux installation, you need to install dependencies first:
#   $ brew install libevent utf8proc ncurses automake
#
# Then install tmux with utf8proc support (required for tmux 3.6+):
#   $ TMUX_CONF_OPT="--enable-utf8proc" asdf install tmux 3.6
#   $ asdf global tmux 3.6
#
# For older tmux versions that don't require utf8proc:
#   $ asdf install tmux 3.5
#   $ asdf global tmux 3.5
#
# Note: tmux 3.6+ requires explicit utf8proc configuration due to macOS
# Unicode handling requirements. The TMUX_CONF_OPT environment variable
# passes configuration flags to the tmux build process.

asdf plugin add neovim
asdf plugin add deno https://github.com/asdf-community/asdf-deno.git
asdf plugin add golang
asdf plugin add nodejs
asdf plugin add bun
asdf plugin add rust
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git
asdf plugin add k3d https://github.com/spencergilbert/asdf-k3d.git
asdf plugin add helm https://github.com/Antiarchitect/asdf-helm.git
asdf plugin add kubecm https://github.com/samhvw8/asdf-kubecm.git
asdf plugin add terraform
asdf plugin add lua-language-server
asdf plugin add task
asdf plugin add mockery https://github.com/cabify/asdf-mockery.git
asdf plugin add golangci-lint https://github.com/hypnoglow/asdf-golangci-lint.git
asdf plugin add redis-cli
asdf plugin add doppler
asdf plugin add uv

# TODO: consider removing tmux plugin as it require building from source which make build dependencies cumbersome to manage across different systems
asdf plugin add tmux https://github.com/aphecetche/asdf-tmux.git

#!/bin/bash

# This script installs asdf and plugins I personally use
# For more information, visit https://asdf-vm.com/

# NOTE: this script assumes you have git and curl installed on your system, if not, just do `apt install curl git`. And asdf should be enabled in your shell

if [ ! -d ~/.asdf ]; then
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.16.7
fi

asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git
asdf plugin add k3d https://github.com/spencergilbert/asdf-k3d.git
asdf plugin add deno https://github.com/asdf-community/asdf-deno.git
asdf plugin add helm https://github.com/Antiarchitect/asdf-helm.git
asdf plugin add kubecm https://github.com/samhvw8/asdf-kubecm.git
# asdf plugin add helix https://github.com/CSergienko/asdf-helix.git
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin add rust
asdf plugin add neovim
asdf plugin add golang
asdf plugin add nodejs
asdf plugin add terraform
asdf plugin add lua-language-server
asdf plugin add task
asdf plugin add mockery https://github.com/cabify/asdf-mockery.git
# asdf plugin add stern

# TODO: bun

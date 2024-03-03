#!/bin/bash

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git
asdf plugin add k3d https://github.com/spencergilbert/asdf-k3d.git
asdf plugin add deno https://github.com/asdf-community/asdf-deno.git
# TODO: bun, node, go, rust

#!/bin/bash

# stop the k3d cluster if it is running
k3d cluster stop default

# if --delete flag is provided, delete the k3d cluster
if [[ $1 == "--delete" ]]; then
	k3d cluster delete -c ~/.dotfiles/k3d.yml
fi

#!/bin/bash

k3d cluster create -c ~/.dotfiles/k3d.yml --kubeconfig-update-default

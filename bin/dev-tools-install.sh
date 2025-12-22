#!/bin/bash

# deno - workspace-manager and git-commmit-ai
deno install -fr --global --allow-run --allow-env --allow-read --allow-write --allow-net jsr:@ball6847/workspace-manager
deno install -fr --global --allow-run --allow-env --allow-read --allow-write --allow-net jsr:@ball6847/git-commit-ai

asdf reshim deno

go install github.com/vektra/mockery/v2@latest
go install github.com/mitranim/gow@latest
go install golang.org/x/tools/gopls@latest

asdf reshim golang

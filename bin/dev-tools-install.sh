#!/bin/bash

# deno - workspace-manager and git-commmit-ai
deno install -fr --global --allow-run --allow-env --allow-read --allow-write --allow-net jsr:@ball6847/workspace-manager
deno install -fr --global --allow-run --allow-env --allow-read --allow-write --allow-net jsr:@ball6847/git-commit-ai

asdf reshim deno


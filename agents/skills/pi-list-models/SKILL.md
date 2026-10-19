---
name: "pi-list-models"
description: "List available pi models for subagent delegation (Agent tool model param). Pipe to grep to filter."
---
```bash
pi --list-models 2>/dev/null | tail -n +2 | awk '{print $1"/"$2}'
```

Prints `provider/model` per line; pass one to the Agent tool's `model` param. Add `| grep -i <term>` to filter.

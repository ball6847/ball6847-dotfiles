# Agent Instructions for lean-skills

IMPORTANT: Always check your current working directory before running any
scripts or commands. Never run scripts from the project root directory. Use the
correct target project directory.

## Examples:

✅ DO:

```bash
cd /path/to/lean-skills
./script.sh
```

❌ DON'T:

```bash
cd /home/ball6847/.dotfiles
./deno-scripts/lean-skills/script.sh
```

After making any code changes to this project, always run these commands:

```bash
deno task fmt
deno task lint
deno task check
```

This ensures code quality and type safety. Follow these instructions carefully.

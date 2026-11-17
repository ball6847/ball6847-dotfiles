#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

python_bin=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1 &&
        "$candidate" -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >/dev/null 2>&1; then
        python_bin="$candidate"
        break
    fi
done

if [ -z "$python_bin" ]; then
    echo "python3 is required to install the dotfiles" >&2
    exit 1
fi

exec "$python_bin" "$dir/install.py" "$@"

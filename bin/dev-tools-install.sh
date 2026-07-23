#!/bin/bash

INSTALL_DENO_PKG=false
INSTALL_GO_PKG=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --deno)
            INSTALL_DENO_PKG=true
            shift
            ;;
        --golang)
            INSTALL_GO_PKG=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --deno              Install only Deno packages"
            echo "  --golang            Install only Go tools"
            echo "  --help, -h          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ "$INSTALL_DENO_PKG" = false && "$INSTALL_GO_PKG" = false ]]; then
    INSTALL_DENO_PKG=true
    INSTALL_GO_PKG=true
fi

install_from_github_repo() {
    local repo="$1"
    local go_package="$2"

    local binary_name
    binary_name=$(basename "$go_package")

    local tmp_dir="/tmp/dev-tools/$binary_name"
    local stamp_file="$tmp_dir/.stamp"

    mkdir -p "$tmp_dir"

    if [[ -d "$tmp_dir/.git" ]]; then
        git -C "$tmp_dir" fetch origin --depth 1 --quiet 2>/dev/null || true
        git -C "$tmp_dir" reset --hard origin/HEAD --quiet
    else
        rm -rf "$tmp_dir"
        git clone --depth 1 "https://github.com/$repo.git" "$tmp_dir" --quiet
    fi

    local head_commit
    head_commit=$(git -C "$tmp_dir" rev-parse HEAD 2>/dev/null)

    local binary_path
    binary_path=$(command -v "$binary_name" 2>/dev/null || true)

    if [[ -n "$binary_path" && -f "$stamp_file" && "$(cat "$stamp_file")" == "$head_commit" ]]; then
        echo "  $binary_name: up-to-date ($head_commit)"
        return 0
    fi

    echo "  $binary_name: installing from $head_commit..."

    if (cd "$tmp_dir" && go install "$go_package"); then
        echo "$head_commit" > "$stamp_file"
        echo "  ✓ $binary_name: installed"
    else
        echo "  ✗ $binary_name: install failed"
        return 1
    fi
}

if [[ "$INSTALL_DENO_PKG" = true ]]; then
    _deno_cfg=$(mktemp /tmp/deno-min-dep-age.XXXXXX.json)
    echo '{"minimumDependencyAge": 0}' > "$_deno_cfg"
    deno install --reload --no-lock --config "$_deno_cfg" --global --allow-run --allow-env --allow-read --allow-write --allow-net -fr jsr:@ball6847/workspace-manager@0.4.5
    deno install --reload --no-lock --config "$_deno_cfg" --global --allow-run --allow-env --allow-read --allow-write --allow-net --allow-sys -fr jsr:@ball6847/git-commit-ai@1.0.3
    deno install --no-lock --config "$_deno_cfg" --global --allow-read --allow-net --allow-env --allow-run -fr jsr:@ball6847/serve-md@1.0.3
    rm -f "$_deno_cfg"
    if command -v asdf &> /dev/null; then
        asdf reshim deno
    fi
fi

if [[ "$INSTALL_GO_PKG" = true ]]; then
    go install golang.org/x/tools/gopls@latest
    go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
    go install github.com/evilmartians/lefthook@latest
    go install github.com/bufbuild/buf/cmd/buf@v1.71.0
    go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
    go install github.com/ball6847/aoex@latest
    go install github.com/google/wire/cmd/wire@latest
    go install github.com/air-verse/air@latest
    # go install github.com/satococoa/wtp/v2/cmd/wtp@latest
    install_from_github_repo "ball6847/wtp" "./cmd/wtp"
    if command -v asdf &> /dev/null; then
        asdf reshim golang
    fi
fi

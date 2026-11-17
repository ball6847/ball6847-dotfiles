# Thin wrapper: the real installer is install.py (same source for Linux, macOS and Windows).

$ErrorActionPreference = "Stop"

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $python) {
    Write-Error "python is required to install the dotfiles"
    exit 1
}

$script = Join-Path $PSScriptRoot "install.py"

if ($python.Name -eq "py.exe") {
    & $python.Source -3 $script @args
}
else {
    & $python.Source $script @args
}

exit $LASTEXITCODE

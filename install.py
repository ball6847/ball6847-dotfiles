"""Cross-platform dotfiles installer for Linux, macOS and Windows."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Sequence

PYTHON_MIN = (3, 9)

# --- value objects -----------------------------------------------------------


class LinkStatus(Enum):
    CREATED = "created"
    CURRENT = "current"
    SKIPPED = "skipped"
    FAILED = "failed"


@dataclass(frozen=True)
class LinkSpec:
    source: str
    target: str = ""
    platforms: tuple = ()
    in_home: bool = False

    def applies_to(self, platform: str) -> bool:
        return not self.platforms or platform in self.platforms


@dataclass(frozen=True)
class LinkResult:
    status: LinkStatus
    message: str = ""
    spec: LinkSpec = None

    @property
    def ok(self) -> bool:
        return self.status is not LinkStatus.FAILED


@dataclass(frozen=True)
class PlatformProfile:
    name: str
    home: Path
    config_dir: Path
    local_config_dir: Path

    @classmethod
    def detect(cls, home: Path = None) -> "PlatformProfile":
        home = Path(home) if home else Path.home()
        if sys.platform == "win32":
            local = _env_path("LOCALAPPDATA", home / "AppData" / "Local")
            return cls("windows", home, home / ".config", local)
        name = "macos" if sys.platform == "darwin" else "linux"
        return cls(name, home, home / ".config", home / ".config")


@dataclass
class InstallReport:
    ran: int = 0
    failed: int = 0

    @property
    def ok(self) -> bool:
        return self.failed == 0

    def summary(self) -> str:
        return "{} step(s) done, {} failed".format(self.ran, self.failed)


# --- filesystem --------------------------------------------------------------


def is_link(path: Path) -> bool:
    if path.is_symlink():
        return True
    checker = getattr(os.path, "isjunction", None)
    return bool(checker and checker(str(path)))


def is_privilege_error(exc: OSError) -> bool:
    if isinstance(exc, PermissionError):
        return True
    return getattr(exc, "winerror", None) == 1314


def _env_path(name: str, fallback: Path) -> Path:
    value = os.environ.get(name)
    return Path(value) if value else fallback


class FileSystem:
    def __init__(self, dry_run: bool = False) -> None:
        self.dry_run = dry_run

    def exists(self, path: Path) -> bool:
        return path.exists() or is_link(path)

    def same(self, left: Path, right: Path) -> bool:
        return os.path.normcase(os.path.realpath(left)) == os.path.normcase(os.path.realpath(right))

    def identical(self, left: Path, right: Path) -> bool:
        if left.is_dir() or right.is_dir():
            return False
        try:
            return left.read_bytes() == right.read_bytes()
        except OSError:
            return False

    def mkdir(self, path: Path) -> None:
        if not self.dry_run:
            path.mkdir(parents=True, exist_ok=True)

    def remove(self, path: Path) -> None:
        if self.dry_run or not self.exists(path):
            return
        if is_link(path):
            if path.is_dir():
                os.rmdir(path)
            else:
                os.unlink(path)
        elif path.is_dir():
            shutil.rmtree(path)
        else:
            os.unlink(path)

    def move(self, source: Path, target: Path) -> None:
        if self.dry_run:
            return
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(target))

    def symlink(self, source: Path, target: Path) -> None:
        if self.dry_run:
            return
        os.symlink(source, target, target_is_directory=source.is_dir())

    def junction(self, source: Path, target: Path) -> None:
        if self.dry_run:
            return
        result = subprocess.run(
            ["cmd", "/c", "mklink", "/J", str(target), str(source)],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise OSError(result.stdout.strip() or result.stderr.strip())

    def copy(self, source: Path, target: Path) -> list:
        if self.dry_run:
            return []
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            return self._copy_tree(source, target)
        shutil.copy2(source, target)
        return []

    def _copy_tree(self, source: Path, target: Path) -> list:
        target.mkdir(parents=True, exist_ok=True)
        skipped = []
        for entry in sorted(source.iterdir()):
            destination = target / entry.name
            if is_link(entry):
                resolved = Path(os.path.realpath(entry))
                if not resolved.exists():
                    skipped.append(str(entry))
                    continue
                self.copy(resolved, destination)
            elif entry.is_dir():
                self._copy_tree(entry, destination)
            else:
                shutil.copy2(entry, destination)
        return skipped


# --- link strategies ---------------------------------------------------------


class Linker(ABC):
    name = "linker"

    def __init__(self, fs: FileSystem) -> None:
        self.fs = fs

    @abstractmethod
    def link(self, spec: LinkSpec, source: Path, target: Path) -> LinkResult:
        raise NotImplementedError

    def is_current(self, source: Path, target: Path) -> bool:
        return self.fs.same(source, target)

    def describe(self) -> str:
        return self.name


class PosixLinker(Linker):
    name = "posix-symlink"

    def link(self, spec: LinkSpec, source: Path, target: Path) -> LinkResult:
        relative = os.path.relpath(str(source), str(target.parent))
        if self.fs.dry_run:
            return LinkResult(LinkStatus.CREATED, "{} -> {}".format(target, relative), spec)
        self.fs.remove(target)
        self.fs.mkdir(target.parent)
        os.symlink(relative, str(target), target_is_directory=source.is_dir())
        return LinkResult(LinkStatus.CREATED, "{} -> {}".format(target, relative), spec)


class WindowsLinker(Linker):
    name = "windows-junction"

    def __init__(self, fs: FileSystem, fallback: "Linker") -> None:
        super().__init__(fs)
        self.fallback = fallback

    def link(self, spec: LinkSpec, source: Path, target: Path) -> LinkResult:
        if self.fs.dry_run:
            kind = "junction" if source.is_dir() else "symlink"
            return LinkResult(LinkStatus.CREATED, "{} -> {} ({})".format(target, source, kind), spec)
        self.fs.remove(target)
        self.fs.mkdir(target.parent)
        if source.is_dir():
            try:
                self.fs.junction(source, target)
            except OSError:
                result = self.fallback.link(spec, source, target)
                return LinkResult(result.status, result.message + " (junction failed)", spec)
            return LinkResult(LinkStatus.CREATED, "{} -> {} (junction)".format(target, source), spec)
        try:
            self.fs.symlink(source, target)
        except OSError as exc:
            if is_privilege_error(exc):
                result = self.fallback.link(spec, source, target)
                return LinkResult(result.status, result.message + " (no symlink privilege)", spec)
            raise
        return LinkResult(LinkStatus.CREATED, "{} -> {}".format(target, source), spec)


class CopyLinker(Linker):
    name = "copy"

    def link(self, spec: LinkSpec, source: Path, target: Path) -> LinkResult:
        if self.fs.dry_run:
            return LinkResult(LinkStatus.CREATED, "copy {} -> {}".format(source, target), spec)
        self.fs.remove(target)
        self.fs.mkdir(target.parent)
        skipped = self.fs.copy(source, target)
        message = "copied {} -> {}".format(source, target)
        if skipped:
            message += " (skipped {} broken link(s))".format(len(skipped))
        return LinkResult(LinkStatus.CREATED, message, spec)

    def is_current(self, source: Path, target: Path) -> bool:
        return self.fs.identical(source, target)


class LinkerFactory:
    def create(self, profile: PlatformProfile, fs: FileSystem, force_copy: bool = False) -> Linker:
        if force_copy:
            return CopyLinker(fs)
        if profile.name == "windows":
            return WindowsLinker(fs, CopyLinker(fs))
        return PosixLinker(fs)

    def can_symlink(self) -> bool:
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / "probe"
            source.write_text("probe")
            try:
                os.symlink(str(source), str(Path(folder) / "link"))
            except OSError:
                return False
            return True


# --- services ----------------------------------------------------------------


class BackupManager:
    def __init__(self, fs: FileSystem, home: Path, backup_dir: Path) -> None:
        self.fs = fs
        self.home = home
        self.backup_dir = backup_dir

    def backup(self, target: Path) -> Path:
        if not self.fs.exists(target):
            return None
        try:
            parts = list(target.relative_to(self.home).parts)
        except ValueError:
            return None
        if parts and parts[0].startswith("."):
            parts[0] = parts[0][1:]
        destination = self.backup_dir.joinpath(*parts)
        self.fs.remove(destination)
        self.fs.mkdir(destination.parent)
        self.fs.move(target, destination)
        return destination


class Reporter:
    def __init__(self, stream=None, verbose: bool = False) -> None:
        self.stream = stream or sys.stdout
        self.verbose = verbose

    def info(self, message: str) -> None:
        print(message, file=self.stream)

    def detail(self, message: str) -> None:
        if self.verbose and message:
            print("  " + message, file=self.stream)

    def warn(self, message: str) -> None:
        print("warning: " + message, file=self.stream)

    def error(self, message: str) -> None:
        print("error: " + message, file=sys.stderr)


class Manifest:
    def __init__(self, specs: Sequence[LinkSpec]) -> None:
        self.specs = tuple(specs)

    def for_platform(self, platform: str) -> list:
        return [spec for spec in self.specs if spec.applies_to(platform)]


# --- tasks -------------------------------------------------------------------


@dataclass(frozen=True)
class InstallContext:
    repo: Path
    home: Path
    profile: PlatformProfile
    manifest: Manifest
    linker: Linker
    backup: BackupManager
    reporter: Reporter
    fs: FileSystem
    xdg_config_home: Path = None

    def resolve_source(self, spec: LinkSpec) -> Path:
        base = self.home if spec.in_home else self.repo
        return base / spec.source

    def resolve_target(self, spec: LinkSpec) -> Path:
        raw = spec.target if spec.target else "." + spec.source
        expanded = Path(os.path.expandvars(raw))
        if expanded.is_absolute():
            return expanded
        return self.home / expanded

    def config_dir_for(self, app: str) -> Path:
        if self.xdg_config_home:
            return self.xdg_config_home / app
        return self.profile.config_dir / app


class InstallTask(ABC):
    def __init__(self, name: str) -> None:
        self.name = name

    @abstractmethod
    def execute(self, ctx: InstallContext) -> LinkResult:
        raise NotImplementedError


class LinkTask(InstallTask):
    def __init__(self, spec: LinkSpec) -> None:
        super().__init__("link " + spec.source)
        self.spec = spec

    def execute(self, ctx: InstallContext) -> LinkResult:
        source = ctx.resolve_source(self.spec)
        target = ctx.resolve_target(self.spec)
        if not source.exists():
            return LinkResult(LinkStatus.SKIPPED, "source missing: {}".format(source), self.spec)
        if ctx.linker.is_current(source, target):
            return LinkResult(LinkStatus.CURRENT, "already linked", self.spec)
        destination = ctx.backup.backup(target)
        if destination:
            ctx.reporter.detail("backed up {} -> {}".format(target, destination))
        return ctx.linker.link(self.spec, source, target)


class NestedLinkCleanupTask(InstallTask):
    def __init__(self) -> None:
        super().__init__("remove nested self-links")

    def execute(self, ctx: InstallContext) -> LinkResult:
        removed = []
        candidates = [ctx.repo / "agents" / "agents"]
        for parent in sorted(ctx.repo.glob("config/*")):
            candidates.append(parent / parent.name)
        for candidate in candidates:
            if ctx.fs.exists(candidate) and is_link(candidate):
                ctx.fs.remove(candidate)
                removed.append(str(candidate))
        if not removed:
            return LinkResult(LinkStatus.CURRENT, "nothing to clean")
        return LinkResult(LinkStatus.CREATED, "removed " + ", ".join(removed))


class LegacyOpencodeTask(InstallTask):
    def __init__(self) -> None:
        super().__init__("drop legacy opencode.json")

    def execute(self, ctx: InstallContext) -> LinkResult:
        legacy = ctx.home / ".opencode" / "opencode.json"
        if not ctx.fs.exists(legacy):
            return LinkResult(LinkStatus.CURRENT, "nothing to drop")
        ctx.fs.remove(legacy)
        return LinkResult(LinkStatus.CREATED, "removed " + str(legacy))


class GitResetTask(InstallTask):
    def __init__(self, path: str = "config/kitty") -> None:
        super().__init__("git checkout " + path)
        self.path = path

    def execute(self, ctx: InstallContext) -> LinkResult:
        if ctx.fs.dry_run:
            return LinkResult(LinkStatus.SKIPPED, "dry run")
        result = subprocess.run(
            ["git", "-C", str(ctx.repo), "checkout", "--", self.path],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            detail = result.stderr.strip() or result.stdout.strip() or "git checkout failed"
            return LinkResult(LinkStatus.FAILED, detail)
        return LinkResult(LinkStatus.CURRENT, "restored " + self.path)


class RioTask(InstallTask):
    def __init__(self) -> None:
        super().__init__("link rio config")

    def execute(self, ctx: InstallContext) -> LinkResult:
        repo_config = ctx.repo / "config" / "rio"
        if ctx.profile.name == "windows":
            source = repo_config / "windows.toml"
            config_dir = ctx.profile.local_config_dir / "rio"
        else:
            source = repo_config / ("macos.toml" if ctx.profile.name == "macos" else "linux.toml")
            config_dir = ctx.config_dir_for("rio")
        if not source.exists():
            return LinkResult(LinkStatus.SKIPPED, "source missing: {}".format(source))
        if ctx.fs.same(config_dir, repo_config):
            target = repo_config / "config.toml"
        else:
            target = config_dir / "config.toml"
        ctx.fs.mkdir(config_dir)
        return ctx.linker.link(LinkSpec("config/rio/config.toml"), source, target)


# --- orchestration -----------------------------------------------------------


class Installer:
    def __init__(self, ctx: InstallContext, tasks: Sequence[InstallTask]) -> None:
        self.ctx = ctx
        self.tasks = list(tasks)

    def run(self) -> InstallReport:
        report = InstallReport()
        for task in self.tasks:
            self.ctx.reporter.info("[" + task.name + "]")
            try:
                result = task.execute(self.ctx)
            except Exception as exc:
                result = LinkResult(LinkStatus.FAILED, "{}: {}".format(type(exc).__name__, exc))
            if result.status is LinkStatus.FAILED:
                report.failed += 1
                self.ctx.reporter.error(self._label(result))
                continue
            if result.status is LinkStatus.SKIPPED:
                self.ctx.reporter.warn(self._label(result))
                continue
            report.ran += 1
            self.ctx.reporter.detail(self._label(result))
        return report

    def _label(self, result: LinkResult) -> str:
        if result.spec is None:
            return result.message
        return "{}: {}".format(result.spec.source, result.message)


# --- manifest ----------------------------------------------------------------


def default_specs() -> list:
    shared = [
        "profile",
        "bashrc",
        "bash_aliases",
        "gitconfig",
        "ansible.cfg",
        "tool-versions",
        "config/nvim",
        "config/opencode",
        "config/git-commit-ai",
        "config/kitty/kitty.conf",
        "pi/agent/settings.json",
        "pi/agent/models.json",
        "pi/agent/configs",
        "pi/agent/agents",
        "pi/agent/extensions",
        "pi/agent/pstack",
        "pi/agent/APPEND_SYSTEM.md",
        "pi/agent/keybindings.json",
        "pi/agent/mcode-token.mjs",
        "prime/agent/settings.json",
        "prime/agent/models.json",
        "prime/agent/keybindings.json",
        "qwen/settings.json",
        "agents",
        "kimi",
        "vibe",
        "agent-browser",
        "qoder",
        "gemini",
        "dsh/settings.yaml",
    ]
    unix_only = [
        "zshrc",
        "direnvrc",
        "xbindkeysrc",
        "tmux.conf",
        "pip/pip.conf",
        "config/terminator",
        "config/agent-of-empires",
        "config/rio",
        "config/vite",
    ]
    specs = [LinkSpec(source=path) for path in shared]
    specs += [LinkSpec(source=path, platforms=("linux", "macos")) for path in unix_only]
    specs.append(LinkSpec(source="config/ghostty", platforms=("linux", "macos")))
    specs.append(LinkSpec(source="config/ghostty", target="$APPDATA/ghostty", platforms=("windows",)))
    specs.append(LinkSpec(source=".agents/skills", target=".claude/skills", in_home=True))
    specs.append(
        LinkSpec(
            source=".config/agent-of-empires",
            target=".agent-of-empires",
            platforms=("macos",),
            in_home=True,
        )
    )
    return specs


def build_tasks(ctx: InstallContext, include_rio: bool = True) -> list:
    tasks = [LinkTask(spec) for spec in ctx.manifest.for_platform(ctx.profile.name)]
    tasks.append(NestedLinkCleanupTask())
    tasks.append(LegacyOpencodeTask())
    tasks.append(GitResetTask())
    if include_rio:
        tasks.append(RioTask())
    return tasks


# --- entry point -------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Install the dotfiles into the home directory")
    parser.add_argument("--repo", type=Path, default=None, help="dotfiles repository (default: this file's folder)")
    parser.add_argument("--home", type=Path, default=None, help="home directory to install into")
    parser.add_argument("--dry-run", action="store_true", help="report what would happen, change nothing")
    parser.add_argument("--copy-mode", action="store_true", help="copy files instead of linking them")
    parser.add_argument("--no-rio", action="store_true", help="skip the rio config link")
    parser.add_argument("--verbose", action="store_true", help="print every action")
    return parser


def main(argv: Sequence[str] = None) -> int:
    if sys.version_info < PYTHON_MIN:
        print("python {}.{} or newer is required".format(*PYTHON_MIN), file=sys.stderr)
        return 2
    args = build_parser().parse_args(argv)
    repo = (args.repo or Path(__file__).resolve().parent).resolve()
    home = (args.home or Path.home()).resolve()
    profile = PlatformProfile.detect(home)
    reporter = Reporter(verbose=args.verbose)
    fs = FileSystem(dry_run=args.dry_run)
    factory = LinkerFactory()
    linker = factory.create(profile, fs, force_copy=args.copy_mode)
    manifest = Manifest(default_specs())
    backup = BackupManager(fs, home, home / ".dotfiles_old")
    xdg = os.environ.get("XDG_CONFIG_HOME")
    ctx = InstallContext(
        repo=repo,
        home=home,
        profile=profile,
        manifest=manifest,
        linker=linker,
        backup=backup,
        reporter=reporter,
        fs=fs,
        xdg_config_home=Path(xdg) if xdg else None,
    )
    reporter.info("dotfiles installer")
    reporter.info("repo: {}".format(repo))
    reporter.info("home: {}".format(home))
    reporter.info("platform: {}".format(profile.name))
    reporter.info("linker: {}".format(linker.describe()))
    if args.dry_run:
        reporter.info("dry run: nothing is written")
    if profile.name == "windows" and not factory.can_symlink():
        reporter.warn("symlinks are not permitted here, file links fall back to copies")
    fs.mkdir(backup.backup_dir)
    report = Installer(ctx, build_tasks(ctx, include_rio=not args.no_rio)).run()
    reporter.info(report.summary())
    return 0 if report.ok else 1


if __name__ == "__main__":
    sys.exit(main())

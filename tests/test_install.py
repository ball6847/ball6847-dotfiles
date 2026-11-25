import io
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import install


class InstallerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        self.repo = root / "repo"
        self.home = root / "home"
        (self.repo / "config" / "nvim").mkdir(parents=True)
        (self.repo / "bashrc").write_text("export A=1\n")
        (self.repo / "config" / "nvim" / "init.lua").write_text("vim.o.number = true\n")
        self.home.mkdir()
        (self.home / ".bashrc").write_text("old content\n")
        self.profile = install.PlatformProfile.detect(self.home)
        self.fs = install.FileSystem()
        self.reporter = install.Reporter(stream=io.StringIO())
        self.linker = install.LinkerFactory().create(self.profile, self.fs)
        self.manifest = install.Manifest(
            [install.LinkSpec(source="bashrc"), install.LinkSpec(source="config/nvim")]
        )
        self.backup = install.BackupManager(self.fs, self.home, self.home / ".dotfiles_old")
        self.ctx = install.InstallContext(
            repo=self.repo,
            home=self.home,
            profile=self.profile,
            manifest=self.manifest,
            linker=self.linker,
            backup=self.backup,
            reporter=self.reporter,
            fs=self.fs,
        )
        self.tasks = [install.LinkTask(spec) for spec in self.manifest.for_platform(self.profile.name)]

    def run_tasks(self):
        return install.Installer(self.ctx, self.tasks).run()

    def assert_bashrc_points_at_repo(self):
        target = self.home / ".bashrc"
        if install.LinkerFactory().can_symlink():
            self.assertEqual(os.path.realpath(target), os.path.realpath(self.repo / "bashrc"))
        else:
            self.assertEqual(target.read_text(), (self.repo / "bashrc").read_text())

    def test_links_file_and_directory(self):
        report = self.run_tasks()
        self.assertTrue(report.ok)
        self.assert_bashrc_points_at_repo()
        self.assertTrue((self.home / ".config" / "nvim" / "init.lua").exists())

    def test_existing_file_is_backed_up(self):
        self.run_tasks()
        backup = self.home / ".dotfiles_old" / "bashrc"
        self.assertTrue(backup.exists())
        self.assertEqual(backup.read_text(), "old content\n")

    def test_second_run_keeps_the_link(self):
        self.run_tasks()
        report = self.run_tasks()
        self.assertTrue(report.ok)
        self.assert_bashrc_points_at_repo()
        self.assertTrue((self.home / ".dotfiles_old" / "bashrc").exists())

    def test_missing_source_is_skipped(self):
        self.ctx = install.InstallContext(
            repo=self.repo,
            home=self.home,
            profile=self.profile,
            manifest=install.Manifest([install.LinkSpec(source="nope")]),
            linker=self.linker,
            backup=self.backup,
            reporter=self.reporter,
            fs=self.fs,
        )
        report = install.Installer(
            self.ctx, [install.LinkTask(install.LinkSpec(source="nope"))]
        ).run()
        self.assertTrue(report.ok)
        self.assertEqual(report.ran, 0)

    def test_manifest_filters_by_platform(self):
        manifest = install.Manifest(
            [
                install.LinkSpec(source="a", platforms=("linux",)),
                install.LinkSpec(source="b"),
            ]
        )
        self.assertEqual([spec.source for spec in manifest.for_platform("macos")], ["b"])
        self.assertEqual([spec.source for spec in manifest.for_platform("linux")], ["a", "b"])

    def test_factory_picks_posix_linker_off_windows(self):
        profile = install.PlatformProfile(
            "linux", self.home, self.home / ".config", self.home / ".config"
        )
        linker = install.LinkerFactory().create(profile, self.fs)
        self.assertIsInstance(linker, install.PosixLinker)

    def test_copy_mode_copies_instead_of_linking(self):
        linker = install.LinkerFactory().create(self.profile, self.fs, force_copy=True)
        self.assertIsInstance(linker, install.CopyLinker)
        result = linker.link(
            install.LinkSpec(source="bashrc"),
            self.repo / "bashrc",
            self.home / ".copied-bashrc",
        )
        self.assertTrue(result.ok)
        self.assertEqual((self.home / ".copied-bashrc").read_text(), "export A=1\n")

    def test_variant_link_task_links_platform_source(self):
        profile = install.PlatformProfile(
            "macos", self.home, self.home / ".config", self.home / ".config"
        )
        ctx = install.InstallContext(
            repo=self.repo,
            home=self.home,
            profile=profile,
            manifest=self.manifest,
            linker=install.LinkerFactory().create(profile, self.fs),
            backup=self.backup,
            reporter=self.reporter,
            fs=self.fs,
        )
        spec = install.VariantLinkSpec(
            name="link platform config",
            app="ghostty",
            selector="platform.ghostty",
            sources={"macos": "macos.ghostty"},
            targets={"macos": "{config_dir}"},
        )
        (self.repo / "config" / "ghostty").mkdir(parents=True)
        (self.repo / "config" / "ghostty" / "macos.ghostty").write_text("font-size = 13\n")
        result = install.VariantLinkTask(spec).execute(ctx)
        self.assertTrue(result.ok)
        target = self.home / ".config" / "ghostty" / "platform.ghostty"
        self.assertEqual(target.read_text(), "font-size = 13\n")

    def test_variant_spec_selects_platform_and_repo_local_target(self):
        spec = install.VariantLinkSpec(
            name="link platform config",
            app="rio",
            selector="config.toml",
            sources={"linux": "linux.toml", "windows": "windows.toml"},
            targets={
                "linux": "{config_dir}",
                "windows": "{local_config_dir}/rio",
            },
        )
        for platform in ("linux", "windows"):
            with self.subTest(platform=platform):
                profile = install.PlatformProfile(
                    platform,
                    self.home,
                    self.home / ".config",
                    self.home / "AppData" / "Local",
                )
                ctx = install.InstallContext(
                    repo=self.repo,
                    home=self.home,
                    profile=profile,
                    manifest=self.manifest,
                    linker=install.LinkerFactory().create(profile, self.fs),
                    backup=self.backup,
                    reporter=self.reporter,
                    fs=self.fs,
                    xdg_config_home=self.repo / "config",
                )
                source, target = spec.resolve(ctx)
                self.assertEqual(source.name, platform + ".toml")
                if platform == "linux":
                    self.assertEqual(target, self.repo / "config" / "rio" / "config.toml")
                else:
                    self.assertEqual(
                        target, self.home / "AppData" / "Local" / "rio" / "config.toml"
                    )

    @mock.patch.dict(os.environ, {"APPDATA": ""})
    def test_default_variants_resolve_for_each_platform(self):
        expected = {
            "linux": {
                "rio": ("linux.toml", Path("/home/u/.config/rio/config.toml")),
                "ghostty": (
                    "linux.ghostty",
                    Path("/home/u/.config/ghostty/platform.ghostty"),
                ),
            },
            "macos": {
                "rio": ("macos.toml", Path("/home/u/.config/rio/config.toml")),
                "ghostty": (
                    "macos.ghostty",
                    Path("/home/u/.config/ghostty/platform.ghostty"),
                ),
            },
            "windows": {
                "rio": ("windows.toml", Path("/home/u/AppData/Local/rio/config.toml")),
                "ghostty": (
                    "windows.ghostty",
                    Path("/home/u/AppData/Roaming/ghostty/platform.ghostty"),
                ),
            },
        }
        for platform, apps in expected.items():
            for app, (source_name, target) in apps.items():
                with self.subTest(platform=platform, app=app):
                    profile = install.PlatformProfile(
                        platform,
                        Path("/home/u"),
                        Path("/home/u/.config"),
                        Path("/home/u/AppData/Local"),
                    )
                    ctx = install.InstallContext(
                        repo=Path("/repo"),
                        home=Path("/home/u"),
                        profile=profile,
                        manifest=install.Manifest(
                            install.default_specs(), install.default_variants()
                        ),
                        linker=install.LinkerFactory().create(profile, self.fs),
                        backup=self.backup,
                        reporter=self.reporter,
                        fs=self.fs,
                    )
                    spec = next(
                        item for item in ctx.manifest.variants if item.app == app
                    )
                    resolved_source, resolved_target = spec.resolve(ctx)
                    self.assertEqual(resolved_source.name, source_name)
                    self.assertEqual(resolved_target, target)

    def test_build_tasks_filters_rio_variant(self):
        ctx = install.InstallContext(
            repo=self.repo,
            home=self.home,
            profile=self.profile,
            manifest=install.Manifest(
                install.default_specs(), install.default_variants()
            ),
            linker=self.linker,
            backup=self.backup,
            reporter=self.reporter,
            fs=self.fs,
        )
        with_rio = [
            task.name
            for task in install.build_tasks(ctx)
            if isinstance(task, install.VariantLinkTask)
        ]
        without_rio = [
            task.name
            for task in install.build_tasks(ctx, include_rio=False)
            if isinstance(task, install.VariantLinkTask)
        ]
        self.assertEqual(with_rio, ["link rio config", "link ghostty platform config"])
        self.assertEqual(without_rio, ["link ghostty platform config"])


if __name__ == "__main__":
    unittest.main()

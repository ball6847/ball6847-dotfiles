import io
import os
import sys
import tempfile
import unittest
from pathlib import Path

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


if __name__ == "__main__":
    unittest.main()

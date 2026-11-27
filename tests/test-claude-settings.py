"""Verify that ~/.claude/settings.json is installed as a copy, not a symlink.

Claude Code が実行中に settings.json を書き換えても、dotfiles リポジトリの作業ツリーを
汚さないことを、使い捨ての HOME で実際の dotfiles.sh を動かして確かめる。
"""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
DOTFILES = ROOT / "scripts" / "dotfiles.sh"
MODE = "work"
SOURCE = ROOT / "src" / ".claude" / f"settings.{MODE}.json"


class ClaudeSettingsCopyTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-claude-settings-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.dest = self.home / ".claude" / "settings.json"
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "DOTFILES_MODE": MODE,
            "NO_COLOR": "1",
        }
        self.source_bytes = SOURCE.read_bytes()

    def run_dotfiles(self, command):
        result = subprocess.run(
            ["bash", str(DOTFILES), command],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def status_line(self):
        output = self.run_dotfiles("status")
        lines = [line for line in output.splitlines() if line.startswith(".claude/settings.json")]
        self.assertEqual(len(lines), 1, output)
        return lines[0]

    def backups(self):
        return list((self.home / ".dotfiles_backup").rglob("settings.json"))

    def test_legacy_symlink_is_replaced_by_copy(self):
        self.dest.parent.mkdir(parents=True)
        self.dest.symlink_to(SOURCE)

        self.run_dotfiles("install")

        self.assertFalse(self.dest.is_symlink())
        self.assertEqual(self.dest.read_bytes(), self.source_bytes)
        self.assertEqual(len(self.backups()), 1)

    def test_runtime_edit_stays_out_of_repository(self):
        self.run_dotfiles("install")
        self.assertIn("OK", self.status_line())

        # Install again: nothing changes and nothing is backed up.
        self.run_dotfiles("install")
        self.assertEqual(self.backups(), [])

        # Simulate Claude Code rewriting its settings (e.g. /effort).
        self.dest.write_text(self.dest.read_text() + "\n")
        self.assertEqual(SOURCE.read_bytes(), self.source_bytes)
        self.assertIn("DIFFERS", self.status_line())

        # Install restores the repository version and keeps the edited copy as a backup.
        self.run_dotfiles("install")
        self.assertEqual(self.dest.read_bytes(), self.source_bytes)
        self.assertEqual(len(self.backups()), 1)

    def test_uninstall_keeps_modified_copy(self):
        self.run_dotfiles("install")
        self.dest.write_text(self.dest.read_text() + "\n")

        self.run_dotfiles("uninstall")
        self.assertTrue(self.dest.exists())

        self.run_dotfiles("install")
        self.run_dotfiles("uninstall")
        self.assertFalse(self.dest.exists())


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""レビュー対象と CLI への権限制限を実際の Git リポジトリで検証する。"""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "src/.claude/skills/claude-review/scripts/review.py"


class ReviewTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        fake = self.bin / "claude"
        fake.write_text(f"#!{sys.executable}\n" + '''import json, os, pathlib, sys
if '--version' in sys.argv:
    print(os.environ.get('CLAUDE_VERSION', '2.1.325 (Claude Code)'))
    sys.exit(0)
pathlib.Path(os.environ['CAPTURE']).write_text(json.dumps({'args': sys.argv[1:], 'prompt': sys.stdin.read()}))
if os.environ.get('EMPTY') != '1':
    print('指摘なし')
sys.exit(int(os.environ.get('FAIL', '0')))
''')
        fake.chmod(0o755)
        self.capture = self.root / "capture.json"
        self.env = {**{k: v for k, v in os.environ.items() if not k.startswith("GIT_")}, "PATH": f"{self.bin}{os.pathsep}{os.environ['PATH']}", "CAPTURE": str(self.capture)}
        self.git("init", "-b", "main")
        self.git("config", "user.email", "test@example.com")
        self.git("config", "user.name", "テスト")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.autocrlf", "false")
        self.config = self.root / "claude-config"
        self.config.mkdir()
        (self.config / "settings.json").write_text(json.dumps({"permissions": {"deny": ["Read(./private.txt)"]}}))
        self.env["CLAUDE_CONFIG_DIR"] = str(self.config)
        (self.repo / "app.py").write_text("x = 1\n")
        self.git("add", "app.py")
        self.git("-c", "core.hooksPath=/dev/null", "commit", "-m", "初期状態")

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.repo, check=True, capture_output=True, env=self.env)

    def run_review(self, *args, cwd=None):
        return subprocess.run([sys.executable, str(SCRIPT), *args], cwd=cwd or self.repo,
                              env=self.env, capture_output=True, text=True)

    def test_no_diff_does_not_start_claude(self):
        result = self.run_review()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("差分がない", result.stdout)
        self.assertFalse(self.capture.exists())

    def test_all_change_types_and_read_only_arguments(self):
        self.git("switch", "-c", "feature")
        (self.repo / "app.py").write_text("x = 2\n")
        self.git("add", "app.py")
        self.git("-c", "core.hooksPath=/dev/null", "commit", "-m", "変更")
        (self.repo / "app.py").write_text("x = 3\n")
        self.git("add", "app.py")
        (self.repo / "app.py").write_text("x = 4\n")
        (self.repo / "new file.py").write_text("new_value = 5\n")
        (self.repo / ".gitignore").write_text("secret.txt\n")
        (self.repo / "secret.txt").write_text("do-not-send\n")
        subdir = self.repo / "subdir"
        subdir.mkdir()
        before = self.git("status", "--porcelain=v1", "--untracked-files=all").stdout
        result = self.run_review(cwd=subdir)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("指摘なし", result.stdout)
        captured = json.loads(self.capture.read_text())
        for text in ("+x = 2", "+x = 3", "+x = 4", "+new_value = 5"):
            self.assertIn(text, captured["prompt"])
        self.assertNotIn("do-not-send", captured["prompt"])
        args = captured["args"]
        for flag, value in (("--tools", "Read,Glob,Grep"), ("--permission-mode", "dontAsk"),
                            ("--disallowedTools", "mcp__*"), ("--setting-sources", "")):
            self.assertEqual(args[args.index(flag) + 1], value)
        self.assertIn("--disable-slash-commands", args)
        self.assertIn("--strict-mcp-config", args)
        settings = json.loads(args[args.index("--settings") + 1])
        self.assertTrue(settings["disableAllHooks"])
        self.assertEqual(settings["permissions"]["deny"], ["Read(./private.txt)"])
        self.assertTrue(settings["permissions"]["blockReadsOutsideWorkingDirectories"])
        self.assertEqual(args[args.index("--permission-prompts") + 1], "none")
        self.assertEqual(before, self.git("status", "--porcelain=v1", "--untracked-files=all").stdout)

    def test_explicit_base(self):
        self.git("branch", "baseline")
        (self.repo / "app.py").write_text("x = 8\n")
        self.git("add", "app.py")
        self.git("-c", "core.hooksPath=/dev/null", "commit", "-m", "変更")
        self.assertIn("差分がない", self.run_review().stdout)
        self.assertEqual(self.run_review("baseline").returncode, 0)
        self.assertIn("+x = 8", json.loads(self.capture.read_text())["prompt"])

    def test_invalid_base_does_not_start_claude(self):
        self.assertNotEqual(self.run_review("missing").returncode, 0)
        self.assertFalse(self.capture.exists())

    def test_old_claude_is_rejected(self):
        (self.repo / "app.py").write_text("x = 8\n")
        self.env["CLAUDE_VERSION"] = "2.1.39 (Claude Code)"
        self.assertNotEqual(self.run_review().returncode, 0)
        self.assertFalse(self.capture.exists())

    def test_nested_repository_is_not_silently_omitted(self):
        nested = self.repo / "nested"
        nested.mkdir()
        subprocess.run(["git", "init", "-b", "main"], cwd=nested, env=self.env, check=True, capture_output=True)
        (nested / "file.txt").write_text("nested content\n")
        result = self.run_review()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("入れ子リポジトリ", result.stderr)
        self.assertFalse(self.capture.exists())

    def test_invalid_permissions_fail_before_review(self):
        (self.repo / "app.py").write_text("x = 8\n")
        (self.config / "settings.json").write_text('{"permissions":{"deny":"Read"}}')
        self.assertNotEqual(self.run_review().returncode, 0)
        self.assertFalse(self.capture.exists())

    def test_project_denies_are_preserved(self):
        (self.repo / "app.py").write_text("x = 8\n")
        (self.repo / ".claude").mkdir()
        (self.repo / ".claude/settings.local.json").write_text(json.dumps({"permissions": {"deny": ["Read(./project-secret.txt)"]}}))
        self.assertEqual(self.run_review().returncode, 0)
        args = json.loads(self.capture.read_text())["args"]
        settings = json.loads(args[args.index("--settings") + 1])
        self.assertEqual(settings["permissions"]["deny"], ["Read(./private.txt)", "Read(./project-secret.txt)"])

    def test_claude_error_is_not_success(self):
        (self.repo / "app.py").write_text("x = 7\n")
        self.env["FAIL"] = "7"
        self.assertEqual(self.run_review().returncode, 7)

    def test_empty_response_is_not_success(self):
        (self.repo / "app.py").write_text("x = 9\n")
        self.env["EMPTY"] = "1"
        self.assertNotEqual(self.run_review().returncode, 0)


if __name__ == "__main__":
    unittest.main()

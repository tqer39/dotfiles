"""Exercise task ordering and argument forwarding without changing real tools or worktrees."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MISE = shutil.which("mise")


class MiseTasksTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="mise-tasks-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "project"
        self.project.mkdir()
        # Test the current checkout's task definitions, without installing tools.
        config = (ROOT / "mise.toml").read_text()
        (self.project / "mise.toml").write_text(config[config.index("[tasks.help]"):])
        shutil.copyfile(ROOT / "Makefile", self.project / "Makefile")
        self.log = self.root / "calls.jsonl"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for command in ("mise", "pnpm", "lefthook", "git", "code", "cf-vault"):
            stub = self.bin / command
            stub.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "name = Path(sys.argv[0]).name\n"
                "with open(os.environ['TASK_TEST_LOG'], 'a') as out:\n"
                "    out.write(json.dumps([name, *sys.argv[1:]]) + '\\n')\n"
                "if name == os.environ.get('TASK_TEST_FAIL'):\n"
                "    sys.exit(7)\n"
            )
            stub.chmod(0o755)
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "MISE_CONFIG_DIR": str(self.root / "config"),
            "MISE_STATE_DIR": str(self.root / "state"),
            "MISE_CACHE_DIR": str(self.root / "cache"),
            "MISE_TRUSTED_CONFIG_PATHS": str(self.project),
            "TASK_TEST_LOG": str(self.log),
        }

    def run_task(self, *args, success=True):
        result = subprocess.run(
            [MISE, "run", "--skip-tools", *args], cwd=self.project,
            env=self.env, capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_setup_order(self):
        self.assertEqual(self.run_task("setup"), [
            ["mise", "install"], ["pnpm", "install", "--frozen-lockfile"],
            ["lefthook", "install"],
        ])

    def test_setup_stops_on_failure(self):
        self.env["TASK_TEST_FAIL"] = "pnpm"
        self.assertEqual(self.run_task("setup", success=False), [
            ["mise", "install"], ["pnpm", "install", "--frozen-lockfile"],
        ])

    def test_lint_hook(self):
        self.assertEqual(self.run_task("lint-hook", "markdownlint"), [
            ["lefthook", "run", "pre-commit", "--commands", "markdownlint", "--all-files"],
        ])

    def test_terraform_directory(self):
        self.assertEqual(self.run_task("tf", "-chdir=prod/dns", "plan"), [
            ["cf-vault", "exec", "dotfiles", "--", "aws-vault", "exec", "portfolio",
             "--", "terraform", "-chdir=infra/terraform/envs/prod/dns", "plan"],
        ])

    def test_worktree_new(self):
        calls = self.run_task("wt-new", "feature")
        self.assertEqual(len(calls), 1)
        command, worktree, action, path, flag, branch = calls[0]
        self.assertEqual([command, worktree, action, flag], ["git", "worktree", "add", "-b"])
        self.assertRegex(branch, r"^feature-\d{6}-[0-9a-f]{6}$")
        self.assertEqual(path, f"../dotfiles-worktrees/{branch}")

    def test_worktree_arguments_are_literal(self):
        name = "name with spaces; echo unexpected"
        self.assertEqual(self.run_task("wt-code", name), [["code", f"../dotfiles-worktrees/{name}"]])

    def test_worktree_force(self):
        self.assertEqual(self.run_task("wt-rm-force", "feature"), [
            ["git", "worktree", "remove", "--force", "../dotfiles-worktrees/feature"],
        ])

    def test_missing_remove_argument(self):
        self.assertEqual(self.run_task("wt-rm", success=False), [["git", "worktree", "list"]])


if __name__ == "__main__":
    unittest.main()

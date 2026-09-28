"""Exercise the Bash/Zsh wrappers with real Git and a recording Claude stub."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "src/.shell_common").read_text()
WRAPPERS = SOURCE[SOURCE.index("# Launch Claude with defaults"):SOURCE.index("# AI coding CLIs\n")]


class AgentWorktreeTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="agent-worktree-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / "repo with spaces"
        self.repo.mkdir()
        self.git("init", "-q")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "commit", "--allow-empty", "-qm", "initial")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "launch.json"
        stub = self.bin / "claude"
        stub.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "Path(os.environ['LAUNCH_LOG']).write_text(json.dumps([os.getcwd(), sys.argv[1:]]))\n"
            "sys.exit(int(os.environ.get('LAUNCH_EXIT', '0')))\n"
        )
        stub.chmod(0o755)
        picker = self.bin / "fzf"
        picker.write_text(
            "#!/usr/bin/env python3\n"
            "import os, sys\n"
            "paths = sys.stdin.read().splitlines()\n"
            "selected = os.environ['PICK_WORKTREE']\n"
            "if not selected or selected not in paths:\n"
            "    sys.exit(1)\n"
            "print(selected)\n"
        )
        picker.chmod(0o755)
        self.script = self.root / "wrappers.sh"
        self.script.write_text(WRAPPERS + '\nclaudewt "$@"\n')
        self.env = {**os.environ, "PATH": f"{self.bin}:{os.environ['PATH']}",
                    "LAUNCH_LOG": str(self.log), "PICK_WORKTREE": ""}

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.repo, check=True,
                              capture_output=True, text=True).stdout

    def launch(self, shell, *args, cwd=None, expected=0):
        self.log.unlink(missing_ok=True)
        result = subprocess.run([shell, str(self.script), *args], cwd=cwd or self.repo,
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return json.loads(self.log.read_text()) if self.log.exists() else None

    def test_wrappers_in_bash_and_zsh(self):
        for shell in ("bash", "zsh"):
            if not shutil.which(shell):
                continue
            with self.subTest(shell=shell):
                nested = self.repo / "nested"
                nested.mkdir(exist_ok=True)
                before = self.git("worktree", "list", "--porcelain")
                cwd, args = self.launch(shell, "new", "feature-demo", "prompt with spaces", cwd=nested)
                self.assertEqual(cwd, str(self.repo))
                self.assertEqual(args, ["--permission-mode", "auto", "--name", "feature-demo",
                                        "--worktree", "feature-demo", "prompt with spaces"])
                # Only Claude may create/manage the new worktree, not the wrapper.
                self.assertEqual(self.git("worktree", "list", "--porcelain"), before)
                self.assertFalse((self.root / "repo with spaces-worktrees").exists())

                for options in (["--permission-mode", "plan", "--name", "custom name"],
                                ["--permission-mode=plan", "-n", "custom name"]):
                    _, args = self.launch(shell, "new", "demo", *options)
                    self.assertEqual(args, ["--worktree", "demo", *options])

                selected = self.root / f"existing worktree {shell}"
                self.git("worktree", "add", "-qb", f"existing-{shell}", str(selected))
                self.env["PICK_WORKTREE"] = str(selected)
                for command in ([], ["list"]):
                    cwd, args = self.launch(shell, *command)
                    self.assertEqual(cwd, str(selected))
                    self.assertEqual(args, ["--permission-mode", "auto", "--name", selected.name])
                _, args = self.launch(shell, "list", "--resume", "saved session")
                self.assertEqual(args, ["--permission-mode", "auto", "--resume", "saved session"])

                self.env["PICK_WORKTREE"] = ""
                self.assertIsNone(self.launch(shell, "list", expected=1))
                self.assertIsNone(self.launch(shell, "new", expected=1))
                self.assertIsNone(self.launch(shell, "new", "demo", cwd=self.root, expected=1))
                self.env["LAUNCH_EXIT"] = "7"
                self.launch(shell, "new", "demo", expected=7)
                self.env.pop("LAUNCH_EXIT")


if __name__ == "__main__":
    unittest.main()

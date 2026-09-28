"""Verify Undo targets the originating pane and never falls back to another pane."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONFIG = tomllib.loads((ROOT / "src/.config/herdr/config.toml").read_text())


class HerdrUndoTest(unittest.TestCase):
    def test_undo_command_targets_captured_pane(self):
        bindings = [item for item in CONFIG["keys"]["command"] if item["key"] == "ctrl+z"]
        self.assertEqual(len(bindings), 1)
        self.assertEqual(bindings[0]["type"], "shell")
        with tempfile.TemporaryDirectory(prefix="herdr-undo-") as directory:
            root = Path(directory)
            log = root / "arguments.json"
            executable = root / "herdr test binary"
            executable.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "Path(os.environ['UNDO_LOG']).write_text(json.dumps(sys.argv[1:]))\n"
            )
            executable.chmod(0o755)
            env = {**os.environ, "HERDR_BIN_PATH": str(executable),
                   "HERDR_ACTIVE_PANE_ID": "pane-42", "UNDO_LOG": str(log)}
            subprocess.run(["sh", "-c", bindings[0]["command"]], env=env, check=True)
            self.assertEqual(json.loads(log.read_text()), ["pane", "send-keys", "pane-42", "ctrl+_"])
            log.unlink()
            for missing in (None, ""):
                if missing is None:
                    env.pop("HERDR_ACTIVE_PANE_ID")
                else:
                    env["HERDR_ACTIVE_PANE_ID"] = missing
                result = subprocess.run(["sh", "-c", bindings[0]["command"]],
                                        env=env, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(log.exists())


if __name__ == "__main__":
    unittest.main()

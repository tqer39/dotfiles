"""Check that Ghostty resolves Home/End to the same actions as Command+arrows."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GHOSTTY = shutil.which('ghostty')


@unittest.skipUnless(GHOSTTY, 'Ghostty is required')
class GhosttyNavigationTest(unittest.TestCase):
    def test_home_end_match_command_arrows(self):
        with tempfile.TemporaryDirectory() as temp:
            config_dir = Path(temp) / 'ghostty'
            config_dir.mkdir()
            shutil.copy(ROOT / 'src/.config/ghostty/config', config_dir / 'config')
            shutil.copytree(ROOT / 'src/.config/ghostty/themes', config_dir / 'themes')
            result = subprocess.run(
                [GHOSTTY, '+show-config'],
                env={**os.environ, 'XDG_CONFIG_HOME': temp},
                capture_output=True, text=True, check=True,
            )
            bindings = {}
            for line in result.stdout.splitlines():
                if line.startswith('keybind = '):
                    trigger, action = line[len('keybind = '):].split('=', 1)
                    bindings[trigger] = action
            self.assertEqual(bindings['home'], bindings['super+arrow_left'])
            self.assertEqual(bindings['end'], bindings['super+arrow_right'])
            self.assertNotEqual(bindings['home'], bindings['end'])


if __name__ == '__main__':
    unittest.main()

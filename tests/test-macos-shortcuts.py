"""macOS のシステムショートカット調整を、実際の設定を書き換えずに検証する。"""

import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = r'''
source scripts/lib/log.sh
source scripts/lib/macos-shortcuts.sh
defaults() { printf '%s\0' "$@" > "$TEST_DEFAULTS_ARGS"; }
configure_macos_shortcuts
'''

# keycode 33 は US 配列の [、JIS 配列の @。
LEFT_BRACKET_KEYCODE = 33
COMMAND_MASK = 0x100000
SHIFT_MASK = 0x20000


class MacosShortcutsTest(unittest.TestCase):
    def run_configure(self, dry_run='false'):
        with tempfile.TemporaryDirectory() as temp:
            args_file = Path(temp) / 'defaults-args'
            activated = Path(temp) / 'activated'
            activate = Path(temp) / 'activateSettings'
            activate.write_text(f'#!/usr/bin/env bash\necho "$@" > "{activated}"\n')
            activate.chmod(0o755)
            result = subprocess.run(
                ['bash', '-c', SCRIPT], cwd=ROOT,
                env={**os.environ, 'DRY_RUN': dry_run,
                     'TEST_DEFAULTS_ARGS': str(args_file),
                     'MACOS_ACTIVATE_SETTINGS': str(activate)},
                capture_output=True, text=True, check=False,
            )
            args = args_file.read_bytes().split(b'\0')[:-1] if args_file.exists() else []
            reloaded = activated.read_text().strip() if activated.exists() else None
            return result, [arg.decode() for arg in args], reloaded

    def test_disables_next_window_shortcut_on_left_bracket_key(self):
        result, args, reloaded = self.run_configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(args[:5], ['write', 'com.apple.symbolichotkeys',
                                    'AppleSymbolicHotKeys', '-dict-add', '27'])
        # defaults は plist の値の断片を受け取るので、文書に包んで解釈する。
        hotkey = plistlib.loads(
            f'<?xml version="1.0"?><plist version="1.0">{args[5]}</plist>'.encode())
        self.assertIs(hotkey['enabled'], False)
        _, keycode, mask = hotkey['value']['parameters']
        self.assertEqual(keycode, LEFT_BRACKET_KEYCODE)
        # Shift なしの ⌘ だが、macOS が Shift 付きの逆方向も取るため Cmd+Shift+[ を塞いでいた。
        self.assertEqual(mask, COMMAND_MASK)
        self.assertEqual(mask & SHIFT_MASK, 0)
        self.assertEqual(reloaded, '-u')

    def test_dry_run_does_not_write_settings(self):
        result, args, reloaded = self.run_configure(dry_run='true')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(args, [])
        self.assertIsNone(reloaded)
        self.assertIn('[DRY RUN]', result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()

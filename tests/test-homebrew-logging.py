"""Verify streaming logs and exit status without installing real packages."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = r'''
source scripts/installers/homebrew.sh
brew() {
  case "$1" in
    update) echo 'Updated Homebrew' ;;
    help) return 1 ;;
    ruby)
      echo "work=$HOMEBREW_WORK_MODE"
      echo '[START] cask example'
      echo "${TEST_MESSAGE:-details}" >&2
      printf 'last line without newline'
      return "${TEST_EXIT:-0}"
      ;;
    *) return 99 ;;
  esac
}
install_homebrew_packages
'''


class HomebrewLoggingTest(unittest.TestCase):
    def run_install(self, **env):
        with tempfile.TemporaryDirectory() as temp:
            log_dir = Path(temp) / 'logs'
            result = subprocess.run(
                ['bash', '-c', SCRIPT], cwd=ROOT,
                env={**os.environ, 'DOTFILES_INSTALL_LOG_DIR': str(log_dir),
                     'WORK_MODE': 'true', 'CI_MODE': 'false', 'DRY_RUN': 'false', **env},
                capture_output=True, text=True, check=False,
            )
            logs = list(log_dir.glob('homebrew-*'))
            content = logs[0].read_text() if logs else ''
            return result, logs, content

    def test_output_and_stderr_are_saved_with_timestamps(self):
        result, logs, content = self.run_install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(logs), 1)
        self.assertIn('work=true', content)
        self.assertIn('details', content)
        self.assertIn('last line without newline', content)
        self.assertRegex(content, r'\[\d{4}-\d\d-\d\d .*\] \[START\] cask example')
        self.assertIn('[START] cask example', result.stdout)

    def test_failed_install_preserves_exit_status_and_log(self):
        result, logs, content = self.run_install(TEST_EXIT='7')
        self.assertEqual(result.returncode, 7)
        self.assertEqual(len(logs), 1)
        self.assertIn('details', content)
        self.assertNotIn('installed successfully', result.stdout)

    def test_ci_failure_warns_without_claiming_success(self):
        result, _, _ = self.run_install(TEST_EXIT='7', CI_MODE='true')
        self.assertEqual(result.returncode, 0)
        self.assertIn('CI mode, continuing', result.stderr)
        self.assertNotIn('installed successfully', result.stdout)

    def test_deprecated_tap_still_fails_in_ci(self):
        result, _, _ = self.run_install(TEST_MESSAGE='tap was deprecated', CI_MODE='true')
        self.assertEqual(result.returncode, 1)
        self.assertIn('Deprecated tap', result.stderr)

    def test_dry_run_does_not_create_logs_or_run_brew(self):
        result, logs, _ = self.run_install(DRY_RUN='true')
        self.assertEqual(result.returncode, 0)
        self.assertEqual(logs, [])
        self.assertNotIn('Updated Homebrew', result.stdout)


if __name__ == '__main__':
    unittest.main()

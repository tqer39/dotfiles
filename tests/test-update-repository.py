"""Exercise the real installer update functions against disposable Git repositories."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SHELL = "bash"


class RepositoryUpdateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-update-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.upstream = self.root / "upstream"
        self.work = self.root / "work with spaces"
        self.env = {
            **os.environ,
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_TERMINAL_PROMPT": "0",
        }
        self.git(self.root, "init", "--quiet", "--initial-branch=main", str(self.upstream))
        self.configure(self.upstream)
        (self.upstream / "tracked.txt").write_text("v1\n")
        self.commit(self.upstream, "initial")
        self.git(self.root, "clone", "--quiet", str(self.upstream), str(self.work))
        self.configure(self.work)
        # Reproduce the user's settings. Explicit update flags must override them.
        for key in ("pull.rebase", "pull.autoStash", "rebase.autoStash", "merge.autoStash"):
            self.git(self.work, "config", key, "true")
        if SHELL == "bash":
            source = (ROOT / "install.sh").read_text()
            self.assertEqual(source.splitlines()[-1], 'main "$@"')
            self.runner = self.root / "update.sh"
            self.runner.write_text(source.rsplit('main "$@"', 1)[0] + '\n'
                                   'DRY_RUN="$UPDATE_TEST_DRY_RUN"\n'
                                   'CI_MODE="$UPDATE_TEST_CI"\nupdate_repository\n')
        else:
            self.runner = self.root / "update.ps1"
            # Parse only the function; never execute the installer's entry point.
            self.runner.write_text('''$ErrorActionPreference = 'Stop'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $env:UPDATE_TEST_INSTALLER, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
$function = $ast.Find({ param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Update-Repository'
}, $true)
if (-not $function) { throw 'Update-Repository function missing' }
. ([scriptblock]::Create($function.Extent.Text))
function Write-Info($message) { Write-Host $message }
function Write-Err($message) { Write-Host $message }
function Write-Success($message) { Write-Host $message }
$DotfilesDir = $env:DOTFILES_DIR
$DryRun = $env:UPDATE_TEST_DRY_RUN -eq 'true'
$CI = $env:UPDATE_TEST_CI -eq 'true'
Update-Repository
''')

    def git(self, directory, *args, success=True):
        result = subprocess.run(["git", "-C", str(directory), *args], env=self.env,
                                capture_output=True, check=False)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr.decode())
        return result.stdout

    def configure(self, directory):
        for key, value in (("user.name", "dotfiles test"), ("user.email", "test@example.com"),
                           ("commit.gpgsign", "false"), ("core.autocrlf", "false")):
            self.git(directory, "config", key, value)

    def commit(self, directory, message):
        self.git(directory, "add", ".")
        self.git(directory, "commit", "--quiet", "-m", message)

    def incoming(self, name="tracked.txt", content="v2\n"):
        (self.upstream / name).write_text(content)
        self.commit(self.upstream, "upstream change")

    def snapshot(self, directory=None):
        directory = directory or self.work
        return (
            self.git(directory, "rev-parse", "HEAD"),
            self.git(directory, "status", "--porcelain=v1", "--untracked-files=all"),
            self.git(directory, "ls-files", "--stage", "-z"),
            self.git(directory, "stash", "list", "--format=%H %gs"),
            {path.relative_to(directory).as_posix(): path.read_bytes()
             for path in directory.rglob("*") if path.is_file()
             and ".git" not in path.relative_to(directory).parts},
        )

    def update(self, success=True, dry_run=False, ci=False, directory=None):
        command = (["bash", str(self.runner)] if SHELL == "bash" else
                   [SHELL, "-NoLogo", "-NoProfile", "-File", str(self.runner)])
        result = subprocess.run(command, env={
            **self.env,
            "DOTFILES_DIR": str(directory or self.work),
            "UPDATE_TEST_INSTALLER": str(ROOT / "install.ps1"),
            "UPDATE_TEST_DRY_RUN": str(dry_run).lower(),
            "UPDATE_TEST_CI": str(ci).lower(),
        }, capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def assert_refused_unchanged(self):
        before = self.snapshot()
        self.update(success=False)
        self.assertEqual(before, self.snapshot())

    def test_clean_checkout_fast_forwards(self):
        self.incoming()
        self.update()
        self.assertEqual(self.git(self.work, "rev-parse", "HEAD"),
                         self.git(self.upstream, "rev-parse", "HEAD"))
        self.assertEqual((self.work / "tracked.txt").read_text(), "v2\n")
        self.assertEqual(self.git(self.work, "status", "--porcelain"), b"")
        self.assertEqual(self.git(self.work, "stash", "list"), b"")
        after = self.snapshot()
        self.update()
        self.assertEqual(after, self.snapshot())

    def test_unstaged_change_stops_even_without_overlap(self):
        self.incoming("other.txt")
        (self.work / "tracked.txt").write_text("local edit\n")
        self.assert_refused_unchanged()

    def test_staged_and_unstaged_versions_survive(self):
        self.incoming()
        (self.work / "tracked.txt").write_text("staged edit\n")
        self.git(self.work, "add", "tracked.txt")
        (self.work / "tracked.txt").write_text("unstaged edit\n")
        self.assert_refused_unchanged()

    def test_untracked_collision_stops(self):
        self.incoming("newfile.txt")
        (self.work / "newfile.txt").write_text("untracked edit\n")
        self.assert_refused_unchanged()

    def test_conflicting_local_change_stops_without_markers(self):
        self.incoming()
        (self.work / "tracked.txt").write_text("local edit\n")
        self.assert_refused_unchanged()
        self.assertEqual(self.git(self.work, "diff", "--name-only", "--diff-filter=U"), b"")

    def test_existing_autostash_conflict_is_preserved(self):
        self.incoming()
        (self.work / "tracked.txt").write_text("local edit\n")
        # Reproduce the old failure using plain pull with autostash enabled.
        self.git(self.work, "pull", "--quiet", success=False)
        self.assertIn(b"tracked.txt", self.git(self.work, "diff", "--name-only", "--diff-filter=U"))
        self.assertTrue(self.git(self.work, "stash", "list"))
        self.assert_refused_unchanged()

    def test_diverged_checkout_stops_without_merge_or_rebase(self):
        self.incoming()
        (self.work / "local.txt").write_text("local commit\n")
        self.commit(self.work, "local commit")
        self.assert_refused_unchanged()

    def test_existing_stash_and_development_worktree_survive(self):
        (self.work / "tracked.txt").write_text("saved work\n")
        self.git(self.work, "stash", "push", "--quiet", "-m", "existing work")
        development = self.root / "development"
        self.git(self.work, "worktree", "add", "--quiet", "--no-track", "-b", "feature", str(development))
        (development / "tracked.txt").write_text("worktree edit\n")
        before = self.snapshot(development)
        self.incoming()
        self.update()
        self.assertEqual(before, self.snapshot(development))
        self.assertEqual(self.git(self.work, "status", "--porcelain"), b"")

    def test_dry_run_and_ci_leave_dirty_checkout_untouched(self):
        self.incoming()
        (self.work / "tracked.txt").write_text("local edit\n")
        before = self.snapshot()
        self.update(dry_run=True)
        self.assertEqual(before, self.snapshot())
        self.update(ci=True)
        self.assertEqual(before, self.snapshot())

    def test_fetch_failure_leaves_checkout_untouched(self):
        self.git(self.work, "remote", "set-url", "origin", str(self.root / "missing"))
        self.assert_refused_unchanged()

    def test_invalid_repository_fails(self):
        invalid = self.root / "not-a-repository"
        invalid.mkdir()
        self.update(success=False, directory=invalid)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--shell", choices=("bash", "powershell", "pwsh"), default="bash")
    args, remaining = parser.parse_known_args()
    SHELL = args.shell
    if not shutil.which(SHELL):
        parser.error(f"Required test runtime is unavailable: {SHELL}")
    unittest.main(argv=[__file__, *remaining])

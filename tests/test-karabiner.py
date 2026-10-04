"""Check the selected Karabiner profile's modifier-role policy."""

import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "src/.config/karabiner/karabiner.json"
TERMINALS = (
    "com.apple.Terminal", "com.mitchellh.ghostty", "com.cmuxterm.app",
    "com.googlecode.iterm2", "co.zeit.hyper",
)


def profile():
    return next(item for item in json.loads(CONFIG.read_text())["profiles"] if item.get("selected"))


def transform(key, modifiers, app, variables=None):
    """Evaluate the first matching basic key rule used by this configuration."""
    variables = {} if variables is None else variables
    groups = {
        "control": {"left_control", "right_control"},
        "command": {"left_command", "right_command"},
        "shift": {"left_shift", "right_shift"},
        "option": {"left_option", "right_option"},
    }
    for rule in profile()["complex_modifications"]["rules"]:
        if not rule.get("enabled", True):
            continue
        for item in rule["manipulators"]:
            if item["from"].get("key_code") != key:
                continue
            valid = True
            for condition in item.get("conditions", []):
                if condition["type"] == "variable_if":
                    matches = variables.get(condition["name"], False) == condition["value"]
                else:
                    matches = any(re.search(pattern, app) for pattern in condition["bundle_identifiers"])
                    matches = matches == (condition["type"] == "frontmost_application_if")
                if not matches:
                    valid = False
            if not valid:
                continue
            spec = item["from"].get("modifiers", {})
            mandatory = spec.get("mandatory", [])
            if any(not (groups.get(modifier, {modifier}) & modifiers) for modifier in mandatory):
                continue
            consumed = set().union(*(groups.get(modifier, {modifier}) for modifier in mandatory)) & modifiers
            remaining = modifiers - consumed
            optional = spec.get("optional", [])
            allowed = set().union(*(groups.get(modifier, {modifier}) for modifier in optional))
            if "any" not in optional and remaining - allowed:
                continue
            for output in item["to"]:
                variable = output.get("set_variable")
                if variable:
                    variables[variable["name"]] = variable["value"]
            output = next((output for output in item["to"] if "key_code" in output), None)
            if output is None:
                continue
            return output["key_code"], remaining | set(output.get("modifiers", []))
    return key, modifiers


def chord(modifier, key, app, extra=frozenset()):
    """Modifier key-down is handled before the following key event."""
    variables = {}
    mapped, _ = transform(modifier, set(), app, variables)
    return transform(key, {mapped, *extra}, app, variables)


class ModifierRoleTest(unittest.TestCase):
    def test_control_is_command_in_regular_apps_and_codex(self):
        for app in (
            "com.apple.TextEdit", "com.google.Chrome", "com.microsoft.VSCode",
            "com.openai.codex",
        ):
            for control in ("left_control", "right_control"):
                with self.subTest(app=app, control=control):
                    self.assertEqual(transform(control, set(), app), ("left_command", set()))
                    self.assertEqual(chord(control, "w", app), ("w", {"left_command"}))

    def test_codex_control_tab_moves_browser_tabs(self):
        for control in ("left_control", "right_control"):
            with self.subTest(control=control):
                self.assertEqual(chord(control, "tab", "com.openai.codex"),
                                 ("tab", {"control"}))
                self.assertEqual(chord(control, "tab", "com.openai.codex", {"left_shift"}),
                                 ("tab", {"control", "left_shift"}))

    def test_codex_control_j_runs_nani_quick_translate(self):
        for control in ("left_control", "right_control"):
            with self.subTest(control=control):
                self.assertEqual(chord(control, "j", "com.openai.codex"),
                                 ("j", {"left_control", "left_option"}))

    def test_codex_control_shift_j_opens_terminal(self):
        for control in ("left_control", "right_control"):
            with self.subTest(control=control):
                self.assertEqual(chord(control, "j", "com.openai.codex", {"left_shift"}),
                                 ("j", {"left_command"}))

    def test_control_j_keeps_command_in_other_apps(self):
        for control in ("left_control", "right_control"):
            with self.subTest(control=control):
                self.assertEqual(chord(control, "j", "com.apple.TextEdit"),
                                 ("j", {"left_command"}))

    def test_control_j_runs_nani_quick_translate_in_browsers(self):
        for app in (
            "com.google.Chrome", "com.brave.Browser", "com.apple.Safari",
            "org.mozilla.firefox",
        ):
            for control in ("left_control", "right_control"):
                with self.subTest(app=app, control=control):
                    self.assertEqual(chord(control, "j", app),
                                     ("j", {"left_control", "left_option"}))

    def test_control_tab_moves_browser_and_vscode_tabs(self):
        for app in (
            "com.google.Chrome", "com.brave.Browser", "com.apple.Safari",
            "org.mozilla.firefox", "com.microsoft.VSCode", "com.microsoft.VSCodeInsiders",
            "com.vscodium",
        ):
            for control in ("left_control", "right_control"):
                with self.subTest(app=app, control=control):
                    self.assertEqual(chord(control, "tab", app), ("tab", {"control"}))
                    self.assertEqual(chord(control, "tab", app, {"left_shift"}),
                                     ("tab", {"control", "left_shift"}))

    def test_control_tab_keeps_command_in_other_apps(self):
        for control in ("left_control", "right_control"):
            with self.subTest(control=control):
                self.assertEqual(chord(control, "tab", "com.apple.TextEdit", {"left_shift"}),
                                 ("tab", {"left_command", "left_shift"}))

    def test_physical_command_tab_keeps_native_application_switcher(self):
        for app in (
            "com.google.Chrome", "com.brave.Browser", "com.apple.Safari",
            "org.mozilla.firefox", "com.microsoft.VSCode", "com.openai.codex",
        ):
            with self.subTest(app=app):
                self.assertEqual(transform("tab", {"left_command"}, app),
                                 ("tab", {"left_command"}))

    def test_physical_command_j_keeps_native_shortcuts(self):
        for app in (
            "com.openai.codex", "com.google.Chrome", "com.brave.Browser",
            "com.apple.Safari", "org.mozilla.firefox",
        ):
            with self.subTest(app=app):
                self.assertEqual(transform("j", {"left_command"}, app),
                                 ("j", {"left_command"}))
                self.assertEqual(transform("j", {"left_command", "left_shift"}, app),
                                 ("j", {"left_command", "left_shift"}))

    def test_control_stays_native_in_terminals(self):
        for app in TERMINALS:
            for control in ("left_control", "right_control"):
                with self.subTest(app=app, control=control):
                    self.assertEqual(transform(control, set(), app), (control, set()))
                    self.assertEqual(chord(control, "c", app), ("c", {control}))
                    self.assertEqual(chord(control, "tab", app), ("tab", {control}))

    def test_ghostty_control_space_switches_input_source(self):
        for control in ("left_control", "right_control"):
            self.assertEqual(chord(control, "spacebar", "com.mitchellh.ghostty"),
                             ("spacebar", {"left_command"}))
            for extra in ({"left_shift"}, {"left_option"}):
                self.assertEqual(chord(control, "spacebar", "com.mitchellh.ghostty", extra),
                                 ("spacebar", {control, *extra}))
            for app in ("com.apple.Terminal", "com.cmuxterm.app"):
                self.assertEqual(chord(control, "spacebar", app), ("spacebar", {control}))
            self.assertEqual(chord(control, "spacebar", "com.openai.codex"),
                             ("spacebar", {"left_command"}))
        self.assertEqual(chord("left_command", "spacebar", "com.mitchellh.ghostty"),
                         ("spacebar", {"left_command"}))

    def test_command_is_not_remapped(self):
        for app in ("com.apple.TextEdit", "com.google.Chrome", *TERMINALS, "com.openai.codex"):
            self.assertEqual(transform("left_command", set(), app), ("left_command", set()))

    def test_legacy_per_shortcut_rules_are_disabled(self):
        legacy_descriptions = {
            "ChatGPT Codex: Control の入力操作を維持",
            "OS: Control でアプリ共通の Command ショートカットを実行",
            "Terminal: Control で貼り付け・新規タブ・タブ終了・アプリ終了",
            "Ghostty: 元 Caps Lock（右 Control）を Command として使う（コピー・貼り付け）",
            "Google Chrome / Brave / Safari: 左 Command と左 Control を交換",
            "VS Code: 元 Caps Lock を Control として使い、Control+Tab / Shift+Tab で次・前のタブへ移動",
            "Slack: Control+左クリックを Command+左クリックに変換（別ウィンドウで開く）",
            "Slack / Nani: Control+Enter で送信・実行",
            "OS: Control で編集・保存・検索・書式・タブ操作（ターミナルを除く）",
        }
        rules = {rule["description"]: rule for rule in profile()["complex_modifications"]["rules"]}
        for description in legacy_descriptions:
            self.assertFalse(rules[description].get("enabled", True), description)


if __name__ == "__main__":
    unittest.main()

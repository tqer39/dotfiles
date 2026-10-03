"""Check the selected Karabiner profile's modifier-role policy."""

import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "src/.config/karabiner/karabiner.json"
TERMINALS_AND_CODEX = (
    "com.apple.Terminal", "com.mitchellh.ghostty", "com.cmuxterm.app",
    "com.googlecode.iterm2", "co.zeit.hyper", "com.openai.codex",
)


def profile():
    return next(item for item in json.loads(CONFIG.read_text())["profiles"] if item.get("selected"))


def transform(key, modifiers, app):
    """Evaluate the first matching basic key rule used by this configuration."""
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
                matches = any(re.search(pattern, app) for pattern in condition["bundle_identifiers"])
                if matches != (condition["type"] == "frontmost_application_if"):
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
            output = item["to"][0]
            return output["key_code"], remaining | set(output.get("modifiers", []))
    return key, modifiers


def chord(modifier, key, app, extra=frozenset()):
    """Modifier key-down is handled before the following key event."""
    mapped, _ = transform(modifier, set(), app)
    return transform(key, {mapped, *extra}, app)


class ModifierRoleTest(unittest.TestCase):
    def test_control_is_command_in_regular_apps(self):
        for app in ("com.apple.TextEdit", "com.google.Chrome", "com.microsoft.VSCode"):
            for control in ("left_control", "right_control"):
                with self.subTest(app=app, control=control):
                    self.assertEqual(transform(control, set(), app), ("left_command", set()))
                    self.assertEqual(chord(control, "w", app), ("w", {"left_command"}))
                    self.assertEqual(chord(control, "tab", app, {"left_shift"}),
                                     ("tab", {"left_command", "left_shift"}))

    def test_control_stays_native_in_terminals_and_codex(self):
        for app in TERMINALS_AND_CODEX:
            for control in ("left_control", "right_control"):
                with self.subTest(app=app, control=control):
                    self.assertEqual(transform(control, set(), app), (control, set()))
                    self.assertEqual(chord(control, "c", app), ("c", {control}))
                    self.assertEqual(chord(control, "tab", app), ("tab", {control}))

    def test_command_is_not_remapped(self):
        for app in ("com.apple.TextEdit", "com.google.Chrome", *TERMINALS_AND_CODEX):
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

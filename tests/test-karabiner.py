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


def matching_rule(key, modifiers, app, variables=None):
    """Find the first matching basic key rule and unconsumed modifiers."""
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
            return item, remaining
    return None, modifiers


def transform(key, modifiers, app, variables=None):
    """Evaluate a following key using the currently held modifier state."""
    item, remaining = matching_rule(key, modifiers, app, variables)
    if item:
        output = next(output for output in item["to"] if "key_code" in output)
        return output["key_code"], remaining | set(output.get("modifiers", []))
    return key, modifiers


class ModifierPress:
    """Model key/variable lifetimes for a single modifier press, not all Karabiner features.

    Karabiner 16.3.0 basic/event_sender.hpp releases non-final `to` events
    immediately; event_queue/queue.hpp also applies their key_up_value then.
    """

    def __init__(self, item):
        self.item = item
        self.held = set()
        self.variables = {}
        self.deferred = []
        for index, output in enumerate(item["to"]):
            self.event(output, True)
            if index < len(item["to"]) - 1 or not output.get("repeat", True):
                self.event(output, False)
            else:
                self.deferred.append(output)

    def event(self, output, down):
        if "key_code" in output:
            if down:
                self.held.add(output["key_code"])
            else:
                self.held.discard(output["key_code"])
        if "set_variable" in output:
            variable = output["set_variable"]
            value_key = "value" if down else "key_up_value"
            if value_key in variable:
                self.variables[variable["name"]] = variable[value_key]

    def release(self):
        for output in self.deferred:
            self.event(output, False)
        for output in self.item.get("to_after_key_up", []):
            self.event(output, True)
            self.event(output, False)


def press_modifier(modifier, app):
    item, _ = matching_rule(modifier, set(), app)
    return ModifierPress(item or {"to": [{"key_code": modifier}]})


def chord(modifier, key, app, extra=frozenset()):
    """Modifier key-down is handled before the following key event."""
    press = press_modifier(modifier, app)
    return transform(key, press.held | set(extra), app, press.variables)


class ModifierRoleTest(unittest.TestCase):
    def test_output_model_detects_early_key_and_variable_release(self):
        variable = {"set_variable": {
            "name": "original_control_pressed", "value": True, "key_up_value": False,
        }}
        command = {"key_code": "left_command"}
        broken_key = ModifierPress({"to": [command, variable]})
        self.assertEqual(broken_key.held, set())
        self.assertTrue(broken_key.variables["original_control_pressed"])
        broken_variable = ModifierPress({"to": [variable, command]})
        self.assertEqual(broken_variable.held, {"left_command"})
        self.assertFalse(broken_variable.variables["original_control_pressed"])

    def test_command_and_origin_state_last_until_control_release(self):
        for app in ("com.openai.codex", "com.apple.TextEdit", "com.google.Chrome"):
            for control in ("left_control", "right_control"):
                with self.subTest(app=app, control=control):
                    press = press_modifier(control, app)
                    self.assertEqual(press.held, {"left_command"})
                    self.assertTrue(press.variables["original_control_pressed"])
                    press.release()
                    self.assertEqual(press.held, set())
                    self.assertFalse(press.variables["original_control_pressed"])
                    for key in ("j", "tab"):
                        self.assertEqual(transform(key, {"left_command"}, app, press.variables),
                                         (key, {"left_command"}))

    def test_input_switch_copy_paste_and_select_all_with_held_control(self):
        for app in ("com.openai.codex", "com.apple.TextEdit", "com.google.Chrome"):
            for control in ("left_control", "right_control"):
                for key in ("spacebar", "c", "v", "a"):
                    with self.subTest(app=app, control=control, key=key):
                        self.assertEqual(chord(control, key, app), (key, {"left_command"}))

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
                                 ("j", {"left_control"}))

    def test_codex_control_shift_j_opens_terminal(self):
        for control in ("left_control", "right_control"):
            with self.subTest(control=control):
                self.assertEqual(chord(control, "j", "com.openai.codex", {"left_shift"}),
                                 ("j", {"left_command"}))

    def test_control_j_runs_nani_quick_translate_in_regular_apps(self):
        for app in (
            "com.apple.TextEdit", "com.google.Chrome", "com.brave.Browser",
            "com.apple.Safari", "org.mozilla.firefox", "com.microsoft.VSCode",
            "com.openai.codex",
        ):
            for control in ("left_control", "right_control"):
                with self.subTest(app=app, control=control):
                    self.assertEqual(chord(control, "j", app),
                                     ("j", {"left_control"}))

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
            "com.apple.TextEdit", "com.openai.codex", "com.google.Chrome",
            "com.brave.Browser", "com.apple.Safari", "org.mozilla.firefox",
            "com.microsoft.VSCode", *TERMINALS,
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
                    self.assertEqual(chord(control, "j", app),
                                     ("j", {"left_control"}))

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

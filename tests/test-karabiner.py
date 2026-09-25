"""Check text shortcuts and terminal/browser exceptions in the selected profile."""

import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "src/.config/karabiner/karabiner.json"


def transform(key, modifiers, app):
    """Evaluate the basic rules used here, stopping at the first match."""
    profile = next(p for p in json.loads(CONFIG.read_text())["profiles"] if p.get("selected"))
    groups = {
        "control": {"left_control", "right_control"},
        "command": {"left_command", "right_command"},
        "shift": {"left_shift", "right_shift"},
        "option": {"left_option", "right_option"},
    }
    for rule in profile["complex_modifications"]["rules"]:
        if not rule.get("enabled", True):
            continue
        for item in rule["manipulators"]:
            if item["from"].get("key_code") != key:
                continue
            applicable = True
            for condition in item.get("conditions", []):
                matches = any(re.search(pattern, app) for pattern in condition["bundle_identifiers"])
                if matches != (condition["type"] == "frontmost_application_if"):
                    applicable = False
            if not applicable:
                continue
            spec = item["from"].get("modifiers", {})
            mandatory = spec.get("mandatory", [])
            if any(not (groups.get(m, {m}) & modifiers) for m in mandatory):
                continue
            consumed = set().union(*(groups.get(m, {m}) for m in mandatory)) & modifiers
            remaining = modifiers - consumed
            optional = spec.get("optional", [])
            allowed = set().union(*(groups.get(m, {m}) for m in optional))
            if "any" not in optional and remaining - allowed:
                continue
            output = item["to"][0]
            return output["key_code"], remaining | set(output.get("modifiers", []))
    return key, modifiers


def chord(modifier, key, app, extra=frozenset()):
    # Modifier key-down is a separate event; its result is not remapped again.
    mapped, _ = transform(modifier, set(), app)
    return transform(key, {mapped, *extra}, app)


class TextShortcutsTest(unittest.TestCase):
    def test_general_apps(self):
        for app in ("com.tinyspeck.slackmacgap", "com.1password.1password", "com.apple.TextEdit"):
            for modifier in ("caps_lock", "left_control", "right_control"):
                for key in ("a", "c", "x", "v", "z", "s", "f", "b", "i", "u", "n", "o", "p", "t", "w", "r"):
                    for extra in (set(), {"left_shift"}, {"left_shift", "left_option"}):
                        with self.subTest(app=app, modifier=modifier, key=key, extra=extra):
                            self.assertEqual(chord(modifier, key, app, extra), (key, {"left_command", *extra}))

    def test_browser_swap_is_not_reversed(self):
        for app in ("com.google.Chrome", "com.brave.Browser", "com.apple.Safari"):
            for key in ("a", "c", "x", "v", "z", "s", "f", "b", "i", "u", "n", "o", "p", "t", "w", "r"):
                for modifier in ("caps_lock", "left_control", "right_control"):
                    self.assertEqual(chord(modifier, key, app), (key, {"left_command"}))
                self.assertEqual(chord("left_command", key, app), (key, {"left_control"}))
            self.assertEqual(chord("left_control", "tab", app), ("tab", {"left_control"}))
            self.assertEqual(chord("left_control", "spacebar", app), ("spacebar", {"left_control"}))

    def test_terminal_control_signals(self):
        for app in ("com.apple.Terminal", "com.mitchellh.ghostty", "com.cmuxterm.app", "com.googlecode.iterm2", "co.zeit.hyper"):
            for key in ("a", "c", "x", "z"):
                self.assertEqual(chord("left_control", key, app), (key, {"left_control"}))
            if app != "com.mitchellh.ghostty":
                self.assertEqual(chord("right_control", "a", app), ("a", {"right_control"}))
        self.assertEqual(chord("left_control", "v", "com.apple.Terminal"), ("v", {"left_command"}))
        self.assertEqual(chord("right_control", "c", "com.mitchellh.ghostty"), ("c", {"left_command"}))

    def test_home_end_editing(self):
        for app in ("com.tinyspeck.slackmacgap", "com.1password.1password", "com.apple.TextEdit", "com.google.Chrome"):
            for key, arrow in (("home", "left_arrow"), ("end", "right_arrow")):
                for extra in (set(), {"left_shift"}, {"right_shift"}):
                    with self.subTest(app=app, key=key, extra=extra):
                        self.assertEqual(transform(key, extra, app), (arrow, {"left_command", *extra}))

    def test_builtin_fn_arrows(self):
        for key in ("left_arrow", "right_arrow"):
            for extra in (set(), {"left_shift"}, {"right_shift"}):
                self.assertEqual(transform(key, {"fn", *extra}, "com.tinyspeck.slackmacgap"),
                                 (key, {"left_command", *extra}))
            self.assertEqual(transform(key, {"fn"}, "com.mitchellh.ghostty"), (key, {"fn"}))

    def test_terminal_home_end_unchanged(self):
        for app in ("com.apple.Terminal", "com.mitchellh.ghostty", "com.cmuxterm.app", "com.googlecode.iterm2", "co.zeit.hyper"):
            for key in ("home", "end"):
                self.assertEqual(transform(key, set(), app), (key, set()))

    def test_code_tab_navigation(self):
        app = "com.microsoft.VSCode"
        for modifier in ("caps_lock", "left_control", "right_control"):
            self.assertEqual(chord(modifier, "tab", app), ("right_arrow", {"left_command", "left_option"}))
            for shift in ("left_shift", "right_shift"):
                self.assertEqual(chord(modifier, "tab", app, {shift}),
                                 ("left_arrow", {"left_command", "left_option"}))
            self.assertEqual(chord(modifier, "a", app), ("a", {"left_command"}))
        self.assertEqual(chord("left_command", "tab", app), ("tab", {"left_command"}))
        self.assertEqual(chord("left_command", "tab", app, {"left_shift"}),
                         ("tab", {"left_command", "left_shift"}))
        self.assertEqual(transform("tab", set(), app), ("tab", set()))
        self.assertEqual(transform("tab", {"left_shift"}, app), ("tab", {"left_shift"}))

    def test_slack_send_shortcut(self):
        app = "com.tinyspeck.slackmacgap"
        for modifier in ("caps_lock", "left_control", "right_control", "left_command"):
            self.assertEqual(chord(modifier, "return_or_enter", app),
                             ("return_or_enter", {"left_command"}))
        self.assertEqual(transform("return_or_enter", set(), app), ("return_or_enter", set()))
        self.assertEqual(transform("return_or_enter", {"left_shift"}, app),
                         ("return_or_enter", {"left_shift"}))
        for other in ("com.apple.Terminal", "com.microsoft.VSCode", "com.apple.TextEdit"):
            for modifier in ("left_control", "right_control"):
                self.assertEqual(chord(modifier, "return_or_enter", other),
                                 ("return_or_enter", {modifier}))

    def test_browser_history(self):
        for app in ("com.google.Chrome", "com.brave.Browser", "com.apple.Safari"):
            for key, output in (("left_arrow", "open_bracket"), ("right_arrow", "close_bracket")):
                for modifier in ("left_option", "right_option"):
                    self.assertEqual(chord(modifier, key, app), (output, {"left_command"}))
                    self.assertEqual(chord(modifier, key, app, {"left_shift"}),
                                     (key, {modifier, "left_shift"}))
        for app in ("com.microsoft.VSCode", "com.apple.Terminal", "com.mitchellh.ghostty", "com.tinyspeck.slackmacgap", "com.apple.finder"):
            for key in ("left_arrow", "right_arrow"):
                self.assertEqual(chord("left_option", key, app), (key, {"left_option"}))

    def test_browser_mission_control(self):
        for app in ("com.google.Chrome", "com.brave.Browser", "com.apple.Safari"):
            for modifier in ("caps_lock", "left_control"):
                for key in ("up_arrow", "left_arrow", "right_arrow"):
                    for option in ("left_option", "right_option"):
                        for extra in (set(), {"left_shift"}):
                            self.assertEqual(chord(modifier, key, app, {option, *extra}),
                                             (key, {"left_control", "left_option", *extra}))
            for key in ("up_arrow", "left_arrow", "right_arrow"):
                self.assertEqual(chord("right_control", key, app, {"left_option"}),
                                 (key, {"right_control", "left_option"}))
        for app in ("com.microsoft.VSCode", "com.tinyspeck.slackmacgap", "com.apple.Terminal"):
            self.assertEqual(chord("left_command", "left_arrow", app, {"left_option"}),
                             ("left_arrow", {"left_command", "left_option"}))

    def test_unrelated_shortcuts(self):
        app = "com.tinyspeck.slackmacgap"
        self.assertEqual(chord("left_control", "tab", app), ("tab", {"left_control"}))
        self.assertEqual(chord("left_command", "a", app), ("a", {"left_command"}))
        self.assertEqual(chord("left_control", "a", app, {"left_command"}), ("a", {"left_control", "left_command"}))


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
MAESTRO_ROOT = REPO_ROOT / ".maestro"
LAUNCH_APP = re.compile(r"^([ \t]*)- launchApp:\n((?:\1 .*\n|[ \t]*\n)*)", re.MULTILINE)
UI_TESTING_KEY = re.compile(r"[\"']?-ui_testing[\"']?\s*:")
APPLE_LOCALE_KEY = re.compile(r"[\"']?-AppleLocale[\"']?\s*:")


def ui_testing_launches(source: str) -> list[tuple[int, bool]]:
    return [
        (match.start(), APPLE_LOCALE_KEY.search(match.group(2)) is not None)
        for match in LAUNCH_APP.finditer(source)
        if UI_TESTING_KEY.search(match.group(2))
    ]


class MaestroLaunchLocaleTests(unittest.TestCase):
    def test_ui_testing_launches_force_a_locale(self) -> None:
        checked = 0
        for path in sorted(MAESTRO_ROOT.rglob("*.yaml")):
            for offset, has_locale in ui_testing_launches(path.read_text(encoding="utf-8")):
                checked += 1
                with self.subTest(path=path.relative_to(MAESTRO_ROOT), offset=offset):
                    self.assertTrue(has_locale, "Without -AppleLocale the app formats dates by the simulator region")

        self.assertGreater(checked, 0)

    def test_ui_testing_launches_when_blank_line_precedes_launch_then_reports_missing_locale(self) -> None:
        source = '- tapOn: "Orders"\n\n- launchApp:\n    arguments:\n      "-ui_testing": true\n'
        launches = ui_testing_launches(source)
        self.assertEqual([has_locale for _, has_locale in launches], [False])


if __name__ == "__main__":
    unittest.main()

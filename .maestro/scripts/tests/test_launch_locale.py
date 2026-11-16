from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
MAESTRO_ROOT = REPO_ROOT / ".maestro"
LAUNCH_APP = re.compile(r"^(\s*)- launchApp:\n((?:\1 .*\n|\s*\n)*)", re.MULTILINE)


class MaestroLaunchLocaleTests(unittest.TestCase):
    def test_ui_testing_launches_force_a_locale(self) -> None:
        checked = 0
        for path in sorted(MAESTRO_ROOT.rglob("*.yaml")):
            source = path.read_text(encoding="utf-8")
            for match in LAUNCH_APP.finditer(source):
                block = match.group(2)
                if '"-ui_testing"' not in block:
                    continue
                checked += 1
                with self.subTest(path=path.relative_to(MAESTRO_ROOT), offset=match.start()):
                    self.assertIn(
                        '"-AppleLocale"',
                        block,
                        "Without -AppleLocale the app formats dates by the simulator region",
                    )

        self.assertGreater(checked, 0)


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "run-smoke-tests.py"
SPEC = importlib.util.spec_from_file_location("runner", SCRIPT)
assert SPEC and SPEC.loader
RUNNER = importlib.util.module_from_spec(SPEC)
import sys
sys.modules[SPEC.name] = RUNNER
SPEC.loader.exec_module(RUNNER)


class RunnerTests(unittest.TestCase):
    def test_redacts_all_woo_values(self) -> None:
        values = {"MAESTRO_WOO_LAB_WPCOM_PASSWORD": "do-not-print"}
        self.assertEqual("failure: <redacted>", RUNNER.redact("failure: do-not-print", values))

    def test_profile_contract(self) -> None:
        self.assertEqual("iphone", RUNNER.PROFILES["core"][3])
        self.assertEqual("ipad", RUNNER.PROFILES["pos-ipad"][3])
        self.assertNotIn("flaky_quarantine", RUNNER.PROFILES["release"][0])


if __name__ == "__main__":
    unittest.main()

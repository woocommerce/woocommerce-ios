from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "annotate-run.py"
SPEC = importlib.util.spec_from_file_location("annotate_run", SCRIPT)
assert SPEC and SPEC.loader
ANNOTATE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = ANNOTATE
SPEC.loader.exec_module(ANNOTATE)


class AnnotateRunTests(unittest.TestCase):
    def test_summary_status_and_failed_cases_are_failure_first(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            junit = root / "report.xml"
            summary = root / "run-summary.json"
            junit.write_text(
                '<testsuite tests="2" failures="1" skipped="0">'
                '<testcase name="passes"/><testcase name="flakes">'
                '<failure message="FLAKY"/></testcase></testsuite>',
                encoding="utf-8",
            )
            summary.write_text(json.dumps({"status": "FLAKY"}), encoding="utf-8")

            rendered = ANNOTATE.render(junit, summary)

        self.assertTrue(rendered.startswith("### Maestro smoke: FLAKY"))
        self.assertIn("2 tests · 1 failures · 0 skipped", rendered)
        self.assertIn("- `flakes`", rendered)


if __name__ == "__main__":
    unittest.main()

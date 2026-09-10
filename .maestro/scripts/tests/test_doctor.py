from __future__ import annotations

import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "doctor.py"
SPEC = importlib.util.spec_from_file_location("doctor", SCRIPT)
assert SPEC and SPEC.loader
DOCTOR = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = DOCTOR
SPEC.loader.exec_module(DOCTOR)


class DoctorTests(unittest.TestCase):
    def test_reports_repository_toolchain_mismatch(self) -> None:
        completed = subprocess.CompletedProcess(
            ["check-toolchain.py"],
            1,
            stdout="Maestro: expected 2.9.0, actual 2.7.0\n",
            stderr="Maestro version mismatch: expected 2.9.0, actual 2.7.0\n",
        )
        with mock.patch.object(DOCTOR.subprocess, "run", return_value=completed):
            passed, message = DOCTOR.check_toolchain()

        self.assertFalse(passed)
        self.assertEqual(
            "toolchain: Maestro version mismatch: expected 2.9.0, actual 2.7.0",
            message,
        )


if __name__ == "__main__":
    unittest.main()

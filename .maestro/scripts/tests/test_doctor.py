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
    def test_reports_non_english_simulator_language(self) -> None:
        completed = subprocess.CompletedProcess(
            ["device_locale.py"],
            1,
            stdout="",
            stderr=(
                "Setup error: simulator sim-1 primary language is es-ES; "
                "Maestro flows require English\n"
            ),
        )
        with mock.patch.object(DOCTOR.subprocess, "run", return_value=completed):
            passed, message = DOCTOR.check_simulator_locale("sim-1")

        self.assertFalse(passed)
        self.assertEqual(
            "simulator language: Setup error: simulator sim-1 primary language is es-ES; "
            "Maestro flows require English",
            message,
        )

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

    def test_reports_the_selections_the_runner_refuses_before_running(self) -> None:
        flows = [DOCTOR.RUNNER.FLOWS_DIR / "orders_create.yaml"]
        cases = [
            (DOCTOR.argparse.Namespace(seed=False, store=None), "Destructive flows require --seed"),
            (DOCTOR.argparse.Namespace(seed=True, store="shared"), "Refusing to run destructive flows against the shared store."),
        ]
        for args, expected in cases:
            with self.subTest(store=args.store, seed=args.seed):
                problems = DOCTOR.selection_problems(flows, {}, args)

                self.assertTrue(any(problem.startswith(expected) for problem in problems), problems)

        self.assertEqual([], DOCTOR.selection_problems(flows, {}, DOCTOR.argparse.Namespace(seed=True, store="lab")))


if __name__ == "__main__":
    unittest.main()

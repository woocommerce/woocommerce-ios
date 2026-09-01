from __future__ import annotations

import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "device_locale.py"
SPEC = importlib.util.spec_from_file_location("device_locale", SCRIPT)
assert SPEC and SPEC.loader
DEVICE_LOCALE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = DEVICE_LOCALE
SPEC.loader.exec_module(DEVICE_LOCALE)


class DeviceLocaleTests(unittest.TestCase):
    def test_parse_primary_locale_reads_the_first_preferred_language(self) -> None:
        output = '(\n    "en-ES",\n    "es-ES"\n)\n'

        self.assertEqual("en-ES", DEVICE_LOCALE.parse_primary_locale(output))

    def test_parse_primary_locale_accepts_unquoted_and_underscore_values(self) -> None:
        self.assertEqual("en-US", DEVICE_LOCALE.parse_primary_locale("(\n    en_US\n)"))

    def test_read_simulator_locale_uses_apple_languages(self) -> None:
        commands: list[list[str]] = []

        def command_runner(command: list[str]) -> subprocess.CompletedProcess[str]:
            commands.append(command)
            return subprocess.CompletedProcess(command, 0, '(\n    "en-GB"\n)\n', "")

        locale = DEVICE_LOCALE.read_simulator_locale("sim-1", command_runner)

        self.assertEqual("en-GB", locale.primary)
        self.assertEqual(
            [
                "xcrun",
                "simctl",
                "spawn",
                "sim-1",
                "defaults",
                "read",
                "NSGlobalDomain",
                "AppleLanguages",
            ],
            commands[0],
        )

    def test_english_region_is_accepted(self) -> None:
        def command_runner(command: list[str]) -> subprocess.CompletedProcess[str]:
            return subprocess.CompletedProcess(command, 0, '(\n    "en-AU"\n)\n', "")

        locale = DEVICE_LOCALE.ensure_english_simulator_locale("sim-1", command_runner)

        self.assertEqual("en-AU", locale.primary)

    def test_non_english_primary_language_is_rejected(self) -> None:
        def command_runner(command: list[str]) -> subprocess.CompletedProcess[str]:
            return subprocess.CompletedProcess(command, 0, '(\n    "es-ES",\n    "en-ES"\n)\n', "")

        with self.assertRaisesRegex(
            DEVICE_LOCALE.SimulatorLocaleError,
            "primary language is es-ES; Maestro flows require English",
        ):
            DEVICE_LOCALE.ensure_english_simulator_locale("sim-1", command_runner)

    def test_unavailable_simulator_language_is_reported(self) -> None:
        def command_runner(command: list[str]) -> subprocess.CompletedProcess[str]:
            return subprocess.CompletedProcess(command, 2, "", "Unable to boot device")

        with self.assertRaisesRegex(
            DEVICE_LOCALE.SimulatorLocaleError,
            "Unable to boot device",
        ):
            DEVICE_LOCALE.read_simulator_locale("sim-1", command_runner)

    def test_runner_checks_language_before_installing_the_app(self) -> None:
        runner = (SCRIPT.parent / "run-smoke-tests.py").read_text(encoding="utf-8")

        locale_check = runner.index("str(DEVICE_LOCALE)")
        app_install = runner.index('["xcrun", "simctl", "install"')

        self.assertLess(locale_check, app_install)


if __name__ == "__main__":
    unittest.main()

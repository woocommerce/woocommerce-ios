from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "check-toolchain.py"
CONFIGURE = Path(__file__).resolve().parents[1] / "configure-toolchain.sh"
REPO_ROOT = Path(__file__).resolve().parents[3]


class CheckToolchainTests(unittest.TestCase):
    def test_reports_matching_maestro_and_java_versions(self) -> None:
        result = self.run_checker(maestro_version="2.8.0", java_version="21.0.8")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("Maestro: expected 2.8.0, actual 2.8.0", result.stdout)
        self.assertIn("Java: expected major 21, actual 21.0.8", result.stdout)
        self.assertIn("Maestro toolchain OK", result.stdout)

    def test_fails_clearly_when_maestro_version_does_not_match(self) -> None:
        result = self.run_checker(maestro_version="2.7.0", java_version="21.0.8")

        self.assertEqual(1, result.returncode)
        self.assertIn("Maestro version mismatch: expected 2.8.0, actual 2.7.0", result.stderr)

    def test_fails_clearly_when_java_major_version_does_not_match(self) -> None:
        result = self.run_checker(maestro_version="2.8.0", java_version="17.0.12")

        self.assertEqual(1, result.returncode)
        self.assertIn("Java version mismatch: expected major 21, actual 17.0.12", result.stderr)

    def test_fails_clearly_when_maestro_is_missing(self) -> None:
        result = self.run_checker(maestro_version=None, java_version="21.0.8")

        self.assertEqual(2, result.returncode)
        self.assertIn("Required command not found: maestro", result.stderr)

    def test_fails_clearly_when_maestro_version_output_is_unrecognized(self) -> None:
        result = self.run_checker(maestro_version="Maestro dev build", java_version="21.0.8")

        self.assertEqual(2, result.returncode)
        self.assertIn("Could not parse Maestro version output", result.stderr)

    def test_ci_configuration_accepts_an_already_matching_toolchain_without_installing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            self.write_executable(bin_dir / "maestro", "printf '%s\\n' '2.8.0'\n")
            self.write_executable(
                bin_dir / "java",
                "printf '%s\\n' 'openjdk version \"21.0.8\"' >&2\n",
            )
            environment = dict(os.environ)
            environment.update(
                {
                    "HOME": str(root),
                    "PATH": f"{bin_dir}:/usr/bin:/bin",
                }
            )

            result = subprocess.run(
                ["/bin/bash", "-c", 'source "$1"', "bash", str(CONFIGURE)],
                cwd=REPO_ROOT,
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertNotIn("Installing pinned Maestro", result.stdout)

    def test_ci_configuration_installs_a_verified_release_into_the_job_workspace(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            curl_log = root / "curl.log"
            archive_maestro = root / "archive-maestro"
            self.write_executable(archive_maestro, "printf '%s\\n' '2.8.0'\n")
            self.write_executable(bin_dir / "maestro", "printf '%s\\n' '2.7.0'\n")
            self.write_executable(
                bin_dir / "java",
                "printf '%s\\n' 'openjdk version \"21.0.8\"' >&2\n",
            )
            self.write_executable(
                bin_dir / "curl",
                f"printf '%s\\n' \"$*\" > '{curl_log}'\n"
                "destination=''\n"
                "while [ \"$#\" -gt 0 ]; do\n"
                "  if [ \"$1\" = '-o' ]; then destination=\"$2\"; break; fi\n"
                "  shift\n"
                "done\n"
                "printf '%s\\n' archive > \"$destination\"\n",
            )
            self.write_executable(
                bin_dir / "sha256sum",
                "printf '%s  %s\\n' "
                "'b3e561161904fb391875ca5834d5b22cf0b01c052dd1b408ad83e30d8f8951b3' \"$1\"\n",
            )
            self.write_executable(
                bin_dir / "unzip",
                "destination=''\n"
                "while [ \"$#\" -gt 0 ]; do\n"
                "  if [ \"$1\" = '-d' ]; then destination=\"$2\"; break; fi\n"
                "  shift\n"
                "done\n"
                "mkdir -p \"$destination/maestro/bin\"\n"
                "cp \"$FAKE_MAESTRO_BIN\" \"$destination/maestro/bin/maestro\"\n",
            )
            environment = dict(os.environ)
            environment.update(
                {
                    "HOME": str(root),
                    "FAKE_MAESTRO_BIN": str(archive_maestro),
                    "MAESTRO_TOOLCHAIN_ROOT": str(root / "toolchain"),
                    "PATH": f"{bin_dir}:/usr/bin:/bin",
                }
            )

            result = subprocess.run(
                ["/bin/bash", "-c", 'source "$1"', "bash", str(CONFIGURE)],
                cwd=REPO_ROOT,
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )
            installed = list((root / "toolchain").glob("maestro-2.8.0-*/bin/maestro"))
            requested_url = curl_log.read_text(encoding="utf-8")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(1, len(installed))
        self.assertIn(
            "https://github.com/mobile-dev-inc/Maestro/releases/download/cli-2.8.0/maestro.zip",
            requested_url,
        )
        self.assertIn("Installing verified Maestro 2.8.0", result.stdout)

    def run_checker(
        self,
        *,
        maestro_version: str | None,
        java_version: str,
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            bin_dir = Path(directory)
            if maestro_version is not None:
                self.write_executable(
                    bin_dir / "maestro",
                    f'printf \'%s\\n\' \'{maestro_version}\'\n',
                )
            self.write_executable(
                bin_dir / "java",
                f'printf \'%s\\n\' \'openjdk version "{java_version}"\' >&2\n',
            )
            environment = dict(os.environ)
            environment["PATH"] = str(bin_dir)
            return subprocess.run(
                [sys.executable, str(SCRIPT)],
                cwd=REPO_ROOT,
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )

    @staticmethod
    def write_executable(path: Path, command: str) -> None:
        path.write_text(f"#!/bin/sh\n{command}", encoding="utf-8")
        path.chmod(0o755)


if __name__ == "__main__":
    unittest.main()

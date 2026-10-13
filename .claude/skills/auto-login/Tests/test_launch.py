"""Host CLI tests: iOS test targets cannot execute the macOS launch helper."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class LaunchTests(unittest.TestCase):
    def setUp(self):
        self.repository = Path(__file__).resolve().parents[4]
        self.script = self.repository / ".claude/skills/auto-login/Scripts/launch.sh"
        self.temporary = tempfile.TemporaryDirectory(prefix="auto-login-tests-")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        binary_directory = self.directory / "bin"
        binary_directory.mkdir()
        self.log = self.directory / "calls.jsonl"
        xcrun = binary_directory / "xcrun"
        xcrun.write_text("""#!/usr/bin/env python3
import json, os, sys
with open(os.environ['TEST_CALLS'], 'a') as output:
    output.write(json.dumps({'args': sys.argv[1:], 'credentials': {
        key: value for key, value in os.environ.items()
        if key.startswith('SIMCTL_CHILD_DEBUG_LOGIN_')}}) + '\\n')
print('Mock simulator process')
""")
        xcrun.chmod(0o700)
        sleep = binary_directory / "sleep"
        sleep.write_text("#!/bin/bash\nexit 0\n")
        sleep.chmod(0o700)
        self.environment = dict(os.environ, PATH=str(binary_directory) + os.pathsep + os.environ["PATH"],
                                TEST_CALLS=str(self.log))
        for key in list(self.environment):
            if key.startswith("SIMCTL_CHILD_DEBUG_LOGIN_"):
                del self.environment[key]
        self.site = "https://fixture.jurassic.ninja"
        self.marker = self.directory / "must-not-exist"
        self.secret = "fake-secret $(touch " + str(self.marker) + ") with spaces"
        self.data = "SITE_URL={}\nUSERNAME=demo\nWP_PASSWORD={}\n".format(self.site, self.secret)
        self.file = self.directory / "credentials.env"
        self.file.write_text(self.data)
        self.file.chmod(0o600)

    def run_launch(self, arguments, success=True, shell="/bin/bash"):
        if self.log.exists():
            self.log.unlink()
        result = subprocess.run([shell, "-x", str(self.script)] + arguments,
                                env=self.environment, universal_newlines=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.assertEqual(result.returncode == 0, success, result.stderr)
        self.assertNotIn(self.secret, result.stdout + result.stderr)
        self.assertNotIn("user:secret@", result.stdout + result.stderr)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []
        if not success:
            self.assertEqual(calls, [], "Rejected input reached simctl")
        return calls

    def file_arguments(self, site=None, path=None):
        return ["--from-environment", "fixture-udid", site or self.site, str(path or self.file)]

    def test_file_launch_when_valid_then_keeps_secret_literal_and_relaunches_without_credentials(self):
        # Given / When: run the native macOS shell and Homebrew shell when installed.
        shells = ["/bin/bash"]
        if Path("/opt/homebrew/bin/bash").exists():
            shells.append("/opt/homebrew/bin/bash")
        for shell in shells:
            with self.subTest(shell=shell):
                calls = self.run_launch(self.file_arguments(site=self.site + "/"), shell=shell)
                # Then: no secret output, shell execution, or credentials on the plain relaunch.
                self.assertEqual([call["args"][1] for call in calls], ["terminate", "launch", "terminate", "launch"])
                self.assertEqual(calls[1]["credentials"]["SIMCTL_CHILD_DEBUG_LOGIN_SECRET"], self.secret)
                self.assertEqual(calls[1]["credentials"]["SIMCTL_CHILD_DEBUG_LOGIN_AUTH_TYPE"], "wporg")
                self.assertEqual(calls[1]["credentials"]["SIMCTL_CHILD_DEBUG_LOGIN_USERNAME"], "demo")
                self.assertEqual(calls[-1]["credentials"], {})
                self.assertFalse(self.marker.exists())

    def test_file_launch_when_caller_has_debug_variables_then_plain_relaunch_clears_them(self):
        # Given
        for name in ("SITE_ADDRESS", "USERNAME", "SECRET", "AUTH_TYPE", "STORE_ID"):
            self.environment["SIMCTL_CHILD_DEBUG_LOGIN_" + name] = "stale-caller-value"
        # When
        calls = self.run_launch(self.file_arguments())
        # Then
        self.assertEqual(calls[1]["credentials"]["SIMCTL_CHILD_DEBUG_LOGIN_SECRET"], self.secret)
        self.assertNotIn("SIMCTL_CHILD_DEBUG_LOGIN_STORE_ID", calls[1]["credentials"])
        self.assertEqual(calls[-1]["credentials"], {})

    def test_file_launch_when_site_or_permissions_are_wrong_then_rejects_before_launch(self):
        # Given / When / Then
        self.run_launch(self.file_arguments(site="https://other.example"), success=False)
        self.file.chmod(0o644)
        self.run_launch(self.file_arguments(), success=False)
        self.file.chmod(0o600)
        for site in ["http://fixture.example", "https:///missing-host", "https://user:secret@fixture.example",
                     "https://fixture.example?token=secret", "https://fixture.example#secret",
                     "https://fixture.example/ bad", "https://fixture.example\\other",
                     "https://user:secret@[broken", "https://user:secret@fixture.example\uff0fother"]:
            with self.subTest(site=site):
                self.file.write_text(self.data.replace(self.site, site))
                self.run_launch(self.file_arguments(site=site), success=False)

    def test_file_launch_when_path_is_unsafe_then_rejects_before_launch(self):
        # Given
        symlink = self.directory / "linked.env"
        symlink.symlink_to(self.file)
        fifo = self.directory / "pipe.env"
        os.mkfifo(str(fifo), 0o600)
        # When / Then: also reject non-regular files without blocking on a FIFO.
        for path in [symlink, fifo, self.directory, "relative.env"]:
            with self.subTest(path=path):
                self.run_launch(self.file_arguments(path=path), success=False)
        descriptor, filename = tempfile.mkstemp(prefix=".auto-login-test-", dir=str(self.repository))
        try:
            with os.fdopen(descriptor, "w") as output:
                output.write(self.data)
            self.run_launch(self.file_arguments(path=filename), success=False)
        finally:
            os.unlink(filename)

    def test_file_launch_when_data_is_invalid_then_rejects_before_launch(self):
        # Given
        invalid = [self.data.replace("WP_PASSWORD=", "APP_PASSWORD="), self.data + "USERNAME=second\n", self.data.replace("WP_PASSWORD=", "UNEXPECTED="),
                   self.data.replace("USERNAME=demo\n", ""), self.data.replace(self.secret, ""),
                   self.data + "\0", self.data + "X" * 65537]
        # When / Then
        for data in invalid:
            with self.subTest(case=invalid.index(data)):
                self.file.write_text(data)
                self.run_launch(self.file_arguments(), success=False)
        self.file.write_bytes(b"\xff")
        self.run_launch(self.file_arguments(), success=False)

    def test_positional_launch_when_auth_type_is_supported_then_preserves_compatibility(self):
        # Given / When / Then
        base = ["fixture-udid", self.site, "demo", "fake-password"]
        for arguments, auth_type in [(base, "wporg"), (base + ["applicationPassword"], "applicationPassword"),
                                     (base + ["wpcom", "123456"], "wpcom")]:
            with self.subTest(auth_type=auth_type):
                calls = self.run_launch(arguments)
                self.assertEqual(calls[1]["credentials"]["SIMCTL_CHILD_DEBUG_LOGIN_AUTH_TYPE"], auth_type)
                if auth_type == "wpcom":
                    self.assertEqual(calls[1]["credentials"]["SIMCTL_CHILD_DEBUG_LOGIN_STORE_ID"], "123456")

    def test_launch_when_arguments_are_incomplete_or_invalid_then_rejects_before_launch(self):
        # Given / When / Then
        base = ["fixture-udid", self.site, "demo", "fake-password"]
        for arguments in [[], self.file_arguments()[:-1], base + ["wpcom"], base + ["unsupported"]]:
            with self.subTest(arguments=arguments):
                self.run_launch(arguments, success=False)


if __name__ == "__main__":
    unittest.main()

import json
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "count-warnings.sh"


class OutputPathTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="strict concurrency ")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name).resolve()
        self.repo = self.root / "fixture repo"
        self.repo.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.tmp = self.root / "temporary output"
        self.tmp.mkdir()
        self.calls = self.root / "xcodebuild calls.jsonl"
        self.output = self.repo / "warnings.json"
        self.env = {
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "HOME": str(self.root),
            "TMPDIR": str(self.tmp) + "/",
            "FIXTURE_REPO": str(self.repo),
            "XCODE_CALLS": str(self.calls),
        }
        subprocess.run(["/usr/bin/git", "init", "-q", str(self.repo)],
                       env=self.env, check=True, capture_output=True)
        fake = self.bin / "xcodebuild"
        fake.write_text('''#!/usr/bin/python3
import json, os, sys
with open(os.environ["XCODE_CALLS"], "a") as calls:
    calls.write(json.dumps(sys.argv[1:]) + "\\n")
print(os.environ["FIXTURE_REPO"] + "/Example.swift:1:1: warning: fixture warning")
print("fixture stderr", file=sys.stderr)
sys.exit(int(os.environ.get("FAKE_BUILD_STATUS", "0")))
''')
        fake.chmod(0o755)

    def run_counter(self, **overrides):
        return subprocess.run(["/bin/bash", str(SCRIPT), str(self.output)],
                              cwd=self.repo, env={**self.env, **overrides},
                              text=True, capture_output=True)

    def recorded_arguments(self):
        return [json.loads(line) for line in self.calls.read_text().splitlines()]

    def assert_warning_json(self):
        self.assertEqual(json.loads(self.output.read_text()),
                         {"total": 1, "perFile": {"Example.swift": 1}})

    def test_explicit_paths_with_spaces_create_missing_log_parent(self):
        log = self.repo / "new evidence folder" / "build output.log"
        derived = self.repo / "local build data" / "DerivedData"
        result = self.run_counter(STRICT_CONCURRENCY_BUILD_LOG=str(log),
                                  STRICT_CONCURRENCY_DERIVED_DATA=str(derived))
        self.assertEqual(result.returncode, 0, result.stderr)
        args = self.recorded_arguments()[0]
        self.assertEqual(args[args.index("-derivedDataPath") + 1], str(derived))
        self.assertIn("fixture warning", log.read_text())
        self.assertIn("fixture stderr", log.read_text())
        self.assert_warning_json()

    def test_default_paths_are_fresh_temporary_directories(self):
        # macOS mktemp without a template can ignore TMPDIR. Confine its output
        # to the fixture while retaining real fresh-directory creation.
        mktemp = self.bin / "mktemp"
        mktemp.write_text('#!/bin/bash\n[[ "$#" == 1 && "$1" == -d ]] || exit 90\n'
                          'exec /usr/bin/mktemp -d "$TMPDIR/fixture.XXXXXXXX"\n')
        mktemp.chmod(0o755)
        logs = []
        for _ in range(2):
            result = self.run_counter()
            self.assertEqual(result.returncode, 0, result.stderr)
            log = Path(re.search(r"\(log: (.+)\)", result.stdout).group(1))
            self.assertTrue(log.is_file())
            self.assertTrue(log.resolve().is_relative_to(self.tmp))
            self.assertEqual(log.name, "strict-concurrency-build.log")
            logs.append(log)
        paths = [Path(args[args.index("-derivedDataPath") + 1])
                 for args in self.recorded_arguments()]
        self.assertNotEqual(logs[0], logs[1])
        self.assertNotEqual(paths[0], paths[1])
        for path in paths:
            self.assertTrue(path.parent.is_dir())
            self.assertTrue(path.resolve().is_relative_to(self.tmp))
            self.assertEqual(path.name, "DerivedData")
        self.assert_warning_json()

    def test_failed_build_keeps_status_and_log_without_warning_json(self):
        log = self.repo / "failed build" / "build.log"
        result = self.run_counter(STRICT_CONCURRENCY_BUILD_LOG=str(log),
                                  FAKE_BUILD_STATUS="42")
        self.assertEqual(result.returncode, 42, result.stderr)
        self.assertIn("fixture stderr", log.read_text())
        self.assertEqual((self.repo / "strict-concurrency-build-failed.log").read_text(),
                         log.read_text())
        self.assertFalse(self.output.exists())

    def test_existing_log_bypasses_build_and_new_output_override(self):
        existing = self.repo / "existing.log"
        existing.write_text(f"{self.repo}/Example.swift:1:1: warning: saved warning\n")
        unused = self.repo / "unused output" / "build.log"
        result = self.run_counter(STRICT_CONCURRENCY_LOG=str(existing),
                                  STRICT_CONCURRENCY_BUILD_LOG=str(unused),
                                  FAKE_BUILD_STATUS="42")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.calls.exists())
        self.assertFalse(unused.parent.exists())
        self.assert_warning_json()

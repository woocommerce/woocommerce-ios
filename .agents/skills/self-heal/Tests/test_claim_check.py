import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "Scripts/claim-check"


def stub(directory, name, body):
    path = Path(directory) / name
    path.write_text("#!/usr/bin/env bash\n" + body)
    path.chmod(0o755)


class ClaimCheckTests(unittest.TestCase):
    def run_check(self, github="", linear=None):
        linear = linear or {"data": {"attachments": {"nodes": []}, "issues": {"nodes": []}}}
        with tempfile.TemporaryDirectory() as bin_dir:
            Path(bin_dir, "linear.json").write_text(json.dumps(linear))
            Path(bin_dir, "github.txt").write_text(github)
            stub(bin_dir, "gh", f'cat "{bin_dir}/github.txt"\n')
            stub(bin_dir, "curl", f'cat "{bin_dir}/linear.json"\n')
            env = {**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}", "LINEAR_API_KEY": "test"}
            return subprocess.run([str(SCRIPT), "42", "WOOCOMMERCE-IOS-1AB"], env=env,
                                  capture_output=True, text=True, check=True).stdout

    def test_unclaimed_crash_prints_nothing(self):
        self.assertEqual(self.run_check(), "")

    def test_github_claim_is_reported(self):
        output = self.run_check(github="github #7 OPEN: Crash: WOOCOMMERCE-IOS-1AB\n")
        self.assertIn("github #7", output)

    def test_linear_claim_via_sentry_link_or_text_is_reported_once(self):
        issue = {"identifier": "WOOMOB-9", "title": "Crash", "state": {"name": "Todo"}}
        output = self.run_check(linear={"data": {
            "attachments": {"nodes": [{"issue": issue}]},
            "issues": {"nodes": [issue]},
        }})
        self.assertEqual(output, "linear WOOMOB-9 Todo: Crash\n")


if __name__ == "__main__":
    unittest.main()

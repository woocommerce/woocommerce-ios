import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "Scripts/cap"


def pr(number, branch, created="2026-11-07T00:00:00Z"):
    return {"number": number, "headRefName": branch, "createdAt": created}


ME = {"login": "self-heal-bot"}
SOMEONE = {"login": "someone"}
CRASH = [{"name": "type: crash"}]


def issue(number, status):
    return {"number": number, "author": ME, "labels": CRASH, "comments": [],
            "body": f"Crash details\n\nStatus: {status}\n"}


def reported_issue(number, *comments):
    return {"number": number, "author": SOMEONE, "labels": [], "body": "Steps to reproduce",
            "comments": [{"author": author, "body": body} for author, body in comments]}


class CapTests(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.dir.cleanup)
        self.mark = Path(self.dir.name, "cap-reset")

    def run_cap(self, *args, prs=(), issues=()):
        bin_dir = self.dir.name
        Path(bin_dir, "prs.json").write_text(json.dumps(list(prs)))
        Path(bin_dir, "issues.json").write_text(json.dumps(list(issues)))
        gh = Path(bin_dir, "gh")
        gh.write_text(f'#!/usr/bin/env bash\ncat "{bin_dir}/$1s.json"\n')
        gh.chmod(0o755)
        env = {**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}", "SELF_HEAL_CAP_MARK": str(self.mark),
               "SELF_HEAL_GH_USER": ME["login"]}
        return subprocess.run([str(SCRIPT), *args], env=env, capture_output=True, text=True, check=True).stdout

    def test_five_open_fix_prs_fill_the_cap(self):
        output = self.run_cap(prs=[pr(n, f"self-heal/crash-{n}") for n in range(5)])
        self.assertIn("fix-slot full", output)

    def test_validation_and_unrelated_prs_do_not_count(self):
        prs = [pr(n, f"self-heal/crash-{n}") for n in range(4)]
        prs += [pr(10, "self-heal/crash-10-red"), pr(11, "mokagio/other-work")]
        self.assertIn("fix-slot free", self.run_cap(prs=prs))

    def test_reset_stops_existing_fix_prs_counting(self):
        self.run_cap("reset")
        output = self.run_cap(prs=[pr(n, f"self-heal/crash-{n}") for n in range(5)])
        self.assertIn("fix PRs counted: 0/5", output)
        self.assertIn("fix-slot free", output)

    def test_fix_prs_opened_after_reset_count_again(self):
        self.mark.write_text("2026-11-11T00:00:00Z\n")
        prs = [pr(n, f"self-heal/crash-{n}", created="2026-11-12T00:00:00Z") for n in range(5)]
        self.assertIn("fix-slot full", self.run_cap(prs=prs))

    def test_briefs_exclude_crashes_with_a_fix_pr_or_a_human(self):
        issues = [
            issue(1, "investigating"),
            issue(2, "red proven, fix PR pending"),
            issue(3, "PR #9 ready for review"),
            issue(4, "needs human"),
        ]
        self.assertIn("briefs: 2/5 [1,2]", self.run_cap(issues=issues))

    def test_reported_issue_is_a_brief_by_the_status_in_our_last_comment(self):
        issues = [
            reported_issue(1, (ME, "Status: red proven, fix PR pending")),
            reported_issue(2, (ME, "Status: red proven, fix PR pending"), (ME, "Status: PR #9 awaiting green build")),
            reported_issue(3, (SOMEONE, "Status: whatever")),
            reported_issue(4),
        ]
        self.assertIn("briefs: 1/5 [1]", self.run_cap(issues=issues))

    def test_five_briefs_fill_the_brief_cap(self):
        issues = [issue(n, "red proven, fix PR pending") for n in range(5)]
        self.assertIn("brief-slot full", self.run_cap(issues=issues))


if __name__ == "__main__":
    unittest.main()

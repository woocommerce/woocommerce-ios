import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "Scripts/trunk-sync"


class TrunkSyncTests(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.dir.cleanup)
        root = Path(self.dir.name)
        self.origin = root / "origin.git"
        self.work = root / "work"
        self.runner = root / "runner"
        self.bin = root / "bin"
        self.bin.mkdir()
        self.git(root, "init", "--quiet", "--bare", "--initial-branch=trunk", str(self.origin))
        self.git(root, "clone", "--quiet", str(self.origin), str(self.work))
        self.commit("shared.swift", "one\ntwo\nthree\n")
        self.git(self.work, "push", "--quiet", "origin", "HEAD:trunk")
        self.git(root, "clone", "--quiet", str(self.origin), str(self.runner))
        self.prs = []

    def git(self, cwd, *args):
        env = {**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
               "GIT_COMMITTER_EMAIL": "t@t", "GIT_CONFIG_GLOBAL": "/dev/null"}
        return subprocess.run(["git", *args], cwd=cwd, env=env, capture_output=True, text=True, check=True).stdout

    def commit(self, path, content):
        Path(self.work, path).write_text(content)
        self.git(self.work, "add", path)
        self.git(self.work, "commit", "--quiet", "-m", path)

    def open_pr(self, number, branch, path, content):
        self.git(self.work, "switch", "--quiet", "-c", branch, "origin/trunk")
        self.commit(path, content)
        self.git(self.work, "push", "--quiet", "origin", branch)
        self.git(self.work, "switch", "--quiet", "--detach", "origin/trunk")
        self.prs.append({"number": number, "headRefName": branch})

    def advance_trunk(self, path, content):
        self.git(self.work, "switch", "--quiet", "--detach", "origin/trunk")
        self.commit(path, content)
        self.git(self.work, "push", "--quiet", "origin", "HEAD:trunk")
        self.git(self.work, "fetch", "--quiet", "origin")

    def run_sync(self, **env):
        Path(self.bin, "prs.json").write_text(json.dumps(self.prs))
        gh = Path(self.bin, "gh")
        gh.write_text(f'#!/usr/bin/env bash\ncat "{self.bin}/prs.json"\n')
        gh.chmod(0o755)
        env = {**os.environ, "PATH": f"{self.bin}:{os.environ['PATH']}", "GIT_CONFIG_GLOBAL": "/dev/null", **env}
        return subprocess.run([str(SCRIPT)], cwd=self.runner, env=env, capture_output=True, text=True,
                              check=True).stdout

    def test_pr_on_latest_trunk_is_current(self):
        self.open_pr(1, "self-heal/crash-1", "fix.swift", "fix\n")
        self.assertEqual("#1 self-heal/crash-1 current behind=0\n", self.run_sync())

    def test_pr_behind_on_unrelated_recent_files_waits(self):
        self.open_pr(1, "self-heal/crash-1", "fix.swift", "fix\n")
        self.advance_trunk("other.swift", "other\n")
        self.assertEqual("#1 self-heal/crash-1 current behind=1\n", self.run_sync())

    def test_trunk_changing_a_file_the_pr_touches_needs_a_sync(self):
        self.open_pr(1, "self-heal/crash-1", "shared.swift", "one\ntwo\nthree\nfour\n")
        self.advance_trunk("shared.swift", "zero\none\ntwo\nthree\n")
        self.assertEqual("#1 self-heal/crash-1 sync overlap behind=1 shared.swift\n", self.run_sync())

    def test_conflicting_trunk_change_needs_a_sync(self):
        self.open_pr(1, "self-heal/crash-1", "shared.swift", "one\nTWO\nthree\n")
        self.advance_trunk("shared.swift", "one\n2\nthree\n")
        self.assertEqual("#1 self-heal/crash-1 sync conflict behind=1 shared.swift\n", self.run_sync())

    def test_pr_built_on_old_trunk_needs_a_sync(self):
        self.open_pr(1, "self-heal/crash-1", "fix.swift", "fix\n")
        self.advance_trunk("other.swift", "other\n")
        output = self.run_sync(SELF_HEAL_SYNC_MAX_AGE_HOURS="0")
        self.assertEqual("#1 self-heal/crash-1 sync stale behind=1\n", output)

    def test_validation_prs_are_checked_and_unrelated_prs_ignored(self):
        self.open_pr(1, "self-heal/crash-1-red", "shared.swift", "one\ntwo\nthree\nfour\n")
        self.open_pr(2, "mokagio/other-work", "shared.swift", "one\ntwo\nthree\nfive\n")
        self.advance_trunk("shared.swift", "zero\none\ntwo\nthree\n")
        self.assertEqual("#1 self-heal/crash-1-red sync overlap behind=1 shared.swift\n", self.run_sync())

    def test_no_open_prs_prints_nothing(self):
        self.assertEqual("", self.run_sync())


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "lint-env.py"
SPEC = importlib.util.spec_from_file_location("lint_env", SCRIPT)
assert SPEC and SPEC.loader
LINT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(LINT)


class LintEnvTests(unittest.TestCase):
    def test_rejects_unquoted_closing_parenthesis_without_echoing_value(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env = root / ".env.local"
            example = root / "env.example"
            env.write_text("MAESTRO_WOO_LAB_WPCOM_PASSWORD=secret)\n")
            example.write_text("MAESTRO_WOO_LAB_WPCOM_PASSWORD=\n")
            errors, _, _ = LINT.lint(env, example, False)
            self.assertTrue(errors)
            self.assertNotIn("secret", " ".join(errors))

    def test_accepts_single_quoted_shell_metacharacters(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env = root / ".env.local"
            example = root / "env.example"
            env.write_text("MAESTRO_WOO_LAB_WPCOM_PASSWORD='safe ) value'\n")
            example.write_text("MAESTRO_WOO_LAB_WPCOM_PASSWORD=\n")
            errors, _, _ = LINT.lint(env, example, False)
            self.assertEqual([], errors)


if __name__ == "__main__":
    unittest.main()

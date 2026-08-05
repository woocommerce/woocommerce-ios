import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "check-smoke-coverage.py"


class CheckSmokeCoverageTests(unittest.TestCase):
    def test_rejects_item_declared_by_a_different_flow_than_its_mapping(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            flows = root / "flows"
            flows.mkdir()
            (flows / "mapped.yaml").write_text("# p2: other.item\n", encoding="utf-8")
            (flows / "claiming.yaml").write_text("# p2: target.item\n", encoding="utf-8")
            coverage = root / "coverage.yaml"
            coverage.write_text(
                "items:\n"
                "  - id: target.item\n"
                f"    flow: {flows / 'mapped.yaml'}\n"
                "  - id: other.item\n"
                f"    flow: {flows / 'mapped.yaml'}\n",
                encoding="utf-8",
            )

            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--coverage", str(coverage), "--flows-dir", str(flows)],
                capture_output=True,
                text=True,
                check=False,
            )

        self.assertEqual(1, result.returncode)
        self.assertIn("target.item", result.stderr)
        self.assertIn("mapped.yaml", result.stderr)

    def test_rejects_duplicate_item_ids(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            flows = root / "flows"
            flows.mkdir()
            (flows / "flow.yaml").write_text("# p2: duplicate.item\n", encoding="utf-8")
            coverage = root / "coverage.yaml"
            coverage.write_text(
                "items:\n"
                "  - id: duplicate.item\n"
                f"    flow: {flows / 'flow.yaml'}\n"
                "  - id: duplicate.item\n"
                f"    flow: {flows / 'flow.yaml'}\n",
                encoding="utf-8",
            )

            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--coverage", str(coverage), "--flows-dir", str(flows)],
                capture_output=True,
                text=True,
                check=False,
            )

        self.assertEqual(1, result.returncode)
        self.assertIn("duplicate item id duplicate.item", result.stderr)

    def test_rejects_an_item_that_is_both_automated_and_manual(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            flows = root / "flows"
            flows.mkdir()
            flow = flows / "flow.yaml"
            flow.write_text("# p2: ambiguous.item\n", encoding="utf-8")
            coverage = root / "coverage.yaml"
            coverage.write_text(
                "items:\n"
                "  - id: ambiguous.item\n"
                f"    flow: {flow}\n"
                "    manual: This must not be accepted as both states.\n",
                encoding="utf-8",
            )

            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--coverage", str(coverage), "--flows-dir", str(flows)],
                capture_output=True,
                text=True,
                check=False,
            )

        self.assertEqual(1, result.returncode)
        self.assertIn("ambiguous.item has both flow and manual reason", result.stderr)


if __name__ == "__main__":
    unittest.main()

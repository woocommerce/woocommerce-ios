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

    def test_accepts_partial_flow_with_gap_and_reports_fidelity_counts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            flows = root / "flows"
            flows.mkdir()
            partial_flow = flows / "partial.yaml"
            full_flow = flows / "full.yaml"
            partial_flow.write_text("# p2: partial.item\n", encoding="utf-8")
            full_flow.write_text("# p2: full.item\n", encoding="utf-8")
            coverage = root / "coverage.yaml"
            coverage.write_text(
                "items:\n"
                "  - id: partial.item\n"
                f"    flow: {partial_flow}\n"
                "    fidelity: partial\n"
                "    gap: Entry point only.\n"
                "  - id: full.item\n"
                f"    flow: {full_flow}\n"
                "  - id: manual.item\n"
                "    manual: External dependency.\n",
                encoding="utf-8",
            )

            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--coverage", str(coverage), "--flows-dir", str(flows)],
                capture_output=True,
                text=True,
                check=False,
            )

        self.assertEqual(0, result.returncode)
        self.assertIn("1 full, 1 partial, 1 manual", result.stdout)

    def test_rejects_partial_flow_without_gap(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            flows = root / "flows"
            flows.mkdir()
            flow = flows / "flow.yaml"
            flow.write_text("# p2: partial.item\n", encoding="utf-8")
            coverage = root / "coverage.yaml"
            coverage.write_text(
                "items:\n"
                "  - id: partial.item\n"
                f"    flow: {flow}\n"
                "    fidelity: partial\n",
                encoding="utf-8",
            )

            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--coverage", str(coverage), "--flows-dir", str(flows)],
                capture_output=True,
                text=True,
                check=False,
            )

        self.assertEqual(1, result.returncode)
        self.assertIn("partial item partial.item has no gap explanation", result.stderr)

    def test_rejects_unknown_fidelity(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            flows = root / "flows"
            flows.mkdir()
            flow = flows / "flow.yaml"
            flow.write_text("# p2: target.item\n", encoding="utf-8")
            coverage = root / "coverage.yaml"
            coverage.write_text(
                "items:\n"
                "  - id: target.item\n"
                f"    flow: {flow}\n"
                "    fidelity: approximate\n",
                encoding="utf-8",
            )

            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--coverage", str(coverage), "--flows-dir", str(flows)],
                capture_output=True,
                text=True,
                check=False,
            )

        self.assertEqual(1, result.returncode)
        self.assertIn("unknown fidelity 'approximate'", result.stderr)


if __name__ == "__main__":
    unittest.main()

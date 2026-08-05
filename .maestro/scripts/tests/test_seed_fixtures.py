from __future__ import annotations

import argparse
import importlib.util
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "seed-fixtures.py"
SPEC = importlib.util.spec_from_file_location("ios_seed_fixtures", SCRIPT)
assert SPEC and SPEC.loader
SEED = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = SEED
SPEC.loader.exec_module(SEED)


class FakeClient:
    def __init__(self, *, fail_delete_id: int | None = None) -> None:
        self.fail_delete_id = fail_delete_id
        self.deleted: list[tuple[str, int]] = []

    def list(self, path: str, **query: object) -> list[dict[str, object]]:
        if path == "products":
            return [
                {"id": 11, "name": "Media SUITE-20260805T120000Z-abc123"},
                {"id": 12, "name": "Merchant product"},
            ]
        return [
            {
                "id": 21,
                "customer_note": "Cash SUITE-20260805T120000Z-abc123",
                "line_items": [],
                "meta_data": [],
            },
            {
                "id": 22,
                "customer_note": "Merchant order",
                "line_items": [],
                "meta_data": [],
            },
        ]

    def delete(self, path: str, entity_id: int) -> None:
        if entity_id == self.fail_delete_id:
            raise SEED.SmokeSetupError("injected deletion failure")
        self.deleted.append((path, entity_id))


class SeedFixtureTests(unittest.TestCase):
    def setUp(self) -> None:
        self.environment = mock.patch.dict(
            os.environ,
            {
                "MAESTRO_WOO_LAB_JETPACK_STORE_URL": "https://shop.example.com",
                "MAESTRO_WOO_CONSUMER_KEY": "ck_test",
                "MAESTRO_WOO_CONSUMER_SECRET": "cs_test",
            },
            clear=False,
        )
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def test_seed_initializes_a_cleanup_journal_before_ui_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "manifest.json"
            args = argparse.Namespace(
                run_id="SUITE-20260805T120000Z-abc123",
                manifest=manifest,
            )

            SEED.initialize(args)

            contents = json.loads(manifest.read_text(encoding="utf-8"))
            self.assertEqual(args.run_id, contents["run_id"])
            self.assertEqual([], contents["entities"])
            self.assertIn("created_at", contents)

    def test_cleanup_deletes_only_exact_run_owned_entities(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "manifest.json"
            args = argparse.Namespace(
                run_id="SUITE-20260805T120000Z-abc123",
                manifest=manifest,
            )
            SEED.initialize(args)
            client = FakeClient()

            with mock.patch.object(SEED, "WooClient", return_value=client):
                SEED.cleanup(args)

            self.assertEqual([("orders", 21), ("products", 11)], client.deleted)
            contents = json.loads(manifest.read_text(encoding="utf-8"))
            self.assertEqual([], contents["entities"])

    def test_partial_cleanup_keeps_only_entities_that_still_need_deletion(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "manifest.json"
            args = argparse.Namespace(
                run_id="SUITE-20260805T120000Z-abc123",
                manifest=manifest,
            )
            SEED.initialize(args)
            client = FakeClient(fail_delete_id=11)

            with (
                mock.patch.object(SEED, "WooClient", return_value=client),
                self.assertRaisesRegex(SEED.SmokeSetupError, "1 deletion error"),
            ):
                SEED.cleanup(args)

            contents = json.loads(manifest.read_text(encoding="utf-8"))
            self.assertEqual([{"type": "product", "id": 11}], contents["entities"])


if __name__ == "__main__":
    unittest.main()

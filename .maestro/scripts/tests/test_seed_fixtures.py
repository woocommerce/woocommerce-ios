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
                {
                    "id": 11,
                    "name": "Media SUITE-20260805T120000Z-abc123",
                    "images": [{"id": 101}],
                },
                {"id": 12, "name": "Merchant product", "images": [{"id": 102}]},
            ]
        if path == "products/tags":
            return [
                {"id": 31, "name": "maestro-SUITE-20260805T120000Z-abc123"},
                {"id": 32, "name": "merchant-tag"},
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

    def delete(self, path: str, entity_id: int, *, prefix: str | None = None) -> None:
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

    def test_rest_datetime_strips_offset_and_microseconds(self) -> None:
        """The API's `after` filter returns nothing when the offset is present.

        `created_at` is written as a full ISO 8601 UTC timestamp, which the
        WooCommerce REST API rejects for date filtering. Measured against a live
        store: 0 rows with the offset, 5 rows without it.
        """
        self.assertEqual(
            "2026-09-09T05:29:41",
            SEED.rest_datetime("2026-09-09T05:29:41.207439+00:00"),
        )
        self.assertEqual("2026-09-09T05:29:41", SEED.rest_datetime("2026-09-09T05:29:41Z"))
        self.assertEqual("2026-09-09T05:29:41", SEED.rest_datetime("2026-09-09T05:29:41"))

    def test_cleanup_collects_run_owned_auto_drafts_but_leaves_unattributed_ones(self) -> None:
        """`status=any` excludes auto-draft, so drafts need their own query.

        A draft carrying the run ID is ours. One without it cannot be told apart
        from a merchant part-way through writing an order, so it is left alone.
        """
        run_id = "SUITE-20260805T120000Z-abc123"

        class StatusAwareClient(FakeClient):
            def list(self, path: str, **query: object) -> list[dict[str, object]]:
                if path != "orders":
                    return []
                if query.get("status") == "auto-draft":
                    return [
                        {
                            "id": 41,
                            "customer_note": "",
                            "line_items": [],
                            "fee_lines": [{"name": f"QR {run_id}"}],
                            "meta_data": [],
                        },
                        {
                            "id": 42,
                            "customer_note": "",
                            "line_items": [],
                            "fee_lines": [],
                            "meta_data": [],
                        },
                    ]
                return []

        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "manifest.json"
            args = argparse.Namespace(run_id=run_id, manifest=manifest)
            SEED.initialize(args)
            client = StatusAwareClient()

            with mock.patch.object(SEED, "WooClient", return_value=client):
                SEED.cleanup(args)

            # 41 carries the run ID in a fee line; 42 is unattributable.
            self.assertEqual([("orders", 41)], client.deleted)

    def test_order_contains_run_id_matches_custom_amount_fee_lines(self) -> None:
        """Custom amounts are fee lines, not line items.

        The QR and share-payment flows stamp the run ID only on a custom amount,
        so without this those orders can never be attributed.
        """
        run_id = "SUITE-20260805T120000Z-abc123"
        order = {
            "customer_note": "",
            "line_items": [],
            "fee_lines": [{"name": f"Share {run_id}"}],
            "meta_data": [],
        }

        self.assertTrue(SEED.order_contains_run_id(order, run_id))
        self.assertFalse(
            SEED.order_contains_run_id(
                {"customer_note": "", "line_items": [], "fee_lines": [{"name": "Gift wrap"}], "meta_data": []},
                run_id,
            )
        )

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

            # Tags are discovered last and the deletion loop is reversed, so ordering is
            # tag → order → the product's uploaded media → product. The merchant's own
            # product (and its image 102), order, and tag are left untouched.
            self.assertEqual(
                [("products/tags", 31), ("orders", 21), ("media", 101), ("products", 11)],
                client.deleted,
            )
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

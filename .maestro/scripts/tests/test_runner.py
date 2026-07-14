from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "run-smoke-tests.py"
SPEC = importlib.util.spec_from_file_location("runner", SCRIPT)
assert SPEC and SPEC.loader
RUNNER = importlib.util.module_from_spec(SPEC)
import sys
sys.modules[SPEC.name] = RUNNER
SPEC.loader.exec_module(RUNNER)


class RunnerTests(unittest.TestCase):
    def test_redacts_all_woo_values(self) -> None:
        values = {"MAESTRO_WOO_LAB_WPCOM_PASSWORD": "do-not-print"}
        self.assertEqual("failure: <redacted>", RUNNER.redact("failure: do-not-print", values))

    def test_flow_status_reports_pass_flaky_and_fail(self) -> None:
        self.assertEqual("PASS", RUNNER.flow_status([0]))
        self.assertEqual("FLAKY", RUNNER.flow_status([1, 0]))
        self.assertEqual("FAIL", RUNNER.flow_status([1, 1]))

    def test_profile_contract(self) -> None:
        self.assertEqual("iphone", RUNNER.PROFILES["core"][3])
        self.assertEqual("ipad", RUNNER.PROFILES["pos-ipad"][3])
        self.assertNotIn("flaky_quarantine", RUNNER.PROFILES["release"][0])

    def test_sanitize_artifacts_redacts_text_and_removes_login_images(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "commands.json").write_text('{"email":"merchant@example.com"}')
            (root / "screen.png").write_bytes(b"image")
            RUNNER.sanitize_artifacts(
                root,
                {"MAESTRO_WOO_LAB_WPCOM_EMAIL": "merchant@example.com"},
                remove_images=True,
            )
            self.assertNotIn("merchant@example.com", (root / "commands.json").read_text())
            self.assertFalse((root / "screen.png").exists())

    def test_app_identifier_is_dynamic(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory) / "Prototype.app"
            app.mkdir()
            (app / "Info.plist").write_text(
                '<?xml version="1.0" encoding="UTF-8"?>'
                '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
                '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
                '<plist version="1.0"><dict><key>CFBundleIdentifier</key>'
                '<string>com.automattic.alpha.woocommerce</string></dict></plist>'
            )
            self.assertEqual("com.automattic.alpha.woocommerce", RUNNER.app_identifier(app))

    def test_maestro_env_args_derives_lab_store_host(self) -> None:
        args = RUNNER.maestro_env_args(
            {"MAESTRO_WOO_LAB_JETPACK_STORE_URL": "http://shop.example.com/path"},
            "com.example.app",
            "run-1",
        )

        self.assertIn("MAESTRO_WOO_LAB_JETPACK_STORE_HOST=shop.example.com", args)

    def test_selected_flow_environment_is_required_but_consumer_keys_are_not(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            flow = Path(directory) / "flow.yaml"
            flow.write_text("appId: ${APP_ID}\n---\n- inputText: ${MAESTRO_WOO_VARIABLE_PRODUCT_NAME}\n")
            required = RUNNER.required_environment([flow], seed=False)
            self.assertIn("MAESTRO_WOO_VARIABLE_PRODUCT_NAME", required)
            self.assertNotIn("MAESTRO_WOO_CONSUMER_KEY", required)

    def test_not_woo_store_requires_site_admin_credentials_only(self) -> None:
        flow = RUNNER.FLOWS_DIR / "login_not_woo_store.yaml"

        required = RUNNER.required_environment([flow], seed=False)

        self.assertIn("MAESTRO_WOO_NOT_A_WOO_STORE_URL", required)
        self.assertIn("MAESTRO_WOO_NOT_A_WOO_STORE_SITE_ADMIN_USERNAME", required)
        self.assertIn("MAESTRO_WOO_NOT_A_WOO_STORE_SITE_ADMIN_PASSWORD", required)
        self.assertNotIn("MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_EMAIL", required)
        self.assertNotIn("MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_PASSWORD", required)
        self.assertNotIn("MAESTRO_WOO_LAB_WPCOM_EMAIL", required)
        self.assertNotIn("MAESTRO_WOO_LAB_WPCOM_PASSWORD", required)

    def test_not_woo_store_wpcom_fallback_must_be_complete(self) -> None:
        flow = RUNNER.FLOWS_DIR / "login_not_woo_store.yaml"
        values = {
            "MAESTRO_WOO_NOT_A_WOO_STORE_URL": "https://example.com",
            "MAESTRO_WOO_NOT_A_WOO_STORE_SITE_ADMIN_USERNAME": "admin",
            "MAESTRO_WOO_NOT_A_WOO_STORE_SITE_ADMIN_PASSWORD": "password",
            "MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_EMAIL": "merchant@example.com",
        }

        with self.assertRaisesRegex(SystemExit, "requires both email and password"):
            RUNNER.validate_environment([flow], values, seed=False)

        values.pop("MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_EMAIL")
        RUNNER.validate_environment([flow], values, seed=False)

    def test_seed_explicitly_requires_consumer_keys(self) -> None:
        required = RUNNER.required_environment([], seed=True)
        self.assertIn("MAESTRO_WOO_CONSUMER_KEY", required)
        self.assertIn("MAESTRO_WOO_CONSUMER_SECRET", required)


if __name__ == "__main__":
    unittest.main()

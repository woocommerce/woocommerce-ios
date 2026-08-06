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

    def test_seed_explicitly_requires_consumer_keys(self) -> None:
        required = RUNNER.required_environment([], seed=True)
        self.assertIn("MAESTRO_WOO_CONSUMER_KEY", required)
        self.assertIn("MAESTRO_WOO_CONSUMER_SECRET", required)


if __name__ == "__main__":
    unittest.main()

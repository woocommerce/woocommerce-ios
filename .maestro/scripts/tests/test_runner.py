from __future__ import annotations

import argparse
import contextlib
import importlib.util
import io
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "run-smoke-tests.py"
SPEC = importlib.util.spec_from_file_location("runner", SCRIPT)
assert SPEC and SPEC.loader
RUNNER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = RUNNER
SPEC.loader.exec_module(RUNNER)


class RunnerTests(unittest.TestCase):
    def test_run_requires_one_discoverable_app_outside_plan_mode(self) -> None:
        with (
            mock.patch.object(sys, "argv", [str(SCRIPT), "--profile", "core"]),
            mock.patch.object(
                RUNNER,
                "discover_app",
                side_effect=SystemExit("No simulator app was found"),
            ),
            self.assertRaisesRegex(SystemExit, "No simulator app was found"),
        ):
            RUNNER.main()

    def test_list_is_an_alias_for_plan(self) -> None:
        with mock.patch.object(sys, "argv", [str(SCRIPT), "--list"]):
            args = RUNNER.parse_args()

        self.assertTrue(args.plan)
        self.assertIsNone(args.app)

    def test_plan_lists_selection_without_runtime_side_effects(self) -> None:
        output = io.StringIO()
        with (
            mock.patch.object(sys, "argv", [str(SCRIPT), "--plan", "--profile", "core"]),
            mock.patch.object(RUNNER.shutil, "which", side_effect=AssertionError("binary lookup")),
            mock.patch.object(RUNNER, "load_environment", side_effect=AssertionError("environment load")),
            mock.patch.object(RUNNER, "app_identifier", side_effect=AssertionError("app inspection")),
            mock.patch.object(RUNNER, "resolve_simulator", side_effect=AssertionError("simulator lookup")),
            mock.patch.object(RUNNER, "run", side_effect=AssertionError("subprocess")),
            contextlib.redirect_stdout(output),
        ):
            exit_code = RUNNER.main()

        self.assertEqual(0, exit_code)
        self.assertIn("Profile:      core", output.getvalue())
        self.assertIn("Selected flows:", output.getvalue())
        self.assertIn("Required environment:", output.getvalue())

    def test_empty_flow_selection_is_fatal(self) -> None:
        args = argparse.Namespace(flows=[], rerun_failed=None)

        with self.assertRaisesRegex(SystemExit, "No Maestro flows matched"):
            RUNNER.select_flows(args, ["tag-that-does-not-exist"], [])

    def test_destructive_runtime_requires_the_cleanup_journal(self) -> None:
        flow = RUNNER.FLOWS_DIR / "orders_create.yaml"

        with self.assertRaisesRegex(SystemExit, "Destructive flows require --seed"):
            RUNNER.validate_destructive_cleanup([flow], seed=False)

        RUNNER.validate_destructive_cleanup([flow], seed=True)

    def test_html_report_names_the_overall_status(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            report = output / "report.html"
            flow = RUNNER.FLOWS_DIR / "dashboard_stats.yaml"
            junit = output / "r01-dashboard_stats-a1.xml"
            log = output / "logs" / "r01-dashboard_stats-a1.log"
            debug = output / "diagnostics" / "r01-dashboard_stats-a1"
            log.parent.mkdir()
            debug.parent.mkdir()
            junit.write_text("<testsuite />", encoding="utf-8")
            log.write_text("failure", encoding="utf-8")
            debug.mkdir()
            attempts = [RUNNER.Attempt(flow, 1, 1, 1, junit, log, debug)]

            RUNNER.write_html(
                report,
                run_id="run-1",
                app=Path("WooCommerce.app"),
                app_id="com.example.woo",
                simulator={"name": "iPhone", "udid": "sim-1"},
                profile="core",
                attempts=attempts,
                status="FLAKY",
                tests=2,
                failures=1,
                skipped=0,
                seed=True,
            )

            contents = report.read_text()
            self.assertIn("Overall status: <strong class='flaky'>FLAKY</strong>", contents)
            self.assertIn("href='diagnostics/r01-dashboard_stats-a1/'", contents)
            self.assertIn("href='logs/r01-dashboard_stats-a1.log'", contents)
            self.assertIn("href='r01-dashboard_stats-a1.xml'", contents)
            self.assertIn("--rerun-failed report.xml", contents)
            self.assertIn("--seed", contents)

    def test_html_report_labels_missing_attempt_artifacts_instead_of_linking_them(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            report = output / "report.html"
            attempt = RUNNER.Attempt(
                RUNNER.FLOWS_DIR / "dashboard_stats.yaml",
                1,
                1,
                124,
                output / "missing.xml",
                output / "missing.log",
                output / "missing-debug",
            )

            RUNNER.write_html(
                report,
                run_id="run-1",
                app=Path("WooCommerce.app"),
                app_id="com.example.woo",
                simulator={"name": "iPhone", "udid": "sim-1"},
                profile="core",
                attempts=[attempt],
                status="TIMED_OUT",
                tests=1,
                failures=1,
                skipped=0,
            )

            contents = report.read_text(encoding="utf-8")

        self.assertIn("artifacts missing", contents)
        self.assertNotIn("href='missing.xml'", contents)

    def test_timed_out_suite_has_timeout_status_and_exit_code(self) -> None:
        self.assertEqual("TIMED_OUT", RUNNER.flow_status([124]))
        status = RUNNER.suite_status(["PASS", "TIMED_OUT"])

        self.assertEqual("TIMED_OUT", status)
        self.assertEqual(124, RUNNER.status_exit_code(status))

    def test_subprocess_timeout_is_enforced(self) -> None:
        with self.assertRaises(subprocess.TimeoutExpired):
            RUNNER.run(
                [sys.executable, "-c", "import time; time.sleep(1)"],
                timeout=0.01,
            )

    def test_suite_status_uses_the_most_severe_result(self) -> None:
        self.assertEqual("PASS", RUNNER.suite_status(["PASS"]))
        self.assertEqual("FLAKY", RUNNER.suite_status(["PASS", "FLAKY"]))
        self.assertEqual("FAIL", RUNNER.suite_status(["FLAKY", "FAIL"]))
        self.assertEqual("TIMED_OUT", RUNNER.suite_status(["FAIL", "TIMED_OUT"]))
        self.assertEqual("SETUP_ERROR", RUNNER.suite_status(["TIMED_OUT", "SETUP_ERROR"]))

    def test_setup_error_has_a_distinct_nonzero_exit_code(self) -> None:
        self.assertEqual(2, RUNNER.status_exit_code("SETUP_ERROR"))

    def test_flaky_retry_is_visible_in_junit_and_returns_nonzero(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            flow = RUNNER.FLOWS_DIR / "dashboard_stats.yaml"
            failed_junit = root / "failed.xml"
            passed_junit = root / "passed.xml"
            failed_junit.write_text(
                '<testsuite name="dashboard" tests="1" failures="1">'
                '<testcase name="dashboard"><failure message="failed" /></testcase>'
                '</testsuite>'
            )
            passed_junit.write_text(
                '<testsuite name="dashboard" tests="1" failures="0">'
                '<testcase name="dashboard" /></testsuite>'
            )
            attempts = [
                RUNNER.Attempt(flow, 1, 1, 1, failed_junit, root / "failed.log", root / "failed-debug"),
                RUNNER.Attempt(flow, 1, 2, 0, passed_junit, root / "passed.log", root / "passed-debug"),
            ]
            report = root / "report.xml"

            result = RUNNER.finalize_suite(attempts, report)

            self.assertEqual("FLAKY", result.status)
            self.assertEqual(1, result.exit_code)
            self.assertEqual(2, result.tests)
            self.assertEqual(1, result.failures)
            suites = ET.parse(report).getroot().findall("testsuite")
            self.assertEqual(2, len(suites))
            self.assertIn("attempt 1", suites[0].get("name", ""))
            self.assertIn("attempt 2", suites[1].get("name", ""))

    def test_completed_run_summary_records_final_status_and_attempts(self) -> None:
        flow = RUNNER.FLOWS_DIR / "dashboard_stats.yaml"
        attempts = [
            RUNNER.Attempt(
                flow,
                1,
                1,
                124,
                Path("run.xml"),
                Path("run.log"),
                Path("diagnostics/run"),
            )
        ]
        initial = {"run_id": "run-1", "profile": "core"}
        result = RUNNER.SuiteResult("TIMED_OUT", 1, 1, 0)

        completed = RUNNER.complete_run_summary(initial, result, attempts, duration_seconds=17)

        self.assertEqual("TIMED_OUT", completed["status"])
        self.assertEqual(17, completed["duration_seconds"])
        self.assertEqual(124, completed["attempts"][0]["return_code"])
        self.assertEqual("TIMED_OUT", completed["attempts"][0]["status"])

    def test_cleanup_failure_overrides_the_suite_status_and_junit(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory) / "report.xml"
            report.write_text(
                '<testsuites tests="1" failures="0" skipped="0">'
                '<testsuite name="flow" tests="1" failures="0">'
                '<testcase name="flow" />'
                "</testsuite></testsuites>",
                encoding="utf-8",
            )
            result = RUNNER.SuiteResult("PASS", 1, 0, 0)

            updated = RUNNER.add_setup_error(result, report, "fixture cleanup failed")

            self.assertEqual("SETUP_ERROR", updated.status)
            self.assertEqual(2, updated.tests)
            self.assertEqual(1, updated.failures)
            root = ET.parse(report).getroot()
            self.assertEqual("2", root.get("tests"))
            self.assertEqual("1", root.get("failures"))
            self.assertIn("fixture cleanup failed", report.read_text(encoding="utf-8"))

    def test_redacts_all_woo_values(self) -> None:
        values = {"MAESTRO_WOO_LAB_WPCOM_PASSWORD": "do-not-print"}
        self.assertEqual("failure: <redacted>", RUNNER.redact("failure: do-not-print", values))

    def test_sanitizer_can_redact_one_new_artifact_without_rescanning_its_parent(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "attempt.xml"
            artifact.write_text("secret-value", encoding="utf-8")

            RUNNER.sanitize_artifacts(
                artifact,
                {"MAESTRO_WOO_LAB_WPCOM_PASSWORD": "secret-value"},
            )

            self.assertEqual("<redacted>", artifact.read_text(encoding="utf-8"))

    def test_flow_status_reports_pass_flaky_and_fail(self) -> None:
        self.assertEqual("PASS", RUNNER.flow_status([0]))
        self.assertEqual("FLAKY", RUNNER.flow_status([1, 0]))
        self.assertEqual("FAIL", RUNNER.flow_status([1, 1]))

    def test_destructive_flows_do_not_blindly_retry_mutations(self) -> None:
        destructive = RUNNER.FLOWS_DIR / "orders_create.yaml"
        safe = RUNNER.FLOWS_DIR / "dashboard_stats.yaml"

        self.assertEqual((1,), RUNNER.attempt_numbers(destructive))
        self.assertEqual((1, 2), RUNNER.attempt_numbers(safe))

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

    def test_unique_built_app_can_be_discovered_for_one_command_runs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            app = root / "Debug-iphonesimulator" / "WooCommerce.app"
            app.mkdir(parents=True)

            self.assertEqual(app.resolve(), RUNNER.discover_app([root]))

    def test_app_bundle_hash_changes_with_candidate_contents(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory) / "WooCommerce.app"
            app.mkdir()
            binary = app / "WooCommerce"
            binary.write_bytes(b"candidate-one")
            first = RUNNER.app_bundle_sha256(app)

            binary.write_bytes(b"candidate-two")
            second = RUNNER.app_bundle_sha256(app)

        self.assertRegex(first, r"^[a-f0-9]{64}$")
        self.assertNotEqual(first, second)

    def test_simulator_resolution_can_be_side_effect_free_for_doctor(self) -> None:
        simulator = {
            "name": "iPhone 17",
            "udid": "sim-1",
            "state": "Shutdown",
            "runtime": "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
        }
        with (
            mock.patch.object(RUNNER, "simulator_records", return_value=[simulator]),
            mock.patch.object(RUNNER, "run", side_effect=AssertionError("must not boot")),
        ):
            selected = RUNNER.resolve_simulator(None, "iphone", boot=False)

        self.assertEqual(simulator, selected)

    def test_selected_flow_environment_is_required_but_consumer_keys_are_not(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            flow = Path(directory) / "flow.yaml"
            flow.write_text("appId: ${APP_ID}\n---\n- inputText: ${MAESTRO_WOO_FEATURE_INPUT}\n")
            required = RUNNER.required_environment([flow], seed=False)
            self.assertIn("MAESTRO_WOO_FEATURE_INPUT", required)
            self.assertNotIn("MAESTRO_WOO_CONSUMER_KEY", required)

    def test_order_creation_uses_a_configured_customer_instead_of_capturing_live_pii(self) -> None:
        flow = RUNNER.FLOWS_DIR / "orders_create.yaml"

        required = RUNNER.required_environment([flow], seed=False)
        source = flow.read_text(encoding="utf-8")

        self.assertIn("MAESTRO_WOO_EXISTING_CUSTOMER_SEARCH", required)
        self.assertNotIn("selectedCustomerEmail", source)

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

    def test_derived_lab_store_host_is_not_required_from_the_environment(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            flow = Path(directory) / "flow.yaml"
            flow.write_text("appId: ${APP_ID}\n---\n- inputText: ${MAESTRO_WOO_LAB_JETPACK_STORE_HOST}\n")

            self.assertNotIn(
                "MAESTRO_WOO_LAB_JETPACK_STORE_HOST",
                RUNNER.required_environment([flow], seed=False),
            )

    def test_seed_explicitly_requires_consumer_keys(self) -> None:
        required = RUNNER.required_environment([], seed=True)
        self.assertIn("MAESTRO_WOO_CONSUMER_KEY", required)
        self.assertIn("MAESTRO_WOO_CONSUMER_SECRET", required)

    def test_maestro_cli_args_contain_only_non_secret_run_values(self) -> None:
        args = RUNNER.maestro_env_args(
            "com.example.app",
            "run-1",
        )

        self.assertEqual(
            ["--env", "APP_ID=com.example.app", "--env", "SUITE_RUN_ID=run-1"],
            args,
        )

    def test_maestro_process_receives_only_selected_flow_environment_and_no_rest_secrets(self) -> None:
        values = {
            "MAESTRO_WOO_LAB_JETPACK_STORE_URL": "http://shop.example.com/path",
            "MAESTRO_WOO_LAB_WPCOM_EMAIL": "merchant@example.com",
            "MAESTRO_WOO_CONSUMER_KEY": "consumer-key",
            "MAESTRO_WOO_CONSUMER_SECRET": "consumer-secret",
            "MAESTRO_UNUSED_SECRET": "must-not-be-forwarded",
        }
        required = {
            "MAESTRO_WOO_LAB_JETPACK_STORE_URL",
            "MAESTRO_WOO_LAB_WPCOM_EMAIL",
            "MAESTRO_WOO_CONSUMER_KEY",
            "MAESTRO_WOO_CONSUMER_SECRET",
        }

        environment = RUNNER.maestro_process_environment(values, required, "run-1")

        self.assertEqual("http://shop.example.com/path", environment["MAESTRO_WOO_LAB_JETPACK_STORE_URL"])
        self.assertEqual("merchant@example.com", environment["MAESTRO_WOO_LAB_WPCOM_EMAIL"])
        self.assertEqual("shop.example.com", environment["MAESTRO_WOO_LAB_JETPACK_STORE_HOST"])
        self.assertEqual("run-1", environment["MAESTRO_SUITE_RUN_ID"])
        self.assertNotIn("MAESTRO_WOO_CONSUMER_KEY", environment)
        self.assertNotIn("MAESTRO_WOO_CONSUMER_SECRET", environment)
        self.assertNotIn("MAESTRO_UNUSED_SECRET", environment)


if __name__ == "__main__":
    unittest.main()

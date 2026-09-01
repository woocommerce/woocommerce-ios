#!/usr/bin/env python3
"""Repository-owned Maestro runner for WooCommerce iOS simulator apps."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import html
import json
import os
import random
import re
import secrets
import shlex
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
MAESTRO_DIR = REPO_ROOT / ".maestro"
FLOWS_DIR = MAESTRO_DIR / "flows"
ENV_FILE = MAESTRO_DIR / ".env.local"
CONFIG_FILE = MAESTRO_DIR / "config.yaml"
LINT_ENV = SCRIPT_DIR / "lint-env.py"
CHECK_TOOLCHAIN = SCRIPT_DIR / "check-toolchain.py"
DEVICE_LOCALE = SCRIPT_DIR / "device_locale.py"
OUTPUT_DEFAULT = Path.home() / "woocommerce-maestro-output"
NOT_WOO_STORE_FLOW = "login_not_woo_store.yaml"
NO_JETPACK_FLOW = "login_no_jetpack.yaml"
NOT_WOO_STORE_WPCOM_FALLBACK = {
    "MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_EMAIL",
    "MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_PASSWORD",
}

PROFILES = {
    "core": (["smoke_core"], ["flaky_quarantine", "pos_ipad", "ios_system"], 1, "iphone"),
    "phone-full": (["smoke_core", "smoke_extended", "destructive"], ["pos_ipad", "ios_system"], 1, "iphone"),
    "release": (["smoke_core", "smoke_extended", "destructive"], ["flaky_quarantine", "pos_ipad", "ios_system"], 1, "iphone"),
    "burst": (["smoke_core", "smoke_extended", "destructive"], ["flaky_quarantine", "pos_ipad", "ios_system"], 3, "iphone"),
    "pos-ipad": (["pos_ipad"], [], 1, "ipad"),
    "ios-system": (["ios_system"], [], 1, "iphone"),
}

ORDERED_FLOWS = [
    "diagnostic.yaml",
    "login_not_wp_site.yaml", "login_wrong_credentials.yaml", "login_help.yaml",
    "login_not_woo_store.yaml", "login_wrong_account.yaml", "login_no_jetpack.yaml",
    "login_google.yaml", "login_successful.yaml", "dashboard_stats.yaml",
    "dashboard_view_all_analytics.yaml", "dashboard_customize.yaml",
    "orders_list_and_search.yaml", "products_list_and_sort.yaml", "products_detail.yaml",
    "products_variations_and_tags.yaml", "hub_menu_settings.yaml", "hub_menu_payments.yaml",
    "hub_menu_coupons.yaml", "hub_menu_customers_inbox.yaml", "hub_menu_admin_and_store.yaml",
    "blaze_campaign.yaml", "google_for_woo.yaml", "orders_create.yaml",
    "orders_details_and_actions.yaml", "orders_mark_complete.yaml", "orders_cash_payment.yaml",
    "orders_refund.yaml", "products_create.yaml", "products_media_upload.yaml",
    "pos_search_and_coupons.yaml", "pos_cash_payment.yaml", "ios_quick_actions.yaml",
    "ios_notification_long_press.yaml", "orders_qr_payment.yaml",
    "orders_share_payment_link.yaml", "orders_barcode_scanner.yaml",
]

SECRET_NAME_RE = re.compile(r"(?:PASSWORD|SECRET|CONSUMER_KEY|TOKEN)", re.I)
ENV_ASSIGNMENT_RE = re.compile(r"^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
ENV_REFERENCE_RE = re.compile(r"\$\{(MAESTRO_[A-Z0-9_]+)\}")
SUBFLOW_REFERENCE_RE = re.compile(r"(?:file:|runFlow:)\s*([^\s#]+\.ya?ml)")
STATUS_EXIT_CODES = {
    "PASS": 0,
    "FLAKY": 1,
    "FAIL": 1,
    "SETUP_ERROR": 2,
    "TIMED_OUT": 124,
}


@dataclass
class Attempt:
    flow: Path
    repeat: int
    number: int
    returncode: int
    junit: Path
    log: Path
    debug: Path


@dataclass(frozen=True)
class SuiteResult:
    status: str
    tests: int
    failures: int
    skipped: int

    @property
    def exit_code(self) -> int:
        return status_exit_code(self.status)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("flows", nargs="*", type=Path)
    parser.add_argument("--app", type=Path, help="Debug or Alpha/prototype .app bundle; auto-detected when unique")
    parser.add_argument(
        "--candidate-kind",
        choices=("developer", "release-candidate"),
        default="developer",
        help="Classify whether this app can be used as release evidence",
    )
    parser.add_argument("--profile", choices=sorted(PROFILES), default="core")
    parser.add_argument("--device", help="Simulator name or UDID")
    parser.add_argument("--include-tags")
    parser.add_argument("--exclude-tags")
    parser.add_argument("--repeat", type=int)
    parser.add_argument("--flow-timeout-seconds", type=float, default=900)
    parser.add_argument("--rerun-failed", type=Path)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--seed", action="store_true")
    parser.add_argument("--no-cleanup", action="store_true")
    parser.add_argument("--no-open", action="store_true")
    parser.add_argument("--plan", "--list", dest="plan", action="store_true", help="Print the resolved flows and requirements without running them")
    return parser.parse_args()


def csv(value: str | None) -> list[str] | None:
    if value is None:
        return None
    return [item.strip() for item in value.split(",") if item.strip()]


def decode_env_value(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def load_environment() -> dict[str, str]:
    values = dict(os.environ)
    if not ENV_FILE.exists():
        return values
    lint = subprocess.run([sys.executable, str(LINT_ENV), "--file", str(ENV_FILE)], cwd=REPO_ROOT)
    if lint.returncode:
        raise SystemExit("Refusing to load an invalid .maestro/.env.local")
    for raw_line in ENV_FILE.read_text(errors="replace").splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = ENV_ASSIGNMENT_RE.match(stripped)
        if match:
            values[match.group(1)] = decode_env_value(match.group(2))
    return values


def run(
    command: list[str],
    *,
    capture: bool = True,
    check: bool = True,
    env: dict[str, str] | None = None,
    timeout: float | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=REPO_ROOT,
        text=True,
        capture_output=capture,
        check=check,
        env=env,
        timeout=timeout,
    )


def app_identifier(app: Path) -> str:
    app = app.expanduser().resolve()
    if not app.is_dir() or app.suffix != ".app":
        raise SystemExit(f"--app must point to an existing .app bundle: {app}")
    plist = app / "Info.plist"
    result = run(["/usr/bin/plutil", "-extract", "CFBundleIdentifier", "raw", "-o", "-", str(plist)])
    identifier = result.stdout.strip()
    if not identifier:
        raise SystemExit(f"CFBundleIdentifier is missing from {plist}")
    return identifier


def discover_app(search_roots: list[Path] | None = None) -> Path:
    if search_roots is None:
        search_roots = [
            REPO_ROOT / "DerivedData" / "Build" / "Products",
            Path.home() / "Library" / "Developer" / "Xcode" / "DerivedData",
        ]
    candidates: set[Path] = set()
    for root in search_roots:
        if root.exists():
            candidates.update(path.resolve() for path in root.glob("**/*-iphonesimulator/WooCommerce.app"))
    if len(candidates) == 1:
        return next(iter(candidates))
    if not candidates:
        raise SystemExit(
            "No simulator app was found. Build WooCommerce for an iOS simulator or pass --app."
        )
    formatted = "\n".join(f"  - {path}" for path in sorted(candidates))
    raise SystemExit(f"Multiple simulator apps were found; pass --app explicitly:\n{formatted}")


def app_bundle_sha256(app: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(item for item in app.rglob("*") if item.is_file()):
        relative = str(path.relative_to(app)).encode("utf-8")
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    return digest.hexdigest()


def simulator_records() -> list[dict[str, str]]:
    payload = json.loads(run(["xcrun", "simctl", "list", "devices", "available", "--json"]).stdout)
    records: list[dict[str, str]] = []
    for runtime, devices in payload.get("devices", {}).items():
        if "iOS" not in runtime:
            continue
        for device in devices:
            records.append({"name": device["name"], "udid": device["udid"], "state": device["state"], "runtime": runtime})
    return records


def resolve_simulator(
    selector: str | None,
    family: str,
    *,
    boot: bool = True,
) -> dict[str, str]:
    records = simulator_records()
    family_token = "ipad" if family == "ipad" else "iphone"
    compatible = [item for item in records if family_token in item["name"].lower()]
    if selector:
        exact = [item for item in records if item["udid"] == selector or item["name"] == selector]
        if len(exact) != 1:
            raise SystemExit(f"--device must match exactly one available simulator name or UDID: {selector}")
        selected = exact[0]
        if family_token not in selected["name"].lower():
            raise SystemExit(f"Profile requires an {family}; selected simulator is {selected['name']}")
    else:
        booted = [item for item in compatible if item["state"] == "Booted"]
        if booted:
            selected = booted[0]
        elif compatible:
            selected = compatible[0]
        else:
            raise SystemExit(f"No available {family} simulator is installed")
    if boot:
        if selected["state"] != "Booted":
            run(["xcrun", "simctl", "boot", selected["udid"]])
        run(["xcrun", "simctl", "bootstatus", selected["udid"], "-b"], capture=False)
    return selected


def flow_tags(path: Path) -> set[str]:
    tags: set[str] = set()
    in_tags = False
    for line in path.read_text(errors="replace").split("---", 1)[0].splitlines():
        if line.strip() == "tags:":
            in_tags = True
        elif in_tags and line.lstrip().startswith("-"):
            tags.add(line.split("-", 1)[1].strip())
        elif in_tags and line and not line.startswith((" ", "\t")):
            in_tags = False
    return tags


def failed_flow_stems(report: Path) -> set[str]:
    root = ET.parse(report).getroot()
    stems: set[str] = set()
    for case in root.iter("testcase"):
        if case.find("failure") is None and case.find("error") is None:
            continue
        haystack = " ".join([case.get("name", ""), case.get("classname", ""), case.get("file", "")])
        stems.update(path.stem for path in FLOWS_DIR.glob("*.yaml") if path.stem in haystack)
    return stems


def select_flows(args: argparse.Namespace, include: list[str], exclude: list[str]) -> list[Path]:
    if args.flows:
        selected = [(path if path.is_absolute() else REPO_ROOT / path).resolve() for path in args.flows]
    else:
        selected = [FLOWS_DIR / name for name in ORDERED_FLOWS if (FLOWS_DIR / name).exists()]
        selected.extend(sorted(path for path in FLOWS_DIR.glob("*.yaml") if path not in selected))
        selected = [path for path in selected if (not include or flow_tags(path).intersection(include)) and not flow_tags(path).intersection(exclude)]
    if args.rerun_failed:
        stems = failed_flow_stems(args.rerun_failed)
        selected = [path for path in selected if path.stem in stems]
    missing = [str(path) for path in selected if not path.is_file()]
    if missing:
        raise SystemExit("Missing flow file(s): " + ", ".join(missing))
    if not selected:
        raise SystemExit("No Maestro flows matched the requested selection")
    return selected


def validate_destructive_cleanup(flows: list[Path], *, seed: bool) -> None:
    if any("destructive" in flow_tags(flow) for flow in flows) and not seed:
        raise SystemExit(
            "Destructive flows require --seed so run-owned products and orders are journaled and cleaned."
        )


def required_environment(flows: list[Path], *, seed: bool) -> set[str]:
    """Return selected-flow requirements without making optional REST keys global."""
    paths = list(flows)
    visited: set[Path] = set()
    required = set()
    while paths:
        path = paths.pop().resolve()
        if path in visited or not path.exists():
            continue
        visited.add(path)
        text = path.read_text(errors="replace")
        references = set(ENV_REFERENCE_RE.findall(text))
        if path.name == NOT_WOO_STORE_FLOW:
            references.difference_update(NOT_WOO_STORE_WPCOM_FALLBACK)
        required.update(references)
        for reference in SUBFLOW_REFERENCE_RE.findall(text):
            paths.append((path.parent / reference).resolve())
    required.discard("MAESTRO_WOO_LAB_JETPACK_STORE_HOST")
    if seed:
        required.update({"MAESTRO_WOO_CONSUMER_KEY", "MAESTRO_WOO_CONSUMER_SECRET"})
    return required


def validate_environment(flows: list[Path], values: dict[str, str], *, seed: bool) -> None:
    missing = sorted(name for name in required_environment(flows, seed=seed) if not values.get(name))
    if missing:
        raise SystemExit("Missing environment required by selected flows: " + ", ".join(missing))
    if any(flow.name == NOT_WOO_STORE_FLOW for flow in flows):
        configured_fallback = [bool(values.get(name)) for name in NOT_WOO_STORE_WPCOM_FALLBACK]
        not_woo_host = normalized_store_host(values.get("MAESTRO_WOO_NOT_A_WOO_STORE_URL", ""))
        if not_woo_host == "wordpress.com" or not_woo_host.endswith(".wordpress.com"):
            if not all(configured_fallback):
                raise SystemExit(
                    "WordPress.com-hosted not-Woo-store fixture requires WP.com email and password"
                )
        elif any(configured_fallback) and not all(configured_fallback):
            raise SystemExit("Not-Woo-store WP.com fallback requires both email and password, or neither")


def site_url_without_wp_admin(value: str) -> str:
    parsed = urlsplit(value)
    path = parsed.path.rstrip("/")
    if not path.endswith("/wp-admin"):
        return value
    site_path = path.removesuffix("wp-admin")
    return urlunsplit(parsed._replace(path=site_path, query="", fragment=""))


def normalized_flow_environment(flows: list[Path], values: dict[str, str]) -> dict[str, str]:
    normalized = dict(values)
    if any(flow.name == NO_JETPACK_FLOW for flow in flows):
        name = "MAESTRO_WOO_NO_JETPACK_SITE_URL"
        if value := normalized.get(name):
            normalized[name] = site_url_without_wp_admin(value)
    return normalized


def runtime_environment_names(flows: list[Path], *, seed: bool) -> set[str]:
    names = required_environment(flows, seed=seed)
    if any(flow.name == NOT_WOO_STORE_FLOW for flow in flows):
        names.update(NOT_WOO_STORE_WPCOM_FALLBACK)
    return names


def normalized_store_host(value: str) -> str:
    candidate = value.strip()
    parsed = urlsplit(candidate if "://" in candidate else f"//{candidate}")
    return (parsed.hostname or "").lower().rstrip(".")


def maestro_process_environment(
    values: dict[str, str],
    required_names: set[str],
    run_id: str,
) -> dict[str, str]:
    rest_only = {"MAESTRO_WOO_CONSUMER_KEY", "MAESTRO_WOO_CONSUMER_SECRET"}
    environment = {name: value for name, value in os.environ.items() if not name.startswith("MAESTRO_")}
    for name in sorted(required_names - rest_only):
        if value := values.get(name):
            environment[name] = value
    lab_store_url = values.get("MAESTRO_WOO_LAB_JETPACK_STORE_URL", "")
    if lab_store_host := normalized_store_host(lab_store_url):
        environment["MAESTRO_WOO_LAB_JETPACK_STORE_HOST"] = lab_store_host
    environment["MAESTRO_SUITE_RUN_ID"] = run_id
    return environment


def maestro_env_args(app_id: str, run_id: str) -> list[str]:
    return ["--env", f"APP_ID={app_id}", "--env", f"SUITE_RUN_ID={run_id}"]


def redact(text: str, values: dict[str, str]) -> str:
    secrets_to_hide = [value for name, value in values.items() if value and (name.startswith("MAESTRO_WOO_") or SECRET_NAME_RE.search(name))]
    for value in sorted(set(secrets_to_hide), key=len, reverse=True):
        text = text.replace(value, "<redacted>")
    return text


def flow_status(returncodes: list[int]) -> str:
    if 124 in returncodes:
        return "TIMED_OUT"
    if not returncodes or returncodes[-1] != 0:
        return "FAIL"
    if len(returncodes) > 1:
        return "FLAKY"
    return "PASS"


def attempt_numbers(flow: Path) -> tuple[int, ...]:
    return (1,) if "destructive" in flow_tags(flow) else (1, 2)


def status_exit_code(status: str) -> int:
    return STATUS_EXIT_CODES[status]


def suite_status(statuses: list[str]) -> str:
    if not statuses:
        return "SETUP_ERROR"
    for status in ("SETUP_ERROR", "TIMED_OUT", "FAIL", "FLAKY"):
        if status in statuses:
            return status
    return "PASS"


def sanitize_artifacts(root: Path, values: dict[str, str], *, remove_images: bool = False) -> None:
    """Redact Maestro's generated text evidence and suppress login screenshots."""
    text_suffixes = {".html", ".json", ".log", ".txt", ".xml", ".yaml", ".yml"}
    image_suffixes = {".heic", ".jpeg", ".jpg", ".png", ".webp"}
    if not root.exists():
        return
    paths = [root] if root.is_file() else root.rglob("*")
    for path in paths:
        if not path.is_file():
            continue
        if remove_images and path.suffix.lower() in image_suffixes:
            path.unlink()
            continue
        if path.suffix.lower() in text_suffixes:
            original = path.read_text(errors="replace")
            sanitized = redact(original, values)
            if sanitized != original:
                path.write_text(sanitized, encoding="utf-8")


def write_combined_junit(attempts: list[Attempt], destination: Path) -> tuple[int, int, int]:
    suites = ET.Element("testsuites")
    tests = failures = skipped = 0
    for attempt in attempts:
        if not attempt.junit.exists():
            suite = ET.SubElement(suites, "testsuite", name=f"{attempt.flow.stem}-attempt-{attempt.number}", tests="1", failures="1")
            case = ET.SubElement(suite, "testcase", name=attempt.flow.stem, file=str(attempt.flow.relative_to(REPO_ROOT)))
            ET.SubElement(case, "failure", message="Maestro did not produce JUnit output")
            tests += 1
            failures += 1
            continue
        root = ET.parse(attempt.junit).getroot()
        children = [root] if root.tag == "testsuite" else list(root.findall("testsuite"))
        for suite in children:
            suite.set("name", f"{suite.get('name', attempt.flow.stem)} [run {attempt.repeat} attempt {attempt.number}]")
            suites.append(suite)
            tests += int(suite.get("tests", len(suite.findall("testcase"))))
            failures += int(suite.get("failures", "0")) + int(suite.get("errors", "0"))
            skipped += int(suite.get("skipped", "0"))
    suites.set("tests", str(tests))
    suites.set("failures", str(failures))
    suites.set("skipped", str(skipped))
    ET.ElementTree(suites).write(destination, encoding="utf-8", xml_declaration=True)
    return tests, failures, skipped


def finalize_suite(attempts: list[Attempt], destination: Path) -> SuiteResult:
    attempts_by_execution: dict[tuple[Path, int], list[int]] = {}
    for attempt in attempts:
        attempts_by_execution.setdefault((attempt.flow, attempt.repeat), []).append(attempt.returncode)
    statuses = [flow_status(returncodes) for returncodes in attempts_by_execution.values()]
    status = suite_status(statuses)
    tests, failures, skipped = write_combined_junit(attempts, destination)
    return SuiteResult(status, tests, failures, skipped)


def add_setup_error(result: SuiteResult, destination: Path, message: str) -> SuiteResult:
    root = ET.parse(destination).getroot()
    suite = ET.SubElement(
        root,
        "testsuite",
        name="woocommerce-ios-maestro-teardown",
        tests="1",
        failures="1",
    )
    case = ET.SubElement(suite, "testcase", name="fixture cleanup")
    ET.SubElement(case, "failure", message=message).text = message
    tests = result.tests + 1
    failures = result.failures + 1
    root.set("tests", str(tests))
    root.set("failures", str(failures))
    root.set("skipped", str(result.skipped))
    ET.ElementTree(root).write(destination, encoding="utf-8", xml_declaration=True)
    return SuiteResult("SETUP_ERROR", tests, failures, result.skipped)


def complete_run_summary(
    initial: dict[str, object],
    result: SuiteResult,
    attempts: list[Attempt],
    *,
    duration_seconds: int,
) -> dict[str, object]:
    completed = dict(initial)
    completed.update(
        {
            "status": result.status,
            "duration_seconds": duration_seconds,
            "tests": result.tests,
            "failures": result.failures,
            "skipped": result.skipped,
            "attempts": [
                {
                    "flow": str(attempt.flow.relative_to(REPO_ROOT)),
                    "repeat": attempt.repeat,
                    "attempt": attempt.number,
                    "return_code": attempt.returncode,
                    "status": "PASS"
                    if attempt.returncode == 0
                    else "TIMED_OUT"
                    if attempt.returncode == 124
                    else "FAIL",
                    "junit": str(attempt.junit),
                    "log": str(attempt.log),
                    "diagnostics": str(attempt.debug),
                }
                for attempt in attempts
            ],
        }
    )
    return completed


def write_json_atomic(destination: Path, value: dict[str, object]) -> None:
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")
    temporary.replace(destination)


def write_html(destination: Path, *, run_id: str, app: Path, app_id: str, simulator: dict[str, str], profile: str, attempts: list[Attempt], status: str, tests: int, failures: int, skipped: int, candidate_kind: str = "developer", app_sha256: str = "", seed: bool = False, flow_timeout_seconds: float = 900) -> None:
    rows = []
    for attempt in attempts:
        state = "pass" if attempt.returncode == 0 else "timed_out" if attempt.returncode == 124 else "fail"
        artifact_links: list[str] = []
        for label, path, suffix in (
            ("debug", attempt.debug, "/"),
            ("log", attempt.log, ""),
            ("JUnit", attempt.junit, ""),
        ):
            if path.exists():
                href = html.escape(os.path.relpath(path, destination.parent) + suffix, quote=True)
                artifact_links.append(f"<a href='{href}'>{label}</a>")
        artifacts = " · ".join(artifact_links) if artifact_links else "artifacts missing"
        rows.append(
            f"<tr><td>{html.escape(attempt.flow.name)}</td><td>{attempt.repeat}</td>"
            f"<td>{attempt.number}</td><td class='{state}'>{state.upper()}</td>"
            f"<td>{artifacts}</td></tr>"
        )
    rerun_command = " ".join(
        [
            "cd",
            shlex.quote(str(destination.parent)),
            "&&",
            shlex.quote(str(SCRIPT_DIR / "run-smoke-tests.sh")),
            "--app",
            shlex.quote(str(app)),
            "--profile",
            shlex.quote(profile),
            "--candidate-kind",
            shlex.quote(candidate_kind),
            "--device",
            shlex.quote(simulator["udid"]),
            "--flow-timeout-seconds",
            shlex.quote(f"{flow_timeout_seconds:g}"),
            *(["--seed"] if seed else []),
            "--rerun-failed",
            "report.xml",
        ]
    )
    destination.write_text(f"""<!doctype html><meta charset='utf-8'><title>WooCommerce iOS Maestro {html.escape(run_id)}</title>
<style>body{{font:14px system-ui;margin:2rem;max-width:1100px}}table{{border-collapse:collapse;width:100%}}th,td{{border:1px solid #ccc;padding:.45rem;text-align:left}}.pass{{color:#067a35}}.flaky{{color:#9a6700}}.fail,.setup_error,.timed_out{{color:#b42318}}code{{word-break:break-all}}</style>
<h1>WooCommerce iOS Maestro run</h1><p><strong>{html.escape(run_id)}</strong></p>
<ul><li>Overall status: <strong class='{html.escape(status.lower())}'>{html.escape(status)}</strong></li><li>Profile: {html.escape(profile)}</li><li>Candidate: {html.escape(candidate_kind)}{' (developer build; not release evidence)' if candidate_kind == 'developer' else ''}</li><li>App: <code>{html.escape(str(app))}</code></li><li>Bundle: <code>{html.escape(app_id)}</code></li><li>App SHA-256: <code>{html.escape(app_sha256 or '<not captured>')}</code></li><li>Simulator: {html.escape(simulator['name'])} (<code>{simulator['udid']}</code>)</li><li>Tests: {tests}; failures: {failures}; skipped: {skipped}</li></ul>
<p><a href='report.xml'>Combined JUnit</a> · <a href='run-summary.json'>JSON summary</a></p>
<h2>Rerun failures</h2><pre><code>{html.escape(rerun_command)}</code></pre>
<table><thead><tr><th>Flow</th><th>Repeat</th><th>Attempt</th><th>Result</th><th>Artifacts</th></tr></thead><tbody>{''.join(rows)}</tbody></table>""", encoding="utf-8")


def main() -> int:
    args = parse_args()
    if args.repeat is not None and args.repeat < 1:
        raise SystemExit("--repeat must be a positive integer")
    if args.flow_timeout_seconds <= 0:
        raise SystemExit("--flow-timeout-seconds must be positive")

    include_default, exclude_default, repeat_default, family = PROFILES[args.profile]
    include = csv(args.include_tags)
    exclude = csv(args.exclude_tags)
    include = include_default if include is None else include
    exclude = exclude_default if exclude is None else exclude
    repeat = args.repeat or repeat_default
    flows = select_flows(args, include, exclude)
    if args.plan:
        destructive_cleanup_required = any("destructive" in flow_tags(flow) for flow in flows)
        required = sorted(
            required_environment(flows, seed=args.seed or destructive_cleanup_required)
        )
        print("--- Maestro execution plan")
        print(f"Profile:      {args.profile}")
        print(f"Device family: {family}")
        print(f"Repeat:       {repeat}")
        print(f"Include tags: {','.join(include) or '<none>'}")
        print(f"Exclude tags: {','.join(exclude) or '<none>'}")
        print(
            "Cleanup:      required (--seed)"
            if destructive_cleanup_required
            else "Cleanup:      not required"
        )
        print("Selected flows:")
        for flow in flows:
            print(f"  - {flow.relative_to(REPO_ROOT)}")
        print("Required environment:")
        if required:
            for name in required:
                print(f"  - {name}")
        else:
            print("  - <none>")
        return 0

    validate_destructive_cleanup(flows, seed=args.seed)
    app = args.app.expanduser().resolve() if args.app is not None else discover_app()
    if not shutil.which("xcrun"):
        raise SystemExit("Required command is missing: xcrun")
    toolchain = run([sys.executable, str(CHECK_TOOLCHAIN)], capture=False, check=False)
    if toolchain.returncode:
        return toolchain.returncode

    values = load_environment()
    app_id = app_identifier(app)
    app_sha256 = app_bundle_sha256(app)
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_id = f"SUITE-{stamp}-{secrets.token_hex(3)}"
    output_root = (args.output_dir or Path(values.get("WOO_MAESTRO_OUTPUT_DIR", OUTPUT_DEFAULT))).expanduser()
    output = output_root / run_id
    output.mkdir(parents=True, exist_ok=False)
    (output / "screenshots").mkdir()
    (output / "diagnostics").mkdir()
    (output / "logs").mkdir()

    validate_environment(flows, values, seed=args.seed)
    values = normalized_flow_environment(flows, values)
    simulator = resolve_simulator(args.device, family)
    locale = run(
        [sys.executable, str(DEVICE_LOCALE), "--device", simulator["udid"]],
        capture=False,
        check=False,
    )
    if locale.returncode:
        return locale.returncode
    run(["xcrun", "simctl", "install", simulator["udid"], str(app)])
    summary = {
        "run_id": run_id, "profile": args.profile, "app": str(app), "app_id": app_id,
        "candidate_kind": args.candidate_kind,
        "candidate_evidence": "developer build; not release evidence" if args.candidate_kind == "developer" else "release candidate",
        "app_sha256": app_sha256,
        "simulator_name": simulator["name"], "simulator_udid": simulator["udid"],
        "include_tags": include, "exclude_tags": exclude, "repeat": repeat,
        "flows": [str(path.relative_to(REPO_ROOT)) for path in flows],
    }
    write_json_atomic(output / "run-summary.json", summary)

    if args.seed:
        seed = SCRIPT_DIR / "seed-fixtures.py"
        print("--- Initializing run-owned cleanup journal", flush=True)
        run([sys.executable, str(seed), "--mode", "seed", "--run-id", run_id, "--manifest", str(output / "run-manifest.json")], env=values)

    attempts: list[Attempt] = []
    required_names = runtime_environment_names(flows, seed=args.seed)
    env_args = maestro_env_args(app_id, run_id)
    maestro_environment = maestro_process_environment(values, required_names, run_id)
    total_runs = len(flows) * repeat
    suite_started = time.monotonic()
    run_index = 0
    statuses: list[str] = []
    cleanup_status = "NOT_REQUESTED"
    cleanup_error = ""
    print("--- Running Maestro flows", flush=True)
    print(f"Run ID:       {run_id}", flush=True)
    print(f"Profile:      {args.profile}", flush=True)
    print(f"Simulator:    {simulator['name']} ({simulator['udid']})", flush=True)
    print(f"Output:       {output}", flush=True)
    print(f"Repeat:       {repeat}", flush=True)
    print(f"Include tags: {','.join(include) or '<none>'}", flush=True)
    print(f"Exclude tags: {','.join(exclude) or '<none>'}", flush=True)
    try:
        for repetition in range(1, repeat + 1):
            for flow in flows:
                run_index += 1
                flow_started = time.monotonic()
                flow_returncodes: list[int] = []
                print(f"[{run_index}/{total_runs}] {flow.stem} (repeat {repetition}/{repeat})", flush=True)
                allowed_attempts = attempt_numbers(flow)
                for attempt_number in allowed_attempts:
                    prefix = f"r{repetition:02d}-{flow.stem}-a{attempt_number}"
                    junit = output / f"{prefix}.xml"
                    log = output / "logs" / f"{prefix}.log"
                    debug = output / "diagnostics" / prefix
                    debug.mkdir()
                    screenshot_dir = output / "screenshots" / prefix
                    screenshot_dir.mkdir()
                    command = ["maestro", "test", "--udid", simulator["udid"], "--config", str(CONFIG_FILE), "--format", "JUNIT", "--output", str(junit), "--debug-output", str(debug), "--test-output-dir", str(screenshot_dir), *env_args, str(flow)]
                    try:
                        completed = run(
                            command,
                            check=False,
                            env=maestro_environment,
                            timeout=args.flow_timeout_seconds,
                        )
                    except subprocess.TimeoutExpired as error:
                        stdout = error.stdout if isinstance(error.stdout, str) else ""
                        stderr = error.stderr if isinstance(error.stderr, str) else ""
                        stderr += f"\nTimed out after {args.flow_timeout_seconds:g} seconds\n"
                        completed = subprocess.CompletedProcess(command, 124, stdout, stderr)
                    log.write_text(redact(completed.stdout + completed.stderr, values), encoding="utf-8")
                    is_login = "login" in flow_tags(flow)
                    sanitize_artifacts(debug, values, remove_images=is_login)
                    sanitize_artifacts(screenshot_dir, values, remove_images=is_login)
                    sanitize_artifacts(junit, values)
                    attempts.append(Attempt(flow, repetition, attempt_number, completed.returncode, junit, log, debug))
                    flow_returncodes.append(completed.returncode)
                    if completed.returncode == 0:
                        break
                    if completed.returncode == 124:
                        print(f"  timed out after {args.flow_timeout_seconds:g}s; not retrying", flush=True)
                        break
                    if attempt_number == 1 and len(allowed_attempts) > 1:
                        print("  first attempt failed; retrying once", flush=True)
                status = flow_status(flow_returncodes)
                statuses.append(status)
                duration = round(time.monotonic() - flow_started)
                print(f"  {status} in {duration}s", flush=True)
    finally:
        if args.seed and not args.no_cleanup:
            cleanup_result = run(
                [sys.executable, str(SCRIPT_DIR / "seed-fixtures.py"), "--mode", "cleanup", "--run-id", run_id, "--manifest", str(output / "run-manifest.json")],
                check=False,
                env=values,
            )
            cleanup_status = "PASS" if cleanup_result.returncode == 0 else "FAIL"
            if cleanup_result.returncode:
                cleanup_error = redact(
                    (cleanup_result.stderr or cleanup_result.stdout).strip()
                    or "Run-owned fixture cleanup failed",
                    values,
                )
        elif args.seed:
            cleanup_status = "SKIPPED"

    print("--- Generating reports", flush=True)
    result = finalize_suite(attempts, output / "report.xml")
    if cleanup_error:
        result = add_setup_error(result, output / "report.xml", cleanup_error)
    write_html(
        output / "report.html",
        run_id=run_id,
        app=app,
        app_id=app_id,
        simulator=simulator,
        profile=args.profile,
        attempts=attempts,
        status=result.status,
        tests=result.tests,
        failures=result.failures,
        skipped=result.skipped,
        candidate_kind=args.candidate_kind,
        app_sha256=app_sha256,
        seed=args.seed,
        flow_timeout_seconds=args.flow_timeout_seconds,
    )
    sanitize_artifacts(output, values)
    passed = statuses.count("PASS")
    flaky = statuses.count("FLAKY")
    failed = statuses.count("FAIL")
    timed_out = statuses.count("TIMED_OUT")
    suite_duration = round(time.monotonic() - suite_started)
    summary["cleanup_status"] = cleanup_status
    summary = complete_run_summary(summary, result, attempts, duration_seconds=suite_duration)
    write_json_atomic(output / "run-summary.json", summary)
    print(f"Maestro artifacts: {output}")
    print(f"Report: {output / 'report.html'}")
    print(f"JUnit:  {output / 'report.xml'}")
    print(f"Simulator: {simulator['name']} ({simulator['udid']})")
    print(f"Bundle identifier: {app_id}")
    print(
        f"Result: {passed} passed, {flaky} flaky, {failed} failed, {timed_out} timed out "
        f"out of {total_runs} executions ({suite_duration}s)"
    )
    print(f"Overall status: {result.status}")
    print(f"Final results: {result.tests} tests, {result.failures} failures, {result.skipped} skipped")
    if not args.no_open and not os.environ.get("CI") and not os.environ.get("BUILDKITE"):
        run(["open", str(output / "report.html")], capture=False, check=False)
    return result.exit_code


if __name__ == "__main__":
    raise SystemExit(main())

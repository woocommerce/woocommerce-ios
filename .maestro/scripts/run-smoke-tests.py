#!/usr/bin/env python3
"""Repository-owned Maestro runner for WooCommerce iOS simulator apps."""

from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import os
import random
import re
import secrets
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
MAESTRO_DIR = REPO_ROOT / ".maestro"
FLOWS_DIR = MAESTRO_DIR / "flows"
ENV_FILE = MAESTRO_DIR / ".env.local"
CONFIG_FILE = MAESTRO_DIR / "config.yaml"
LINT_ENV = SCRIPT_DIR / "lint-env.py"
OUTPUT_DEFAULT = Path.home() / "woocommerce-maestro-output"

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


@dataclass
class Attempt:
    flow: Path
    repeat: int
    number: int
    returncode: int
    junit: Path
    log: Path
    debug: Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("flows", nargs="*", type=Path)
    parser.add_argument("--app", required=True, type=Path, help="Debug or Alpha/prototype .app bundle")
    parser.add_argument("--profile", choices=sorted(PROFILES), default="core")
    parser.add_argument("--device", help="Simulator name or UDID")
    parser.add_argument("--include-tags")
    parser.add_argument("--exclude-tags")
    parser.add_argument("--repeat", type=int)
    parser.add_argument("--rerun-failed", type=Path)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--seed", action="store_true")
    parser.add_argument("--no-cleanup", action="store_true")
    parser.add_argument("--no-open", action="store_true")
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


def run(command: list[str], *, capture: bool = True, check: bool = True, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=REPO_ROOT, text=True, capture_output=capture, check=check, env=env)


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


def simulator_records() -> list[dict[str, str]]:
    payload = json.loads(run(["xcrun", "simctl", "list", "devices", "available", "--json"]).stdout)
    records: list[dict[str, str]] = []
    for runtime, devices in payload.get("devices", {}).items():
        if "iOS" not in runtime:
            continue
        for device in devices:
            records.append({"name": device["name"], "udid": device["udid"], "state": device["state"], "runtime": runtime})
    return records


def resolve_simulator(selector: str | None, family: str) -> dict[str, str]:
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


def maestro_env_args(values: dict[str, str], app_id: str, run_id: str) -> list[str]:
    exported = {name: value for name, value in values.items() if name.startswith("MAESTRO_") and value}
    exported.update({"APP_ID": app_id, "SUITE_RUN_ID": run_id, "MAESTRO_SUITE_RUN_ID": run_id})
    result: list[str] = []
    for name in sorted(exported):
        result.extend(["--env", f"{name}={exported[name]}"])
    return result


def redact(text: str, values: dict[str, str]) -> str:
    secrets_to_hide = [value for name, value in values.items() if value and (name.startswith("MAESTRO_WOO_") or SECRET_NAME_RE.search(name))]
    for value in sorted(set(secrets_to_hide), key=len, reverse=True):
        text = text.replace(value, "<redacted>")
    return text


def sanitize_artifacts(root: Path, values: dict[str, str], *, remove_images: bool = False) -> None:
    """Redact Maestro's generated text evidence and suppress login screenshots."""
    text_suffixes = {".html", ".json", ".log", ".txt", ".xml", ".yaml", ".yml"}
    image_suffixes = {".heic", ".jpeg", ".jpg", ".png", ".webp"}
    if not root.exists():
        return
    for path in root.rglob("*"):
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


def write_html(destination: Path, *, run_id: str, app: Path, app_id: str, simulator: dict[str, str], profile: str, attempts: list[Attempt], tests: int, failures: int, skipped: int) -> None:
    rows = []
    for attempt in attempts:
        state = "pass" if attempt.returncode == 0 else "fail"
        rows.append(f"<tr><td>{html.escape(attempt.flow.name)}</td><td>{attempt.repeat}</td><td>{attempt.number}</td><td class='{state}'>{state.upper()}</td><td>{html.escape(str(attempt.debug.name))}</td></tr>")
    destination.write_text(f"""<!doctype html><meta charset='utf-8'><title>WooCommerce iOS Maestro {html.escape(run_id)}</title>
<style>body{{font:14px system-ui;margin:2rem;max-width:1100px}}table{{border-collapse:collapse;width:100%}}th,td{{border:1px solid #ccc;padding:.45rem;text-align:left}}.pass{{color:#067a35}}.fail{{color:#b42318}}code{{word-break:break-all}}</style>
<h1>WooCommerce iOS Maestro run</h1><p><strong>{html.escape(run_id)}</strong></p>
<ul><li>Profile: {html.escape(profile)}</li><li>App: <code>{html.escape(str(app))}</code></li><li>Bundle: <code>{html.escape(app_id)}</code></li><li>Simulator: {html.escape(simulator['name'])} (<code>{simulator['udid']}</code>)</li><li>Tests: {tests}; failures: {failures}; skipped: {skipped}</li></ul>
<table><thead><tr><th>Flow</th><th>Repeat</th><th>Attempt</th><th>Result</th><th>Diagnostics</th></tr></thead><tbody>{''.join(rows)}</tbody></table>""", encoding="utf-8")


def main() -> int:
    args = parse_args()
    if args.repeat is not None and args.repeat < 1:
        raise SystemExit("--repeat must be a positive integer")
    for command in ("maestro", "xcrun"):
        if not shutil.which(command):
            raise SystemExit(f"Required command is missing: {command}")

    include_default, exclude_default, repeat_default, family = PROFILES[args.profile]
    include = csv(args.include_tags)
    exclude = csv(args.exclude_tags)
    include = include_default if include is None else include
    exclude = exclude_default if exclude is None else exclude
    repeat = args.repeat or repeat_default
    values = load_environment()
    app = args.app.expanduser().resolve()
    app_id = app_identifier(app)
    simulator = resolve_simulator(args.device, family)
    run(["xcrun", "simctl", "install", simulator["udid"], str(app)])

    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_id = f"SUITE-{stamp}-{secrets.token_hex(3)}"
    output_root = (args.output_dir or Path(values.get("WOO_MAESTRO_OUTPUT_DIR", OUTPUT_DEFAULT))).expanduser()
    output = output_root / run_id
    output.mkdir(parents=True, exist_ok=False)
    (output / "screenshots").mkdir()
    (output / "diagnostics").mkdir()
    (output / "logs").mkdir()

    flows = select_flows(args, include, exclude)
    summary = {
        "run_id": run_id, "profile": args.profile, "app": str(app), "app_id": app_id,
        "simulator_name": simulator["name"], "simulator_udid": simulator["udid"],
        "include_tags": include, "exclude_tags": exclude, "repeat": repeat,
        "flows": [str(path.relative_to(REPO_ROOT)) for path in flows],
    }
    (output / "run-summary.json").write_text(json.dumps(summary, indent=2) + "\n")

    if args.seed:
        seed = SCRIPT_DIR / "seed-fixtures.py"
        run([sys.executable, str(seed), "--mode", "seed", "--run-id", run_id, "--manifest", str(output / "run-manifest.json")], env=values)

    attempts: list[Attempt] = []
    env_args = maestro_env_args(values, app_id, run_id)
    try:
        for repetition in range(1, repeat + 1):
            for flow in flows:
                for attempt_number in (1, 2):
                    prefix = f"r{repetition:02d}-{flow.stem}-a{attempt_number}"
                    junit = output / f"{prefix}.xml"
                    log = output / "logs" / f"{prefix}.log"
                    debug = output / "diagnostics" / prefix
                    debug.mkdir()
                    screenshot_dir = output / "screenshots" / prefix
                    screenshot_dir.mkdir()
                    command = ["maestro", "test", "--udid", simulator["udid"], "--config", str(CONFIG_FILE), "--format", "JUNIT", "--output", str(junit), "--debug-output", str(debug), "--test-output-dir", str(screenshot_dir), *env_args, str(flow)]
                    completed = run(command, check=False)
                    log.write_text(redact(completed.stdout + completed.stderr, values), encoding="utf-8")
                    is_login = "login" in flow_tags(flow)
                    sanitize_artifacts(debug, values, remove_images=is_login)
                    sanitize_artifacts(screenshot_dir, values, remove_images=is_login)
                    sanitize_artifacts(junit.parent, values)
                    attempts.append(Attempt(flow, repetition, attempt_number, completed.returncode, junit, log, debug))
                    if completed.returncode == 0:
                        break
    finally:
        if args.seed and not args.no_cleanup:
            run([sys.executable, str(SCRIPT_DIR / "seed-fixtures.py"), "--mode", "cleanup", "--run-id", run_id, "--manifest", str(output / "run-manifest.json")], check=False, env=values)

    final_by_flow_run: dict[tuple[Path, int], Attempt] = {}
    for attempt in attempts:
        final_by_flow_run[(attempt.flow, attempt.repeat)] = attempt
    report_attempts = list(final_by_flow_run.values())
    tests, failures, skipped = write_combined_junit(report_attempts, output / "report.xml")
    write_html(output / "report.html", run_id=run_id, app=app, app_id=app_id, simulator=simulator, profile=args.profile, attempts=attempts, tests=tests, failures=failures, skipped=skipped)
    sanitize_artifacts(output, values)
    print(f"Maestro artifacts: {output}")
    print(f"Simulator: {simulator['name']} ({simulator['udid']})")
    print(f"Bundle identifier: {app_id}")
    print(f"Final results: {tests} tests, {failures} failures, {skipped} skipped")
    return 1 if any(attempt.returncode for attempt in report_attempts) else 0


if __name__ == "__main__":
    raise SystemExit(main())

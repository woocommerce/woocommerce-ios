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
STORES = ("lab", "shared")
# Flows with this tag run against the shared store, every other flow against
# the lab store. --store runs every selected flow against one store instead.
SHARED_STORE_TAG = "store_shared"
# Kept in the simulator's home directory: the host of the store the app was
# last logged in to, so a later run knows whether to sign the app out first.
STORE_MARKER_NAME = ".woo-maestro-store"
NOTIFICATION_FLOW = "ios_notification_long_press.yaml"
STORE_ORDER_PUSH = MAESTRO_DIR / "helpers" / "store_order_push.json"
# Flows read these store-neutral names; the runner fills them from the
# MAESTRO_WOO_LAB_* or MAESTRO_WOO_SHARED_* block of the store a flow runs against.
STORE_SCOPED_SUFFIXES = (
    "JETPACK_STORE_URL",
    "WPCOM_EMAIL",
    "WPCOM_PASSWORD",
    "JETPACK_SITE_ADMIN_USERNAME",
    "JETPACK_SITE_ADMIN_PASSWORD",
    "CONSUMER_KEY",
    "CONSUMER_SECRET",
    "APPLICATION_PASSWORD",
)
# Older .env.local files keep the lab REST keys without the LAB_ prefix.
LEGACY_UNSCOPED_LAB_SUFFIXES = ("CONSUMER_KEY", "CONSUMER_SECRET")
# Seeding and cleanup use the REST keys, and the admin's application password
# to delete uploaded images. Maestro never receives them.
CLEANUP_ONLY_ENVIRONMENT = {
    "MAESTRO_WOO_CONSUMER_KEY",
    "MAESTRO_WOO_CONSUMER_SECRET",
    "MAESTRO_WOO_JETPACK_SITE_ADMIN_USERNAME",
    "MAESTRO_WOO_APPLICATION_PASSWORD",
}
NOT_WOO_STORE_WPCOM_FALLBACK = {
    "MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_EMAIL",
    "MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_PASSWORD",
}

PROFILES = {
    "core": (["smoke_core"], ["flaky_quarantine", "pos_ipad", "ios_system"], "iphone"),
    "phone-full": (["smoke_core", "smoke_extended", "destructive"], ["pos_ipad", "ios_system"], "iphone"),
    "pos-ipad": (["pos_ipad"], [], "ipad"),
    "ios-system": (["ios_system"], [], "iphone"),
}

ORDERED_FLOWS = [
    "diagnostic.yaml",
    "login_not_wp_site.yaml", "login_wrong_credentials.yaml", "login_help.yaml",
    "login_not_woo_store.yaml", "login_wrong_account.yaml", "login_no_jetpack.yaml",
    "login_successful.yaml", "dashboard_stats.yaml",
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
REDACTED = "[redacted]"
MIN_REDACTED_VALUE_LENGTH = 8
ENV_ASSIGNMENT_RE = re.compile(r"^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
ENV_REFERENCE_RE = re.compile(r"\$\{(MAESTRO_[A-Z0-9_]+)\}")
SUBFLOW_REFERENCE_RE = re.compile(r"(?:file:|runFlow:)\s*([^\s#]+\.ya?ml)")
STATUS_EXIT_CODES = {
    "PASS": 0,
    "FLAKY": 0,
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
    parser.add_argument(
        "--store",
        choices=STORES,
        help="Run every selected flow against this store instead of the store each flow needs",
    )
    parser.add_argument("--include-tags")
    parser.add_argument("--exclude-tags")
    parser.add_argument("--repeat", type=int, default=1)
    parser.add_argument("--flow-timeout-seconds", type=float, default=1800)
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
    """Read a value the way bash does, including quotes and a trailing comment."""
    value = raw.strip()
    if value[:1] in {"'", '"'}:
        try:
            return "".join(shlex.split(value, comments=True))
        except ValueError:
            return value
    return value.split(maxsplit=1)[0] if value else ""


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


def select_store_environment(values: dict[str, str], store: str) -> dict[str, str]:
    selected = dict(values)
    for suffix in STORE_SCOPED_SUFFIXES:
        neutral = f"MAESTRO_WOO_{suffix}"
        value = values.get(scoped_store_name(neutral, store), "")
        if not value and store == "lab" and suffix in LEGACY_UNSCOPED_LAB_SUFFIXES:
            value = values.get(neutral, "")
        if value:
            selected[neutral] = value
        else:
            selected.pop(neutral, None)
    return selected


def scoped_store_name(name: str, store: str) -> str:
    suffix = name.removeprefix("MAESTRO_WOO_")
    if suffix not in STORE_SCOPED_SUFFIXES:
        return name
    return f"MAESTRO_WOO_{store.upper()}_{suffix}"


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


# iOS offers to save the login password on top of the dashboard, and Maestro
# can't see anything in the app while that system prompt is up.
PASSWORD_AUTOFILL_DEFAULTS = (
    ("com.apple.WebUI", "AutoFillPasswords"),
    ("com.apple.WebUI", "SavePasswords"),
    ("com.apple.Safari", "AutoFillPasswords"),
    ("com.apple.Safari", "OfferToSaveLoginCredentials"),
)


def turn_off_password_autofill(udid: str) -> None:
    for domain, key in PASSWORD_AUTOFILL_DEFAULTS:
        run(["xcrun", "simctl", "spawn", udid, "defaults", "write", domain, key, "-bool", "NO"])


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


def flow_store(path: Path, store_override: str | None = None) -> str:
    if store_override:
        return store_override
    return "shared" if SHARED_STORE_TAG in flow_tags(path) else "lab"


def in_store_order(flows: list[Path], store_override: str | None = None) -> list[Path]:
    """Lab flows run first, then the flows that need the shared store."""
    return [flow for flow in flows if flow_store(flow, store_override) == "lab"] + [
        flow for flow in flows if flow_store(flow, store_override) == "shared"
    ]


def failed_flow_stems(report: Path) -> set[str]:
    root = ET.parse(report).getroot()
    stems: set[str] = set()
    for case in root.iter("testcase"):
        status = case.find("./properties/property[@name='maestro.status']")
        is_flaky = status is not None and status.get("value") == "FLAKY"
        if case.find("failure") is None and case.find("error") is None and not is_flaky:
            continue
        if flow_file := case.get("file"):
            stems.add(Path(flow_file).stem)
            continue
        haystack = " ".join([case.get("name", ""), case.get("classname", "")])
        stems.update(path.stem for path in FLOWS_DIR.glob("*.yaml") if path.stem in haystack)
    return stems


def select_flows(args: argparse.Namespace, include: list[str], exclude: list[str]) -> list[Path]:
    if args.flows:
        selected = list(dict.fromkeys((path if path.is_absolute() else REPO_ROOT / path).resolve() for path in args.flows))
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


def has_destructive_flows(flows: list[Path]) -> bool:
    return any("destructive" in flow_tags(flow) for flow in flows)


def validate_shared_destructive(flows: list[Path], *, store: str | None) -> None:
    if store == "shared" and has_destructive_flows(flows):
        raise SystemExit(
            "Refusing to run destructive flows against the shared store.\n"
            "Use --store lab for destructive iteration, or remove destructive flows from the selection."
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
    required.discard("MAESTRO_WOO_JETPACK_STORE_HOST")
    if seed:
        required.update(CLEANUP_ONLY_ENVIRONMENT)
    return required


def scoped_required_environment(flows: list[Path], *, seed: bool, store_override: str | None) -> set[str]:
    names = {
        scoped_store_name(name, flow_store(flow, store_override))
        for flow in flows
        for name in required_environment([flow], seed=False)
    }
    if seed:
        names.update(
            scoped_store_name(name, store_override or "lab") for name in required_environment([], seed=True)
        )
    return names


def validate_environment(flows: list[Path], values: dict[str, str], *, seed: bool, store: str = "lab") -> None:
    missing = sorted(
        scoped_store_name(name, store) for name in required_environment(flows, seed=seed) if not values.get(name)
    )
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


def validate_login_store_hosts(flows: list[Path], values: dict[str, str], *, store: str) -> None:
    if not any("MAESTRO_WOO_JETPACK_STORE_URL" in required_environment([flow], seed=False) for flow in flows):
        return
    store_host = normalized_store_host(values.get("MAESTRO_WOO_JETPACK_STORE_URL", ""))
    no_jetpack_host = normalized_store_host(values.get("MAESTRO_WOO_NO_JETPACK_SITE_URL", ""))
    if store_host and store_host == no_jetpack_host:
        upper = store.upper()
        raise SystemExit(
            f"Setup error: selected --store {store} points the Jetpack store at the same host as the no-Jetpack site.\n\n"
            "The selected flow set includes WP.com/Jetpack login flows. Set the "
            f"{store} store block to a Jetpack-connected WooCommerce store with MAESTRO_WOO_{upper}_JETPACK_STORE_URL,\n"
            f"MAESTRO_WOO_{upper}_WPCOM_EMAIL, and MAESTRO_WOO_{upper}_WPCOM_PASSWORD.\n"
            "Keep MAESTRO_WOO_NO_JETPACK_* only for login_no_jetpack.yaml."
        )


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
    environment = {name: value for name, value in os.environ.items() if not name.startswith("MAESTRO_WOO_")}
    for name in sorted(required_names - CLEANUP_ONLY_ENVIRONMENT):
        if value := values.get(name):
            environment[name] = value
    store_url = values.get("MAESTRO_WOO_JETPACK_STORE_URL", "")
    if store_host := normalized_store_host(store_url):
        environment["MAESTRO_WOO_JETPACK_STORE_HOST"] = store_host
    environment["MAESTRO_SUITE_RUN_ID"] = run_id
    return environment


def store_marker(udid: str) -> Path:
    home = run(["xcrun", "simctl", "getenv", udid, "HOME"]).stdout.strip()
    return Path(home) / STORE_MARKER_NAME


def switch_store(udid: str, app: Path, app_id: str, store: str, store_url: str) -> None:
    """Sign the app out when it was last logged in to another store."""
    marker = store_marker(udid)
    store_host = normalized_store_host(store_url)
    logged_in_host = marker.read_text(encoding="utf-8").strip() if marker.exists() else ""
    if store_host == logged_in_host:
        return
    print(f"--- Clearing the app session before the {store} store flows", flush=True)
    run(["xcrun", "simctl", "terminate", udid, app_id], check=False)
    run(["xcrun", "simctl", "uninstall", udid, app_id])
    run(["xcrun", "simctl", "keychain", udid, "reset"])
    run(["xcrun", "simctl", "install", udid, str(app)])
    marker.write_text(f"{store_host}\n", encoding="utf-8")


def forget_store(udid: str) -> None:
    store_marker(udid).unlink(missing_ok=True)


def settle_store(udid: str, store_url: str, status: str, resets_session: bool) -> bool:
    """Name the store again once a flow passed on it; False means the next flow signs in again."""
    if resets_session or status not in ("PASS", "FLAKY"):
        return False
    store_marker(udid).write_text(f"{normalized_store_host(store_url)}\n", encoding="utf-8")
    return True


def deliver_store_order_push(udid: str, app_id: str) -> None:
    # A notification that arrives while the app is open never reaches
    # Notification Center, where the notification flow opens it.
    run(["xcrun", "simctl", "terminate", udid, app_id], check=False)
    run(["xcrun", "simctl", "push", udid, app_id, str(STORE_ORDER_PUSH)])


def maestro_env_args(app_id: str, run_id: str) -> list[str]:
    return ["--env", f"APP_ID={app_id}", "--env", f"SUITE_RUN_ID={run_id}"]


def redaction_targets(values: dict[str, str]) -> set[str]:
    targets: set[str] = set()
    for name, value in values.items():
        if not value:
            continue
        # Short values that are not secrets, such as a "demo" username, also
        # appear inside flow names and artifact paths.
        if not SECRET_NAME_RE.search(name) and not (
            name.startswith("MAESTRO_WOO_") and len(value) >= MIN_REDACTED_VALUE_LENGTH
        ):
            continue
        # Maestro's JSON and the XML and HTML reports keep some characters escaped.
        targets.update(
            {
                value,
                html.escape(value),
                json.dumps(value)[1:-1],
                json.dumps(value, ensure_ascii=False)[1:-1],
            }
        )
    return targets


def redact(text: str, values: dict[str, str]) -> str:
    for value in sorted(redaction_targets(values), key=len, reverse=True):
        text = text.replace(value, REDACTED)
    return text


def process_output_text(output: str | bytes | None) -> str:
    if isinstance(output, bytes):
        return output.decode("utf-8", errors="replace")
    return output or ""


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


def sanitize_artifacts(root: Path, values: dict[str, str]) -> None:
    """Redact Maestro's generated text evidence."""
    text_suffixes = {".html", ".json", ".log", ".txt", ".xml", ".yaml", ".yml"}
    if not root.exists():
        return
    paths = [root] if root.is_file() else root.rglob("*")
    for path in paths:
        if not path.is_file():
            continue
        if path.suffix.lower() in text_suffixes:
            original = path.read_text(errors="replace")
            sanitized = redact(original, values)
            if sanitized != original:
                path.write_text(sanitized, encoding="utf-8")


def write_combined_junit(attempts: list[Attempt], destination: Path) -> tuple[int, int, int]:
    suites = ET.Element("testsuites")
    tests = failures = skipped = 0
    attempts_by_execution: dict[tuple[Path, int], list[int]] = {}
    for attempt in attempts:
        attempts_by_execution.setdefault((attempt.flow, attempt.repeat), []).append(
            attempt.returncode
        )
    for attempt in attempts:
        status = flow_status(attempts_by_execution[(attempt.flow, attempt.repeat)])
        if not attempt.junit.exists():
            suite = ET.SubElement(suites, "testsuite", name=f"{attempt.flow.stem}-attempt-{attempt.number}", tests="1", failures="1")
            case = ET.SubElement(suite, "testcase", name=attempt.flow.stem, file=str(attempt.flow.relative_to(REPO_ROOT)))
            if status == "FLAKY":
                properties = ET.SubElement(case, "properties")
                ET.SubElement(properties, "property", name="maestro.status", value="FLAKY")
            ET.SubElement(case, "failure", message="Maestro did not produce JUnit output")
            tests += 1
            failures += 1
            continue
        root = ET.parse(attempt.junit).getroot()
        children = [root] if root.tag == "testsuite" else list(root.findall("testsuite"))
        for suite in children:
            suite.set("name", f"{suite.get('name', attempt.flow.stem)} [run {attempt.repeat} attempt {attempt.number}]")
            if status == "FLAKY":
                for case in suite.iter("testcase"):
                    properties = case.find("properties")
                    if properties is None:
                        properties = ET.Element("properties")
                        case.insert(0, properties)
                    existing = properties.find("property[@name='maestro.status']")
                    if existing is None:
                        ET.SubElement(properties, "property", name="maestro.status", value="FLAKY")
                    else:
                        existing.set("value", "FLAKY")
            for case in suite.iter("testcase"):
                case.set("file", str(attempt.flow.relative_to(REPO_ROOT)))
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


def selection_arguments(args: argparse.Namespace) -> list[str]:
    """Options beyond the profile that decided which flows ran and where."""
    arguments: list[str] = []
    if args.store:
        arguments += ["--store", args.store]
    if args.include_tags is not None:
        arguments += ["--include-tags", args.include_tags]
    if args.exclude_tags is not None:
        arguments += ["--exclude-tags", args.exclude_tags]
    if args.repeat > 1:
        arguments += ["--repeat", str(args.repeat)]
    arguments += [str((path if path.is_absolute() else REPO_ROOT / path).resolve()) for path in args.flows]
    return arguments


def write_html(destination: Path, *, run_id: str, app: Path, app_id: str, simulator: dict[str, str], profile: str, attempts: list[Attempt], status: str, tests: int, failures: int, skipped: int, candidate_kind: str = "developer", app_sha256: str = "", seed: bool = False, flow_timeout_seconds: float = 900, selection: list[str] | None = None) -> None:
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
            *(shlex.quote(argument) for argument in selection or []),
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
    if args.repeat < 1:
        raise SystemExit("--repeat must be a positive integer")
    if args.flow_timeout_seconds <= 0:
        raise SystemExit("--flow-timeout-seconds must be positive")

    include_default, exclude_default, family = PROFILES[args.profile]
    include = csv(args.include_tags)
    exclude = csv(args.exclude_tags)
    include = include_default if include is None else include
    exclude = exclude_default if exclude is None else exclude
    repeat = args.repeat
    flows = in_store_order(select_flows(args, include, exclude), args.store)
    if args.plan:
        destructive_cleanup_required = any("destructive" in flow_tags(flow) for flow in flows)
        required = sorted(
            scoped_required_environment(
                flows,
                seed=args.seed or destructive_cleanup_required,
                store_override=args.store,
            )
        )
        print("--- Maestro execution plan")
        print(f"Profile:      {args.profile}")
        print(f"Store:        {args.store or 'per flow'}")
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
            suffix = " (shared store)" if not args.store and flow_store(flow) == "shared" else ""
            print(f"  - {flow.relative_to(REPO_ROOT)}{suffix}")
        print("Required environment:")
        if required:
            for name in required:
                print(f"  - {name}")
        else:
            print("  - <none>")
        return 0

    validate_destructive_cleanup(flows, seed=args.seed)
    validate_shared_destructive(flows, store=args.store)
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

    values = normalized_flow_environment(flows, values)
    run_stores = [store for store in STORES if any(flow_store(flow, args.store) == store for flow in flows)]
    store_flows = {store: [flow for flow in flows if flow_store(flow, args.store) == store] for store in run_stores}
    store_values = {store: select_store_environment(values, store) for store in run_stores}
    for store in run_stores:
        validate_environment(store_flows[store], store_values[store], seed=False, store=store)
        validate_login_store_hosts(store_flows[store], store_values[store], store=store)
    # Seeding and cleanup reach the store the destructive flows run against.
    seed_store = args.store or "lab"
    seed_values = select_store_environment(values, seed_store)
    if args.seed:
        validate_environment([], seed_values, seed=True, store=seed_store)
    manifest = output / "run-manifest.json"
    simulator = resolve_simulator(args.device, family)
    locale = run(
        [sys.executable, str(DEVICE_LOCALE), "--device", simulator["udid"]],
        capture=False,
        check=False,
    )
    if locale.returncode:
        return locale.returncode
    turn_off_password_autofill(simulator["udid"])
    run(["xcrun", "simctl", "install", simulator["udid"], str(app)])
    summary = {
        "run_id": run_id, "profile": args.profile, "store": args.store or "per flow", "app": str(app), "app_id": app_id,
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
        seeded = run(
            [sys.executable, str(seed), "--mode", "seed", "--run-id", run_id, "--manifest", str(output / "run-manifest.json")],
            check=False,
            env=seed_values,
        )
        if seeded.returncode:
            raise SystemExit(redact((seeded.stderr or seeded.stdout).strip(), values))


    attempts: list[Attempt] = []
    env_args = maestro_env_args(app_id, run_id)
    maestro_environments = {
        store: maestro_process_environment(
            store_values[store],
            runtime_environment_names(store_flows[store], seed=args.seed),
            run_id,
        )
        for store in run_stores
    }
    active_store: str | None = None
    total_runs = len(flows) * repeat
    suite_started = time.monotonic()
    run_index = 0
    statuses: list[str] = []
    cleanup_status = "NOT_REQUESTED"
    cleanup_error = ""
    print("--- Running Maestro flows", flush=True)
    print(f"Run ID:       {run_id}", flush=True)
    print(f"Profile:      {args.profile}", flush=True)
    print(f"Store:        {args.store or 'per flow'}", flush=True)
    print(f"Simulator:    {simulator['name']} ({simulator['udid']})", flush=True)
    print(f"Output:       {output}", flush=True)
    print(f"Repeat:       {repeat}", flush=True)
    print(f"Include tags: {','.join(include) or '<none>'}", flush=True)
    print(f"Exclude tags: {','.join(exclude) or '<none>'}", flush=True)
    try:
        for repetition in range(1, repeat + 1):
            for flow in flows:
                store = flow_store(flow, args.store)
                store_url = store_values[store].get("MAESTRO_WOO_JETPACK_STORE_URL", "")
                # Login flows reset the session themselves and can end signed in to
                # another site, so the flow after them signs in again.
                resets_session = "login" in flow_tags(flow)
                if not resets_session and store != active_store:
                    switch_store(simulator["udid"], app, app_id, store, store_url)
                    active_store = store
                # A flow that fails or is stopped half way can leave the app signed in
                # to another site, so the marker names a store only between flows.
                forget_store(simulator["udid"])
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
                    if flow.name == NOTIFICATION_FLOW:
                        deliver_store_order_push(simulator["udid"], app_id)
                    command = ["maestro", "test", "--udid", simulator["udid"], "--config", str(CONFIG_FILE), "--format", "JUNIT", "--output", str(junit), "--debug-output", str(debug), "--test-output-dir", str(screenshot_dir), *env_args, str(flow)]
                    try:
                        completed = run(
                            command,
                            check=False,
                            env=maestro_environments[store],
                            timeout=args.flow_timeout_seconds,
                        )
                    except subprocess.TimeoutExpired as error:
                        stdout = process_output_text(error.stdout)
                        stderr = process_output_text(error.stderr)
                        stderr += f"\nTimed out after {args.flow_timeout_seconds:g} seconds\n"
                        completed = subprocess.CompletedProcess(command, 124, stdout, stderr)
                    log.write_text(redact(completed.stdout + completed.stderr, values), encoding="utf-8")
                    sanitize_artifacts(debug, values)
                    sanitize_artifacts(screenshot_dir, values)
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
                if not settle_store(simulator["udid"], store_url, status, resets_session):
                    active_store = None
                statuses.append(status)
                duration = round(time.monotonic() - flow_started)
                print(f"  {status} in {duration}s", flush=True)
    finally:
        if args.seed and not args.no_cleanup:
            cleanup_result = run(
                [sys.executable, str(SCRIPT_DIR / "seed-fixtures.py"), "--mode", "cleanup", "--run-id", run_id, "--manifest", str(output / "run-manifest.json")],
                check=False,
                env=seed_values,
            )
            cleanup_status = "PASS" if cleanup_result.returncode == 0 else "FAIL"
            # Surface cleanup output even when it succeeds. It reports orders it
            # could not attribute to this run and therefore left on the store,
            # which is exactly the case a PASS would otherwise hide.
            cleanup_output = redact(
                "\n".join(
                    part.strip()
                    for part in (cleanup_result.stdout, cleanup_result.stderr)
                    if part and part.strip()
                ),
                values,
            )
            if cleanup_output:
                print(cleanup_output, flush=True)
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
        selection=selection_arguments(args),
    )
    sanitize_artifacts(output, values)
    flaky = statuses.count("FLAKY")
    passed = statuses.count("PASS") + flaky
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
        f"Result: {passed} passed ({flaky} flaky), {failed} failed, {timed_out} timed out "
        f"out of {total_runs} executions ({suite_duration}s)"
    )
    print(f"Overall status: {result.status}")
    print(f"Final results: {result.tests} tests, {result.failures} failures, {result.skipped} skipped")
    if not args.no_open:
        run(["open", str(output / "report.html")], capture=False, check=False)
    return result.exit_code


if __name__ == "__main__":
    raise SystemExit(main())

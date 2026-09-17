#!/usr/bin/env python3
"""Inspect iOS Maestro prerequisites without printing secret values."""

from __future__ import annotations

import argparse
import importlib.util
import os
import shutil
import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
RUNNER_PATH = SCRIPT_DIR / "run-smoke-tests.py"
CHECK_TOOLCHAIN = SCRIPT_DIR / "check-toolchain.py"
DEVICE_LOCALE = SCRIPT_DIR / "device_locale.py"
SPEC = importlib.util.spec_from_file_location("woo_maestro_runner", RUNNER_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Cannot load {RUNNER_PATH}")
RUNNER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = RUNNER
SPEC.loader.exec_module(RUNNER)


def check_toolchain() -> tuple[bool, str]:
    result = subprocess.run(
        [sys.executable, str(CHECK_TOOLCHAIN)],
        cwd=RUNNER.REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode == 0:
        return True, "toolchain matches the repository pin"
    details = [line.strip() for line in result.stderr.splitlines() if line.strip()]
    reason = details[-1] if details else "toolchain check failed"
    return False, f"toolchain: {reason}"


def check_simulator_locale(device: str) -> tuple[bool, str]:
    result = subprocess.run(
        [sys.executable, str(DEVICE_LOCALE), "--device", device],
        cwd=RUNNER.REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode == 0:
        details = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        return True, details[-1] if details else "simulator primary language is English"
    details = [line.strip() for line in result.stderr.splitlines() if line.strip()]
    reason = details[-1] if details else "simulator language check failed"
    return False, f"simulator language: {reason}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path)
    parser.add_argument("--profile", choices=sorted(RUNNER.PROFILES), default="core")
    parser.add_argument("--device")
    parser.add_argument("--include-tags")
    parser.add_argument("--exclude-tags")
    parser.add_argument("--seed", action="store_true")
    args = parser.parse_args()

    checks: list[tuple[bool, str]] = []
    for command in ("bash", "python3", "maestro", "xcrun", "plutil"):
        path = shutil.which(command)
        checks.append((path is not None, f"{command}: {path or 'not found'}"))
    checks.append(check_toolchain())

    try:
        values = RUNNER.load_environment()
        checks.append((True, "local environment syntax is valid"))
    except SystemExit:
        values = dict(os.environ)
        checks.append((False, "local environment syntax is invalid"))

    try:
        app_id = RUNNER.app_identifier(args.app)
        checks.append((True, f"app bundle identifier: {app_id}"))
    except (SystemExit, subprocess.SubprocessError) as error:
        checks.append((False, f"app bundle: {error}"))

    family = RUNNER.PROFILES[args.profile][3]
    try:
        simulator = RUNNER.resolve_simulator(args.device, family, boot=False)
        checks.append((True, f"simulator: {simulator['name']} ({simulator['udid']})"))
        checks.append(check_simulator_locale(simulator["udid"]))
    except (SystemExit, subprocess.SubprocessError) as error:
        checks.append((False, f"simulator: {error}"))

    include = RUNNER.csv(args.include_tags) or RUNNER.PROFILES[args.profile][0]
    exclude = RUNNER.csv(args.exclude_tags)
    if exclude is None:
        exclude = RUNNER.PROFILES[args.profile][1]
    namespace = argparse.Namespace(flows=[], rerun_failed=None)
    try:
        flows = RUNNER.select_flows(namespace, include, exclude)
        checks.append((True, f"selected flows: {len(flows)}"))
    except SystemExit as error:
        checks.append((False, f"flow selection: {error}"))

    required = RUNNER.required_environment(flows if 'flows' in locals() else [], seed=args.seed)
    missing = sorted(name for name in required if not values.get(name))
    checks.append((not missing, "required credentials are present" if not missing else "missing variables: " + ", ".join(missing)))

    print("WooCommerce iOS Maestro doctor")
    print(f"profile: {args.profile}")
    failures = 0
    for passed, message in checks:
        print(f"[{'OK' if passed else 'FAIL'}] {message}")
        failures += int(not passed)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Lint local Maestro env files without printing secret values."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


ASSIGNMENT_RE = re.compile(r"^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
INLINE_COMMENT_RE = re.compile(r"\s+#")
SHELL_META_RE = re.compile(r"""[\s()&;<>|`$]""")
DEPRECATED_ALIASES = {
    "MAESTRO_WOO_LAB_STORE_URL": "MAESTRO_WOO_LAB_JETPACK_STORE_URL",
    "MAESTRO_WOO_LAB_EMAIL": "MAESTRO_WOO_LAB_WPCOM_EMAIL",
    "MAESTRO_WOO_LAB_PASSWORD": "MAESTRO_WOO_LAB_WPCOM_PASSWORD",
    "MAESTRO_WOO_JN_SITE_URL": "MAESTRO_WOO_NO_JETPACK_SITE_URL",
    "MAESTRO_WOO_JN_USERNAME": "MAESTRO_WOO_NO_JETPACK_SITE_ADMIN_USERNAME",
    "MAESTRO_WOO_JN_PASSWORD": "MAESTRO_WOO_NO_JETPACK_SITE_ADMIN_PASSWORD",
}


def expected_names(example_path: Path) -> set[str]:
    names: set[str] = set()
    if not example_path.exists():
        return names
    for line in example_path.read_text(errors="replace").splitlines():
        match = ASSIGNMENT_RE.match(line.strip())
        if match:
            names.add(match.group(1))
    return names


def strip_inline_comment(value: str) -> str:
    split = INLINE_COMMENT_RE.split(value, maxsplit=1)
    return split[0].rstrip()


def is_quoted(value: str) -> bool:
    value = value.strip()
    return len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}


def lint(path: Path, example_path: Path, seed: bool) -> tuple[list[str], list[str], int]:
    errors: list[str] = []
    warnings: list[str] = []
    count = 0
    expected = expected_names(example_path)

    if not path.exists():
        return [f"{path} does not exist."], warnings, count

    syntax = subprocess.run(["bash", "-n", str(path)], capture_output=True, text=True)
    if syntax.returncode != 0:
        errors.append(
            f"{path}: shell syntax check failed. Check quoting around passwords or values with shell metacharacters."
        )

    seen: set[str] = set()
    for line_number, raw_line in enumerate(path.read_text(errors="replace").splitlines(), start=1):
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        match = ASSIGNMENT_RE.match(stripped)
        if not match:
            errors.append(f"{path}:{line_number}: expected NAME=value or export NAME=value.")
            continue

        name, raw_value = match.groups()
        count += 1
        seen.add(name)

        value = strip_inline_comment(raw_value)
        if name.startswith("MAESTRO_WOO_") and expected and name not in expected and name not in DEPRECATED_ALIASES:
            warnings.append(f"{path}:{line_number}: {name} is not declared in .maestro/env.example.")

        if name in DEPRECATED_ALIASES:
            warnings.append(f"{path}:{line_number}: {name} is supported as a legacy alias; prefer {DEPRECATED_ALIASES[name]}.")

        if not seed and re.search(r"MAESTRO_WOO_.*CONSUMER_(KEY|SECRET)$", name):
            warnings.append(f"{path}:{line_number}: {name} is only needed when running with --seed.")

        if value and not is_quoted(value) and SHELL_META_RE.search(value):
            errors.append(
                f"{path}:{line_number}: {name} has an unquoted value containing shell metacharacters; wrap it in single quotes."
            )

    for name in sorted(seen):
        if name.startswith("MAESTRO_WOO_") and "PASSWORD" in name:
            # This intentionally does not inspect or print the value. The line-level checks above catch
            # shell-unsafe password characters before the file is sourced.
            continue

    return errors, warnings, count


def main() -> int:
    parser = argparse.ArgumentParser(description="Lint .maestro/.env.local without printing secret values.")
    parser.add_argument("--file", default=".maestro/.env.local", type=Path)
    parser.add_argument("--example", default=".maestro/env.example", type=Path)
    parser.add_argument("--seed", action="store_true", help="Allow Woo REST consumer key/secret variables.")
    args = parser.parse_args()

    errors, warnings, count = lint(args.file, args.example, args.seed)
    for warning in warnings:
        print(f"warning: {warning}", file=sys.stderr)
    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"OK: {args.file} contains {count} assignment(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

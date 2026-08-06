#!/usr/bin/env python3
"""Report the local Maestro toolchain against the repository pin."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


VERSION_FILE = Path(__file__).resolve().parents[1] / "toolchain.properties"
MAESTRO_VERSION_PATTERN = re.compile(r"(?m)^\s*(\d+\.\d+\.\d+(?:[-+][^\s]+)?)\s*$")
JAVA_VERSION_PATTERN = re.compile(r'(?:openjdk|java) version "([^"]+)"')


def load_versions() -> dict[str, str]:
    return dict(
        line.split("=", 1)
        for line in VERSION_FILE.read_text(encoding="utf-8").splitlines()
        if line.strip()
    )


def command_output(command: list[str]) -> str:
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
    except FileNotFoundError:
        print(f"Required command not found: {command[0]}", file=sys.stderr)
        raise SystemExit(2) from None
    except subprocess.CalledProcessError as error:
        print(
            f"Could not run {' '.join(command)} successfully (exit {error.returncode})",
            file=sys.stderr,
        )
        raise SystemExit(2) from None
    return result.stdout + result.stderr


def parsed_version(pattern: re.Pattern[str], output: str, tool: str) -> str:
    match = pattern.search(output)
    if match is None:
        print(f"Could not parse {tool} version output", file=sys.stderr)
        raise SystemExit(2)
    return match.group(1)


def main() -> int:
    expected = load_versions()
    maestro_output = command_output(["maestro", "--version"])
    java_output = command_output(["java", "-version"])
    maestro_version = parsed_version(MAESTRO_VERSION_PATTERN, maestro_output, "Maestro")
    java_version = parsed_version(JAVA_VERSION_PATTERN, java_output, "Java")

    print(f"Maestro: expected {expected['maestro']}, actual {maestro_version}")
    print(f"Java: expected major {expected['java']}, actual {java_version}")
    if maestro_version != expected["maestro"]:
        print(
            f"Maestro version mismatch: expected {expected['maestro']}, actual {maestro_version}",
            file=sys.stderr,
        )
        return 1
    java_major = java_version.split(".", 1)[0]
    if java_major != expected["java"]:
        print(
            f"Java version mismatch: expected major {expected['java']}, actual {java_version}",
            file=sys.stderr,
        )
        return 1
    print("Maestro toolchain OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

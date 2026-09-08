#!/usr/bin/env python3
"""Validate that an iOS simulator uses English as its primary language."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from typing import Callable


LOCALE_RE = re.compile(r"^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{1,8})*$")


class SimulatorLocaleError(RuntimeError):
    """Raised when the simulator language cannot be read or is not English."""


@dataclass(frozen=True)
class SimulatorLocale:
    primary: str

    @property
    def message(self) -> str:
        return f"simulator primary language {self.primary} is English (AppleLanguages)"


CommandRunner = Callable[[list[str]], subprocess.CompletedProcess[str]]


def run_command(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, capture_output=True, text=True, check=False)


def parse_primary_locale(value: str) -> str | None:
    for line in value.splitlines():
        candidate = line.strip().rstrip(",").strip()
        if len(candidate) >= 2 and candidate[0] == candidate[-1] == '"':
            candidate = candidate[1:-1]
        if LOCALE_RE.fullmatch(candidate):
            return candidate.replace("_", "-")
    return None


def read_simulator_locale(
    device: str,
    command_runner: CommandRunner = run_command,
) -> SimulatorLocale:
    command = [
        "xcrun",
        "simctl",
        "spawn",
        device,
        "defaults",
        "read",
        "NSGlobalDomain",
        "AppleLanguages",
    ]
    result = command_runner(command)
    if result.returncode != 0:
        details = [line.strip() for line in result.stderr.splitlines() if line.strip()]
        reason = details[-1] if details else "AppleLanguages could not be read"
        raise SimulatorLocaleError(
            f"could not determine the primary language for simulator {device}: {reason}"
        )
    primary = parse_primary_locale(result.stdout)
    if primary is None:
        raise SimulatorLocaleError(
            f"could not parse the primary language for simulator {device}"
        )
    return SimulatorLocale(primary=primary)


def ensure_english_simulator_locale(
    device: str,
    command_runner: CommandRunner = run_command,
) -> SimulatorLocale:
    locale = read_simulator_locale(device, command_runner)
    language = locale.primary.split("-", maxsplit=1)[0].lower()
    if language != "en":
        raise SimulatorLocaleError(
            f"simulator {device} primary language is {locale.primary}; Maestro flows require English. "
            "Make English the first Preferred Language in the simulator's Language & Region settings, "
            "then rerun pre-flight"
        )
    return locale


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Require an English primary language on an iOS simulator."
    )
    parser.add_argument("--device", required=True, help="iOS simulator UDID")
    args = parser.parse_args()

    try:
        locale = ensure_english_simulator_locale(args.device)
    except SimulatorLocaleError as error:
        print(f"Setup error: {error}", file=sys.stderr)
        return 1
    print(locale.message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

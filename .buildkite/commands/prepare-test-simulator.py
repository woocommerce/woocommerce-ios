#!/usr/bin/env python3
"""Prepare one simulator in an ephemeral Buildkite VM after runtime personalization."""

import json
import os
import subprocess
import sys
import time


def run(arguments, timeout=20):
    return subprocess.run(arguments, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          universal_newlines=True, timeout=timeout)


if os.environ.get("BUILDKITE") != "true":
    sys.exit("This helper only runs in a task-owned Buildkite VM.")
if len(sys.argv) != 2:
    sys.exit("Usage: prepare-test-simulator.py <simulator name>")

version_result = run(["xcodebuild", "-version"])
if version_result.returncode:
    sys.exit(version_result.stdout)
version = version_result.stdout.splitlines()[0].split()[1]
components = tuple(int(part) for part in version.split(".")[:2])
if components < (27, 2):
    print("Xcode {} does not need runtime personalization.".format(version), flush=True)
    sys.exit(0)

name = sys.argv[1]
inventory = run(["xcrun", "simctl", "list", "devices", "available", "--json"])
if inventory.returncode:
    sys.exit(inventory.stdout)
devices = json.loads(inventory.stdout)["devices"]
matches = [device for group in devices.values() for device in group if device["name"] == name]
if len(matches) != 1:
    sys.exit("Expected one available simulator named {!r}; found {}.".format(name, len(matches)))
udid = matches[0]["udid"]

# Xcode 27.2 remounts VM runtimes during personalization. A boot during that
# transition can lose its runtime or launchd domain (AINFRA-3618).
print("Personalizing Xcode {} simulator runtimes.".format(version), flush=True)
personalization = run(["xcrun", "simctl", "personalization", "scan-and-personalize"], timeout=60)
print(personalization.stdout, flush=True)
if personalization.returncode:
    sys.exit(personalization.returncode)

deadline = time.monotonic() + 90
last_error = "Simulator did not remain booted."
while time.monotonic() < deadline:
    try:
        boot = run(["xcrun", "simctl", "boot", udid])
        ready = run(["xcrun", "simctl", "bootstatus", udid, "-b"], timeout=25)
        if ready.returncode == 0:
            time.sleep(5)
            current = run(["xcrun", "simctl", "list", "devices", "--json"])
            if current.returncode == 0:
                state = [device for group in json.loads(current.stdout)["devices"].values()
                         for device in group if device["udid"] == udid]
                if len(state) == 1 and state[0]["state"] == "Booted":
                    print("{} ({}) is booted after personalization.".format(name, udid), flush=True)
                    sys.exit(0)
        last_error = ready.stdout or boot.stdout
    except subprocess.TimeoutExpired as error:
        last_error = str(error)
    print("Retrying {} after runtime registration: {}".format(name, last_error[-800:]), flush=True)
    run(["xcrun", "simctl", "shutdown", udid])
    run(["xcrun", "simctl", "erase", udid])
    time.sleep(3)

sys.exit("Simulator readiness timed out: " + last_error)

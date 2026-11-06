#!/usr/bin/env python3
"""Prepare one simulator in an ephemeral Buildkite VM after runtime personalization."""

import json
import os
import subprocess
import sys
import time


def prepare(name):
    deadline = time.monotonic() + 180

    def run(arguments, timeout=20):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("Simulator preparation exceeded 180 seconds.")
        return subprocess.run(arguments, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              universal_newlines=True, timeout=min(timeout, remaining))

    version_result = run(["xcodebuild", "-version"])
    if version_result.returncode:
        raise RuntimeError(version_result.stdout)
    version = version_result.stdout.splitlines()[0].split()[1]
    if tuple(int(part) for part in version.split(".")[:2]) < (27, 2):
        print("Xcode {} does not need runtime personalization.".format(version), flush=True)
        return

    # Xcode 27.2 remounts VM runtimes during personalization (AINFRA-3618).
    # A boot during that transition can lose its runtime or launchd domain.
    print("Personalizing Xcode {} simulator runtimes.".format(version), flush=True)
    personalization = run(["xcrun", "simctl", "personalization", "scan-and-personalize"], timeout=60)
    print(personalization.stdout, flush=True)
    if personalization.returncode:
        raise RuntimeError("Runtime personalization failed.")

    udid = None
    last_error = "Simulator did not remain booted."
    while time.monotonic() < deadline:
        try:
            inventory = run(["xcrun", "simctl", "list", "devices", "--json"])
            if inventory.returncode:
                raise RuntimeError(inventory.stdout)
            matches = {device["udid"]: device
                       for group in json.loads(inventory.stdout)["devices"].values()
                       for device in group if device["name"] == name}
            if len(matches) > 1:
                raise ValueError("More than one simulator is named {!r}.".format(name))
            if not matches:
                raise RuntimeError("Simulator {!r} is temporarily unavailable.".format(name))
            udid, device = next(iter(matches.items()))
            print("{} state: {}".format(name, device["state"]), flush=True)
            if device["state"] == "Shutting Down":
                time.sleep(min(3, max(0, deadline - time.monotonic())))
                continue
            if device["state"] == "Shutdown":
                erased = run(["xcrun", "simctl", "erase", udid])
                if erased.returncode:
                    raise RuntimeError(erased.stdout)
                boot = run(["xcrun", "simctl", "boot", udid])
                if boot.returncode:
                    raise RuntimeError(boot.stdout)
            # A timeout here leaves the boot running. Erasing on each timeout
            # would repeatedly restart first-boot migrations.
            ready = run(["xcrun", "simctl", "bootstatus", udid, "-b"], timeout=50)
            if ready.returncode:
                raise RuntimeError(ready.stdout)
            if deadline - time.monotonic() < 10:
                break
            time.sleep(10)
            current = run(["xcrun", "simctl", "list", "devices", "--json"])
            if current.returncode:
                raise RuntimeError(current.stdout)
            states = [device for group in json.loads(current.stdout)["devices"].values()
                      for device in group if device["udid"] == udid]
            if len(states) == 1 and states[0]["state"] == "Booted":
                print("{} ({}) is booted after personalization.".format(name, udid), flush=True)
                return
            last_error = "Simulator changed state after boot completed."
        except (subprocess.TimeoutExpired, RuntimeError, json.JSONDecodeError) as error:
            last_error = str(error)
        print("Waiting for {}: {}".format(name, last_error[-800:]), flush=True)
        time.sleep(min(3, max(0, deadline - time.monotonic())))
    raise TimeoutError("Simulator preparation timed out: " + last_error)


if __name__ == "__main__":
    if os.environ.get("BUILDKITE") != "true":
        sys.exit("This helper only runs in a task-owned Buildkite VM.")
    if len(sys.argv) != 2:
        sys.exit("Usage: prepare-test-simulator.py <simulator name>")
    try:
        prepare(sys.argv[1])
    except (TimeoutError, ValueError, subprocess.TimeoutExpired, RuntimeError) as error:
        sys.exit(str(error))

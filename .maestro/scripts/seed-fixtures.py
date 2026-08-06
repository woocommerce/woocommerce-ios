#!/usr/bin/env python3
"""Optional run-owned REST seed/cleanup hook.

Normal Maestro execution never calls this script. The initial iOS stack keeps
UI-created entities as the source of truth; this hook records the explicit
request and provides a stable extension point without making consumer keys a
preflight dependency.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("seed", "cleanup"), required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()
    required = ("MAESTRO_WOO_CONSUMER_KEY", "MAESTRO_WOO_CONSUMER_SECRET")
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        parser.error("explicit REST seed/cleanup requires: " + ", ".join(missing))
    if args.mode == "seed":
        args.manifest.write_text(json.dumps({"run_id": args.run_id, "entities": []}, indent=2) + "\n")
        print("Seed hook ready; this suite creates its run-owned fixtures through the UI.")
    else:
        if not args.manifest.exists():
            parser.error(f"manifest does not exist: {args.manifest}")
        print("Cleanup hook found no REST-seeded entities; UI-created leftovers are allowed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

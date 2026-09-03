#!/usr/bin/env python3
"""Journal and clean run-owned iOS Maestro entities through Woo REST."""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any


RUN_ID_RE = re.compile(r"^SUITE-\d{8}T\d{6}Z-[a-f0-9]{6}$")
API_PREFIX = "/wp-json/wc/v3/"


class SmokeSetupError(RuntimeError):
    pass


def required_environment(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SmokeSetupError(f"Missing required environment variable: {name}")
    return value


def strict_run_id(value: str) -> str:
    if not RUN_ID_RE.fullmatch(value):
        raise SmokeSetupError(f"Invalid suite run ID: {value!r}")
    return value


def write_manifest(path: Path, contents: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(contents, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def read_manifest(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise SmokeSetupError(f"Cleanup manifest does not exist: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


class WooClient:
    def __init__(self) -> None:
        self.site_url = required_environment("MAESTRO_WOO_LAB_JETPACK_STORE_URL").rstrip("/")
        key = required_environment("MAESTRO_WOO_CONSUMER_KEY")
        secret = required_environment("MAESTRO_WOO_CONSUMER_SECRET")
        token = base64.b64encode(f"{key}:{secret}".encode()).decode("ascii")
        self.headers = {
            "Accept": "application/json",
            "Authorization": f"Basic {token}",
            "User-Agent": "woocommerce-ios-maestro-smoke",
        }

    def request(self, method: str, path: str, *, query: dict[str, Any] | None = None) -> Any:
        url = self.site_url + API_PREFIX + path.lstrip("/")
        if query:
            url += "?" + urllib.parse.urlencode(query, doseq=True)
        request = urllib.request.Request(url, headers=self.headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                payload = response.read().decode("utf-8")
                return json.loads(payload) if payload else {}
        except urllib.error.HTTPError as error:
            raise SmokeSetupError(
                f"WooCommerce API {method} {path} failed with HTTP {error.code}"
            ) from error
        except urllib.error.URLError as error:
            raise SmokeSetupError(f"WooCommerce API {method} {path} failed: {error.reason}") from error

    def list(self, path: str, **query: Any) -> list[dict[str, Any]]:
        query.setdefault("per_page", 100)
        return self.request("GET", path, query=query)

    def delete(self, path: str, entity_id: int) -> None:
        self.request("DELETE", f"{path}/{entity_id}", query={"force": "true"})


def initialize(args: argparse.Namespace) -> None:
    run_id = strict_run_id(args.run_id)
    manifest = {
        "run_id": run_id,
        "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "discovery_complete": False,
        "entities": [],
    }
    write_manifest(args.manifest, manifest)
    print(f"Initialized cleanup journal for {run_id}")


def order_contains_run_id(order: dict[str, Any], run_id: str) -> bool:
    candidates = [str(order.get("customer_note", ""))]
    candidates.extend(str(item.get("name", "")) for item in order.get("line_items", []))
    candidates.extend(str(item.get("value", "")) for item in order.get("meta_data", []))
    return any(run_id in candidate for candidate in candidates)


def discover_entities(client: WooClient, manifest: dict[str, Any]) -> list[dict[str, Any]]:
    run_id = strict_run_id(str(manifest.get("run_id", "")))
    entities: list[dict[str, Any]] = []
    for product in client.list("products", search=run_id, status="any"):
        if run_id in str(product.get("name", "")):
            entities.append({"type": "product", "id": int(product["id"])})
    for order in client.list(
        "orders",
        after=manifest["created_at"],
        status="any",
        order="asc",
    ):
        if order_contains_run_id(order, run_id):
            entities.append({"type": "order", "id": int(order["id"])})
    return entities


def cleanup(args: argparse.Namespace) -> None:
    manifest = read_manifest(args.manifest)
    if strict_run_id(args.run_id) != manifest.get("run_id"):
        raise SmokeSetupError("Cleanup run ID does not match the manifest")
    client = WooClient()
    if not manifest.get("discovery_complete", False):
        manifest["entities"] = discover_entities(client, manifest)
        manifest["discovery_complete"] = True
        write_manifest(args.manifest, manifest)

    paths = {"order": "orders", "product": "products"}
    errors: list[str] = []
    original_count = len(manifest["entities"])
    for entity in reversed(list(manifest["entities"])):
        try:
            client.delete(paths[entity["type"]], int(entity["id"]))
        except SmokeSetupError as error:
            errors.append(str(error))
        else:
            manifest["entities"].remove(entity)
            write_manifest(args.manifest, manifest)
    if errors:
        raise SmokeSetupError(f"Cleanup completed with {len(errors)} deletion error(s)")
    print(f"Cleaned {original_count} run-owned entities")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("seed", "cleanup"), required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.mode == "seed":
            initialize(args)
        else:
            cleanup(args)
    except (SmokeSetupError, KeyError, ValueError, json.JSONDecodeError) as error:
        print(f"Maestro fixture cleanup error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

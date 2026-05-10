#!/usr/bin/env python3
"""Production security smoke checks that never print sensitive response bodies."""

from __future__ import annotations

import os
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from urllib.parse import urljoin


BASE_URL = os.environ.get("ASTRONOVA_BASE_URL", "https://astronova.onrender.com").rstrip("/") + "/"
TIMEOUT = float(os.environ.get("ASTRONOVA_PROD_TIMEOUT", "12"))


@dataclass
class Response:
    status: int
    body_size: int
    body: bytes


def fetch(path: str, *, headers: dict[str, str] | None = None) -> Response:
    request = urllib.request.Request(urljoin(BASE_URL, path.lstrip("/")), headers=headers or {})
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            body = response.read()
            return Response(response.status, len(body), body)
    except urllib.error.HTTPError as error:
        body = error.read()
        return Response(error.code, len(body), body)


def check(condition: bool, passed: str, failed: str, failures: list[str]) -> None:
    if condition:
        print(f"PASS {passed}")
    else:
        print(f"FAIL {failed}")
        failures.append(failed)


def main() -> int:
    failures: list[str] = []
    print(f"Checking Astronova production security at {BASE_URL.rstrip('/')}")

    health = fetch("/health")
    check(health.status == 200, "GET /health returns 200", f"GET /health returned {health.status}", failures)

    admin_list = fetch("/api/v1/admin/list-users?limit=1")
    check(
        admin_list.status == 401,
        "GET /api/v1/admin/list-users rejects missing token",
        f"GET /api/v1/admin/list-users without token returned {admin_list.status} and {admin_list.body_size} bytes",
        failures,
    )

    admin_health = fetch("/api/v1/admin/health")
    check(
        admin_health.status == 401,
        "GET /api/v1/admin/health rejects missing token",
        f"GET /api/v1/admin/health without token returned {admin_health.status} and {admin_health.body_size} bytes",
        failures,
    )

    openapi = fetch("/api/v1/openapi.yaml")
    spec_text = openapi.body.decode("utf-8", errors="replace")
    check(
        openapi.status == 200 and len(spec_text) > 1000 and "/api/v1/auth/apple" in spec_text and "paths:" in spec_text,
        "OpenAPI spec is non-empty and includes auth paths",
        f"OpenAPI spec is stale/missing: status={openapi.status}, bytes={openapi.body_size}",
        failures,
    )

    if failures:
        print(f"\n{len(failures)} production security check(s) failed.")
        return 1

    print("\nAstronova production security checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

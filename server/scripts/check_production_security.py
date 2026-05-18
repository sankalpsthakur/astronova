#!/usr/bin/env python3
"""Production security smoke checks that never print sensitive response bodies."""

from __future__ import annotations

import json
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
    headers: dict[str, str]


def fetch(
    path: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    json_body: dict | None = None,
) -> Response:
    request_headers = dict(headers or {})
    body = None
    if json_body is not None:
        body = json.dumps(json_body).encode("utf-8")
        request_headers.setdefault("Content-Type", "application/json")

    request = urllib.request.Request(
        urljoin(BASE_URL, path.lstrip("/")),
        data=body,
        headers=request_headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            body = response.read()
            return Response(response.status, len(body), body, dict(response.headers.items()))
    except urllib.error.HTTPError as error:
        body = error.read()
        return Response(error.code, len(body), body, dict(error.headers.items()))


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
        openapi.status == 200
        and len(spec_text) > 1000
        and "/api/v1/auth/apple" in spec_text
        and "identityToken" in spec_text
        and "adminTokenAuth" in spec_text
        and "paths:" in spec_text,
        "OpenAPI spec is non-empty and includes hardened auth/admin paths",
        f"OpenAPI spec is stale/missing: status={openapi.status}, bytes={openapi.body_size}",
        failures,
    )

    tokenless_apple = fetch(
        "/api/v1/auth/apple",
        method="POST",
        json_body={"userIdentifier": "prod-smoke-user"},
    )
    check(
        tokenless_apple.status == 401,
        "POST /api/v1/auth/apple rejects tokenless Apple auth",
        f"POST /api/v1/auth/apple without Apple token returned {tokenless_apple.status}",
        failures,
    )

    seed_test_user = fetch("/api/v1/seed-test-user", method="POST")
    check(
        seed_test_user.status in (401, 503),
        "POST /api/v1/seed-test-user rejects missing admin token in production",
        f"POST /api/v1/seed-test-user without admin token returned {seed_test_user.status}",
        failures,
    )

    report_status = fetch("/api/v1/reports/not-a-real-report-id/status")
    check(
        report_status.status == 401,
        "GET /api/v1/reports/{id}/status rejects missing Bearer token",
        f"GET /api/v1/reports/{{id}}/status without token returned {report_status.status}",
        failures,
    )

    subscription = fetch("/api/v1/subscription/status?userId=not-a-real-user")
    check(
        subscription.status == 401,
        "GET /api/v1/subscription/status rejects missing Bearer token",
        f"GET /api/v1/subscription/status without token returned {subscription.status}",
        failures,
    )

    cors_probe = fetch("/health", headers={"Origin": "http://localhost:8080"})
    check(
        cors_probe.headers.get("Access-Control-Allow-Origin") != "http://localhost:8080",
        "localhost CORS origin is not allowed by production",
        "localhost CORS origin is allowed by production",
        failures,
    )

    if failures:
        print(f"\n{len(failures)} production security check(s) failed.")
        return 1

    print("\nAstronova production security checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

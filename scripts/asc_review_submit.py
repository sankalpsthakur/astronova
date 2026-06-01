#!/usr/bin/env python3
"""Submit Astronova 1.0 for App Store review via App Store Connect API.

This intentionally does not try to answer App Privacy questions because Apple
serves those through the authenticated App Store Connect web/iris surface, not
the public API-key endpoint.
"""

from __future__ import annotations

import json
import os
import time
from pathlib import Path
from typing import Any

import jwt
import requests


APP_ID = os.environ.get("ASC_APP_ID", "6746982743")
VERSION_ID = os.environ.get("ASC_VERSION_ID", "1577f289-33ba-4b51-9143-d488d8020ed9")
KEY_PATH = os.environ.get("ASC_KEY_PATH", "/Users/sankalp/Downloads/AuthKey_FTUF2YD2G3.p8")
KEY_ID = os.environ.get("ASC_KEY_ID", "FTUF2YD2G3")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "c6da3eeb-1bf0-4f44-8064-76e395f4784a")
API_ROOT = "https://api.appstoreconnect.apple.com/v1"
OUT_DIR = Path("qa-results/20260523-launch")


def token() -> str:
    now = int(time.time())
    key = Path(KEY_PATH).read_text()
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )


class ASC:
    def __init__(self) -> None:
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {token()}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            }
        )

    def request(self, method: str, path: str, **kwargs: Any) -> dict[str, Any]:
        response = self.session.request(method, f"{API_ROOT}{path}", timeout=60, **kwargs)
        try:
            body = response.json()
        except ValueError:
            body = {"raw": response.text}
        return {"status": response.status_code, "body": body}

    def get(self, path: str) -> dict[str, Any]:
        return self.request("GET", path)

    def post(self, path: str, payload: dict[str, Any]) -> dict[str, Any]:
        return self.request("POST", path, data=json.dumps(payload))

    def patch(self, path: str, payload: dict[str, Any]) -> dict[str, Any]:
        return self.request("PATCH", path, data=json.dumps(payload))


def brief_errors(resp: dict[str, Any]) -> list[str]:
    errors = resp.get("body", {}).get("errors") or []
    return [
        " | ".join(str(e.get(k, "")) for k in ("status", "code", "title", "detail") if e.get(k))
        for e in errors
    ]


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    api = ASC()
    evidence: dict[str, Any] = {
        "startedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "appId": APP_ID,
        "versionId": VERSION_ID,
        "steps": [],
    }

    version = api.get(
        f"/appStoreVersions/{VERSION_ID}"
        "?include=build,appStoreReviewDetail,appStoreVersionLocalizations"
    )
    evidence["appStoreVersion"] = version

    submissions = api.get(
        f"/apps/{APP_ID}/reviewSubmissions"
        "?limit=200&include=items,appStoreVersionForReview"
        "&fields[reviewSubmissions]=platform,submittedDate,state,items,appStoreVersionForReview"
        "&fields[reviewSubmissionItems]=state,appStoreVersion"
    )
    evidence["reviewSubmissionsBefore"] = submissions

    submission_ids = [
        item["id"]
        for item in submissions.get("body", {}).get("data", [])
        if item.get("attributes", {}).get("state") == "READY_FOR_REVIEW"
    ]
    if not submission_ids:
        create = api.post(
            "/reviewSubmissions",
            {
                "data": {
                    "type": "reviewSubmissions",
                    "attributes": {"platform": "IOS"},
                    "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
                }
            },
        )
        evidence["steps"].append({"name": "create-review-submission", **create})
        if create["status"] == 201:
            submission_ids.append(create["body"]["data"]["id"])

    item_payload = {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": ""}},
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}},
            },
        }
    }

    submitted = False
    for submission_id in submission_ids:
        item_payload["data"]["relationships"]["reviewSubmission"]["data"]["id"] = submission_id
        create_item = api.post("/reviewSubmissionItems", item_payload)
        evidence["steps"].append(
            {
                "name": "create-review-submission-item",
                "submissionId": submission_id,
                **create_item,
                "errors": brief_errors(create_item),
            }
        )

        after_item = api.get(f"/reviewSubmissions/{submission_id}?include=items,appStoreVersionForReview")
        evidence["steps"].append(
            {"name": "read-review-submission-after-item", "submissionId": submission_id, **after_item}
        )

        if create_item["status"] not in (200, 201):
            continue

        submit = api.patch(
            f"/reviewSubmissions/{submission_id}",
            {
                "data": {
                    "type": "reviewSubmissions",
                    "id": submission_id,
                    "attributes": {"submitted": True},
                }
            },
        )
        evidence["steps"].append(
            {
                "name": "patch-submitted-true",
                "submissionId": submission_id,
                **submit,
                "errors": brief_errors(submit),
            }
        )
        submitted = submit["status"] == 200
        if submitted:
            break

    evidence["reviewSubmissionsAfter"] = api.get(
        f"/apps/{APP_ID}/reviewSubmissions?limit=200&include=items,appStoreVersionForReview"
    )
    evidence["finishedAt"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    evidence["submitted"] = submitted

    out = OUT_DIR / "asc-review-submit-latest.json"
    out.write_text(json.dumps(evidence, indent=2), encoding="utf-8")
    print(json.dumps({"submitted": submitted, "evidence": str(out)}, indent=2))
    for step in evidence["steps"]:
        print(step["name"], step.get("submissionId", ""), step["status"])
        for err in step.get("errors", []):
            print("  ", err)


if __name__ == "__main__":
    main()

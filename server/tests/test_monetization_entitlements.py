from __future__ import annotations

import json

import jwt
import pytest
import db as db_module
from services.report_generation_service import GeneratedReport


_LOCAL_TEST_JWS_KEY = "astronova-local-storekit-test-key-32b"


def _unsigned_storekit_jws(product_id: str, transaction_id: str, original_transaction_id: str | None = None) -> str:
    return jwt.encode(
        {
            "bundleId": "com.astronova.app",
            "productId": product_id,
            "transactionId": transaction_id,
            "originalTransactionId": original_transaction_id or transaction_id,
            "environment": "Sandbox",
        },
        key=_LOCAL_TEST_JWS_KEY,
        algorithm="HS256",
    )


def _sample_birth_data() -> dict:
    return {
        "date": "1990-01-15",
        "time": "14:30",
        "timezone": "Asia/Kolkata",
        "latitude": 19.076,
        "longitude": 72.8777,
    }


def test_entitlement_helper_uses_subscription_status(sample_user):
    assert db_module.get_premium_entitlement(sample_user["id"]) == {
        "hasPremium": False,
        "source": "subscription_status",
        "subscription": {"isActive": False},
    }

    db_module.set_subscription(sample_user["id"], True, "astronova_pro_monthly")

    entitlement = db_module.get_premium_entitlement(sample_user["id"])
    assert entitlement["hasPremium"] is True
    assert entitlement["source"] == "subscription_status"
    assert entitlement["subscription"]["productId"] == "astronova_pro_monthly"


def test_subscription_sync_activates_server_premium_entitlement(authenticated_client, sample_user, monkeypatch):
    monkeypatch.setenv("ASTRONOVA_ALLOW_UNVERIFIED_STOREKIT_JWS", "true")
    transaction_id = "2000000123456789"
    response = authenticated_client.post(
        "/api/v1/subscription/sync",
        json={
            "productId": "astronova_pro_monthly",
            "transactionId": transaction_id,
            "originalTransactionId": "2000000123456000",
            "environment": "Sandbox",
            "signedTransactionJWS": _unsigned_storekit_jws("astronova_pro_monthly", transaction_id, "2000000123456000"),
        },
    )

    assert response.status_code == 200
    data = response.get_json()
    assert data["isActive"] is True
    assert data["productId"] == "astronova_pro_monthly"
    assert data["entitlement"] == {"hasPremium": True, "source": "subscription_sync"}

    entitlement = db_module.get_premium_entitlement(sample_user["id"])
    assert entitlement["hasPremium"] is True
    assert entitlement["subscription"]["productId"] == "astronova_pro_monthly"


def test_subscription_sync_rejects_non_pro_products(authenticated_client, sample_user):
    response = authenticated_client.post(
        "/api/v1/subscription/sync",
        json={
            "productId": "detailed_report_birth_chart",
            "transactionId": "2000000999999999",
        },
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["code"] == "UNSUPPORTED_PRODUCT"
    assert db_module.get_subscription(sample_user["id"]) == {"isActive": False}


@pytest.mark.parametrize("deprecated_product_id", ["astronova_pro_yearly", "astronova_pro_annual"])
def test_subscription_sync_rejects_deprecated_pro_aliases(authenticated_client, sample_user, monkeypatch, deprecated_product_id):
    monkeypatch.setenv("ASTRONOVA_ALLOW_UNVERIFIED_STOREKIT_JWS", "true")
    transaction_id = f"2000000{deprecated_product_id[-6:]}"

    response = authenticated_client.post(
        "/api/v1/subscription/sync",
        json={
            "productId": deprecated_product_id,
            "transactionId": transaction_id,
            "originalTransactionId": transaction_id,
            "environment": "Sandbox",
            "signedTransactionJWS": _unsigned_storekit_jws(deprecated_product_id, transaction_id),
        },
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["code"] == "UNSUPPORTED_PRODUCT"
    assert db_module.get_subscription(sample_user["id"]) == {"isActive": False}


def test_subscription_sync_requires_transaction_identity(authenticated_client, sample_user):
    response = authenticated_client.post(
        "/api/v1/subscription/sync",
        json={"productId": "astronova_pro_monthly"},
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["code"] == "INVALID_PAYLOAD"
    assert db_module.get_subscription(sample_user["id"]) == {"isActive": False}


def test_subscription_sync_rejects_unsigned_transaction_identity(authenticated_client, sample_user):
    response = authenticated_client.post(
        "/api/v1/subscription/sync",
        json={
            "productId": "astronova_pro_monthly",
            "transactionId": "2000000123456789",
            "originalTransactionId": "2000000123456000",
            "environment": "Sandbox",
        },
    )

    assert response.status_code == 400
    data = response.get_json()
    assert data["code"] == "STOREKIT_TRANSACTION_UNVERIFIED"
    assert db_module.get_subscription(sample_user["id"]) == {"isActive": False}


def test_report_generation_requires_active_subscription(authenticated_client, sample_user, monkeypatch):
    def fail_generate(*_args, **_kwargs):
        raise AssertionError("report generation should not run without premium entitlement")

    monkeypatch.setattr("routes.reports._report_service.generate", fail_generate)

    response = authenticated_client.post(
        "/api/v1/reports/generate",
        json={"reportType": "birth_chart", "birthData": _sample_birth_data()},
    )

    assert response.status_code == 402
    data = response.get_json()
    assert data["error"] == "payment_required"
    assert data["code"] == "PAYMENT_REQUIRED"
    assert data["feature"] == "report_generation"
    assert data["entitlement"]["source"] == "subscription_status"
    assert data["entitlement"]["hasPremium"] is False
    assert db_module.get_user_reports(sample_user["id"]) == []


def test_report_entitlement_sync_allows_one_matching_report(authenticated_client, sample_user, monkeypatch):
    monkeypatch.setenv("ASTRONOVA_ALLOW_UNVERIFIED_STOREKIT_JWS", "true")
    transaction_id = "2000000555000001"
    sync_response = authenticated_client.post(
        "/api/v1/report-entitlements/sync",
        json={
            "productId": "report_general",
            "transactionId": transaction_id,
            "originalTransactionId": transaction_id,
            "environment": "Sandbox",
            "signedTransactionJWS": _unsigned_storekit_jws("report_general", transaction_id),
        },
    )

    assert sync_response.status_code == 200
    sync_data = sync_response.get_json()
    assert sync_data["isAvailable"] is True
    assert sync_data["reportType"] == "birth_chart"

    def fake_generate(report_type: str, birth_data: dict | None = None) -> GeneratedReport:
        return GeneratedReport(
            report_type=report_type,
            title="Purchased Birth Chart",
            summary="Individual report entitlement accepted.",
            key_insights=["Single report purchase generated on server"],
            content=json.dumps({
                "summary": "Individual report entitlement accepted.",
                "keyInsights": ["Single report purchase generated on server"],
            }),
        )

    monkeypatch.setattr("routes.reports._report_service.generate", fake_generate)

    report_response = authenticated_client.post(
        "/api/v1/reports/generate",
        json={"reportType": "birth_chart", "birthData": _sample_birth_data()},
    )

    assert report_response.status_code == 200
    report_data = report_response.get_json()
    assert report_data["status"] == "completed"
    assert report_data["title"] == "Purchased Birth Chart"
    reports = db_module.get_user_reports(sample_user["id"])
    assert len(reports) == 1

    second_response = authenticated_client.post(
        "/api/v1/reports/generate",
        json={"reportType": "birth_chart", "birthData": _sample_birth_data()},
    )
    assert second_response.status_code == 402


def test_report_generation_allows_active_subscription(authenticated_client, sample_user, monkeypatch):
    db_module.set_subscription(sample_user["id"], True, "astronova_pro_monthly")

    def fake_generate(report_type: str, birth_data: dict | None = None) -> GeneratedReport:
        payload = {
            "summary": "Premium report generated.",
            "keyInsights": ["Subscription-backed entitlement accepted"],
        }
        return GeneratedReport(
            report_type=report_type,
            title="Premium Birth Chart",
            summary=payload["summary"],
            key_insights=payload["keyInsights"],
            content=json.dumps(payload),
        )

    monkeypatch.setattr("routes.reports._report_service.generate", fake_generate)

    response = authenticated_client.post(
        "/api/v1/reports/generate",
        json={"reportType": "birth_chart", "birthData": _sample_birth_data()},
    )

    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "completed"
    assert data["title"] == "Premium Birth Chart"
    assert data["summary"] == "Premium report generated."
    reports = db_module.get_user_reports(sample_user["id"])
    assert len(reports) == 1
    assert reports[0]["type"] == "birth_chart"


def test_quick_oracle_chat_preserves_free_daily_api_contract(authenticated_client, monkeypatch):
    def fake_generate_response(message: str, user_id: str | None = None, birth_data: dict | None = None):
        return f"free reply to {message}", ["Ask about today's energy"]

    monkeypatch.setattr("routes.chat._chat_service.generate_response", fake_generate_response)

    response = authenticated_client.post(
        "/api/v1/chat",
        json={"message": "What should I focus on today?", "context": "depth=quick"},
    )

    assert response.status_code == 200
    data = response.get_json()
    assert data["reply"] == "free reply to What should I focus on today?"
    assert data["suggestedFollowUps"] == ["Ask about today's energy"]


def test_deep_oracle_chat_requires_active_subscription(authenticated_client, sample_user, monkeypatch):
    def fail_generate_response(*_args, **_kwargs):
        raise AssertionError("deep chat should not run without premium entitlement")

    monkeypatch.setattr("routes.chat._chat_service.generate_response", fail_generate_response)

    response = authenticated_client.post(
        "/api/v1/chat",
        json={"message": "Give me a deep reading.", "context": "depth=deep"},
    )

    assert response.status_code == 402
    data = response.get_json()
    assert data["error"] == "payment_required"
    assert data["feature"] == "oracle_chat_deep"
    assert data["entitlement"]["source"] == "subscription_status"
    assert data["entitlement"]["hasPremium"] is False
    assert db_module.get_user_conversations(sample_user["id"]) == []


def test_oracle_premium_flag_requires_active_subscription(authenticated_client, sample_user, monkeypatch):
    def fail_generate_response(*_args, **_kwargs):
        raise AssertionError("premium-flagged chat should not run without premium entitlement")

    monkeypatch.setattr("routes.chat._chat_service.generate_response", fail_generate_response)

    response = authenticated_client.post(
        "/api/v1/chat",
        json={"message": "Use the premium mode.", "context": "depth=quick", "requiresPremium": "true"},
    )

    assert response.status_code == 402
    data = response.get_json()
    assert data["error"] == "payment_required"
    assert data["feature"] == "oracle_chat_deep"
    assert db_module.get_user_conversations(sample_user["id"]) == []


def test_deep_oracle_chat_allows_active_subscription(authenticated_client, sample_user, monkeypatch):
    db_module.set_subscription(sample_user["id"], True, "astronova_pro_monthly")

    def fake_generate_response(message: str, user_id: str | None = None, birth_data: dict | None = None):
        return "premium deep reply", ["Explore the timing"]

    monkeypatch.setattr("routes.chat._chat_service.generate_response", fake_generate_response)

    response = authenticated_client.post(
        "/api/v1/chat",
        json={"message": "Give me a deep reading.", "context": "depth=deep"},
    )

    assert response.status_code == 200
    data = response.get_json()
    assert data["reply"] == "premium deep reply"
    assert data["suggestedFollowUps"] == ["Explore the timing"]

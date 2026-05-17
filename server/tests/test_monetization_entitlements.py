from __future__ import annotations

import json

import db as db_module
from services.report_generation_service import GeneratedReport


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

"""Focused request-correlation and request-log privacy tests."""

from __future__ import annotations

import json
from unittest.mock import patch

from flask import Flask, jsonify

from middleware import add_request_id, log_request_response


def _app() -> Flask:
    app = Flask(__name__)
    app.before_request(add_request_id)
    app.after_request(log_request_response)

    @app.post("/api/v1/chart/<chart_id>")
    def chart(chart_id: str):
        return jsonify({"ok": True, "chart_id": chart_id})

    return app


def _last_log_line(captured: str) -> dict:
    return json.loads(captured.strip().splitlines()[-1])


def test_client_request_id_is_echoed_and_used_in_structured_log(capsys):
    app = _app()
    request_id = "client-request-0001"
    forbidden = [
        "Bearer secret.jwt.value",
        "1990-01-15",
        "private birth place",
        "my private oracle question",
        "Jane Person",
    ]

    with app.test_client() as client:
        response = client.post(
            "/api/v1/chart/123?place=private-birth-place",
            headers={
                "X-Request-ID": request_id,
                "Authorization": forbidden[0],
                "User-Agent": "Astronova Jane Person iPhone OS 18_0",
            },
            json={
                "birthDate": forbidden[1],
                "birthPlace": forbidden[2],
                "text": forbidden[3],
            },
        )

    event = _last_log_line(capsys.readouterr().out)
    assert response.headers["X-Request-ID"] == request_id
    assert event["request_id"] == request_id
    assert event["event"] == "http_request"
    assert event["route"] == "/api/v1/chart/:chart_id"
    assert event["user_agent_class"] == "ios/18.0"

    serialized = json.dumps(event)
    for value in forbidden:
        assert value not in serialized
    for forbidden_field in ("authorization", "birth", "text", "query", "user_id"):
        assert forbidden_field not in serialized.lower()


def test_invalid_sensitive_request_id_is_replaced_once_and_never_logged(capsys):
    app = _app()
    generated = "0123456789abcdef0123456789abcdef"
    sensitive_id = "Bearer secret.jwt.value"

    with patch("middleware.uuid.uuid4") as uuid4:
        uuid4.return_value.hex = generated
        with app.test_client() as client:
            response = client.post(
                "/api/v1/chart/123",
                headers={"X-Request-ID": sensitive_id},
                json={"text": "private user text"},
            )

    event = _last_log_line(capsys.readouterr().out)
    uuid4.assert_called_once_with()
    assert response.headers["X-Request-ID"] == generated
    assert event["request_id"] == generated
    assert sensitive_id not in json.dumps(event)
    assert "private user text" not in json.dumps(event)

from __future__ import annotations


def test_openapi_yaml_served(client):
    resp = client.get("/api/v1/openapi.yaml")
    assert resp.status_code == 200
    assert resp.content_type.startswith("application/yaml")
    body = resp.data.decode("utf-8", errors="replace")
    assert "openapi:" in body
    assert "/api/v1/chart/generate:" in body


def test_swagger_ui_served(client):
    resp = client.get("/docs")
    assert resp.status_code == 200
    assert resp.content_type.startswith("text/html")
    body = resp.data.decode("utf-8", errors="replace")
    assert "SwaggerUIBundle" in body
    assert "/api/v1/openapi.yaml" in body


def test_swagger_ui_alias_redirects(client):
    resp = client.get("/api/v1/docs")
    assert resp.status_code in (301, 302, 307, 308)
    assert resp.headers.get("Location") == "/docs"


from __future__ import annotations


def test_openapi_yaml_served(client):
    resp = client.get("/api/v1/openapi.yaml")
    assert resp.status_code == 200
    assert resp.content_type.startswith("application/yaml")
    body = resp.data.decode("utf-8", errors="replace")
    assert "openapi:" in body
    assert "/api/v1/chart/generate:" in body
    assert "paths: {}" not in body
    assert "title: Astronova Backend API" in body


def test_openapi_spec_not_excluded_from_container_artifact():
    from pathlib import Path

    dockerignore = Path(__file__).resolve().parents[1] / ".dockerignore"
    ignored = {
        line.strip()
        for line in dockerignore.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.strip().startswith("#")
    }
    assert "openapi_spec.yaml" not in ignored


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

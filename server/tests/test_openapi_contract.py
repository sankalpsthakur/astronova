from __future__ import annotations

import re
from pathlib import Path


HTTP_METHODS = {"get", "post", "put", "delete", "patch", "options", "head"}
_FLASK_PARAM_RE = re.compile(r"<(?:[^:>]+:)?([^>]+)>")


def _parse_openapi_paths(spec_text: str) -> dict[str, set[str]]:
    """
    Parse the OpenAPI YAML as plain text to extract `paths:` entries and their methods.

    Avoids adding a YAML dependency (PyYAML) in restricted environments.
    """
    in_paths = False
    current_path: str | None = None
    methods_by_path: dict[str, set[str]] = {}

    for raw_line in spec_text.splitlines():
        line = raw_line.rstrip("\n")

        if not in_paths:
            if line.strip() == "paths:":
                in_paths = True
            continue

        # End of paths section once we hit a new top-level key.
        if line and not line.startswith(" "):
            break

        # Path entry: 2-space indent and starts with "/".
        if line.startswith("  /") and line.rstrip().endswith(":") and not line.startswith("    "):
            current_path = line.strip()[:-1]
            methods_by_path.setdefault(current_path, set())
            continue

        # Method entry under a path: exactly 4-space indent and "<method>:" key.
        if current_path and line.startswith("    ") and not line.startswith("      "):
            stripped = line.strip()
            if stripped.endswith(":"):
                key = stripped[:-1].strip().lower()
                if key in HTTP_METHODS:
                    methods_by_path[current_path].add(key.upper())

    return methods_by_path


def _normalize_flask_rule(rule: str) -> str:
    # Convert Flask-style params: /x/<id> or /x/<path:id> -> /x/{id}
    return _FLASK_PARAM_RE.sub(lambda m: "{" + m.group(1) + "}", rule)


def test_openapi_paths_exist_in_app(app):
    spec_path = Path(__file__).resolve().parents[1] / "openapi_spec.yaml"
    spec_text = spec_path.read_text(encoding="utf-8")

    spec_methods = _parse_openapi_paths(spec_text)
    assert spec_methods, "Failed to parse any OpenAPI paths"

    app_paths = {_normalize_flask_rule(r.rule) for r in app.url_map.iter_rules() if not r.rule.startswith("/static")}
    missing_paths = sorted(set(spec_methods.keys()) - app_paths)
    assert not missing_paths, f"OpenAPI spec references missing paths: {missing_paths}"


def test_openapi_methods_are_implemented(app):
    spec_path = Path(__file__).resolve().parents[1] / "openapi_spec.yaml"
    spec_text = spec_path.read_text(encoding="utf-8")
    spec_methods = _parse_openapi_paths(spec_text)

    app_methods_by_path: dict[str, set[str]] = {}
    for rule in app.url_map.iter_rules():
        if rule.rule.startswith("/static"):
            continue
        normalized = _normalize_flask_rule(rule.rule)
        app_methods_by_path.setdefault(normalized, set()).update(rule.methods or set())

    missing: list[str] = []
    for path, methods in spec_methods.items():
        implemented = app_methods_by_path.get(path, set())
        for method in methods:
            if method not in implemented:
                missing.append(f"{method} {path}")

    assert not missing, f"OpenAPI spec methods not implemented: {missing}"


def test_all_app_routes_are_documented_in_openapi(app):
    spec_path = Path(__file__).resolve().parents[1] / "openapi_spec.yaml"
    spec_text = spec_path.read_text(encoding="utf-8")
    spec_paths = set(_parse_openapi_paths(spec_text).keys())

    app_paths = {
        _normalize_flask_rule(r.rule)
        for r in app.url_map.iter_rules()
        if not r.rule.startswith("/static") and r.rule != "/favicon.ico"
    }

    missing_in_spec = sorted(app_paths - spec_paths)
    assert not missing_in_spec, f"App routes missing from OpenAPI spec: {missing_in_spec}"

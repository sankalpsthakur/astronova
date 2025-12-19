from __future__ import annotations

import json
import logging
import threading
import uuid
from datetime import datetime

from flask import Blueprint, Response, jsonify, request
from werkzeug.exceptions import BadRequest

import db
from services.pdf import render_report_pdf
from services.report_generation_service import ReportGenerationService

reports_bp = Blueprint("reports", __name__)

logger = logging.getLogger(__name__)
_report_service = ReportGenerationService()
_VALID_REPORT_DOMAINS = {"general", "love", "career", "money", "health", "family", "spiritual"}


def _generate_report_async(report_id: str, report_type: str, birth_data: dict | None, domain: str | None = None):
    """Background task to generate report content."""
    try:
        logger.info("Starting async report generation for %s (type: %s)", report_id, report_type)
        generated = _report_service.generate(report_type=report_type, birth_data=birth_data)
        content = generated.content
        if domain:
            try:
                parsed = json.loads(content)
                if isinstance(parsed, dict):
                    parsed["domain"] = domain
                    content = json.dumps(parsed, ensure_ascii=False)
            except Exception:
                pass
        db.update_report(report_id, generated.title, content, status="completed")
        logger.info("Report %s generation completed successfully", report_id)
    except Exception as exc:
        logger.error("Async report generation failed for %s: %s", report_id, exc)
        # Mark as failed so client knows to retry
        try:
            db.update_report(report_id, f"Report Generation Failed", json.dumps({"error": str(exc)}), status="failed")
        except Exception:
            pass


@reports_bp.route("", methods=["GET"])
def reports_info():
    return jsonify(
        {
            "service": "reports",
            "status": "available",
            "endpoints": {
                "POST /": "Generate a report (alias: /full, /generate)",
                "GET /user/<user_id>": "List reports for a user",
                "GET /<report_id>/pdf": "Download report PDF",
            },
        }
    )


@reports_bp.route("/user/<user_id>", methods=["GET"])
def user_reports(user_id: str):
    try:
        reports = db.get_user_reports(user_id)
    except Exception as exc:
        logger.error("Report retrieval failed: %s", exc)
        return jsonify({"error": "Unable to fetch reports right now", "code": "REPORT_QUERY_FAILED"}), 500

    # Normalize to match the iOS `DetailedReport` schema.
    normalized = []
    for report in reports:
        report_id = report.get("report_id") or report.get("reportId")
        content_raw = report.get("content")
        summary = ""
        key_insights: list[str] = []
        if isinstance(content_raw, str) and content_raw.strip():
            try:
                parsed = json.loads(content_raw)
                if isinstance(parsed, dict):
                    if isinstance(parsed.get("summary"), str):
                        summary = parsed["summary"]
                    insights = parsed.get("keyInsights")
                    if isinstance(insights, list):
                        key_insights = [str(i) for i in insights if isinstance(i, str) and i.strip()]
            except Exception:
                summary = content_raw

        if not summary:
            summary = str(content_raw or "")
        if not key_insights:
            key_insights = [
                "Your Sun sign reveals your core life purpose",
                "Moon sign reflects emotional needs",
            ]

        normalized.append(
            {
                "reportId": report_id,
                "type": report.get("type"),
                "title": report.get("title"),
                "content": content_raw,
                "summary": summary,
                "keyInsights": key_insights,
                "downloadUrl": f"/api/v1/reports/{report_id}/pdf" if report_id else None,
                "generatedAt": report.get("generated_at") or report.get("generatedAt"),
                "userId": report.get("user_id") or report.get("userId"),
                "status": report.get("status") or "completed",
            }
        )

    return jsonify(normalized)


@reports_bp.route("", methods=["POST"])
@reports_bp.route("/full", methods=["POST"])
@reports_bp.route("/generate", methods=["POST"])
def generate_report():
    try:
        payload = request.get_json(force=False, silent=False)
    except BadRequest:
        return jsonify({"error": "Request body must be valid JSON", "code": "INVALID_JSON"}), 400

    data = payload or {}
    if not isinstance(data, dict):
        return jsonify({"error": "Request body must be a JSON object", "code": "INVALID_PAYLOAD"}), 400

    birth_data_raw = data.get("birthData")
    if birth_data_raw is not None and not isinstance(birth_data_raw, dict):
        return jsonify({"error": "birthData must be a JSON object when provided", "code": "INVALID_PAYLOAD"}), 400
    report_type = data.get("reportType", "birth_chart")
    user_id = data.get("userId") or request.headers.get("X-User-Id")
    # Default to synchronous so API callers get an immediate, stable response.
    # Async mode is opt-in via {"async": true}.
    async_mode = bool(data.get("async", False))
    domain_raw = data.get("domain") or data.get("category")
    domain = domain_raw.strip().lower() if isinstance(domain_raw, str) else None
    if domain and len(domain) > 24:
        domain = None
    if domain and domain not in _VALID_REPORT_DOMAINS:
        domain = None

    report_id = str(uuid.uuid4())
    report_title = _get_report_title(report_type)

    if async_mode:
        # Insert placeholder report with "processing" status
        try:
            db.insert_report(
                report_id,
                user_id,
                report_type,
                report_title,
                json.dumps(
                    {
                        "status": "generating",
                        "message": "Your cosmic report is being prepared...",
                        "reportType": report_type,
                        "title": report_title,
                        "domain": domain,
                    },
                    ensure_ascii=False,
                ),
                status="processing",
            )
        except Exception as exc:
            logger.error("Report placeholder creation failed: %s", exc)
            return jsonify({"error": "Unable to start report generation", "code": "REPORT_CREATION_FAILED"}), 500

        # Start background generation
        thread = threading.Thread(
            target=_generate_report_async,
            args=(report_id, report_type, birth_data_raw, domain),
            daemon=True,
        )
        thread.start()

        response = {
            "reportId": report_id,
            "type": report_type,
            "title": report_title,
            "summary": "Your report is being generated. This may take a few minutes.",
            "keyInsights": ["Generation in progress..."],
            "downloadUrl": f"/api/v1/reports/{report_id}/pdf",
            "generatedAt": datetime.utcnow().isoformat() + "Z",
            "status": "processing",
        }
    else:
        # Synchronous generation (for quick reports)
        generated = _report_service.generate(report_type=report_type, birth_data=birth_data_raw)
        content = generated.content
        if domain:
            try:
                parsed = json.loads(content)
                if isinstance(parsed, dict):
                    parsed["domain"] = domain
                    content = json.dumps(parsed, ensure_ascii=False)
            except Exception:
                pass
        try:
            db.insert_report(report_id, user_id, report_type, generated.title, content)
        except Exception as exc:
            logger.error("Report persistence failed: %s", exc)
            return jsonify({"error": "Unable to save report at this time", "code": "REPORT_PERSISTENCE_FAILED"}), 500

        response = {
            "reportId": report_id,
            "type": report_type,
            "title": generated.title,
            "summary": generated.summary,
            "keyInsights": generated.key_insights,
            "downloadUrl": f"/api/v1/reports/{report_id}/pdf",
            "generatedAt": datetime.utcnow().isoformat() + "Z",
            "status": "completed",
        }

    return jsonify(response)


def _get_report_title(report_type: str) -> str:
    """Get a user-friendly title for a report type."""
    titles = {
        "birth_chart": "Your Birth Chart Analysis",
        "love_forecast": "Love & Relationship Forecast",
        "career_forecast": "Career & Professional Guidance",
        "year_ahead": "Your Year Ahead Forecast",
        "transit_report": "Current Transit Analysis",
    }
    return titles.get(report_type, f"{report_type.replace('_', ' ').title()} Report")


@reports_bp.route("/<report_id>/status", methods=["GET"])
def get_report_status(report_id: str):
    """Get the current status of a report."""
    report = db.get_report(report_id)
    if not report:
        return jsonify({"error": "Report not found", "code": "REPORT_NOT_FOUND"}), 404

    status = report.get("status", "completed")

    # Parse content for summary if completed
    summary = ""
    key_insights = []
    if status == "completed":
        content_raw = report.get("content")
        if isinstance(content_raw, str) and content_raw.strip():
            try:
                parsed = json.loads(content_raw)
                if isinstance(parsed, dict):
                    summary = parsed.get("summary", "")
                    insights = parsed.get("keyInsights", [])
                    if isinstance(insights, list):
                        key_insights = [str(i) for i in insights if isinstance(i, str)]
            except Exception:
                summary = content_raw[:200] if len(content_raw) > 200 else content_raw

    return jsonify({
        "reportId": report_id,
        "status": status,
        "title": report.get("title"),
        "type": report.get("type"),
        "summary": summary or "Report is ready.",
        "keyInsights": key_insights or [],
        "downloadUrl": f"/api/v1/reports/{report_id}/pdf" if status == "completed" else None,
        "generatedAt": report.get("generated_at"),
    })


@reports_bp.route("/<report_id>/pdf", methods=["GET"])
def get_pdf(report_id: str):
    report = None
    try:
        report = db.get_report(report_id)
    except Exception:
        report = None

    # The report generator may run asynchronously. To keep the PDF response
    # stable (and avoid returning a "processing" placeholder), wait briefly
    # for the report to complete if it's in-flight.
    if report and report.get("status") in {"processing", "generating"}:
        import time

        deadline = time.monotonic() + 2.0
        while time.monotonic() < deadline:
            latest = None
            try:
                latest = db.get_report(report_id)
            except Exception:
                latest = None
            if not latest:
                break
            report = latest
            if report.get("status") in {"completed", "failed"}:
                break
            time.sleep(0.05)

    domain = request.args.get("domain")
    if isinstance(domain, str):
        domain = domain.strip().lower()
    if domain and domain not in _VALID_REPORT_DOMAINS:
        domain = None
    payload = render_report_pdf(report_id, report, domain=domain)
    resp = Response(payload, mimetype="application/pdf")
    resp.headers["Content-Disposition"] = f'inline; filename="report-{report_id}.pdf"'
    return resp

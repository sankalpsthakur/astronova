from __future__ import annotations

from flask import Blueprint, jsonify, request, Response
import uuid

from db import init_db, insert_report, get_user_reports

reports_bp = Blueprint('reports', __name__)


@reports_bp.before_app_first_request
def _ensure_db():
    init_db()


@reports_bp.route('/user/<user_id>', methods=['GET'])
def user_reports(user_id: str):
    reports = get_user_reports(user_id)
    return jsonify(reports)


@reports_bp.route('', methods=['POST'])
@reports_bp.route('/full', methods=['POST'])
@reports_bp.route('/generate', methods=['POST'])
def generate_report():
    data = request.get_json(silent=True) or {}
    birth_data = data.get('birthData', {})
    report_type = data.get('reportType', 'birth_chart')
    user_id = data.get('userId')

    # Create dummy content
    title = {
        'birth_chart': 'Complete Birth Chart Reading',
        'love_forecast': 'Love Forecast',
        'career_forecast': 'Career Forecast',
        'year_ahead': 'Year Ahead Overview',
    }.get(report_type, 'Astrological Report')

    content = f"Personalized {report_type.replace('_', ' ')} based on provided birth data."
    report_id = str(uuid.uuid4())
    insert_report(report_id, user_id, report_type, title, content)

    response = {
        'reportId': report_id,
        'type': report_type,
        'title': title,
        'summary': content,
        'keyInsights': [
            'Your Sun sign reveals your core life purpose',
            'Moon sign reflects emotional needs',
        ],
        'downloadUrl': f"/api/v1/reports/{report_id}/pdf",
        'generatedAt': None,
        'status': 'completed',
    }
    return jsonify(response)


@reports_bp.route('/<report_id>/pdf', methods=['GET'])
def get_pdf(report_id: str):
    # Return a minimal PDF-like payload; clients expect bytes
    payload = b"%PDF-1.4\n% Minimal PDF placeholder for report " + report_id.encode() + b"\n"
    return Response(payload, mimetype='application/pdf')

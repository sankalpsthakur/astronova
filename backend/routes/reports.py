from flask import Blueprint, jsonify, request
from utils.validators import validate_request
from models.schemas import ReportRequest, DetailedReportRequest
from services.report_service import ReportService
from services.detailed_reports_service import DetailedReportsService
import base64
import uuid
from datetime import datetime

reports_bp = Blueprint('reports', __name__)
report_service = ReportService()
detailed_reports_service = DetailedReportsService()

@reports_bp.route('/generate', methods=['POST'])
@validate_request(ReportRequest)
def generate(data: ReportRequest):
    pdf_bytes = report_service.generate_pdf(data.title, data.content)
    encoded = base64.b64encode(pdf_bytes).decode()
    return jsonify({'pdf': encoded})

@reports_bp.route('/full', methods=['POST'])
@validate_request(DetailedReportRequest)
def generate_detailed_report(data: DetailedReportRequest):
    """Generate comprehensive astrological report"""
    try:
        # Generate unique report ID
        report_id = str(uuid.uuid4())
        
        # Generate the detailed report based on type
        report_data = detailed_reports_service.generate_detailed_report(
            birth_data=data.birthData,
            report_type=data.reportType,
            options=data.options or {},
            user_id=data.userId
        )
        
        # Store report for retrieval
        report_record = {
            'reportId': report_id,
            'type': data.reportType,
            'title': report_data['title'],
            'content': report_data['content'],
            'summary': report_data.get('summary', ''),
            'keyInsights': report_data.get('keyInsights', []),
            'downloadUrl': f"/api/v1/reports/{report_id}/download",
            'generatedAt': datetime.utcnow().isoformat(),
            'userId': data.userId,
            'status': 'completed'
        }
        
        # TODO: Store in database/cache
        detailed_reports_service.store_report(report_id, report_record)
        
        return jsonify({
            'reportId': report_id,
            'type': data.reportType,
            'title': report_data['title'],
            'summary': report_data.get('summary', ''),
            'keyInsights': report_data.get('keyInsights', []),
            'downloadUrl': f"/api/v1/reports/{report_id}/download",
            'generatedAt': report_record['generatedAt'],
            'status': 'completed'
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@reports_bp.route('/<report_id>', methods=['GET'])
def get_report(report_id: str):
    """Retrieve generated report"""
    try:
        report = detailed_reports_service.get_report(report_id)
        if not report:
            return jsonify({'error': 'Report not found'}), 404
            
        return jsonify(report)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@reports_bp.route('/<report_id>/download', methods=['GET'])
def download_report(report_id: str):
    """Download report as PDF"""
    try:
        report = detailed_reports_service.get_report(report_id)
        if not report:
            return jsonify({'error': 'Report not found'}), 404
            
        # Generate PDF
        pdf_bytes = detailed_reports_service.generate_pdf_report(report)
        encoded = base64.b64encode(pdf_bytes).decode()
        
        return jsonify({
            'pdf': encoded,
            'filename': f"{report['type']}_{report_id}.pdf"
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@reports_bp.route('/user/<user_id>', methods=['GET'])
def get_user_reports(user_id: str):
    """Get all reports for a user"""
    try:
        reports = detailed_reports_service.get_user_reports(user_id)
        return jsonify({'reports': reports})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

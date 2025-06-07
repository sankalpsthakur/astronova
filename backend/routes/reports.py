from flask import Blueprint, jsonify
from utils.validators import validate_request
from models.schemas import ReportRequest
from services.report_service import ReportService
import base64

reports_bp = Blueprint('reports', __name__)
report_service = ReportService()

@reports_bp.route('/generate', methods=['POST'])
@validate_request(ReportRequest)
def generate(data: ReportRequest):
    pdf_bytes = report_service.generate_pdf(data.title, data.content)
    encoded = base64.b64encode(pdf_bytes).decode()
    return jsonify({'pdf': encoded})

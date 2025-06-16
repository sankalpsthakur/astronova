from fastapi import APIRouter, HTTPException, Path, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from models.schemas import ReportRequest, DetailedReportRequest
from services.report_service import ReportService
from services.detailed_reports_service import DetailedReportsService
import base64
import uuid
from datetime import datetime

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)
report_service = ReportService()
detailed_reports_service = DetailedReportsService()


@router.post('/full')
@limiter.limit("10/hour")
async def generate_detailed_report(request: Request, data: DetailedReportRequest):
    """Generate comprehensive astrological report"""
    try:
        # Generate unique report ID
        report_id = str(uuid.uuid4())
        
        # Convert birth data to dict format
        birth_data_dict = {
            'date': data.birthData.date,
            'time': data.birthData.time,
            'timezone': data.birthData.timezone,
            'latitude': data.birthData.latitude,
            'longitude': data.birthData.longitude
        }
        
        # Generate the detailed report based on type
        report_data = detailed_reports_service.generate_detailed_report(
            birth_data=birth_data_dict,
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
        
        return {
            'reportId': report_id,
            'type': data.reportType,
            'title': report_data['title'],
            'summary': report_data.get('summary', ''),
            'keyInsights': report_data.get('keyInsights', []),
            'downloadUrl': f"/api/v1/reports/{report_id}/download",
            'generatedAt': report_record['generatedAt'],
            'status': 'completed'
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/{report_id}')
@limiter.limit("100/hour")
async def get_report(request: Request, report_id: str = Path(..., description="Report ID")):
    """Retrieve generated report"""
    try:
        report = detailed_reports_service.get_report(report_id)
        if not report:
            raise HTTPException(status_code=404, detail='Report not found')
            
        return report
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/{report_id}/download')
@limiter.limit("50/hour")
async def download_report(request: Request, report_id: str = Path(..., description="Report ID")):
    """Download report as PDF"""
    try:
        report = detailed_reports_service.get_report(report_id)
        if not report:
            raise HTTPException(status_code=404, detail='Report not found')
            
        # Generate PDF
        pdf_bytes = detailed_reports_service.generate_pdf_report(report)
        encoded = base64.b64encode(pdf_bytes).decode()
        
        return {
            'pdf': encoded,
            'filename': f"{report['type']}_{report_id}.pdf"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/user/{user_id}')
@limiter.limit("100/hour")
async def get_user_reports(request: Request, user_id: str = Path(..., description="User ID")):
    """Get all reports for a user"""
    try:
        reports = detailed_reports_service.get_user_reports(user_id)
        return {'reports': reports}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
from flask import Blueprint, jsonify
from utils.validators import validate_request
from models.schemas import ChartRequest

chart_bp = Blueprint('chart', __name__)

@chart_bp.route('/generate', methods=['POST'])
@validate_request(ChartRequest)
def generate(data: ChartRequest):
    try:
        import uuid
        chart_id = str(uuid.uuid4())
        return jsonify({
            'chartId': chart_id, 
            'type': data.chartType,
            'status': 'generated',
            'mock': True
        })
    except Exception as e:
        return jsonify({'error': 'Chart generation failed'}), 500

@chart_bp.route('/aspects', methods=['POST'])
@validate_request(ChartRequest)
def aspects(data: ChartRequest):
    try:
        return jsonify({'aspects': []})
    except Exception as e:
        return jsonify({'error': 'Aspect calculation failed'}), 500

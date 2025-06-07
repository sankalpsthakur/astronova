from flask import Blueprint, jsonify
from utils.validators import validate_request
from models.schemas import ChartRequest

chart_bp = Blueprint('chart', __name__)

@chart_bp.route('/generate', methods=['POST'])
@validate_request(ChartRequest)
def generate(data: ChartRequest):
    return jsonify({'chartId': '1', 'type': data.chartType})

@chart_bp.route('/aspects', methods=['POST'])
@validate_request(ChartRequest)
def aspects(data: ChartRequest):
    return jsonify({'aspects': []})

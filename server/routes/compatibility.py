from __future__ import annotations

from flask import Blueprint, jsonify, request

compat_bp = Blueprint('compatibility', __name__)


@compat_bp.route('', methods=['POST'])
def compatibility():
    # Minimal: return a plausible structure with dummy scores
    data = request.get_json(silent=True) or {}
    return jsonify({
        'overallScore': 75,
        'vedicScore': 28,
        'chineseScore': 80,
        'synastryAspects': [],
        'userChart': {},
        'partnerChart': {}
    })

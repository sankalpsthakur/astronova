from __future__ import annotations

from flask import Blueprint, jsonify
from db import init_db, get_content_management

content_bp = Blueprint('content', __name__)


@content_bp.route('', methods=['GET'])
def content_info():
    return jsonify({
        'service': 'content',
        'status': 'available',
        'endpoints': {
            'GET /management': 'Get quick questions and insights'
        }
    })


@content_bp.route('/management', methods=['GET'])
def content_management():
    # Ensure DB is initialized and return DB-backed content
    init_db()
    data = get_content_management()
    return jsonify(data)

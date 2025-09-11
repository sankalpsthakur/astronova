from __future__ import annotations

from flask import Blueprint, jsonify, request
from datetime import datetime, timedelta
import uuid

from db import init_db, upsert_user

auth_bp = Blueprint('auth', __name__)


def _fake_jwt() -> str:
    # Minimal dev token
    return "demo-token"


@auth_bp.before_app_first_request
def _ensure_db():
    init_db()


@auth_bp.route('/apple', methods=['POST'])
def apple_auth():
    data = request.get_json(silent=True) or {}
    user_identifier = data.get('userIdentifier') or str(uuid.uuid4())
    email = data.get('email')
    first_name = data.get('firstName')
    last_name = data.get('lastName')
    full_name = (f"{first_name or ''} {last_name or ''}").strip() or (email or "User")

    upsert_user(user_identifier, email, first_name, last_name, full_name)

    resp = {
        'jwtToken': _fake_jwt(),
        'user': {
            'id': user_identifier,
            'email': email,
            'firstName': first_name,
            'lastName': last_name,
            'fullName': full_name,
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat(),
        },
        'expiresAt': (datetime.utcnow() + timedelta(days=30)).isoformat(),
    }
    return jsonify(resp)


@auth_bp.route('/validate', methods=['GET'])
def validate():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    return jsonify({'valid': token == _fake_jwt()})


@auth_bp.route('/refresh', methods=['POST'])
def refresh():
    token = _fake_jwt()
    resp = {
        'jwtToken': token,
        'user': {
            'id': 'demo-user',
            'email': None,
            'firstName': None,
            'lastName': None,
            'fullName': 'Demo User',
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat(),
        },
        'expiresAt': (datetime.utcnow() + timedelta(days=30)).isoformat(),
    }
    return jsonify(resp)


@auth_bp.route('/logout', methods=['POST'])
def logout():
    return jsonify({'status': 'ok'})


@auth_bp.route('/delete-account', methods=['DELETE'])
def delete_account():
    # No-op in minimal build
    return jsonify({'status': 'ok'})

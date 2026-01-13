"""
Admin endpoints for internal management.
SECURITY: These endpoints should be protected in production with proper authentication.
"""

import logging
from datetime import datetime
from flask import Blueprint, jsonify, request
from db import get_connection

logger = logging.getLogger(__name__)

admin_bp = Blueprint("admin", __name__)


@admin_bp.route("/grant-pro", methods=["POST"])
def grant_pro():
    """
    Grant Pro subscription to a user by email or user ID.

    Request body:
    {
        "email": "user@example.com"  // OR
        "userId": "user-id-here"
    }

    Response:
    {
        "success": true,
        "userId": "...",
        "email": "...",
        "subscription": {
            "isActive": true,
            "productId": "pro.annual"
        }
    }
    """
    data = request.get_json() or {}
    email = data.get("email")
    user_id = data.get("userId")

    if not email and not user_id:
        return jsonify({"error": "email or userId is required"}), 400

    conn = get_connection()
    cur = conn.cursor()

    # Find user by email or userId
    if email:
        cur.execute("SELECT id, email, full_name FROM users WHERE email = ?", (email,))
    else:
        cur.execute("SELECT id, email, full_name FROM users WHERE id = ?", (user_id,))

    user = cur.fetchone()

    if not user:
        conn.close()
        return jsonify({
            "error": "User not found",
            "email": email,
            "userId": user_id,
            "message": "User must sign in at least once before granting Pro access"
        }), 404

    user_id = user["id"]
    full_name = user["full_name"] or "User"

    # Update or insert subscription
    now = datetime.utcnow().isoformat()

    cur.execute("SELECT user_id FROM subscription_status WHERE user_id = ?", (user_id,))
    existing = cur.fetchone()

    if existing:
        cur.execute("""
            UPDATE subscription_status
            SET is_active = 1,
                product_id = 'pro.annual',
                updated_at = ?
            WHERE user_id = ?
        """, (now, user_id))
        action = "updated"
    else:
        cur.execute("""
            INSERT INTO subscription_status (user_id, is_active, product_id, updated_at)
            VALUES (?, 1, 'pro.annual', ?)
        """, (user_id, now))
        action = "created"

    conn.commit()

    # Verify
    cur.execute("SELECT is_active, product_id FROM subscription_status WHERE user_id = ?", (user_id,))
    sub = cur.fetchone()

    conn.close()

    logger.info(f"Pro access granted to {email} (user_id: {user_id})")

    return jsonify({
        "success": True,
        "action": action,
        "userId": user_id,
        "email": email,
        "fullName": full_name,
        "subscription": {
            "isActive": bool(sub["is_active"]) if sub else False,
            "productId": sub["product_id"] if sub else None
        }
    }), 200


@admin_bp.route("/list-users", methods=["GET"])
def list_users():
    """
    List all users in the system.

    Query params:
    - limit: Maximum number of users to return (default 50)
    - offset: Number of users to skip (default 0)

    Response:
    {
        "users": [
            {
                "id": "...",
                "email": "...",
                "fullName": "...",
                "subscription": {
                    "isActive": true,
                    "productId": "pro.annual"
                },
                "createdAt": "..."
            }
        ],
        "total": 123
    }
    """
    limit = min(int(request.args.get("limit", 50)), 200)
    offset = int(request.args.get("offset", 0))

    conn = get_connection()
    cur = conn.cursor()

    # Get total count
    cur.execute("SELECT COUNT(*) as count FROM users")
    total = cur.fetchone()["count"]

    # Get users with subscription info
    cur.execute("""
        SELECT
            u.id,
            u.email,
            u.full_name,
            u.created_at,
            s.is_active,
            s.product_id
        FROM users u
        LEFT JOIN subscription_status s ON u.id = s.user_id
        ORDER BY u.created_at DESC
        LIMIT ? OFFSET ?
    """, (limit, offset))

    users = []
    for row in cur.fetchall():
        users.append({
            "id": row["id"],
            "email": row["email"],
            "fullName": row["full_name"],
            "subscription": {
                "isActive": bool(row["is_active"]) if row["is_active"] is not None else False,
                "productId": row["product_id"]
            },
            "createdAt": row["created_at"]
        })

    conn.close()

    return jsonify({
        "users": users,
        "total": total,
        "limit": limit,
        "offset": offset
    }), 200


@admin_bp.route("/health", methods=["GET"])
def admin_health():
    """Admin endpoints health check."""
    return jsonify({
        "status": "ok",
        "endpoints": {
            "POST /grant-pro": "Grant Pro subscription to user by email",
            "GET /list-users": "List all users with subscription info"
        }
    })

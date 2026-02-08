"""
Temple Routes - Pooja Booking and Pandit Management

Endpoints for:
- Listing available poojas and pandits
- Booking poojas with scheduling
- Managing pandit enrollment
- Session link generation
"""

from __future__ import annotations

import json
import logging
import re
import uuid
from datetime import datetime, timedelta, timezone
from flask import Blueprint, jsonify, request
from flask_babel import gettext as _

from db import get_connection

logger = logging.getLogger(__name__)
temple_bp = Blueprint("temple", __name__)


def get_base_url() -> str:
    """Get base URL for session links (environment-aware)"""
    import os
    # Check if we're in production (Render sets PORT env var)
    port = os.environ.get("PORT", "8080")

    # If running on default port 8080 locally, use localhost
    if port == "8080":
        return "http://127.0.0.1:8080"

    # Production: use onrender.com domain
    return "https://astronova.onrender.com"


# =============================================================================
# Contact Detail Filtering Service
# =============================================================================

CONTACT_PATTERNS = [
    # Phone numbers (Indian and international)
    r"\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}\b",
    # Email addresses
    r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",
    # WhatsApp mentions
    r"\b(?:whatsapp|wa\.me|whats\s*app)\b",
    # Telegram mentions
    r"\b(?:telegram|t\.me|tg)\b",
    # Instagram handles
    r"\b(?:instagram|insta|ig)\s*[:\-]?\s*@?\w+\b",
    # Generic social media handles
    r"@[A-Za-z0-9_]{3,}",
    # URLs with common domains
    r"https?://[^\s]+",
    # Spaced out phone numbers (1 2 3 4 5 6 7 8 9 0)
    r"\b\d(?:\s\d){9,}\b",
    # Phone written as words
    r"\b(?:nine|zero|one|two|three|four|five|six|seven|eight)(?:\s+(?:nine|zero|one|two|three|four|five|six|seven|eight)){6,}\b",
]

COMPILED_PATTERNS = [re.compile(p, re.IGNORECASE) for p in CONTACT_PATTERNS]


def filter_contact_details(
    message: str,
    context_type: str,
    context_id: str,
    sender_type: str,
    sender_id: str,
) -> tuple[str, list[str]]:
    """
    Filter contact details from messages in chats and meets.
    Returns (filtered_message, list_of_matched_patterns).
    """
    if not message:
        return message, []

    matched_patterns = []
    filtered = message

    for i, pattern in enumerate(COMPILED_PATTERNS):
        matches = pattern.findall(filtered)
        if matches:
            matched_patterns.extend(matches)
            filtered = pattern.sub("[contact removed]", filtered)

    # Log if any patterns were matched
    if matched_patterns:
        _log_contact_filter(
            context_type=context_type,
            context_id=context_id,
            sender_type=sender_type,
            sender_id=sender_id,
            original_message=message,
            filtered_message=filtered,
            patterns_matched=matched_patterns,
        )

    return filtered, matched_patterns


def _log_contact_filter(
    context_type: str,
    context_id: str,
    sender_type: str,
    sender_id: str,
    original_message: str,
    filtered_message: str,
    patterns_matched: list[str],
) -> None:
    """Log contact filter activity for monitoring."""
    try:
        conn = get_connection()
        cur = conn.cursor()
        now = datetime.utcnow().isoformat()
        log_id = str(uuid.uuid4())

        cur.execute("""
            INSERT INTO contact_filter_logs
            (id, context_type, context_id, sender_type, sender_id,
             original_message, filtered_message, patterns_matched, action_taken, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            log_id,
            context_type,
            context_id,
            sender_type,
            sender_id,
            original_message[:500],  # Truncate for storage
            filtered_message[:500],
            json.dumps(patterns_matched[:10]),  # Limit matches stored
            "filtered",
            now,
        ))
        conn.commit()
        conn.close()
    except Exception as e:
        logger.error(f"Failed to log contact filter: {e}")


# =============================================================================
# Pooja Type Endpoints
# =============================================================================


@temple_bp.route("/poojas", methods=["GET"])
def list_pooja_types():
    """
    GET /api/v1/temple/poojas

    List all available pooja types.
    """
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, name, description, deity, duration_minutes, base_price,
               icon_name, benefits, ingredients, sort_order
        FROM pooja_types
        WHERE is_active = 1
        ORDER BY sort_order ASC
    """)

    poojas = []
    for row in cur.fetchall():
        poojas.append({
            "id": row["id"],
            "name": row["name"],
            "description": row["description"],
            "deity": row["deity"],
            "durationMinutes": row["duration_minutes"],
            "basePrice": row["base_price"],
            "iconName": row["icon_name"],
            "benefits": json.loads(row["benefits"]) if row["benefits"] else [],
            "ingredients": json.loads(row["ingredients"]) if row["ingredients"] else [],
        })

    conn.close()
    return jsonify({"poojas": poojas})


@temple_bp.route("/poojas/<pooja_id>", methods=["GET"])
def get_pooja_type(pooja_id: str):
    """
    GET /api/v1/temple/poojas/<pooja_id>

    Get details of a specific pooja type.
    """
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, name, description, deity, duration_minutes, base_price,
               icon_name, benefits, ingredients, mantras
        FROM pooja_types
        WHERE id = ? AND is_active = 1
    """, (pooja_id,))

    row = cur.fetchone()
    conn.close()

    if not row:
        return jsonify({"error": _("Pooja not found")}), 404

    return jsonify({
        "id": row["id"],
        "name": row["name"],
        "description": row["description"],
        "deity": row["deity"],
        "durationMinutes": row["duration_minutes"],
        "basePrice": row["base_price"],
        "iconName": row["icon_name"],
        "benefits": json.loads(row["benefits"]) if row["benefits"] else [],
        "ingredients": json.loads(row["ingredients"]) if row["ingredients"] else [],
        "mantras": json.loads(row["mantras"]) if row["mantras"] else [],
    })


# =============================================================================
# Pandit Endpoints
# =============================================================================


@temple_bp.route("/pandits", methods=["GET"])
def list_pandits():
    """
    GET /api/v1/temple/pandits

    List all available pandits with optional filters.
    Query params:
    - specialization: Filter by specialization
    - language: Filter by language
    - available: Filter by availability (true/false)
    """
    specialization = request.args.get("specialization")
    language = request.args.get("language")
    available_only = request.args.get("available", "true").lower() == "true"

    conn = get_connection()
    cur = conn.cursor()

    query = """
        SELECT id, name, specializations, languages, experience_years,
               rating, review_count, price_per_session, avatar_url, bio,
               is_verified, is_available
        FROM pandits
        WHERE is_verified = 1
    """
    params = []

    if available_only:
        query += " AND is_available = 1"

    query += " ORDER BY rating DESC, review_count DESC"

    cur.execute(query, params)

    pandits = []
    for row in cur.fetchall():
        specializations = json.loads(row["specializations"]) if row["specializations"] else []
        languages = json.loads(row["languages"]) if row["languages"] else []

        # Apply filters in Python for flexibility
        if specialization and specialization not in specializations:
            continue
        if language and language not in languages:
            continue

        pandits.append({
            "id": row["id"],
            "name": row["name"],
            "specializations": specializations,
            "languages": languages,
            "experienceYears": row["experience_years"],
            "rating": row["rating"],
            "reviewCount": row["review_count"],
            "pricePerSession": row["price_per_session"],
            "avatarUrl": row["avatar_url"],
            "bio": row["bio"],
            "isVerified": bool(row["is_verified"]),
            "isAvailable": bool(row["is_available"]),
        })

    conn.close()
    logger.info(
        "Temple list_pandits available_only=%s specialization=%s language=%s count=%d",
        available_only,
        specialization,
        language,
        len(pandits),
    )
    return jsonify({"pandits": pandits})


@temple_bp.route("/pandits/<pandit_id>", methods=["GET"])
def get_pandit(pandit_id: str):
    """
    GET /api/v1/temple/pandits/<pandit_id>

    Get details of a specific pandit.
    """
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, name, specializations, languages, experience_years,
               rating, review_count, price_per_session, avatar_url, bio,
               is_verified, is_available
        FROM pandits
        WHERE id = ? AND is_verified = 1
    """, (pandit_id,))

    row = cur.fetchone()
    conn.close()

    if not row:
        return jsonify({"error": _("Pandit not found")}), 404

    return jsonify({
        "id": row["id"],
        "name": row["name"],
        "specializations": json.loads(row["specializations"]) if row["specializations"] else [],
        "languages": json.loads(row["languages"]) if row["languages"] else [],
        "experienceYears": row["experience_years"],
        "rating": row["rating"],
        "reviewCount": row["review_count"],
        "pricePerSession": row["price_per_session"],
        "avatarUrl": row["avatar_url"],
        "bio": row["bio"],
        "isVerified": bool(row["is_verified"]),
        "isAvailable": bool(row["is_available"]),
    })


@temple_bp.route("/pandits/<pandit_id>/availability", methods=["GET"])
def get_pandit_availability(pandit_id: str):
    """
    GET /api/v1/temple/pandits/<pandit_id>/availability

    Get available slots for a pandit.
    Query params:
    - date: Specific date (YYYY-MM-DD), defaults to next 7 days
    """
    date_str = request.args.get("date")

    conn = get_connection()
    cur = conn.cursor()

    # Get pandit's general availability
    cur.execute("""
        SELECT day_of_week, start_time, end_time
        FROM pandit_availability
        WHERE pandit_id = ? AND is_active = 1
    """, (pandit_id,))

    availability_rows = cur.fetchall()

    # Get existing bookings to exclude
    if date_str:
        start_date = date_str
        end_date = date_str
    else:
        start_date = datetime.utcnow().strftime("%Y-%m-%d")
        end_date = (datetime.utcnow() + timedelta(days=7)).strftime("%Y-%m-%d")

    cur.execute("""
        SELECT scheduled_date, scheduled_time
        FROM pooja_bookings
        WHERE pandit_id = ?
          AND scheduled_date BETWEEN ? AND ?
          AND status NOT IN ('cancelled', 'completed')
    """, (pandit_id, start_date, end_date))

    booked_slots = {(row["scheduled_date"], row["scheduled_time"]) for row in cur.fetchall()}
    conn.close()

    # Generate available slots
    slots = []
    current = datetime.strptime(start_date, "%Y-%m-%d")
    end = datetime.strptime(end_date, "%Y-%m-%d")

    while current <= end:
        day_of_week = current.weekday()  # 0 = Monday
        for avail in availability_rows:
            if avail["day_of_week"] == day_of_week:
                # Generate hourly slots
                start_hour = int(avail["start_time"].split(":")[0])
                end_hour = int(avail["end_time"].split(":")[0])

                for hour in range(start_hour, end_hour):
                    time_str = f"{hour:02d}:00"
                    date_str = current.strftime("%Y-%m-%d")

                    if (date_str, time_str) not in booked_slots:
                        slots.append({
                            "date": date_str,
                            "time": time_str,
                            "available": True,
                        })

        current += timedelta(days=1)

    logger.info(
        "Temple pandit_availability pandit_id=%s date_range=%s..%s slots=%d booked=%d",
        pandit_id,
        start_date,
        end_date,
        len(slots),
        len(booked_slots),
    )
    return jsonify({"slots": slots})


# =============================================================================
# Booking Endpoints
# =============================================================================


@temple_bp.route("/bookings", methods=["POST"])
def create_booking():
    """
    POST /api/v1/temple/bookings

    Create a new pooja booking.
    Body:
    {
        "poojaTypeId": "pooja_ganesh",
        "panditId": "pandit_001" (optional, auto-assign if not provided),
        "scheduledDate": "2025-01-15",
        "scheduledTime": "10:00",
        "timezone": "Asia/Kolkata",
        "sankalpName": "John Doe",
        "sankalpGotra": "Kashyap",
        "sankalpNakshatra": "Rohini",
        "specialRequests": "Please include..."
    }
    """
    user_id = request.headers.get("X-User-Id")
    if not user_id:
        return jsonify({"error": _("Authentication required")}), 401

    data = request.get_json() or {}

    pooja_type_id = data.get("poojaTypeId")
    if not pooja_type_id:
        return jsonify({"error": _("poojaTypeId is required")}), 400

    scheduled_date = data.get("scheduledDate")
    scheduled_time = data.get("scheduledTime")
    if not scheduled_date or not scheduled_time:
        return jsonify({"error": _("scheduledDate and scheduledTime are required")}), 400

    requested_pandit_id = data.get("panditId")
    pandit_id = requested_pandit_id

    conn = get_connection()
    cur = conn.cursor()

    # Verify pooja type exists
    cur.execute("SELECT base_price FROM pooja_types WHERE id = ? AND is_active = 1", (pooja_type_id,))
    pooja_row = cur.fetchone()
    if not pooja_row:
        conn.close()
        return jsonify({"error": _("Invalid pooja type")}), 400

    # Auto-assign pandit if not provided
    if not pandit_id:
        cur.execute("""
            SELECT id FROM pandits
            WHERE is_verified = 1 AND is_available = 1
            ORDER BY rating DESC
            LIMIT 1
        """)
        pandit_row = cur.fetchone()
        if pandit_row:
            pandit_id = pandit_row["id"]

    logger.info(
        "Temple booking_create user_id=%s pooja_type=%s requested_pandit=%s assigned_pandit=%s scheduled=%s %s",
        user_id,
        pooja_type_id,
        requested_pandit_id,
        pandit_id,
        scheduled_date,
        scheduled_time,
    )

    # Create booking
    booking_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()

    cur.execute("""
        INSERT INTO pooja_bookings
        (id, user_id, pooja_type_id, pandit_id, scheduled_date, scheduled_time,
         timezone, status, sankalp_name, sankalp_gotra, sankalp_nakshatra,
         special_requests, amount_paid, payment_status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        booking_id,
        user_id,
        pooja_type_id,
        pandit_id,
        scheduled_date,
        scheduled_time,
        data.get("timezone", "Asia/Kolkata"),
        "pending",
        data.get("sankalpName"),
        data.get("sankalpGotra"),
        data.get("sankalpNakshatra"),
        data.get("specialRequests"),
        pooja_row["base_price"],
        "pending",
        now,
        now,
    ))

    conn.commit()
    conn.close()

    logger.info(
        "Temple booking_created booking_id=%s status=pending user_id=%s pooja_type=%s pandit_id=%s",
        booking_id,
        user_id,
        pooja_type_id,
        pandit_id,
    )
    return jsonify({
        "bookingId": booking_id,
        "status": "pending",
        "scheduledDate": scheduled_date,
        "scheduledTime": scheduled_time,
        "amountDue": pooja_row["base_price"],
        "message": "Booking created successfully. Please complete payment to confirm.",
    }), 201


@temple_bp.route("/bookings", methods=["GET"])
def list_user_bookings():
    """
    GET /api/v1/temple/bookings

    List all bookings for the authenticated user.
    Query params:
    - status: Filter by status (pending, confirmed, completed, cancelled)
    """
    user_id = request.headers.get("X-User-Id")
    if not user_id:
        return jsonify({"error": _("Authentication required")}), 401

    status_filter = request.args.get("status")

    conn = get_connection()
    cur = conn.cursor()

    query = """
        SELECT b.id, b.pooja_type_id, b.pandit_id, b.scheduled_date, b.scheduled_time,
               b.timezone, b.status, b.sankalp_name, b.amount_paid, b.payment_status,
               b.session_link, b.created_at,
               p.name as pooja_name, p.icon_name, p.duration_minutes,
               pd.name as pandit_name
        FROM pooja_bookings b
        JOIN pooja_types p ON b.pooja_type_id = p.id
        LEFT JOIN pandits pd ON b.pandit_id = pd.id
        WHERE b.user_id = ?
    """
    params = [user_id]

    if status_filter:
        query += " AND b.status = ?"
        params.append(status_filter)

    query += " ORDER BY b.scheduled_date DESC, b.scheduled_time DESC"

    cur.execute(query, params)

    bookings = []
    for row in cur.fetchall():
        bookings.append({
            "id": row["id"],
            "poojaTypeId": row["pooja_type_id"],
            "poojaName": row["pooja_name"],
            "poojaIcon": row["icon_name"],
            "durationMinutes": row["duration_minutes"],
            "panditId": row["pandit_id"],
            "panditName": row["pandit_name"],
            "scheduledDate": row["scheduled_date"],
            "scheduledTime": row["scheduled_time"],
            "timezone": row["timezone"],
            "status": row["status"],
            "sankalpName": row["sankalp_name"],
            "amountPaid": row["amount_paid"],
            "paymentStatus": row["payment_status"],
            "sessionLink": row["session_link"],
            "createdAt": row["created_at"],
        })

    conn.close()
    return jsonify({"bookings": bookings})


@temple_bp.route("/bookings/<booking_id>", methods=["GET"])
def get_booking(booking_id: str):
    """
    GET /api/v1/temple/bookings/<booking_id>

    Get details of a specific booking.
    """
    user_id = request.headers.get("X-User-Id")
    if not user_id:
        return jsonify({"error": _("Authentication required")}), 401

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT b.*, p.name as pooja_name, p.icon_name, p.duration_minutes,
               p.benefits, p.ingredients,
               pd.name as pandit_name, pd.avatar_url as pandit_avatar
        FROM pooja_bookings b
        JOIN pooja_types p ON b.pooja_type_id = p.id
        LEFT JOIN pandits pd ON b.pandit_id = pd.id
        WHERE b.id = ? AND b.user_id = ?
    """, (booking_id, user_id))

    row = cur.fetchone()
    conn.close()

    if not row:
        return jsonify({"error": _("Booking not found")}), 404

    return jsonify({
        "id": row["id"],
        "poojaTypeId": row["pooja_type_id"],
        "poojaName": row["pooja_name"],
        "poojaIcon": row["icon_name"],
        "durationMinutes": row["duration_minutes"],
        "benefits": json.loads(row["benefits"]) if row["benefits"] else [],
        "ingredients": json.loads(row["ingredients"]) if row["ingredients"] else [],
        "panditId": row["pandit_id"],
        "panditName": row["pandit_name"],
        "panditAvatar": row["pandit_avatar"],
        "scheduledDate": row["scheduled_date"],
        "scheduledTime": row["scheduled_time"],
        "timezone": row["timezone"],
        "status": row["status"],
        "sankalpName": row["sankalp_name"],
        "sankalpGotra": row["sankalp_gotra"],
        "sankalpNakshatra": row["sankalp_nakshatra"],
        "specialRequests": row["special_requests"],
        "amountPaid": row["amount_paid"],
        "paymentStatus": row["payment_status"],
        "sessionLink": row["session_link"],
        "createdAt": row["created_at"],
    })


@temple_bp.route("/bookings/<booking_id>/cancel", methods=["POST"])
def cancel_booking(booking_id: str):
    """
    POST /api/v1/temple/bookings/<booking_id>/cancel

    Cancel a booking.
    """
    user_id = request.headers.get("X-User-Id")
    if not user_id:
        return jsonify({"error": _("Authentication required")}), 401

    conn = get_connection()
    cur = conn.cursor()

    # Check booking exists and belongs to user
    cur.execute("""
        SELECT status FROM pooja_bookings
        WHERE id = ? AND user_id = ?
    """, (booking_id, user_id))

    row = cur.fetchone()
    if not row:
        conn.close()
        return jsonify({"error": _("Booking not found")}), 404

    if row["status"] in ("completed", "cancelled"):
        conn.close()
        return jsonify({
            "error": _("Cannot cancel booking with status: %(status)s") % {"status": row["status"]}
        }), 400

    # Update status
    now = datetime.utcnow().isoformat()
    cur.execute("""
        UPDATE pooja_bookings
        SET status = 'cancelled', updated_at = ?
        WHERE id = ?
    """, (now, booking_id))

    conn.commit()
    conn.close()

    return jsonify({
        "bookingId": booking_id,
        "status": "cancelled",
        "message": "Booking cancelled successfully",
    })


@temple_bp.route("/bookings/<booking_id>/accept", methods=["POST"])
def accept_booking(booking_id: str):
    """
    POST /api/v1/temple/bookings/<booking_id>/accept

    Pandit accepts a booking assignment.
    """
    pandit_id = request.headers.get("X-Pandit-Id")
    if not pandit_id:
        return jsonify({"error": _("Pandit authentication required")}), 401

    conn = get_connection()
    cur = conn.cursor()

    # Verify pandit exists
    cur.execute("SELECT id, name, is_verified FROM pandits WHERE id = ?", (pandit_id,))
    pandit = cur.fetchone()
    if not pandit:
        conn.close()
        return jsonify({"error": _("Pandit not found")}), 404

    # Check booking exists and is available for acceptance
    cur.execute("""
        SELECT id, status, pandit_id, pooja_type_id, scheduled_date, scheduled_time
        FROM pooja_bookings
        WHERE id = ?
    """, (booking_id,))

    booking = cur.fetchone()
    if not booking:
        conn.close()
        return jsonify({"error": _("Booking not found")}), 404

    if booking["pandit_id"] and booking["pandit_id"] != pandit_id:
        conn.close()
        return jsonify({"error": _("Booking already assigned to another pandit")}), 400

    if booking["status"] in ("completed", "cancelled"):
        conn.close()
        return jsonify({
            "error": _("Cannot accept booking with status: %(status)s") % {"status": booking["status"]}
        }), 400

    # Assign pandit to booking
    now = datetime.now(timezone.utc).isoformat()
    cur.execute("""
        UPDATE pooja_bookings
        SET pandit_id = ?, status = 'assigned', updated_at = ?
        WHERE id = ?
    """, (pandit_id, now, booking_id))

    # Generate simple session link - anyone with the link can join
    session_id = str(uuid.uuid4())
    base_url = get_base_url()
    session_link = f"{base_url}/api/v1/temple/session/{session_id}"

    cur.execute("""
        INSERT OR REPLACE INTO pooja_sessions
        (id, booking_id, provider, user_link, pandit_link, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (session_id, booking_id, "twilio", session_link, session_link, "scheduled", now))

    # Update booking with session link
    cur.execute("""
        UPDATE pooja_bookings
        SET session_link = ?, session_id = ?
        WHERE id = ?
    """, (session_link, session_id, booking_id))

    conn.commit()
    conn.close()

    return jsonify({
        "bookingId": booking_id,
        "status": "assigned",
        "panditId": pandit_id,
        "panditName": pandit["name"],
        "sessionLink": session_link,
        "scheduledDate": booking["scheduled_date"],
        "scheduledTime": booking["scheduled_time"],
        "message": f"Booking accepted. Join link: {session_link}",
    })


@temple_bp.route("/bookings/<booking_id>/session", methods=["POST"])
def generate_session_link(booking_id: str):
    """
    POST /api/v1/temple/bookings/<booking_id>/session

    Generate a video session link for the booking.
    Called when payment is confirmed.
    """
    user_id = request.headers.get("X-User-Id")
    if not user_id:
        return jsonify({"error": _("Authentication required")}), 401
    logger.info("Temple generate_session_link booking_id=%s user_id=%s", booking_id, user_id)

    conn = get_connection()
    cur = conn.cursor()

    # Check booking exists
    cur.execute("""
        SELECT id, pandit_id, status, payment_status
        FROM pooja_bookings
        WHERE id = ? AND user_id = ?
    """, (booking_id, user_id))

    row = cur.fetchone()
    if not row:
        conn.close()
        return jsonify({"error": _("Booking not found")}), 404

    # Generate simple session link - anyone with the link can join
    session_id = str(uuid.uuid4())
    base_url = get_base_url()
    session_link = f"{base_url}/api/v1/temple/session/{session_id}"

    now = datetime.utcnow().isoformat()

    # Create session record
    cur.execute("""
        INSERT INTO pooja_sessions
        (id, booking_id, provider, user_link, pandit_link, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (session_id, booking_id, "twilio", session_link, session_link, "scheduled", now))

    # Update booking with session link
    cur.execute("""
        UPDATE pooja_bookings
        SET session_link = ?, session_id = ?, status = 'confirmed', updated_at = ?
        WHERE id = ?
    """, (session_link, session_id, now, booking_id))

    conn.commit()
    conn.close()

    logger.info(
        "Temple session_link_generated booking_id=%s session_id=%s status=confirmed",
        booking_id,
        session_id,
    )
    return jsonify({
        "sessionId": session_id,
        "sessionLink": session_link,
        "status": "confirmed",
        "message": "Session link generated. Share this link with anyone who needs to join.",
    })


# =============================================================================
# Pandit Enrollment
# =============================================================================


@temple_bp.route("/pandits/enroll", methods=["POST"])
def enroll_pandit():
    """
    POST /api/v1/temple/pandits/enroll

    Enroll a new pandit on the platform.
    Returns a pandit ID that can be used for authentication.
    """
    data = request.get_json() or {}

    required = ["name", "email", "phone", "specializations", "languages", "experienceYears"]
    for field in required:
        if field not in data:
            return jsonify({"error": _("%(field)s is required") % {"field": field}}), 400

    conn = get_connection()
    cur = conn.cursor()

    # Check if email already exists
    cur.execute("SELECT id FROM pandits WHERE email = ?", (data["email"],))
    if cur.fetchone():
        conn.close()
        return jsonify({"error": _("Email already registered")}), 400

    pandit_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    cur.execute("""
        INSERT INTO pandits (id, name, email, phone, specializations, languages,
                            experience_years, bio, rating, review_count, price_per_session,
                            is_verified, is_available, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        pandit_id,
        data["name"],
        data["email"],
        data["phone"],
        json.dumps(data["specializations"]),
        json.dumps(data["languages"]),
        data["experienceYears"],
        data.get("bio", ""),
        0.0,  # Initial rating
        0,    # Initial review count
        data.get("pricePerSession", 500),  # Default price
        False,  # Not verified initially
        True,   # Available by default
        now
    ))

    conn.commit()
    conn.close()

    return jsonify({
        "panditId": pandit_id,
        "name": data["name"],
        "status": "pending_verification",
        "message": "Enrollment submitted. Your profile will be verified within 24-48 hours.",
        "portalLink": f"{get_base_url()}/pandit/portal?id={pandit_id}"
    }), 201


# =============================================================================
# Pandit Portal Endpoints (for enrolled pandits)
# =============================================================================


@temple_bp.route("/pandit/bookings", methods=["GET"])
def list_pandit_bookings():
    """
    GET /api/v1/temple/pandit/bookings

    List bookings assigned to the pandit.
    Requires X-Pandit-Id header.
    """
    pandit_id = request.headers.get("X-Pandit-Id")
    if not pandit_id:
        return jsonify({"error": _("Pandit authentication required")}), 401

    status_filter = request.args.get("status")

    conn = get_connection()
    cur = conn.cursor()

    query = """
        SELECT b.id, b.pooja_type_id, b.scheduled_date, b.scheduled_time,
               b.timezone, b.status, b.sankalp_name, b.sankalp_gotra,
               b.sankalp_nakshatra, b.special_requests,
               p.name as pooja_name, p.duration_minutes
        FROM pooja_bookings b
        JOIN pooja_types p ON b.pooja_type_id = p.id
        WHERE b.pandit_id = ?
    """
    params = [pandit_id]

    if status_filter:
        query += " AND b.status = ?"
        params.append(status_filter)

    query += " ORDER BY b.scheduled_date ASC, b.scheduled_time ASC"

    cur.execute(query, params)

    bookings = []
    for row in cur.fetchall():
        bookings.append({
            "id": row["id"],
            "poojaTypeId": row["pooja_type_id"],
            "poojaName": row["pooja_name"],
            "durationMinutes": row["duration_minutes"],
            "scheduledDate": row["scheduled_date"],
            "scheduledTime": row["scheduled_time"],
            "timezone": row["timezone"],
            "status": row["status"],
            "sankalpName": row["sankalp_name"],
            "sankalpGotra": row["sankalp_gotra"],
            "sankalpNakshatra": row["sankalp_nakshatra"],
            "specialRequests": row["special_requests"],
        })

    conn.close()
    return jsonify({"bookings": bookings})


@temple_bp.route("/pandit/bookings/<booking_id>/join", methods=["GET"])
def get_pandit_session_link(booking_id: str):
    """
    GET /api/v1/temple/pandit/bookings/<booking_id>/join

    Get the pandit's session link for a booking.
    """
    pandit_id = request.headers.get("X-Pandit-Id")
    if not pandit_id:
        return jsonify({"error": _("Pandit authentication required")}), 401

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT s.pandit_link, s.status, b.scheduled_date, b.scheduled_time
        FROM pooja_sessions s
        JOIN pooja_bookings b ON s.booking_id = b.id
        WHERE b.id = ? AND b.pandit_id = ?
    """, (booking_id, pandit_id))

    row = cur.fetchone()
    conn.close()

    if not row:
        return jsonify({"error": _("Session not found")}), 404

    return jsonify({
        "sessionLink": row["pandit_link"],
        "status": row["status"],
        "scheduledDate": row["scheduled_date"],
        "scheduledTime": row["scheduled_time"],
    })


# =============================================================================
# Chat Message Filtering Endpoint
# =============================================================================


@temple_bp.route("/filter-message", methods=["POST"])
def filter_message():
    """
    POST /api/v1/temple/filter-message

    Filter contact details from a message.
    Used by chat and video call services.

    Body:
    {
        "message": "Call me at 9876543210",
        "contextType": "pooja_session",
        "contextId": "session_123",
        "senderType": "pandit",
        "senderId": "pandit_001"
    }
    """
    data = request.get_json() or {}

    message = data.get("message", "")
    context_type = data.get("contextType", "unknown")
    context_id = data.get("contextId", "unknown")
    sender_type = data.get("senderType", "unknown")
    sender_id = data.get("senderId", "unknown")

    filtered_message, matched_patterns = filter_contact_details(
        message=message,
        context_type=context_type,
        context_id=context_id,
        sender_type=sender_type,
        sender_id=sender_id,
    )

    return jsonify({
        "originalMessage": message,
        "filteredMessage": filtered_message,
        "wasFiltered": len(matched_patterns) > 0,
        "patternsFound": len(matched_patterns),
    })


# =============================================================================
# Jitsi Meet Video Session
# =============================================================================


@temple_bp.route("/session/<session_id>/token", methods=["POST"])
def get_session_token(session_id: str):
    """
    POST /api/v1/temple/session/<session_id>/token

    Generate a Jitsi Meet room URL for joining a session.
    Anyone with the session ID can join - no authentication needed.

    Body:
    {
        "identity": "User Name"
    }
    """
    data = request.get_json() or {}
    identity = data.get("identity", f"Guest-{uuid.uuid4().hex[:6]}")

    # Generate Jitsi Meet room URL
    # Format: https://meet.jit.si/astronova-{session_id}
    room_name = f"astronova-{session_id}"
    jitsi_url = f"https://meet.jit.si/{room_name}"

    logger.info(f"Generated Jitsi room URL for {identity}: {jitsi_url}")

    return jsonify({
        "roomUrl": jitsi_url,
        "roomName": room_name,
        "identity": identity,
        "provider": "jitsi",
        "message": "Jitsi Meet - Free & Secure Video Calls"
    })


@temple_bp.route("/session/<session_id>", methods=["GET"])
def serve_session_page(session_id: str):
    """
    GET /api/v1/temple/session/<session_id>

    Serve the video session page.
    """
    from flask import send_from_directory, current_app
    import os

    static_dir = os.path.join(current_app.root_path, "static", "temple")
    return send_from_directory(static_dir, "session.html")


# =============================================================================
# Temple Redesign Endpoints
# =============================================================================


@temple_bp.route("/muhurats", methods=["GET"])
def get_muhurats():
    """
    GET /api/v1/temple/muhurats?date=YYYY-MM-DD&lat=...&lon=...

    Returns muhurat times and panchang data for a given date.
    Uses calculated sample data based on the date.
    """
    from math import sin, cos, pi

    date_str = request.args.get("date")
    if not date_str:
        date_str = datetime.utcnow().strftime("%Y-%m-%d")

    try:
        target_date = datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        return jsonify({"error": "Invalid date format. Use YYYY-MM-DD."}), 400

    # Day-of-year seed for deterministic but varying data
    doy = target_date.timetuple().tm_yday

    # Calculate muhurat windows (approximate, based on sunrise/sunset)
    # In reality these come from a panchang API; we generate plausible times.
    sunrise_hour = 6 + (sin(doy * pi / 182.5) * 0.5)  # ~5:30-6:30
    sunset_hour = 18 - (sin(doy * pi / 182.5) * 0.5)   # ~17:30-18:30
    day_dur = sunset_hour - sunrise_hour

    def _fmt(h):
        hh = int(h)
        mm = int((h - hh) * 60)
        return f"{hh:02d}:{mm:02d}"

    abhijit_start = sunrise_hour + day_dur * 0.4583  # ~11:30
    brahma_start = sunrise_hour + day_dur * 0.375    # ~10:30

    # Rahu Kalam varies by day of week
    rahu_offsets = [7, 1, 6, 4, 5, 3, 2]  # Sun-Sat segment number
    rk_segment = rahu_offsets[target_date.weekday()]
    rk_start = sunrise_hour + (rk_segment - 1) * (day_dur / 8)
    rk_end = rk_start + day_dur / 8

    godhuli_start = sunset_hour - 0.4  # ~24 min before sunset

    muhurats = [
        {
            "name": "Abhijit Muhurat",
            "description": "The victorious muhurat, ideal for all auspicious activities",
            "startTime": _fmt(abhijit_start),
            "endTime": _fmt(abhijit_start + day_dur / 15),
            "isAuspicious": True,
        },
        {
            "name": "Brahma Muhurat",
            "description": "Sacred time for meditation and spiritual practices",
            "startTime": _fmt(sunrise_hour - 1.6),
            "endTime": _fmt(sunrise_hour - 0.8),
            "isAuspicious": True,
        },
        {
            "name": "Rahu Kalam",
            "description": "Inauspicious period ruled by Rahu, avoid new beginnings",
            "startTime": _fmt(rk_start),
            "endTime": _fmt(rk_end),
            "isAuspicious": False,
        },
        {
            "name": "Godhuli Muhurat",
            "description": "Twilight muhurat, auspicious for weddings and prayers",
            "startTime": _fmt(godhuli_start),
            "endTime": _fmt(sunset_hour),
            "isAuspicious": True,
        },
    ]

    # Panchang data (deterministic from day-of-year)
    tithis = [
        "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
        "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
        "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima",
        "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
        "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
        "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Amavasya",
    ]
    nakshatras = [
        "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira",
        "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha",
        "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati",
        "Vishakha", "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha",
        "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
        "Purva Bhadrapada", "Uttara Bhadrapada", "Revati",
    ]
    yogas = [
        "Vishkumbha", "Preeti", "Ayushman", "Saubhagya", "Shobhana",
        "Atiganda", "Sukarma", "Dhriti", "Shoola", "Ganda",
        "Vriddhi", "Dhruva", "Vyaghata", "Harshana", "Vajra",
        "Siddhi", "Vyatipata", "Variyan", "Parigha", "Shiva",
        "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma",
        "Indra", "Vaidhriti",
    ]
    karanas = [
        "Bava", "Balava", "Kaulava", "Taitila", "Gara",
        "Vanija", "Vishti", "Shakuni", "Chatushpada", "Naga", "Kimstughna",
    ]

    panchang = {
        "tithi": tithis[doy % len(tithis)],
        "nakshatra": nakshatras[doy % len(nakshatras)],
        "yoga": yogas[doy % len(yogas)],
        "karana": karanas[(doy * 2) % len(karanas)],
        "sunrise": _fmt(sunrise_hour),
        "sunset": _fmt(sunset_hour),
    }

    return jsonify({
        "date": date_str,
        "muhurats": muhurats,
        "panchang": panchang,
    })


@temple_bp.route("/diy-poojas", methods=["GET"])
def list_diy_poojas():
    """
    GET /api/v1/temple/diy-poojas

    Returns enriched pooja data with DIY steps, mantras, and ingredients.
    Only returns poojas that have steps populated.
    """
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, name, description, deity, duration_minutes, base_price,
               icon_name, benefits, ingredients, mantras, steps,
               deity_description, significance, sort_order
        FROM pooja_types
        WHERE is_active = 1 AND steps IS NOT NULL
        ORDER BY sort_order ASC
    """)

    poojas = []
    for row in cur.fetchall():
        poojas.append({
            "id": row["id"],
            "name": row["name"],
            "description": row["description"],
            "deity": row["deity"],
            "durationMinutes": row["duration_minutes"],
            "basePrice": row["base_price"],
            "iconName": row["icon_name"],
            "benefits": json.loads(row["benefits"]) if row["benefits"] else [],
            "ingredients": json.loads(row["ingredients"]) if row["ingredients"] else [],
            "mantras": json.loads(row["mantras"]) if row["mantras"] else [],
            "steps": json.loads(row["steps"]) if row["steps"] else [],
            "deityDescription": row["deity_description"],
            "significance": row["significance"],
        })

    conn.close()
    return jsonify({"poojas": poojas})


@temple_bp.route("/vedic-library", methods=["GET"])
def get_vedic_library():
    """
    GET /api/v1/temple/vedic-library?category=X&search=Y

    Browse and search vedic entries.
    Returns entries grouped by category with counts.
    """
    category = request.args.get("category")
    search = request.args.get("search")

    conn = get_connection()
    cur = conn.cursor()

    query = """
        SELECT id, category, title, sanskrit_text, transliteration,
               translation, source, tags, sort_order
        FROM vedic_entries
        WHERE is_active = 1
    """
    params = []

    if category:
        query += " AND category = ?"
        params.append(category)

    if search:
        query += " AND (title LIKE ? OR translation LIKE ? OR tags LIKE ?)"
        search_term = f"%{search}%"
        params.extend([search_term, search_term, search_term])

    query += " ORDER BY category, sort_order ASC"

    cur.execute(query, params)

    # Group by category
    categories_map: dict[str, list] = {}
    for row in cur.fetchall():
        cat = row["category"]
        if cat not in categories_map:
            categories_map[cat] = []
        categories_map[cat].append({
            "id": row["id"],
            "title": row["title"],
            "sanskritText": row["sanskrit_text"],
            "transliteration": row["transliteration"],
            "translation": row["translation"],
            "source": row["source"],
            "tags": json.loads(row["tags"]) if row["tags"] else [],
        })

    conn.close()

    categories_list = [
        {"name": name, "count": len(entries), "entries": entries}
        for name, entries in categories_map.items()
    ]

    return jsonify({
        "categories": categories_list,
        "totalEntries": sum(c["count"] for c in categories_list),
    })


@temple_bp.route("/bell/ring", methods=["POST"])
def record_bell_ring():
    """
    POST /api/v1/temple/bell/ring

    Record a bell ring for the authenticated user.
    Body: { "streak": 5, "totalRings": 42 }
    """
    user_id = request.headers.get("X-User-Id")
    if not user_id:
        return jsonify({"error": "Authentication required"}), 401

    data = request.get_json() or {}

    activity_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()

    activity_data = json.dumps({
        "streak": data.get("streak", 0),
        "totalRings": data.get("totalRings", 0),
    })

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        INSERT INTO user_temple_activity
        (id, user_id, activity_type, data, created_at)
        VALUES (?, ?, ?, ?, ?)
    """, (activity_id, user_id, "bell_ring", activity_data, now))

    conn.commit()
    conn.close()

    logger.info(
        "Temple bell_ring user_id=%s streak=%s total=%s",
        user_id,
        data.get("streak", 0),
        data.get("totalRings", 0),
    )

    return jsonify({
        "success": True,
        "message": "Bell ring recorded. Om Shanti!",
    })

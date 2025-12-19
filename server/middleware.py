"""
Request/Response logging middleware for Flask
"""

import logging
import time
import uuid

from flask import g, request

logger = logging.getLogger(__name__)


def setup_logging():
    """Configure structured logging for the application"""
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s - %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
    )


def add_request_id():
    """Generate and attach request ID to g context"""
    g.request_id = str(uuid.uuid4())[:8]
    g.start_time = time.time()


def log_request_response(response):
    """Log request and response details"""
    try:
        duration_ms = (time.time() - g.start_time) * 1000 if hasattr(g, "start_time") else 0
        request_id = g.request_id if hasattr(g, "request_id") else "unknown"

        log_data = {
            "request_id": request_id,
            "method": request.method,
            "path": request.path,
            "status": response.status_code,
            "duration_ms": round(duration_ms, 2),
            "ip": request.remote_addr,
            "user_agent": request.headers.get("User-Agent", "unknown")[:50],
        }

        if response.status_code >= 500:
            logger.error(f"REQUEST {log_data}")
        elif response.status_code >= 400:
            logger.warning(f"REQUEST {log_data}")
        else:
            logger.info(f"REQUEST {log_data}")

        # Add request ID to response headers for tracing
        response.headers["X-Request-ID"] = request_id

    except Exception as e:
        logger.error(f"Error in logging middleware: {e}")

    return response



import json
import logging
import os
import sqlite3
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from utils.time_utils import utc_now_iso

logger = logging.getLogger(__name__)


class StoreKitTransactionConflict(ValueError):
    """A verified App Store transaction was already claimed differently."""


def _resolve_db_path() -> str:
    """Resolve database path, ensuring directory exists and is writable."""
    # Check environment variable first
    env_path = os.environ.get("DB_PATH")
    if env_path:
        db_dir = os.path.dirname(env_path) or "."
        try:
            os.makedirs(db_dir, exist_ok=True)
            # Test write permission
            test_file = os.path.join(db_dir, ".write_test")
            with open(test_file, "w") as f:
                f.write("test")
            os.remove(test_file)
            logger.info(f"Using DB_PATH from environment: {env_path}")
            return env_path
        except (OSError, IOError) as e:
            logger.warning(f"Cannot use DB_PATH={env_path}: {e}")

    # Try app directory
    app_dir_path = os.path.join(os.path.dirname(__file__), "astronova.db")
    app_dir = os.path.dirname(app_dir_path)
    try:
        os.makedirs(app_dir, exist_ok=True)
        test_file = os.path.join(app_dir, ".write_test")
        with open(test_file, "w") as f:
            f.write("test")
        os.remove(test_file)
        return app_dir_path
    except (OSError, IOError) as e:
        logger.warning(f"Cannot use app directory for DB: {e}")

    # Fallback to /tmp (always writable on Linux)
    tmp_path = "/tmp/astronova.db"
    logger.info(f"Using fallback DB path: {tmp_path}")
    return tmp_path


DB_PATH = _resolve_db_path()


def get_connection():
    conn = sqlite3.connect(DB_PATH, timeout=10, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    # WAL lets readers and a writer proceed concurrently (vs. the default
    # rollback journal that locks the whole DB on write), and busy_timeout makes
    # a contended write wait briefly instead of failing with "database is
    # locked" — both matter under multi-worker gunicorn. In-memory test DBs do
    # not support WAL, so tolerate failure there.
    try:
        conn.execute("PRAGMA journal_mode = WAL")
        conn.execute("PRAGMA busy_timeout = 5000")
    except sqlite3.OperationalError:
        pass
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db():
    """
    Initialize the database by running all pending migrations.

    This function:
    1. Runs all pending migrations (which create tables if needed)
    2. Seeds content tables with defaults if empty
    """
    from migrations import run_migrations, MigrationError

    conn = get_connection()

    try:
        # Run all pending migrations
        applied = run_migrations(conn)
        if applied > 0:
            logger.info(f"Applied {applied} database migration(s)")
    except MigrationError as e:
        logger.error(f"Database migration failed: {e}")
        conn.close()
        raise

    # Seed content tables with defaults if empty
    _seed_content(conn)
    conn.close()


def _seed_content(conn: sqlite3.Connection) -> None:
    """Seed content tables with default data if empty."""
    cur = conn.cursor()

    cur.execute("SELECT COUNT(*) AS c FROM content_quick_questions")
    if (cur.fetchone()[0] or 0) == 0:
        defaults_q = [
            ("q1", "What's my love forecast?", "love", 1, 1),
            ("q2", "Career guidance?", "career", 2, 1),
            ("q3", "Today's energy?", "daily", 3, 1),
            ("q4", "What should I focus on?", "guidance", 4, 1),
            ("q5", "Lucky numbers today?", "daily", 5, 1),
        ]
        cur.executemany(
            "INSERT INTO content_quick_questions (id, text, category, order_index, is_active) VALUES (?,?,?,?,?)",
            defaults_q,
        )

    cur.execute("SELECT COUNT(*) AS c FROM content_insights")
    if (cur.fetchone()[0] or 0) == 0:
        defaults_i = [
            ("i1", "Daily Energy", "Your cosmic energy forecast", "daily", 1, 1),
            ("i2", "Love & Relationships", "Insights into your romantic journey", "love", 2, 1),
            ("i3", "Career Path", "Professional guidance from the stars", "career", 3, 1),
        ]
        cur.executemany(
            "INSERT INTO content_insights (id, title, content, category, priority, is_active) VALUES (?,?,?,?,?,?)",
            defaults_i,
        )

    conn.commit()


def upsert_user(user_id: str, email: Optional[str], first_name: Optional[str], last_name: Optional[str], full_name: str):
    now = utc_now_iso()
    conn = get_connection()
    try:
        # Atomic upsert: two concurrent first sign-ins for the same user must
        # not race a SELECT-then-INSERT into an IntegrityError.
        conn.execute(
            """
            INSERT INTO users (id, email, first_name, last_name, full_name, created_at, updated_at)
            VALUES (?,?,?,?,?,?,?)
            ON CONFLICT(id) DO UPDATE SET
                email=excluded.email,
                first_name=excluded.first_name,
                last_name=excluded.last_name,
                full_name=excluded.full_name,
                updated_at=excluded.updated_at
            """,
            (user_id, email, first_name, last_name, full_name, now, now),
        )
        conn.commit()
    finally:
        conn.close()


def get_user_preferred_language(user_id: str) -> Optional[str]:
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT preferred_language FROM users WHERE id=?", (user_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        return None
    return row["preferred_language"] or None


def insert_report(report_id: str, user_id: Optional[str], type_: str, title: str, content: str, status: str = "completed"):
    now = utc_now_iso()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO reports (report_id, user_id, type, title, content, generated_at, status) VALUES (?,?,?,?,?,?,?)",
        (report_id, user_id, type_, title, content, now, status),
    )
    conn.commit()
    conn.close()


def get_user_reports(user_id: str) -> list[dict]:
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT report_id, user_id, type, title, content, generated_at, status FROM reports WHERE user_id=? ORDER BY generated_at DESC",
        (user_id,),
    )
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows


def get_user_report_summaries(user_id: str, limit: int = 25) -> list[dict]:
    """Return report list metadata without shipping full report bodies."""
    conn = get_connection()
    cur = conn.cursor()
    safe_limit = max(1, min(int(limit), 50))
    cur.execute(
        """
        SELECT
            report_id,
            user_id,
            type,
            title,
            CASE
                WHEN json_valid(content) THEN COALESCE(json_extract(content, '$.summary'), '')
                ELSE substr(COALESCE(content, ''), 1, 280)
            END AS summary,
            CASE
                WHEN json_valid(content) THEN json_extract(content, '$.keyInsights')
                ELSE NULL
            END AS key_insights_json,
            generated_at,
            status
        FROM reports
        WHERE user_id=?
        ORDER BY generated_at DESC
        LIMIT ?
        """,
        (user_id, safe_limit),
    )
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return rows


def get_report(report_id: str) -> Optional[dict]:
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT report_id, user_id, type, title, content, generated_at, status FROM reports WHERE report_id=?",
        (report_id,),
    )
    row = cur.fetchone()
    conn.close()
    return dict(row) if row else None


def update_report(report_id: str, title: str, content: str, status: str = "completed"):
    """Update an existing report with generated content."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "UPDATE reports SET title=?, content=?, status=? WHERE report_id=?",
        (title, content, status, report_id),
    )
    conn.commit()
    conn.close()


def fail_stuck_reports(older_than_minutes: int = 15) -> int:
    """Mark reports stuck in 'processing' past a threshold as failed.

    Async generation runs in background threads that don't survive a process
    restart, leaving reports 'processing' forever. Called at startup to clear
    those so the client sees a definitive 'failed' (and can retry) instead of a
    spinner that never resolves. Returns the number of reports updated.
    """
    cutoff = (datetime.utcnow() - timedelta(minutes=older_than_minutes)).isoformat()
    payload = json.dumps(
        {"error": "Report generation was interrupted. Please try again.", "code": "REPORT_GENERATION_INTERRUPTED"}
    )
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "UPDATE reports SET status='failed', content=? WHERE status IN ('processing','generating') AND generated_at < ?",
            (payload, cutoff),
        )
        conn.commit()
        return cur.rowcount
    except sqlite3.OperationalError:
        return 0
    finally:
        conn.close()


# Content accessors
def get_content_management() -> dict:
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT id, text, category, order_index as order_idx, is_active FROM content_quick_questions ORDER BY order_index ASC"
    )
    quick_questions = []
    for r in cur.fetchall():
        quick_questions.append(
            {
                "id": r["id"],
                "text": r["text"],
                "category": r["category"],
                "order": r["order_idx"],
                "is_active": bool(r["is_active"]),
            }
        )
    cur.execute("SELECT id, title, content, category, priority, is_active FROM content_insights ORDER BY priority ASC")
    insights = []
    for r in cur.fetchall():
        insights.append(
            {
                "id": r["id"],
                "title": r["title"],
                "content": r["content"],
                "category": r["category"],
                "priority": r["priority"],
                "is_active": bool(r["is_active"]),
            }
        )
    conn.close()
    return {"quick_questions": quick_questions, "insights": insights}


# Chat persistence helpers
def ensure_conversation(conversation_id: Optional[str], user_id: Optional[str]) -> str:
    conn = get_connection()
    cur = conn.cursor()
    now = utc_now_iso()
    if conversation_id:
        cur.execute("SELECT id FROM chat_conversations WHERE id=?", (conversation_id,))
        row = cur.fetchone()
        if not row:
            cur.execute(
                "INSERT INTO chat_conversations (id, user_id, created_at, updated_at) VALUES (?,?,?,?)",
                (conversation_id, user_id, now, now),
            )
    else:
        import uuid

        conversation_id = str(uuid.uuid4())
        cur.execute(
            "INSERT INTO chat_conversations (id, user_id, created_at, updated_at) VALUES (?,?,?,?)",
            (conversation_id, user_id, now, now),
        )
    conn.commit()
    conn.close()
    return conversation_id


def add_chat_message(conversation_id: str, role: str, content: str, user_id: Optional[str] = None) -> str:
    import uuid

    message_id = str(uuid.uuid4())
    now = utc_now_iso()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO chat_messages (id, conversation_id, user_id, role, content, created_at) VALUES (?,?,?,?,?,?)",
        (message_id, conversation_id, user_id, role, content, now),
    )
    cur.execute(
        "UPDATE chat_conversations SET updated_at=? WHERE id=?",
        (now, conversation_id),
    )
    conn.commit()
    conn.close()
    return message_id


def get_chat_messages(conversation_id: str, limit: int = 50, offset: int = 0) -> list[dict]:
    """Retrieve chat messages for a conversation."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """SELECT id, conversation_id, user_id, role, content, created_at
           FROM chat_messages
           WHERE conversation_id=?
           ORDER BY created_at ASC
           LIMIT ? OFFSET ?""",
        (conversation_id, limit, offset),
    )
    rows = cur.fetchall()
    conn.close()
    return [
        {
            "id": row["id"],
            "conversationId": row["conversation_id"],
            "userId": row["user_id"],
            "role": row["role"],
            "content": row["content"],
            "createdAt": row["created_at"],
        }
        for row in rows
    ]


def get_user_conversations(user_id: str, limit: int = 20) -> list[dict]:
    """Retrieve conversations for a user."""
    if not user_id:
        return []
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """SELECT id, user_id, created_at, updated_at
           FROM chat_conversations
           WHERE user_id=?
           ORDER BY updated_at DESC
           LIMIT ?""",
        (user_id, limit),
    )
    rows = cur.fetchall()
    conn.close()
    return [
        {
            "id": row["id"],
            "userId": row["user_id"],
            "createdAt": row["created_at"],
            "updatedAt": row["updated_at"],
        }
        for row in rows
    ]


# Subscription helpers
def _column_exists(cur, table: str, column: str) -> bool:
    cur.execute(f"PRAGMA table_info({table})")
    return any(r[1] == column for r in cur.fetchall())


def get_subscription(user_id: Optional[str]) -> dict:
    if not user_id:
        return {"isActive": False}
    conn = get_connection()
    cur = conn.cursor()
    # expires_at is added by migration 009; tolerate older schemas.
    has_expiry = _column_exists(cur, "subscription_status", "expires_at")
    columns = "is_active, product_id, updated_at" + (", expires_at" if has_expiry else "")
    cur.execute(
        f"SELECT {columns} FROM subscription_status WHERE user_id=?",
        (user_id,),
    )
    row = cur.fetchone()
    conn.close()
    if not row:
        return {"isActive": False}

    is_active = bool(row["is_active"])
    expires_at = row["expires_at"] if has_expiry else None

    # A verified auto-renewable subscription stays entitled only until it
    # expires. If Apple hasn't told us about a renewal past the expiry, treat
    # it as lapsed so a stale 'active' flag can't grant indefinite access.
    if is_active and expires_at:
        try:
            parsed = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            if parsed < datetime.now(timezone.utc):
                is_active = False
        except (ValueError, AttributeError):
            # Fail closed: an unparseable expiry must not grant indefinite
            # access. Apple re-verification will restore a legitimate sub.
            logger.warning("Unparseable subscription expiry %r; treating as lapsed", expires_at)
            is_active = False

    result = {
        "isActive": is_active,
        "productId": row["product_id"],
        "updatedAt": row["updated_at"],
    }
    if expires_at:
        result["expiresAt"] = expires_at
    return result


def get_premium_entitlement(user_id: Optional[str]) -> dict:
    """Return the server-side premium entitlement from subscription_status only."""
    subscription = get_subscription(user_id)
    is_active = bool(subscription.get("isActive"))
    return {
        "hasPremium": is_active,
        "source": "subscription_status",
        "subscription": subscription,
    }


def has_premium_entitlement(user_id: Optional[str]) -> bool:
    """Whether the user currently has server-recognized premium access."""
    return bool(get_premium_entitlement(user_id).get("hasPremium"))


def set_subscription(user_id: str, is_active: bool, product_id: Optional[str] = None) -> None:
    """Create or update a user's subscription status."""
    now = utc_now_iso()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO subscription_status (user_id, is_active, product_id, updated_at)
           VALUES (?, ?, ?, ?)
           ON CONFLICT(user_id) DO UPDATE SET
             is_active = excluded.is_active,
             product_id = excluded.product_id,
             updated_at = excluded.updated_at""",
        (user_id, int(is_active), product_id, now),
    )
    conn.commit()
    conn.close()


def set_subscription_from_transaction(
    user_id: str,
    *,
    is_active: bool,
    product_id: Optional[str],
    expires_at: Optional[str] = None,
    original_transaction_id: Optional[str] = None,
    latest_transaction_id: Optional[str] = None,
    environment: Optional[str] = None,
    auto_renew: Optional[bool] = None,
) -> None:
    """Persist an App Store-verified subscription and its renewal metadata."""
    now = utc_now_iso()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO subscription_status
             (user_id, is_active, product_id, expires_at, original_transaction_id,
              latest_transaction_id, environment, auto_renew, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(user_id) DO UPDATE SET
             is_active = excluded.is_active,
             product_id = excluded.product_id,
             expires_at = excluded.expires_at,
             original_transaction_id = excluded.original_transaction_id,
             latest_transaction_id = excluded.latest_transaction_id,
             environment = excluded.environment,
             auto_renew = excluded.auto_renew,
             updated_at = excluded.updated_at""",
        (
            user_id, int(is_active), product_id, expires_at,
            original_transaction_id, latest_transaction_id, environment,
            None if auto_renew is None else int(auto_renew), now,
        ),
    )
    conn.commit()
    conn.close()


def deactivate_subscription(user_id: str, *, reason: Optional[str] = None) -> None:
    """Revoke a user's subscription after expiry, refund, or revocation."""
    conn = get_connection()
    conn.execute(
        "UPDATE subscription_status SET is_active=0, auto_renew=0, updated_at=? WHERE user_id=?",
        (utc_now_iso(), user_id),
    )
    conn.commit()
    conn.close()


def is_transaction_processed(transaction_id: str) -> bool:
    if not transaction_id:
        return False
    conn = get_connection()
    row = conn.execute(
        "SELECT 1 FROM processed_transactions WHERE transaction_id=?",
        (transaction_id,),
    ).fetchone()
    conn.close()
    return row is not None


def record_processed_transaction(
    transaction_id: str,
    *,
    user_id: Optional[str],
    product_id: Optional[str],
    type: Optional[str],
    environment: Optional[str] = None,
) -> bool:
    """Record a verified transaction once; return False for a replay."""
    if not transaction_id:
        return False
    conn = get_connection()
    try:
        conn.execute(
            """INSERT INTO processed_transactions
                 (transaction_id, user_id, product_id, type, environment, processed_at)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (transaction_id, user_id, product_id, type, environment, utc_now_iso()),
        )
        conn.commit()
        return True
    except sqlite3.IntegrityError:
        return False
    finally:
        conn.close()


def has_report_entitlement(user_id: Optional[str], domain: Optional[str]) -> bool:
    if not user_id or not domain:
        return False
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT 1 FROM processed_transactions WHERE user_id=? AND product_id=? LIMIT 1",
            (user_id, f"report_{domain}"),
        ).fetchone()
        return row is not None
    except sqlite3.OperationalError:
        return False
    finally:
        conn.close()


def find_user_by_original_transaction(original_transaction_id: str) -> Optional[str]:
    if not original_transaction_id:
        return None
    conn = get_connection()
    row = conn.execute(
        "SELECT user_id FROM subscription_status WHERE original_transaction_id=?",
        (original_transaction_id,),
    ).fetchone()
    conn.close()
    return row["user_id"] if row else None


def record_storekit_transaction(
    user_id: str,
    product_id: str,
    purchase_kind: str,
    transaction_id: str,
    original_transaction_id: Optional[str] = None,
    units: int = 0,
    environment: Optional[str] = None,
) -> bool:
    """Claim a verified transaction once, returning True only for first delivery."""
    now = utc_now_iso()
    conn = get_connection()
    try:
        conn.execute("BEGIN IMMEDIATE")
        row = conn.execute(
            """SELECT user_id, product_id, purchase_kind, units
               FROM storekit_transaction_ledger WHERE transaction_id=?""",
            (transaction_id,),
        ).fetchone()
        if row:
            if row["user_id"] is None:
                raise StoreKitTransactionConflict("StoreKit transaction was previously claimed")
            if (
                row["user_id"] != user_id
                or row["product_id"] != product_id
                or row["purchase_kind"] != purchase_kind
                or row["units"] != units
            ):
                raise StoreKitTransactionConflict("StoreKit transaction is already claimed")
            conn.commit()
            return False

        conn.execute(
            """INSERT INTO storekit_transaction_ledger
               (transaction_id, original_transaction_id, user_id, product_id,
                purchase_kind, units, environment, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                transaction_id,
                original_transaction_id,
                user_id,
                product_id,
                purchase_kind,
                units,
                environment,
                now,
            ),
        )
        conn.commit()
        return True
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def sync_oracle_credit_purchase(
    user_id: str,
    product_id: str,
    transaction_id: str,
    credits: int,
    original_transaction_id: Optional[str] = None,
    environment: Optional[str] = None,
) -> dict:
    """Atomically claim a verified consumable transaction and credit its owner."""
    now = utc_now_iso()
    conn = get_connection()
    try:
        conn.execute("BEGIN IMMEDIATE")
        row = conn.execute(
            """SELECT user_id, product_id, purchase_kind, units
               FROM storekit_transaction_ledger WHERE transaction_id=?""",
            (transaction_id,),
        ).fetchone()
        replayed = row is not None
        if row:
            if row["user_id"] is None:
                raise StoreKitTransactionConflict("StoreKit transaction was previously claimed")
            if (
                row["user_id"] != user_id
                or row["product_id"] != product_id
                or row["purchase_kind"] != "oracle_credits"
                or row["units"] != credits
            ):
                raise StoreKitTransactionConflict("StoreKit transaction is already claimed")
        else:
            conn.execute(
                """INSERT INTO storekit_transaction_ledger
                   (transaction_id, original_transaction_id, user_id, product_id,
                    purchase_kind, units, environment, created_at)
                   VALUES (?, ?, ?, ?, 'oracle_credits', ?, ?, ?)""",
                (
                    transaction_id,
                    original_transaction_id,
                    user_id,
                    product_id,
                    credits,
                    environment,
                    now,
                ),
            )
            conn.execute(
                """INSERT INTO oracle_credit_balances (user_id, balance, updated_at)
                   VALUES (?, ?, ?)
                   ON CONFLICT(user_id) DO UPDATE SET
                     balance = oracle_credit_balances.balance + excluded.balance,
                     updated_at = excluded.updated_at""",
                (user_id, credits, now),
            )

        balance_row = conn.execute(
            "SELECT balance, updated_at FROM oracle_credit_balances WHERE user_id=?",
            (user_id,),
        ).fetchone()
        conn.commit()
        return {
            "balance": int(balance_row["balance"]) if balance_row else 0,
            "creditedUnits": 0 if replayed else credits,
            "replayed": replayed,
            "updatedAt": balance_row["updated_at"] if balance_row else now,
        }
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def get_oracle_credit_balance(user_id: Optional[str]) -> int:
    if not user_id:
        return 0
    conn = get_connection()
    row = conn.execute(
        "SELECT balance FROM oracle_credit_balances WHERE user_id=?",
        (user_id,),
    ).fetchone()
    conn.close()
    return int(row["balance"]) if row else 0


# Individual report purchase helpers
def sync_report_purchase_entitlement(
    user_id: str,
    product_id: str,
    report_type: str,
    transaction_id: str,
    original_transaction_id: Optional[str] = None,
    environment: Optional[str] = None,
) -> dict:
    """Create or return a StoreKit-backed individual report entitlement."""
    now = utc_now_iso()
    entitlement_id = str(uuid.uuid4())
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO report_purchase_entitlements
           (id, user_id, product_id, report_type, transaction_id, original_transaction_id, environment, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(transaction_id) DO UPDATE SET
             original_transaction_id = COALESCE(excluded.original_transaction_id, original_transaction_id),
             environment = COALESCE(excluded.environment, environment)""",
        (
            entitlement_id,
            user_id,
            product_id,
            report_type,
            transaction_id,
            original_transaction_id,
            environment,
            now,
        ),
    )
    cur.execute(
        """SELECT id, user_id, product_id, report_type, transaction_id,
                  original_transaction_id, environment, consumed_report_id, created_at, consumed_at
           FROM report_purchase_entitlements
           WHERE transaction_id=?""",
        (transaction_id,),
    )
    row = cur.fetchone()
    conn.commit()
    conn.close()
    return _report_purchase_row_to_dict(row)


def get_available_report_purchase(user_id: str, report_type: str) -> Optional[dict]:
    """Return one unconsumed individual report entitlement for the report type."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """SELECT id, user_id, product_id, report_type, transaction_id,
                  original_transaction_id, environment, consumed_report_id, created_at, consumed_at
           FROM report_purchase_entitlements
           WHERE user_id=? AND report_type=? AND consumed_at IS NULL
           ORDER BY created_at ASC
           LIMIT 1""",
        (user_id, report_type),
    )
    row = cur.fetchone()
    conn.close()
    return _report_purchase_row_to_dict(row) if row else None


def consume_report_purchase(entitlement_id: str, report_id: str) -> None:
    now = utc_now_iso()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """UPDATE report_purchase_entitlements
           SET consumed_report_id=?, consumed_at=?
           WHERE id=? AND consumed_at IS NULL""",
        (report_id, now, entitlement_id),
    )
    conn.commit()
    conn.close()


def _report_purchase_row_to_dict(row) -> dict:
    if not row:
        return {}
    return {
        "id": row["id"],
        "userId": row["user_id"],
        "productId": row["product_id"],
        "reportType": row["report_type"],
        "transactionId": row["transaction_id"],
        "originalTransactionId": row["original_transaction_id"],
        "environment": row["environment"],
        "consumedReportId": row["consumed_report_id"],
        "createdAt": row["created_at"],
        "consumedAt": row["consumed_at"],
        "isAvailable": row["consumed_at"] is None,
    }


# Server-side chat-credit helpers
def get_credit_balance(user_id: Optional[str]) -> int:
    if not user_id:
        return 0
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT balance FROM user_credits WHERE user_id=?", (user_id,))
    row = cur.fetchone()
    conn.close()
    return int(row["balance"]) if row else 0


def add_credits(
    user_id: str,
    amount: int,
    *,
    reason: Optional[str] = None,
    transaction_id: Optional[str] = None,
) -> int:
    """Atomically adjust a user's chat-credit balance and append the ledger."""
    now = utc_now_iso()
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("BEGIN IMMEDIATE")
        cur.execute("SELECT balance FROM user_credits WHERE user_id=?", (user_id,))
        row = cur.fetchone()
        current = int(row["balance"]) if row else 0
        new_balance = max(0, current + amount)
        cur.execute(
            """INSERT INTO user_credits (user_id, balance, updated_at)
               VALUES (?, ?, ?)
               ON CONFLICT(user_id) DO UPDATE SET
                 balance = excluded.balance,
                 updated_at = excluded.updated_at""",
            (user_id, new_balance, now),
        )
        cur.execute(
            """INSERT INTO credit_ledger (user_id, delta, reason, transaction_id, created_at)
               VALUES (?, ?, ?, ?, ?)""",
            (user_id, new_balance - current, reason, transaction_id, now),
        )
        conn.commit()
    finally:
        conn.close()
    return new_balance


def consume_credit(user_id: str, *, reason: Optional[str] = None) -> bool:
    """Atomically spend one credit, returning whether a credit was available."""
    now = utc_now_iso()
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "UPDATE user_credits SET balance = balance - 1, updated_at=? WHERE user_id=? AND balance > 0",
            (now, user_id),
        )
        if cur.rowcount != 1:
            conn.rollback()
            return False
        cur.execute(
            """INSERT INTO credit_ledger (user_id, delta, reason, transaction_id, created_at)
               VALUES (?, ?, ?, ?, ?)""",
            (user_id, -1, reason or "chat_consume", None, now),
        )
        conn.commit()
        return True
    finally:
        conn.close()


# Birth data helpers
def get_user_birth_data(user_id: Optional[str]) -> Optional[dict]:
    """Get user's birth data for personalized astrology."""
    if not user_id:
        return None
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT birth_date, birth_time, timezone, latitude, longitude, location_name FROM user_birth_data WHERE user_id=?",
        (user_id,),
    )
    row = cur.fetchone()
    conn.close()
    if not row:
        return None
    return {
        "birth_date": row["birth_date"],
        "birth_time": row["birth_time"],
        "timezone": row["timezone"],
        "latitude": row["latitude"],
        "longitude": row["longitude"],
        "location_name": row["location_name"],
    }


def upsert_user_birth_data(
    user_id: str,
    birth_date: str,
    birth_time: Optional[str] = None,
    timezone: Optional[str] = None,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    location_name: Optional[str] = None,
):
    """Store or update user's birth data."""
    now = utc_now_iso()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT user_id FROM user_birth_data WHERE user_id=?", (user_id,))
    if cur.fetchone():
        cur.execute(
            "UPDATE user_birth_data SET birth_date=?, birth_time=?, timezone=?, latitude=?, longitude=?, location_name=?, updated_at=? WHERE user_id=?",
            (birth_date, birth_time, timezone, latitude, longitude, location_name, now, user_id),
        )
    else:
        cur.execute(
            "INSERT INTO user_birth_data (user_id, birth_date, birth_time, timezone, latitude, longitude, location_name, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?,?)",
            (user_id, birth_date, birth_time, timezone, latitude, longitude, location_name, now, now),
        )
    conn.commit()
    conn.close()


# Relationship helpers for compatibility feature
def create_relationship(
    user_id: str,
    partner_name: str,
    partner_birth_date: str,
    partner_birth_time: Optional[str] = None,
    partner_timezone: Optional[str] = None,
    partner_latitude: Optional[float] = None,
    partner_longitude: Optional[float] = None,
    partner_location_name: Optional[str] = None,
    partner_avatar_url: Optional[str] = None,
) -> dict:
    """Create a new relationship for compatibility tracking."""
    import uuid

    relationship_id = str(uuid.uuid4())
    now = utc_now_iso()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO relationships
           (id, user_id, partner_name, partner_birth_date, partner_birth_time,
            partner_timezone, partner_latitude, partner_longitude, partner_location_name,
            partner_avatar_url, is_favorite, created_at, updated_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)""",
        (
            relationship_id,
            user_id,
            partner_name,
            partner_birth_date,
            partner_birth_time,
            partner_timezone,
            partner_latitude,
            partner_longitude,
            partner_location_name,
            partner_avatar_url,
            0,
            now,
            now,
        ),
    )
    conn.commit()
    conn.close()
    return get_relationship(relationship_id)


def get_relationship(relationship_id: str) -> Optional[dict]:
    """Get a single relationship by ID."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """SELECT id, user_id, partner_name, partner_birth_date, partner_birth_time,
                  partner_timezone, partner_latitude, partner_longitude, partner_location_name,
                  partner_avatar_url, is_favorite, last_viewed_at, created_at, updated_at
           FROM relationships WHERE id=?""",
        (relationship_id,),
    )
    row = cur.fetchone()
    conn.close()
    if not row:
        return None
    return {
        "id": row["id"],
        "userId": row["user_id"],
        "partnerName": row["partner_name"],
        "partnerBirthDate": row["partner_birth_date"],
        "partnerBirthTime": row["partner_birth_time"],
        "partnerTimezone": row["partner_timezone"],
        "partnerLatitude": row["partner_latitude"],
        "partnerLongitude": row["partner_longitude"],
        "partnerLocationName": row["partner_location_name"],
        "partnerAvatarUrl": row["partner_avatar_url"],
        "isFavorite": bool(row["is_favorite"]),
        "lastViewedAt": row["last_viewed_at"],
        "createdAt": row["created_at"],
        "updatedAt": row["updated_at"],
    }


def get_user_relationships(user_id: str) -> list[dict]:
    """Get all relationships for a user."""
    if not user_id:
        return []
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """SELECT id, user_id, partner_name, partner_birth_date, partner_birth_time,
                  partner_timezone, partner_latitude, partner_longitude, partner_location_name,
                  partner_avatar_url, is_favorite, last_viewed_at, created_at, updated_at
           FROM relationships
           WHERE user_id=?
           ORDER BY is_favorite DESC, updated_at DESC""",
        (user_id,),
    )
    rows = cur.fetchall()
    conn.close()
    return [
        {
            "id": row["id"],
            "userId": row["user_id"],
            "partnerName": row["partner_name"],
            "partnerBirthDate": row["partner_birth_date"],
            "partnerBirthTime": row["partner_birth_time"],
            "partnerTimezone": row["partner_timezone"],
            "partnerLatitude": row["partner_latitude"],
            "partnerLongitude": row["partner_longitude"],
            "partnerLocationName": row["partner_location_name"],
            "partnerAvatarUrl": row["partner_avatar_url"],
            "isFavorite": bool(row["is_favorite"]),
            "lastViewedAt": row["last_viewed_at"],
            "createdAt": row["created_at"],
            "updatedAt": row["updated_at"],
        }
        for row in rows
    ]


def delete_relationship(relationship_id: str, user_id: str) -> bool:
    """Delete a relationship (only if owned by user)."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "DELETE FROM relationships WHERE id=? AND user_id=?",
        (relationship_id, user_id),
    )
    deleted = cur.rowcount > 0
    conn.commit()
    conn.close()
    return deleted


def update_relationship_last_viewed(relationship_id: str) -> None:
    """Update the last_viewed_at timestamp for a relationship."""
    now = utc_now_iso()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "UPDATE relationships SET last_viewed_at=?, updated_at=? WHERE id=?",
        (now, now, relationship_id),
    )
    conn.commit()
    conn.close()


def delete_user_data(user_id: str) -> dict:
    """
    Delete all user data from all tables.
    Required for App Store compliance (Guideline 5.1.1).
    Returns a summary of deleted records.
    """
    if not user_id:
        return {"error": "user_id required", "deleted": False}

    conn = get_connection()
    cur = conn.cursor()
    deleted_counts = {}

    cur.execute("SELECT id FROM pooja_bookings WHERE user_id=?", (user_id,))
    pooja_booking_ids = [row["id"] for row in cur.fetchall()]

    pooja_session_ids = []
    if pooja_booking_ids:
        placeholders = ",".join("?" for _ in pooja_booking_ids)
        cur.execute(f"SELECT id FROM pooja_sessions WHERE booking_id IN ({placeholders})", pooja_booking_ids)
        pooja_session_ids = [row["id"] for row in cur.fetchall()]

        context_ids = pooja_booking_ids + pooja_session_ids
        context_placeholders = ",".join("?" for _ in context_ids)
        cur.execute(
            f"DELETE FROM contact_filter_logs WHERE sender_id=? OR context_id IN ({context_placeholders})",
            [user_id, *context_ids],
        )
        deleted_counts["contact_filter_logs"] = cur.rowcount

        cur.execute(f"DELETE FROM pooja_sessions WHERE booking_id IN ({placeholders})", pooja_booking_ids)
        deleted_counts["pooja_sessions"] = cur.rowcount
    else:
        cur.execute("DELETE FROM contact_filter_logs WHERE sender_id=?", (user_id,))
        deleted_counts["contact_filter_logs"] = cur.rowcount
        deleted_counts["pooja_sessions"] = 0

    # Keep the transaction ID/product/kind claim as a replay tombstone while
    # removing its direct account identifier. A deleted/re-registered account
    # must never be able to deliver the same signed purchase again.
    now = utc_now_iso()
    cur.execute(
        """UPDATE storekit_transaction_ledger
           SET user_id=NULL, tombstoned_at=?
           WHERE user_id=?""",
        (now, user_id),
    )
    deleted_counts["storekit_transaction_ledger_anonymized"] = cur.rowcount

    # Delete from all remaining tables that reference user_id.
    tables_to_clean = [
        ("oracle_credit_balances", "user_id"),
        ("report_purchase_entitlements", "user_id"),
        ("user_temple_activity", "user_id"),
        ("pooja_bookings", "user_id"),  # Temple/Pooja bookings
        ("relationships", "user_id"),
        ("chat_messages", "user_id"),
        ("chat_conversations", "user_id"),
        ("reports", "user_id"),
        ("subscription_status", "user_id"),
        ("processed_transactions", "user_id"),
        ("user_credits", "user_id"),
        ("credit_ledger", "user_id"),
        ("user_birth_data", "user_id"),
        ("users", "id"),
    ]

    for table, id_column in tables_to_clean:
        # Tables created by later migrations may be absent in older databases;
        # skip cleanly rather than aborting the whole deletion.
        try:
            cur.execute(f"DELETE FROM {table} WHERE {id_column}=?", (user_id,))
            deleted_counts[table] = cur.rowcount
        except sqlite3.OperationalError:
            deleted_counts[table] = 0

    conn.commit()
    conn.close()

    return {
        "deleted": True,
        "userId": user_id,
        "deletedRecords": deleted_counts,
    }

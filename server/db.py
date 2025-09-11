import os
import sqlite3
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), 'astronova.db')


def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_connection()
    cur = conn.cursor()
    # Users table (very minimal)
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT,
            first_name TEXT,
            last_name TEXT,
            full_name TEXT,
            created_at TEXT,
            updated_at TEXT
        )
        """
    )
    # Reports table (minimal)
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS reports (
            report_id TEXT PRIMARY KEY,
            user_id TEXT,
            type TEXT,
            title TEXT,
            content TEXT,
            generated_at TEXT,
            status TEXT
        )
        """
    )
    # Content: quick questions
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS content_quick_questions (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            category TEXT,
            order_index INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
        )
        """
    )
    # Content: insights
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS content_insights (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT,
            priority INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
        )
        """
    )
    # Chat: conversations and messages
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS chat_conversations (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            created_at TEXT,
            updated_at TEXT
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS chat_messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT,
            user_id TEXT,
            role TEXT,
            content TEXT,
            created_at TEXT
        )
        """
    )
    # Subscription status (very minimal)
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS subscription_status (
            user_id TEXT PRIMARY KEY,
            is_active INTEGER DEFAULT 0,
            product_id TEXT,
            updated_at TEXT
        )
        """
    )
    conn.commit()

    # Seed content tables with defaults if empty
    def _seed_content():
        cur.execute("SELECT COUNT(*) AS c FROM content_quick_questions")
        if (cur.fetchone()[0] or 0) == 0:
            defaults_q = [
                ("q1", "What's my love forecast? 💖", "love", 1, 1),
                ("q2", "Career guidance? ⭐", "career", 2, 1),
                ("q3", "Today's energy? ☀️", "daily", 3, 1),
                ("q4", "What should I focus on? 🎯", "guidance", 4, 1),
                ("q5", "Lucky numbers today? 🍀", "daily", 5, 1),
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

    _seed_content()
    conn.commit()
    conn.close()


def upsert_user(user_id: str, email: str | None, first_name: str | None, last_name: str | None, full_name: str):
    now = datetime.utcnow().isoformat()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT id FROM users WHERE id=?", (user_id,))
    if cur.fetchone():
        cur.execute(
            "UPDATE users SET email=?, first_name=?, last_name=?, full_name=?, updated_at=? WHERE id=?",
            (email, first_name, last_name, full_name, now, user_id),
        )
    else:
        cur.execute(
            "INSERT INTO users (id, email, first_name, last_name, full_name, created_at, updated_at) VALUES (?,?,?,?,?,?,?)",
            (user_id, email, first_name, last_name, full_name, now, now),
        )
    conn.commit()
    conn.close()


def insert_report(report_id: str, user_id: str | None, type_: str, title: str, content: str, status: str = 'completed'):
    now = datetime.utcnow().isoformat()
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


# Content accessors
def get_content_management() -> dict:
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT id, text, category, order_index as order_idx, is_active FROM content_quick_questions ORDER BY order_index ASC"
    )
    quick_questions = []
    for r in cur.fetchall():
        quick_questions.append({
            'id': r['id'],
            'text': r['text'],
            'category': r['category'],
            'order': r['order_idx'],
            'is_active': bool(r['is_active']),
        })
    cur.execute(
        "SELECT id, title, content, category, priority, is_active FROM content_insights ORDER BY priority ASC"
    )
    insights = []
    for r in cur.fetchall():
        insights.append({
            'id': r['id'],
            'title': r['title'],
            'content': r['content'],
            'category': r['category'],
            'priority': r['priority'],
            'is_active': bool(r['is_active']),
        })
    conn.close()
    return {'quick_questions': quick_questions, 'insights': insights}


# Chat persistence helpers
def ensure_conversation(conversation_id: str | None, user_id: str | None) -> str:
    conn = get_connection()
    cur = conn.cursor()
    now = datetime.utcnow().isoformat()
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


def add_chat_message(conversation_id: str, role: str, content: str, user_id: str | None = None) -> str:
    import uuid
    message_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()
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


# Subscription helpers
def get_subscription(user_id: str | None) -> dict:
    if not user_id:
        return {'isActive': False}
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT is_active, product_id, updated_at FROM subscription_status WHERE user_id=?",
        (user_id,),
    )
    row = cur.fetchone()
    conn.close()
    if not row:
        return {'isActive': False}
    return {
        'isActive': bool(row['is_active']),
        'productId': row['product_id'],
        'updatedAt': row['updated_at'],
    }

def set_subscription(user_id: str, is_active: bool, product_id: str | None = None):
    now = datetime.utcnow().isoformat()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT user_id FROM subscription_status WHERE user_id=?", (user_id,))
    if cur.fetchone():
        cur.execute(
            "UPDATE subscription_status SET is_active=?, product_id=?, updated_at=? WHERE user_id=?",
            (1 if is_active else 0, product_id, now, user_id),
        )
    else:
        cur.execute(
            "INSERT INTO subscription_status (user_id, is_active, product_id, updated_at) VALUES (?,?,?,?)",
            (user_id, 1 if is_active else 0, product_id, now),
        )
    conn.commit()
    conn.close()

#!/usr/bin/env python3
"""
Admin script to grant Pro access to a user account.
Usage: python admin_grant_pro.py <email>
Example: python admin_grant_pro.py sankalphimself@gmail.com
"""

import sys
import sqlite3
from datetime import datetime

ASTRONOVA_PRO_PRODUCT_ID = "astronova_pro_monthly"

def grant_pro_access(email: str, db_path: str = "astronova.db"):
    """Grant Pro subscription to user by email."""

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # Find user by email
    cur.execute("SELECT id, email, full_name FROM users WHERE email = ?", (email,))
    user = cur.fetchone()

    if not user:
        print(f"❌ User not found with email: {email}")
        conn.close()
        return False

    user_id = user["id"]
    full_name = user["full_name"] or "User"
    print(f"✅ Found user: {full_name} (ID: {user_id})")

    # Update or insert subscription status
    now = datetime.utcnow().isoformat()

    cur.execute("SELECT user_id FROM subscription_status WHERE user_id = ?", (user_id,))
    existing = cur.fetchone()

    if existing:
        cur.execute("""
            UPDATE subscription_status
            SET is_active = 1,
                product_id = ?,
                updated_at = ?
            WHERE user_id = ?
        """, (ASTRONOVA_PRO_PRODUCT_ID, now, user_id))
        print(f"✅ Updated existing subscription to Pro")
    else:
        cur.execute("""
            INSERT INTO subscription_status (user_id, is_active, product_id, updated_at)
            VALUES (?, 1, ?, ?)
        """, (user_id, ASTRONOVA_PRO_PRODUCT_ID, now))
        print(f"✅ Created new Pro subscription")

    conn.commit()

    # Verify
    cur.execute("SELECT is_active, product_id FROM subscription_status WHERE user_id = ?", (user_id,))
    sub = cur.fetchone()

    if sub and sub["is_active"]:
        print(f"✅ Pro access granted successfully!")
        print(f"   Product ID: {sub['product_id']}")
        print(f"   Status: Active")
    else:
        print(f"❌ Verification failed - subscription not active")
        conn.close()
        return False

    conn.close()
    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python admin_grant_pro.py <email>")
        print("Example: python admin_grant_pro.py sankalphimself@gmail.com")
        sys.exit(1)

    email = sys.argv[1]
    print(f"🔧 Granting Pro access to: {email}")
    print()

    success = grant_pro_access(email)

    if success:
        print()
        print("✨ Done! User now has Pro access with all features:")
        print("   • Unlimited AI Oracle chat")
        print("   • Complete birth chart reports")
        print("   • Full Dasha timeline access")
        print("   • Compatibility analysis")
        print("   • Temple/Pooja bookings")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()

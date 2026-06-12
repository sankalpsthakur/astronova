"""Tests for server-authoritative App Store payment verification.

These build a throwaway EC certificate chain (root -> intermediate -> leaf),
sign JWS payloads with the leaf key exactly as StoreKit 2 / App Store Server
Notifications do, and inject the test root as the trusted anchor. This lets us
exercise the full cryptographic verification path without contacting Apple.
"""

from __future__ import annotations

import base64
from datetime import datetime, timedelta, timezone

import jwt as pyjwt
import pytest
from cryptography import x509
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import Encoding
from cryptography.x509.oid import NameOID

import db as db_module
from services.appstore_verification import (
    AppStoreVerificationError,
    verify_notification,
    verify_signed_jws,
)

BUNDLE_ID = "com.astronova.app"


def _make_cert(subject_name, issuer_cert, issuer_key, *, is_ca, not_before=None, not_after=None):
    key = ec.generate_private_key(ec.SECP256R1())
    subject = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, subject_name)])
    issuer = issuer_cert.subject if issuer_cert else subject
    signing_key = issuer_key or key
    now = datetime.now(timezone.utc)
    builder = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(not_before or (now - timedelta(days=1)))
        .not_valid_after(not_after or (now + timedelta(days=365)))
        .add_extension(x509.BasicConstraints(ca=is_ca, path_length=None), critical=True)
    )
    cert = builder.sign(signing_key, hashes.SHA256())
    return cert, key


@pytest.fixture(scope="module")
def cert_chain():
    """root -> intermediate -> leaf, plus an untrusted alternate root."""
    root_cert, root_key = _make_cert("Test Apple Root CA G3", None, None, is_ca=True)
    inter_cert, inter_key = _make_cert("Test Apple Intermediate", root_cert, root_key, is_ca=True)
    leaf_cert, leaf_key = _make_cert("Test Apple Leaf", inter_cert, inter_key, is_ca=False)
    other_root_cert, _ = _make_cert("Untrusted Root", None, None, is_ca=True)
    return {
        "root": root_cert,
        "leaf_cert": leaf_cert,
        "leaf_key": leaf_key,
        "chain": [leaf_cert, inter_cert, root_cert],
        "other_root": other_root_cert,
    }


def _x5c(chain):
    return [base64.b64encode(c.public_bytes(Encoding.DER)).decode() for c in chain]


def _sign(payload, chain, leaf_key):
    return pyjwt.encode(
        payload,
        leaf_key,
        algorithm="ES256",
        headers={"x5c": _x5c(chain), "alg": "ES256"},
    )


def _tx_payload(**overrides):
    base = {
        "transactionId": "txn-1",
        "originalTransactionId": "orig-1",
        "productId": "astronova_pro_monthly",
        "bundleId": BUNDLE_ID,
        "environment": "Sandbox",
        "expiresDate": int((datetime.now(timezone.utc) + timedelta(days=30)).timestamp() * 1000),
    }
    base.update(overrides)
    return base


# ---------------------------------------------------------------------------
# Verification primitive
# ---------------------------------------------------------------------------


def test_verify_valid_chain(cert_chain):
    token = _sign(_tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    payload = verify_signed_jws(token, trusted_roots=[cert_chain["root"]])
    assert payload["productId"] == "astronova_pro_monthly"


def test_verify_rejects_untrusted_root(cert_chain):
    token = _sign(_tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    with pytest.raises(AppStoreVerificationError):
        verify_signed_jws(token, trusted_roots=[cert_chain["other_root"]])


def test_verify_rejects_tampered_payload(cert_chain):
    token = _sign(_tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    header_b64, payload_b64, sig = token.split(".")
    # Flip a byte in the payload segment.
    forged_payload = base64.urlsafe_b64encode(b'{"productId":"hacked"}').rstrip(b"=").decode()
    tampered = f"{header_b64}.{forged_payload}.{sig}"
    with pytest.raises(AppStoreVerificationError):
        verify_signed_jws(tampered, trusted_roots=[cert_chain["root"]])


def test_verify_requires_configured_root(cert_chain, monkeypatch):
    monkeypatch.delenv("APPLE_ROOT_CA_PEM", raising=False)
    monkeypatch.delenv("APPLE_ROOT_CA_PATH", raising=False)
    token = _sign(_tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    # No trusted root configured at all -> fail closed.
    with pytest.raises(AppStoreVerificationError):
        verify_signed_jws(token)


def test_verify_rejects_malformed_token(cert_chain):
    with pytest.raises(AppStoreVerificationError):
        verify_signed_jws("not-a-jws", trusted_roots=[cert_chain["root"]])


# ---------------------------------------------------------------------------
# /payments/verify endpoint
# ---------------------------------------------------------------------------


def _set_root_env(monkeypatch, cert_chain):
    pem = cert_chain["root"].public_bytes(Encoding.PEM).decode()
    monkeypatch.setenv("APPLE_ROOT_CA_PEM", pem)


def test_verify_endpoint_grants_subscription(authenticated_client, sample_user, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    token = _sign(_tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])

    resp = authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    assert resp.status_code == 200, resp.get_json()
    data = resp.get_json()
    assert data["granted"]["type"] == "subscription"
    assert data["entitlement"]["hasPremium"] is True
    assert db_module.get_premium_entitlement(sample_user["id"])["hasPremium"] is True


def test_verify_endpoint_grants_credits(authenticated_client, sample_user, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    token = _sign(
        _tx_payload(productId="chat_credits_5", transactionId="txn-credits", expiresDate=None),
        cert_chain["chain"],
        cert_chain["leaf_key"],
    )
    resp = authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    assert resp.status_code == 200, resp.get_json()
    assert resp.get_json()["granted"]["balance"] == 50
    assert db_module.get_credit_balance(sample_user["id"]) == 50


def test_verify_endpoint_is_idempotent_for_credits(authenticated_client, sample_user, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    token = _sign(
        _tx_payload(productId="chat_credits_5", transactionId="txn-dupe", expiresDate=None),
        cert_chain["chain"],
        cert_chain["leaf_key"],
    )
    authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    # Replaying the same transaction must not double-credit.
    assert db_module.get_credit_balance(sample_user["id"]) == 50


def test_verify_endpoint_rejects_bundle_mismatch(authenticated_client, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    token = _sign(_tx_payload(bundleId="com.someone.else"), cert_chain["chain"], cert_chain["leaf_key"])
    resp = authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    assert resp.status_code == 400
    assert resp.get_json()["code"] == "BUNDLE_MISMATCH"


def test_verify_endpoint_rejects_forged_receipt(authenticated_client, sample_user, cert_chain, monkeypatch):
    # Trust only the real test root, but sign with an attacker chain.
    _set_root_env(monkeypatch, cert_chain)
    attacker_root, attacker_root_key = _make_cert("Attacker Root", None, None, is_ca=True)
    attacker_leaf, attacker_leaf_key = _make_cert("Attacker Leaf", attacker_root, attacker_root_key, is_ca=False)
    token = _sign(_tx_payload(), [attacker_leaf, attacker_root], attacker_leaf_key)
    resp = authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    assert resp.status_code == 400
    assert resp.get_json()["code"] == "VERIFICATION_FAILED"
    assert db_module.get_premium_entitlement(sample_user["id"])["hasPremium"] is False


def test_verify_endpoint_requires_auth(client, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    token = _sign(_tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    resp = client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    assert resp.status_code == 401


def test_credits_endpoint_returns_balance(authenticated_client, sample_user):
    db_module.add_credits(sample_user["id"], 30, reason="test")
    resp = authenticated_client.get("/api/v1/payments/credits")
    assert resp.status_code == 200
    assert resp.get_json()["balance"] == 30


def test_report_purchase_unlocks_that_domain(authenticated_client, sample_user, cert_chain, monkeypatch):
    """Buying report_love lets the user generate a love report without Pro."""
    _set_root_env(monkeypatch, cert_chain)

    # Without any entitlement, report generation is gated.
    def fail_generate(*_a, **_k):
        raise AssertionError("should not generate without entitlement")

    monkeypatch.setattr("routes.reports._report_service.generate", fail_generate)
    birth = {"date": "1990-01-15", "time": "14:30", "timezone": "Asia/Kolkata", "latitude": 19.076, "longitude": 72.8777}
    gated = authenticated_client.post(
        "/api/v1/reports/generate", json={"reportType": "love", "domain": "love", "birthData": birth}
    )
    assert gated.status_code == 402

    # Verify a report_love purchase.
    token = _sign(
        _tx_payload(productId="report_love", transactionId="txn-report-love", expiresDate=None),
        cert_chain["chain"],
        cert_chain["leaf_key"],
    )
    vr = authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    assert vr.status_code == 200
    assert db_module.has_report_entitlement(sample_user["id"], "love") is True

    # Now generation for that domain is allowed (and a different domain is not).
    assert db_module.has_report_entitlement(sample_user["id"], "career") is False


# ---------------------------------------------------------------------------
# /payments/notifications webhook (refund revokes access)
# ---------------------------------------------------------------------------


def _notification(ntype, tx_payload, chain, leaf_key, renewal_payload=None):
    signed_tx = _sign(tx_payload, chain, leaf_key)
    data = {"signedTransactionInfo": signed_tx, "environment": "Sandbox", "bundleId": BUNDLE_ID}
    if renewal_payload is not None:
        data["signedRenewalInfo"] = _sign(renewal_payload, chain, leaf_key)
    outer = {"notificationType": ntype, "notificationUUID": "uuid-1", "data": data}
    return _sign(outer, chain, leaf_key)


def test_notification_refund_revokes_access(authenticated_client, sample_user, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    # First establish an active subscription via a verified purchase.
    purchase = _sign(_tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": purchase})
    assert db_module.get_premium_entitlement(sample_user["id"])["hasPremium"] is True

    # Apple sends a REFUND notification for the same originalTransactionId.
    note = _notification("REFUND", _tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    resp = authenticated_client.post("/api/v1/payments/notifications", json={"signedPayload": note})
    assert resp.status_code == 200, resp.get_json()
    assert resp.get_json()["action"] == "revoked"
    assert db_module.get_premium_entitlement(sample_user["id"])["hasPremium"] is False


def test_notification_unknown_subscription_is_acknowledged(authenticated_client, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    note = _notification(
        "DID_RENEW",
        _tx_payload(originalTransactionId="never-seen"),
        cert_chain["chain"],
        cert_chain["leaf_key"],
    )
    resp = authenticated_client.post("/api/v1/payments/notifications", json={"signedPayload": note})
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ignored"


def test_notification_rejects_unverified_payload(authenticated_client, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    attacker_root, attacker_root_key = _make_cert("Attacker Root", None, None, is_ca=True)
    attacker_leaf, attacker_leaf_key = _make_cert("Attacker Leaf", attacker_root, attacker_root_key, is_ca=False)
    note = _notification("REFUND", _tx_payload(), [attacker_leaf, attacker_root], attacker_leaf_key)
    resp = authenticated_client.post("/api/v1/payments/notifications", json={"signedPayload": note})
    assert resp.status_code == 400
    assert resp.get_json()["code"] == "VERIFICATION_FAILED"


# ---------------------------------------------------------------------------
# Notification subtypes, expiry lapse, idempotency, malformed payloads
# ---------------------------------------------------------------------------


def _establish_subscription(authenticated_client, cert_chain):
    purchase = _sign(_tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": purchase})


def test_notification_did_renew_keeps_active_and_extends(authenticated_client, sample_user, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    _establish_subscription(authenticated_client, cert_chain)
    future = int((datetime.now(timezone.utc) + timedelta(days=60)).timestamp() * 1000)
    note = _notification("DID_RENEW", _tx_payload(expiresDate=future), cert_chain["chain"], cert_chain["leaf_key"])
    resp = authenticated_client.post("/api/v1/payments/notifications", json={"signedPayload": note})
    assert resp.status_code == 200
    assert resp.get_json()["action"] == "updated"
    assert db_module.get_premium_entitlement(sample_user["id"])["hasPremium"] is True


def test_notification_expired_revokes(authenticated_client, sample_user, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    _establish_subscription(authenticated_client, cert_chain)
    note = _notification("EXPIRED", _tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    resp = authenticated_client.post("/api/v1/payments/notifications", json={"signedPayload": note})
    assert resp.status_code == 200
    assert resp.get_json()["action"] == "revoked"
    assert db_module.get_premium_entitlement(sample_user["id"])["hasPremium"] is False


def test_notification_grace_period_expired_revokes(authenticated_client, sample_user, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    _establish_subscription(authenticated_client, cert_chain)
    note = _notification("GRACE_PERIOD_EXPIRED", _tx_payload(), cert_chain["chain"], cert_chain["leaf_key"])
    resp = authenticated_client.post("/api/v1/payments/notifications", json={"signedPayload": note})
    assert resp.status_code == 200
    assert db_module.get_premium_entitlement(sample_user["id"])["hasPremium"] is False


def test_subscription_lapses_at_expiry(sample_user, clean_db):
    """A subscription flagged active but past its expiry must read as inactive."""
    past = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
    db_module.set_subscription_from_transaction(
        sample_user["id"],
        is_active=True,
        product_id="astronova_pro_monthly",
        expires_at=past,
        original_transaction_id="orig-lapse",
        latest_transaction_id="tx-lapse",
        environment="Sandbox",
        auto_renew=True,
    )
    assert db_module.get_subscription(sample_user["id"])["isActive"] is False
    assert db_module.get_premium_entitlement(sample_user["id"])["hasPremium"] is False


def test_verify_credits_idempotent_ledger_net(authenticated_client, sample_user, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    token = _sign(
        _tx_payload(productId="chat_credits_5", transactionId="txn-ledger", expiresDate=None),
        cert_chain["chain"],
        cert_chain["leaf_key"],
    )
    authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    conn = db_module.get_connection()
    total = conn.execute("SELECT COALESCE(SUM(delta),0) FROM credit_ledger WHERE user_id=?", (sample_user["id"],)).fetchone()[0]
    conn.close()
    assert total == 50  # not 100


def test_credit_double_spend_prevented_under_concurrency(sample_user, clean_db):
    from concurrent.futures import ThreadPoolExecutor

    db_module.add_credits(sample_user["id"], 2, reason="test")
    results = []

    def consume():
        results.append(db_module.consume_credit(sample_user["id"], reason="concurrent"))

    with ThreadPoolExecutor(max_workers=8) as ex:
        for f in [ex.submit(consume) for _ in range(8)]:
            f.result()

    assert sum(1 for r in results if r) == 2
    assert db_module.get_credit_balance(sample_user["id"]) == 0


def test_verify_rejects_empty_and_nonstring_payload(authenticated_client, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    for bad in ({"signedTransaction": ""}, {"signedTransaction": 123}, {}):
        resp = authenticated_client.post("/api/v1/payments/verify", json=bad)
        assert resp.status_code == 400


def test_notifications_rejects_empty_payload(authenticated_client, cert_chain, monkeypatch):
    _set_root_env(monkeypatch, cert_chain)
    resp = authenticated_client.post("/api/v1/payments/notifications", json={"signedPayload": ""})
    assert resp.status_code == 400


def test_verify_rejects_missing_x5c(authenticated_client, cert_chain, monkeypatch):
    import jwt as pyjwt

    _set_root_env(monkeypatch, cert_chain)
    # Sign with the leaf key but omit the x5c chain header entirely.
    token = pyjwt.encode(_tx_payload(), cert_chain["leaf_key"], algorithm="ES256")
    resp = authenticated_client.post("/api/v1/payments/verify", json={"signedTransaction": token})
    assert resp.status_code == 400
    assert resp.get_json()["code"] == "VERIFICATION_FAILED"


def test_concurrent_replay_of_same_transaction_grants_once(sample_user, clean_db):
    """Two simultaneous /verify submissions of one transaction must not
    double-credit: the processed_transactions PK insert is the gate."""
    from concurrent.futures import ThreadPoolExecutor

    from routes.payments import _apply_transaction

    tx = {
        "productId": "chat_credits_5",
        "transactionId": "txn-race",
        "environment": "Sandbox",
    }

    with ThreadPoolExecutor(max_workers=8) as ex:
        for f in [ex.submit(_apply_transaction, sample_user["id"], dict(tx)) for _ in range(8)]:
            f.result()

    assert db_module.get_credit_balance(sample_user["id"]) == 50
    conn = db_module.get_connection()
    total = conn.execute(
        "SELECT COALESCE(SUM(delta),0) FROM credit_ledger WHERE user_id=?",
        (sample_user["id"],),
    ).fetchone()[0]
    conn.close()
    assert total == 50


def test_concurrent_add_credits_all_land(sample_user, clean_db):
    """Concurrent grants must accumulate, not overwrite each other."""
    from concurrent.futures import ThreadPoolExecutor

    with ThreadPoolExecutor(max_workers=8) as ex:
        for f in [ex.submit(db_module.add_credits, sample_user["id"], 10, reason="race") for _ in range(8)]:
            f.result()

    assert db_module.get_credit_balance(sample_user["id"]) == 80


def test_malformed_expiry_fails_closed(sample_user, clean_db):
    """An unparseable expires_at must lapse the subscription, not grant
    indefinite access."""
    db_module.set_subscription_from_transaction(
        sample_user["id"],
        is_active=True,
        product_id="astronova_pro_monthly",
        expires_at="not-a-date",
        original_transaction_id="orig-bad-expiry",
        latest_transaction_id="tx-bad-expiry",
        environment="Sandbox",
        auto_renew=True,
    )
    assert db_module.get_subscription(sample_user["id"])["isActive"] is False

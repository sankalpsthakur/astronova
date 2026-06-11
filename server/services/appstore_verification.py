"""Verification of Apple App Store signed payloads (StoreKit 2 / ASSN v2).

StoreKit 2 ``Transaction.jwsRepresentation`` values and App Store Server
Notifications V2 ``signedPayload`` are JWS (JSON Web Signature) compact tokens
signed with ES256. The JWS protected header carries an ``x5c`` certificate
chain ``[leaf, intermediate, root]``. To trust a payload we must:

1. Parse the x5c chain.
2. Verify each certificate was signed by the next one up the chain.
3. Verify the chain terminates in a *trusted* Apple root certificate.
4. Verify the certificates are within their validity window.
5. Verify the JWS signature using the leaf certificate's public key.

Only then is the decoded payload trustworthy. This module fails closed: if no
trusted Apple root is configured it raises rather than accepting an unverified
payload, so a misconfiguration can never silently grant entitlements.

The trusted root(s) are configurable (constructor argument or the
``APPLE_ROOT_CA_PEM`` / ``APPLE_ROOT_CA_PATH`` environment variables) so the
verifier can be unit-tested with a self-signed test CA without contacting Apple.
"""

from __future__ import annotations

import base64
import logging
import os
from datetime import datetime, timezone
from typing import Optional

import jwt
from cryptography import x509
from cryptography.hazmat.primitives.asymmetric import ec, padding, rsa
from cryptography.hazmat.primitives.serialization import Encoding

logger = logging.getLogger(__name__)


class AppStoreVerificationError(Exception):
    """Raised when a signed App Store payload cannot be trusted."""


def _b64url_to_der(value: str) -> bytes:
    # x5c entries are standard base64 (not base64url) DER certificates.
    return base64.b64decode(value)


def _load_trusted_roots(explicit_pem: Optional[str] = None) -> list[x509.Certificate]:
    """Resolve the set of trusted Apple root certificates.

    Precedence: explicit PEM argument, ``APPLE_ROOT_CA_PEM`` env (inline PEM),
    ``APPLE_ROOT_CA_PATH`` env (file path). Multiple PEM blocks are allowed.
    """
    pem_data: Optional[bytes] = None
    if explicit_pem:
        pem_data = explicit_pem.encode() if isinstance(explicit_pem, str) else explicit_pem
    elif os.environ.get("APPLE_ROOT_CA_PEM"):
        pem_data = os.environ["APPLE_ROOT_CA_PEM"].encode()
    elif os.environ.get("APPLE_ROOT_CA_PATH"):
        path = os.environ["APPLE_ROOT_CA_PATH"]
        try:
            with open(path, "rb") as fh:
                pem_data = fh.read()
        except OSError as exc:
            raise AppStoreVerificationError(
                f"Configured APPLE_ROOT_CA_PATH could not be read: {exc}"
            ) from exc

    if not pem_data:
        raise AppStoreVerificationError(
            "No trusted Apple root certificate configured. Set APPLE_ROOT_CA_PEM "
            "or APPLE_ROOT_CA_PATH (Apple Root CA - G3) to verify App Store "
            "payloads. Refusing to trust an unverified receipt."
        )

    return x509.load_pem_x509_certificates(pem_data)


def _verify_signed_by(child: x509.Certificate, issuer: x509.Certificate) -> None:
    """Verify ``child`` was signed by ``issuer``'s key, else raise."""
    issuer_key = issuer.public_key()
    try:
        if isinstance(issuer_key, ec.EllipticCurvePublicKey):
            issuer_key.verify(
                child.signature,
                child.tbs_certificate_bytes,
                ec.ECDSA(child.signature_hash_algorithm),
            )
        elif isinstance(issuer_key, rsa.RSAPublicKey):
            issuer_key.verify(
                child.signature,
                child.tbs_certificate_bytes,
                padding.PKCS1v15(),
                child.signature_hash_algorithm,
            )
        else:  # pragma: no cover - Apple only uses EC/RSA
            raise AppStoreVerificationError("Unsupported issuer key type in certificate chain")
    except AppStoreVerificationError:
        raise
    except Exception as exc:  # signature mismatch
        raise AppStoreVerificationError(f"Certificate chain signature invalid: {exc}") from exc


def _within_validity(cert: x509.Certificate, now: datetime) -> bool:
    not_before = cert.not_valid_before_utc
    not_after = cert.not_valid_after_utc
    return not_before <= now <= not_after


def verify_signed_jws(
    token: str,
    *,
    trusted_roots: Optional[list[x509.Certificate]] = None,
    trusted_root_pem: Optional[str] = None,
    now: Optional[datetime] = None,
) -> dict:
    """Verify an Apple JWS compact token and return its decoded payload.

    Raises AppStoreVerificationError if the chain, root trust, validity window,
    or signature fail.
    """
    if not token or not isinstance(token, str) or token.count(".") != 2:
        raise AppStoreVerificationError("Malformed JWS token")

    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=timezone.utc)

    if trusted_roots is None:
        trusted_roots = _load_trusted_roots(trusted_root_pem)

    try:
        header = jwt.get_unverified_header(token)
    except Exception as exc:
        raise AppStoreVerificationError(f"Unreadable JWS header: {exc}") from exc

    x5c = header.get("x5c")
    if not x5c or not isinstance(x5c, list):
        raise AppStoreVerificationError("JWS header missing x5c certificate chain")

    try:
        chain = [x509.load_der_x509_certificate(_b64url_to_der(c)) for c in x5c]
    except Exception as exc:
        raise AppStoreVerificationError(f"Invalid certificate in x5c chain: {exc}") from exc

    if len(chain) < 2:
        raise AppStoreVerificationError("Certificate chain too short")

    leaf = chain[0]
    presented_root = chain[-1]

    # Validity window for every certificate in the chain.
    for cert in chain:
        if not _within_validity(cert, now):
            raise AppStoreVerificationError("Certificate in chain is expired or not yet valid")

    # Each certificate must be signed by the next one up.
    for i in range(len(chain) - 1):
        _verify_signed_by(chain[i], chain[i + 1])

    # The presented root must be one we trust, and must be self-consistent
    # (the trusted copy verifies the presented root's signature / matches it).
    trusted_match = None
    presented_root_der = presented_root.public_bytes(encoding=Encoding.DER)
    for anchor in trusted_roots:
        if anchor.public_bytes(encoding=Encoding.DER) == presented_root_der:
            trusted_match = anchor
            break
    if trusted_match is None:
        raise AppStoreVerificationError("Certificate chain does not terminate in a trusted Apple root")

    # Finally verify the JWS signature with the leaf public key.
    leaf_key = leaf.public_key()
    try:
        payload = jwt.decode(
            token,
            leaf_key,
            algorithms=["ES256"],
            options={"verify_aud": False, "verify_exp": False, "verify_signature": True},
        )
    except Exception as exc:
        raise AppStoreVerificationError(f"JWS signature verification failed: {exc}") from exc

    return payload


# ---------------------------------------------------------------------------
# Higher-level helpers for the two payload shapes we consume.
# ---------------------------------------------------------------------------


def verify_transaction(token: str, **kwargs) -> dict:
    """Verify a StoreKit 2 signed transaction (JWSTransaction) payload."""
    return verify_signed_jws(token, **kwargs)


def verify_notification(token: str, **kwargs) -> dict:
    """Verify an App Store Server Notification V2 ``signedPayload``.

    Returns a dict with the decoded notification plus the *verified* nested
    transaction/renewal info (each is itself a signed JWS).
    """
    decoded = verify_signed_jws(token, **kwargs)
    data = decoded.get("data") or {}

    result = {
        "notificationType": decoded.get("notificationType"),
        "subtype": decoded.get("subtype"),
        "notificationUUID": decoded.get("notificationUUID"),
        "data": data,
        "transactionInfo": None,
        "renewalInfo": None,
    }

    signed_tx = data.get("signedTransactionInfo")
    if signed_tx:
        result["transactionInfo"] = verify_signed_jws(signed_tx, **kwargs)
    signed_renewal = data.get("signedRenewalInfo")
    if signed_renewal:
        result["renewalInfo"] = verify_signed_jws(signed_renewal, **kwargs)

    return result

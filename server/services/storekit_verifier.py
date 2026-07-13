"""StoreKit signed transaction verification.

Production sync endpoints must not trust client-supplied product or
transaction IDs. They accept Apple's signed transaction JWS and validate it
before mutating server-side entitlements.
"""

from __future__ import annotations

import base64
import os
from pathlib import Path
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

import jwt
from cryptography import x509
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec, padding
from cryptography.x509.oid import NameOID


class StoreKitVerificationError(ValueError):
    """Raised when a StoreKit signed transaction cannot be trusted."""


@dataclass(frozen=True)
class VerifiedStoreKitTransaction:
    product_id: str
    transaction_id: str
    original_transaction_id: str | None
    environment: str | None
    bundle_id: str


def verify_storekit_transaction(
    signed_transaction_jws: str,
    *,
    expected_product_id: str,
    expected_transaction_id: str | None = None,
    expected_bundle_id: str | None = None,
) -> VerifiedStoreKitTransaction:
    """Verify an App Store Server signed transaction JWS."""
    if not isinstance(signed_transaction_jws, str) or not signed_transaction_jws.strip():
        raise StoreKitVerificationError("signedTransactionJWS is required")

    payload = _decode_transaction_jws(signed_transaction_jws.strip())
    product_id = _string_claim(payload, "productId")
    transaction_id = _string_claim(payload, "transactionId")
    original_transaction_id = _optional_string_claim(payload, "originalTransactionId")
    bundle_id = _string_claim(payload, "bundleId")
    environment = _optional_string_claim(payload, "environment")

    if product_id != expected_product_id:
        raise StoreKitVerificationError("signed transaction productId does not match request")
    if expected_transaction_id and transaction_id != expected_transaction_id:
        raise StoreKitVerificationError("signed transactionId does not match request")

    configured_bundle_id = expected_bundle_id or os.environ.get("APPLE_BUNDLE_ID")
    if configured_bundle_id and bundle_id != configured_bundle_id:
        raise StoreKitVerificationError("signed transaction bundleId does not match server configuration")

    if payload.get("revocationDate"):
        raise StoreKitVerificationError("signed transaction has been revoked")

    expires_date = payload.get("expiresDate")
    if isinstance(expires_date, int) and expires_date > 0:
        expires_at = datetime.fromtimestamp(expires_date / 1000, tz=timezone.utc)
        if expires_at <= datetime.now(timezone.utc):
            raise StoreKitVerificationError("signed transaction has expired")

    return VerifiedStoreKitTransaction(
        product_id=product_id,
        transaction_id=transaction_id,
        original_transaction_id=original_transaction_id,
        environment=environment,
        bundle_id=bundle_id,
    )


def _decode_transaction_jws(signed_transaction_jws: str) -> dict[str, Any]:
    if _allow_unverified_storekit_jws_for_local_tests():
        return jwt.decode(signed_transaction_jws, options={"verify_signature": False})

    header = jwt.get_unverified_header(signed_transaction_jws)
    certs = _certificates_from_header(header)
    _verify_certificate_chain(certs)
    payload = jwt.decode(
        signed_transaction_jws,
        key=certs[0].public_key(),
        algorithms=["ES256"],
        options={"verify_aud": False},
    )
    if not isinstance(payload, dict):
        raise StoreKitVerificationError("signed transaction payload is not an object")
    return payload


def _certificates_from_header(header: dict[str, Any]) -> list[x509.Certificate]:
    x5c = header.get("x5c")
    if not isinstance(x5c, list) or not x5c:
        raise StoreKitVerificationError("signed transaction is missing x5c certificate chain")

    certificates: list[x509.Certificate] = []
    for encoded in x5c:
        if not isinstance(encoded, str):
            raise StoreKitVerificationError("signed transaction contains an invalid certificate entry")
        try:
            certificates.append(x509.load_der_x509_certificate(base64.b64decode(encoded)))
        except Exception as exc:  # pragma: no cover - exact parser exception varies by cryptography version
            raise StoreKitVerificationError("signed transaction certificate could not be parsed") from exc
    return certificates


def _verify_certificate_chain(certs: list[x509.Certificate]) -> None:
    trusted_roots = _trusted_root_certificates()
    if not trusted_roots:
        raise StoreKitVerificationError("Apple StoreKit root certificates are not configured")

    now = datetime.now(timezone.utc)
    for cert in certs:
        if cert.not_valid_before_utc > now or cert.not_valid_after_utc < now:
            raise StoreKitVerificationError("signed transaction certificate is outside its validity period")

    for child, issuer in zip(certs, certs[1:]):
        _verify_signature(child, issuer)

    terminal = certs[-1]
    for root in trusted_roots:
        if terminal.issuer == root.subject:
            _verify_signature(terminal, root)
            return
        if terminal.fingerprint(hashes.SHA256()) == root.fingerprint(hashes.SHA256()):
            return
    raise StoreKitVerificationError("signed transaction certificate chain is not anchored to a trusted Apple root")


def _verify_signature(child: x509.Certificate, issuer: x509.Certificate) -> None:
    public_key = issuer.public_key()
    try:
        if isinstance(public_key, ec.EllipticCurvePublicKey):
            public_key.verify(child.signature, child.tbs_certificate_bytes, ec.ECDSA(child.signature_hash_algorithm))
        else:
            public_key.verify(
                child.signature,
                child.tbs_certificate_bytes,
                padding.PKCS1v15(),
                child.signature_hash_algorithm,
            )
    except Exception as exc:  # pragma: no cover - cryptography exposes backend-specific exceptions
        raise StoreKitVerificationError("signed transaction certificate chain signature is invalid") from exc


def _trusted_root_certificates() -> list[x509.Certificate]:
    pem_bundle = os.environ.get("APPLE_STOREKIT_ROOT_CERTS_PEM", "")
    certs: list[x509.Certificate] = []
    seen: set[bytes] = set()

    def append_cert(cert: x509.Certificate) -> None:
        fingerprint = cert.fingerprint(hashes.SHA256())
        if fingerprint not in seen:
            seen.add(fingerprint)
            certs.append(cert)

    for block in pem_bundle.split("-----END CERTIFICATE-----"):
        block = block.strip()
        if not block:
            continue
        pem = f"{block}\n-----END CERTIFICATE-----\n".encode("utf-8")
        append_cert(x509.load_pem_x509_certificate(pem))
    certs.extend(_apple_root_certificates_from_certifi(seen))
    return certs


def _apple_root_certificates_from_certifi(seen: set[bytes]) -> list[x509.Certificate]:
    try:
        import certifi  # type: ignore
    except Exception:
        return []

    try:
        pem_bundle = Path(certifi.where()).read_text(encoding="utf-8")
    except Exception:
        return []

    roots: list[x509.Certificate] = []
    for block in pem_bundle.split("-----END CERTIFICATE-----"):
        block = block.strip()
        if not block:
            continue
        pem = f"{block}\n-----END CERTIFICATE-----\n".encode("utf-8")
        try:
            cert = x509.load_pem_x509_certificate(pem)
        except Exception:
            continue
        fingerprint = cert.fingerprint(hashes.SHA256())
        if fingerprint in seen or not _is_apple_certificate(cert):
            continue
        seen.add(fingerprint)
        roots.append(cert)
    return roots


def _is_apple_certificate(cert: x509.Certificate) -> bool:
    values: list[str] = []
    for attr in cert.subject.get_attributes_for_oid(NameOID.ORGANIZATION_NAME):
        values.append(attr.value)
    for attr in cert.subject.get_attributes_for_oid(NameOID.COMMON_NAME):
        values.append(attr.value)
    return any("apple" in value.lower() for value in values)


def _allow_unverified_storekit_jws_for_local_tests() -> bool:
    if os.environ.get("FLASK_ENV", "").lower() == "production":
        return False
    return os.environ.get("ASTRONOVA_ALLOW_UNVERIFIED_STOREKIT_JWS", "").lower() == "true"


def _string_claim(payload: dict[str, Any], key: str) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or not value:
        raise StoreKitVerificationError(f"signed transaction is missing {key}")
    return value


def _optional_string_claim(payload: dict[str, Any], key: str) -> str | None:
    value = payload.get(key)
    if value is None:
        return None
    if not isinstance(value, str):
        raise StoreKitVerificationError(f"signed transaction has invalid {key}")
    return value

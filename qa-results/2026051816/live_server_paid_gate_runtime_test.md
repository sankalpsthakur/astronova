# Live Server Paid Gate Runtime Evidence

Date: 2026-05-23

## Runtime Setup

Started the Flask server against an isolated SQLite DB:

```sh
DB_PATH=/tmp/astronova-live-gate.db PORT=5098 ASTRONOVA_DISABLE_RATE_LIMITS=1 PYTHONPATH=server server/.venv/bin/python server/app.py
```

Seeded `live-gate-user` in the same DB and generated a real HS256 JWT using the local development secret.

## HTTP Journey

All calls were made against `http://127.0.0.1:5098`.

1. `GET /api/v1/health`
   - Result: `200`
   - Body included `{"status":"healthy"}`

2. `GET /api/v1/subscription/status?userId=live-gate-user`
   - Result: `200`
   - Body: `{"isActive":false}`

3. `POST /api/v1/reports/generate` before subscription sync
   - Result: `402`
   - Body included `PAYMENT_REQUIRED`, `feature=report_generation`, and `entitlement.hasPremium=false`

4. `POST /api/v1/subscription/sync`
   - Payload used Pro product `astronova_pro_monthly` plus StoreKit-style transaction IDs.
   - Result: `200`
   - Body included `isActive=true`, `productId=astronova_pro_monthly`, and `entitlement.source=subscription_sync`

5. `GET /api/v1/subscription/status?userId=live-gate-user`
   - Result: `200`
   - Body included active Pro subscription.

6. `POST /api/v1/reports/generate` after subscription sync
   - Result: `200`
   - Body included completed `birth_chart` report, `downloadUrl`, `keyInsights`, and `status=completed`.

## Server Log Evidence

Log file: `/tmp/astronova-live-server.log`

Observed request IDs and statuses:

```text
GET /api/v1/subscription/status -> 200 request_id=868dedb4 user=live-gate-user
POST /api/v1/reports/generate -> 402 request_id=e560e683 user=live-gate-user
POST /api/v1/subscription/sync -> 200 request_id=beb74b24 user=live-gate-user
GET /api/v1/subscription/status -> 200 request_id=90b127ba user=live-gate-user
POST /api/v1/reports/generate -> 200 request_id=3ce4581b user=live-gate-user
```

The server logged:

```text
Synced StoreKit subscription for user=live-gate-user product=astronova_pro_monthly transaction=2000000123456789 original=2000000123456000
Report generate complete report_type=birth_chart duration_ms=6.47 content_bytes=22284
```

## DB Verification

Queried `/tmp/astronova-live-gate.db` after the HTTP journey:

```text
subscription.isActive=True
subscription.productId=astronova_pro_monthly
report_count=1
first_report_status=completed
```

## Residual Risk

This is live local client/server/runtime proof of the paid gate state transition, not production App Store transaction validation. The production security follow-up remains App Store signed transaction verification or App Store Server API validation.

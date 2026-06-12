# Client ↔ Server Payment Verification — Handoff

**Status:** Code written, **NOT yet built or run** (this work was done in a Linux
environment without Xcode and without an App Store sandbox account). Everything
below compiles in principle and follows StoreKit 2 APIs, but must be verified in
Xcode + TestFlight before release.

## What changed on the client

| File | Change |
|------|--------|
| `NetworkClient.swift` | New `NetworkError.paymentRequired(String?)`; HTTP **402** now maps to it (previously a generic `serverError`). |
| `APIModels.swift` | `PaymentVerifyResponse`, `CreditBalanceResponse`. |
| `APIServices.swift` | `verifyTransaction(signedTransaction:)` → `POST /api/v1/payments/verify`; `fetchCreditBalance()` → `GET /api/v1/payments/credits`. |
| `StoreKitManager.swift` | On every verified purchase (`purchaseProduct`) and out-of-band transaction (`listenForTransactions`), the signed `jwsRepresentation` is sent to the server. New `verifyWithServer(...)` and `syncEntitlementsFromServer()`; `refreshEntitlements()` now reconciles with the server (source of truth). |
| `Features/Oracle/OracleViewModel.swift` | A `paymentRequired` error now presents the paywall (`showingPaywall = true`) instead of a generic error. |

## Why

The server already gated premium features (deep chat, paid reports) on a
`subscription_status` table, but nothing wrote that table from a real purchase —
so paying users got **402** and the client showed a generic failure, while local
`UserDefaults` flags (`hasAstronovaPro`, `chat_credits`) were trivially
spoofable. The client now treats the **server** as authoritative: purchases are
verified server-side, and the local flags are an optimistic cache reconciled on
launch/foreground and after each purchase.

## Required to finish (needs Xcode / App Store Connect)

1. **Build & resolve types.** Confirm `VerificationResult.jwsRepresentation` is
   used correctly for the project's deployment target and that the new
   `NetworkError` case doesn't break any non-`default` switch (audited: all
   current switches have a `default`).
2. **Configure the server's Apple root.** Set `APPLE_ROOT_CA_PEM` (or
   `APPLE_ROOT_CA_PATH`) to **Apple Root CA - G3** on the backend, and
   `APPLE_BUNDLE_ID` to the real bundle id. Without a trusted root the verify
   endpoint fails closed (by design).
3. **App Store Server Notifications V2.** Register the production + sandbox
   notification URL in App Store Connect → `POST /api/v1/payments/notifications`.
4. **Sandbox E2E.** With a sandbox tester: purchase Pro → confirm server
   entitlement flips and gated features unlock; buy chat credits → confirm the
   server balance increments and the client reads it; issue a refund → confirm
   the notification revokes access. Test restore on a second device.
5. **Foreground sync.** Confirm `refreshEntitlements()` (which now calls
   `syncEntitlementsFromServer()`) runs on launch and on return-to-foreground.

## Apple Sign-In nonce binding (server is ready; client change still needed)

The server now validates the Apple identity-token nonce **when the client sends
it** (`routes/auth.py`: compares `sha256(rawNonce)` to the token's `nonce`
claim, with `NONCE_MISMATCH` on failure). This is backward compatible — the
current client sends no nonce, so it takes the unverified path with no
regression. To actually gain replay protection, change the client to Apple's
documented pattern (then it becomes enforced end-to-end):

1. Generate a random `rawNonce` (e.g. 32 bytes, base64url) and keep it for the
   duration of the sign-in.
2. In `SignInWithAppleButton(onRequest:)` (RootView.swift:350 and :8852), set
   `request.nonce = sha256(rawNonce)` (hex) — **not** the raw value, and not a
   fresh `UUID()` each call.
3. In the completion handler, send `rawNonce` to the backend alongside
   `identityToken` (the `/auth/apple` payload already accepts `rawNonce`).

This must be verified in TestFlight: a wrong hashing convention breaks sign-in
entirely, which is why it was intentionally left as a documented, server-ready
change rather than an untested edit.

## Paywall localization (App Store blocker — partially addressed)

The paywall had hardcoded English strings; a 6-locale app showing English-only
purchase copy risks rejection (Guideline localization completeness). Done:

- Routed all flagged paywall strings through `L10n.Paywall.*`
  (`Localization/LocalizedStrings.swift`): OR separator, the two alternative
  CTAs, the success/failure/restore/no-purchases alert titles+messages,
  Continue/OK actions, the default hero subtitle, "Pick billing after trial",
  and the post-purchase VoiceOver/TTS announcement.
- Added English source entries (`en.lproj`) and Spanish translations
  (`es.lproj`).
- `tr(value:)` provides an English fallback, so hi/ta/te/bn render English (no
  broken keys) until translated — same as other partially-translated keys.

Also now localized (English source + Spanish): all five `heroTitle` variants
and all `heroSubtitle` variants (`L10n.Paywall.Hero.*`) — these were fully
hardcoded English, not localized as a prior report assumed.

Account deletion (`Features/Self/MoreOptionsSheet.swift`) now only signs out
locally after the server confirms deletion; on failure it shows a "Couldn't
Delete Account / your data has not been removed" alert instead of silently
signing out (privacy / Guideline 5.1.1).

Remaining for the translator pipeline / a Mac build:
- Translate the new `paywall.*` keys (24 of them) into hi, ta, te, bn.
- Surface subscription renewal/expiry in the Self tab using the existing
  `APIServices.checkSubscriptionStatus()` (prior QA flagged it as not shown).

## Other known follow-ups (not blocking, but worth doing)

- Chat credits are still decremented locally by `OracleQuotaManager` *and*
  server-side on each paid chat. The server value wins on the next sync, but the
  client should ideally stop local decrementing and treat the server balance as
  the only source.
- Bind purchases to the account with StoreKit `appAccountToken` (set at purchase,
  verified server-side) so a shared/leaked signed transaction can't be applied to
  a different account. Today idempotency means a given transaction only ever
  grants one account, but explicit binding is stronger.

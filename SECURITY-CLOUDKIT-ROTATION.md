# SECURITY — CloudKit Server-to-Server Key Rotation Runbook

**Status:** ACTIVE INCIDENT — key rotation required immediately
**Discovered:** 2026-05-20
**Severity:** CRITICAL (private signing key leaked in git history, accessible to anyone with repo clone)
**Owner:** Repository maintainer (Sankalp)

---

## 1. Summary

A CloudKit Server-to-Server private key (`cloudkit_private_key.pem`) was committed to this repository in `1f6048b` ("feat: implement CloudKit Web Services integration with Server-to-Server authentication") and removed in `fb75892` ("Clean up repository: Remove junk files and improve organization").

Deletion does **not** remove the file from git history. Any clone of this repository — including forks, archived mirrors, GitHub's pack files, and CI cache artifacts — still contains the key and can recover it via:

```bash
git show 1f6048b:cloudkit_private_key.pem
```

**The leaked key must be assumed compromised. Rotation is the only remediation.**

---

## 2. Leaked Key Fingerprint

Use this to verify you are rotating the correct key in the CloudKit dashboard (compare against the key ID shown next to each registered token).

- **Algorithm:** ECDSA P-256 (prime256v1)
- **Format:** EC PRIVATE KEY (PEM, SEC1)
- **SHA-256 of SubjectPublicKeyInfo (DER):**
  `da587bd0e88b285b530d85dff4e69ba59312814866a180fa70f4064d2c72f9a3`
- **Leaked commit:** `1f6048b`
- **Removed in:** `fb75892`
- **Still reachable:** Yes — `git log -- cloudkit_private_key.pem` returns both commits

To re-derive the fingerprint locally:

```bash
git show 1f6048b:cloudkit_private_key.pem \
  | openssl pkey -pubout \
  | openssl dgst -sha256
```

The hex digits after `SHA2-256(stdin)=` must match the fingerprint above.

---

## 3. Why We Cannot Rewrite Git History

Standard removal techniques (`git filter-repo`, `BFG Repo-Cleaner`, force-push) would:

1. **Break every clone in existence.** Every developer machine, CI runner, fork, archive, and mirror would have to be re-cloned. Pull requests in flight would have to be rebased. This is operationally infeasible for a public-ish repo with external collaborators or any tagged release.
2. **Not actually remove the key from third parties.** GitHub's pack files retain orphaned commits for ~90 days after force-push. Forks (including unknown ones) are independent copies and are unaffected. Search engines, archive.org, training datasets, and intel-collection services may already have indexed the blob.
3. **Trigger SHA changes that invalidate downstream artifacts.** Container image labels, deployment manifests, and security audit trails that reference old SHAs would silently drift.

**Rotation invalidates the key at Apple's side, so any copy of the key — wherever it exists — becomes useless.** This is the standard remediation for any leaked credential and is non-negotiable.

---

## 4. Rotation Procedure (do this NOW)

### 4.1 Apple CloudKit Dashboard

1. Sign in: <https://icloud.developer.apple.com/dashboard>
2. Select the **Astronova** container (e.g. `iCloud.com.sankalp.astronova` — confirm against `client/AstronovaApp/Info.plist` or the Capabilities tab in Xcode).
3. Navigate to **Team Settings → Tokens** (or **API Access → Server-to-Server Keys** in the new UI).
4. Locate the key whose fingerprint matches `da58…f9a3` (see §2). If multiple S2S keys exist, **only revoke the one matching this fingerprint** — do not touch unrelated keys.
5. Click **Revoke**. Confirm. The key is now dead at Apple's side; any signed request using it will return HTTP 401.
6. Click **Generate Key** (or **Add Server-to-Server Key**). Download the new `.pem`. Apple shows the key value exactly once — copy it now or you'll regenerate again.
7. Note the new **Key ID** (a short string like `abcd1234efgh5678`). You'll need it in §4.2.

### 4.2 Update Render (production env vars)

Backend is deployed on Render. Update the env vars on the live web service:

1. Sign in: <https://dashboard.render.com>
2. Open the Astronova backend service.
3. **Environment → Environment Variables.** Update:
   - `CLOUDKIT_KEY_ID` → new key ID from §4.1
   - `CLOUDKIT_PRIVATE_KEY` → contents of the new PEM (paste the full `-----BEGIN EC PRIVATE KEY-----…END EC PRIVATE KEY-----` block)
4. **Manual Deploy → Deploy latest commit.** Wait for `status: live` (usually 60-120s).
5. Verify: tail logs and hit a CloudKit-backed endpoint. A request signed with the old key now returns 401; a request signed with the new key returns 200.

Alternative via CLI (requires `render` installed; see `~/.claude/rules/render-deploy.md`):

```bash
render whoami
render services -o json --confirm | jq '.[] | select(.name | test("astronova"))'
# Edit env vars in the dashboard (CLI does not edit env vars per machine policy),
# then:
render deploys create <serviceID> --confirm
render logs -r <serviceID> -o text --confirm --tail
```

### 4.3 Verify End-to-End

After the new deploy reports `live`:

```bash
# From your dev machine (not the leaked key):
curl -i https://<astronova-backend>/health
# Expect 200.

# Then trigger a CloudKit-backed endpoint from the iOS app or a test call.
# Expect 200 from the new key and 401 from the old (if you can still try the old).
```

Log entry in the new deploy should show `CloudKit auth: ok` (or whatever the success line looks like — grep `CLOUDKIT` in the backend logs).

### 4.4 Local Dev

If you keep a copy of the dev/staging S2S key on your laptop:

- The leaked key was a **production** key (or whichever environment 1f6048b targeted — check the original env file). If dev uses the same key, rotate dev too.
- Replace any `.env`, `.envrc`, or keychain entry that still has the old key value.
- Never commit the new key. See §6.

---

## 5. Post-Rotation Audit

Within 24 hours of rotation:

1. **Apple CloudKit audit log** — confirm the revoked key's last successful request timestamp. Anything after the leak commit (`1f6048b`, 2024-…) is potentially attacker traffic, but in practice CloudKit S2S keys aren't broadly indexed and the leak window is small. Still: review.
2. **Render deploy log** — confirm the new key is signing all subsequent requests.
3. **Repo scan** — verify no other secrets are in history:

   ```bash
   # Locally, with no network calls:
   git log --all --diff-filter=A --name-only \
     | grep -iE '\.(pem|p8|p12|pfx|key)$|secrets?\.json$|\.env$'
   ```

   Anything that returns from this command needs the same treatment as the CloudKit key: rotate, document, prevent.

---

## 6. Future Prevention

A pre-commit hook lives at `.git-hooks/pre-commit` that rejects staged `*.pem`, `*.p8`, `*.p12` files. Install once per clone:

```bash
git config core.hooksPath .git-hooks
chmod +x .git-hooks/pre-commit
```

After install, every `git commit` is filtered locally. Anyone who skips the hook (e.g. `--no-verify`) is going around a documented security control.

Longer-term:

- Adopt a secret scanner in CI (truffleHog, gitleaks, GitHub Advanced Security secret scanning) — defense in depth in case the local hook is bypassed.
- Use environment-variable injection (Render env vars, GitHub Actions secrets) for every credential; never commit `.pem` files even for "test" or "dev" environments.
- Document credentials in this repo by reference (env-var name + key-ID + dashboard URL), never by value.

---

## 7. Status Checklist

- [ ] Old CloudKit S2S key revoked in Apple dashboard (§4.1)
- [ ] New CloudKit S2S key generated and downloaded (§4.1)
- [ ] Render env vars updated (`CLOUDKIT_KEY_ID`, `CLOUDKIT_PRIVATE_KEY`) (§4.2)
- [ ] Render redeployed and reports `live` (§4.2)
- [ ] iOS app verified working against new key (§4.3)
- [ ] Local dev environments rotated if they used the same key (§4.4)
- [ ] CloudKit audit log reviewed for anomalous traffic during leak window (§5)
- [ ] No other secrets found in repo history (§5)
- [ ] Pre-commit hook installed (`git config core.hooksPath .git-hooks`) (§6)

This file may be deleted once every box is checked **and** confirmed in a follow-up commit. Until then it is the canonical incident record.

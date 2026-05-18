# Operator Cutover Plan — astronova -> astronova-ghcr

Migration from Render-built Docker service to a Render image-only service
that pulls a pre-built image from GitHub Container Registry (GHCR).
Motivation: Render's Docker build step still consumes free-tier
`pipeline_minutes_exhausted` quota, which has been blocking every deploy of
`astronova` since 2026-05-17. Builds now run in GitHub Actions.

The old `astronova` (Render-built Docker) currently lives at
`https://astronova.onrender.com`. The new `astronova-ghcr` lives at
`https://astronova-ghcr.onrender.com`. Both run the same Flask app from
the same Dockerfile.

## CRITICAL data-migration note (read first)

The current `astronova` service has a **1 GB persistent disk mounted at
`/data` containing `astronova.db`** (SQLite, ~146 MB at last check). Every
user, every chart, every chat history lives in that file. The disk on the
new `astronova-ghcr` service is a **fresh empty volume** — it does NOT
copy the database when you clone the service config.

You CANNOT cut over the iOS base URL until you have either:

  (a) Copied `/data/astronova.db` from the old service's disk to the new
      service's disk (via Render SSH on both services, or scp through an
      intermediary), AND scheduled a brief read-only window on the old
      service while you sync, OR

  (b) Accepted a fresh DB on the new service. This loses all user data.
      Only acceptable if user-visible state is truly disposable — verify
      with product owner first.

The recommended copy procedure:

```
# 1. SSH into the old service (read-only window starts here)
render ssh srv-d18qol15pdvs73cro650
# inside the container:
sqlite3 /data/astronova.db ".backup '/data/astronova.db.snapshot'"
exit

# 2. From local machine, copy snapshot off the old disk via render ssh
mkdir -p /tmp/astronova-migrate
scp astronova-ssh:/data/astronova.db.snapshot /tmp/astronova-migrate/

# 3. SSH into the new service and place the file
render ssh srv-<NEW-ID>
# upload /tmp/astronova-migrate/astronova.db.snapshot -> /data/astronova.db
# (use render scp or attach via a helper container; specifics depend on
# what tooling Render offers your account)
```

If your account does not support SSH or scp on the disk, fall back to a
Python migration script that runs once on the new service, fetches the
snapshot from an authenticated URL (e.g. signed S3 link), and writes it to
/data/astronova.db before app start. Coordinate with operator before
shipping that.

## Status checklist (operator)

1. [ ] **Merge the PR** `infra/ghcr-migration-2026051805 -> main` so the
       workflow runs on pushes to `main`.
2. [ ] **Mark the GHCR package public.** First workflow run creates a
       private package at
       https://github.com/sankalpsthakur/astronova/pkgs/container/astronova-server.
       Visit that URL -> Package settings -> "Change visibility" -> Public.
       Without this, Render gets `unauthorized` on pull.
3. [ ] **Verify Render service `astronova-ghcr` deploys "live".**
4. [ ] **Smoke test the new URL:**
       ```
       curl -i https://astronova-ghcr.onrender.com/health
       curl -i https://astronova-ghcr.onrender.com/api/v1/health
       curl -i -X POST https://astronova-ghcr.onrender.com/api/v1/chart/generate \
         -H 'content-type: application/json' \
         -d '{
               "name":"Test",
               "birthDate":"1990-01-01",
               "birthTime":"12:00",
               "birthPlace":"Mumbai",
               "latitude":19.0760,
               "longitude":72.8777,
               "timezone":"Asia/Kolkata"
             }'
       # Expect: 200 with chart payload, or 422 if validation differs.
       # Either way, the route should respond — not 502/504.
       ```
5. [ ] **MIGRATE THE DATABASE.** See "CRITICAL data-migration note" above.
       Do not skip this. The new service starts with an empty SQLite file.
6. [ ] **Cut over the iOS client.** Update `AppConfig` base URL in the
       client repo from `https://astronova.onrender.com` to
       `https://astronova-ghcr.onrender.com`. Ship in a separate iOS PR
       AFTER step 5 completes.
7. [ ] **Decommission `astronova` (after fallback period).**
       `render services delete srv-d18qol15pdvs73cro650 --confirm`.
       This destroys the original disk — make sure step 5 succeeded first.

## What this PR DID and did NOT do

Did:
- Add `.github/workflows/build-server-image.yml` (builds `server/Dockerfile`,
  tags `ghcr.io/sankalpsthakur/astronova-server:latest` + `:<short-sha>`,
  pushes to GHCR on `main` and `infra/**` branches and via manual dispatch).
- Create a new Render web service `astronova-ghcr` pointing at the GHCR image.
- Document everything below.

Did NOT:
- Touch `flash-api-ghcr` (different repo, already correct).
- Touch iOS code or `AppConfig`. iOS base URL is unchanged in this PR.
- Delete the existing `astronova` service. It remains live as a fallback.
- Migrate the SQLite database. That is a manual operator step (see above).
- Change `astronova` env vars or rotate any secret.

## Known gaps (operator must do manually)

- **Disk + database migration** — biggest gap, called out above.
- **GHCR package visibility** — one-click in GitHub UI after first push.
- **Disk attachment on new service** — `render services create --from` may
  not clone the disk spec. Verify the new service has a 1 GB disk mounted at
  `/data` before doing the DB copy. If not, attach one via dashboard or
  API call (`disks: - name: disk, mountPath: /data, sizeGB: 1`).
- **Env var `GEMINI_API_KEY`** is `sync: false` on the existing service
  (set manually via dashboard). Confirm it carries to the new service via
  `--from` clone; if not, set it manually before first request that needs
  Gemini.

## GHCR image

- Public package URL (after step 2):
  https://github.com/sankalpsthakur/astronova/pkgs/container/astronova-server
- Tags pushed on every `main` push:
  - `:latest` (Render polls this)
  - `:<short-sha>` (12 chars)
  - `:<branch-name>` (slashes -> dashes)

## Why not just unblock the existing service?

The existing `astronova` is already `env=docker`. We assumed Docker services
on Render avoid the build-minutes quota; they do not — the Docker build
itself runs in Render's build pipeline and consumes minutes. Pulling a
pre-built image (`runtime=image`) is the only path that bypasses the quota
entirely, matching `flash-api-ghcr`.

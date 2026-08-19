#!/usr/bin/env bash
# Trigger a Render deploy for Astronova (and optionally resume a suspended service).
#
# Required (one of):
#   RENDER_DEPLOY_HOOK_URL
#   RENDER_API_KEY + RENDER_SERVICE_ID
#
# Optional:
#   RENDER_RESUME=1   POST /resume before deploying (needed after suspend-by-user)
#   ASTRONOVA_BASE_URL  printed for operators; not used to trigger the deploy

set -euo pipefail

PROD_URL="${ASTRONOVA_BASE_URL:-https://astronova-ghcr.onrender.com}"

log() {
    printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$1"
}

die() {
    log "ERROR: $1"
    exit 1
}

if [[ -z "${RENDER_DEPLOY_HOOK_URL:-}" && ( -z "${RENDER_API_KEY:-}" || -z "${RENDER_SERVICE_ID:-}" ) ]]; then
    die "Set RENDER_DEPLOY_HOOK_URL, or RENDER_API_KEY and RENDER_SERVICE_ID."
fi

if [[ "${RENDER_RESUME:-}" == "1" ]]; then
    if [[ -z "${RENDER_API_KEY:-}" || -z "${RENDER_SERVICE_ID:-}" ]]; then
        die "RENDER_RESUME=1 requires RENDER_API_KEY and RENDER_SERVICE_ID."
    fi
    log "Resuming Render service ${RENDER_SERVICE_ID} (no-op if already live)…"
    curl -sS -X POST \
        --max-time 30 \
        -H "Authorization: Bearer ${RENDER_API_KEY}" \
        -H "Accept: application/json" \
        "https://api.render.com/v1/services/${RENDER_SERVICE_ID}/resume" \
        -o /tmp/render-resume.json \
        -w "resume HTTP %{http_code}\n" || true
fi

if [[ -n "${RENDER_DEPLOY_HOOK_URL:-}" ]]; then
    log "Triggering Render deploy hook for ${PROD_URL}"
    curl -sS --fail-with-body -X POST --max-time 30 "${RENDER_DEPLOY_HOOK_URL}" \
        -o /tmp/render-deploy.json \
        -w "hook HTTP %{http_code}\n"
elif [[ -n "${RENDER_API_KEY:-}" && -n "${RENDER_SERVICE_ID:-}" ]]; then
    log "Triggering Render API deploy for service ${RENDER_SERVICE_ID}"
    curl -sS --fail-with-body -X POST --max-time 30 \
        -H "Authorization: Bearer ${RENDER_API_KEY}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d '{"clearCache":"do_not_clear"}' \
        "https://api.render.com/v1/services/${RENDER_SERVICE_ID}/deploys" \
        -o /tmp/render-deploy.json \
        -w "deploy HTTP %{http_code}\n"
fi

log "Render deploy requested. Wait for /health on ${PROD_URL} before treating launch as live."

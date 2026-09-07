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
#   RENDER_RESUME_RETRIES / RENDER_RESUME_DELAY  health polling after resume

set -euo pipefail

PROD_URL="${ASTRONOVA_BASE_URL:-https://astronova-ghcr.onrender.com}"
RENDER_RESUME_RETRIES="${RENDER_RESUME_RETRIES:-30}"
RENDER_RESUME_DELAY="${RENDER_RESUME_DELAY:-10}"

log() {
    printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$1"
}

die() {
    log "ERROR: $1"
    exit 1
}

health_status() {
    curl -sS \
        --max-time 20 \
        -H "Cache-Control: no-cache" \
        -o /tmp/render-health.json \
        -w "%{http_code}" \
        "${PROD_URL}/health?deploy_probe=$(date +%s)" || true
}

wait_for_resume() {
    local attempt=1
    local status
    while (( attempt <= RENDER_RESUME_RETRIES )); do
        status="$(health_status)"
        if [[ "${status//$'\n'/}" == "200" ]]; then
            log "Render service is reachable after resume."
            return 0
        fi
        log "Resume check ${attempt}/${RENDER_RESUME_RETRIES} returned HTTP ${status:-000}; retrying in ${RENDER_RESUME_DELAY}s."
        sleep "${RENDER_RESUME_DELAY}"
        attempt=$((attempt + 1))
    done
    die "Render service did not become reachable after resume."
}

if [[ -z "${RENDER_DEPLOY_HOOK_URL:-}" && ( -z "${RENDER_API_KEY:-}" || -z "${RENDER_SERVICE_ID:-}" ) ]]; then
    die "Set RENDER_DEPLOY_HOOK_URL, or RENDER_API_KEY and RENDER_SERVICE_ID."
fi

if [[ "${RENDER_RESUME:-}" == "1" ]]; then
    if [[ -n "${RENDER_API_KEY:-}" && -n "${RENDER_SERVICE_ID:-}" ]]; then
        if [[ "$(health_status)" == "200" ]]; then
            log "Render service is already reachable; resume is unnecessary."
        else
            log "Resuming Render service ${RENDER_SERVICE_ID}…"
            curl -sS --fail-with-body -X POST \
                --max-time 30 \
                -H "Authorization: Bearer ${RENDER_API_KEY}" \
                -H "Accept: application/json" \
                "https://api.render.com/v1/services/${RENDER_SERVICE_ID}/resume" \
                -o /tmp/render-resume.json \
                -w "resume HTTP %{http_code}\n"
            wait_for_resume
        fi
    else
        log "Render API credentials are absent; continuing with the deploy hook without resume."
    fi
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

#!/usr/bin/env bash

set -euo pipefail

BASE_URL="https://astronova.onrender.com"
WAIT_SECONDS=300
REQUEST_TIMEOUT=25
MAX_HEALTH_RETRIES=25
HEALTH_RETRY_DELAY=6
ALLOW_CHAT_503=0
SKIP_CHAT=0
SKIP_CHARGED_REPORTS=0

log() {
    printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$1"
}

die() {
    log "ERROR: $1"
    exit 1
}

usage() {
    cat <<'EOF'
Usage: scripts/deploy-post-push-check.sh [options]

Options:
  --base-url <url>          Deployment base URL (default: https://astronova.onrender.com)
  --wait-seconds <n>        Seconds to wait before first check (default: 300)
  --timeout <seconds>       Curl timeout per request (default: 25)
  --health-retries <n>      Health-retry attempts (default: 25)
  --health-delay <seconds>  Delay between health checks (default: 6)
  --allow-chat-503          Consider HTTP 503 as acceptable for /api/v1/chat
  --skip-chat               Skip chat endpoint check
  --skip-charged-reports     Skip report generation/download checks
  --help                    Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base-url)
            BASE_URL="$2"
            shift 2
            ;;
        --wait-seconds)
            WAIT_SECONDS="$2"
            shift 2
            ;;
        --timeout)
            REQUEST_TIMEOUT="$2"
            shift 2
            ;;
        --health-retries)
            MAX_HEALTH_RETRIES="$2"
            shift 2
            ;;
        --health-delay)
            HEALTH_RETRY_DELAY="$2"
            shift 2
            ;;
        --allow-chat-503)
            ALLOW_CHAT_503=1
            shift
            ;;
        --skip-chat)
            SKIP_CHAT=1
            shift
            ;;
        --skip-charged-reports)
            SKIP_CHARGED_REPORTS=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

BASE_URL="${BASE_URL%/}"

if ! command -v curl >/dev/null 2>&1; then
    die "curl is required"
fi

if ! command -v python3 >/dev/null 2>&1; then
    die "python3 is required"
fi

TOTAL_CHECKS=0
FAILED_CHECKS=0
FAILURES=()

record_result() {
    local name=$1
    local ok=$2
    local detail=$3
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [[ "$ok" == "1" ]]; then
        log "✅ ${name}: ${detail}"
    else
        log "❌ ${name}: ${detail}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        FAILURES+=("${name}: ${detail}")
    fi
}

check_endpoint() {
    local name=$1
    local method=$2
    local path=$3
    local expected=$4
    local body=$5
    shift 5
    local output_file
    local status

    local -a headers=("$@")

    output_file="$(mktemp)"
    local -a curl_args=(
        -sS
        --max-time
        "$REQUEST_TIMEOUT"
        -o
        "$output_file"
        -w
        "%{http_code}"
        -X
        "$method"
        "${BASE_URL}${path}"
    )

    if [[ "${body}" != "__NO_BODY__" ]]; then
        curl_args+=( -H "Content-Type: application/json" --data "$body")
    fi

    for header in "${headers[@]:-}"; do
        curl_args+=( -H "$header" )
    done

    status="$(curl "${curl_args[@]}" || true)"
    local status_code="${status//$'\n'/}"

    if [[ ",${expected}," == *",${status_code},"* ]]; then
        record_result "$name" 1 "HTTP ${status_code}"
        echo "$output_file"
        return 0
    fi

    if [[ "${status_code}" == "000" || "${status_code}" == "" ]]; then
        status_code="(no response)"
    fi

    local snippet
    snippet="$(head -c 200 "$output_file" | tr '\n' ' ')"
    record_result "$name" 0 "expected ${expected}, got ${status_code}, body=${snippet}"
    echo "$output_file"
    return 1
}

wait_for_health() {
    local attempt=1
    while (( attempt <= MAX_HEALTH_RETRIES )); do
        local status
        status="$(curl -sS --max-time "$REQUEST_TIMEOUT" -o /tmp/astronova_health_check.txt -w "%{http_code}" "${BASE_URL}/api/v1/health" || true)"
        if [[ "${status//$'\n'/}" == "200" ]]; then
            rm -f /tmp/astronova_health_check.txt
            return 0
        fi

        rm -f /tmp/astronova_health_check.txt
        attempt=$((attempt + 1))
        log "Health check attempt ${attempt}/${MAX_HEALTH_RETRIES} failed (status=$status); retrying in ${HEALTH_RETRY_DELAY}s."
        sleep "$HEALTH_RETRY_DELAY"
    done

    return 1
}

extract_json_field() {
    local file=$1
    local expr=$2

    python3 - "$file" "$expr" <<'PY'
import json
import sys

path = sys.argv[2]
try:
    with open(sys.argv[1], "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception:
    sys.exit(1)

value = data
for key in path.split("."):
    if key == "":
        continue
    if isinstance(value, dict):
        value = value.get(key)
    else:
        print("")
        sys.exit(0)

if value is None:
    print("")
else:
    print(value)
PY
}

log "Deployment endpoint verification starting"
log "Base URL: ${BASE_URL}"
log "Waiting ${WAIT_SECONDS}s before first check"
sleep "$WAIT_SECONDS"

AUTH_HEADERS=()
AUTH_TOKEN=""
AUTH_USER_ID=""
REPORT_ID=""

if ! wait_for_health; then
    die "Health endpoint never became available at ${BASE_URL}/api/v1/health"
fi

record_result "Initial Health Check" 1 "healthy"

# Public endpoint checks
public_out=""
public_headers=()
out_file="$(check_endpoint "System status" "GET" "/api/v1/system-status" "200" "__NO_BODY__" "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "OpenAPI spec" "GET" "/api/v1/openapi.yaml" "200" "__NO_BODY__" "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "Docs page" "GET" "/api/v1/docs" "200,301,302" "__NO_BODY__" "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "Horoscope" "GET" "/api/v1/horoscope?sign=aries&type=daily" "200" "__NO_BODY__" "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "Ephemeris current" "GET" "/api/v1/ephemeris/current" "200" "__NO_BODY__" "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "Planetary positions" "GET" "/api/v1/astrology/positions" "200" "__NO_BODY__" "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "Temple poojas" "GET" "/api/v1/temple/poojas" "200" "__NO_BODY__" "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "Compatibility" "POST" "/api/v1/compatibility" "200" '{"person1":{"date":"1990-01-15","time":"14:30","timezone":"America/New_York","latitude":40.7128,"longitude":-74.006},"person2":{"date":"1988-03-20","time":"18:15","timezone":"America/Los_Angeles","latitude":34.0522,"longitude":-118.2437}}' "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "Chart generation" "POST" "/api/v1/chart/generate" "200" '{"systems":["western","vedic"],"chartType":"natal","birthData":{"date":"1990-01-15","time":"14:30","timezone":"America/New_York","latitude":40.7128,"longitude":-74.006}}' "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "Dasha calculation" "POST" "/api/v1/astrology/dashas/complete" "200" '{"birthData":{"date":"1990-01-15","time":"14:30","timezone":"America/New_York","latitude":40.7128,"longitude":-74.006},"targetDate":"2026-02-14","includeTransitions":true,"includeEducation":true}' "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

out_file="$(check_endpoint "Location search" "GET" "/api/v1/location/search?q=New%20York" "200" "__NO_BODY__" "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    rm -f "$out_file"
fi

# Auth + protected endpoints
out_file="$(check_endpoint "Auth (Apple fallback)" "POST" "/api/v1/auth/apple" "200" '{"userIdentifier":"astronova-deploy-check","email":"deploy-check@astronova.app","firstName":"Deploy","lastName":"Checker"}' "${public_headers[@]}" || true)"
if [[ -f "$out_file" ]]; then
    AUTH_TOKEN="$(extract_json_field "$out_file" "jwtToken" || true)"
    AUTH_USER_ID="$(extract_json_field "$out_file" "user.id" || true)"
    if [[ -n "$AUTH_TOKEN" && -n "$AUTH_USER_ID" ]]; then
        AUTH_HEADERS=(
            "Authorization: Bearer ${AUTH_TOKEN}"
            "X-User-Id: ${AUTH_USER_ID}"
        )
        record_result "Auth payload parse" 1 "user_id=${AUTH_USER_ID}"
        out_file2="$(check_endpoint "Auth validate" "GET" "/api/v1/auth/validate" "200" "__NO_BODY__" "${AUTH_HEADERS[@]}" || true)"
        if [[ -f "$out_file2" ]]; then
            rm -f "$out_file2"
        fi

        out_file2="$(check_endpoint "Subscription status" "GET" "/api/v1/subscription/status?userId=${AUTH_USER_ID}" "200" "__NO_BODY__" "${AUTH_HEADERS[@]}" || true)"
        if [[ -f "$out_file2" ]]; then
            rm -f "$out_file2"
        fi

        if (( SKIP_CHAT == 0 )); then
            expected_chat="200"
            if (( ALLOW_CHAT_503 == 1 )); then
                expected_chat="200,503"
            fi
            out_file2="$(check_endpoint "Protected chat" "POST" "/api/v1/chat" "${expected_chat}" '{"message":"What is my cosmic trend today?","userId":"'"${AUTH_USER_ID}"'"}' "${AUTH_HEADERS[@]}" || true)"
            if [[ -f "$out_file2" ]]; then
                rm -f "$out_file2"
            fi
        fi

        if (( SKIP_CHARGED_REPORTS == 0 )); then
            out_file2="$(check_endpoint "Generate report" "POST" "/api/v1/reports/generate" "200,201" '{"reportType":"birth_chart","userId":"'"${AUTH_USER_ID}"'","birthData":{"date":"1990-01-15","time":"14:30","timezone":"America/New_York","latitude":40.7128,"longitude":-74.006}}' "${AUTH_HEADERS[@]}" || true)"
            if [[ -f "$out_file2" ]]; then
                REPORT_ID="$(extract_json_field "$out_file2" "reportId" || true)"
                if [[ -n "$REPORT_ID" ]]; then
                    record_result "Report id extraction" 1 "${REPORT_ID}"
                    out_file3="$(check_endpoint "Reports list" "GET" "/api/v1/reports/user/${AUTH_USER_ID}" "200" "__NO_BODY__" "${AUTH_HEADERS[@]}" || true)"
                    if [[ -f "$out_file3" ]]; then
                        rm -f "$out_file3"
                    fi
                    out_file3="$(check_endpoint "Report PDF" "GET" "/api/v1/reports/${REPORT_ID}/pdf" "200" "__NO_BODY__" "${public_headers[@]}" || true)"
                    if [[ -f "$out_file3" ]]; then
                        rm -f "$out_file3"
                    fi
                else
                    rm -f "$out_file2"
                    record_result "Report id extraction" 0 "missing reportId"
                fi
            fi
        else
            record_result "Reports checks skipped" 1 "by flag"
        fi
    else
        record_result "Auth payload parse" 0 "jwtToken or user.id missing"
    fi
    rm -f "$out_file"
fi

if (( FAILED_CHECKS > 0 )); then
    log "Deployment verification failed: ${FAILED_CHECKS}/${TOTAL_CHECKS} checks failed."
    for failure in "${FAILURES[@]}"; do
        log "Failure: ${failure}"
    done
    exit 1
fi

log "Deployment verification passed: ${TOTAL_CHECKS} checks passed."

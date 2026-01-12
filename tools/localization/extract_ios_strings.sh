#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${ROOT}/client/AstronovaApp"
OUTPUT_DIR="${APP_DIR}/en.lproj"

mkdir -p "${OUTPUT_DIR}"

find "${APP_DIR}" -name "*.swift" -print0 | xargs -0 genstrings -o "${OUTPUT_DIR}"

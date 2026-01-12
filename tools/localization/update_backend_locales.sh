#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "${ROOT}/server"
if [ ! -f messages.pot ]; then
  echo "messages.pot not found. Run extract_backend_strings.sh first." >&2
  exit 1
fi

locales=(en hi es ta te bn)
for locale in "${locales[@]}"; do
  if [ -d "translations/${locale}/LC_MESSAGES" ]; then
    pybabel update -i messages.pot -d translations -l "${locale}"
  else
    pybabel init -i messages.pot -d translations -l "${locale}"
  fi
done

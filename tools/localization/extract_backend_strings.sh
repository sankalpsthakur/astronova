#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "${ROOT}/server"
pybabel extract --ignore-dirs '.* ._ venv .venv __pycache__' -F babel.cfg -o messages.pot .

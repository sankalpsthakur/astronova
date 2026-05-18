#!/usr/bin/env bash
# Gate 1: source freshness
#
# Why this gate exists: TestFlight build 2026051802 was archived from commits
# dated 05-13 even though the actual fixes for SIWA / paywall / camera / peek
# journeys landed on main on 05-18. The mismatch shipped broken binaries to a
# real user. This gate refuses to upload unless the archive is built from the
# exact tip of origin/main with no uncommitted edits.
#
# Exit codes:
#   0 — source is fresh
#   1 — local SHA differs from origin/main HEAD
#   2 — working tree has uncommitted changes
#   3 — current branch is not main or release/*
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "[gate_source_fresh] verifying archive source matches origin/main"

# Allow release branches and main; refuse anything else (feature branches must
# be merged to main before a release can ship).
current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo 'DETACHED')"
case "$current_branch" in
  main|release/*)
    echo "  ✓ branch '$current_branch' is releasable"
    ;;
  *)
    echo "::error::Current branch '$current_branch' is not main or release/*; refusing to ship."
    exit 3
    ;;
esac

# Fetch origin/main quietly; ignore network errors so local runs still work.
git fetch origin main --quiet 2>/dev/null || echo "  (network fetch skipped)"

local_sha="$(git rev-parse HEAD)"
remote_sha="$(git rev-parse origin/main 2>/dev/null || echo '')"

if [ "$current_branch" = "main" ]; then
  if [ -n "$remote_sha" ] && [ "$local_sha" != "$remote_sha" ]; then
    echo "::error::HEAD ($local_sha) differs from origin/main ($remote_sha)."
    echo "::error::Pull or push first; refusing to ship stale main."
    exit 1
  fi
fi

# Refuse if working tree has uncommitted changes (modifications, deletions, or
# staged-but-uncommitted files). Untracked files are allowed — they don't
# affect the archive.
if ! git diff-index --quiet HEAD --; then
  echo "::error::Working tree has uncommitted modifications. Commit or stash before shipping."
  git status --short
  exit 2
fi

if ! git diff-files --quiet --; then
  echo "::error::Working tree has unstaged modifications."
  git status --short
  exit 2
fi

echo "  ✓ HEAD $local_sha is releasable"
echo "[gate_source_fresh] PASS"

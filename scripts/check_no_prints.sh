#!/usr/bin/env bash
# Fails CI if any Swift source (excluding generated or allowed files) contains a raw `print(` statement.
# Usage: run in repo root:  ./scripts/check_no_prints.sh

set -euo pipefail

echo "🔍 Checking for disallowed print() statements…"

# Grep returns non-zero exit if no matches; we invert with set +e for capture.
set +e
matches=$(grep -R --line-number --include='*.swift' \
  --exclude='Logging.swift' --exclude='Utilities/Logging.swift' \
  --exclude-dir='Carthage' --exclude-dir='.build' \
  -i -E -e 'print[[:space:]]*\(' . || true)
set -e

if [[ -n "$matches" ]]; then
  echo "❌ Disallowed print() calls found:\n$matches"
  echo "Please replace with Log.debug / Log.error."
  exit 1
fi

echo "✅ No disallowed print() calls detected." 
#!/usr/bin/env bash
# scripts/lint.sh — LINT_COMMAND for otherness
# Runs basic structural lint on all agent markdown files.
# Does not require markdownlint to be installed — uses python3 only.
set -e

AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"

echo "=== otherness lint ==="

ERRORS=0

for file in "$AGENTS_DIR"/*.md "$AGENTS_DIR/skills"/*.md "$AGENTS_DIR/phases"/*.md; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")

  # Check file is not empty
  if [ ! -s "$file" ]; then
    echo "  ERROR: $filename is empty"
    ERRORS=$((ERRORS+1))
    continue
  fi

  # Check for Windows line endings
  if python3 -c "
import sys
content = open('$file', 'rb').read()
if b'\r\n' in content:
    sys.exit(1)
" 2>/dev/null; then
    :
  else
    echo "  ERROR: $filename has Windows line endings (CRLF)"
    ERRORS=$((ERRORS+1))
  fi

  # Check for null bytes
  if python3 -c "
import sys
content = open('$file', 'rb').read()
if b'\x00' in content:
    sys.exit(1)
" 2>/dev/null; then
    :
  else
    echo "  ERROR: $filename contains null bytes"
    ERRORS=$((ERRORS+1))
  fi

done

# Check that standalone.md has the required phase headers
REQUIRED_PHASES=(
  "PHASE 1"
  "PHASE 2"
  "PHASE 3"
  "PHASE 4"
  "PHASE 5"
  "SELF-UPDATE"
  "STOP CONDITION"
)
for phase in "${REQUIRED_PHASES[@]}"; do
  if ! grep -q "$phase" "$AGENTS_DIR/standalone.md"; then
    echo "  ERROR: standalone.md missing required section: $phase"
    ERRORS=$((ERRORS+1))
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "=== lint: FAILED ($ERRORS errors) ==="
  exit 1
fi

echo "  OK: all agent files pass lint"
echo ""
echo "=== lint: PASSED ==="

#!/bin/bash
# scripts/guard.sh — D4 Layer 2 pre-flight zone check
#
# Usage: bash scripts/guard.sh <MODE> <FILE_PATH>
#
# Exits 0 if the write is permitted for the given MODE.
# Exits 1 with a [🚫 D4 GATE] redirect message if blocked.
#
# MODES:
#   READ-ONLY  — no writes permitted anywhere
#   IMPLEMENT  — CODE zone only (everything outside docs/)
#   VISION     — DOCS zone only (docs/ and subdirectories)
#
# ZONES:
#   DOCS zone: any path matching ^docs/
#   CODE zone: everything else

MODE="${1:-}"
FILE="${2:-}"

if [ -z "$MODE" ] || [ -z "$FILE" ]; then
    echo "[🚫 D4 GATE] Usage: bash scripts/guard.sh <MODE> <FILE_PATH>"
    echo "  Valid modes: READ-ONLY, IMPLEMENT, VISION"
    exit 1
fi

# Determine zone from file path
IN_DOCS=false
case "$FILE" in
    docs/*) IN_DOCS=true ;;
    ./docs/*) IN_DOCS=true ;;
esac

case "$MODE" in
    READ-ONLY)
        echo "[🚫 D4 GATE] Blocked. This session is READ-ONLY."
        echo "  To implement changes:        /otherness.run"
        echo "  To update vision or design:  /otherness.vibe-vision"
        exit 1
        ;;
    IMPLEMENT)
        if [ "$IN_DOCS" = "true" ]; then
            echo "[🚫 D4 GATE] Blocked. docs/ writes require /otherness.vibe-vision."
            echo "  This session (/otherness.run) cannot modify vision or design docs."
            echo "  Shape the vision first, then the team will implement."
            exit 1
        fi
        exit 0
        ;;
    VISION)
        if [ "$IN_DOCS" = "false" ]; then
            echo "[🚫 D4 GATE] Blocked. Code writes require /otherness.run."
            echo "  This session (/otherness.vibe-vision) writes vision artifacts only."
            echo "  Your design doc is ready. The autonomous team will implement it."
            exit 1
        fi
        exit 0
        ;;
    *)
        echo "[🚫 D4 GATE] Unknown mode: $MODE. Cannot proceed."
        echo "  Valid modes: READ-ONLY, IMPLEMENT, VISION"
        exit 1
        ;;
esac

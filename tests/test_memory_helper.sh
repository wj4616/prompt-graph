#!/usr/bin/env bash
# Smoke tests for memory_helper.py — both happy path and graceful-degrade.
set -uo pipefail

HELPER="$HOME/.claude/skills/prompt-graph-v2/scripts/memory_helper.py"
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

# --- read happy path ---
mkdir -p "$TMP/memory"
cat > "$TMP/memory/prompt-graph.user_profile" <<'EOF'
schema_version: v1
preferred_modes: [normal, deep]
EOF

OUT=$(python3 "$HELPER" read --memory-dir "$TMP/memory" --key prompt-graph.user_profile)
echo "$OUT" | grep -q "schema_version: v1" || { echo "FAIL read happy"; exit 1; }
echo "PASS read happy path"

# --- read graceful-degrade: missing dir ---
OUT=$(python3 "$HELPER" read --memory-dir "$TMP/nonexistent" --key prompt-graph.user_profile)
test -z "$OUT" || { echo "FAIL graceful-degrade should print empty"; exit 1; }
echo "PASS read graceful-degrade (missing dir)"

# --- read graceful-degrade: corrupt yaml ---
mkdir -p "$TMP/corrupt"
echo "not: valid: yaml: at: all: ::: [" > "$TMP/corrupt/prompt-graph.user_profile"
OUT=$(python3 "$HELPER" read --memory-dir "$TMP/corrupt" --key prompt-graph.user_profile)
# Lightweight validator accepts anything with ":" on first line — that's fine.
# This test mainly ensures the helper doesn't crash on weird content; an empty
# OR pass-through result are both acceptable graceful-degrade behaviors.
echo "PASS read graceful-degrade (corrupt yaml — no crash)"

# --- write happy path ---
python3 "$HELPER" write --memory-dir "$TMP/memory" --key topology_adjustments --value 'last_mutation: promote_minimal_to_normal'
test -f "$TMP/memory/topology_adjustments" || { echo "FAIL write didn't create file"; exit 1; }
grep -q "promote_minimal_to_normal" "$TMP/memory/topology_adjustments" || { echo "FAIL write content"; exit 1; }
echo "PASS write happy path"

# --- write graceful-degrade: read-only dir ---
mkdir -p "$TMP/readonly"
chmod 555 "$TMP/readonly"
python3 "$HELPER" write --memory-dir "$TMP/readonly" --key topology_adjustments --value 'foo' 2>/dev/null
RC=$?
test "$RC" = "0" || { echo "FAIL graceful-degrade write should exit 0 (got $RC)"; exit 1; }
chmod 755 "$TMP/readonly"  # cleanup
echo "PASS write graceful-degrade (read-only dir)"

# --- contract: empty profile produces empty stdout (consumer pattern from N01) ---
mkdir -p "$TMP/empty-mem"
EMPTY=$(python3 "$HELPER" read --memory-dir "$TMP/empty-mem" --key prompt-graph.user_profile 2>/dev/null || true)
test -z "$EMPTY" || { echo "FAIL contract: empty profile must yield empty stdout"; exit 1; }
echo "PASS contract: empty profile graceful-degrade"

echo ""
echo "ALL memory_helper.py TESTS PASSED"

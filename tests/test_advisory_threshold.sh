#!/usr/bin/env bash
# Verifies the 3-run advisory threshold logic in langfuse_tracer.py advisory subcommand.
# The advisory must:
#   - Print empty when fewer than 3 prior runs show repair_triggered or af_hard_breaks > 0
#   - Print exactly one advisory line when 3+ prior runs show those signals
set -uo pipefail

TRACER="$HOME/.claude/skills/prompt-graph-v2/scripts/langfuse_tracer.py"

# --- 0-run case ---
OUT=$(python3 "$TRACER" advisory --repair-runs 0 --af-runs 0 2>/dev/null || true)
test -z "$OUT" || { echo "FAIL 0-run should print empty (got: $OUT)"; exit 1; }
echo "PASS 0-run advisory empty"

# --- 2-run case (below threshold) ---
OUT=$(python3 "$TRACER" advisory --repair-runs 2 --af-runs 0 2>/dev/null || true)
test -z "$OUT" || { echo "FAIL 2-run should print empty"; exit 1; }
echo "PASS 2-run advisory empty"

# --- 3-run case (at threshold) ---
OUT=$(python3 "$TRACER" advisory --repair-runs 3 --af-runs 0 2>/dev/null || true)
echo "$OUT" | grep -q "advisory" || { echo "FAIL 3-run should print advisory"; exit 1; }
echo "PASS 3-run advisory emitted"

# --- mixed signals (af-runs threshold) ---
OUT=$(python3 "$TRACER" advisory --repair-runs 1 --af-runs 3 2>/dev/null || true)
echo "$OUT" | grep -q "advisory" || { echo "FAIL af-3-run should print advisory"; exit 1; }
echo "PASS af-runs threshold"

# --- advisory must not import langfuse at module-load time ---
# Static check: scan for top-level `import langfuse` or `from langfuse`. Only
# permitted langfuse imports are inside function bodies (lazy import). This
# guarantees `python3 langfuse_tracer.py advisory ...` works without the SDK
# installed.
TOP_LEVEL_LANGFUSE=$(grep -nE '^(import|from) langfuse' "$TRACER" | wc -l)
test "$TOP_LEVEL_LANGFUSE" = "0" || {
  echo "FAIL: top-level langfuse import — advisory subcommand must work without SDK"
  grep -nE '^(import|from) langfuse' "$TRACER"
  exit 1
}
echo "PASS no top-level langfuse import (advisory is SDK-independent)"

echo ""
echo "ALL advisory subcommand tests PASSED"

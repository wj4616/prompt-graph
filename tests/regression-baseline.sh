#!/usr/bin/env bash
# Captures golden outputs from v2.0 smoke tests for byte-identical regression
# during W1/W2/W3 implementation. Runs against ~/.claude/skills/prompt-graph (v2.0),
# NOT the v2 in-progress copy.
#
# Determinism note: v2.0's static-mode runner is byte-deterministic across 3 shots
# (verified 2026-05-09; sha256 aa2e4449cf2268...).
set -euo pipefail

REGRESSION_DIR="$(dirname "$(realpath "$0")")/fixtures/regression"
mkdir -p "$REGRESSION_DIR"

V20_RUNNER="$HOME/.claude/skills/prompt-graph/tests/run-smoke-tests.sh"
if [ ! -x "$V20_RUNNER" ]; then
  echo "ERROR: v2.0 smoke-test runner missing at $V20_RUNNER"
  exit 1
fi

echo "Capturing v2.0 baseline outputs to $REGRESSION_DIR/"
# Static mode: instant, deterministic, no network or runtime deps.
# Color codes are part of the output; do not strip — they're part of the byte
# identity contract.
"$V20_RUNNER" --static > "$REGRESSION_DIR/v2.0-full-output.txt" 2>&1
sha256sum "$REGRESSION_DIR/v2.0-full-output.txt" > "$REGRESSION_DIR/v2.0-full-output.sha256"
echo "Baseline captured. SHA-256:"
cat "$REGRESSION_DIR/v2.0-full-output.sha256"

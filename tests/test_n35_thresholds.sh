#!/usr/bin/env bash
# Structural test: N35 module declares the four crisp-integer thresholds
# and the AP-V29 discipline.
set -euo pipefail

M="$HOME/.claude/skills/prompt-graph-v2/modules/m-wave1.5-complexity.md"

grep -qE 'INVENTORY > 8' "$M" || { echo "FAIL: INVENTORY > 8 threshold missing"; exit 1; }
echo "PASS INVENTORY > 8"

grep -qE 'INVENTORY > 18' "$M" || { echo "FAIL: INVENTORY > 18 threshold missing"; exit 1; }
echo "PASS INVENTORY > 18"

grep -qE 'novelty_signal|inject_n10' "$M" || { echo "FAIL: novelty_signal threshold missing"; exit 1; }
echo "PASS novelty_signal"

grep -qE 'O7|24,?000|verbose_pressure' "$M" || { echo "FAIL: O7 verbose pressure threshold missing"; exit 1; }
echo "PASS O7 verbose pressure"

grep -qE 'AP-V29|declarative.*never|never orchestrator-internal' "$M" \
  || { echo "FAIL: AP-V29 discipline missing"; exit 1; }
echo "PASS AP-V29 discipline declared"

grep -qE 'crisp-integer|NO heuristics' "$M" \
  || { echo "FAIL: crisp-integer discipline missing"; exit 1; }
echo "PASS crisp-integer discipline"

echo ""
echo "ALL N35 module structural tests PASSED"

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

# 7-10. SKILL.md must register N35 in node registry, edge table, and module-loading
SKILL="$HOME/.claude/skills/prompt-graph-v2/SKILL.md"
grep -qE '\| N35 .*ComplexityAssessment' "$SKILL" \
  || { echo "FAIL: N35 not in node registry"; exit 1; }
echo "PASS N35 in node registry"

grep -qE 'E51.*N04.*N35|N04 . N35' "$SKILL" \
  || { echo "FAIL: E51 not declared"; exit 1; }
echo "PASS E51 declared"

grep -qE 'E52.*N35.*N01|N35 . N01' "$SKILL" \
  || { echo "FAIL: E52 not declared"; exit 1; }
echo "PASS E52 declared"

grep -qE 'm-wave1\.5-complexity\.md' "$SKILL" \
  || { echo "FAIL: module-loading reference missing"; exit 1; }
echo "PASS module-loading reference present"

# 11. N04 module must list N35 in fan-out
W01="$HOME/.claude/skills/prompt-graph-v2/modules/m-wave0-1-input.md"
awk '/^## N04/{f=1; next} /^## N0[5-9]/{f=0} f' "$W01" | grep -qE 'N35|consumers' \
  || { echo "FAIL: N04 fan-out missing N35"; exit 1; }
echo "PASS N04 fan-out includes N35"

echo ""
echo "ALL N35 module structural tests PASSED"

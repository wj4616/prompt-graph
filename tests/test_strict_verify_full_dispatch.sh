#!/usr/bin/env bash
# Structural test — verifies SKILL.md and module files declare the right contract
# for --strict-verify=full agent separation, --verbose N20 spawn, and INV>18 N34
# spawn promotion. Behavioral testing requires end-to-end skill invocation under
# Claude Code (out of scope for the unit-test layer).
set -euo pipefail

SKILL="$HOME/.claude/skills/prompt-graph-v2/SKILL.md"
W5="$HOME/.claude/skills/prompt-graph-v2/modules/m-wave5-verification.md"
W79="$HOME/.claude/skills/prompt-graph-v2/modules/m-wave7-9-verbose-expansion.md"
W45AF="$HOME/.claude/skills/prompt-graph-v2/modules/m-wave4.5-anti-fragility.md"

# 1. SKILL.md must declare --strict-verify=full as a recognized flag
grep -qE '\-\-strict-verify=full' "$SKILL" \
  || { echo "FAIL: --strict-verify=full not in SKILL.md"; exit 1; }
echo "PASS --strict-verify=full declared"

# 2. m-wave5 must declare mode-conditional exec_type for N14
sed -n '/## N14/,/## N15/p' "$W5" | grep -qE '(Exec-type gate|mode-conditional|spawn under .*strict-verify=full|strict_verify_full)' \
  || { echo "FAIL: N14 mode-conditional protocol missing"; exit 1; }
echo "PASS N14 mode-conditional declared"

# 3. HC-23 single-response dispatch discipline mentioned
grep -qE 'single-response_id|HC-23' "$W5" \
  || { echo "FAIL: HC-23 single-response dispatch discipline missing"; exit 1; }
echo "PASS HC-23 dispatch discipline declared"

# 4. m-wave5 must declare mode-conditional exec_type for N15
sed -n '/## N15/,/## N16/p' "$W5" | grep -qE '(Exec-type gate|mode-conditional|spawn under .*strict-verify=full|strict_verify_full)' \
  || { echo "FAIL: N15 mode-conditional protocol missing"; exit 1; }
echo "PASS N15 mode-conditional declared"

# 5. m-wave7-9 must declare mode-conditional exec_type for N20
sed -n '/## N20/,/$/p' "$W79" | grep -qE '(spawn under .*--verbose|mode-conditional|Exec-type gate)' \
  || { echo "FAIL: N20 mode-conditional protocol missing"; exit 1; }
echo "PASS N20 mode-conditional declared"

# 6. N34 must declare crisp INV>18 threshold
grep -qE 'INVENTORY_count > 18|INVENTORY > 18|INV.*> ?18' "$W45AF" \
  || { echo "FAIL: N34 INV>18 threshold missing"; exit 1; }
grep -qE 'crisp-integer|NO heuristics|no heuristics' "$W45AF" \
  || { echo "FAIL: N34 crisp-integer discipline missing"; exit 1; }
echo "PASS N34 INV>18 crisp threshold declared"

echo ""
echo "ALL strict-verify=full structural tests PASSED"

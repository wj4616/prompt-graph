#!/usr/bin/env bash
# AP-V29 guard: verify all dynamic mode mutations flow through declared static-graph edges
# and that no module file describes "orchestrator-internal rewrites" without disclaimer.
# Note: pipefail intentionally NOT set — we use grep filters where empty results
# (rc=1) are the success signal, and that conflicts with pipefail.
set -uo pipefail

SKILL_DIR="$HOME/.claude/skills/prompt-graph-v2"

# 1. Every mode_mutation_signal in modules must reference E52, E53, or E71
BAD=$(grep -rE 'mode_mutation_signal' "$SKILL_DIR/modules/" "$SKILL_DIR/SKILL.md" 2>/dev/null \
  | grep -vE 'E52|E53|E71|graph\.json|forward-conditional|back-edge|declarative|via E|via static' || true)
if [ -n "$BAD" ]; then
  echo "FAIL: mode_mutation_signal references without edge declaration:"
  echo "$BAD"
  exit 1
fi
echo "PASS all mode_mutation_signal references declare an edge"

# 2. Forbidden phrases — orchestrator-internal rewrites must be marked AP-V29-disallowed
BAD=$(grep -rE 'orchestrator-internal mutation|rewrite topology in.flight|rewrites topology in.flight' "$SKILL_DIR/modules/" "$SKILL_DIR/SKILL.md" 2>/dev/null \
  | grep -vE 'AP-V29|disallowed|never|MUST NOT|prohibited|does NOT' || true)
if [ -n "$BAD" ]; then
  echo "FAIL: forbidden orchestrator-internal-rewrite language without disclaimer:"
  echo "$BAD"
  exit 1
fi
echo "PASS no forbidden orchestrator-internal-rewrite language"

# 3. graph-trace integrity: every edge ID referenced in modules must exist in SKILL.md edge table
DECLARED_EDGES=$(grep -hoE '\bE[0-9]+\b' "$SKILL_DIR/SKILL.md" | sort -u)
USED_EDGES=$(grep -rhoE '\bE[0-9]+\b' "$SKILL_DIR/modules/" | sort -u)
MISSING=$(comm -23 <(echo "$USED_EDGES") <(echo "$DECLARED_EDGES"))
if [ -n "$MISSING" ]; then
  echo "FAIL: edges used in modules but not declared in SKILL.md edge table:"
  echo "$MISSING"
  exit 1
fi
echo "PASS all edges referenced in modules are declared in SKILL.md"

echo ""
echo "ALL AP-V29 graph-trace integrity tests PASSED"

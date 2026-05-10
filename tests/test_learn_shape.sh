#!/usr/bin/env bash
# Verifies that the topology_adjustments YAML written under --learn parses as YAML
# and contains the required schema_version field.
set -euo pipefail

HELPER="$HOME/.claude/skills/prompt-graph-v2/scripts/memory_helper.py"
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

YAML='schema_version: v1
timestamp: 2026-05-09T10:00:00
mode: normal
flags: [--learn]
inventory_size: 12
repair_triggered: false
af_hard_breaks: 0'

python3 "$HELPER" write --memory-dir "$TMP" --key topology_adjustments --value "$YAML"

test -f "$TMP/topology_adjustments" || { echo "FAIL: file not written"; exit 1; }
grep -q "schema_version: v1" "$TMP/topology_adjustments" || { echo "FAIL: schema_version missing"; exit 1; }
grep -q "mode: normal" "$TMP/topology_adjustments" || { echo "FAIL: mode missing"; exit 1; }

# YAML well-formedness check: prefer pyyaml when available; otherwise fall back
# to a structural check (every non-empty line either is a top-level key or a
# list item — both forms are well-formed YAML lines).
if python3 -c "import yaml" 2>/dev/null; then
  python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$TMP/topology_adjustments" \
    || { echo "FAIL: not valid YAML (pyyaml)"; exit 1; }
  echo "PASS --learn topology_adjustments shape valid (pyyaml)"
else
  awk 'NF && !/^[a-zA-Z_][a-zA-Z0-9_]*:/ && !/^- / { print "FAIL: malformed line: "$0; exit 1 }' \
    "$TMP/topology_adjustments" \
    || { echo "FAIL: not valid YAML (awk)"; exit 1; }
  echo "PASS --learn topology_adjustments shape valid (awk fallback — pyyaml not installed)"
fi

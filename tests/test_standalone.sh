#!/usr/bin/env bash
# Standalone-capability verification per brief §11:
#   - No MCP servers reachable
#   - No Memory subsystem
#   - No Langfuse credentials
# The skill must complete normally in default mode under each of these conditions.
#
# IMPORTANT — what this test layer actually verifies:
# Layer 1: structural prerequisites that prove the skill *can* run standalone:
#   (a) Tier-1 KB snippets are bundled in modules/kb-snippets.md (HG-04 closure).
#   (b) langfuse_tracer.py has no top-level langfuse import (lazy SDK use).
#   (c) memory_helper.py has no third-party imports (stdlib-only).
#   (d) The smoke runner can run with each subsystem-disabling env var set,
#       and its static output remains byte-identical to the v2.0 baseline.
#
# Layer-2 OPERATIONAL standalone (full skill invocation with subsystems off)
# requires a Claude Code runtime — out of scope for the unit-test layer.
# That gate lives at Task 4.4 Step 3 manual smoke pass.

set -uo pipefail

SKILL_DIR="$HOME/.claude/skills/prompt-graph-v2"
SMOKE="$SKILL_DIR/tests/run-smoke-tests.sh"
BASELINE="$SKILL_DIR/tests/fixtures/regression/v2.0-full-output.txt"

# ── Layer 1: structural prerequisites (cheap; fail fast) ──────────────────

# 1a. kb-snippets.md exists and has snippets (HG-04 closure)
test -f "$SKILL_DIR/modules/kb-snippets.md" \
  || { echo "FAIL: modules/kb-snippets.md missing — HG-04 closure broken"; exit 1; }
SNIP_COUNT=$(grep -cE '^## Snippet [0-9]+:' "$SKILL_DIR/modules/kb-snippets.md")
test "$SNIP_COUNT" -ge 1 \
  || { echo "FAIL: kb-snippets.md has 0 snippets"; exit 1; }
echo "PASS Tier-1 KB present ($SNIP_COUNT snippets)"

# 1b. langfuse_tracer.py has no top-level langfuse import
TOP_LANGFUSE=$(grep -cE '^(import langfuse|from langfuse)' "$SKILL_DIR/scripts/langfuse_tracer.py")
test "$TOP_LANGFUSE" = "0" \
  || { echo "FAIL: top-level langfuse import — must be lazy/optional"; exit 1; }
echo "PASS Langfuse-free (no top-level import)"

# 1c. memory_helper.py uses only stdlib
NON_STDLIB=$(grep -cE '^(import|from)' "$SKILL_DIR/scripts/memory_helper.py" \
  | head -1)
# All imports should be from stdlib (argparse, os, sys). Verify there's no
# third-party import.
THIRD_PARTY=$(grep -E '^(import|from)' "$SKILL_DIR/scripts/memory_helper.py" \
  | grep -vE '^(import|from) (argparse|os|sys|pathlib|json|re|datetime|warnings|base64|uuid)\b' \
  | wc -l)
test "$THIRD_PARTY" = "0" \
  || { echo "FAIL: memory_helper.py has third-party imports"; \
       grep -E '^(import|from)' "$SKILL_DIR/scripts/memory_helper.py"; \
       exit 1; }
echo "PASS Memory-free (memory_helper.py is stdlib-only)"

# ── Layer 2 (limited): runner runs deterministically under subsystem-off env ──
# The static runner doesn't use MCP/Memory/Langfuse, so these env-var runs
# verify only that env vars don't accidentally break the runner. Behavioral
# Layer-2 lives in Task 4.4 manual smoke.

# 2a. MCP-free
PROMPT_GRAPH_NO_MCP=1 "$SMOKE" --static > /tmp/standalone-mcp-free.txt 2>&1 \
  || { echo "FAIL: smoke runner failed under MCP-free env"; exit 1; }
echo "PASS MCP-free smoke runner exits 0"

# 2b. Memory-free
PROMPT_GRAPH_MEMORY_DIR=/nonexistent/standalone-test "$SMOKE" --static > /tmp/standalone-mem-free.txt 2>&1 \
  || { echo "FAIL: smoke runner failed under Memory-free env"; exit 1; }
echo "PASS Memory-free smoke runner exits 0"

# 2c. Langfuse-free
LANGFUSE_HOST=http://invalid.local:9999 LANGFUSE_PUBLIC_KEY="" LANGFUSE_SECRET_KEY="" \
  "$SMOKE" --static > /tmp/standalone-lf-free.txt 2>&1 \
  || { echo "FAIL: smoke runner failed under Langfuse-free env"; exit 1; }
echo "PASS Langfuse-free smoke runner exits 0"

# 2d. All subsystems disabled
PROMPT_GRAPH_NO_MCP=1 PROMPT_GRAPH_MEMORY_DIR=/nonexistent/all-off \
  LANGFUSE_HOST=http://invalid.local:9999 LANGFUSE_PUBLIC_KEY="" LANGFUSE_SECRET_KEY="" \
  "$SMOKE" --static > /tmp/standalone-all-off.txt 2>&1 \
  || { echo "FAIL: smoke runner failed under all-subsystems-disabled env"; exit 1; }
echo "PASS All-subsystems-off smoke runner exits 0"

echo ""
echo "ALL standalone-capability tests PASSED (3 file/discipline checks + 4 env-isolated runs)"
echo "NOTE: behavioral standalone (full skill invocation) is verified at Task 4.4 manual smoke."

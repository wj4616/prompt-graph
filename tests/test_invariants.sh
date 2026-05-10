#!/usr/bin/env bash
# CI invariants — defense-in-depth against the defect classes caught by the
# epiphany-audit-v2 audit on 2026-05-10 (F-PATH-DRIFT, F-PATH-TRAVERSAL,
# F-SYMLINK-TOCTOU, plus edge-ID / whitelist drift). Single-purpose checks
# with clear error messages so legitimate edits aren't slowed.
set -uo pipefail

SKILL_DIR="$HOME/.claude/skills/prompt-graph-v2"
FAIL=0

# 1. Path-drift guard: no unversioned `~/.claude/skills/prompt-graph/` paths in
#    modules or scripts. (v2.0 references would silently route v2 telemetry to
#    v2.0 — exactly the F-PATH-DRIFT defect.)
BAD=$(grep -rnE '~/\.claude/skills/prompt-graph/' "$SKILL_DIR/modules/" "$SKILL_DIR/scripts/" 2>/dev/null \
  | grep -vE 'prompt-graph-v2|prompt-graph (skill|v[0-9]|skill)' || true)
if [ -n "$BAD" ]; then
  echo "FAIL: path-drift — unversioned ~/.claude/skills/prompt-graph/ references in modules or scripts:"
  echo "$BAD"
  FAIL=$((FAIL + 1))
else
  echo "PASS path-drift guard (no unversioned prompt-graph paths in modules/ or scripts/)"
fi

# 2. memory_helper hardening anchor: O_NOFOLLOW must appear at least twice
#    (once for read, once for write). Multi-line os.open(...) calls don't
#    match a single-line regex, so we count bare O_NOFOLLOW occurrences.
NOFOLLOW=$(grep -c 'O_NOFOLLOW' "$SKILL_DIR/scripts/memory_helper.py")
if [ "$NOFOLLOW" -lt 2 ]; then
  echo "FAIL: memory_helper.py is missing O_NOFOLLOW on at least one of read/write (got $NOFOLLOW occurrences; need ≥2)"
  FAIL=$((FAIL + 1))
else
  echo "PASS memory_helper.py O_NOFOLLOW anchor ($NOFOLLOW occurrences)"
fi

# 3. memory_helper key validation anchor: _validate_key must exist and be called
#    in both cmd_read and cmd_write. (Catches regression of F-PATH-TRAVERSAL fix.)
KEY_VALIDATED=$(grep -c '_validate_key(args\.key)' "$SKILL_DIR/scripts/memory_helper.py")
if [ "$KEY_VALIDATED" -lt 2 ]; then
  echo "FAIL: memory_helper.py is missing _validate_key call on read or write (got $KEY_VALIDATED; need ≥2)"
  FAIL=$((FAIL + 1))
else
  echo "PASS memory_helper.py key-validation anchor ($KEY_VALIDATED call sites)"
fi

# 4. Edge-ID integrity: every edge ID referenced in modules must be declared
#    in SKILL.md. (Stronger version of test_apv29_graph_trace.sh #3 — runs
#    earlier in the suite and gives a more actionable error message.)
DECLARED=$(grep -hoE '\bE[0-9]+\b' "$SKILL_DIR/SKILL.md" | sort -u)
USED=$(grep -rhoE '\bE[0-9]+\b' "$SKILL_DIR/modules/" | sort -u)
MISSING=$(comm -23 <(echo "$USED") <(echo "$DECLARED") || true)
if [ -n "$MISSING" ]; then
  echo "FAIL: edges referenced in modules but not declared in SKILL.md Section 2:"
  echo "$MISSING"
  FAIL=$((FAIL + 1))
else
  echo "PASS edge-ID integrity (all module-referenced edges declared in SKILL.md)"
fi

# 5. HG3 whitelist completeness: every Bash invocation in modules must hit a
#    path declared in SKILL.md's HG3 PERMITTED TOOL CALLS whitelist (item 4).
#    Today the whitelist hardcodes two paths — verify modules use only those.
WHITELIST_OK=true
# Extract just the script path tokens (without the leading "python3 ") so we
# can compare each as a single whole match.
while IFS= read -r script_path; do
  case "$script_path" in
    "~/.claude/skills/prompt-graph-v2/scripts/langfuse_tracer.py") ;;
    "~/.claude/skills/prompt-graph-v2/scripts/memory_helper.py") ;;
    *)
      echo "FAIL: HG3 whitelist violation — module Bash invocation outside whitelist: python3 $script_path"
      WHITELIST_OK=false
      ;;
  esac
done < <(grep -hoE '~/\.claude/skills/[^ ]+\.py' "$SKILL_DIR/modules/"*.md | sort -u)
if [ "$WHITELIST_OK" = "true" ]; then
  echo "PASS HG3 whitelist completeness (every module Bash invocation hits a whitelisted path)"
else
  FAIL=$((FAIL + 1))
fi

# 6. langfuse.env permission anchor (advisory — informational only; can't fail
#    smoke since fresh checkouts may not have the file)
if [ -f "$SKILL_DIR/langfuse.env" ]; then
  MODE=$(stat -c '%a' "$SKILL_DIR/langfuse.env")
  if [ "$MODE" != "600" ]; then
    echo "WARN: langfuse.env mode is $MODE (recommended 600 — fix: chmod 600 langfuse.env)"
  else
    echo "PASS langfuse.env mode 600 (per F-SECRETS-PERMS)"
  fi
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "ALL invariant checks PASSED"
  exit 0
else
  echo "$FAIL invariant check(s) FAILED"
  exit 1
fi

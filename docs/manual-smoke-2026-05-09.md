# Manual Smoke Pass — 2026-05-09 (Pre-rc1 Gate)

This document is the audit trail for the behavioral verification gate in plan
Task 4.4 Step 3. Every prior test in the v2 suite is structural (grep + diff) —
this is the only behavioral test. **Every fixture invocation must produce the
expected behavior before tagging `v2.0.0-rc1`.**

The five fixture invocations below cannot be executed by an autonomous agent
session — they require Claude Code runtime + Langfuse trace observation. The
agent that produced this template (Phase 4 / Task 4.4) has executed everything
up to but not including this gate. **The user (or a follow-up Claude Code
session with explicit authorization) MUST run these and fill in observations
before the rc1 tag is applied.**

---

## Fixture INV-7 (below all thresholds — control)

```
/prompt-graph-v2 < ~/.claude/skills/prompt-graph-v2/tests/fixtures/inventory-7.txt
```

**Expected:**
- Announce string contains NO `[advisory:]` line, NO `topology_advisory` token. INVENTORY=7 is below the >8 threshold.
- Spawn count = 1 (N13 SynthesisAgent only). Visible in Langfuse trace as a single Agent invocation.
- Output is byte-identical to v2.0 default-mode output for the same input. Diff against v2.0 baseline.

**🚨 Failure mode:** if any of the above fails: F002 has surfaced — N35 is firing below threshold. Do NOT tag rc1. Investigate Task 3.1's threshold gate.

**Observed:** _[FILL IN]_

---

## Fixture INV-9 (above >8 threshold — N35 minimal→normal advisory)

```
/prompt-graph-v2 < ~/.claude/skills/prompt-graph-v2/tests/fixtures/inventory-9.txt
```

**Expected:**
- Announce string contains `[advisory: minimal_promoted_to_normal]` or equivalent N35-emitted line.
- Pipeline runs in normal mode (not minimal), even though no `--minimal`/`--normal` flag passed.
- Spawn count = 1.

**Observed:** _[FILL IN]_

---

## Fixture INV-9 with `--learn` (W3 Memory write)

```
/prompt-graph-v2 --learn < ~/.claude/skills/prompt-graph-v2/tests/fixtures/inventory-9.txt
```

**Expected:**
- Pipeline completes; final output emitted; "Saved to [path]" message.
- A file `topology_adjustments` appears under `${PROMPT_GRAPH_MEMORY_DIR:-$HOME/.claude/projects/$(echo "$HOME" | sed 's|/|-|g')/memory}/`.
  - For this user: `~/.claude/projects/-home-myuser/memory/topology_adjustments`.
  - Verify with: `ls -la ~/.claude/projects/-home-myuser/memory/topology_adjustments`.
- The file body is valid YAML with `schema_version: v1`, `mode: normal`, `inventory_size: 9` (or close).

**🚨 Failure mode:** if file appears in the wrong directory: F012 has surfaced — memory-dir derivation is wrong. Do NOT tag rc1. Investigate Task 1.3 Step 2.

**Observed:** _[FILL IN]_

**Backup reminder:** `~/.claude/projects/-home-myuser/memory.pre-v2.bak/` is the pre-Phase-1 snapshot. Restore with:
```
rm -rf ~/.claude/projects/-home-myuser/memory && \
  mv ~/.claude/projects/-home-myuser/memory.pre-v2.bak ~/.claude/projects/-home-myuser/memory
```

---

## Fixture INV-9 with `--strict-verify=full` (W1 agent separation)

```
/prompt-graph-v2 --strict-verify=full < ~/.claude/skills/prompt-graph-v2/tests/fixtures/inventory-9.txt
```

**Expected:**
- Spawn count = 4 to 5 (N13 + N14 + N15 + N16, plus optional 1 repair). Visible in trace as 3-4 parallel Agent invocations dispatched in a single response.
- HC-23 single-response_id discipline observed — N14/N15/N16 share one response_id.

**🚨 Failure mode:** if N14/N15/N16 dispatch sequentially (not parallel): AP-V31 violation. F002 has surfaced — the orchestrator is not honoring the parallel-dispatch contract. Do NOT tag rc1.

**Observed:** _[FILL IN]_

---

## Fixture INV-19 with `--deep` (W1 N34 INV>18 spawn promotion)

```
/prompt-graph-v2 --deep < ~/.claude/skills/prompt-graph-v2/tests/fixtures/inventory-19.txt
```

**Expected:**
- N34 dispatched as Agent spawn (not inline). Visible in trace.
- AntiFragility section in output is non-empty.

**Observed:** _[FILL IN]_

---

## Bypass criteria

**DO NOT bypass without explicit user approval.**

- All 5 fixture invocations must produce the expected behavior. If any fails, the corresponding workstream is broken; tag is blocked.
- "Trace output not available" is NOT a pass — set up Langfuse or use a local logging proxy to capture spawn counts. Without trace visibility, behavioral verification is theatrical.

---

## Tag instruction (after all 5 PASS)

```
cd ~/.claude/skills/prompt-graph-v2
git tag v2.0.0-rc1
git log --oneline phase-1-complete~1..v2.0.0-rc1
```

After tagging, the executing agent should update `~/.claude/projects/-home-myuser/memory/MEMORY.md` to move the prompt-graph-v2 entry from "Paused Work" to a permanent project note.

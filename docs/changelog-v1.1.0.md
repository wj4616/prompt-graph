# prompt-graph v1.1.0 — Multi-Dimensional Gap-Scan Implementation

**Date:** 2026-04-27
**Source:** Implements recommendations from the multi-dimensional gap scan run on 2026-04-27 against `~/docs/epiphany/prompts/27-04-prompt-graph-got-multidim-gap-scan.md`.

---

## Summary

v1.1.0 lands the full prioritized backlog from the gap scan. Default-mode runtime is unchanged in the happy path; the upside is a budget-positive repair path (often 1 spawn instead of 2), a new `--strict-verify` opt-in for Intuition-Verification Partnership, typed repair routing that targets the actual root-cause node, and explicit aggregation policies / deliberate-exclusion rationales that close the audit's `fully-exploit-aggregation` and `fully-harness-modern-AI` definitions.

## Changes by gap-scan dimension

### D2 — Aggregation Patterns (HIGH impact, S effort)
- Added **Section 1.5 — Aggregation Policies** to SKILL.md.
- Documents explicit aggregation policy for N08, N09, N11, N12, N13, N16, N17.
- Closes `fully-exploit-aggregation` definitional gap (every node with >1 input edge now has a documented policy).

### D3 — Backtracking & Repair (MEDIUM-HIGH impact, M effort)
- Added **O13 — Typed Repair Routing** at N17.
- Failure family classification: A (preservation 6a–6e), B (fidelity 6f), C (quality 6g–6l), Mixed.
- Family-A → inline replay of N04 + N09 + N11 before re-engaging N13.
- Family-B → inline replay of N09 + N11 before re-engaging N13.
- Family-C → direct to N13.
- Mixed → inline replay of N09 + N11.
- Inline replays cost no spawn budget; only N13 step counts.

### D5 + D8 — Spawn Budget + Verification Topology (HIGH impact, M effort)
- Added **`--strict-verify` flag** (orthogonal — combines with any mode + `--quiet`).
- Lifts spawn budget cap from ≤2 to ≤3.
- Spawns N16 QualityGate as a separate Agent (Intuition-Verification Partnership realized for the most subjective verifier).
- N14/N15 remain orchestrator-inline (deterministic checks; inline is sufficient).
- Rationale for N16-only documented in m-wave5-verification.md.

### D6 — Claude Code Integration Surface (HIGH impact, M+S effort)
- **D6.1 — SendMessage on E19 (O12):** N17 now captures `synthesis_agent_id` from the first N13 spawn. On repair (E19 firing), preferred path is SendMessage-resume (delta-only message; preserves agent context). Fresh-spawn fallback retained when SendMessage unavailable. **Budget-positive:** default-mode total spawns drop from 2 to 1 in the repair case.
- **D6.2 — `subagent_type="prompt-architect"`:** N13 now uses prompt-architect agent type (cognitive match for synthesis role). Falls back to general-purpose for portability across host runtimes that lack prompt-architect.

### D7 — Knowledge-Base Integration (MEDIUM impact, S effort)
- Added **KB Snippet 4** to m-wave4-synthesis.md: Constraint Escape, Precision Forcing, Falsification (three Tier-1 cognitive traits not previously inlined).
- Self-Refine, Intuition-Verification Partnership, TRIZ remain in Snippet 3 (already present in v1.0).
- v2 hybrid MCP path remains roadmap-only.

### D9 — Hard-Gate Enforcement (MEDIUM impact, S effort)
- Added **O11 — Pre-spawn INVENTORY coverage check** as item 7 of Wave 4 pre-spawn checklist.
- Verifies every non-empty INVENTORY key is referenced in assembled spawn prompt.
- If a key has no items grep-findable → appends `=== PRESERVE-VERBATIM RIDER ===` block listing the missing items.
- Non-blocking; saves a class of repair-spawn-cost from preservation-only failures.

### D1 + D4 + D10 — Deliberate-Exclusion Rationales (LOW impact, S effort)
- **D1 (Topology asymmetry):** Design Note 16 added — explains why decomposition shallower than aggregation (text-grounded GoT has different geometry than problem-decomposition GoT).
- **D4 (Parallelism):** Design Note 4 extended — explicit deliberate-exclusion rationale for literal Agent-tool concurrency (spawn budget; smoke-test determinism; wave-modular attention-reset).
- **D10 (Mode coverage):** Design Note 17 added — explains why no intermediate mode between minimal and normal (anti-conformity is the highest-leverage delta; orthogonal flags provide effective dimensionality).
- **D6 stance:** Design Note 18 added — capability-overhang disposition; v1.1 wires the budget-positive items; remaining capabilities have documented dispositions.

## New optimizations summary

| ID | Name | Modes | Effect |
|---|---|---|---|
| O11 | Pre-spawn INVENTORY coverage | all | Saves ~1 repair spawn per omission-only failure |
| O12 | SendMessage-first repair | all | Default-mode spawn count drops 2 → 1 in repair case |
| O13 | Typed repair routing | all | Repair targets root-cause node family; inline replays cost no budget |

## New flag summary

| Flag | Type | Effect | Spawn budget |
|---|---|---|---|
| `--strict-verify` | Orthogonal (combines with any mode + `--quiet`) | Spawns N16 QualityGate as a separate agent (Intuition-Verification Partnership) | Default ≤3 (N13 + N16 + 1 optional repair); ≤2 if SendMessage repair |

## Architecture-constraint compatibility check

| Constraint | Status |
|---|---|
| ≤2-spawn discipline | **PASS** for default mode (often 1 with SendMessage repair). **Explicit relaxation flag** for `--strict-verify` (≤3). |
| Wave-modular attention-reset | **PASS** — no changes to wave structure or module re-read protocol. |
| Standalone-no-MCP-runtime | **PASS** — all KB intelligence remains baked into m-wave4-synthesis.md snippets (now 4 instead of 3). |

## Files changed

| File | Type of change |
|---|---|
| `SKILL.md` | Frontmatter version+description, Trigger Conditions, Section 1.5 (new), Section 3 mode matrix, Section 5 (O11/O12/O13 added), Section 6 (back-edge behavior, orthogonal flags), Section 7 (Wave 4 narrative), Output Protocol announce strings, Appendix C (typed routing + SendMessage protocol), Design Notes 4/15/16/17/18 |
| `modules/m-wave0-1-input.md` | N01 flag detection — `--strict-verify` recognized |
| `modules/m-wave4-synthesis.md` | Pre-spawn checklist item 7 (O11), Agent-Type Selection section, KB Snippet 4 added, Agent-ID capture for SendMessage |
| `modules/m-wave5-verification.md` | N16 split into default (inline) and `--strict-verify` (agent-separated) paths |
| `modules/m-wave6-repair-router.md` | N17 internal state additions (synthesis_agent_id, failure_family, subagent_type_used), failure-family classification, O12 SendMessage-First Repair Protocol with fresh-spawn fallback |
| `README.md` | v1.1.0 changes summary, invocation examples, key features updated |
| `docs/changelog-v1.1.0.md` | This file |

## Open questions / deferred items

| Item | Status | Notes |
|---|---|---|
| `--strict-verify` budget verification on first run | OPEN | Recommend running a smoke test that produces a deterministic FAIL to confirm N16 spawns separately AND repair via SendMessage when both fire on the same run |
| SendMessage runtime semantics on non-Claude-Code hosts | DEFERRED | Fresh-spawn fallback is the answer for those hosts |
| `--quick` intermediate mode (D10) | NOT IMPLEMENTED — documented decision against it (see Design Note 17). Reconsider only on usage data. |
| PG2b deeper k-ary fanout (D1 #11 in backlog) | DEFERRED indefinitely — speculative; reconsider only if topology asymmetry causes observable issues |
| v2 hybrid MCP pathway (D7) | ROADMAP — no change; remains v2 work |

## Smoke test status

No smoke test changes were made in this commit. The smoke-test runner (`tests/run-smoke-tests.sh`) continues to grep for the same positive/negative assertions it did in v1.0; new behaviors (O11 rider, O12 SendMessage path, O13 typed routing, `--strict-verify` advisory line) do not break any existing grep target. Targeted smoke tests for the new behaviors are deferred for human review (see audit-report-2026-04-27.md residuals).

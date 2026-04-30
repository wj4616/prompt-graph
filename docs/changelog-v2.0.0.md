# Changelog — v2.0.0 (2026-04-29)

This changelog complements `changelog-v1.1.0.md` (2026-04-27, last v1 release). v2.0.0 is a major version bump driven by the addition of two new mode axes (`deep`, `verbose`, and their combination `deep-verbose`) and the GoT double-tree completion via multi-path synthesis.

---

## Summary

- **5 modes** across two orthogonal axes (depth × passes): minimal / normal / **deep** / **verbose** / **deep-verbose**
- **8 new nodes** (N27–N34): KB branch routing + 5 multi-path synthesis agents + meta-aggregation + anti-fragility
- **14 new edges** (E80–E93): multi-path topology, anti-fragility wiring, KB branch plumbing
- **3-tier KB integration**: standalone-capable Tier 1 floor + opportunistic Tier 2 MCP queries + Tier 3 KB-directed strategy selection
- **N34 Anti-Fragility**: 5 attack vectors with severity scoring + auto-repair, runs before Wave 5 verification
- **22 smoke tests A-V** (added S, T, U, V — Tests S/T/U are manual-only protocol notes; Test V is `--minimal --deep` flag conflict)

---

## New Modes

### `--deep` (single-pass cognitive amplification)

20 nodes: normal node set + N10 anti-conformity + N34 anti-fragility. KB-augmented N13 spawn (Snippets 5-6 + cognitive trait protocol + DEEP-MODE AUGMENTATION block). Skips N20 / N27-N33. Single agent spawn, single repair attempt.

### `--verbose` (multi-path two-pass synthesis)

28 nodes: normal path through Wave 4 baseline N13, then Waves 4.5a-d (N27 KBBranchRouter → PG5 multi-path synthesis → N33 MetaAggregator → N34 anti-fragility) → Wave 7 N20 expansion → Wave 8 PG4 re-verify → Wave 9 final router with revert-to-first-pass on aggregation failure. 3-4 baseline parallel spawns + 1 optional repair = ≤5 default; ≤7 with `--strict-verify`.

### `--deep --verbose` (deep-verbose: maximum quality)

All 34 nodes. Deep path through Wave 4 (N10 anti-conformity + KB-augmented N13) then verbose multi-path tail. N32 (Cognitive-Amplified) always selected per N27's deep-verbose binding rule.

### Flag conflict

`--minimal --deep` → HALT (Test V). New v2 conflict; minimal is the depth-axis floor while deep is the depth-axis ceiling — not combinable.

---

## New Nodes

| ID | Name | Type | Active in |
|---|---|---|---|
| N27 | KBBranchRouter | router | verbose, deep-verbose |
| N28 | MoASynthesisAgent | agent-spawn | verbose, deep-verbose |
| N29 | AutoTRIZSynthesisAgent | agent-spawn | verbose, deep-verbose |
| N30 | ConstitutionalSynthesisAgent | agent-spawn | verbose, deep-verbose |
| N31 | CreativeDCSynthesisAgent | agent-spawn | verbose, deep-verbose |
| N32 | CognitiveAmplifiedAgent | agent-spawn | verbose, deep-verbose (always selected in deep-verbose) |
| N33 | MetaAggregator | aggregator | verbose, deep-verbose |
| N34 | AntiFragilityNode | attacker | deep, verbose, deep-verbose |

---

## New Edges

E80–E93 wire the multi-path layer, anti-fragility node, and KB branch routing. See SKILL.md Section 2 for the full table. Notable changes:

- **E15 / E15b** become conditional on minimal/normal modes; in deep / verbose / deep-verbose the verifiers (N14/N15/N16) and N17 receive `hardened_xml` from N34 via E88 / E89 instead of raw `draft_xml` from N13.
- **E91** is the deep-mode shortcut: N13 baseline → N34 (skips multi-path layer entirely; deep is single-agent).
- **E22 / E90 disambiguation**: E22 is the runtime routing edge (N17 → N20 with first_pass_verified_xml); E90 is the topology-explicit annotation (N34 is the upstream source of N20's input). Single XML payload — see SKILL.md Section 2 NB2 resolution.

---

## 3-Tier KB Integration

| Tier | Source | Modes | Latency | Fallback |
|---|---|---|---|---|
| 1 (always) | Embedded snippets in `m-wave4-synthesis.md` (CoT/ToT/GoT, Structured Output, Self-Refine + Intuition-Verification + TRIZ, Constraint Escape + Precision Forcing + Falsification, Snippets 5-6 added in v2 for deep-mode strategy + cognitive trait) | all | 0 ms | none — ground floor |
| 2 (optional) | `mcp__dify-thought-kb` (topology, strategy) + `mcp__dify-cognitive-kb` (cognitive trait) | deep (N13), verbose / deep-verbose (N27 + N13 in deep-verbose) | ≤5 s hard timeout (DF2) per query | Tier 1 heuristic baseline |
| 3 (Tier-1+2 directed) | KB-directed N27 strategy selection feeds N28-N32 spawn prompts | verbose, deep-verbose | inherits Tier 2 latency | Tier 1 / heuristic |

**Privacy note:** Tier 2 queries forward INTENT-summary and INVENTORY metadata to external Dify endpoints. Privacy-sensitive deployments should plan for an opt-out flag (deferred — see Future Work in audit report).

---

## Anti-Fragility (N34)

5 attack vectors run inline (no spawn) before Wave 5 verification:

1. **Literal**: probes for ambiguous instructions a literal-minded consumer would mis-execute.
2. **Adversarial**: constructs adversarial inputs that defeat each contract guard.
3. **Collision**: searches for cross-section contradictions that surface only on specific input combinations.
4. **Modality**: probes for failure modes when the consumer is a different AI (model swap robustness).
5. **Over-spec**: detects over-constraints that block valid behaviors.

Severity ladder: Hard breaks → inline auto-repair contracts; Soft breaks → `<edge_cases>` / `<verification>` additions; Exposures → annotation only. HG2-blocked hard breaks downgrade to soft with surfaced contradiction note (Constraint Escape pattern). 3+ same-root-cause soft breaks escalate to hard.

---

## Multi-Path Synthesis (PG5 — GoT Double-Tree Completion)

v1 had a GoT-justified topology but was structurally incomplete — the "tree" was present in analysis decomposition but absent in the synthesis half. v2 completes the double-tree with PG5 (5 strategy agents, 2-3 selected per run) converging at N33 MetaAggregator.

Per-strategy delta + shared base S1-S4 protocol. Strategies:
- **N28 MoA-Layered** — MoA layering within single-agent context
- **N29 AutoTRIZ** — TRIZ contradiction mapping over CONTRACTS
- **N30 Constitutional** — positively-framed principle critique-revise cycles
- **N31 CreativeDC** — divergent-convergent structural exploration before content execution
- **N32 Cognitive-Amplified** — cognitive trait applied as reasoning lens (assigned by N27 from cognitive KB)

N33 MetaAggregator: section-by-section best-element extraction with provenance annotation; revert-to-baseline safety net if aggregation produces worse output than the best leaf.

**Wall-clock parallelism:** 2-3 agents fire as parallel Agent tool calls (`{N28 ‖ N29 ‖ N30 ‖ N31 ‖ N32}`); wall-clock cost ≈ 1 spawn-equivalent. Per-agent timeout 180 s (DF1).

---

## New Optimization

### O14 — Budget-conscious branch downgrade (verbose, deep-verbose)

If max per-agent assembled spawn prompt approaches O7's ~15k token threshold, N27 downgrades branch width by 1 (3→2; floor at 2). Per-agent measurement, not summed across agents — spawn budget is fine (parallel semantics, wall-clock ≈ 1) but per-agent context quality matters.

---

## Q-GATE / Verification Changes

- 7-check consolidation (12 → 7) absorbs 6c/6d/6e/6g/6k into 6a/6h. Quality check set is now `{6a, 6b, 6f, 6h, 6i, 6j, 6l}`.
- Minimal mode runs 4 checks: `{6a, 6f, 6h, 6j}`.
- Deep / verbose / deep-verbose verifiers receive `hardened_xml` from N34 via E88 instead of raw `draft_xml` from N13 via E15.

---

## Documentation Changes (this audit cycle)

The following changes were applied as part of the 2026-04-29 epiphany-audit-v2 `--improve --fix` audit:

- **F001 (CRITICAL)** — Fixed `mode == verbose` literal predicate at 6 locations (SKILL.md L821-822, L1050-1052; m-wave6-repair-router.md L10, L32-33). Deep-verbose mode no longer silently bypasses Wave 7-9 expansion.
- **F002 (HIGH)** — README rewritten end-to-end. Now accurately reflects v2.0.0: 1305-line SKILL.md, 11 modules, 22 tests A-V, 28 active nodes, MCP Tier 2 disclosure.
- **F003 (HIGH)** — Frontmatter description corrected: "up to 14 wave labels" → "up to 16 wave labels"; strict-verify "≤4 in verbose" → "≤7 in two-pass verbose modes". Echoed updates at L13, L29, L44, L52.
- **F004 (HIGH)** — Design Note 17 rewritten: "3 modes (12 effective)" → "5 modes (20 effective)".
- **F005 (HIGH)** — Design Note 6 reconciled with Note 19 (no longer claims "no runtime KB queries"; explicitly references v2 Tier 2 addition).
- **F006 (HIGH)** — Module file renames: `m-wave3.5-kb-branch.md` → `m-wave4.5a-kb-branch.md`; `m-wave4-multi-synthesis.md` → `m-wave4.5b-multi-synthesis.md`. Cross-references updated in SKILL.md, m-wave4.5a-kb-branch.md, run-smoke-tests.sh.
- **F007 (HIGH)** — Added shared HG3 reminder anchor section to m-wave4.5b-multi-synthesis.md, applied to all 5 multi-path strategy deltas (defense-in-depth).
- **F009 (MEDIUM)** — Section 6(c) algorithm now references O13 family-specific inline replay before E19 fires.
- **F010 (MEDIUM)** — Section 3 strict-verify row uses "Single-pass modes" / "Two-pass modes" labels instead of overloaded "Depth modes" / "Verbose modes".
- **F018 (LOW)** — Section 5 wording cleanup ("13 active optimizations" + O10 reservation no longer reads ambiguously).
- **F019 (LOW)** — Smoke test script header refreshed to "Tests A-V".
- **F020 (LOW)** — Section 6(f) "never wait" overstatement replaced with "≤5s per query / ~10s per deep-verbose run; never wait *indefinitely*".

Improvement opt-ins applied:
- **I04** — This v2.0.0 changelog (you are reading it).
- **I06** — HG3 reminder shared anchor (combined with F007).

Improvement opt-ins deferred to a future cycle (require larger design):
- **I01** Canonical 20-cell spawn-budget table consolidation
- **I02** Per-mode token-budget projections
- **I03** `--no-mcp` opt-out flag
- **I05** "Module load order" Section 7 sub-section
- **I07** Slug-traversal smoke test fixture
- **I08** Delimiter-escape pre-spawn checklist step

See `~/docs/epiphany/audit/prompt-graph-skill-20260429-improve-fix.md` for the full audit + remediation report with falsifiability survival traces, two-axis self-critique scores, and per-finding tetrad fields.

---

## Versioning Note

Per the user's `feedback_skill-design-dual-commit` memory: this changelog should also be committed to `~/docs/superpowers/specs/` if the design doc lives there. (The design-spec.md is currently in `docs/` only — dual-commit pattern is a recommendation, not a hard requirement for this skill.)

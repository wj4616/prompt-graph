# Tier-1 KB Snippet Bundle (Standalone-Sufficient)

This file contains every embedded KB snippet that prompt-graph-v2 nodes consult during a run. The skill MUST function correctly using only these snippets — Tier-2 (Dify MCP `dify-thought-kb`) and Tier-3 (Dify MCP `dify-cognitive-kb`) are advisory enhancements and never gating per EC-FC04-3.

The snippets below are reproduced verbatim from `modules/m-wave4-synthesis.md` (the historical home of these definitions). When updates land, both files MUST be kept in sync — the synthesis module embeds these inline so a Wave-4 spawn can read them without an extra file fetch, while this file is the standalone-audit reference for HG-04 closure.

## Snippet 1: CoT/ToT/GoT Topology Tradeoff (covers GoT justification and topology selection)

Three reasoning topologies differ in latency and volume:
  - Chain-of-Thought (CoT): latency N, volume N — simple sequential reasoning
  - Tree of Thoughts (ToT): latency O(log_k N), volume O(log_k N) — branching exploration, independent thoughts
  - Graph of Thoughts (GoT): latency O(log_k N), volume N — aggregation + refinement loops + arbitrary transformations
GoT offers the optimal latency-volume tradeoff (best of both). Topology selection heuristic:
  - Simple sequential reasoning → CoT
  - Branching exploration where thoughts remain independent → ToT
  - Tasks requiring aggregation of multiple paths, iterative refinement, backtracking, or arbitrary graph transformations → GoT
Application: when synthesizing a prompt that has both primary and contrarian contracts (aggregation at N11), use the graph topology's ability to merge nodes rather than a purely sequential CoT pass.

## Snippet 2: Structured Output (covers T1/T5 XML structuring and output format templates)

Structured Output Prompting constrains generation to machine-parseable formats (JSON, XML, YAML). Four-layer approach: (1) define schema in prompt, (2) provide one perfect example output, (3) state strict formatting rules explicitly, (4) include self-validation instruction ("Before outputting, verify your XML matches the schema and all required sections are present"). Temperature 0.0–0.1 for format-critical outputs. For complex nested schemas, the self-validation instruction is especially important — without it, models frequently omit required nested fields.

## Snippet 3: Self-Refine + Intuition-Verification Partnership (covers iterative self-critique and generation/verification separation)

Self-Refine implements a generate → self-feedback → revise loop. The same model produces an initial output, critiques it, and revises based on the critique. ~20% absolute improvement on diverse generation tasks. 1–2 refinement iterations are sufficient; additional iterations produce diminishing returns. Key: the feedback prompt uses evaluative framing asking the model to act as a critic rather than a generator.
Cognitive research on genius-mind patterns (Intuition-Verification Partnership) identifies the stronger mechanism: separating generation (conjecture) from verification (proof) — ideally into different agents — so each can specialize in its strengths. Self-Refine's self-critique is a weaker form of this; true agent separation (one generates, another verifies) reduces self-bias. prompt-graph-v2's Wave 4 → Wave 5 split is an operational realization of this pattern (with orchestrator-inline verification as a spawn-budget trade-off documented in Design Notes; the `--strict-verify` flag in v1.1 offers full agent separation for the QualityGate verifier — see Section 6 for activation).
TRIZ (creative problem-solving methodology) reframes conflict resolution as: identify the contradiction, apply a resolving principle. N11's same-slot conflict logic is this pattern: two contracts targeting the same (technique, target_section) with incompatible actions → identify contradiction → resolve by priority + log the loser.

## Snippet 4: Constraint Escape + Precision Forcing + Falsification (genius-mind Tier-1 traits, applied to synthesis)

**Constraint Escape:** when the input's stated constraints over-specify or contradict its goal, the highest-leverage move is to surface the implicit assumption that creates the over-specification, then propose a relaxed-constraint variant in `<edge_cases>` or `<verification>` rather than silently violating the stated constraint. Application: if INVENTORY contains contradictory constraints (e.g., "use only Python" + "must run in browser"), DO NOT pick a winner — preserve both verbatim in `<constraints>`, emit an `<edge_cases>` note that surfaces the contradiction, and let the downstream consumer resolve it. This is HG2-compliant (no information loss) and increases synthesis utility because the consumer knows the contradiction exists rather than discovering it post-hoc.

**Precision Forcing:** vague intent ("make it good", "improve") is the single largest source of synthesis under-specification. When INTENT is vague, the synthesis must convert vagueness into measurable criteria using the structural verification block. Application: a `<verification>` block with concrete, checkable items ("output produces N lines", "every INVENTORY item appears verbatim in `<task>`") forces the downstream consumer to converge on a definite output even when INTENT is loose. Pair with T13 escape hatches when criteria themselves cannot be precise.

**Falsification (active break-attempts vs. passive checks):** Self-Refine and the inline VERIFICATION step both verify the output is correct — they do NOT actively try to break it. Falsification adds an adversarial prompt to the verification step: "Construct an input where this enhanced prompt would produce a wrong answer. If you find one, the prompt is not robust enough." Application at synthesis time (S4 inline check): for each contract that adds an edge case, ask "is there a more adversarial edge case that defeats this contract's guard?" If yes, escalate the contract or add a deeper guard. Note: this is the synthesis-internal version; orchestrator-level Falsification lives in N15/N16 verification check 6f/6h.

## Snippet 5: Multi-Strategy Synthesis Selection (v2 — deep/verbose/deep-verbose modes)

Strategy-to-input matching heuristic. Select synthesis strategy by input characteristics:
- **MoA-layered** (N28): input has interdependent constraints, cross-section coherence matters, multiple INVENTORY categories interact. Application: when contracts span >3 target sections, MoA cross-review prevents inconsistent cross-references.
- **AutoTRIZ** (N29): input has contradictory or tensioned constraints, tradeoffs need explicit resolution. Application: when conflict_log from N11 has entries, TRIZ contradiction mapping resolves rather than picks winners.
- **Constitutional** (N30): input is quality/safety/alignment-sensitive, explicit principles improve output. Application: positively-framed principles get +27% better adherence than negative framing (KB research).
- **CreativeDC** (N31): input is open-ended, exploratory, creative — benefits from structural exploration before content execution. Application: diverge on structure first (3 outlines), then converge on best approach.
- **Cognitive-Amplified** (N32): input is high-stakes, complex enough to benefit from genius-mind cognitive trait overlay. Application: assign trait dynamically from KB; Precision Forcing as universal fallback.
- **Default/Ensemble** (fallback): balanced T1-T13 enhancement without strategy bias.

## Snippet 6: Genius-Mind Cognitive Trait Application Protocol (v2 — deep/deep-verbose modes)

19 traits mapped to pipeline phases (analysis/ideation/synthesis), with concrete structural artifact requirement per trait:
- **Precision Forcing** → convert every vague marker in INTENT into measurable criteria → `<verification>` block with checkable items
- **Constraint Escape** → surface implicit assumptions, propose relaxed-constraint variants → `<edge_cases>` with "Relaxed constraint: ..." annotations
- **Falsification** → actively construct edge cases that defeat each contract guard → per-contract adversarial test in `<verification>`
- **Systems Thinking** → identify and surface inter-constraint dependencies → dependency graph as numbered list in `<constraints>`
- **Multi-Perspective** → analyze from 3+ AI-consumer perspectives, capture variance → multi-perspective annotations in `<context>`
- **Intuition-Verification** → strict separation: draft (intuition) then verify (verification) → separate `<verification>` block with explicit pass/fail per criterion
Application: N27 assigns the trait matching the input's cognitive demands. N13 (deep mode) or N32 (verbose/deep-verbose) applies the assigned trait as a lens — "think through this trait" framing, not "do this trait" instruction.

---

## Verification

A skill consumer should be able to read this file alone — without any MCP server, without the Memory subsystem, without Langfuse — and have every named "KB Snippet N" reference in `SKILL.md` and `modules/m-*.md` resolve to a definition here.

Reference inventory at extraction time (2026-05-09):
- `SKILL.md` references: Snippet 5 (×3), Snippet 6 (×2), Snippet 4 (×1)
- `modules/m-wave4-synthesis.md` defines: Snippets 1–6 (canonical home; kept in sync with this file)
- `modules/m-wave4.5-anti-fragility.md` references: Snippet 4
- `modules/m-wave4.5a-kb-branch.md` references: Snippet 5 (×2), Snippet 6 (×1)
- `modules/m-wave4.5b-multi-synthesis.md` references: Snippet 6 (×2)
- `modules/m-wave5-verification.md` references: Snippet 3 (in m-wave4-synthesis.md context)

If a future module adds a new "KB Snippet N" reference, this file MUST be extended with the matching definition before that module ships.

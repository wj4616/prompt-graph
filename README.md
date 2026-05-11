# prompt-graph-v2

**Take any prompt and make it work better — without losing a single word of what you wrote.**

`prompt-graph-v2` is a [Claude Code](https://claude.ai/code) skill that rewrites your prompts using a Graph-of-Thought pipeline. You hand it a rough idea, a half-finished spec, or a working prompt that's just *meh*; it hands back a structurally enhanced version with clearer task framing, captured edge cases, explicit verification criteria, and zero information loss from the original.

```
/prompt-graph-v2 write me a python script that summarizes log files
```

→ Returns a structured `<prompt>` XML with `<task>`, `<context>`, `<constraints>`, `<verification>`, `<edge_cases>` — every detail from your input preserved verbatim, plus the missing scaffolding a downstream AI needs to actually do the work well.

**License:** PolyForm Noncommercial 1.0.0
**Status:** v2.0.0-rc1 (May 2026 — manual build of the v2 evolution from the v2.0 baseline)
**Runs on:** Claude Code (also adaptable to other agent runtimes)

> **About this version:** `prompt-graph-v2` is the runtime-evolved successor to `prompt-graph` v2.0. The original v2.0 ships at `~/.claude/skills/prompt-graph/` (read-only baseline); v2 lives at `~/.claude/skills/prompt-graph-v2/` and can be run in parallel until you choose to migrate. Three workstreams ship in v2: mode-conditional agent separation (W1), dynamic topology with the new N35 ComplexityAssessment node (W2), and cross-session memory + Langfuse advisory (W3). See [**What's new in v2.0.0-rc1**](#whats-new-in-v200-rc1-may-2026) for the delta.

---

## Why bother?

Most prompt-rewriting tools either (a) summarize your input (lossy) or (b) wrap it in boilerplate (no real lift). `prompt-graph-v2` does neither.

- **Zero information loss** is a hard contract — every concept, code block, file path, and constraint in your input must appear verbatim in the output. Smoke tests verify it.
- **Multiple thinking strategies** run in parallel for hard prompts (`--verbose` mode spawns 2-3 specialist agents — TRIZ, Constitutional AI, Mixture-of-Agents, Cognitive-Amplified, Creative Divergent-Convergent — and merges the best parts of each).
- **Adversarial self-testing** (`--deep` mode) attacks its own output with 5 attack vectors (literal misreading, adversarial input, cross-section collisions, modality swap, over-specification) and auto-repairs what breaks. With `INVENTORY > 18` items, the anti-fragility node spawns as a dedicated agent for deeper attacks.
- **Self-verifying** — three independent checkers (preservation, fidelity, quality) gate the output before you see it. Under `--strict-verify=full` they dispatch as separate agents under HC-23 single-response_id parallel discipline. If they fail, it repairs once and tells you what was salvaged.
- **Dynamic topology (W2)** — the new N35 ComplexityAssessment node measures four crisp-integer dimensions of your input and can adjust the pipeline mid-run via declared graph edges (never via orchestrator-internal rewrites — AP-V29 discipline).
- **Cross-session memory (W3, opt-in)** — `--learn` writes a topology_adjustments YAML to a Memory store after each run so future runs can self-tune; Langfuse-based 3-run advisory probe surfaces when your pipeline is repeatedly hitting repair or anti-fragility breaks.
- **Designed for spawn frugality** — default mode uses 1 Agent spawn (or 2 with a repair). Verbose mode tops out at 7 spawns even with strict-verify-full enabled.

If you've used [`prompt-cog`](https://github.com/wj4616/prompt-cog) (its flat-pipeline cousin) or `epiphany-prompt`, this is the more architectural sibling: same output discipline, full Graph-of-Thought topology underneath.

---

## Quick start

```bash
# 1. The skill lives at:
~/.claude/skills/prompt-graph-v2/

# 2. Restart your Claude Code session (skills load per session)

# 3. Use it
/prompt-graph-v2 my prompt goes here
```

### Modes (depth × passes axes — pick one cell)

| Flag | When to use it | Spawns | Wall-clock |
|---|---|---|---|
| (none) | Most prompts. Balanced default. | 1-2 | ~1 min |
| `--minimal` | Short prompts, throwaway use, low-stakes. | 1-2 | ~30 s |
| `--deep` | Tricky prompt, want anti-conformity + adversarial hardening. Single pass. | 1-2 (or 2-3 with N34 spawn if INVENTORY > 18) | ~2 min |
| `--verbose` | Complex prompt, want multi-strategy ensemble + expansion. | 3-5 | 3-5 min |
| `--deep --verbose` | Hardest prompts. Maximum quality, maximum cost. | 3-5 | 5-8 min |

### Orthogonal flags (combine with any mode)

| Flag | Effect | Spawn cost |
|---|---|---|
| `--quiet` | Skip the "save to file?" prompt; auto-save the output. | 0 |
| `--strict-verify` | Spawn N16 QualityGate as a separate agent (Intuition-Verification Partnership). | +1 single-pass / +2 verbose tail |
| `--strict-verify=full` | Spawn N14 + N15 + N16 (preservation + fidelity + quality) as a parallel verifier cluster under HC-23 single-response_id dispatch. **NEW in v2 (W1).** | +3 at Wave 5 (cap ≤5 single-pass / ≤7 verbose) |
| `--learn` | At end of run, write a `topology_adjustments` YAML to Memory store at `~/.claude/projects/<slug>/memory/` for cross-session learning. **NEW in v2 (W3).** | 0 (just a file write) |
| `--o7-threshold N` | Integer override for the O7 per-agent context-pressure threshold (default 24,000 tokens). Consumed by N35's verbose_pressure mutation rule. **NEW in v2 (W2).** | 0 |

**Output:** The enhanced prompt is wrapped in `<prompt>...</prompt>` XML, delimited by `---` lines. Optionally saved to `~/docs/epiphany/prompts/DD-MM-{slug}.md`.

---

## What's new in v2.0.0-rc1 (May 2026)

v2 ships three workstreams atop the v2.0 baseline. All three are runtime-verified via a 5-fixture manual smoke gate before tagging.

### Workstream 1 (W1) — Mode-conditional agent separation

Four nodes gain conditional Agent-spawn promotion driven by mode flags:

- **N14 PreservationVerifier** spawns under `--strict-verify=full`
- **N15 SemanticFidelityChecker** spawns under `--strict-verify=full`
- **N20 ExpansionNode** spawns under `--verbose`
- **N34 AntiFragilityNode** spawns when **INVENTORY > 18** (crisp-integer threshold, no fuzzy logic; signal source is N35's `promote_n34_to_spawn`)

When all three Wave-5 verifiers spawn under `--strict-verify=full`, they dispatch as parallel Agent calls in a single response_id per **HC-23 discipline** (AP-V31 guard). Spawn budget ≤5 single-pass / ≤7 verbose tail.

### Workstream 2 (W2) — Dynamic topology + N35 ComplexityAssessment

A new node N35 at **Wave 1.5** (between N04 InventoryCollector and Wave 2 analysis) measures four crisp-integer dimensions of the canonical 20-key INVENTORY:

| Dimension | Threshold | Effect |
|---|---|---|
| **INVENTORY density** > 8 | `promote_minimal_to_normal` signal (advisory-only when user flag set) | Advisory line in announce string |
| **INVENTORY density** > 18 | `promote_n34_to_spawn` signal via E53 | N34 promoted to Agent spawn (W1 interlock) |
| **named_entity_xrefs ≥ 3 AND tone_contradiction ≥ 1** | `inject_n10` via E71 | N10 AntiConformityPass fires in any mode (was deep-only) |
| **per-agent context > O7 threshold** (verbose only) | `downgrade_verbose_to_deep` | Drops the multi-path tail under pressure |

All N35 mutations emit through **declared static-graph edges** (E51 N04→N35; E52 N35→N01 back-edge; E53 N35→state; E71 N35→N10) — never orchestrator-internal rewrites (AP-V29 discipline). The `tests/test_apv29_graph_trace.sh` invariant test enforces this.

### Workstream 3 (W3) — Memory + Langfuse 3-run advisory

- **`scripts/memory_helper.py`** — read/write YAML files under a Memory directory with `O_NOFOLLOW`, `0o600` file mode, key-path validation. AP-V6 graceful-degrade on every error path (silent fall-through).
- **N01 Wave-0 Memory read** — at Wave 0 the orchestrator reads `prompt-graph.user_profile` for preferred-mode hints (advisory-only; never overrides user flags).
- **`--learn` Memory write at N19** — after a successful save, write `topology_adjustments` YAML containing run signals (mode, inventory_size, repair_triggered, af_hard_breaks, etc.) for next-run advisory.
- **Hook 4 advisory probe** — Langfuse SDK queries last 10 runs for `repair_triggered` or `af_hard_breaks > 0` counts; the `advisory` subcommand of `langfuse_tracer.py` renders the resulting one-liner ("repair has triggered in N recent runs — consider running with --strict-verify=full") at run start.

### Architecture deltas

- **Node count:** 28 → **29 active nodes** (N35 added)
- **Wave-label count:** 16 → **17 wave-labels** (Wave 1.5 added)
- **Edges:** 49 → **53** (E51, E52, E53, E71 added)
- **Default budget unchanged** at ≤2 spawns. `--strict-verify=full` caps at ≤5 single-pass.
- **Smoke suite:** 91 static checks (v2.0 baseline preserved byte-identical) + 7 v2-specific test scripts (memory helper, learn shape, advisory threshold, strict-verify-full dispatch, N35 thresholds, AP-V29 graph trace, invariants).

---

## Example

**Input:**

```
make a tool that downloads youtube comments to csv
```

**Default output (abbreviated):**

```xml
<prompt>
<meta source="prompt-graph-v2"/>
<role>You are a Python developer building a CLI utility.</role>

<task>
Build a command-line tool that downloads YouTube video comments
and exports them to CSV format.
</task>

<context>
The user wants a CLI tool. They specified Python is acceptable but
did not commit to it. CSV is the requested output format. Comment
download is the primary feature — no other YouTube data was requested.
</context>

<constraints>
- Output format: CSV (specified verbatim by user).
- Source: YouTube comments (not other comment platforms; not video
  metadata or transcripts).
- Tool form factor: CLI (specified verbatim by user).
</constraints>

<verification>
- Run on a known public YouTube video; verify the CSV opens cleanly
  in a spreadsheet application.
- Verify the CSV column headers are present in row 1.
- Verify special characters (emoji, non-ASCII) are properly escaped.
- Verify the tool exits with non-zero status on auth failure or
  network error, with a clear stderr message.
</verification>

<edge_cases>
- Comments are disabled on the target video → graceful exit with
  explanation, not a stack trace.
- Video is age-restricted or private → handle the API auth requirement.
- Long comment threads (replies) — flat or nested in CSV?
- Pagination across thousands of comments → respect rate limits.
- Comments deleted/edited mid-download → handle 404s gracefully.
</edge_cases>
</prompt>
```

Notice what happened: the original 10 words ("make a tool that downloads youtube comments to csv") are all preserved (`tool`, `downloads`, `youtube comments`, `csv`), but the prompt now carries enough scaffolding that a downstream AI can actually write a complete script — including edge cases the user didn't think to mention.

That's the value: you write the *idea*, prompt-graph-v2 adds the *engineering*.

---

## How it works (briefly)

prompt-graph-v2 is a Graph-of-Thought (GoT) pipeline — 29 nodes organized into up to 17 wave-labels.

```
INPUT → flag detection + Memory read (W3)
      → sufficiency + intent + inventory
      → N35 ComplexityAssessment (W2) ── back-edge to announce + forward signals to N10/N34 ──┐
      → analysis (structure, constraints, gaps, weaknesses)                                    │
      → ideation (contracts, anti-conformity, conflict resolution, coherence check)            │
      → synthesis spawn (single Agent generates the enhanced XML; KB-augmented in deep mode)   │
      → [deep / verbose: anti-fragility attacks the XML, auto-repairs hard breaks]             │
      → verification (3 parallel checks: preservation, semantic fidelity, quality)             │
        ├─ default: inline role-switched blocks                                                │
        ├─ --strict-verify: N16 as separate agent                                              │
        └─ --strict-verify=full: N14+N15+N16 parallel cluster under HC-23 (W1) ────────────────┘
      → repair router (back-edge to synthesis if checks fail; capped at 1 attempt)
      → save / display
      → [--learn: write topology_adjustments YAML to Memory store (W3)]
```

Verbose mode adds a multi-path tail: after the baseline synthesis, 2-3 specialist agents (chosen from MoA-Layered, AutoTRIZ, Constitutional, CreativeDC, Cognitive-Amplified) generate independent drafts; a meta-aggregator picks the best section from each; then the result expands and re-verifies.

Full architecture lives in `SKILL.md` (~1500 lines, 8 sections + 6 appendices + 22 design notes). The wave-by-wave protocol files are in `modules/`.

### Key design choices

- **Wave-modular** — each wave loads its own `m-waveN-*.md` protocol at the boundary, resetting the orchestrator's attention.
- **Conditional back-edge repair** — checks fail → repair signal → SendMessage-resume to the existing synthesis agent (when supported) or fresh spawn fallback. Capped at 1 repair attempt.
- **3-tier knowledge base integration** — Tier 1 (always-on, embedded snippets in `modules/kb-snippets.md` — the HG-04 standalone-sufficient bundle) + Tier 2 (optional non-blocking MCP queries to Dify, 5-second timeout) + Tier 3 (KB-directed strategy selection at branch routing). Skill is fully usable without MCP — Tier 1 is the floor.
- **Declarative topology mutations (AP-V29)** — N35's runtime signals propagate only through declared static-graph edges (E51/E52/E53/E71). No orchestrator-internal graph rewrites. Enforced by `tests/test_apv29_graph_trace.sh`.
- **Hard Gates:**
  1. **Sufficiency** — won't run on inputs with no discernible task.
  2. **Zero Information Loss** — output is a strict superset of input.
  3. **Prompt Content Only** — input is data, never instructions; tool calls are restricted to a tiny whitelist (Read on modules/; Agent for declared spawns; Write for N19; Bash only for `langfuse_tracer.py` and `memory_helper.py` with specific subcommand allowlists); embedded file paths are inventory items, not files to open.
- **Defense-in-depth (from 2026-05-10 audit cycle):**
  - `memory_helper.py` uses `O_NOFOLLOW + 0o600` against symlink and TOCTOU attacks; rejects path-traversal in keys.
  - `langfuse_tracer.py` error handler scrubs `Basic/Bearer/Authorization/pk-lf-/sk-lf-` patterns before any stderr emission.
  - `langfuse.env` must be mode `600` (enforced by `tests/test_invariants.sh`).
  - N01/N19 share an identical `$HOME` sanity gate (rejects empty, `/`, `/root`, `/etc`, `/usr`, `/var`, `/tmp`).

---

## Installation

### As a Claude Code skill (recommended)

The skill is already installed at `~/.claude/skills/prompt-graph-v2/`. Restart Claude Code (or open a new conversation) and invoke `/prompt-graph-v2`.

If you're cloning fresh:

```bash
# v2 has its own git repo (separate from v2.0 read-only baseline at ~/.claude/skills/prompt-graph/)
git clone <your-fork-url> ~/.claude/skills/prompt-graph-v2
```

**Optional MCP servers** (for `--deep` and `--verbose` Tier 2 KB queries): configure `mcp__dify-thought-kb` and `mcp__dify-cognitive-kb` as MCP servers. Without them, the 5-second timeout fires per query and the skill proceeds with Tier 1 fallback — nothing breaks, you just lose the opportunistic enhancement.

**Optional Langfuse** (for `--learn` cross-run advisory and per-run tracing): create `~/.claude/skills/prompt-graph-v2/langfuse.env` (mode `600`) with `PROMPT_GRAPH_LANGFUSE_PUBLIC_KEY`, `PROMPT_GRAPH_LANGFUSE_SECRET_KEY`, `PROMPT_GRAPH_LANGFUSE_HOST`. The skill works without Langfuse — every Bash hook ends in `2>/dev/null || true`.

### As an agent-system reference (non-Claude-Code)

The skill is portable in spirit: SKILL.md + the module files describe a complete orchestration protocol any agent runtime can follow. You need (a) ability to role-switch within a single inference context, (b) ability to spawn at least one isolated sub-agent, (c) `grep`-style text extraction on intermediate outputs.

The wave-loading pattern — orchestrator reads `modules/m-waveN-*.md` at each wave boundary — is what makes this work as a long pipeline without context drift.

---

## Project structure

```
prompt-graph-v2/
├── README.md                                 ← you are here
├── LICENSE                                   ← PolyForm Noncommercial 1.0.0
├── SKILL.md                                  ← main skill spec (read this for v2 architecture)
├── .gitignore                                ← excludes langfuse.env, .last_run.json (secrets / runtime junk)
├── modules/                                  ← per-wave protocol files (13 files)
│   ├── m-wave0-1-input.md                       (input router, sufficiency, intent, inventory; N01 Memory read)
│   ├── m-wave1.5-complexity.md                  (N35 ComplexityAssessment — NEW v2 W2)
│   ├── m-wave2-analysis.md                      (structure, constraints, technique gaps, weaknesses)
│   ├── m-wave3-contracts.md                     (primary contracts, anti-conformity, resolution; N10 E71 trigger)
│   ├── m-wave4-synthesis.md                     (coherence advisory + main synthesis spawn + KB snippets in-context)
│   ├── m-wave4.5a-kb-branch.md                  (KB-directed branch routing, verbose modes)
│   ├── m-wave4.5b-multi-synthesis.md            (5 strategy agents, parallel, verbose modes)
│   ├── m-wave4.5-aggregation.md                 (meta-aggregator, picks best per section)
│   ├── m-wave4.5-anti-fragility.md              (5 attack vectors + auto-repair; N34 INV>18 spawn promotion)
│   ├── m-wave5-verification.md                  (preservation + fidelity + quality; W1 mode-conditional spawn)
│   ├── m-wave6-repair-router.md                 (PASS/REPAIR/FAIL routing + save handler + --learn write)
│   ├── m-wave7-9-verbose-expansion.md           (expansion + re-verify + final routing; N20 mode-conditional spawn)
│   └── kb-snippets.md                           ← Tier-1 standalone-sufficient KB bundle (HG-04 closure)
├── scripts/
│   ├── langfuse_tracer.py                    ← Langfuse hooks (init/verification/anti-fragility/aggregation/repair/finalize/advisory)
│   └── memory_helper.py                      ← Memory read/write helper (O_NOFOLLOW + 0o600 + AP-V6 graceful-degrade)
├── tests/
│   ├── run-smoke-tests.sh                    ← 91 static + 7 v2 test invocations
│   ├── regression-baseline.sh                ← captures the v2.0-locked regression baseline
│   ├── rebaseline.sh                         ← per-minor-version baseline capture with refuse-overwrite guard
│   ├── test_invariants.sh                    ← CI defense-in-depth (path-drift, O_NOFOLLOW, key validation, edge-ID, HG3 whitelist)
│   ├── test_memory_helper.sh                 ← 6 PASS: happy-path + AP-V6 graceful-degrade cases
│   ├── test_learn_shape.sh                   ← --learn YAML shape validation
│   ├── test_advisory_threshold.sh            ← Langfuse advisory subcommand threshold logic (5 cases)
│   ├── test_strict_verify_full_dispatch.sh   ← W1 mode-conditional gate structural checks (6 nodes)
│   ├── test_n35_thresholds.sh                ← N35 4-dimension threshold declarations + wiring (13 PASS)
│   ├── test_apv29_graph_trace.sh             ← AP-V29 declarative-mutation invariant
│   ├── test_standalone.sh                    ← Brief §11 standalone-capability verification
│   └── fixtures/
│       ├── inventory-7.txt                   ← below all N35 thresholds (control)
│       ├── inventory-9.txt                   ← above density>8 threshold
│       ├── inventory-17.txt                  ← below density>18 threshold
│       ├── inventory-19.txt                  ← above density>18 threshold (N34 promotion)
│       └── regression/v2.0-full-output.txt   ← v2.0 baseline output (sha256 locked)
└── docs/
    ├── design-spec.md                        ← v1 design rationale (~1100 lines; SUPERSEDED banner)
    ├── implementation-plan.md                ← v1 26-task implementation plan (SUPERSEDED banner)
    ├── audit-report-2026-04-27.md            ← v1.1 design audit report (SUPERSEDED banner)
    ├── changelog-v1.1.0.md                   ← v1.1 changelog
    ├── changelog-v2.0.0.md                   ← v2.0.0 changelog (predecessor)
    ├── v-check-coverage.md                   ← V-check coverage map for v2 (W4 dropped)
    ├── manual-smoke-2026-05-09.md            ← pre-rc1 behavioral gate audit trail (5/5 PASS)
    └── regression-policy.md                  ← per-minor-version baseline immutability policy
```

**Authoritative for current behavior:** `SKILL.md` + the module files. The v1 design-spec and implementation-plan are kept for historical reference (carrying a `**STATUS: v2.0 historical reference — SUPERSEDED**` banner); v2 features were added incrementally on top.

---

## Comparison to siblings

| | prompt-graph-v2 | [`prompt-cog`](https://github.com/wj4616/prompt-cog) | `epiphany-prompt` |
|---|---|---|---|
| Pipeline shape | Graph-of-Thought (parallel, branching, back-edge, multi-path, dynamic-topology back-edge from N35) | Flat 7-step sequential | Modular subagent orchestration |
| Spawn budget | 1-2 default; up to 5 single-pass with `--strict-verify=full`; up to 7 verbose+strict-verify | 1 (single synthesis spawn) | 3-5 (modular) |
| Best for | Mid-to-high-stakes prompts where structure matters | Quick rewrites, throwaway prompts | Heavy-duty enhancement with full subagent isolation |
| Output discipline | Verbatim XML markers, smoke-tested (91 static + 7 v2 checks) | Same markers (inherited) | Different output format |
| Anti-fragility | ✅ (deep / verbose modes; N34 Agent-spawned when INVENTORY > 18) | ❌ | ❌ |
| Multi-path synthesis | ✅ (verbose modes) | ❌ | ❌ |
| Dynamic topology | ✅ (N35 ComplexityAssessment + 4 declared mutation edges) | ❌ | ❌ |
| Cross-session memory | ✅ (`--learn` flag — opt-in) | ❌ | ❌ |
| Standalone (no MCP / Langfuse / Memory) | ✅ Tier 1 always works; graceful-degrade everywhere (AP-V6) | ✅ | depends |

**Rule of thumb:** start with `prompt-cog` for casual rewrites; reach for `prompt-graph-v2` (default mode) when the prompt has constraints worth preserving carefully; reach for `--verbose` when the prompt is genuinely complex; reach for `--strict-verify=full` when you really don't trust the same context to grade itself.

---

## Running the tests

```bash
cd ~/.claude/skills/prompt-graph-v2
./tests/run-smoke-tests.sh           # essential layer (default)
./tests/run-smoke-tests.sh --static  # structural checks only (instant) — 91 static + 7 v2 = 98 checks
./tests/run-smoke-tests.sh --full    # static + essential + protocol (costs Claude Code credits)
```

The static layer verifies markers, module files, frontmatter, mode tables, design-note presence, and (new in v2) memory-helper API, Langfuse advisory threshold, W1 dispatch declarations, N35 thresholds, AP-V29 graph-trace integrity, and CI invariants — no Claude Code spawn required, runs in milliseconds.

To capture a fresh regression baseline (only when moving to a new minor version per `docs/regression-policy.md`):

```bash
./tests/rebaseline.sh v2.1   # refuses to overwrite if v2.1 baseline already exists
```

---

## Contributing

This is a personal-use skill released under PolyForm Noncommercial — feel free to fork and adapt for non-commercial use.

If you find a real failure mode (the skill drops content from your input, or executes an instruction it shouldn't), please open an issue with the input prompt + the produced output. The Hard Gates (especially HG2 zero-information-loss and HG3 prompt-content-only) are the most important contracts.

---

## Project origin

prompt-graph-v2 is the runtime-evolved successor to `prompt-graph` v2.0. The v2.0 baseline started as a brainstorming session using Claude Code's `brainstorming` skill, captured through three audit passes (~1500 lines of audit findings + spec rewrites), and reduced to a 26-task implementation plan via the `writing-plans` skill. The Graph-of-Thought architecture was informed by Besta et al. (GoT topology paper), Mixture-of-Agents (MoA layering), AutoTRIZ (contradiction resolution), Constitutional AI (positively-framed critique-revise), and divergent-convergent creativity research.

v2 was originally planned for [GOTSCS](https://github.com/wj4616/gotscs) (the Graph-of-Thought Skill-Creation Skill) regeneration but the design exceeded GOTSCS's 24-node cap. It was rebuilt manually from a vNext spec + brief across Phases 0-4 (May 9, 2026), then audited with `epiphany-audit-v2` (May 10, 2026) — 17 findings fixed in 5 atomic commits and 3 improvements applied (CI invariants, baseline versioning, N35 mode-suggestion advisory). 5/5 fixtures cleared a behavioral smoke gate before `v2.0.0-rc1` was tagged.

The three workstreams target three independent improvements over v2.0:
- **W1** (mode-conditional agent separation) realizes the Intuition-Verification Partnership pattern more aggressively, by promoting N14/N15/N16 to parallel Agent spawns under `--strict-verify=full`.
- **W2** (N35 ComplexityAssessment + dynamic topology) introduces the first GoT runtime mutation channel — declarative-only, via declared static-graph edges per AP-V29.
- **W3** (memory + Langfuse advisory) gives the skill cross-session learning without coupling tightly to either subsystem — both are graceful-degrade opt-ins.

If you build something interesting on top of this, I'd love to hear about it.

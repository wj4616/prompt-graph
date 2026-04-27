# prompt-graph

A Claude Code skill that enhances user-provided prompts using a Graph-of-Thought (GoT) execution topology. Positioned alongside [`prompt-cog`](../prompt-cog/) (flat 7-step sequential pipeline) and [`epiphany-prompt`](../epiphany-prompt/) (modular subagent-orchestrated). Inherits prompt-cog's output-marker discipline; adds GoT topology: parallel verifier group, branching router, conditional back-edge repair.

**License:** PolyForm Noncommercial 1.0.0 (see `LICENSE`).

---

## Status

| Artifact | State |
|---|---|
| `docs/design-spec.md` (~1100 lines) | ✅ Complete — approved design with all 20 nodes, 35 edges, 9 waves, 4 modes, 3 audit passes |
| `docs/implementation-plan.md` (~1800 lines) | ✅ Complete — 26 bite-sized tasks, each with TDD-style steps and per-task commits |
| `SKILL.md` (~800 lines) | ✅ Complete — 8 sections, 3 appendices, design notes, v1.1+ roadmap |
| `modules/m-wave*.md` (7 files) | ✅ Complete — per-wave protocol files for Waves 0–9 |
| `tests/run-smoke-tests.sh` | ✅ Complete — 18 tests A–R across static/essential/protocol tiers |

---

## What prompt-graph does

Takes a user-provided prompt and produces a semantically optimized, graph-of-thought-structured version — preserving all original meaning, technical content, and intent while maximizing effectiveness when consumed by AI systems.

**Invocation:**

```
/prompt-graph <your prompt>
/prompt-graph --minimal <your prompt>    # lighter pass (13 active nodes, 4 waves)
/prompt-graph --verbose <your prompt>    # adds expansion wave (all 20 nodes, 9 waves)
/prompt-graph --quiet <your prompt>      # orthogonal; combines with any mode
```

**Output:** enhanced prompt wrapped in `<prompt>...</prompt>` XML delimited by `---` lines, plus a save prompt (or auto-save in `--quiet` mode) to `~/docs/epiphany/prompts/DD-MM-{slug}.md`.

**Key architectural features:**

- Up to 20 nodes (N01–N20) organized into up to 9 waves
- One synthesis agent spawn baseline; up to 1 repair spawn (≤2 total — single-attempt cap enforced)
- Orchestrator-inline role-switched verification (PG3 = N14 ∥ N15 ∥ N16)
- Conditional back-edge repair (E19: N17 → N13 on FAIL + `completed_repairs = 0`)
- Wave-modular architecture: each wave's protocol lives in its own `modules/m-wave*.md` file, loaded via Read at each wave boundary for attention reset
- Standalone — no MCP runtime dependencies; KB intelligence baked into 3 embedded snippets in `m-wave4-synthesis.md`

See `docs/design-spec.md` Sections 1–2 and Design Notes for the full rationale.

---

## Installation

**As a Claude Code user:**

1. Clone or copy this entire `prompt-graph/` directory into your skills folder:
   ```bash
   cp -r prompt-graph/ ~/.claude/skills/
   ```
2. Restart Claude Code (or start a new conversation — skills are loaded per session).
3. Invoke `/prompt-graph <your prompt>` in any Claude Code chat.

**As an agent-system user (non-Claude-Code):**

The skill's `SKILL.md` + modules can be referenced as input context for any agent pipeline that supports structured prompt documents. The frontmatter is standard YAML; the body is markdown. Adapt the orchestration loop to your system:
- Orchestrator reads `SKILL.md` at session start
- At each wave boundary, orchestrator reads `modules/m-waveN-*.md` and follows that wave's protocol
- Only N13 (Wave 4) spawns an isolated agent; all other nodes execute in the orchestrator's own context
- Output markers (`=== ANALYST OUTPUT BEGIN/END ===` etc.) are the extractable handles between waves

Minimum system requirement: ability to (a) role-switch within a single inference context, (b) spawn at least one isolated sub-agent with a structured prompt, (c) do `grep`-style text extraction on intermediate outputs.

---

## Portability

The skill is self-contained by design:

- **No MCP dependencies** — all KB intelligence baked as embedded snippets in `modules/m-wave4-synthesis.md`. No runtime network calls.
- **No hardcoded absolute paths** — save directory `~/docs/epiphany/prompts/` uses `~` tilde expansion at write time. Per-user paths work on any Unix-like system.
- **No external sibling-skill reads required at runtime** — the T1–T13 technique catalog is inlined authoritatively in `modules/m-wave2-analysis.md` (other modules reference by section anchor). `prompt-cog` and `epiphany-prompt` are mentioned in design prose but not required for execution.
- **Deterministic output markers** — smoke tests in `tests/run-smoke-tests.sh` use `grep -qF` (fixed-string match) and `awk` (ordered multi-marker extraction). No language-specific parsers.
- **Standard POSIX test runner** — `tests/run-smoke-tests.sh` uses only `bash`, `grep`, `awk`, `cat`. Runs on any Unix system with `bash` 4+.

---

## Directory layout

```
prompt-graph/
├── README.md                              ← this file
├── LICENSE                                ← PolyForm Noncommercial 1.0.0
├── SKILL.md                               ← main orchestrator: frontmatter, 8 sections, appendices, design notes
├── modules/                               ← per-wave protocol files
│   ├── m-wave0-1-input.md                    (N01–N04)
│   ├── m-wave2-analysis.md                   (N05–N08 + T1–T13 reference)
│   ├── m-wave3-contracts.md                  (N09–N11)
│   ├── m-wave4-synthesis.md                  (N12 advisory + N13 spawn prompt + 3 KB snippets)
│   ├── m-wave5-verification.md               (N14–N16 verifiers + checks 6a–6l)
│   ├── m-wave6-repair-router.md              (N17 state machine + N18 + N19 with slug generation)
│   └── m-wave7-9-verbose-expansion.md        (N20 + Wave 8/9 re-read references)
├── tests/                                 ← smoke test infrastructure
│   └── run-smoke-tests.sh                    (18 tests A–R across static/essential/protocol tiers)
└── docs/
    ├── design-spec.md                     ← full design specification (authoritative reference for implementation)
    └── implementation-plan.md             ← 26-task implementation plan with per-task commits
```

---

## Executing the implementation plan

`docs/implementation-plan.md` contains 26 tasks, each with 2–5 bite-sized steps. To execute:

**Option 1: Subagent-driven (recommended)**

Open Claude Code in this repository and invoke:

```
/execute-plan docs/implementation-plan.md
```

(Or, if using the superpowers skill system directly: invoke `subagent-driven-development` with the plan path.)

Subagent-driven execution dispatches a fresh subagent per task, reviews changes between tasks, and commits after each.

**Option 2: Inline execution**

Use `executing-plans` skill for batch execution with checkpoints every 3–5 tasks. Lower overhead; loses fresh-context benefit.

**Option 3: Manual**

The plan is human-readable. A skilled developer can work through the 26 tasks directly.

In all cases: the plan tasks are ordered by file creation sequence (scaffold → SKILL.md sections → modules → test runner → validation). Each task commits independently, giving a clean git history.

---

## Design references

For deeper context, see `docs/design-spec.md` sections:

- **Section 2** — Locked architectural decisions with rationale
- **Section 4.5** — ASCII pipeline diagram (verbose path)
- **Section 4.6** — Node Registry (what each of the 20 nodes does)
- **Section 4.11** — GoT Controller Logic (how mode selection and back-edge routing work)
- **Section 4.16** — Design Notes (14 items covering trade-offs and source-prompt contradictions resolved)
- **Section 4.17** — v1.1+ Roadmap (`--strict-verify`, `--spec`/`--plan` modes, live MCP hybrid, etc.)

## Project origin

This skill was designed through a brainstorming session using the `brainstorming` skill, captured through three audit passes (spec-self-review + two deeper audit passes covering 15 + 6 issues respectively), and reduced to the implementation plan using the `writing-plans` skill. The design synthesis drew on the cognitive-KB (Tier-1 genius-mind traits: divergent–convergent thinking, anti-conformity, Intuition-Verification Partnership) and thought-KB (CoT/ToT/GoT topology research — latency/volume trade-off, aggregation patterns) queried via MCP at design time only. The runtime skill itself ships standalone.

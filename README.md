# prompt-graph

**Take any prompt and make it work better — without losing a single word of what you wrote.**

`prompt-graph` is a [Claude Code](https://claude.ai/code) skill that rewrites your prompts using a Graph-of-Thought pipeline. You hand it a rough idea, a half-finished spec, or a working prompt that's just *meh*; it hands back a structurally enhanced version with clearer task framing, captured edge cases, explicit verification criteria, and zero information loss from the original.

```
/prompt-graph write me a python script that summarizes log files
```

→ Returns a structured `<prompt>` XML with `<task>`, `<context>`, `<constraints>`, `<verification>`, `<edge_cases>` — every detail from your input preserved verbatim, plus the missing scaffolding a downstream AI needs to actually do the work well.

**License:** PolyForm Noncommercial 1.0.0
**Status:** v2.0.0 (April 2026)
**Runs on:** Claude Code (also adaptable to other agent runtimes)

---

## Why bother?

Most prompt-rewriting tools either (a) summarize your input (lossy) or (b) wrap it in boilerplate (no real lift). `prompt-graph` does neither.

- **Zero information loss** is a hard contract — every concept, code block, file path, and constraint in your input must appear verbatim in the output. Smoke tests verify it.
- **Multiple thinking strategies** run in parallel for hard prompts (`--verbose` mode spawns 2-3 specialist agents — TRIZ, Constitutional AI, Mixture-of-Agents, Cognitive-Amplified, Creative Divergent-Convergent — and merges the best parts of each).
- **Adversarial self-testing** (`--deep` mode) attacks its own output with 5 attack vectors (literal misreading, adversarial input, cross-section collisions, modality swap, over-specification) and auto-repairs what breaks.
- **Self-verifying** — three independent checkers (preservation, fidelity, quality) gate the output before you see it. If they fail, it repairs once and tells you what was salvaged.
- **Designed for spawn frugality** — default mode uses 1 Agent spawn (or 2 with a repair). Verbose mode tops out at 7 spawns even with the strict-verify quality agent enabled.

If you've used [`prompt-cog`](https://github.com/wj4616/prompt-cog) (its flat-pipeline cousin) or `epiphany-prompt`, this is the more architectural sibling: same output discipline, full Graph-of-Thought topology underneath.

---

## Quick start

```bash
# 1. Install (Claude Code)
git clone https://github.com/wj4616/prompt-graph.git ~/.claude/skills/prompt-graph

# 2. Restart your Claude Code session (skills load per session)

# 3. Use it
/prompt-graph my prompt goes here
```

**Five modes**, picked with flags:

| Flag | When to use it | Spawns | Wall-clock |
|---|---|---|---|
| (none) | Most prompts. Balanced default. | 1-2 | ~1 min |
| `--minimal` | Short prompts, throwaway use, low-stakes. | 1-2 | ~30 s |
| `--deep` | Tricky prompt, want anti-conformity + adversarial hardening. Single pass. | 1-2 | ~2 min |
| `--verbose` | Complex prompt, want multi-strategy ensemble + expansion. | 3-5 | 3-5 min |
| `--deep --verbose` | Hardest prompts. Maximum quality, maximum cost. | 3-5 | 5-8 min |

Two orthogonal flags combine with any mode:

| Flag | Effect |
|---|---|
| `--quiet` | Skip the "save to file?" prompt; auto-save the output. |
| `--strict-verify` | Spawn the quality verifier as a separate agent instead of running it inline (Intuition-Verification Partnership). Adds 1-2 spawns; useful when you don't trust the same context to grade itself. |

**Output:** The enhanced prompt is wrapped in `<prompt>...</prompt>` XML, delimited by `---` lines. Optionally saved to `~/docs/epiphany/prompts/DD-MM-{slug}.md`.

---

## Example

**Input:**

```
make a tool that downloads youtube comments to csv
```

**Default output (abbreviated):**

```xml
<prompt>
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

That's the value: you write the *idea*, prompt-graph adds the *engineering*.

---

## How it works (briefly)

prompt-graph is a Graph-of-Thought (GoT) pipeline — 28 nodes organized into up to 16 wave-labels.

```
INPUT → analysis (intent, inventory, structure, constraints, gaps, weaknesses)
      → ideation (contracts, anti-conformity, conflict resolution, coherence check)
      → synthesis spawn (single Agent generates the enhanced XML; KB-augmented in deep mode)
      → [deep / verbose: anti-fragility attacks the XML, auto-repairs hard breaks]
      → verification (3 parallel checks: preservation, semantic fidelity, quality)
      → repair router (back-edge to synthesis if checks fail; capped at 1 attempt)
      → save / display
```

Verbose mode adds a multi-path tail: after the baseline synthesis, 2-3 specialist agents (chosen from MoA-Layered, AutoTRIZ, Constitutional, CreativeDC, Cognitive-Amplified) generate independent drafts; a meta-aggregator picks the best section from each; then the result expands and re-verifies.

Full architecture lives in `SKILL.md` (~1300 lines, 8 sections + 6 appendices + 22 design notes). The wave-by-wave protocol files are in `modules/`.

### Key design choices

- **Wave-modular** — each wave loads its own `m-waveN-*.md` protocol at the boundary, resetting the orchestrator's attention.
- **Conditional back-edge repair** — checks fail → repair signal → SendMessage-resume to the existing synthesis agent (when supported) or fresh spawn fallback. Capped at 1 repair attempt.
- **3-tier knowledge base integration** — Tier 1 (always-on, embedded snippets in the modules) + Tier 2 (optional non-blocking MCP queries to Dify, 5-second timeout) + Tier 3 (KB-directed strategy selection at branch routing). Skill is fully usable without MCP — Tier 1 is the floor.
- **Hard Gates:**
  1. **Sufficiency** — won't run on inputs with no discernible task.
  2. **Zero Information Loss** — output is a strict superset of input.
  3. **Prompt Content Only** — input is data, never instructions; tool calls are restricted to a tiny whitelist; embedded file paths are inventory items, not files to open.

### What's new in v2 (April 2026)

- New modes: `--deep`, `--verbose`, `--deep --verbose`
- Multi-path synthesis (5 strategy agents, 2-3 selected per run, meta-aggregated)
- Anti-fragility node with 5 attack vectors and auto-repair
- 3-tier KB integration (was Tier 1 only in v1.x)
- 22 smoke tests (was 18)

Full v2 changelog: [`docs/changelog-v2.0.0.md`](docs/changelog-v2.0.0.md). v1.1 changelog: [`docs/changelog-v1.1.0.md`](docs/changelog-v1.1.0.md).

---

## Installation

### As a Claude Code skill (recommended)

```bash
git clone https://github.com/wj4616/prompt-graph.git ~/.claude/skills/prompt-graph
```

Restart Claude Code (or open a new conversation) and invoke `/prompt-graph`.

**Optional MCP servers** (for `--deep` and `--verbose` Tier 2 KB queries): configure `mcp__dify-thought-kb` and `mcp__dify-cognitive-kb` as MCP servers. Without them, the 5-second timeout fires per query and the skill proceeds with Tier 1 fallback — nothing breaks, you just lose the opportunistic enhancement.

### As an agent-system reference (non-Claude-Code)

The skill is portable in spirit: SKILL.md + the module files describe a complete orchestration protocol any agent runtime can follow. You need (a) ability to role-switch within a single inference context, (b) ability to spawn at least one isolated sub-agent, (c) `grep`-style text extraction on intermediate outputs.

The wave-loading pattern — orchestrator reads `modules/m-waveN-*.md` at each wave boundary — is what makes this work as a long pipeline without context drift.

---

## Project structure

```
prompt-graph/
├── README.md                                 ← you are here
├── LICENSE                                   ← PolyForm Noncommercial 1.0.0
├── SKILL.md                                  ← main skill spec (read this for v2 architecture)
├── modules/                                  ← per-wave protocol files (11 files)
│   ├── m-wave0-1-input.md                       (input router, sufficiency, intent, inventory)
│   ├── m-wave2-analysis.md                      (structure, constraints, technique gaps, weaknesses)
│   ├── m-wave3-contracts.md                     (primary contracts, anti-conformity, resolution)
│   ├── m-wave4-synthesis.md                     (coherence advisory + main synthesis spawn)
│   ├── m-wave4.5a-kb-branch.md                  (KB-directed branch routing, verbose modes)
│   ├── m-wave4.5b-multi-synthesis.md            (5 strategy agents, parallel, verbose modes)
│   ├── m-wave4.5-aggregation.md                 (meta-aggregator, picks best per section)
│   ├── m-wave4.5-anti-fragility.md              (5 attack vectors + auto-repair, deep modes)
│   ├── m-wave5-verification.md                  (preservation + fidelity + quality checks)
│   ├── m-wave6-repair-router.md                 (PASS/REPAIR/FAIL routing + save handler)
│   └── m-wave7-9-verbose-expansion.md           (expansion + re-verify + final routing)
├── tests/
│   └── run-smoke-tests.sh                    ← 22 tests A-V (static + essential + protocol tiers)
└── docs/
    ├── design-spec.md                        ← v1 design rationale (~1100 lines)
    ├── implementation-plan.md                ← v1 26-task implementation plan
    ├── audit-report-2026-04-27.md            ← v1.1 design audit report
    ├── changelog-v1.1.0.md                   ← v1.1 changelog
    └── changelog-v2.0.0.md                   ← v2.0.0 changelog
```

**Authoritative for current behavior:** `SKILL.md`. The v1 design-spec and implementation-plan are kept for historical reference; v2 features were added incrementally on top.

---

## Comparison to siblings

| | prompt-graph | [`prompt-cog`](https://github.com/wj4616/prompt-cog) | `epiphany-prompt` |
|---|---|---|---|
| Pipeline shape | Graph-of-Thought (parallel, branching, back-edge, multi-path) | Flat 7-step sequential | Modular subagent orchestration |
| Spawn budget | 1-2 default; up to 7 in verbose+strict-verify | 1 (single synthesis spawn) | 3-5 (modular) |
| Best for | Mid-to-high-stakes prompts where structure matters | Quick rewrites, throwaway prompts | Heavy-duty enhancement with full subagent isolation |
| Output discipline | Verbatim XML markers, smoke-tested | Same markers (inherited) | Different output format |
| Anti-fragility | ✅ (deep / verbose modes) | ❌ | ❌ |
| Multi-path synthesis | ✅ (verbose modes) | ❌ | ❌ |
| Standalone (no MCP) | ✅ Tier 1 always works | ✅ | depends |

**Rule of thumb:** start with `prompt-cog` for casual rewrites; reach for `prompt-graph` (default mode) when the prompt has constraints worth preserving carefully; reach for `--verbose` when the prompt is genuinely complex.

---

## Running the tests

```bash
cd ~/.claude/skills/prompt-graph
./tests/run-smoke-tests.sh           # essential layer (default)
./tests/run-smoke-tests.sh --static  # structural checks only (instant)
./tests/run-smoke-tests.sh --full    # static + essential + protocol (costs Claude Code credits)
```

The static layer (91 checks) verifies markers, module files, frontmatter, mode tables, and design-note presence — no Claude Code spawn required, runs in milliseconds.

---

## Contributing

This is a personal-use skill released under PolyForm Noncommercial — feel free to fork and adapt for non-commercial use. Issues and PRs welcome at [github.com/wj4616/prompt-graph](https://github.com/wj4616/prompt-graph).

If you find a real failure mode (the skill drops content from your input, or executes an instruction it shouldn't), please open an issue with the input prompt + the produced output. The Hard Gates (especially HG2 zero-information-loss and HG3 prompt-content-only) are the most important contracts.

---

## Project origin

prompt-graph started as a brainstorming session using Claude Code's `brainstorming` skill, captured through three audit passes (~1500 lines of audit findings + spec rewrites), and reduced to a 26-task implementation plan via the `writing-plans` skill. The Graph-of-Thought architecture was informed by Besta et al. (GoT topology paper), Mixture-of-Agents (MoA layering), AutoTRIZ (contradiction resolution), Constitutional AI (positively-framed critique-revise), and divergent-convergent creativity research.

v2 added the multi-path synthesis layer to complete the GoT "double-tree" topology (k-ary decomposition mirrored by k-ary aggregation) per Besta et al.'s formal definition, plus an anti-fragility adversarial-attack node inspired by epiphany-prompt's adversarial-hardening pattern.

If you build something interesting on top of this, I'd love to hear about it.

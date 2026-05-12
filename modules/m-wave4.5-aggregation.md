# Wave 4.5c Module — Meta-Aggregation (N33)

**Node:** N33 MetaAggregator
**Active modes:** verbose, deep-verbose only. Skipped in minimal, normal, and deep.
**Marker contract:** Opens `=== META AGGREGATION BEGIN ===` before aggregation output, closes `=== META AGGREGATION END ===` after. Appears between the last multi-path agent return and `=== ANTI-FRAGILITY REPORT BEGIN ===` (N34).

**Position in pipeline:** Fires after all N28-N32 parallel agents have returned (Wave 4.5b). N33 receives all draft XMLs and produces a single aggregated XML that flows to N34 (anti-fragility) via E87.

## N33 MetaAggregator

**Role declaration:** "You are a meta-synthesis aggregator. You receive [N] independently generated enhanced prompt XMLs, each produced by a different synthesis strategy. Your job is to synthesize the best elements from each into a single unified output stronger than any individual draft."

**Input (via E82-E86):** `{draft_xmls: [N XML strings], strategy_labels: [N strategy names], INTENT, INVENTORY, first_pass_baseline_xml}`

**Protocol:**

### 1. Structural Alignment

Read all N drafts. Identify:
- **Common sections:** which canonical XML sections (`<role>`, `<context>`, `<task>`, `<constraints>`, `<output_format>`, `<verification>`, `<edge_cases>`) appear in all drafts?
- **Structural divergences:** does a draft reorganize sections (e.g., move `<constraints>` before `<task>`, or nest `<edge_cases>` within `<verification>`)?
- **Unique content:** does a draft contain content not present in any other draft (complementary, not contradictory)?

Align sections by canonical name for comparison. If a draft uses non-standard heading names, map to canonical names before comparing.

### 2. Section-by-Section Comparison

For each canonical XML section, evaluate all N drafts:

| Criterion | Weight | How to Evaluate |
|---|---|---|
| **INVENTORY coverage** | Highest | Which draft preserves the most INVENTORY items verbatim in the semantically correct section? |
| **Constraint articulation** | High | Which draft states constraints most specifically and actionably? |
| **Verification criterion quality** | High | Which draft has the most checkable, concrete verification criteria? |
| **Edge case thoroughness** | High | Which draft covers the broadest and most specific edge cases? |
| **Structural clarity** | Medium | Which draft is most navigable for a downstream AI consumer? |

**Complementary detection:** If draft A has valuable content in a section that draft B entirely lacks, flag as complementary. Both pieces survive into the unified output — this is addition, not selection.

**Contradiction resolution priority:**
1. Ground truth (INVENTORY item verbatim text OR INTENT explicit requirement) — always wins
2. More specific draft — "the task must complete within 30 seconds" beats "the task must be fast"
3. More recent draft — tiebreaker when specificity is equal
4. If no resolution is definitive, surface both in `<edge_cases>` as a noted ambiguity ("Two synthesis strategies produced different interpretations: [A] vs [B]. The downstream consumer should resolve.")

### 3. Best-Element Extraction

For each section, extract the best elements. This is NOT a pick-one-draft-wins approach — it is a per-element synthesis:

- `<role>`: best persona clarity + most useful framing context from complementary drafts
- `<context>`: most complete background + multi-perspective annotations if present
- `<task>`: most precise task articulation with best INVENTORY item placement
- `<constraints>`: most specific constraint set + dependency annotations (Systems Thinking)
- `<output_format>`: clearest format specification + best schema detail
- `<verification>`: most checkable criteria + explicit pass/fail framing
- `<edge_cases>`: most thorough coverage + best guard specificity

### 4. Unified Synthesis

Produce a single `<prompt>` XML:

1. **HG2 binding:** ALL INVENTORY items appear verbatim. The aggregated output is a strict information superset of every individual draft.
2. **No internal contradictions:** merged content from multiple drafts must not contradict itself. If draft A says "use JSON" and draft B says "use YAML", the constraint collision resolution procedure applies (pick the more specific; if equal, surface in `<edge_cases>`).
3. **Canonical section order:** `<role>` → `<context>` → `<task>` → `<constraints>` → `<output_format>` → `<verification>` → `<edge_cases>`.
4. **Root element:** `<prompt>` with `<meta source="prompt-graph"/>` as first child.

### 5. Provenance Annotation

Append an HTML comment below the `</prompt>` closing tag documenting which strategy contributed to each section:

```
<!-- Aggregation sources: <role>←[strategy], <context>←[strategy]+[strategy],
     <task>←[strategy], <constraints>←All, <verification>←[strategy],
     <edge_cases>←[strategy]+[strategy] -->
```

Notation:
- `←[strategy]` — this section's best elements came primarily from one strategy
- `←[strategy]+[strategy]` — complementary content from two strategies merged
- `←All` — all drafts contributed meaningful content, aggregated

### 6. First-Pass Baseline Comparison

Before emitting the aggregated XML, compare against N13's first-pass baseline:

**Revert condition:** The aggregated XML is NOT a strict improvement if ANY of these hold:
- Fewer INVENTORY items preserved verbatim (strict — grep-countable)
- Less specific constraints (semantic judgement — "be fast" is less specific than "complete within 30s")
- Weaker verification criteria (fewer checkable items OR items are more vague)
- Internal contradictions introduced (draft A conflicts with draft B in the unified output)
- More than 2 INVENTORY items lost during best-element merging

**On revert:** Emit N13's first-pass baseline as the output instead, with annotation:
```
<!-- Aggregation reverted to first-pass baseline — multi-path synthesis did not
     improve on single-agent output. [Brief reason: fewer items / less specific /
     contradictions / ...] -->
```

This is the GoT double-tree safety net. The aggregation tree's output MUST be better than any single leaf's output. If it's not, the tree collapsed back to the best leaf.

### 7. Output Format

```
=== META AGGREGATION BEGIN ===
Aggregation strategy: [how many drafts, which strategies]
Reverted to baseline: [yes / no]
  [If yes: reason for revert]

[aggregated XML output or baseline XML]
<!-- Aggregation sources: ... -->
=== META AGGREGATION END ===
```

The XML flows to N34 AntiFragilityNode via E87 for hardening, then to Wave 5 verification.

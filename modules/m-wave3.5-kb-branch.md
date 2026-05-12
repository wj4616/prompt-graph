# Wave 3.5 Module — KB Branch Routing (N27)

**Node:** N27 KBBranchRouter
**Active modes:** verbose, deep-verbose only. Skipped in minimal, normal, and deep.
**Marker contract:** Opens `=== KB BRANCH PLAN BEGIN ===` before the branch plan, closes `=== KB BRANCH PLAN END ===` after. Appears between `=== SYNTHESIS RETURN END ===` (Wave 4 first-pass) and the Wave 4.5 multi-path synthesis spawn.

**Position in pipeline:** Fires after N13's first-pass baseline returns (and after the verbose handoff note in m-wave4-synthesis.md). N27 is the decision node that determines how the multi-path synthesis layer (N28-N32) is configured.

## N27 KBBranchRouter

**Role:** None (structural routing, no role declaration).

**Input (via E80):** `{draft_xml (N13 first-pass baseline), INTENT, INVENTORY, resolved_contracts, mode_flags, analysis_blocks?}`. In deep-verbose mode, resolved_contracts include anti-conformity additions from N10.

**Protocol:**

### 1. Complexity Assessment

Count INVENTORY items across all 20 keys, constraint count from `INVENTORY.key_constraints`, named entity count from `INVENTORY.named_entities`. Classify:

| Tier | Item Count | Constraint Count | Typical Input Shape |
|---|---|---|---|
| **Simple** | ≤8 items | ≤2 constraints | Single-task, few requirements, straightforward |
| **Moderate** | 9–18 items | 3–6 constraints | Multi-part task, cross-references, some constraint interaction |
| **Complex** | >18 items | >6 constraints | Dense specification, interdependent constraints, multiple named entities |

### 2. KB Query (Optional, Non-Blocking)

Query `mcp__dify-thought-kb__ToT-GoT-Cot-KB-retrieval` with a summary of input characteristics:
- Item count, constraint count, complexity tier
- Whether resolved_contracts includes anti-conformity additions (deep-verbose)
- Whether conflict_log from N11 is non-empty
- Primary INVENTORY categories with non-empty values

**On response:** Use the topology/strategy recommendation to inform branch width and strategy selection.

**On no response / error / timeout:** Use the complexity heuristic below. **Pipeline does not wait on KB.** Query fires; N27 proceeds with whatever is available at decision time. The KB is an advisor, not a gate.

In deep-verbose mode, additionally query `mcp__dify-cognitive-kb__cognitive-research-kb-dify` for the cognitive trait best matching the input's thinking demands. Fallback to "Precision Forcing" (universal fallback trait) if query fails or returns empty.

### 3. Branch Width Determination

| Complexity | Branch Width | Active Agents | Rationale |
|---|---|---|---|
| Simple | 2 | Best-fit strategy + second-best-fit | 2 strategies sufficient; >2 over-diversifies simple inputs |
| Moderate | 2 | Best-fit strategy + second-best-fit | 2 strategies give meaningful diversity without redundant coverage |
| Complex | 3 | Best-fit + second-best-fit + third-best-fit | 3 strategies needed for adequate coverage of the constraint space |

**O14 budget-conscious downgrade:** If the assembled spawn prompts for all branch agents approach O7's ~15k token threshold (per-agent context pressure detected), downgrade branch width by 1 (3→2, 2→2 — floor at 2). Spawn budget is not the issue (parallel semantics, wall-clock cost ≈ 1); per-agent context quality is. A 3-agent branch with cramped context is worse than a 2-agent branch with room.

### 4. Strategy Selection

For each branch slot, select the best-fit strategy family. Use the strategy-to-input matching heuristic from KB Snippet 5. Selection is ordered: best-fit first, then next-best, etc.

| Strategy | Agent | Best Fit When | Selection Signal |
|---|---|---|---|
| **MoA-layered** | N28 | INVENTORY spans >3 Tier-1 categories, cross-section coherence matters, multiple contracts target different XML sections | High INVENTORY category diversity |
| **AutoTRIZ** | N29 | conflict_log non-empty, contradictory constraints detected, tradeoffs need explicit resolution rather than winner-picking | Non-empty N11 conflict_log |
| **Constitutional** | N30 | Input is quality/safety/alignment-sensitive, explicit principles improve output | Tone markers suggest formal/regulatory context |
| **CreativeDC** | N31 | Input is open-ended, exploratory, creative — benefits from structural exploration before content execution | Sparse constraints, broad intent |
| **Cognitive-Amplified** | N32 | Input is high-stakes, complex enough to benefit from genius-mind cognitive trait overlay | Deep-verbose mode OR >18 INVENTORY items with dense named entities |
| **Default/Ensemble** | (mapped to N28) | No strategy clearly dominates — balanced T1-T13 without strategy bias | Fallback when two strategies have nearly equal fit |

**Deep-verbose mode rule:** N32 (Cognitive-Amplified) is ALWAYS one of the selected agents. Deep mode's purpose is cognitive amplification — skipping the cognitive agent would contradict the depth flag. In deep-verbose with complexity=Simple, the 2-agent branch is: Cognitive-Amplified (N32) + best-fit other strategy. The cognitive trait is assigned dynamically from the MCP query; fallback to "Precision Forcing."

### 5. Branch Plan Emission

```
=== KB BRANCH PLAN BEGIN ===
Complexity: [Simple / Moderate / Complex]
Branch width: [2 / 3]
KB sources: [MCP query results if available, "complexity heuristic" if fallback]

Branches:
  1. N[28-32] — [strategy_family]
     Why: [one-line rationale tying input characteristics to strategy selection]
     [Cognitive trait: <trait_name> — only for N32]
  2. N[28-32] — [strategy_family]
     Why: [one-line rationale]
     [Cognitive trait: ...]
  [3. ... — only when branch_width=3]

Deep-verbose augmentation: [active / not active]
  [If active: anti-conformity contracts present in resolved_contracts — all N
   agents receive them. N32 cognitive trait: <assigned_trait>.]
=== KB BRANCH PLAN END ===
```

### 6. Spawn Prompt Assembly (per Agent)

For each agent in the branch plan, N27 assembles the spawn prompt:

1. `=== NORMALIZED INPUT ===` — verbatim normalized input (same as N13 received)
2. `=== ANALYSIS ===` — extracted ANALYST OUTPUT body (same as N13 received)
3. `=== CONTRACTS ===` — extracted IDEATION OUTPUT body (same as N13 received, includes anti-conformity additions in deep-verbose)
4. Strategy-specific delta — appended after `=== CONTRACTS END ===`, from the Multi-Synthesis module (m-wave4-multi-synthesis.md)

The assembled spawn prompt is passed to the multi-path synthesis layer via E81 (fan to selected N28-N32 agents). Per-agent assembly is documented in m-wave4-multi-synthesis.md; N27's output is the branch plan + the routing decision. The actual spawns fire in Wave 4.5b.

### 7. KB Source Annotation Format

Every KB-derived decision in the branch plan MUST annotate its provenance:

| Source | Annotation Format |
|---|---|
| MCP query returned | `[KB: <server_name> — "<key finding, ≤80 chars>"]` |
| Complexity heuristic (fallback) | `[Heuristic: complexity tier → branch width N]` |
| KB Snippet 5 (static) | `[Snippet 5: strategy matching]` |
| KB Snippet 6 (static) | `[Snippet 6: cognitive trait — <trait>]` |

This is a zero-hallucination mechanism. Every claim about what KB research recommends must cite whether it came from a runtime MCP query (dynamic, potentially fresher) or an embedded snippet (static, always available). If the provenance is unclear, default to `[Snippet 5/6]` — the embedded snippets are the ground truth; MCP queries are advisory augmentation.

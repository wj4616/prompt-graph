# Wave 2 Module — Structured Analysis (v2: 4 blocks collapsed to 2)

**Nodes:** N05 StructureAnalyzer + N06 ConstraintAuditor (merged), N07 TechniqueGapAnalyst + N08 WeaknessDetector (merged)
**Active modes:** normal, deep, verbose, deep-verbose only (skipped in minimal)
**Marker contract:** Continues ANALYST OUTPUT block opened in Wave 1. Closes `=== ANALYST OUTPUT END ===` after the merged N07+N08 block's WEAKNESSES sub-section.
**Role:** Structured prompt analyst (continued from Wave 1's N03/N04 role declaration).

**v2 change — 4 blocks collapsed to 2 (saves 2 inferences):**
- Wave 2a: N05+N06 merged → single role-switched block producing both `### STRUCTURE + CONSTRAINTS` sub-sections
- Wave 2b: N07+N08 merged → single role-switched block producing both `### TECHNIQUE GAPS + WEAKNESSES` sub-sections

## Block Header Emission Contract (v2 — merged)

Each merged block opens with a single markdown H3 header:

- Merged N05+N06 block emits `### STRUCTURE + CONSTRAINTS` as the first line, then produces both sub-sections within a single inference.
- Merged N07+N08 block emits `### TECHNIQUE GAPS + WEAKNESSES` as the first line, then produces both sub-sections within a single inference.

These headers are the smoke-test grep targets for Test B (negative-assertion: must be absent in minimal mode) and Test R (GoT controller path selection). Do NOT vary the casing, decorate with bold/italics, or add suffixes. The header line is the contract; everything below it is the block body.

## Merged N05+N06 — Structure + Constraints Analysis

**Input:** normalized_input (from N02 via E00a + E00b — both edges now feed the single merged block).

**Protocol:**

1. Read the normalized_input and identify both organizational structure and all constraints in a single analysis pass.
2. Produce a combined STRUCTURE + CONSTRAINTS block containing:
   - **Current organization:** How the prompt is currently structured (paragraphs, sections, bullets, etc.)
   - **Missing structural elements:** What structural components are absent (section headers, constraints block, output format spec, edge case handling, etc.)
   - **Structural coherence assessment:** How well the existing structure supports the prompt's stated intent
   - **Explicit constraints:** Directly stated requirements, limitations, and rules
   - **Implicit constraints:** Constraints implied by the intent, context, or domain but not directly stated
   - **Conflict surface:** Areas where constraints may contradict or create tension
   - **Cross-reference note:** Constraints detected in the text that inform structural observations (and vice versa) should be noted.

**Output:** Combined STRUCTURE + CONSTRAINTS block (text, single inference covering both former N05 and N06 dimensions).

## Merged N07+N08 — Technique Gaps + Weaknesses

**Input:** `{normalized_input, INTENT, STRUCTURE, CONSTRAINTS}` (from N02 via E00c+E00d, N03 via E03, and the merged N05+N06 output via E06+E07).

**Protocol:**

1. Read the normalized_input with the INTENT block, STRUCTURE, and CONSTRAINTS as context.
2. Produce a combined TECHNIQUE GAPS + WEAKNESSES block containing:

   **Technique Gap Analysis:**
   - For each of the 13 techniques (T1–T13), assess:
     - **Already present:** Is this technique already partially or fully applied?
     - **Needed:** Would applying this technique meaningfully improve the prompt?
     - **Impact:** If needed, estimate expected improvement (high/medium/low)
   - **Streamlined assessment:** Skip techniques where the gap is clearly absent (no need for detailed analysis when a technique is obviously irrelevant). Focus depth on techniques where the gap analysis is non-obvious.
   - Present results in tabular form.

   **KB query (deep, verbose, deep-verbose only — optional, non-blocking):**
   - Fire query to `mcp__dify-thought-kb__ToT-GoT-Cot-KB-retrieval` with a summary of input characteristics: "topology recommendation for [intent summary]"
   - Pipeline does NOT wait on KB response. If response arrives before the block is emitted, incorporate topology-grounded recommendations into the technique gap analysis (e.g., "GoT topology recommended — T6 structured reasoning injection is higher-impact than static T1-T13 analysis would suggest").
   - On no response / failure: proceed with static T1-T13 analysis. Tier 1 fallback.

   **Weakness Detection:**
   - Synthesize findings from the input, INTENT, STRUCTURE, and CONSTRAINTS.
   - Identify specific weaknesses — numbered W1…Wn, each with:
     - **Weakness description:** What the weakness is
     - **Impact score:** high / medium / low
     - **Causal explanation:** WHY this is a weakness and how it degrades prompt effectiveness
   - Format example: `"Weakness: vague success criteria [high] — causal: without measurable criteria, the synthesizer cannot determine when enhancement is complete, leading to under- or over-specified output."`
   - **Step self-check (non-blocking annotations):**
     - INTENT specificity: is the INTENT block specific enough to guide enhancement?
     - WEAKNESSES causal explanation: does each weakness include a causal mechanism?
     - INVENTORY completeness: are there items in the input not yet captured in INVENTORY?

**Output:** Combined TECHNIQUE GAPS + WEAKNESSES block (text, single inference covering both former N07 and N08 dimensions).

**Marker contract:** `=== ANALYST OUTPUT END ===` closes after this block.

## T1–T13 Reference Table (Authoritative for prompt-graph)

*Source: prompt-cog Enhancement Techniques Reference — authoritative for this module. Other modules reference by section anchor.*

| # | Technique | Trigger | Application |
|---|-----------|---------|-------------|
| T1 | XML semantic structuring | 2+ logical sections | Wrap in `<context>`, `<task>`, `<constraints>`, etc. |
| T2 | Prompt decomposition | Monolithic block | Split into labeled sections |
| T3 | Explicit constraint specification | Implicit assumptions | Convert to DO/DO NOT constraints |
| T4 | Role/persona assignment | No expert framing | Add calibrated persona |
| T5 | Output format templates | No output spec | Add XML/JSON/markdown template |
| T6 | Structured reasoning injection | Multi-step analysis | Add CoT guidance |
| T7 | Priority hierarchy | Conflicting constraints | "If X and Y conflict, prioritize X" |
| T8 | Boundary/edge case spec | Ambiguous inputs | "If [edge case], then [behavior]" |
| T9 | Few-shot exemplar injection | Task benefits from demo | 1-3 examples covering normal + edge |
| T10 | Self-critique/validation | Quality-critical output | "Verify [criteria]. If any fail, revise." |
| T11 | Context preservation anchoring | Long prompt, recurring concepts | Label key concepts early |
| T12 | Audience calibration | No output consumer specified | Target reader, assumed knowledge |
| T13 | Escape hatch provision | Ambiguous completion | "If cannot determine X, state what's missing" |

**Application order:** T2→T1→T4→T3→T7→T6→T5→T8→T12→T9→T11→T10→T13

**Note on T13:** Place escape hatches in `<edge_cases>` or `<verification>`, not `<constraints>`. Constraints specify behavior; escape hatches handle ambiguity.

**Not every technique applies.** Apply only what gap analysis identifies as needed.

## Hard Gate 2 Reminder

Analysis is read-only — do not add content beyond what the input contains. The analyst identifies gaps and weaknesses; the ideation phase (Wave 3) generates enhancement contracts to address them.

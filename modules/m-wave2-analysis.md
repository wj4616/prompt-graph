# Wave 2 Module — Structured Analysis

**Nodes:** N05 StructureAnalyzer, N06 ConstraintAuditor, N07 TechniqueGapAnalyst, N08 WeaknessDetector
**Active modes:** normal, verbose only (skipped in minimal)
**Marker contract:** Continues ANALYST OUTPUT block opened in Wave 1. Closes `=== ANALYST OUTPUT END ===` after N08's WEAKNESSES block.
**Role:** Structured prompt analyst (continued from Wave 1's N03/N04 role declaration).

**Block header emission contract (deterministic):** Each analysis block in this wave MUST open with a line-starting markdown H3 header using the exact label, no decoration:

- N05 emits `### STRUCTURE` as the first line of its block.
- N06 emits `### CONSTRAINTS` as the first line of its block.
- N07 emits `### TECHNIQUES` as the first line of its block.
- N08 emits `### WEAKNESSES` as the first line of its block.

These headers are the smoke-test grep targets for Test B (negative-assertion: must be absent in minimal mode) and Test R (GoT controller path selection). Do NOT vary the casing, decorate with bold/italics, or add suffixes like `(N05)`. The header line is the contract; everything below it is the block body.

## N05 StructureAnalyzer

**Input:** normalized_input (from N02 via E00a).

**Protocol:**

1. Read the normalized_input and identify its current organizational structure.
2. Produce a STRUCTURE block containing:
   - **Current organization:** How the prompt is currently structured (paragraphs, sections, bullets, etc.)
   - **Missing structural elements:** What structural components are absent (section headers, constraints block, output format spec, edge case handling, etc.)
   - **Structural coherence assessment:** How well the existing structure supports the prompt's stated intent

**Output:** STRUCTURE block (text).

## N06 ConstraintAuditor

**Input:** normalized_input (from N02 via E00b).

**Protocol:**

1. Read the normalized_input and identify all constraints.
2. Produce a CONSTRAINTS block containing:
   - **Explicit constraints:** Directly stated requirements, limitations, and rules
   - **Implicit constraints:** Constraints implied by the intent, context, or domain but not directly stated
   - **Conflict surface:** Areas where constraints may contradict or create tension

**Output:** CONSTRAINTS block (text).

## N07 TechniqueGapAnalyst

**Input:** `{normalized_input, INTENT}` (from N02 via E00c and N03 via E03).

**Protocol:**

1. Read the normalized_input with the INTENT block as context.
2. For each of the 13 techniques (T1–T13), assess:
   - **Already present:** Is this technique already partially or fully applied in the input?
   - **Needed:** Would applying this technique meaningfully improve the prompt for its stated intent?
   - **Impact:** If needed, estimate the expected improvement (high/medium/low)
3. Produce a TECHNIQUES block listing gap analysis results in tabular form.

**Output:** TECHNIQUES block (T1–T13 gap analysis).

## N08 WeaknessDetector

**Input:** `{normalized_input, INTENT, STRUCTURE, CONSTRAINTS}` (from N02 via E00d, N03 via E03, N05 via E06, N06 via E07).

**Protocol:**

1. Synthesize findings from the input, INTENT, STRUCTURE, and CONSTRAINTS.
2. Identify specific weaknesses — numbered W1…Wn, each with:
   - **Weakness description:** What the weakness is
   - **Impact score:** high / medium / low
   - **Causal explanation:** WHY this is a weakness and how it degrades prompt effectiveness
3. Format example: `"Weakness: vague success criteria [high] — causal: without measurable criteria, the synthesizer cannot determine when enhancement is complete, leading to under- or over-specified output."`
4. Step self-check (non-blocking annotations):
   - INTENT specificity: is the INTENT block specific enough to guide enhancement?
   - WEAKNESSES causal explanation: does each weakness include a causal mechanism?
   - INVENTORY completeness: are there items in the input not yet captured in INVENTORY?

**Output:** WEAKNESSES block (numbered, scored, with causal explanations).

**Marker contract:** `=== ANALYST OUTPUT END ===` closes after this block in normal/verbose.

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
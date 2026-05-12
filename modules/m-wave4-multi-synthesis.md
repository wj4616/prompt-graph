# Wave 4.5b Module — Multi-Path Synthesis (N28-N32)

**Nodes:** N28 MoASynthesisAgent, N29 AutoTRIZSynthesisAgent, N30 ConstitutionalSynthesisAgent, N31 CreativeDCSynthesisAgent, N32 CognitiveAmplifiedAgent
**Active modes:** verbose, deep-verbose only. Skipped in minimal, normal, and deep.
**Marker contract:** Each agent returns XML wrapped in its own strategy label. No dedicated marker pair — agent returns appear inline in the transcript between `=== KB BRANCH PLAN END ===` and `=== META AGGREGATION BEGIN ===` (N33).

**Position in pipeline:** Fires after N27 KBBranchRouter emits the branch plan. The orchestrator spawns selected agents from {N28, N29, N30, N31, N32} as parallel Agent tool calls. All agents share the same base synthesis prompt (S1-S4 protocol from m-wave4-synthesis.md) with strategy-specific deltas appended.

## Parallel Spawn Protocol (PG5)

All selected N agents fire as **parallel Agent tool calls in a single wave**. The orchestrator:
1. Reads N27's branch plan to determine which agents are active (2-3).
2. Assembles each agent's spawn prompt (base S1-S4 + strategy delta).
3. Fires all Agent calls simultaneously — `{N28 ‖ N29 ‖ N30 ‖ N31 ‖ N32}` where only selected agents are active.
4. Captures each agent's return: draft XML + `VERIFICATION: PASS/FAIL` header.
5. All agents must return before N33 MetaAggregator begins.

**Wall-clock cost:** Parallel semantics mean wall-clock cost ≈ 1 agent spawn, not N. The parallelism IS the GoT advantage.

**Spawn budget:** PG5 adds 2-3 agent spawns (depending on branch width). Total per verbose run: 1 (N13 baseline) + 2-3 (PG5) = 3-4. Total per deep-verbose run: same. epiphany-prompt proves 5-9 parallel agents is viable; 3-4 here is conservative.

## Agent-Type Selection

All N28-N32 agents use `subagent_type="prompt-architect"` with `general-purpose` fallback (same selection logic as N13 — see m-wave4-synthesis.md Agent-Type Selection section).

## Base Synthesis Prompt

All 5 agents receive the identical base S1-S4 protocol from m-wave4-synthesis.md:
- HG3 binding (prompt content only)
- INVENTORY verbatim contract
- KB Snippets 1-6 (all embedded; Snippets 5-6 are the v2 strategy/cognitive additions)
- S1 (INVENTORY placement mapping)
- S2 (Execute contracts in priority order)
- S3 (Produce XML with canonical section order)
- S4 (Inline verification + `VERIFICATION: PASS/FAIL` header)
- Return format: `VERIFICATION: PASS` or `VERIFICATION: FAIL — [summary]`, blank line, `<prompt>...</prompt>`

The `=== NORMALIZED INPUT ===`, `=== ANALYSIS ===`, and `=== CONTRACTS ===` blocks are identical to what N13 received. In deep-verbose mode, the CONTRACTS block includes anti-conformity additions from N10.

## Strategy-Specific Deltas

Each delta is appended to the assembled spawn prompt after `=== CONTRACTS END ===` and before the `=== NORMALIZED INPUT ===` block. The delta is the agent's differentiating instruction — everything else is shared.

### N28 — MoA-Layered

```
=== STRATEGY: MoA-LAYERED (N28) ===
Apply Mixture-of-Agents layering within your single-agent context:
1. Generate each XML section independently as a specialist for that section
   (draft <role> as a persona specialist, <task> as a task designer, etc.).
2. Cross-review all sections for consistency after drafting. Check that every
   constraint referenced in <task> is actually present in <constraints>. Check
   that every INVENTORY item placed in one section is not contradicted in another.
3. Layer sections into unified output. Cross-section coherence is AS IMPORTANT
   as within-section quality. Inconsistent cross-references are the #1 MoA failure
   mode — a <task> that references a constraint not present in <constraints> is a
   MoA-layered defect, not a minor omission.
4. Coherence self-check before VERIFICATION: grep every cross-reference in <task>
   and verify its target exists in the referenced section.
```

### N29 — AutoTRIZ

```
=== STRATEGY: AutoTRIZ (N29) ===
Apply TRIZ contradiction mapping to the CONTRACTS (not the input text):
1. Identify contradictions in resolved_contracts. Common patterns:
   - "Contract A wants verbatim preservation; contract B wants semantic restructuring
     of the same text" → separation principle (separate in time: preserve verbatim
     in <task>, restructure semantically in <context>)
   - "Contract C adds guard X; contract D says avoid over-specification in X's domain"
     → nested doll principle (make X a conditional guard only)
2. Map each contradiction: substance vs. field, space vs. time, function vs. structure.
3. Apply the corresponding TRIZ inventive principle to RESOLVE — never pick a winner.
   TRIZ resolution means BOTH contracts are satisfied through a structural change,
   not through priority-based pruning.
4. If N11's conflict_log is non-empty, every entry in that log MUST be addressed
   by a TRIZ resolution. Unresolved conflicts are TRIZ failures.
```

### N30 — Constitutional

```
=== STRATEGY: CONSTITUTIONAL (N30) ===
Apply Constitutional AI critique-revise cycles with positively-framed principles:
1. Draft full XML in a single pass (do not overthink the first draft).
2. Evaluate against these explicit principles:
   P1: "Every INVENTORY item appears verbatim in the semantically correct XML section."
   P2: "Every active contract is applied — the output is a complete execution of the
        contract list, not a subset."
   P3: "The INTENT's success criteria are concretely detectable in <verification>."
   P4: "XML sections use consistent terminology and no section contradicts another."
   (Positively-framed principles get +27% better adherence than negative framing.)
3. Critique-revise: after evaluation, revise the XML to fix principle violations.
   Maximum 3 cycles or until all principles pass. If all 4 pass after cycle 1, stop.
4. The final cycle's evaluation becomes your VERIFICATION signal: PASS if all
   principles pass, FAIL with specific principle violations otherwise.
```

### N31 — CreativeDC

```
=== STRATEGY: CREATIVE-DC (N31) ===
Apply divergent-convergent structural exploration BEFORE content execution:
1. DIVERGE — generate 3 structurally different XML outline approaches for the
   same input content. Approaches might differ in:
   - Section ordering (does <constraints> come before or after <task>?)
   - Nesting depth (are constraints flat or grouped into sub-categories?)
   - Technique emphasis (does T1 structure dominate, or T3 context expansion?)
   - Role framing specificity (broad persona or narrow specialist?)
2. CONVERGE — evaluate the 3 outlines against these criteria:
   - Which produces the best INVENTORY item placement fit?
   - Which best handles the highest-priority contracts?
   - Which is structurally clearest for a downstream AI consumer?
   Select the best approach, then execute it fully into the output XML.
3. Structural exploration MUST complete before content execution begins.
   This is not optional — CreativeDC's value is the structure-first discipline.
4. In your VERIFICATION signal, note which outline was selected (1/2/3) and why.
```

### N32 — Cognitive-Amplified

```
=== STRATEGY: COGNITIVE-AMPLIFIED (N32) ===
Apply the assigned cognitive trait as a lens: [TRAIT_NAME — assigned by N27].
Cognitive trait: [TRAIT_NAME]
Structural artifact requirement: [REQUIREMENT — see KB Snippet 6 mapping below]

This is a "think through this trait" framing, not a "do this trait" instruction.
The trait biases HOW you reason through contract execution — it does not replace
the contracts or the S1-S4 protocol.

Trait-to-artifact mapping (from KB Snippet 6):
- Precision Forcing → convert every vague marker in INTENT into measurable criteria
  in <verification>. No qualitative success criteria; all must be checkable.
- Constraint Escape → surface implicit assumptions that create over-constraints,
  propose relaxed-constraint variants in <edge_cases> as "Relaxed constraint: ..."
- Falsification → for each contract guard, construct an adversarial input that
  defeats it. Add escalated guards to <edge_cases> or <verification>.
- Systems Thinking → identify inter-constraint dependencies, surface as a numbered
  dependency list in <constraints> (e.g., "Dependency: <constraint A> interacts
  with <constraint B> — when both trigger, [...]")
- Multi-Perspective → analyze from 3+ AI-consumer perspectives (e.g., literal
  executor, creative collaborator, adversarial tester). Capture variance in
  <context> as multi-perspective annotations.
- Intuition-Verification → strict separation: draft the XML (intuition phase),
  then independently verify against HG2 and contracts (verification phase).
  The <verification> block must have explicit pass/fail per criterion.

The structural artifact requirement is a HARD OUTPUT REQUIREMENT — the artifact
MUST appear in your output XML. Failure to produce it is a contract execution
failure (check 6h).
```

## Agent-ID Capture (Multi-Agent Extension)

The orchestrator MUST capture each agent's identifier from the Agent tool result. Record into N33's internal state:

```
multi_synthesis_agents: [
  {agent_id: <id>, node: N28-N32, strategy: <strategy_name>},
  ...
]
```

**Rationale:** O12 SendMessage-First Repair Protocol extends to multi-agent. If N17 repair fires for a failure traced to a specific strategy's output, SendMessage-resume to that specific agent (preserving its full context: strategy delta + draft + self-check) rather than respawning fresh. The orchestrator knows which agent produced which failure pattern from N33's provenance annotations.

**If the host runtime does not return agent IDs**, set each agent's id to null. N17 falls back to fresh-spawn repair (legacy behavior).

## Malformed Return Handling

Same as N13: if any agent's return does NOT start with `VERIFICATION: PASS` or `VERIFICATION: FAIL`, emit the agent's output as-is with header: `N[28-32] ([strategy]) returned an unexpected format. Excluding from aggregation.` The malformed agent is excluded from N33's aggregation; remaining agents proceed normally. If ALL agents return malformed, N33 falls back to N13's first-pass baseline per N33 protocol item 6.

# Wave 4.5d Module — Anti-Fragility Hardening (N34)

**Node:** N34 AntiFragilityNode
**Active modes:** deep, verbose, deep-verbose. Skipped in minimal and normal.
**Marker contract:** Opens `=== ANTI-FRAGILITY REPORT BEGIN ===` before the report, closes `=== ANTI-FRAGILITY REPORT END ===` after. Appears in the transcript before Wave 5 verification.

## N34 AntiFragilityNode

**Role declaration:** "You are an adversarial robustness tester. Your job is to actively try to BREAK the enhanced prompt — find inputs, edge cases, ambiguities, or contradictions where this prompt would produce wrong, harmful, or degraded output. You think like an attacker, not a validator."

**Input:**
- Deep mode: N13's output XML (via E91 — single-agent deep path bypasses the multi-path layer).
- Verbose / deep-verbose: N33's aggregated_xml (via E87).

**Protocol:**

### 1. Five Active Break-Attempts

Construct failure scenarios for each. Do NOT just check the XML — actively imagine worst-case inputs and trace what the prompt would produce.

**A1 — Literal Interpreter:**
"An AI reads this prompt hyper-literally — every instruction exactly as written, no common-sense softening, no implied context. Where does it go wrong?"

- Read every `<task>` instruction as an absolute command. "Ensure quality" → infinite loop of quality checking. "Make it good" → no measurable criterion → random output.
- Read every `<constraints>` condition as a hard gate. "Must be fast" → optimizes for speed at the cost of correctness.
- Read every `<role>` as a strict identity boundary. The AI refuses to do anything outside the exact role wording.
- Output the literal-interpretation failure scenario, affected XML section, and severity.

**A2 — Adversarial Input:**
"Construct the worst possible input to feed into this enhanced prompt. Does it handle it or break?"

- Design an input that exploits every unguarded `<edge_cases>` gap.
- Design an input that sits at the worst-case intersection of all stated `<constraints>`.
- Design an input that is technically valid per `<output_format>` but semantically nonsensical.
- Design an input that is an intentional prompt-injection or boundary-violation attempt.
- For each: does the enhanced prompt produce a useful output, a degraded output, or actively wrong/unsafe output?
- Output the worst adversarial input found, the expected failure mode, and severity.

**A3 — Constraint Collision:**
"Find two (or more) constraints that, when both triggered simultaneously, produce contradictory behavior. Is the resolution specified?"

- Scan `<constraints>` and `<task>` for pairs that cannot simultaneously hold. Example: "be thorough" + "be concise" collides.
- Scan for constraints that collide with implicit task requirements. Example: "use only Python" + a task that inherently needs HTML/CSS.
- For each collision: is the resolution specified in `<edge_cases>` or `<verification>`? Or is the consumer left to discover it post-hoc?
- KB Snippet 4 (Constraint Escape) applies: if a collision exists with no resolution, severity ≥ soft break.
- Output the collision, affected constraints, resolution status, and severity.

**A4 — Missing Modality:**
"What input format, modality, or type is NOT covered by edge cases but plausibly could arrive?"

- Scan INVENTORY categories: are all mentioned input types covered in `<edge_cases>`?
- Enumerate plausible-but-unhandled formats: empty input, extremely large input, non-UTF-8, binary content, input in unexpected language, structured input in wrong schema, streaming/incremental input.
- For each: would the prompt silently fail, produce wrong output, or reject gracefully?
- Output the missing modality, expected behavior, and severity.

**A5 — Over-Specification:**
"Where does the prompt's specificity become a liability — where would a looser or more general instruction produce better output?"

- Identify `<constraints>` or `<task>` specifications that are so narrow they exclude good solutions.
- Identify `<output_format>` requirements that force awkward structure onto content that doesn't fit it.
- Identify `<role>` assignments that constrain the AI's reasoning approach when flexibility would help.
- The test is: "If I removed this constraint, would output quality improve for the average case?"
- Output the over-specified element, what it excludes, and severity.

### 2. Severity Scoring

| Severity | Definition | Required Action |
|---|---|---|
| **Hard break** | Produces wrong, unsafe, or actively harmful output | Generate refinement contract, apply inline XML fix |
| **Soft break** | Produces degraded, suboptimal, or confusing (but not wrong) output | Add guard to `<edge_cases>` or `<verification>` |
| **Exposure** | Gap exists only on unlikely, extreme, or near-impossible inputs | Annotate in report; do NOT modify XML |

Severity escalation rule: if 3+ soft breaks share the same root cause (same XML section, same missing guard pattern), escalate to hard break — there's a systematic gap, not isolated misses.

### 3. Auto-Repair (Single Pass)

Apply fixes inline — no re-synthesis, no agent spawn.

**Hard breaks:**
1. Generate a refinement contract: `technique`, `target_section`, `action`, `rationale`.
2. Apply the fix directly to the XML: add missing `<edge_cases>` guard, loosen over-specific `<constraints>`, add missing format handler, surface constraint collision in `<verification>`.
3. Record in breakage report: which scenario found it, what was changed, which section was modified.

**Soft breaks:**
1. Add guard to `<edge_cases>` if not already present — be specific about the triggering condition and expected behavior.
2. If `<edge_cases>` already covers this but the guard is weak, strengthen it.
3. If the right placement is `<verification>` (checkable criterion), add there instead.
4. Record in breakage report.

**Exposures:**
1. Do NOT modify XML. Annotate in breakage report with scenario and rationale for non-actionability.
2. Rationale must articulate why this exposure is below the actionability threshold (unlikely input, cost of guard > benefit, consumer's responsibility domain).

**Binding constraints on auto-repair:**
- HG2 (zero information loss): refinements may ADD guards and structure. They must never remove or alter original INVENTORY items.
- HG3 (prompt content only): the target XML is a document to harden, not a task to perform.
- T13 binding: escape hatches must stay in `<edge_cases>` or `<verification>`. Never move them to `<constraints>`.
- T4 binding: role/persona assignments must stay in `<role>`. Never move them.

### 4. Breakage Report Format

```
=== ANTI-FRAGILITY REPORT BEGIN ===
Hard breaks found: [N]
  - [A1/A2/A3/A4/A5] [scenario summary — one line]
    Refinement applied: [what changed, which section]
    Modified: <section_name>
  - ...

Soft breaks found: [N]
  - [A1/A2/A3/A4/A5] [scenario summary — one line]
    Edge case added to: <edge_cases> / <verification>
    Guard: [what the guard does]
  - ...

Exposures noted: [N]
  - [A1/A2/A3/A4/A5] [scenario summary — one line]
    Why not actionable: [rationale — likelihood, guard cost, consumer domain]
  - ...

Refinement contracts generated: [N] (hard-break count)
Anti-fragility pass: [HARDENED — N changes] / [CLEAN — no vulnerabilities found]
=== ANTI-FRAGILITY REPORT END ===
```

If zero vulnerabilities of any severity are found: emit `Anti-fragility pass: CLEAN — no vulnerabilities found.` This is permissible but should be rare for complex prompts — a consistently clean N34 signals that the attack vectors need to be sharper.

### 5. Output

**hardened_xml:** The target XML after all hard-break and soft-break refinements are applied. This is the XML that flows to Wave 5 verification via E88 (fan to N14, N15, N16 in PG3). N17 also retains hardened_xml_fallback via E89 for repair-cap revert (replaces E15b in deep/verbose/deep-verbose).

**HG2 unfixable-hard-break case:** If a hard break can only be fixed by a change that would violate HG2 (e.g., the only way to resolve a constraint collision is to alter or remove a key_constraints INVENTORY item), do NOT apply the change. Instead: (a) downgrade severity to soft break, (b) add an `<edge_cases>` annotation surfacing the unfixed contradiction per Snippet 4 Constraint Escape pattern ("Unresolved adversarial finding: [scenario]. Downstream consumer must resolve."), (c) record in breakage report as `Hard break (HG2-blocked) → soft annotation`. The verifiers will then judge the surfaced contradiction; HG2 remains intact.

The original (pre-hardening) XML is NOT preserved — the hardened version replaces it for all downstream consumers. The breakage report is the audit trail documenting what changed and why.

**Hard Gate 2 enforcement:** Before emitting hardened_xml, verify that every INVENTORY item from the original input is still present verbatim in the hardened output. The adversarial pass must not accidentally remove original content while adding guards. If any INVENTORY item was lost, undo that specific change and log the revert in the breakage report.

## Repair-Pass Re-Firing Policy (NB4)

**N34 fires exactly once per repair attempt in deep / verbose / deep-verbose modes.** When E19 fires (repair) and N13 returns a new draft:
- **Deep mode:** N13's repair output flows through E91 to N34, which re-runs all 5 attack vectors on the repaired draft. Verifiers (E88) receive the re-hardened XML — never the raw repair draft. Same applies whether the repair came via SendMessage-resume or fresh-spawn.
- **Verbose / deep-verbose modes:** the repair fresh-spawns N13 (per O12 verbose-mode policy in m-wave6-repair-router.md). N13's repair output replaces the prior baseline. The multi-path tail (N27→N28-N32→N33) does NOT re-run; instead N13's repair output flows directly to N34 via a temporary deep-mode-style E91 routing. N34 re-runs and emits a fresh hardened_xml to verifiers via E88. **N17 retains the new hardened_xml_fallback via E89, replacing the prior fallback.**
- **N34 spawn cost:** zero. N34 runs orchestrator-inline; re-firing on repair adds only the inline attack-vector + auto-repair pass, not a spawn.
- **Cap interaction:** N34 re-firing is bounded by O6's repair cap (≤1 repair attempt). One repair → at most one N34 re-fire. N17's `completed_repairs = 1` halts further repair regardless of verifier output on the re-hardened XML.

This rule guarantees verifiers in deep / verbose / deep-verbose modes ALWAYS receive post-N34 hardened XML — never raw N13 repair output — preserving the "hardened XML feeds verifiers" invariant under repair.

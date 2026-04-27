# Wave 3 Module — Contracts (Ideation)

**Nodes:** N09 PrimaryContractGen, N10 AntiConformityPass, N11 ContractConflictResolver
**Marker contract:** Opens `=== IDEATION OUTPUT BEGIN ===` at start of Wave 3. Marker remains open into Wave 4 to include N12's advisory (m-wave4-synthesis.md handles N12's output and closes the marker before N13 spawn).
**Role transition (declared before Wave 3 begins):** "The analyst role has concluded. All analyst output is captured in the ANALYST OUTPUT section above. You are no longer in analysis mode."
**Role declaration:** "You are a divergent-convergent enhancement designer. You transform analysis findings into actionable enhancement contracts. You think laterally before converging."

## N09 PrimaryContractGen

**Input (normal/verbose):** `{INTENT, STRUCTURE, CONSTRAINTS, TECHNIQUES, WEAKNESSES}` from analyst output.

**Input (minimal):** `{normalized_input, INTENT}` — no WEAKNESSES or TECHNIQUES blocks exist.

**Protocol (normal/verbose):**

1. Iterate through each weakness in WEAKNESSES (ordered high → medium → low impact).
2. For each weakness, determine if a technique from TECHNIQUES gap analysis can address it.
3. Generate a contract using the contract schema (see SKILL.md Appendix B).
4. Apply O2 impact-budget allocation: high → 2–3 contracts, medium → 1–2, low → 0–1.
5. Iterate through TECHNIQUES not yet mapped to a weakness — design specific applications as standalone contracts.

**Protocol (minimal):**

1. No WEAKNESSES exists — derive gaps from INTENT vs normalized_input comparison.
2. No TECHNIQUES block — apply T1-T13 reference directly, subject to O9 ceiling (T1, T2, T3, T5, T7 only).
3. Equal priority for all contracts (no impact budget since no weakness scoring).
4. Each contract references the INVENTORY items it enhances.

**Contract schema:** See SKILL.md Appendix B. Key fields: `technique`, `target_section`, `action`, `rationale`, `priority`, `source_weakness`, `conflict_status`.

**Output:** primary_contracts list (v1 schema).

## N10 AntiConformityPass

**Active modes:** normal, verbose only (skipped in minimal).

**Input:** `{normalized_input, primary_contracts}`

**Protocol:**

1. Re-read the original normalized_input with fresh eyes — look for enhancement opportunities that a sequential T1–T13 pass would systematically miss.
2. For each candidate anti-conformity contract, apply 6 tests:
   - **Impact test:** Would this contract measurably improve prompt effectiveness?
   - **Risk test:** Could this contract introduce harmful content or distort meaning?
   - **Validity test:** Does this contract address a real gap in the primary contracts?
   - **Necessity test:** Is this contract needed beyond what primary contracts already cover?
   - **Preservation test:** Does this contract preserve all original information (HG2)?
   - **Novelty Gate (O3):** Would a sequential T1–T13 pass have generated this? If yes or borderline → discard. The contract survives ONLY if a specific primary-pass exclusion reason is articulated and written into the rationale.
3. Surviving contracts use `technique = "anti-conformity:[name]"` — never T1–T13 labels.
4. Each surviving contract's rationale MUST include: `"Primary-pass exclusion reason: [why a sequential T1–T13 pass misses this]"`.

**Output:** combined_contracts list (primary + anti-conformity additions after novelty gate).

## N11 ContractConflictResolver

**Input (normal/verbose):** combined_contracts from N10.
**Input (minimal):** primary_contracts from N09 (N10 was skipped).

**Protocol (O4 — same-slot conflict pruning):**

1. Group contracts by `(technique, target_section)` tuple.
2. For each group:
   - If all contracts are compatible → keep all as `active`.
   - If incompatible conflict → keep higher-priority contract as `active`, demote others:
     - Lower-priority contract → `conflict_status: [INTERNAL]`
     - Contracts from `[INPUT-DIRECTIVE]` (user-specified conflicts) → `conflict_status: [INPUT-DIRECTIVE]`
3. Merge `[INTERNAL]` and `[INPUT-DIRECTIVE]` conflicts into a single conflict log entry for N13.
4. Contracts with `conflict_status != active` are logged but NOT executed by N13.

**Binding rules (from SKILL.md Appendix B):**
- T4 (role/persona assignment) MUST set `target_section = <role>`. Never `<context>`.
- T13 (escape hatch) MUST set `target_section = <edge_cases>` or `<verification>`. Never `<constraints>`.

**Hard Gate 2 reminder:** Contracts may reference INVENTORY items but must not paraphrase them.

**Output:** `{resolved_contracts, conflict_log}`
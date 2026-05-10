# Wave 1.5 Module — N35 ComplexityAssessment

**Node:** N35 ComplexityAssessment (NEW in v2)
**Wave-label slot:** 1.5 (executes AFTER Wave 1 N04 emits inventory_yaml, BEFORE Wave 2 analysis fan-out begins). Effect surface includes a retroactive Wave-0 back-edge (E52 → N01 announce-string update) — this is a side-channel, not a topology rewrite.
**Activation:** unconditional whenever Wave 1 N04 has produced inventory_yaml. The N04→N35 edge (E51) is required; N35 cannot run before its input exists.
**Why "1.5" instead of "0.5":** an earlier draft labeled this Wave 0.5 because the side-channel back-edge (E52) modifies Wave-0 output (N01's announce string). That label is misleading — it suggests N35 executes between N01 and N02, but execution requires N04's output (Wave 1). The Wave 1.5 label reflects execution timing; the back-edge effect on Wave 0 is documented at E52's edge declaration in SKILL.md, not in the wave label.
**Exec-type:** inline. Token budget 2500.

## N35 ComplexityAssessment

**Role:** ComplexityMeasurer — read-only analyzer that measures four orthogonal complexity dimensions of the canonical 20-key INVENTORY YAML and emits two declarative signals (topology_advisory, mode_mutation_signal) via static-graph edges.

**Inputs:** inventory_yaml (canonical 20-key Appendix A schema; produced by N04).

**Outputs:**
- `topology_advisory:yaml` — emitted via E52 back-edge to N01's announce string (one-shot, retry-cap 1).
- `mode_mutation_signal:enum` — emitted via E53 (state-only edge for orchestrator) and conditionally via E71 (forward-conditional to N10 AntiConformityPass for novelty injection).
- `complexity_assessment:yaml` — full breakdown (used by N27 KBBranchRouter via state read).

**Protocol:**

1. **Measure four dimensions (each is an integer count, NOT a percentage):**

   a. **INVENTORY density** = sum of items across all 20 INVENTORY keys (`int`). Do NOT count keys; count items.

   b. **Constraint interdependence** = count of items in `key_constraints` that explicitly reference (by name or index) another item in `key_constraints`, `success_criteria`, or `assumptions`. Cross-reference detection is literal-string-match — if item N's text contains another item M's name or unique identifier substring, count it. (`int`)

   c. **Named-entity cross-references** = count of named entities (proper nouns, system names, file paths, function names extracted from any INVENTORY key) that appear in 2+ different keys. (`int`)

   d. **Tone-marker contradiction** = count of pairs `(formal_marker, casual_marker)` co-occurring in the same INVENTORY key. Formal markers: words like "shall", "MUST", "REQUIRED". Casual markers: contractions ("can't", "won't"), exclamation points, informal greetings. Each co-occurring pair counts as 1. (`int`)

2. **Apply crisp-integer thresholds (NO heuristics, NO ranges, NO fuzzy logic):**

   | Threshold | Trigger condition | Effect |
   |---|---|---|
   | `INVENTORY > 8` | dimension (a) > 8 | emit `mode_mutation_signal: promote_minimal_to_normal` via E53; also emit `topology_advisory: minimal_promoted_to_normal` via E52 to N01 announce string |
   | `INVENTORY > 18` | dimension (a) > 18 | emit `mode_mutation_signal: promote_n34_to_spawn` via E53; threshold consumed at N34 (W1 / Phase 2). Note: this signal does NOT compete with the W1 N34 INV>18 gate — they are the same signal source; N35 emits, N34 consumes. |
   | `novelty_signal` | dimension (c) ≥ 3 AND dimension (d) ≥ 1 | emit `mode_mutation_signal: inject_n10` via E71 forward-conditional to N10 AntiConformityPass |
   | `verbose_pressure` | per-agent context > 24,000 tokens (O7 threshold; for verbose modes only) | emit `mode_mutation_signal: downgrade_verbose_to_deep` via E53 |

   The thresholds are calibration constants — see SKILL.md §"Calibration Points". Mutation signals are advisory-only when the user has passed an explicit mode flag (e.g., `--minimal` overrides `promote_minimal_to_normal`); the user flag wins. Detection-pattern operationalization per brief §9a EDGE-MIND-CHANGE: emit `topology_advisory` as advisory text only — never silently rewrite the user's mode.

3. **Emit declarative signals (declarative — never orchestrator-internal mutation):**

   All mode mutations MUST be expressed as values written to declared graph edges (E52, E53, E71). Per AP-V29: the orchestrator does NOT rewrite topology in-flight — it just reads the signal and routes per declared static edges. Anything resembling "rewrite topology" or "orchestrator-internal mutation" is AP-V29-disallowed and MUST NOT appear in module text without a disclaimer.

4. **Graceful-degrade (AP-V6):**

   If inventory_yaml is empty, malformed, or fewer than 20 keys: emit no mutation signals; pipeline proceeds with default mode_dispatch from N01. No HALT, no user-facing error.

**Output schema (topology_advisory):**

```yaml
inventory_density: <int>
constraint_interdependence: <int>
named_entity_xrefs: <int>
tone_marker_contradiction: <int>
mutations_emitted:
  - signal: <one of: promote_minimal_to_normal | promote_n34_to_spawn | inject_n10 | downgrade_verbose_to_deep>
    user_override_active: <bool>
```

**Failure modes:**

| Failure | Trigger | Action |
|---|---|---|
| inventory_yaml absent | E51 fires before N04 completes | HALT — this is an orchestrator ordering bug, not a degradation case |
| inventory_yaml malformed | parse fails | log advisory; emit no mutations; proceed |
| measurement exception | string operations throw | log advisory; emit no mutations; proceed |
| E52 retry-cap exceeded | second back-edge attempt | suppress second; record `e52_suppressed: true` in run log |

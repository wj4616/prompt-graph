# Wave 6 Module — Repair Router, Output Formatter, Save Handler

**Nodes:** N17 RepairRouter, N18 OutputFormatter, N19 SaveHandler
**Also re-read at Wave 9** (verbose mode, final routing after Wave 8 re-verify). Module is stateless — re-reads have no side effects.

## N17 RepairRouter

**Internal state:**
- `completed_repairs: 0|1` — initialized to 0; incremented to 1 after first repair spawn returns (O6 repair cap)
- `expansion_completed: bool` — initialized to false; set to true at start of Wave 9 in verbose mode

**Decision logic (see SKILL.md Appendix C for authoritative algorithm):**

1. **Aggregate:** Collect FAILs from N14 (if present per O1), N15, N16.
   - If N14 was skipped per O1 (all 20 INVENTORY keys empty): preservation_report is absent; treat preservation failing_checks as empty and proceed with N15 + N16 reports only.
   - Build: `failing_checks[]`, `affected_sections[]`, `failure_detail` string

2. **Route:**
   - IF failing_checks empty AND (mode != verbose OR expansion_completed = true): → E20 route `{verified_xml, "verified", preservation_summary}` to N18 (PASS path; terminal)
   - IF failing_checks empty AND mode = verbose AND expansion_completed = false: → E22 route first_pass_verified_xml to N20 (expansion wave); retain first_pass_verified_xml as N17 internal state (for potential Wave 9 revert)
   - IF non-empty AND completed_repairs = 0: determine repair_scope from failing_checks:
     - 6a–6e only → targeted: preservation placement
     - 6f only → targeted: semantic fidelity
     - 6g–6l only → targeted: quality pass
     - multiple → full re-synthesis
     Build repair_signal with repair_count = 1 → E19 route to N13 (spawns new Agent tool call — this is the second and final N13 spawn); after N13 returns: increment completed_repairs to 1, re-aggregate verification reports
   - IF non-empty AND completed_repairs = 1: Halt repair loop (cap reached — enforces ≤2 total synthesis spawns). Retrieve draft_xml_fallback (retained from E15b — this is the most recent failed draft). Annotate: prepend `<!-- VERIFICATION FAILED: [checks] — unverified output -->` → E20 route `{annotated_xml, "annotated-fallback", preservation_summary}` to N18 (FAIL path)

**Retained internal states:**
- `draft_xml_fallback` — held from Wave 4 via E15b for repair-cap revert; always retained
- `first_pass_verified_xml` — held when E22 fires for expansion-failure revert in Wave 9 (verbose only)

## Router Signal Emission

Emit exactly one of:
- `VERIFICATION: PASS`
- `VERIFICATION: REPAIRING [count=1, checks=6a,6h,...]`  (only ever count=1 in v1)
- `VERIFICATION: FAIL — capped at 1 repair, fallback output`

## N18 OutputFormatter

**Protocol:**

1. Wrap verified (or annotated) XML in `---` delimiters.
2. Append preservation/coverage summary (INVENTORY item counts per key, from N14's preservation_report bundled in E20 payload by N17).
3. On FAIL path: append recovery guidance:
   ```
   Verification failed on checks: [list]. To retry with a better outcome:
     (1) run with --minimal to reduce synthesis node context pressure
     (2) re-feed the best-effort XML as Type C input for a refinement pass
     (3) for inputs with >12 INVENTORY items or deeply interdependent constraints,
         split the input into smaller independent segments and enhance each separately
   ```
4. Role reset: "The ideation and synthesis phases are complete. Returning to orchestrator context."

## N19 SaveHandler

**Protocol:**

- **Non-quiet:** `Save to file? (y/n)` prompt. On yes → save.
- **Quiet:** Write tool saves directly without asking.
- **Save path:** `~/docs/epiphany/prompts/DD-MM-{slug}.md` (tilde expansion, collision `-v2`/`-v3`, never overwrite).
- **Print:** `Saved to [full absolute path]` on success.

### Slug Generation (G4)

Generate a 3–5 word kebab-case slug for the filename.

**Priority order:**
1. INTENT goal noun-phrase (e.g., "string reversal function" → `string-reversal-function`)
2. First non-empty `INVENTORY.named_entities` item
3. First content-bearing phrase from normalized_input

**Normalization rules:**
1. Lowercase
2. Replace punctuation with hyphens
3. Strip non-alphanumeric characters except hyphens
4. Collapse repeated hyphens to single
5. Trim leading/trailing hyphens
6. Truncate to 40 characters on word boundary

**Examples:**
- Input: "Write a function that reverses a string in Python" → slug: `string-reversal-function`
- Input: "Create a REST API using Express.js" → slug: `rest-api-express`
- Input: "Analyze the performance of the sorting algorithm" → slug: `sorting-algorithm-performance`
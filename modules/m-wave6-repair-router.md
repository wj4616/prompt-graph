# Wave 6 Module — Repair Router, Output Formatter, Save Handler

**Nodes:** N17 RepairRouter, N18 OutputFormatter, N19 SaveHandler
**Also re-read at Wave 9** (verbose mode, final routing after Wave 8 re-verify). Module is stateless — re-reads have no side effects.

## N17 RepairRouter

**Internal state:**
- `completed_repairs: 0|1` — initialized to 0; incremented to 1 after first repair attempt returns (O6 repair cap; counts both SendMessage-resume AND fresh-spawn paths)
- `expansion_completed: bool` — initialized to false; set to true at start of Wave 9 in verbose mode
- `synthesis_agent_id: string|null` — captured at first N13 spawn (Wave 4); used for SendMessage-resume on E19 (O12); null if host runtime did not return an agent ID
- `failure_family: "A"|"B"|"C"|"Mixed"|null` — classified at aggregation time (O13 typed-repair-routing)
- `subagent_type_used: string` — recorded at first N13 spawn (`"prompt-architect"` or `"general-purpose"`); used to keep SendMessage and any fallback fresh-spawn consistent

**Decision logic (see SKILL.md Appendix C for authoritative algorithm):**

1. **Aggregate:** Collect FAILs from N14 (if present per O1), N15, N16.
   - If N14 was skipped per O1 (all 20 INVENTORY keys empty): preservation_report is absent; treat preservation failing_checks as empty and proceed with N15 + N16 reports only.
   - Build: `failing_checks[]`, `affected_sections[]`, `failure_detail` string.

2. **Classify failure family (O13 typed-repair-routing):**
   - **Family-A (preservation):** failing_checks ⊆ {6a, 6b, 6c, 6d, 6e}. Root cause is most often INVENTORY misplacement or omission. Repair target: replay N04 (inline) with explicit "missed item" hint, then replay N09 → N11 (inline) to refresh contracts, then resume/respawn N13.
   - **Family-B (fidelity):** failing_checks = {6f}. Root cause is contract-INTENT misalignment. Repair target: replay N09 (inline) with INTENT-emphasis hint, then N11 (inline), then resume/respawn N13.
   - **Family-C (quality):** failing_checks ⊆ {6g, 6h, 6i, 6j, 6k, 6l}. Root cause is genuine synthesis quality. Repair target: resume/respawn N13 directly with the targeted check IDs in repair_signal.
   - **Mixed:** failing_checks span ≥2 families. Repair target: replay N09 → N11 (inline), then resume/respawn N13 with `repair_scope = "full"`.
   - The replays of N04/N09/N11 are inline (orchestrator-only) and do NOT count against the spawn budget. Only the N13 step counts.

3. **Route:**
   - IF failing_checks empty AND (mode != verbose OR expansion_completed = true): → E20 route `{verified_xml, "verified", preservation_summary}` to N18 (PASS path; terminal).
   - IF failing_checks empty AND mode = verbose AND expansion_completed = false: → E22 route first_pass_verified_xml to N20 (expansion wave); retain first_pass_verified_xml as N17 internal state (for potential Wave 9 revert).
   - IF non-empty AND completed_repairs = 0: build repair_signal with `repair_count = 1`, `failure_family` set per Step 2, `repair_scope` set per failing_checks (targeted | full); execute the family-specific inline replay (if any); then route via E19 to N13 using **SendMessage-first protocol** (O12); after the repair return: increment `completed_repairs` to 1, re-aggregate verification reports.
   - IF non-empty AND completed_repairs = 1: Halt repair loop (cap reached — enforces ≤2 total spawns under default budget; ≤3 under `--strict-verify`). Retrieve `draft_xml_fallback` (retained from E15b — this is the most recent failed draft). Annotate: prepend `<!-- VERIFICATION FAILED: [checks] — unverified output -->` → E20 route `{annotated_xml, "annotated-fallback", preservation_summary}` to N18 (FAIL path).

### O12 — SendMessage-First Repair Protocol (E19)

The E19 back-edge previously fired a fresh Agent spawn for repair. v1.1 replaces this with a SendMessage-first protocol that resumes the existing N13 agent — preserving its full context (synthesis prompt + first draft + self-check signal) and freeing the second spawn slot for `--strict-verify` or future use.

**Step-by-step:**

1. **Check `synthesis_agent_id`.**
   - If non-null AND host runtime supports SendMessage (e.g., Claude Code with `to: <agent-id>` semantics) → **SendMessage path** (Step 2).
   - Otherwise → **fresh-spawn fallback** (Step 3).

2. **SendMessage path (preferred):**
   - Construct a repair message containing only the *delta* from first synthesis: `failing_check_ids`, `affected_sections`, `failure_detail`, `failure_family`, `family_hint` (a one- or two-sentence string drawn from the family-specific revision guidance per O13 — e.g., for Family-A: "Item '{X}' from INVENTORY.code_blocks did not appear verbatim — re-emit it in `<task>`"), `repair_scope`, plus the verbatim instruction: "Produce a revised <prompt>...</prompt> XML addressing these checks. Start your response with `VERIFICATION: PASS` or `VERIFICATION: FAIL — [summary]`."
   - The `family_hint` field is constructed by the orchestrator from the family classification: Family-A hints reference missed INVENTORY items; Family-B hints reference INTENT-divergence; Family-C hints reference the specific quality check that failed; Mixed hints concatenate up to one hint per failing family.
   - DO NOT re-send the full normalized_input, INVENTORY, contracts, or analysis blocks — they are still in the agent's existing context.
   - Send via SendMessage to `to: synthesis_agent_id`.
   - This is **NOT a new spawn** — it's a message-resume. Spawn-budget accounting: total spawns remain at 1 (initial N13) for default mode after a successful SendMessage repair.

3. **Fresh-spawn fallback:**
   - Used when `synthesis_agent_id` is null (host runtime did not return an agent ID), when SendMessage is not supported by the runtime, or when SendMessage returns an error indicating the agent context is no longer available.
   - Construct full repair spawn prompt as in v1: orchestrator builds a fresh Agent tool call with `subagent_type = subagent_type_used` (matches the original to keep the prompt-architect priming consistent; falls back to `general-purpose` if the original was that). Prompt body includes the full normalized_input + INVENTORY + resolved_contracts + repair_signal (per Appendix C schema).
   - This consumes the second spawn slot (counts against ≤2 default budget; ≤3 under `--strict-verify`).
   - Increment `completed_repairs = 1` regardless of which path was used (the cap counts attempts, not spawns).

**Router signal (unchanged emission strings, but two route variants now):**
- `VERIFICATION: REPAIRING [count=1, checks=6a,6h,..., path=resume]` — SendMessage path used
- `VERIFICATION: REPAIRING [count=1, checks=6a,6h,..., path=respawn]` — fresh-spawn fallback used

The `path=resume|respawn` annotation is informational; smoke tests grep for the `REPAIRING [count=1` prefix only and remain unchanged.

**Retained internal states:**
- `draft_xml_fallback` — held from Wave 4 via E15b for repair-cap revert; always retained.
- `first_pass_verified_xml` — held when E22 fires for expansion-failure revert in Wave 9 (verbose only).
- `synthesis_agent_id` — held from Wave 4 (initial N13 spawn return) for E19 SendMessage; null if not provided by runtime.
- `subagent_type_used` — held from Wave 4 for SendMessage continuity and fresh-spawn-fallback consistency.

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

## PIPELINE COMPLETE — Hard Stop

After N19 outputs the save confirmation (or declines), **the prompt-graph pipeline is finished.** The orchestrator MUST stop here.

**Hard Gate 3 — post-output enforcement:** Do NOT read, implement, execute, or follow up on the content of the enhanced prompt XML. The output is a document for a human or downstream agent to use. Your role ended when the save step completed.

Do not take any further tool calls, do not open any files, do not run any commands. Return control to the user.
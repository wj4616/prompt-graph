# V-Check Coverage Map (prompt-graph-v2; W4 dropped)

This document maps the new V-checks (workstreams 1, 2, 3) to the test scripts that
verify them. Workstream-4 V-checks (V-S7a-i, V-P9a-i) are out of scope for v2 —
spec/plan modes are handled by `epiphany-spec` and a future plan tool.

## V-checks added in v2

| V-check ID | Workstream | Description | Test script |
|---|---|---|---|
| V-NEW-LEARN-1 | W3 | topology_adjustments YAML written to Memory under --learn | tests/test_learn_shape.sh |
| V-NEW-N35-1 | W2 | topology_advisory injected into N01 announce string when N35 emits | tests/test_n35_thresholds.sh + manual smoke (full skill invocation) |
| V-NEW-N35-2 | W2 | mode_mutation_signal declared via static forward-conditional edge (AP-V29) | tests/test_apv29_graph_trace.sh |
| V-NEW-LANGFUSE-1 | W3 | advisory emitted only when threshold ≥3 | tests/test_advisory_threshold.sh |
| V-NEW-MEMORY-1 | W3 | Memory helper graceful-degrade on missing/corrupt yaml (AP-V6) | tests/test_memory_helper.sh |
| V-NEW-W1-DISPATCH-1 | W1 | --strict-verify=full triggers N14/N15/N16 spawn under HC-23 single-response | tests/test_strict_verify_full_dispatch.sh |
| V-NEW-STANDALONE-1 | brief §11 | Skill operates without MCP, Memory, Langfuse | tests/test_standalone.sh |

## V-checks NOT covered (acknowledged)

- **V-NEW-N35-1 behavioral** — full end-to-end check requires Claude Code runtime (skill invocation against an INVENTORY=9 fixture and verifying the announce-string contains the advisory). The unit-test layer can only verify the protocol declarations and threshold logic. The runtime check belongs in a manual smoke pass before declaring the skill production-ready (Task 4.4 Step 3).
- **V-NEW-W1-DISPATCH-1 behavioral** — verifying that the orchestrator actually issues 3 parallel Agent calls in a single response_id under `--strict-verify=full` requires runtime trace observation (Langfuse). Unit tests verify only the protocol declarations.
- **V-NEW-LEARN-1 end-to-end** — verifying that an actual `/prompt-graph-v2 --learn` invocation writes to the resolved Memory directory requires runtime invocation. Unit tests verify only the helper's I/O behavior.
- **W4 V-checks** (V-S7a-i, V-P9a-i) — out of scope; spec/plan modes deferred per 2026-05-09 user decision.

## Backward-compat preservation

v2.0 smoke tests A–V are preserved byte-identical via the regression baseline at
`tests/fixtures/regression/v2.0-full-output.txt`. Every phase commits its
default-mode regression diff against this baseline (Phase 1.6, Phase 2.5, Phase 3.6).

## Test invocation

The full v2 test suite runs via `tests/run-smoke-tests.sh` which executes both the
v2.0 baseline checks (91 static checks) and the v2 additions (6 structural test
scripts). Standalone-capability tests are invoked separately via
`tests/test_standalone.sh` because they manipulate env vars that interfere with
the standard runner.

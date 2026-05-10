# Regression Baseline Versioning Policy

**Purpose:** Prevent the regression baseline at `tests/fixtures/regression/<version>-full-output.txt` from becoming a cage that prevents legitimate version increments.

## Policy

Baselines are **per minor-version**. The current `v2.0-full-output.txt` is the v2.0 historical anchor — it locks the v2.0 invariant for the v2 manual-build phase. When v2.1 work begins, capture a fresh `v2.1-full-output.txt` at the v2.1 freeze point.

### Rules

1. **Each minor-version (v2.0, v2.1, v2.2, ...) gets its own baseline file** under `tests/fixtures/regression/`.
2. **Baselines are immutable once captured.** A baseline file is created exactly once per version; it is never overwritten or edited.
3. **Older baselines are kept**, not deleted. They serve as cross-version diff anchors.
4. **Phase regression checks always diff against the baseline matching the active minor-version**, not the latest. During v2.0 fix/maintenance work, the diff target is `v2.0-full-output.txt`. During v2.1 development, it is `v2.1-full-output.txt`.
5. **A new baseline is captured only when the active minor-version changes**, typically at a freeze point in the implementation plan.

### When to capture a new baseline

- Major-version change (v2 → v3): new baseline mandatory.
- Minor-version change (v2.0 → v2.1): new baseline mandatory at the v2.1 freeze point.
- Patch-version change (v2.0.0 → v2.0.1): same baseline. Patches must preserve byte-identity vs the current baseline.

### How to capture a new baseline

Use `tests/rebaseline.sh <version>`. The script refuses to overwrite an existing baseline file — protection against accidental loss of the invariant proof.

```bash
~/.claude/skills/prompt-graph-v2/tests/rebaseline.sh v2.1
# → Captures current static-mode output to tests/fixtures/regression/v2.1-full-output.txt
# → Refuses if v2.1-full-output.txt already exists
```

## Rationale

The current `v2.0-full-output.txt` was captured against `~/.claude/skills/prompt-graph/` (v2.0, read-only baseline). The v2 smoke runner's `SKILL_DIR=prompt-graph` is intentional so v2's runner exercises v2.0's SKILL.md, making the regression diff legitimately empty across all fix-groups in the v2 manual-build phase.

For v2.1+, the smoke runner should switch `SKILL_DIR=prompt-graph-v2` so the runner exercises v2's own SKILL.md, and a fresh `v2.1-full-output.txt` is captured against that switched runner. This unlocks legitimate v2 evolution (e.g., adding more nodes, deepening protocols) without losing the v2.0 invariant proof or accidentally breaking it.

## See also

- `tests/regression-baseline.sh` — captures the initial baseline; documents the v2.0 SKILL_DIR anchor in its header
- `tests/rebaseline.sh` — captures subsequent per-version baselines with the refuse-overwrite guard
- `docs/v-check-coverage.md` — V-check coverage map for v2 (W4 dropped)

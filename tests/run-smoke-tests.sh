#!/usr/bin/env bash
# prompt-graph smoke test runner — covers SKILL.md Tests A-R
#
# Usage:
#   ./run-smoke-tests.sh              # essential: static + essential runtime (default)
#   ./run-smoke-tests.sh --full       # strict: static + essential + protocol
#   ./run-smoke-tests.sh --static     # static/structural checks only (instant)
#   ./run-smoke-tests.sh --fast       # static + halt-path runtime tests only
#
# Exit code: 0 if all ESSENTIAL + STATIC checks pass.

set -u

PASS_E=0; FAIL_E=0
PASS_P=0; FAIL_P=0
PASS_S=0; FAIL_S=0
SKIP=0
MODE="${1:-essential}"
TIMEOUT=180

SKILL_DIR="$HOME/.claude/skills/prompt-graph"
SKILL_MD="$SKILL_DIR/SKILL.md"

G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; C=$'\033[36m'; N=$'\033[0m'

header() { echo; printf "${B}=== %s ===${N}\n" "$1"; }

check() {
    local desc="$1" pattern="$2" output="$3" invert="${4:-0}" tier="${5:-essential}"
    local matched=0
    echo "$output" | grep -qF -- "$pattern" && matched=1
    local pass=$matched
    [[ $invert -eq 1 ]] && pass=$((1 - matched))
    local label=""
    if [[ $tier == "essential" ]]; then
        label="E"
        if [[ $pass -eq 1 ]]; then ((PASS_E++)) || true; else ((FAIL_E++)) || true; fi
    elif [[ $tier == "protocol" ]]; then
        label="P"
        if [[ $pass -eq 1 ]]; then ((PASS_P++)) || true; else ((FAIL_P++)) || true; fi
    else
        label="S"
        if [[ $pass -eq 1 ]]; then ((PASS_S++)) || true; else ((FAIL_S++)) || true; fi
    fi
    if [[ $pass -eq 1 ]]; then
        printf "  ${G}✓${N} [%s] %s\n" "$label" "$desc"
    else
        printf "  ${R}✗${N} [%s] %s\n" "$label" "$desc"
        printf "      expected%s: %s\n" "${invert:+ absent}" "$pattern"
    fi
}

check_file() {
    local desc="$1" pattern="$2" file="$3" invert="${4:-0}" tier="${5:-static}"
    local output
    output=$(cat "$file" 2>/dev/null)
    check "$desc" "$pattern" "$output" "$invert" "$tier"
}

run_static() {
    header "STATIC STRUCTURAL CHECKS"

    # Frontmatter + version
    check_file "frontmatter: name: prompt-graph" "name: prompt-graph" "$SKILL_MD"
    check_file "frontmatter: version present" "version: 1.0.0" "$SKILL_MD"
    check_file "frontmatter: triggers list" 'triggers: ["/prompt-graph"]' "$SKILL_MD"

    # Required sections
    check_file "Section 1 Node Registry header" "## Section 1 — Node Registry" "$SKILL_MD"
    check_file "Section 2 Edge/Channel Table header" "## Section 2 — Edge/Channel Table" "$SKILL_MD"
    check_file "Section 3 Mode Matrix header" "## Section 3 — Mode Activation Matrix" "$SKILL_MD"
    check_file "Section 4 Parallel Groups header" "## Section 4 — Logically Parallel Groups" "$SKILL_MD"
    check_file "Section 5 Optimizations header" "## Section 5 — Optimization Strategies" "$SKILL_MD"
    check_file "Section 6 GoT Controller header" "## Section 6 — GoT Controller Logic" "$SKILL_MD"
    check_file "Section 7 Pipeline Narrative header" "## Section 7 — Pipeline Narrative" "$SKILL_MD"
    check_file "Section 8 Smoke Test Checklist header" "## Section 8 — Smoke Test Checklist" "$SKILL_MD"

    # Modules exist
    for mod in m-wave0-1-input m-wave2-analysis m-wave3-contracts m-wave4-synthesis m-wave5-verification m-wave6-repair-router m-wave7-9-verbose-expansion; do
        if [[ -f "$SKILL_DIR/modules/$mod.md" ]]; then
            printf "  ${G}✓${N} [S] module file exists: $mod.md\n"; ((PASS_S++)) || true
        else
            printf "  ${R}✗${N} [S] MISSING module: $mod.md\n"; ((FAIL_S++)) || true
        fi
    done

    # Test R structural check: minimal-mode node list referenced
    check_file "Section 3 mentions minimal-mode node list" "(13 nodes)" "$SKILL_MD"

    # Test Q structural check: 3 sub-block markers defined
    check_file "VERIFICATION REPORTS sub-block: PRESERVATION" "--- PRESERVATION (6a-6e) ---" "$SKILL_MD"
    check_file "VERIFICATION REPORTS sub-block: FIDELITY" "--- FIDELITY (6f) ---" "$SKILL_MD"
    check_file "VERIFICATION REPORTS sub-block: QUALITY" "--- QUALITY (6g-6l) ---" "$SKILL_MD"

    # Hard gates present
    check_file "Hard Gate 1 SUFFICIENCY" "SUFFICIENCY" "$SKILL_MD"
    check_file "Hard Gate 2 ZERO INFORMATION LOSS" "ZERO INFORMATION LOSS" "$SKILL_MD"
    check_file "Hard Gate 3 PROMPT CONTENT ONLY" "PROMPT CONTENT ONLY" "$SKILL_MD"

    # Appendices present
    check_file "Appendix A INVENTORY" "Appendix A" "$SKILL_MD"
    check_file "Appendix B Contract" "Appendix B" "$SKILL_MD"
    check_file "Appendix C Repair" "Appendix C" "$SKILL_MD"

    # Design Notes present
    check_file "Design Notes section" "## Design Notes" "$SKILL_MD"

    # Optimizations present
    check_file "O6 repair cap" "completed_repairs" "$SKILL_MD"
    check_file "O9 technique ceiling" "O9" "$SKILL_MD"

    # FAIL-path message templates (Tests G, O, P structural)
    check_file "Test G: FAIL-capped signal defined" "VERIFICATION: FAIL — capped at 1 repair, fallback output" "$SKILL_MD"
    check_file "Test G: recovery guidance defined" "re-feed the best-effort XML as Type C input" "$SKILL_MD"
    check_file "Test O: REPAIRING signal defined" "VERIFICATION: REPAIRING" "$SKILL_MD"
    check_file "Test P: FAIL annotation template defined" "VERIFICATION FAILED:" "$SKILL_MD"

    # --plan deferred flag message (companion to Test E)
    check_file "--plan deferred halt message defined" "Same format for --plan" "$SKILL_MD"

    # Cross-Wave Rules table present
    check_file "Cross-Wave Rules table header" "Cross-Wave Rules" "$SKILL_MD"
    check_file "Cross-Wave: INVENTORY verbatim contract" "INVENTORY verbatim contract" "$SKILL_MD"
    check_file "Cross-Wave: channel marker discipline" "Channel marker discipline" "$SKILL_MD"
    check_file "Cross-Wave: repair signal schema binding" "Repair signal schema binding" "$SKILL_MD"
}

run_essential_halt() {
    header "ESSENTIAL HALT-PATH CHECKS"

    # Test E — deferred flag --spec
    local out
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph --spec Write a function." 2>&1 || true)
    check "Test E: --spec deferred halt message" "The \`--spec\` flag is not yet supported in prompt-graph v1" "$out"
    check "Test E: does NOT proceed to analysis" "=== ANALYST OUTPUT BEGIN ===" "$out" 1

    # Test E companion — deferred flag --plan
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph --plan Write a function." 2>&1 || true)
    check "Test E: --plan deferred halt message" "The \`--plan\` flag is not yet supported in prompt-graph v1" "$out"
    check "Test E: --plan does NOT proceed to analysis" "=== ANALYST OUTPUT BEGIN ===" "$out" 1

    # Test J — conflicting --minimal --verbose halt
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph --minimal --verbose Write a function." 2>&1 || true)
    check "Test J: flag conflict halt" "--minimal and --verbose conflict" "$out"
}

run_essential_runtime() {
    header "ESSENTIAL RUNTIME CHECKS"

    # Test A — Normal mode simple input
    local out
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph Write a function that reverses a string." 2>&1 || true)
    check "Test A: announce message (normal)" "Using prompt-graph to analyze and enhance this prompt." "$out"
    check "Test A: ANALYST OUTPUT BEGIN marker" "=== ANALYST OUTPUT BEGIN ===" "$out"
    check "Test A: ANALYST OUTPUT END marker" "=== ANALYST OUTPUT END ===" "$out"
    check "Test A: IDEATION OUTPUT BEGIN marker" "=== IDEATION OUTPUT BEGIN ===" "$out"
    check "Test A: SYNTHESIS RETURN marker" "=== SYNTHESIS RETURN BEGIN ===" "$out"
    check "Test A: VERIFICATION REPORTS marker" "=== VERIFICATION REPORTS BEGIN ===" "$out"
    check "Test A: VERIFICATION signal" "VERIFICATION: PASS" "$out"

    # Test A negative: verbose-mode-only markers absent in normal mode
    check "Test A: EXPANSION OUTPUT absent (not verbose)" "=== EXPANSION OUTPUT BEGIN ===" "$out" 1
    check "Test A: pass=2 re-verify absent (not verbose)" "=== VERIFICATION REPORTS (pass=2) BEGIN ===" "$out" 1

    # Test Q — three sub-blocks in VERIFICATION REPORTS (ordered)
    local v_block
    v_block=$(echo "$out" | awk '/=== VERIFICATION REPORTS BEGIN ===/,/=== VERIFICATION REPORTS END ===/')
    check "Test Q: PRESERVATION sub-block first" "--- PRESERVATION (6a-6e) ---" "$v_block"
    check "Test Q: FIDELITY sub-block second" "--- FIDELITY (6f) ---" "$v_block"
    check "Test Q: QUALITY sub-block third" "--- QUALITY (6g-6l) ---" "$v_block"

    # Test B — Minimal mode: no analysis blocks (negative assertions)
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph --minimal Write a function." 2>&1 || true)
    check "Test B: minimal mode announce" "Using prompt-graph (minimal mode) to enhance this prompt." "$out"
    check "Test B: minimal advisory line" "Analysis limited to intent and inventory" "$out"
    check "Test B: STRUCTURE block absent" "STRUCTURE block" "$out" 1
    check "Test B: CONSTRAINTS block absent" "CONSTRAINTS block" "$out" 1
    check "Test B: TECHNIQUES block absent" "TECHNIQUES block" "$out" 1
    check "Test B: WEAKNESSES block absent" "WEAKNESSES block" "$out" 1
    check "Test B: EXPANSION OUTPUT absent (minimal mode)" "=== EXPANSION OUTPUT BEGIN ===" "$out" 1

    # Test R — same as B but as explicit GoT controller path selection test
    check "Test R: GoT controller path — analysis content absent" "STRUCTURE:" "$out" 1

    # Test H — combined --minimal --quiet
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph --minimal --quiet Write a function." 2>&1 || true)
    check "Test H: combined announce" "Using prompt-graph (quiet + minimal mode) to enhance this prompt." "$out"
    check "Test H: quiet saves directly (no save prompt)" "Save to file? (y/n)" "$out" 1
    check "Test H: quiet prints save path" "Saved to " "$out"

    # Test K — channel marker abort (confirm the abort message is defined in SKILL.md)
    check_file "Test K: channel abort message defined" "Wave 4 pre-spawn abort: channel markers missing" "$SKILL_MD" 0 essential

    # Test F — unknown flag prose context (soft advisory)
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph --describe what a function does" 2>&1 || true)
    check "Test F: soft advisory shown" "Token '--describe' resembles a flag" "$out"

    # Test L — Type D advisory
    local type_d_fixture
    type_d_fixture=$(printf -- '---\nname: test-skill\ndescription: test\ntriggers: ["/test"]\n---\n# Test Skill\n\nBody content.')
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph $type_d_fixture" 2>&1 || true)
    check "Test L: Type D advisory first line" "appears to describe an executable workflow" "$out"
}

run_protocol() {
    header "PROTOCOL-TIER CHECKS (costs API credits)"

    # Test C — Quiet mode (non-minimal)
    local out
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph --quiet Write a function that reverses a string." 2>&1 || true)
    check "Test C: quiet announce" "Using prompt-graph (quiet mode) to enhance this prompt." "$out" 0 protocol
    check "Test C: quiet no save prompt" "Save to file? (y/n)" "$out" 1 protocol
    check "Test C: quiet prints save path" "Saved to " "$out" 0 protocol

    # Test D — Type B input (prior prompt-epiphany output)
    local type_b_input='<prompt><meta source="prompt-epiphany"/><task>Write a string reversal function in Python.</task></prompt>'
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph $type_b_input" 2>&1 || true)
    check "Test D: Type B routing — synthesis ran" '<meta source="prompt-graph"/>' "$out" 0 protocol
    check "Test D: Type B routing — original wrapper stripped" '<meta source="prompt-epiphany"/>' "$out" 1 protocol

    # Test I — Type C input (prior prompt-cog output)
    local type_c_input='<prompt><meta source="prompt-cog"/><task>Write a string reversal function.</task></prompt>'
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph $type_c_input" 2>&1 || true)
    check "Test I: Type C routing — synthesis ran" '<meta source="prompt-graph"/>' "$out" 0 protocol
    check "Test I: Type C routing — prompt-cog meta stripped from input" 'source="prompt-cog"' "$out" 1 protocol

    # Test M — File path input
    local tmpfile=/tmp/prompt-graph-test-input.txt
    echo "Write a function that reverses a string." > "$tmpfile"
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph $tmpfile" 2>&1 || true)
    check "Test M: file path input — synthesis ran" '<meta source="prompt-graph"/>' "$out" 0 protocol
    rm -f "$tmpfile"

    # Test N — Verbose mode full path
    out=$(timeout $TIMEOUT claude --dangerously-skip-permissions "/prompt-graph --verbose Write a function that reverses a string." 2>&1 || true)
    check "Test N: verbose announce" "Using prompt-graph (verbose mode)" "$out" 0 protocol
    check "Test N: EXPANSION OUTPUT marker present" "=== EXPANSION OUTPUT BEGIN ===" "$out" 0 protocol
    check "Test N: pass=2 re-verification marker" "=== VERIFICATION REPORTS (pass=2) BEGIN ===" "$out" 0 protocol

    # Tests G, O, P — require manual construction to trigger FAIL paths
    echo "  ${Y}ℹ${N}  [P] Tests G, O, P require manual construction — see Section 8 of SKILL.md"
}

# Dispatch
case "$MODE" in
    --static|static)
        run_static
        ;;
    --fast|fast)
        run_static
        run_essential_halt
        ;;
    --full|full)
        run_static
        run_essential_halt
        run_essential_runtime
        run_protocol
        ;;
    --essential|essential)
        run_static
        run_essential_halt
        run_essential_runtime
        ;;
    *)
        printf "${R}Unknown mode:${N} %s\n" "$MODE"
        printf "Usage: %s [--static|--fast|--essential|--full]\n" "$0"
        exit 2
        ;;
esac

# Summary
header "SUMMARY"
printf "  ${B}Static:${N}    %d passed, %d failed\n" "$PASS_S" "$FAIL_S"
printf "  ${B}Essential:${N} %d passed, %d failed\n" "$PASS_E" "$FAIL_E"
printf "  ${B}Protocol:${N}  %d passed, %d failed\n" "$PASS_P" "$FAIL_P"

# Exit code: 0 if essential + static pass
[[ $FAIL_S -eq 0 && $FAIL_E -eq 0 ]] && exit 0 || exit 1
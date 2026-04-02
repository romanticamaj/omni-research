#!/usr/bin/env bash
# Test 2: Setup Flow Simulation
# Simulates SKILL.md Steps 1-6 with controlled inputs, generates output files,
# and validates they match expected structure.
# Run: bash tests/test-setup-flow.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/omni-research"
TEST_OUTPUT="$HOME/omni-research-test-output/2026-04-02-prompt-engineering-t3st"
PASS=0
FAIL=0

pass() { ((PASS++)); echo "  PASS  $1"; }
fail() { ((FAIL++)); echo "  FAIL  $1"; }

echo "=== Test 2: Setup Flow Simulation ==="
echo "Output: $TEST_OUTPUT"
echo ""

# ── Clean up previous test ──────────────────────────────────────────
rm -rf "$TEST_OUTPUT"
mkdir -p "$TEST_OUTPUT"

# ── Test inputs (simulating user responses) ──────────────────────────
TOPIC="Best practices for prompt engineering with Claude"
TOPIC_TYPE="research"
LANGUAGE="English"
MAX_CYCLES="8"
OUTPUT_DIR="$TEST_OUTPUT"
SKILL_DIR_RESOLVED="$SKILL_DIR"
CONTEXT="I'm interested in system prompts, few-shot examples, and chain-of-thought techniques. I want practical, actionable advice."
SEED_SOURCES="None provided — the agent will run Phase 0 Source Scouting to discover high-quality sources automatically."
RESEARCH_LINES="## 1. System Prompt Design
### 1.1 How do structural elements (XML tags, sections) affect Claude's output quality?
### 1.2 What is the optimal length and detail level for system prompts?
### 1.3 How do role-based vs task-based system prompts compare?

## 2. Few-Shot Examples
### 2.1 How many examples are needed for different task types?
### 2.2 What makes a high-quality few-shot example?
### 2.3 When do few-shot examples hurt performance?

## 3. Chain-of-Thought & Reasoning
### 3.1 When does explicit CoT improve results vs implicit reasoning?
### 3.2 How do thinking tags and structured reasoning compare?
### 3.3 What are the limits of CoT for different task complexities?"

# ── Step 3-5: Generate program.md from template ─────────────────────
echo "--- Generating program.md ---"

TEMPLATE="$SKILL_DIR/program-template.md"
PROGRAM="$TEST_OUTPUT/program.md"

# Replace placeholders
sed \
  -e "s|{{TOPIC}}|$TOPIC|g" \
  -e "s|{{TOPIC_TYPE}}|$TOPIC_TYPE|g" \
  -e "s|{{LANGUAGE}}|$LANGUAGE|g" \
  -e "s|{{MAX_CYCLES}}|$MAX_CYCLES|g" \
  -e "s|{{OUTPUT_DIR}}|$OUTPUT_DIR|g" \
  -e "s|{{SKILL_DIR}}|$SKILL_DIR_RESOLVED|g" \
  "$TEMPLATE" > "$PROGRAM.tmp"

# Handle multi-line replacements with awk
awk -v context="$CONTEXT" '{gsub(/\{\{CONTEXT\}\}/, context)}1' "$PROGRAM.tmp" > "$PROGRAM.tmp2"
awk -v seeds="$SEED_SOURCES" '{gsub(/\{\{SEED_SOURCES\}\}/, seeds)}1' "$PROGRAM.tmp2" > "$PROGRAM.tmp3"
# RESEARCH_LINES is multi-line, use a different approach
python3 -c "
import sys
with open('$PROGRAM.tmp3', 'r') as f:
    content = f.read()
lines = '''$RESEARCH_LINES'''
content = content.replace('{{RESEARCH_LINES}}', lines)
with open('$PROGRAM', 'w') as f:
    f.write(content)
" 2>/dev/null || {
  # Fallback if python3 not available
  cp "$PROGRAM.tmp3" "$PROGRAM"
  sed -i "s|{{RESEARCH_LINES}}|[research lines would be here]|g" "$PROGRAM"
}
rm -f "$PROGRAM.tmp" "$PROGRAM.tmp2" "$PROGRAM.tmp3"

# ── Step 6: Generate research.md skeleton ────────────────────────────
echo "--- Generating research.md ---"

cat > "$TEST_OUTPUT/research.md" << 'SKELETON'
# Best practices for prompt engineering with Claude — Research Knowledge Base
## Last Updated: 2026-04-02
## Total Research Cycles: 0

## Executive Summary
[To be filled by research agent]

## 1. System Prompt Design
### 1.1 How do structural elements (XML tags, sections) affect Claude's output quality?
### 1.2 What is the optimal length and detail level for system prompts?
### 1.3 How do role-based vs task-based system prompts compare?

## 2. Few-Shot Examples
### 2.1 How many examples are needed for different task types?
### 2.2 What makes a high-quality few-shot example?
### 2.3 When do few-shot examples hurt performance?

## 3. Chain-of-Thought & Reasoning
### 3.1 When does explicit CoT improve results vs implicit reasoning?
### 3.2 How do thinking tags and structured reasoning compare?
### 3.3 What are the limits of CoT for different task complexities?

## 4. Design Recommendations / Actionable Insights
[Practical takeaways]

## 5. Open Questions & Next Directions
[What we still don't know]

## Source Queue
| # | URL | Title/Author | Lines | Authority | Recency | Relevance | Score | Status |
|---|-----|-------------|-------|-----------|---------|-----------|-------|--------|

## Appendix: Sources
[Full citation list with URLs]
SKELETON

# ── Step 7: Generate experiments.tsv ─────────────────────────────────
echo "--- Generating experiments.tsv ---"

printf 'cycle\ttimestamp\tline\thypothesis\tsources_found\tkey_finding\tstatus\tresearch_md_lines\tgate_decision\tnext_direction\n' > "$TEST_OUTPUT/experiments.tsv"

# ── Step 8: Generate steer.md ────────────────────────────────────────
echo "--- Generating steer.md ---"

cat > "$TEST_OUTPUT/steer.md" << 'STEER'
# Steering File
Write instructions here to redirect the research agent mid-run.
The agent checks this file at the start of every cycle.
Examples: "Focus on Line 3 next", "Add this context: ...", "Skip Line 2", "Wrap up soon"
STEER

echo ""

# ══════════════════════════════════════════════════════════════════════
# VALIDATION
# ══════════════════════════════════════════════════════════════════════

echo "--- Validating generated files ---"
echo ""

# ── program.md checks ────────────────────────────────────────────────
echo "  [program.md]"

[[ -f "$PROGRAM" ]] \
  && pass "program.md exists" \
  || fail "program.md not created"

# No remaining {{...}} placeholders
REMAINING=$(grep -cE '\{\{[A-Z_]+\}\}' "$PROGRAM" || true)
if [[ "$REMAINING" -eq 0 ]]; then
  pass "No remaining {{PLACEHOLDER}} literals in program.md"
else
  fail "$REMAINING unresolved placeholders in program.md:"
  grep -oE '\{\{[A-Z_]+\}\}' "$PROGRAM" | sort -u | while read -r ph; do
    echo "        - $ph"
  done
fi

# Topic substituted
grep -q "prompt engineering with Claude" "$PROGRAM" \
  && pass "{{TOPIC}} correctly substituted" \
  || fail "{{TOPIC}} not found in program.md"

# Topic type
grep -q "^research$" "$PROGRAM" \
  && pass "{{TOPIC_TYPE}} correctly substituted" \
  || fail "{{TOPIC_TYPE}} not substituted correctly"

# Language
grep -q "English" "$PROGRAM" \
  && pass "{{LANGUAGE}} correctly substituted" \
  || fail "{{LANGUAGE}} not found"

# Max cycles
grep -q "8 cycles total" "$PROGRAM" \
  && pass "{{MAX_CYCLES}} correctly substituted" \
  || fail "{{MAX_CYCLES}} not substituted (looking for '8 cycles total')"

# Output dir
grep -q "$TEST_OUTPUT" "$PROGRAM" \
  && pass "{{OUTPUT_DIR}} correctly substituted" \
  || fail "{{OUTPUT_DIR}} not found in program.md"

# Skill dir (for BRIEF template path)
grep -q "$SKILL_DIR_RESOLVED" "$PROGRAM" \
  && pass "{{SKILL_DIR}} correctly substituted" \
  || fail "{{SKILL_DIR}} not found in program.md"

# No hardcoded paths
if grep -q '~/.claude/skills' "$PROGRAM"; then
  fail "program.md contains hardcoded ~/.claude/skills path"
else
  pass "program.md has no hardcoded paths"
fi

echo ""

# ── research.md checks ───────────────────────────────────────────────
echo "  [research.md]"

[[ -f "$TEST_OUTPUT/research.md" ]] \
  && pass "research.md exists" \
  || fail "research.md not created"

grep -q "Research Knowledge Base" "$TEST_OUTPUT/research.md" \
  && pass "Has Knowledge Base header" \
  || fail "Missing Knowledge Base header"

grep -q "Executive Summary" "$TEST_OUTPUT/research.md" \
  && pass "Has Executive Summary section" \
  || fail "Missing Executive Summary"

grep -q "## 1\." "$TEST_OUTPUT/research.md" \
  && pass "Has numbered research line sections" \
  || fail "Missing numbered research lines"

grep -q "### 1.1" "$TEST_OUTPUT/research.md" \
  && pass "Has sub-hypothesis sections" \
  || fail "Missing sub-hypotheses"

grep -q "Source Queue" "$TEST_OUTPUT/research.md" \
  && pass "Has Source Queue section" \
  || fail "Missing Source Queue"

# Check Source Queue has correct columns
grep -A1 "Source Queue" "$TEST_OUTPUT/research.md" | grep -q "Authority" \
  && pass "Source Queue has scoring columns" \
  || fail "Source Queue missing scoring columns"

grep -q "Appendix: Sources" "$TEST_OUTPUT/research.md" \
  && pass "Has Appendix: Sources section" \
  || fail "Missing Appendix: Sources"

# Count research line sections
LINE_COUNT=$(grep -c "^## [0-9]" "$TEST_OUTPUT/research.md" || true)
if [[ "$LINE_COUNT" -ge 3 ]]; then
  pass "Has $LINE_COUNT research line sections (expected ≥3)"
else
  fail "Only $LINE_COUNT research line sections (expected ≥3)"
fi

echo ""

# ── experiments.tsv checks ───────────────────────────────────────────
echo "  [experiments.tsv]"

[[ -f "$TEST_OUTPUT/experiments.tsv" ]] \
  && pass "experiments.tsv exists" \
  || fail "experiments.tsv not created"

# Check header columns
HEADER=$(head -1 "$TEST_OUTPUT/experiments.tsv")
for col in cycle timestamp line hypothesis sources_found key_finding status research_md_lines gate_decision next_direction; do
  echo "$HEADER" | grep -q "$col" \
    && pass "experiments.tsv has '$col' column" \
    || fail "experiments.tsv missing '$col' column"
done

# Check it's tab-separated (not spaces)
TAB_COUNT=$(head -1 "$TEST_OUTPUT/experiments.tsv" | tr -cd '\t' | wc -c)
if [[ "$TAB_COUNT" -eq 9 ]]; then
  pass "experiments.tsv is tab-separated (9 tabs for 10 columns)"
else
  fail "experiments.tsv tab count: $TAB_COUNT (expected 9)"
fi

echo ""

# ── steer.md checks ──────────────────────────────────────────────────
echo "  [steer.md]"

[[ -f "$TEST_OUTPUT/steer.md" ]] \
  && pass "steer.md exists" \
  || fail "steer.md not created"

grep -q "Steering File" "$TEST_OUTPUT/steer.md" \
  && pass "steer.md has header" \
  || fail "steer.md missing header"

grep -q "every cycle" "$TEST_OUTPUT/steer.md" \
  && pass "steer.md explains check frequency" \
  || fail "steer.md missing cycle check explanation"

echo ""

# ── Summary ──────────────────────────────────────────────────────────
echo "==========================================="
echo "  PASS: $PASS   FAIL: $FAIL"
echo "==========================================="
echo "  Output directory: $TEST_OUTPUT"

if [[ $FAIL -gt 0 ]]; then
  echo "  RESULT: FAILED ($FAIL issues found)"
  exit 1
else
  echo "  RESULT: PASSED"
  echo ""
  echo "  Files ready for agent test:"
  ls -la "$TEST_OUTPUT/"
  exit 0
fi

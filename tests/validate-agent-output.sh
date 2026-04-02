#!/usr/bin/env bash
# Test 3: Validate agent output after a research run completes
# Run: bash tests/validate-agent-output.sh <output-dir>
# Example: bash tests/validate-agent-output.sh ~/omni-research-test-output/2026-04-02-prompt-engineering-t3st

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: bash tests/validate-agent-output.sh <output-dir>"
  exit 1
fi

OUTPUT_DIR="$1"
PASS=0
FAIL=0
WARN=0

pass() { ((PASS++)); echo "  PASS  $1"; }
fail() { ((FAIL++)); echo "  FAIL  $1"; }
warn() { ((WARN++)); echo "  WARN  $1"; }

echo "=== Test 3: Agent Output Validation ==="
echo "Directory: $OUTPUT_DIR"
echo ""

# ── 1. File existence ────────────────────────────────────────────────
echo "--- 1. File Existence ---"

for f in program.md research.md experiments.tsv steer.md; do
  [[ -f "$OUTPUT_DIR/$f" ]] \
    && pass "$f exists" \
    || fail "$f missing"
done

# BRIEF.md may or may not exist yet
if [[ -f "$OUTPUT_DIR/BRIEF.md" ]]; then
  pass "BRIEF.md exists (research completed)"
  BRIEF_EXISTS=true
else
  warn "BRIEF.md not found (agent may still be running or terminated early)"
  BRIEF_EXISTS=false
fi

echo ""

# ── 2. research.md growth ────────────────────────────────────────────
echo "--- 2. research.md Content ---"

RESEARCH="$OUTPUT_DIR/research.md"
LINE_COUNT=$(wc -l < "$RESEARCH")

if [[ "$LINE_COUNT" -gt 30 ]]; then
  pass "research.md has $LINE_COUNT lines (grown from skeleton)"
else
  fail "research.md only has $LINE_COUNT lines (expected >30 after research)"
fi

# Check for inline citations [text](url)
CITATION_COUNT=$(grep -coE '\[.+\]\(https?://' "$RESEARCH" || true)
if [[ "$CITATION_COUNT" -ge 3 ]]; then
  pass "research.md has $CITATION_COUNT inline citations"
else
  fail "research.md has only $CITATION_COUNT inline citations (expected ≥3)"
fi

# Check Source Queue has entries
SQ_ENTRIES=$(grep -cE '^\| [0-9]' "$RESEARCH" || true)
if [[ "$SQ_ENTRIES" -ge 3 ]]; then
  pass "Source Queue has $SQ_ENTRIES entries"
else
  fail "Source Queue has only $SQ_ENTRIES entries (expected ≥3)"
fi

# Check for scoring columns in Source Queue entries
if grep -E '^\| [0-9]' "$RESEARCH" | head -1 | grep -qE '\| [1-5]' ; then
  pass "Source Queue entries have numeric scores"
else
  warn "Source Queue entries may be missing numeric scores"
fi

# Check for consensus markers
if grep -qE '\[✓|\[~|\[✗|sources agree|mixed evidence|conflicting' "$RESEARCH"; then
  pass "research.md contains consensus/conflict markers"
else
  warn "No consensus markers found (may be acceptable for short runs)"
fi

# Check Appendix: Sources has entries
APPENDIX_URLS=$(grep -cE 'https?://' "$RESEARCH" || true)
if [[ "$APPENDIX_URLS" -ge 5 ]]; then
  pass "research.md references $APPENDIX_URLS URLs total"
else
  warn "research.md only references $APPENDIX_URLS URLs (expected ≥5)"
fi

echo ""

# ── 3. experiments.tsv content ───────────────────────────────────────
echo "--- 3. experiments.tsv Content ---"

TSV="$OUTPUT_DIR/experiments.tsv"
TSV_ROWS=$(($(wc -l < "$TSV") - 1))  # Subtract header

if [[ "$TSV_ROWS" -ge 3 ]]; then
  pass "experiments.tsv has $TSV_ROWS data rows"
else
  fail "experiments.tsv has only $TSV_ROWS data rows (expected ≥3)"
fi

# Check for Phase 0 (source_scouting)
if grep -q "source_scouting" "$TSV"; then
  pass "Phase 0 source_scouting cycles logged"
else
  fail "No source_scouting entries in experiments.tsv (Phase 0 required)"
fi

# Check status values
for status in breakthrough useful incremental dead_end; do
  if grep -q "$status" "$TSV"; then
    pass "Status '$status' found in experiments.tsv"
    break
  fi
done

# Check for gate_decision entries (if enough cycles ran)
if [[ "$TSV_ROWS" -ge 4 ]]; then
  if grep -qE 'PROCEED|REFINE|PIVOT' "$TSV"; then
    pass "Gate decision (PROCEED/REFINE/PIVOT) logged"
  else
    warn "No gate decision found (expected after 4+ cycles)"
  fi
fi

# Check research_md_lines is increasing
LINES_COL=$(awk -F'\t' 'NR>1 && $8!="" {print $8}' "$TSV" | tail -5)
if [[ -n "$LINES_COL" ]]; then
  FIRST_LINE=$(echo "$LINES_COL" | head -1)
  LAST_LINE=$(echo "$LINES_COL" | tail -1)
  if [[ "$LAST_LINE" -gt "$FIRST_LINE" ]] 2>/dev/null; then
    pass "research.md line count growing ($FIRST_LINE → $LAST_LINE)"
  else
    warn "research.md line count not clearly growing"
  fi
else
  warn "Could not parse research_md_lines column"
fi

# Check total cycles ≤ max
if [[ "$TSV_ROWS" -le 8 ]]; then
  pass "Total cycles ($TSV_ROWS) within quick scope limit (≤8)"
else
  warn "Total cycles ($TSV_ROWS) exceeds quick scope max of 8"
fi

echo ""

# ── 4. BRIEF.md content ─────────────────────────────────────────────
if [[ "$BRIEF_EXISTS" == true ]]; then
  echo "--- 4. BRIEF.md Content ---"

  BRIEF="$OUTPUT_DIR/BRIEF.md"

  # Check for confidence legend
  if grep -q "Confidence" "$BRIEF"; then
    pass "BRIEF.md has confidence indicators"
  else
    fail "BRIEF.md missing confidence indicators"
  fi

  # Check for inline citations
  BRIEF_CITES=$(grep -coE '\[.+\]\(https?://' "$BRIEF" || true)
  if [[ "$BRIEF_CITES" -ge 2 ]]; then
    pass "BRIEF.md has $BRIEF_CITES inline citations"
  else
    warn "BRIEF.md has only $BRIEF_CITES inline citations"
  fi

  # Check for Research Stats section
  if grep -q "Research Stats" "$BRIEF"; then
    pass "BRIEF.md has Research Stats section"
  else
    fail "BRIEF.md missing Research Stats section"
  fi

  # Check for cycles count in stats
  if grep -q "Cycles" "$BRIEF"; then
    pass "BRIEF.md reports cycle count"
  else
    fail "BRIEF.md missing cycle count in stats"
  fi

  # Check for sources count in stats
  if grep -q "Sources" "$BRIEF"; then
    pass "BRIEF.md reports source count"
  else
    fail "BRIEF.md missing source count in stats"
  fi

  # Check BRIEF has actual content (not just template)
  BRIEF_LINES=$(wc -l < "$BRIEF")
  if [[ "$BRIEF_LINES" -gt 20 ]]; then
    pass "BRIEF.md has $BRIEF_LINES lines of content"
  else
    fail "BRIEF.md only has $BRIEF_LINES lines (expected >20)"
  fi

  echo ""
fi

# ── 5. steer.md status ──────────────────────────────────────────────
echo "--- 5. steer.md Status ---"

STEER="$OUTPUT_DIR/steer.md"
if grep -q "Processed" "$STEER"; then
  pass "steer.md shows agent has processed it"
else
  pass "steer.md unchanged (no steering attempted — expected)"
fi

echo ""

# ── Summary ──────────────────────────────────────────────────────────
echo "==========================================="
echo "  PASS: $PASS   FAIL: $FAIL   WARN: $WARN"
echo "==========================================="

if [[ $FAIL -gt 0 ]]; then
  echo "  RESULT: FAILED ($FAIL issues found)"
  exit 1
else
  echo "  RESULT: PASSED"
  exit 0
fi

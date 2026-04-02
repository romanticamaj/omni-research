#!/usr/bin/env bash
# Static validation for omni-research plugin structure
# Run: bash tests/validate-structure.sh
# Exit code 0 = all pass, 1 = failures found

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/omni-research"
PASS=0
FAIL=0
WARN=0

pass() { ((PASS++)); echo "  PASS  $1"; }
fail() { ((FAIL++)); echo "  FAIL  $1"; }
warn() { ((WARN++)); echo "  WARN  $1"; }

echo "=== Omni-Research Plugin Validation ==="
echo ""

# ── 1. Plugin structure ──────────────────────────────────────────────
echo "--- 1. Plugin Structure ---"

[[ -f "$REPO_ROOT/.claude-plugin/plugin.json" ]] \
  && pass "plugin.json exists" \
  || fail "plugin.json missing at .claude-plugin/plugin.json"

[[ -f "$SKILL_DIR/SKILL.md" ]] \
  && pass "SKILL.md exists" \
  || fail "SKILL.md missing at skills/omni-research/SKILL.md"

[[ -f "$SKILL_DIR/program-template.md" ]] \
  && pass "program-template.md exists" \
  || fail "program-template.md missing"

[[ -f "$SKILL_DIR/config.json.example" ]] \
  && pass "config.json.example exists" \
  || fail "config.json.example missing"

for type in product marketing production research; do
  [[ -f "$SKILL_DIR/templates/brief-${type}.md" ]] \
    && pass "brief-${type}.md template exists" \
    || fail "brief-${type}.md template missing"
done

[[ -f "$REPO_ROOT/.gitignore" ]] \
  && pass ".gitignore exists" \
  || warn ".gitignore missing"

[[ -f "$REPO_ROOT/CHANGELOG.md" ]] \
  && pass "CHANGELOG.md exists" \
  || warn "CHANGELOG.md missing"

[[ -f "$REPO_ROOT/LICENSE" ]] \
  && pass "LICENSE exists" \
  || warn "LICENSE missing"

echo ""

# ── 2. plugin.json validation ────────────────────────────────────────
echo "--- 2. plugin.json Validation ---"

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"

# Check required fields
for field in name version description; do
  if grep -q "\"$field\"" "$PLUGIN_JSON"; then
    pass "plugin.json has '$field' field"
  else
    fail "plugin.json missing '$field' field"
  fi
done

# Check name is kebab-case
NAME=$(grep '"name"' "$PLUGIN_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
if [[ "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  pass "plugin name '$NAME' is valid kebab-case"
else
  fail "plugin name '$NAME' is not valid kebab-case"
fi

# Check version is semver
VERSION=$(grep '"version"' "$PLUGIN_JSON" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  pass "plugin version '$VERSION' is valid semver"
else
  fail "plugin version '$VERSION' is not valid semver"
fi

echo ""

# ── 3. SKILL.md validation ───────────────────────────────────────────
echo "--- 3. SKILL.md Validation ---"

SKILL_FILE="$SKILL_DIR/SKILL.md"

# Check frontmatter
if head -1 "$SKILL_FILE" | grep -q "^---"; then
  pass "SKILL.md has YAML frontmatter"
else
  fail "SKILL.md missing YAML frontmatter"
fi

# Check required frontmatter fields
for field in name description; do
  if grep -q "^${field}:" "$SKILL_FILE"; then
    pass "SKILL.md frontmatter has '$field'"
  else
    fail "SKILL.md frontmatter missing '$field'"
  fi
done

# Check no hardcoded ~/.claude/skills paths
if grep -q '~/.claude/skills' "$SKILL_FILE"; then
  fail "SKILL.md contains hardcoded ~/.claude/skills/ path"
else
  pass "SKILL.md uses no hardcoded skill paths"
fi

# Check ${CLAUDE_SKILL_DIR} is used
if grep -q 'CLAUDE_SKILL_DIR' "$SKILL_FILE"; then
  pass "SKILL.md uses \${CLAUDE_SKILL_DIR}"
else
  fail "SKILL.md should reference \${CLAUDE_SKILL_DIR}"
fi

# Check ${CLAUDE_PLUGIN_DATA} is used for config
if grep -q 'CLAUDE_PLUGIN_DATA' "$SKILL_FILE"; then
  pass "SKILL.md uses \${CLAUDE_PLUGIN_DATA} for config"
else
  fail "SKILL.md should use \${CLAUDE_PLUGIN_DATA} for config storage"
fi

echo ""

# ── 4. Placeholder consistency ───────────────────────────────────────
echo "--- 4. Placeholder Consistency ---"

PROGRAM_FILE="$SKILL_DIR/program-template.md"

# Extract {{PLACEHOLDERS}} from program-template.md
PROGRAM_PLACEHOLDERS=$(grep -oE '\{\{[A-Z_]+\}\}' "$PROGRAM_FILE" | sort -u)

# Check each placeholder in program-template.md is documented in SKILL.md
for ph in $PROGRAM_PLACEHOLDERS; do
  # Strip the {{ }} for searching
  ph_name=$(echo "$ph" | sed 's/[{}]//g')
  if grep -q "$ph_name" "$SKILL_FILE"; then
    pass "Placeholder $ph referenced in SKILL.md"
  else
    fail "Placeholder $ph in program-template.md but not in SKILL.md"
  fi
done

echo ""

# ── 5. experiments.tsv header consistency ────────────────────────────
echo "--- 5. experiments.tsv Header Consistency ---"

SKILL_TSV=$(grep 'cycle' "$SKILL_FILE" | grep 'timestamp' | head -1 | tr -d ' \t\r\n' | sed 's/```//')
PROGRAM_TSV=$(grep 'cycle' "$PROGRAM_FILE" | grep 'timestamp' | head -1 | tr -d ' \t\r\n' | sed 's/```//')

# Normalize: remove all whitespace for comparison
SKILL_TSV_NORM=$(echo "$SKILL_TSV" | tr -d '[:space:]')
PROGRAM_TSV_NORM=$(echo "$PROGRAM_TSV" | tr -d '[:space:]')

if [[ "$SKILL_TSV_NORM" == "$PROGRAM_TSV_NORM" ]]; then
  pass "experiments.tsv header matches between SKILL.md and program-template.md"
else
  fail "experiments.tsv header MISMATCH"
  echo "        SKILL.md:    $(grep -P 'cycle\t' "$SKILL_FILE" | head -1)"
  echo "        program.md:  $(grep -P 'cycle\t' "$PROGRAM_FILE" | head -1)"
fi

echo ""

# ── 6. BRIEF template consistency ────────────────────────────────────
echo "--- 6. BRIEF Template Consistency ---"

# All templates should have confidence legend
for type in product marketing production research; do
  TMPL="$SKILL_DIR/templates/brief-${type}.md"

  if grep -q "Confidence legend" "$TMPL"; then
    pass "brief-${type}.md has confidence legend"
  else
    fail "brief-${type}.md missing confidence legend"
  fi

  if grep -q "GATE_DECISIONS" "$TMPL"; then
    pass "brief-${type}.md has GATE_DECISIONS stat"
  else
    fail "brief-${type}.md missing GATE_DECISIONS in Research Stats"
  fi

  if grep -q "Translate all section headers" "$TMPL"; then
    pass "brief-${type}.md has language translation note"
  else
    fail "brief-${type}.md missing language translation note"
  fi

  if grep -q "Confidence" "$TMPL" | head -1; then
    pass "brief-${type}.md references table has Confidence column"
  else
    # Check more carefully
    if grep -q "| Confidence |" "$TMPL"; then
      pass "brief-${type}.md references table has Confidence column"
    else
      fail "brief-${type}.md references table missing Confidence column"
    fi
  fi
done

echo ""

# ── 7. Source Queue consistency ──────────────────────────────────────
echo "--- 7. Source Queue Table Consistency ---"

# Check column count in SKILL.md Source Queue
SKILL_SQ_COLS=$(grep -A1 'Source Queue' "$SKILL_FILE" | grep '|' | head -1 | tr -cd '|' | wc -c)
PROGRAM_SQ_COLS=$(grep -A1 'Source Queue' "$PROGRAM_FILE" | grep '|' | head -1 | tr -cd '|' | wc -c)

if [[ "$SKILL_SQ_COLS" -eq "$PROGRAM_SQ_COLS" ]]; then
  pass "Source Queue column count matches ($SKILL_SQ_COLS pipes)"
else
  fail "Source Queue column count mismatch: SKILL.md=$SKILL_SQ_COLS, program-template.md=$PROGRAM_SQ_COLS"
fi

# Check required columns exist in program-template.md
for col in Lines Authority Recency Relevance Score Status; do
  if grep -A2 'Source Queue' "$PROGRAM_FILE" | grep -q "$col"; then
    pass "Source Queue has '$col' column"
  else
    fail "Source Queue missing '$col' column"
  fi
done

echo ""

# ── 8. No stale references ──────────────────────────────────────────
echo "--- 8. Stale Reference Check ---"

# No hardcoded paths in any skill file
for f in "$SKILL_FILE" "$PROGRAM_FILE"; do
  fname=$(basename "$f")
  if grep -q '~/.claude/skills/omni-research' "$f"; then
    fail "$fname contains hardcoded ~/.claude/skills/omni-research path"
  else
    pass "$fname has no hardcoded skill paths"
  fi
done

# Check [未驗證] is not hardcoded (should be [Unverified])
for f in "$SKILL_FILE" "$PROGRAM_FILE"; do
  fname=$(basename "$f")
  if grep -q '未驗證' "$f"; then
    fail "$fname contains hardcoded Chinese [未驗證] marker"
  else
    pass "$fname uses language-neutral markers"
  fi
done

# Check BRIEF templates don't have hardcoded [未驗證]
for type in product marketing production research; do
  TMPL="$SKILL_DIR/templates/brief-${type}.md"
  if grep -q '未驗證' "$TMPL"; then
    fail "brief-${type}.md contains hardcoded Chinese [未驗證]"
  else
    pass "brief-${type}.md uses language-neutral markers"
  fi
done

echo ""

# ── 9. Cycle cadence consistency ─────────────────────────────────────
echo "--- 9. Cycle Cadence Consistency ---"

# PIVOT/REFINE should be every 4th
PIVOT_REFS=$(grep -c 'every 4' "$PROGRAM_FILE" || true)
if [[ "$PIVOT_REFS" -ge 2 ]]; then
  pass "PIVOT/REFINE gate consistently referenced as 'every 4th'"
else
  warn "PIVOT/REFINE gate references may be inconsistent (found $PIVOT_REFS)"
fi

# Source discovery should be every 5th
DISCOVERY_REFS=$(grep -c 'every 5' "$PROGRAM_FILE" || true)
if [[ "$DISCOVERY_REFS" -ge 2 ]]; then
  pass "Source discovery consistently referenced as 'every 5th'"
else
  warn "Source discovery references may be inconsistent (found $DISCOVERY_REFS)"
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

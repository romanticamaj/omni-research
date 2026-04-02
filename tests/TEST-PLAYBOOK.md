# Omni-Research Test Playbook

Manual test procedures for validating the omni-research skill. Run these in a Claude Code session.

## Pre-requisites

- Claude Code CLI, desktop app, or IDE extension
- A plan with background agents and web tools (WebSearch, WebFetch)
- The omni-research plugin installed (via `/plugin install` or manual copy)

## Test 0: Static Validation (Automated)

```bash
bash tests/validate-structure.sh
```

**Expected:** All checks PASS (0 FAIL). Validates plugin structure, placeholder consistency, template formatting, and no stale references.

---

## Test 1: First-Run Config Setup

**Goal:** Verify Step 0 config resolution works on fresh install.

### Steps

1. Delete existing config (if any):
   ```
   Tell Claude: "Delete the file at ${CLAUDE_PLUGIN_DATA}/config.json if it exists"
   ```
2. Run `/omni-research`
3. When prompted for output directory, provide a test path (e.g., `~/omni-research-test-output`)

### Verify

- [ ] Claude asks for output directory path
- [ ] Config file is created at `${CLAUDE_PLUGIN_DATA}/config.json`
- [ ] Config contains the path you provided
- [ ] On next `/omni-research` run, it does NOT ask for the directory again

---

## Test 2: Setup Flow (Steps 1-6)

**Goal:** Verify the interactive setup produces correct files.

### Steps

1. Run `/omni-research`
2. Use this test topic: **"Best practices for prompt engineering with Claude"**
3. When asked for type, confirm **research**
4. When asked for context/intuitions, say: **"I'm interested in system prompts, few-shot examples, and chain-of-thought. Done."**
5. Review proposed research lines — confirm as-is
6. Select **(a) Quick survey** (5-8 cycles)
7. Confirm launch

### Verify — Output Directory

- [ ] Directory created at `<output_base_dir>/YYYY-MM-DD-prompt-engineering-XXXX/`
- [ ] Date matches today
- [ ] Slug is derived from topic
- [ ] 4-char random suffix present

### Verify — program.md

- [ ] File exists in output directory
- [ ] `{{TOPIC}}` replaced with actual topic (no literal `{{TOPIC}}`)
- [ ] `{{TOPIC_TYPE}}` replaced with `research`
- [ ] `{{LANGUAGE}}` replaced with `English`
- [ ] `{{MAX_CYCLES}}` replaced with `8`
- [ ] `{{OUTPUT_DIR}}` replaced with actual path
- [ ] `{{SKILL_DIR}}` replaced with actual skill directory path
- [ ] `{{RESEARCH_LINES}}` replaced with the confirmed lines
- [ ] `{{SEED_SOURCES}}` replaced (either URLs or "None provided" message)
- [ ] `{{CONTEXT}}` replaced with user's context
- [ ] **No remaining `{{...}}` literal placeholders** (search for `{{`)

### Verify — research.md

- [ ] File exists with skeleton structure
- [ ] Has `# [Topic] — Research Knowledge Base` header
- [ ] Has `## Executive Summary` section
- [ ] Has numbered sections matching research lines (e.g., `## 1. System Prompts`)
- [ ] Each line has sub-hypotheses (e.g., `### 1.1 ...`)
- [ ] Has `## Source Queue` section with correct 9-column table header
- [ ] Has `## Appendix: Sources` section

### Verify — experiments.tsv

- [ ] File exists with header row
- [ ] Header is: `cycle  timestamp  line  hypothesis  sources_found  key_finding  status  research_md_lines  gate_decision  next_direction`
- [ ] Tab-separated (not spaces)

### Verify — steer.md

- [ ] File exists with instructions
- [ ] Contains example steering commands
- [ ] Mentioned in Claude's launch message to user

---

## Test 3: Background Agent Execution (Quick Scope)

**Goal:** Verify the autonomous research agent runs correctly through all 3 phases.

### Steps

1. After Test 2 launches the agent, wait for completion (quick scope = ~10-20 minutes)
2. Monitor `research.md` periodically to see it growing

### Verify — Phase 0 (Source Scouting)

- [ ] experiments.tsv has 1-2 rows with `line` = `source_scouting`
- [ ] Source Queue in research.md has entries with scores (Authority/Recency/Relevance/Score columns filled)
- [ ] At least some sources have Score ≥ 4.0

### Verify — Phase 1 (Seed Mining)

- [ ] experiments.tsv has rows from seed mining (line = a research line name)
- [ ] Sources in Source Queue marked as `done`
- [ ] research.md sections have content with inline citations `[text](url)`

### Verify — Phase 2 (Hypothesis Loop)

- [ ] experiments.tsv has hypothesis cycle rows
- [ ] `status` column has values from: `breakthrough`, `useful`, `incremental`, `dead_end`
- [ ] `research_md_lines` column shows increasing line counts
- [ ] At least one `gate_decision` entry (PROCEED/REFINE/PIVOT) appears (if ≥4 Phase 2 cycles ran)

### Verify — Inline Citations

- [ ] research.md body contains `[text](url)` inline links (not just appendix)
- [ ] At least 5 distinct source URLs are cited
- [ ] No `[Unverified]` markers (ideally — some are acceptable)

### Verify — Confidence Signals

- [ ] research.md contains at least one consensus marker: `[✓`, `[~`, or `[✗`
- [ ] Or equivalent natural language ("sources agree", "mixed evidence", "conflicting")

### Verify — Completion

- [ ] BRIEF.md generated in output directory
- [ ] BRIEF.md follows the brief-research.md template structure
- [ ] BRIEF.md has confidence legend (🟢/🟡/🔴) in header
- [ ] BRIEF.md has Research Stats section with cycles, runtime, sources cited
- [ ] BRIEF.md has inline citations in the body
- [ ] Agent's final message contains BRIEF.md content

### Verify — Termination

- [ ] experiments.tsv shows a termination reason (saturation, completion, or max cycles)
- [ ] Total cycle count ≤ 8 (quick scope max)

---

## Test 4: Mid-Run Steering

**Goal:** Verify the agent reads and follows steer.md edits.

### Steps

1. Start a new `/omni-research` session (comprehensive scope for more time)
2. Topic: **"Comparison of React vs Vue vs Svelte for enterprise applications"**
3. After agent launches, wait for 2-3 cycles (check experiments.tsv)
4. Edit `steer.md` in the output directory:
   ```markdown
   Focus on Line 1 (React) for the next 2 cycles — I need depth here before moving on.
   ```
5. Wait for 2 more cycles

### Verify

- [ ] experiments.tsv shows the next 1-2 cycles focused on the redirected line
- [ ] steer.md contains `[Processed cycle N]` appended to the instruction
- [ ] Agent did not ignore the steering (check `line` column in experiments.tsv)

---

## Test 5: Recovery BRIEF Generation

**Goal:** Verify `/omni-research brief <path>` regenerates BRIEF from existing data.

### Steps

1. Take the output directory from Test 3
2. Delete BRIEF.md:
   ```bash
   rm <output-dir>/BRIEF.md
   ```
3. Run: `/omni-research brief <output-dir-path>`

### Verify

- [ ] BRIEF.md is regenerated
- [ ] Content synthesizes findings from research.md (not generic)
- [ ] Correct template used (matching the topic type from program.md)
- [ ] Confidence legend present
- [ ] Research Stats filled in
- [ ] Inline citations present
- [ ] Claude displays the BRIEF content in chat

---

## Test 6: Edge Cases

### 6a: Vague Topic Rejection

1. Run `/omni-research`
2. Enter a vague topic: **"AI"**
3. **Expected:** Claude asks to narrow it down (not accepted as-is)

### 6b: Type Override

1. Run `/omni-research`
2. Enter: **"How to build a SaaS for pet grooming scheduling"**
3. Claude should auto-detect as **product**
4. Say: **"Actually, make it marketing"**
5. **Expected:** Type changes to marketing

### 6c: Empty Seed Sources

1. During Step 3, just say **"done"** immediately
2. **Expected:** `{{SEED_SOURCES}}` in program.md set to "None provided — the agent will run Phase 0..."

### 6d: Multiple Seed URLs

1. During Step 3, paste 2-3 URLs and say done
2. **Expected:** URLs appear in program.md under Seed Sources section

### 6e: Non-English Language

1. Run `/omni-research`
2. Enter topic in Chinese: **"比較 React 和 Vue 在企業應用中的優劣"**
3. **Expected:** Language auto-detected as Chinese, all output in Chinese
4. **Expected:** BRIEF.md section headers translated to Chinese (not English)

---

## Test 7: Plugin Installation (Clean Install)

**Goal:** Verify a fresh user can install and use the plugin.

### Steps

1. In a clean Claude Code session (no prior omni-research):
   ```
   /plugin marketplace add romanticamaj/omni-research
   /plugin install omni-research
   ```
2. Start a new session
3. Run `/omni-research`

### Verify

- [ ] Plugin installs without errors
- [ ] `/omni-research` appears in skill autocomplete
- [ ] Skill runs correctly (Step 0 config prompt appears)

---

## Scoring

| Test | Weight | Status |
|------|--------|--------|
| Test 0: Static validation | Required | |
| Test 1: Config setup | Required | |
| Test 2: Setup flow | Required | |
| Test 3: Agent execution | Required | |
| Test 4: Mid-run steering | Important | |
| Test 5: Recovery BRIEF | Important | |
| Test 6: Edge cases | Nice to have | |
| Test 7: Plugin installation | Required (once published) | |

**Minimum for release:** Tests 0-3 all pass. Tests 4-5 are strongly recommended.

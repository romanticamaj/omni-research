---
name: omni-research
description: Use when the user wants to autonomously research any topic — product ideas, marketing plans, production plans, or pure research questions. Guides interactive setup, then spawns a background agent for autonomous web research.
---

# Omni-Research

Autonomous research agent. Guides the user through topic setup, then spawns a background agent that loops: hypothesis → web search → synthesis → knowledge accumulation → auto-terminate when saturated.

## Entry Points

**Primary:** `/omni-research` — full interactive setup flow (Steps 0-7 below)
**Recovery:** `/omni-research brief <path>` — generate BRIEF.md from existing research.md + experiments.tsv at `<path>`. Skip to Step 8.

Routing logic:
- `/omni-research` (no args) → Step 0, then Step 1
- `/omni-research brief <path>` → Step 8 (requires `<path>/research.md` to exist)
- `/omni-research <path>` (no `brief` keyword) → check if `<path>/research.md` exists. If yes, treat as recovery (Step 8). If no, treat as primary (Step 0, then Step 1).

## Configuration

On every `/omni-research` invocation (except `brief`), **before Step 1**, run **Step 0: Resolve Output Directory**.

Config file location: `~/.claude/skills/omni-research/config.json`

```json
{
  "output_base_dir": ""
}
```

### Step 0: Resolve Output Directory

1. Read `~/.claude/skills/omni-research/config.json`
2. If `output_base_dir` is empty or the path does not exist on disk:
   - Ask the user:
     > Where should research reports be saved? Please provide an absolute path to a base directory.
     > (e.g. `D:\garysrc\omni-research-agent\docs\research` or `~/projects/research`)
   - Validate that the provided path exists (create it if the user confirms)
   - Write the path back to `config.json`
3. If `output_base_dir` is set and the path exists: proceed silently — do not ask again.
4. The final output directory for each research session will be: `<output_base_dir>/YYYY-MM-DD-<slug>-<4char>/`

## Flow

### Step 1: Ask Topic

> What do you want to research? This can be a product idea, marketing plan, production plan, or a pure research question.
> Share any initial thoughts, intuitions, or reference materials you have.

Collect the topic description. If too vague (fewer than 3 specific nouns or constraints), ask the user to narrow it:

> That's quite broad. Can you narrow it down? For example, instead of "AI in healthcare" → "How to use LLM conversation to assess elderly patients' cognitive decline in home settings"

### Step 2: Classify Topic Type

Auto-detect which type fits best, then confirm:

| Type | Signal words |
|------|-------------|
| **product** | build, app, tool, feature, MVP, prototype, startup, SaaS |
| **marketing** | audience, campaign, channel, brand, positioning, GTM, launch |
| **production** | workflow, timeline, budget, team, deliverable, milestone, specs |
| **research** | literature, theory, evidence, hypothesis, mechanism, framework |

> This looks like a **[type]** research. Correct?
> (Options: product / marketing / production / research)

### Step 3: Collect User Intuitions & Seed Sources (Deep)

> Do you have any intuitions, hypotheses, or reference materials for this topic?
> You can paste links, file paths, or describe your thinking. Say "done" when finished.
>
> If you already know of trusted guides, blog posts, or community threads — feel free to paste URLs. But don't worry if you don't — the research agent will **automatically scout for high-quality sources** before diving into research, using curated list searches, community forum searches, and expert blog discovery.

Accept multiple rounds. Read any files or URLs the user provides. Accumulate all context.

If the user provides URLs, separate them into a `{{SEED_SOURCES}}` list for injection into program.md. If no URLs provided, set `{{SEED_SOURCES}}` to "None provided — the agent will run Phase 0 Source Scouting to discover high-quality sources automatically."

### Step 4: Propose Research Lines

Based on topic + user context, propose **3-5 research lines**:

```
Line 1 — [Name]
 • Hypothesis/angle 1
 • Hypothesis/angle 2
 • Hypothesis/angle 3

Line 2 — [Name]
 • Hypothesis/angle 1
 • Hypothesis/angle 2
 • Hypothesis/angle 3

...
```

Each line = independent research direction. Combined = comprehensive coverage.

> Review these research lines. You can confirm, modify, add, or remove lines.

### Step 5: Configure Scope

> How deep should the research go?
> (a) Quick survey — 5-8 cycles, ~10 sources
> (b) Comprehensive — 12-20 cycles, ~25 sources
> (c) Deep dive — 20+ cycles, 30+ sources

Map to max_cycles: (a)=8, (b)=20, (c)=30

### Step 6: Confirm & Launch

Display summary:

```
Topic:     [topic]
Type:      [product/marketing/production/research]
Language:  [auto-detected, e.g. "Chinese" or "English"]
Scope:     [quick/comprehensive/deep] (max N cycles)
Lines:     [count] research lines
Output:    <output_base_dir>/YYYY-MM-DD-<slug>-<4char>/
```

> Confirm to launch? (The output language was auto-detected from your input — let me know if you want to change it.)

On confirm:

1. Generate a 4-character random suffix (lowercase alphanumeric)
2. Create output directory: `<output_base_dir>/YYYY-MM-DD-<slug>-<4char>/` (using the path from Step 0)
3. Read `~/.claude/skills/omni-research/program-template.md`
4. Replace all `{{placeholders}}`:
   - `{{TOPIC}}` → user's topic
   - `{{CONTEXT}}` → accumulated user context from Step 3
   - `{{TOPIC_TYPE}}` → product/marketing/production/research
   - `{{RESEARCH_LINES}}` → confirmed lines (as numbered sections with sub-questions)
   - `{{SEED_SOURCES}}` → user-provided URLs from Step 3 (or "None provided" if empty)
   - `{{LANGUAGE}}` → detected language
   - `{{MAX_CYCLES}}` → from scope selection
   - `{{OUTPUT_DIR}}` → the output directory path
5. Write `program.md` to output directory
6. Create `research.md` skeleton:
   ```
   # [Topic] — Research Knowledge Base
   ## Last Updated: [date]
   ## Total Research Cycles: 0

   ## Executive Summary
   [To be filled by research agent]

   ## 1. [Line 1 Name]
   ### 1.1 [Hypothesis 1]
   ### 1.2 [Hypothesis 2]
   ### 1.3 [Hypothesis 3]
   ...continue for all lines...

   ## [Next #]. Design Recommendations / Actionable Insights
   [Practical takeaways]

   ## [Next #]. Open Questions & Next Directions
   [What we still don't know]

   ## Source Queue
   | # | URL | Title/Author | Lines | Authority | Recency | Relevance | Score | Status |
   |---|-----|-------------|-------|-----------|---------|-----------|-------|--------|
   
   ## Appendix: Sources
   [Full citation list with URLs]
   ```
7. Create `experiments.tsv` with header:
   ```
   cycle	timestamp	line	hypothesis	sources_found	key_finding	status	research_md_lines	gate_decision	next_direction
   ```
8. Create `steer.md` with initial content:
   ```
   # Steering File
   Write instructions here to redirect the research agent mid-run.
   The agent checks this file at the start of every cycle.
   Examples: "Focus on Line 3 next", "Add this context: ...", "Skip Line 2", "Wrap up soon"
   ```
9. Spawn background agent (substitute the actual output directory path for `<output-dir>`):
   ```
   Agent(
     subagent_type: "general-purpose",
     run_in_background: true,
     prompt: "You are an autonomous research agent. Read program.md at <output-dir>/program.md for your complete instructions. Begin immediately. Work autonomously until you meet the termination conditions defined in program.md. When done, return the full content of BRIEF.md as your final message."
   )
   ```

### Step 7: Report

> Research agent launched in background. You'll be notified when it completes with a summary.
>
> **Live files you can check anytime:**
> - `<output-dir>/research.md` — accumulated knowledge (grows each cycle)
> - `<output-dir>/experiments.tsv` — experiment log (one row per cycle)
> - `<output-dir>/steer.md` — **edit this to redirect the agent mid-run** (e.g., "Focus on Line 3", "Add context: ...", "Wrap up soon")
>
> When complete, `BRIEF.md` will be generated and I'll show you the summary.

### Step 8: Recovery BRIEF Generation

For `/omni-research brief <path>`:

1. Read `<path>/research.md` and `<path>/experiments.tsv`
2. Detect topic type from `<path>/program.md` (look for `## Topic Type` section value)
3. Read the matching BRIEF template from `~/.claude/skills/omni-research/templates/brief-<type>.md`
4. Generate BRIEF.md following the template, synthesizing all findings from research.md
5. Write to `<path>/BRIEF.md`
6. Display the BRIEF content to the user

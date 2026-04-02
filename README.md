# Omni-Research

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Skill](https://img.shields.io/badge/Claude%20Code-Skill-blueviolet)](https://docs.anthropic.com/en/docs/claude-code)

Autonomous research agent skill for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Give it a topic, and it autonomously searches the web, verifies sources, synthesizes findings, and produces a structured research report — all running in the background while you continue working.

```
/omni-research
```

## Why This Exists

Asking an AI to "research X" gives you a one-shot answer based on training data. Omni-Research is different: it runs a **multi-cycle autonomous loop** that searches the web, reads actual pages, verifies every claim at the source, and builds a growing knowledge base over 5-30+ research cycles. The result is closer to what a human research analyst would produce — with citations you can actually check.

## How It Works

```
You                          Claude Code                        Background Agent
 |                               |                                    |
 |  /omni-research               |                                    |
 |------------------------------>|                                    |
 |  "Research X topic"           |                                    |
 |                               |  Interactive setup:                |
 |  <-- Topic? Type? Scope? -->  |  1. Refine topic                   |
 |  <-- Research lines? -------> |  2. Classify type                  |
 |  <-- Confirm? --------------> |  3. Propose research lines         |
 |                               |  4. Configure depth                |
 |                               |                                    |
 |                               |  Launch background agent --------->|
 |                               |                                    |
 |  "Agent launched. Check       |    PHASE 0: Source Scouting        |
 |   research.md anytime."       |    - Hunt curated lists, blogs,    |
 |                               |      community threads             |
 |  (continue your work)         |    - Score sources (1-5)           |
 |                               |    - Build Source Queue (8+ items) |
 |                               |                                    |
 |  (edit steer.md to redirect)  |    PHASE 1: Seed Mining            |
 |          |                    |    - WebFetch & deep-read sources  |
 |          v                    |    - Extract findings with inline  |
 |   "Focus on Line 3"          |      citations                     |
 |                               |                                    |
 |                               |    PHASE 2: Hypothesis Loop        |
 |                               |    1. Check steer.md for redirects |
 |                               |    2. Pick biggest knowledge gap   |
 |                               |    3. WebSearch for evidence       |
 |                               |    4. WebFetch & verify sources    |
 |                               |    5. Synthesize with inline cites |
 |                               |    6. Update research.md           |
 |                               |    7. Every 4th: PIVOT/REFINE gate|
 |                               |    8. Every 5th: discover sources  |
 |                               |    9. Repeat until saturated       |
 |                               |                                    |
 |                               |    COMPLETION:                     |
 |                               |    - Anti-fabrication verify pass  |
 |  <-- "Research complete!" ----|--- Generate BRIEF.md --------------|
 |                               |                                    |
```

## Features

- **4 research types** — product, marketing, production, pure research — each with tailored BRIEF templates
- **Autonomous loop** — searches, reads, evaluates, and synthesizes without intervention
- **Source verification** — every claim is WebFetched and verified in the original page before citing (no search-snippet-only citations)
- **Structured output** — `research.md` (growing knowledge base), `experiments.tsv` (cycle log), `BRIEF.md` (executive summary)
- **Configurable depth** — quick survey (5-8 cycles), comprehensive (12-20), or deep dive (20-30+)
- **Mid-run steering** — edit `steer.md` anytime to redirect the agent: change focus, add context, skip lines, or wrap up early
- **Inline citations** — every claim links to its source inline, not just in an appendix
- **Confidence signals** — findings marked with consensus (✓ agree / ~ mixed / ✗ conflict) and confidence levels (High/Medium/Low)
- **Source scoring** — sources rated on authority, recency, and relevance (1-5 each) to prioritize quality
- **PIVOT/REFINE gates** — every 4 cycles the agent evaluates progress and can change direction instead of grinding on dead ends
- **Anti-fabrication pass** — final sweep verifies every citation URL actually appeared in search results before publishing
- **Auto-detected language** — writes output in the same language you use
- **Live monitoring** — check `research.md` anytime to see progress
- **Recovery mode** — `/omni-research brief <path>` regenerates BRIEF.md from existing research data

## Installation

### 1. Copy the skill to Claude Code's global skills directory

**macOS / Linux:**
```bash
git clone https://github.com/romanticamaj/omni-research.git
cp -r omni-research ~/.claude/skills/omni-research
```

**Windows:**
```powershell
git clone https://github.com/romanticamaj/omni-research.git
xcopy /E /I omni-research %USERPROFILE%\.claude\skills\omni-research
```

### 2. Create the config file

```bash
cp ~/.claude/skills/omni-research/config.json.example ~/.claude/skills/omni-research/config.json
```

The first time you run `/omni-research`, it will ask where to save research output and remember your choice.

### 3. Verify

Start a new Claude Code session and type:
```
/omni-research
```

You should see the topic prompt. That's it.

## Usage

### Start a new research session

```
/omni-research
```

Follow the interactive prompts:
1. **Topic** — describe what you want to research
2. **Type** — product / marketing / production / research (auto-detected)
3. **Context** — share intuitions, links, files, or reference materials
4. **Research lines** — review and customize proposed research directions
5. **Scope** — quick (a), comprehensive (b), or deep dive (c)
6. **Confirm** — the agent launches in background

### Monitor progress

While the agent runs, check these files in your output directory:

| File | Description |
|------|-------------|
| `research.md` | Growing knowledge base — updated every cycle |
| `experiments.tsv` | One row per cycle: hypothesis, sources found, key finding, status |
| `steer.md` | **Edit this to redirect the agent mid-run** (change focus, add context, wrap up) |
| `program.md` | The full research program (for reference) |
| `BRIEF.md` | Executive summary (generated when research completes) |

### Steer mid-run

Edit `steer.md` in the output directory to redirect the agent while it's running:

```markdown
Focus on Line 3 — I found this article that might help: https://example.com/article
```

The agent checks this file at the start of every cycle and follows your instructions.

### Recover / regenerate a BRIEF

If the session ended early or you want to regenerate the summary:

```
/omni-research brief path/to/research-output/
```

## Output Structure

```
<output_base_dir>/
  2026-03-28-suno-prompting-r7k2/
    program.md          # Research instructions
    research.md         # Accumulated knowledge (grows each cycle)
    steer.md            # Steering file (edit to redirect agent)
    experiments.tsv     # Experiment log
    BRIEF.md            # Executive summary (generated at completion)
```

## File Overview

```
omni-research/
  SKILL.md                # Skill definition (interactive flow)
  program-template.md     # Template for the autonomous agent's instructions
  config.json.example     # Example config (copy to config.json)
  templates/
    brief-product.md      # BRIEF template for product research
    brief-marketing.md    # BRIEF template for marketing research
    brief-production.md   # BRIEF template for production research
    brief-research.md     # BRIEF template for pure research
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI, desktop app, or IDE extension
- A Claude plan with **background agents** and **web tools** (WebSearch, WebFetch) — this includes Max and Team plans

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Agent stops mid-research | Context window limit reached | Use `/omni-research brief <path>` to generate BRIEF from partial results |
| "WebSearch not available" | Plan doesn't support web tools | Upgrade to a plan with web tool access |
| Agent drifts from topic | Long research sessions can lose focus | Edit `steer.md` to redirect, or reduce scope to "quick survey" |
| `config.json` not found | First-time setup | The skill will prompt you — just provide the output directory path |
| Empty `research.md` after launch | Agent failed to start | Check that `program.md` was created in the output directory |

## License

MIT

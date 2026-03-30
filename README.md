# Omni-Research

Autonomous research agent skill for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Give it a topic, and it autonomously searches the web, verifies sources, synthesizes findings, and produces a structured research report — all running in the background while you continue working.

```
/omni-research
```

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
 |  "Agent launched. Check       |    LOOP:                           |
 |   research.md anytime."       |    1. Read current knowledge       |
 |                               |    2. Pick biggest gap             |
 |  (continue your work)         |    3. WebSearch for evidence       |
 |                               |    4. WebFetch & verify sources    |
 |                               |    5. Synthesize findings          |
 |                               |    6. Update research.md           |
 |                               |    7. Log in experiments.tsv       |
 |                               |    8. Check termination            |
 |                               |    9. Repeat until saturated       |
 |                               |                                    |
 |  <-- "Research complete!" ----|--- Generate BRIEF.md --------------|
 |                               |                                    |
```

## Features

- **4 research types** — product, marketing, production, pure research — each with tailored BRIEF templates
- **Autonomous loop** — searches, reads, evaluates, and synthesizes without intervention
- **Source verification** — every claim is WebFetched and verified in the original page before citing (no search-snippet-only citations)
- **Structured output** — `research.md` (growing knowledge base), `experiments.tsv` (cycle log), `BRIEF.md` (executive summary)
- **Configurable depth** — quick survey (5-8 cycles), comprehensive (12-20), or deep dive (20-30+)
- **Auto-detected language** — writes output in the same language you use
- **Live monitoring** — check `research.md` anytime to see progress
- **Recovery mode** — `/omni-research brief <path>` regenerates BRIEF.md from existing research data

## Installation

### 1. Copy the skill to Claude Code's global skills directory

**macOS / Linux:**
```bash
# Clone the repo
git clone https://github.com/romanticamaj/omni-research.git

# Copy to Claude Code skills directory
cp -r omni-research ~/.claude/skills/omni-research
```

**Windows:**
```powershell
# Clone the repo
git clone https://github.com/romanticamaj/omni-research.git

# Copy to Claude Code skills directory
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
| `program.md` | The full research program (for reference) |
| `BRIEF.md` | Executive summary (generated when research completes) |

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
- A Claude plan that supports background agents and web tools (WebSearch, WebFetch)

## License

MIT

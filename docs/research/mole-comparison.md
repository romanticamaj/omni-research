# Mole Comparison — What Omni-Research Should Learn

Reference project: https://github.com/lajosdeme/mole

## Executive summary

Omni-Research and Mole solve the same broad problem — autonomous deep research — at different layers.

- **Omni-Research is a research strategy / agent harness.** The skill tells Claude Code how to scout sources, mine seeds, iterate hypotheses, pivot, verify, synthesize, and stop.
- **Mole is a research runtime.** It moves budget enforcement, evidence storage, quote verification, fetch safety, claim relationships, output validation, and evaluation into deterministic code.

The main design lesson is:

> **Prompt should own reasoning; code should own invariants.**

Omni-Research should keep its current strength — a flexible research method that can evolve quickly — while progressively moving reliability guarantees out of `program-template.md` and into deterministic tools.

## Current architecture difference

```text
Omni-Research today

Claude Code
   |
   v
SKILL.md
   |
   v
program.md
   |
   v
LLM controls
  - planning
  - search
  - fetch
  - verification
  - budget proxies
  - state
  - synthesis


Mole

Agent / LLM
   |
   v
Research runtime
  - planner
  - executor
  - budget ledger
  - search / fetch
  - evidence store
  - quote verifier
  - claim graph
  - output validator
  - eval
```

## 1. Deterministic quote verification

### Omni-Research today

The program tells the agent to WebFetch a source, confirm the claim appears in the original page, cite it, and later run an anti-fabrication pass.

This is better than search-snippet citation, but the guarantee still depends on the model following instructions correctly.

A bad claim can therefore enter `research.md`, influence later cycles, and only be removed near the end.

### Mole

Mole requires each extracted claim to carry a source quote. Before the claim reaches storage, deterministic code checks whether the quote actually exists in the fetched source text. Exact matching is attempted first, with whitespace-normalized matching as a fallback.

If the quote cannot be located, the claim is rejected before it contaminates the evidence set.

Relevant implementation:

- `internal/actors/quote.go`
- `internal/actors/mine.go`

### Recommendation for Omni-Research

Add a structured evidence record:

```json
{
  "claim": "...",
  "source_url": "...",
  "quote": "...",
  "verified": true,
  "research_line": 2,
  "source_score": 4.5,
  "retrieved_at": "..."
}
```

Store these records in `evidence.jsonl`.

**Invariant:** only evidence whose quote can be found in the fetched source may be marked `verified: true` or promoted into `research.md` / `BRIEF.md`.

This should be the first reliability feature to implement.

## 2. Separate machine truth from rendered reports

### Omni-Research today

`research.md` currently acts as several things at once:

- working memory
- claim store
- source queue
- knowledge base
- human-readable report

`experiments.tsv` separately records cycle history.

This is convenient for a prompt-first prototype, but it makes validation, replay, querying, and cross-run learning harder.

### Mole

Mole persists structured state for sessions, sources/documents, claims, verification state, claim edges, tool calls, costs, fetch outcomes, and dataset rows. Human-readable output is rendered later from that state.

### Recommendation for Omni-Research

Do not jump directly to SQLite. A lightweight intermediate design is enough:

```text
program.md
sources.jsonl
 evidence.jsonl
experiments.tsv
      |
      v
research.md
      |
      v
BRIEF.md
```

Treat `sources.jsonl`, `evidence.jsonl`, and `experiments.tsv` as **machine truth**.

Treat `research.md` and `BRIEF.md` as **rendered views**.

This split unlocks deterministic validation without forcing Omni-Research to become a large runtime immediately.

## 3. Hard work budget instead of model self-monitoring

### Omni-Research today

The skill explicitly acknowledges that the background agent cannot directly measure its own token usage. It therefore uses proxies such as cycle count, file size, diminishing returns, and consecutive tool failures.

### Mole

Mole owns the provider calls, so it can enforce money or token ceilings using a reserve-before-dispatch / settle-after-call ledger. It also reserves output budget so research cannot consume everything before verification and synthesis.

Relevant implementation:

- `internal/budget/ledger.go`
- `internal/budget/estimator.go`

### Recommendation for Omni-Research

Claude Code subscription usage is not visible to the skill, so Omni should **not pretend to have an exact cost ledger**.

Instead introduce a deterministic work budget:

```text
max_cycles
max_searches
max_fetches
max_sources
max_wall_clock (when the runtime can observe it)
```

Also reserve work capacity by phase, for example:

```text
research       80%
verification   10%
synthesis      10%
```

If Omni later gains an API-engine mode, the same interface can be backed by a real token / dollar ledger.

## 4. Toolkit mode is a strong architectural fit

Mole has an autonomous mode where Mole owns the LLM calls, and a toolkit mode where the coding agent's model performs reasoning while Mole supplies deterministic tools such as search, fetch, quote verification, claim storage, citations, graph operations, and local-data aggregation.

Relevant implementation:

- `internal/mcpserver/toolkit.go`

This model fits Omni-Research especially well because Claude Code is already the brain and the research method already lives in a Skill.

Recommended target architecture:

```text
       Omni-Research Skill
        research strategy
              |
              v
          Claude Code
            reasoning
              |
              v MCP
       Omni Research Core
        deterministic tools
       /      |       \
   search    fetch   evidence
                      |
                 verify_quote
                      |
                  claim store
                      |
                  trace / eval
```

The Skill remains easy to iterate. The core becomes model-independent infrastructure.

## 5. Claim graph instead of model-authored confidence labels

### Omni-Research today

The report uses signals such as:

- `✓ sources agree`
- `~ mixed evidence`
- `✗ sources conflict`
- High / Medium / Low confidence

This is directionally correct, but the model is responsible for deciding and writing those labels.

### Mole

Mole stores relationships between claims and derives confidence from the resulting graph. It can represent support, contradiction, duplication, staleness, and unresolved comparisons as explicit state.

Relevant implementation:

- `internal/verifier/verifier.go`
- `internal/verifier/confidence.go`
- `internal/verifier/pairs.go`

### Recommendation for Omni-Research

Start small with an edge record:

```json
{
  "from": "claim-12",
  "to": "claim-03",
  "relation": "supports|contradicts|duplicates",
  "confidence": 0.84
}
```

Then derive report-level consensus from the graph instead of having the writer invent the label from memory.

This is a later phase than quote verification because pair adjudication itself still needs a model and has non-trivial cost.

## 6. Validate the synthesized output too

Verified evidence does not guarantee that the final LLM-authored report is valid.

Mole mechanically checks synthesized citation markers and can reject malformed or unsupported output, falling back to a simpler evidence listing rather than shipping a polished but untrustworthy answer.

Relevant implementation:

- `internal/output/validate.go`

### Recommendation for Omni-Research

Add a post-render validator for `BRIEF.md`:

- every citation target must exist in the evidence store
- every cited claim must be verified
- no unknown / fabricated source URL may appear
- every factual section must contain at least one citation when evidence exists
- malformed citation syntax should fail validation

If validation fails, generate a conservative evidence-first brief instead of retrying blindly.

## 7. Mechanical evaluation instead of LLM self-scoring

Mole's evaluation package intentionally computes metrics from persisted state without model calls. Metrics that cannot be measured are explicitly reported as unmeasured rather than receiving a model-generated score.

Relevant implementation:

- `internal/eval/scorecard.go`

Recommended first Omni metrics:

- citation integrity
- verified claims / total claims
- source concentration
- sources per research line
- searches / fetches / cycles
- failed fetch rate
- duplicate evidence rate
- contradiction count
- work-budget adherence

Later, add external benchmark quality metrics separately.

## What not to copy yet

Mole has a much larger runtime surface than Omni currently needs. Do **not** make these immediate requirements:

- rewrite in Go
- SQLite persistence
- own LLM-provider abstraction
- local-data SQL sandbox
- full daemon architecture
- complex contradiction verifier
- academic actor parity all at once

Those are useful when the deterministic core proves valuable, but they would slow down the current Skill-first product unnecessarily.

## Recommended implementation sequence

### P0 — Reliability foundation

1. Structured `evidence.jsonl`
2. deterministic `verify_quote`
3. `BRIEF.md` citation/output validator
4. hard work budget (`search`, `fetch`, `source`, `cycle` ceilings)

### P1 — Research Core

5. Extract search/fetch/evidence helpers into an Omni Research Core
6. expose deterministic helpers over MCP
7. keep Claude Code + Skill as the reasoning layer

### P2 — Evidence intelligence

8. claim relation graph
9. derived consensus / conflict labels
10. mechanical eval scorecard

### P3 — Scale and portability

11. parallel research lines with shared budget
12. provider-specific retrievers / academic APIs
13. optional API-engine mode with real token / USD accounting
14. cross-agent compatibility

## Design principle going forward

A useful rule for deciding whether a feature belongs in `program-template.md` or in code:

> If failure means "the agent made a judgement we disagree with," it can stay in the prompt.
>
> If failure means "the system violated a rule we promised," move it into deterministic code.

Examples:

- Which research line should we explore next? → **prompt / model**
- Is this source authoritative enough? → **prompt / model + metadata**
- Does this quote literally exist in the source? → **code**
- Have we exceeded the maximum number of fetches? → **code**
- Does citation 17 point to a real stored source? → **code**
- Which conflicting evidence matters most to the conclusion? → **prompt / model**

# Omni-Research TODO

Roadmap of future work, organized by priority.

The reliability priorities below were updated after studying [lajosdeme/mole](https://github.com/lajosdeme/mole). See [`docs/research/mole-comparison.md`](docs/research/mole-comparison.md) for the architecture comparison and rationale.

Core principle:

> Prompt owns reasoning. Code owns invariants.

---

## P0 — Evidence & Reliability Foundation

These are the highest-leverage improvements because they turn instructions the model is merely asked to follow into guarantees the runtime can enforce.

- [ ] **Structured evidence store** — add `evidence.jsonl` with claim, source URL, verbatim quote, research line, source score, retrieval time, and verification state
- [ ] **Deterministic quote verification** — a claim may become verified only when its quote can be located in the fetched source text (exact or whitespace-normalized match)
- [ ] **Evidence-only rendering contract** — `research.md` and `BRIEF.md` may cite only verified evidence records
- [ ] **BRIEF output validator** — reject unknown citation targets, unverified claims, fabricated URLs, and malformed citation syntax; fall back to a conservative evidence listing when synthesis fails validation
- [ ] **Hard work budget** — track and enforce max cycles, searches, fetches, sources, and later wall-clock independently of model self-reporting
- [ ] **Reserve work for completion** — keep explicit capacity for final verification and synthesis instead of allowing research cycles to consume the entire run
- [ ] **Machine truth vs rendered views** — move source/evidence state out of `research.md`; treat Markdown outputs as renderings of structured state

## P1 — Omni Research Core / MCP

Keep Claude Code + the Skill as the reasoning layer, while moving deterministic research infrastructure into reusable tools.

- [ ] **Omni Research Core** — extract search, fetch, evidence verification, state, budget, and validation helpers into a small runtime module
- [ ] **MCP toolkit surface** — expose deterministic primitives such as `search`, `fetch`, `verify_quote`, `claim_add`, `claims_list`, `citations`, and budget/status tools
- [ ] **Claude subscription / toolkit mode** — Claude Code performs reasoning using subscription tokens while Omni Core provides deterministic infrastructure
- [ ] **Search/fetch adapters** — make retrieval providers swappable without changing the research strategy prompt
- [ ] **Structured trace** — persist tool calls, fetch outcomes, evidence counts, stop reason, and budget usage for replay/debugging
- [ ] **Cross-agent compatibility** — make the Skill + Core usable from Codex CLI and Gemini CLI where MCP/tool contracts allow it

## P2 — Evidence Intelligence & Retrieval

- [ ] **Claim relation graph** — represent `supports`, `contradicts`, and `duplicates` relationships explicitly instead of relying on report prose
- [ ] **Derived confidence/consensus** — generate ✓ / ~ / ✗ and High/Medium/Low signals from evidence relationships rather than model memory alone
- [ ] **Cross-model review via MCP** — optional second-LLM scoring/adjudication where an additional judgement is actually useful (ARIS pattern)
- [ ] **Retriever strategy per topic type** — product → competitor sites + Product Hunt; research → academic sources; marketing → communities + first-party campaign sources (GPT-Researcher pattern)
- [ ] **Academic source APIs** — arXiv, OpenAlex/Crossref, Semantic Scholar, PubMed direct integration for research-type topics
- [ ] **Citation graph traversal** — find papers citing/cited by known good sources
- [ ] **Parallel sub-agents per research line** — fan out independent retrieval while sharing a global work budget (GPT-Researcher pattern)
- [ ] **Cross-run learning** — save structured lessons per session and load relevant lessons for similar future topics (AutoResearchClaw/MetaClaw pattern)
- [ ] **Tone/depth parameter** during setup — "executive summary" vs "technical deep-dive" varies output and research strategy

## P3 — Distribution

- [ ] Submit to official Anthropic marketplace — https://claude.ai/settings/plugins/submit
- [ ] List on [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)
- [ ] List on [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills)
- [ ] List on [alvinunreal/awesome-autoresearch](https://github.com/alvinunreal/awesome-autoresearch)
- [ ] List on [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [ ] Post launch announcement on r/ClaudeAI with Test 3 BRIEF as demo
- [ ] Add GitHub repo topics: `claude-code-plugin`, `research-agent`, `deep-research`, `autonomous-agent`
- [ ] Add example BRIEF output to README (use Test 3 prompt engineering output as showcase)

## P4 — Quality, Testing & Evaluation

- [ ] Run remaining manual tests from `tests/TEST-PLAYBOOK.md` before next release:
  - [ ] Test 1: First-run config setup (clean environment)
  - [ ] Test 4: Mid-run steering (edit steer.md during live run)
  - [ ] Test 6a-e: Edge cases (vague topic, type override, empty seeds, multi-URL seeds, non-English)
  - [ ] Test 7: Clean plugin install from marketplace
- [ ] Add CI workflow to run `tests/validate-structure.sh` on every PR
- [ ] Add integration test that runs a minimal quick-scope research in CI (~5 min, using cached fixtures)
- [ ] **Mechanical eval scorecard** — citation integrity, verified/total claims, source concentration, sources per line, fetch failure rate, duplicate evidence rate, contradiction count, and budget adherence
- [ ] **Self-evaluation score** only for metrics that require judgement; explicitly label unmeasured metrics instead of inventing a score (MiroThinker/Mole pattern)
- [ ] Benchmark Omni-Research against BrowseComp or SimpleQA to get an external quality score
- [ ] Build a small labelled contradiction/support corpus before optimizing claim-graph adjudication
- [ ] Investigate ARIS reliability pain points (issue #74: LLM drift after N cycles) and how to defend against them
- [ ] Measure actual observable work per cycle; add token/USD accounting only when running through an API path that exposes usage
- [ ] Survey users on what topic types they actually research (validate the product/marketing/production/research taxonomy)

## P5 — Polish & Nice-to-Have

- [ ] **HTML/PDF export** for shareable reports
- [ ] **Notification hook** on research completion (webhook, email, or Feishu-style mobile push)
- [ ] **Dataset mode** — structured row collection with provenance and contested-value handling
- [ ] Optional API-engine mode with provider abstraction and exact token/USD budget enforcement

## Release / Versioning

Published versions use GitHub Releases with strict `vX.Y.Z` tags.

- `.claude-plugin/plugin.json` contains the plugin version
- `.claude-plugin/marketplace.json` mirrors the same version in both metadata and plugin entry
- `python3 scripts/set-version.py X.Y.Z` updates all manifest copies
- `.github/workflows/release.yml` publishes the GitHub Release only when the release version matches all manifest copies
- `scripts/check-release-version.sh vX.Y.Z` is the consistency guard used by release automation

The **GitHub Release tag is the published version boundary**; manifest versions are validated mirrors and must already be merged before publishing the release.

## Done

- [x] Version/release consistency tooling and GitHub Release workflow — this branch
- [x] Mole architecture comparison + staged deterministic-runtime roadmap — this branch
- [x] 3-phase research method (Phase 0 source scouting → Phase 1 seed mining → Phase 2 hypothesis loop) — [c543d0d](https://github.com/romanticamaj/omni-research/commit/c543d0d)
- [x] Mid-run steering via `steer.md` — [c543d0d](https://github.com/romanticamaj/omni-research/commit/c543d0d)
- [x] Inline citations in report body — [c543d0d](https://github.com/romanticamaj/omni-research/commit/c543d0d)
- [x] Confidence/consensus signals (✓/~/✗ and 🟢/🟡/🔴) — [c543d0d](https://github.com/romanticamaj/omni-research/commit/c543d0d)
- [x] Source scoring (1-5 on authority/recency/relevance) — [c543d0d](https://github.com/romanticamaj/omni-research/commit/c543d0d)
- [x] PIVOT/REFINE gates every 4th cycle — [c543d0d](https://github.com/romanticamaj/omni-research/commit/c543d0d)
- [x] Anti-fabrication final WebFetch pass — [c543d0d](https://github.com/romanticamaj/omni-research/commit/c543d0d)
- [x] Plugin conversion with `.claude-plugin/plugin.json` manifest — [6f6b13b](https://github.com/romanticamaj/omni-research/commit/6f6b13b)
- [x] Static validation test suite (65 checks) — [7b59064](https://github.com/romanticamaj/omni-research/commit/7b59064)
- [x] Setup flow simulation + agent output validators (57 checks) — [e9226b3](https://github.com/romanticamaj/omni-research/commit/e9226b3)
- [x] Test playbook with 7 manual test procedures — [7b59064](https://github.com/romanticamaj/omni-research/commit/7b59064)

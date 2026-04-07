# Omni-Research TODO

Roadmap of future work, organized by priority. Items are checked off as they ship.

---

## P0 — Distribution (biggest unlock, minimal code)

- [ ] Submit to official Anthropic marketplace — https://claude.ai/settings/plugins/submit
- [ ] List on [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)
- [ ] List on [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills)
- [ ] List on [alvinunreal/awesome-autoresearch](https://github.com/alvinunreal/awesome-autoresearch)
- [ ] List on [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [ ] Post launch announcement on r/ClaudeAI with Test 3 BRIEF as demo
- [ ] Add GitHub repo topics: `claude-code-plugin`, `research-agent`, `deep-research`, `autonomous-agent`
- [ ] Add example BRIEF output to README (use Test 3 prompt engineering output as showcase)

## P1 — Feature Parity (close competitive gaps)

- [ ] **Cross-model review via MCP** — optional second-LLM scoring of BRIEF before delivery (ARIS pattern)
- [ ] **Retriever strategy per topic type** — product → competitor sites + Product Hunt; research → arXiv + Scholar (GPT-Researcher pattern)
- [ ] **Cross-run learning** — save `lessons.md` per session, load for similar future topics (AutoResearchClaw MetaClaw pattern)
- [ ] **Parallel sub-agents per research line** — fan out WebSearch calls instead of sequential looping (GPT-Researcher pattern)
- [ ] **Tone/depth parameter** during setup — "executive summary" vs "technical deep-dive" vary prompt template

## P2 — Quality & Testing

- [ ] Run remaining manual tests from `tests/TEST-PLAYBOOK.md` before next release:
  - [ ] Test 1: First-run config setup (clean environment)
  - [ ] Test 4: Mid-run steering (edit steer.md during live run)
  - [ ] Test 6a-e: Edge cases (vague topic, type override, empty seeds, multi-URL seeds, non-English)
  - [ ] Test 7: Clean plugin install from marketplace
- [ ] Add CI workflow to run `tests/validate-structure.sh` on every PR
- [ ] Add integration test that runs a minimal quick-scope research in CI (~5 min, using cached fixtures)

## P3 — Polish & Nice-to-Have

- [ ] **HTML/PDF export** for shareable reports
- [ ] **Notification hook** on research completion (webhook, email, or Feishu-style mobile push)
- [ ] **Self-evaluation score** on final BRIEF (MiroThinker pattern)
- [ ] **Cross-agent compatibility** — make SKILL.md work with Codex CLI and Gemini CLI
- [ ] **Academic source APIs** — arXiv, Semantic Scholar, PubMed direct integration for research-type topics
- [ ] **Citation graph traversal** in source scouting — find papers citing/cited by known good sources

## P4 — Research & Exploration

- [ ] Investigate ARIS's reliability pain points (issue #74: LLM drift after N cycles) and how to defend against them
- [ ] Measure actual token consumption per cycle and add a cost estimator to setup flow
- [ ] Benchmark Omni-Research against BrowseComp or SimpleQA to get a quality score
- [ ] Survey users on what topic types they actually research (validate the product/marketing/production/research taxonomy)

## Done

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

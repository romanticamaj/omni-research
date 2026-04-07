# Changelog

## 2.0.2 — 2026-04-07

### Fixed
- Added required `type` and `title` fields to `userConfig.output_base_dir` in `plugin.json`.
  Without these, `/plugin install` failed with "Invalid option: expected one of string/number/boolean/directory/file"
  and "title: expected string, received undefined". The runtime validator is stricter than the documented schema.

### Added
- `tests/validate-structure.sh` now checks `userConfig` entries for required `type`, `title`, `description`
  fields and validates that `type` is one of the 5 allowed enum values (77 total checks, all passing).

## 2.0.1 — 2026-04-07

### Fixed
- Added `.claude-plugin/marketplace.json` so the repo works as a self-hosted marketplace.
  Previously `/plugin marketplace add romanticamaj/omni-research` failed with "marketplace.json not found"
  because Claude Code's `marketplace add` command requires a marketplace manifest, not a plugin manifest.
- Updated README install instructions to include `@omni-research-marketplace` suffix.

### Added
- Test suite now validates `marketplace.json` structure and checks version sync between
  `plugin.json` and `marketplace.json`.

## 2.0.0 — 2026-04-02

**Plugin conversion** — omni-research is now a Claude Code plugin with versioning, auto-updates, and marketplace distribution.

### New Features
- **Mid-run steering** — edit `steer.md` to redirect the agent while it runs
- **Inline citations** — every claim uses `[text](url)` format in the report body
- **Confidence signals** — consensus markers (agree/mixed/conflict) and confidence levels (High/Medium/Low) in BRIEF
- **Source scoring** — sources rated 1-5 on authority, recency, and relevance
- **PIVOT/REFINE gates** — every 4 cycles the agent evaluates and can change direction
- **Anti-fabrication pass** — final sweep verifies all citation URLs before publishing
- **Troubleshooting section** in README

### Improvements
- BRIEF templates now translate section headers to match research language
- Source Queue table includes scoring columns
- experiments.tsv includes `gate_decision` column
- Phase 1 has explicit per-source cycle structure with dead URL handling
- Cycle budget is explicit (Phase 0/1/2 all count toward max)
- Source discovery (every 5th cycle) and PIVOT/REFINE (every 4th) are offset to avoid collision
- Added `.gitignore` for config.json

### Breaking Changes
- Directory structure changed from flat to plugin format (`skills/omni-research/`)
- Config now stored in `${CLAUDE_PLUGIN_DATA}/config.json` instead of skill directory
- File references use `${CLAUDE_SKILL_DIR}` instead of hardcoded paths

## 1.1.0 — 2026-03-30

- Added 3-phase research method: source scouting, seed mining, hypothesis loop
- Source Queue with curated list discovery
- Phase 0 mandatory source scouting before hypothesis research

## 1.0.0 — 2026-03-30

- Initial release: autonomous research agent skill for Claude Code
- 4 research types with tailored BRIEF templates
- Interactive setup flow
- Background agent with saturation detection

# Evidence Layer

Omni-Research is moving factual reliability out of prompt-only instructions and into deterministic tooling.

The first invariant is simple:

> A factual claim is not verified until a verbatim supporting quote can be found in the source text.

## Evidence record

Each verification attempt is appended to `evidence.jsonl` as a JSON object:

```json
{
  "id": "ev_0123456789abcdef",
  "claim": "A factual claim written by the research agent.",
  "source_url": "https://example.com/source",
  "quote": "A verbatim span copied from the source that directly supports the claim.",
  "research_line": "2",
  "source_score": 4.3,
  "retrieved_at": "2026-08-17T01:00:00+00:00",
  "verification": {
    "verified": true,
    "method": "direct_fetch:exact"
  }
}
```

The evidence ID is a deterministic SHA-256-derived identifier over `source_url + claim + quote`. This makes accidental or manual mutation detectable by the validator.

## Verify a claim

```bash
python3 scripts/evidence.py verify \
  --claim "The claim to verify" \
  --source-url "https://example.com/source" \
  --quote "A sufficiently long verbatim quote copied from that source." \
  --research-line "2" \
  --source-score 4.3 \
  --output ./evidence.jsonl
```

Verification behavior:

1. fetch the source independently of the model
2. reject non-public / localhost source targets
3. extract text from HTML
4. try exact quote matching
5. fall back to whitespace-normalized quote matching
6. append the verification attempt to `evidence.jsonl`
7. exit `0` only when the quote is verified

A missing quote is still persisted with `verification.verified=false` for auditability and returns exit code `2`.

`--source-file` is available for offline fixtures and tests. Production research should prefer direct URL verification so the check is independent of model-generated text.

## Validate the store

```bash
python3 scripts/evidence.py validate --input ./evidence.jsonl
```

The validator checks required fields, score bounds, verification state shape, and evidence ID integrity.

## Rendering contract

This PR establishes the deterministic evidence primitive. The next integration step is to make the Skill enforce this rendering contract:

- `research.md` and `BRIEF.md` are rendered views, not sources of truth
- every factual claim must reference a verified evidence record
- unverified evidence may remain in `evidence.jsonl` for audit/debugging but must not appear as a factual assertion in rendered output
- the final BRIEF validator must reject citations that cannot be mapped to verified evidence

That integration is intentionally separate from the verifier itself so the mechanical primitive can be tested independently before changing the autonomous research loop.

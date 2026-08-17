#!/usr/bin/env python3
"""Deterministic evidence verification for Omni-Research.

A factual claim becomes renderable only after a verbatim supporting quote can be
located in independently fetched source text. Verification uses exact matching
first, then whitespace-normalized matching.

The command appends every verification attempt to evidence.jsonl for auditability.
Only records with verification.verified=true may be rendered into research.md or
BRIEF.md.
"""

from __future__ import annotations

import argparse
import hashlib
import ipaddress
import json
import socket
import sys
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from typing import Iterable
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener

MAX_FETCH_BYTES = 2 * 1024 * 1024
DEFAULT_TIMEOUT_SECONDS = 20
USER_AGENT = "omni-research-evidence/1.0"


class TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []

    def handle_data(self, data: str) -> None:
        if data.strip():
            self.parts.append(data)

    def text(self) -> str:
        return "\n".join(self.parts)


def normalize_whitespace(value: str) -> str:
    return " ".join(value.split())


def match_quote(source_text: str, quote: str) -> tuple[bool, str]:
    if quote in source_text:
        return True, "exact"
    if normalize_whitespace(quote) in normalize_whitespace(source_text):
        return True, "whitespace_normalized"
    return False, "not_found"


def _addresses_for_host(hostname: str) -> Iterable[ipaddress._BaseAddress]:
    try:
        for item in socket.getaddrinfo(hostname, None):
            raw = item[4][0]
            yield ipaddress.ip_address(raw)
    except socket.gaierror as exc:
        raise ValueError(f"could not resolve host: {hostname}") from exc


def assert_public_url(url: str) -> None:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise ValueError("source URL must use http or https")
    if not parsed.hostname:
        raise ValueError("source URL must include a hostname")
    if parsed.username or parsed.password:
        raise ValueError("source URL must not contain credentials")
    if parsed.hostname.lower() == "localhost":
        raise ValueError("localhost is not an allowed source")

    try:
        literal_ip = ipaddress.ip_address(parsed.hostname)
        addresses = [literal_ip]
    except ValueError:
        addresses = list(_addresses_for_host(parsed.hostname))

    if not addresses:
        raise ValueError(f"source host resolved to no addresses: {parsed.hostname}")

    for address in addresses:
        if not address.is_global:
            raise ValueError(f"source host resolves to non-public address: {address}")


class SafeRedirectHandler(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        assert_public_url(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def fetch_source_text(url: str, timeout: int = DEFAULT_TIMEOUT_SECONDS) -> str:
    assert_public_url(url)
    request = Request(url, headers={"User-Agent": USER_AGENT, "Accept": "text/html,text/plain,*/*;q=0.1"})
    opener = build_opener(SafeRedirectHandler())

    with opener.open(request, timeout=timeout) as response:
        final_url = response.geturl()
        assert_public_url(final_url)
        payload = response.read(MAX_FETCH_BYTES + 1)
        if len(payload) > MAX_FETCH_BYTES:
            raise ValueError(f"source exceeds {MAX_FETCH_BYTES} byte verification limit")

        charset = response.headers.get_content_charset() or "utf-8"
        decoded = payload.decode(charset, errors="replace")
        content_type = response.headers.get_content_type()

    if content_type in {"text/html", "application/xhtml+xml"} or "<html" in decoded[:500].lower():
        parser = TextExtractor()
        parser.feed(decoded)
        return parser.text()

    return decoded


def evidence_id(source_url: str, claim: str, quote: str) -> str:
    payload = "\n".join((source_url, claim, quote)).encode("utf-8")
    return "ev_" + hashlib.sha256(payload).hexdigest()[:16]


def append_jsonl(path: Path, record: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8", newline="\n") as handle:
        handle.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")


def build_record(args: argparse.Namespace, verified: bool, method: str, error: str | None = None) -> dict:
    record = {
        "id": evidence_id(args.source_url, args.claim, args.quote),
        "claim": args.claim,
        "source_url": args.source_url,
        "quote": args.quote,
        "research_line": args.research_line,
        "source_score": args.source_score,
        "retrieved_at": args.retrieved_at or datetime.now(timezone.utc).isoformat(),
        "verification": {
            "verified": verified,
            "method": method,
        },
    }
    if error:
        record["verification"]["error"] = error
    return record


def cmd_verify(args: argparse.Namespace) -> int:
    if not 1 <= args.source_score <= 5:
        print("ERROR: source-score must be between 1 and 5", file=sys.stderr)
        return 1
    if len(normalize_whitespace(args.quote)) < 24:
        print("ERROR: quote must contain at least 24 non-whitespace-normalized characters", file=sys.stderr)
        return 1

    try:
        if args.source_file:
            source_text = Path(args.source_file).read_text(encoding="utf-8")
            source_mode = "source_file"
        else:
            source_text = fetch_source_text(args.source_url, timeout=args.timeout)
            source_mode = "direct_fetch"
    except (OSError, ValueError, HTTPError, URLError) as exc:
        record = build_record(args, False, "fetch_error", str(exc))
        append_jsonl(Path(args.output), record)
        print(json.dumps(record, ensure_ascii=False))
        return 1

    verified, method = match_quote(source_text, args.quote)
    record = build_record(args, verified, f"{source_mode}:{method}")
    append_jsonl(Path(args.output), record)
    print(json.dumps(record, ensure_ascii=False))
    return 0 if verified else 2


REQUIRED_FIELDS = {
    "id",
    "claim",
    "source_url",
    "quote",
    "research_line",
    "source_score",
    "retrieved_at",
    "verification",
}


def validate_record(record: dict, line_number: int) -> list[str]:
    errors: list[str] = []
    missing = REQUIRED_FIELDS - set(record)
    if missing:
        errors.append(f"line {line_number}: missing fields: {', '.join(sorted(missing))}")
        return errors

    if not isinstance(record["verification"], dict) or not isinstance(record["verification"].get("verified"), bool):
        errors.append(f"line {line_number}: verification.verified must be boolean")
    if not isinstance(record["quote"], str) or not record["quote"].strip():
        errors.append(f"line {line_number}: quote must be a non-empty string")
    if not isinstance(record["claim"], str) or not record["claim"].strip():
        errors.append(f"line {line_number}: claim must be a non-empty string")
    if not isinstance(record["source_url"], str) or not record["source_url"].strip():
        errors.append(f"line {line_number}: source_url must be a non-empty string")
    if not isinstance(record["source_score"], (int, float)) or not 1 <= record["source_score"] <= 5:
        errors.append(f"line {line_number}: source_score must be between 1 and 5")

    expected_id = evidence_id(record["source_url"], record["claim"], record["quote"])
    if record["id"] != expected_id:
        errors.append(f"line {line_number}: evidence id does not match record content")
    return errors


def cmd_validate(args: argparse.Namespace) -> int:
    path = Path(args.input)
    if not path.exists():
        print(f"ERROR: evidence store not found: {path}", file=sys.stderr)
        return 1

    errors: list[str] = []
    total = 0
    verified = 0
    with path.open("r", encoding="utf-8") as handle:
        for line_number, raw in enumerate(handle, start=1):
            if not raw.strip():
                continue
            total += 1
            try:
                record = json.loads(raw)
            except json.JSONDecodeError as exc:
                errors.append(f"line {line_number}: invalid JSON: {exc}")
                continue
            errors.extend(validate_record(record, line_number))
            if isinstance(record.get("verification"), dict) and record["verification"].get("verified") is True:
                verified += 1

    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        print(f"INVALID: {len(errors)} error(s), {total} record(s)", file=sys.stderr)
        return 1

    print(f"VALID: {total} record(s), {verified} verified")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Verify and validate Omni-Research evidence")
    subparsers = parser.add_subparsers(dest="command", required=True)

    verify = subparsers.add_parser("verify", help="verify a quote and append an evidence record")
    verify.add_argument("--claim", required=True)
    verify.add_argument("--source-url", required=True)
    verify.add_argument("--quote", required=True)
    verify.add_argument("--research-line", required=True)
    verify.add_argument("--source-score", required=True, type=float)
    verify.add_argument("--output", required=True)
    verify.add_argument("--retrieved-at")
    verify.add_argument("--source-file", help="test/offline mode: verify against local source text instead of fetching URL")
    verify.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT_SECONDS)
    verify.set_defaults(func=cmd_verify)

    validate = subparsers.add_parser("validate", help="validate an evidence.jsonl store")
    validate.add_argument("--input", required=True)
    validate.set_defaults(func=cmd_validate)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())

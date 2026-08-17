import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "scripts" / "evidence.py"


class EvidenceCliTests(unittest.TestCase):
    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            text=True,
            capture_output=True,
            check=False,
        )

    def base_args(self, source_file, output_file, quote):
        return (
            "verify",
            "--claim", "Omni-Research uses deterministic quote verification.",
            "--source-url", "https://example.com/source",
            "--quote", quote,
            "--research-line", "1",
            "--source-score", "4",
            "--source-file", str(source_file),
            "--output", str(output_file),
            "--retrieved-at", "2026-08-17T00:00:00+00:00",
        )

    def test_exact_quote_verifies_and_is_persisted(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "source.txt"
            output = root / "evidence.jsonl"
            quote = "Deterministic quote verification protects the evidence layer from fabricated support."
            source.write_text(f"Header\n{quote}\nFooter", encoding="utf-8")

            result = self.run_cli(*self.base_args(source, output, quote))

            self.assertEqual(result.returncode, 0, result.stderr)
            record = json.loads(output.read_text(encoding="utf-8"))
            self.assertTrue(record["verification"]["verified"])
            self.assertEqual(record["verification"]["method"], "source_file:exact")
            self.assertTrue(record["id"].startswith("ev_"))

    def test_whitespace_normalized_quote_verifies(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "source.txt"
            output = root / "evidence.jsonl"
            source.write_text(
                "A deterministic quote\nverification check tolerates   whitespace but not changed words.",
                encoding="utf-8",
            )
            quote = "A deterministic quote verification check tolerates whitespace but not changed words."

            result = self.run_cli(*self.base_args(source, output, quote))

            self.assertEqual(result.returncode, 0, result.stderr)
            record = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(record["verification"]["method"], "source_file:whitespace_normalized")

    def test_missing_quote_is_rejected_but_audited(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "source.txt"
            output = root / "evidence.jsonl"
            source.write_text("This source says something completely different.", encoding="utf-8")
            quote = "This sufficiently long supporting quote does not actually appear in the source."

            result = self.run_cli(*self.base_args(source, output, quote))

            self.assertEqual(result.returncode, 2)
            record = json.loads(output.read_text(encoding="utf-8"))
            self.assertFalse(record["verification"]["verified"])
            self.assertEqual(record["verification"]["method"], "source_file:not_found")

    def test_validate_accepts_valid_store_and_rejects_tampering(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "source.txt"
            output = root / "evidence.jsonl"
            quote = "This is a sufficiently long quote that exists in the local source fixture."
            source.write_text(quote, encoding="utf-8")

            verified = self.run_cli(*self.base_args(source, output, quote))
            self.assertEqual(verified.returncode, 0, verified.stderr)

            valid = self.run_cli("validate", "--input", str(output))
            self.assertEqual(valid.returncode, 0, valid.stderr)

            record = json.loads(output.read_text(encoding="utf-8"))
            record["id"] = "ev_tampered"
            output.write_text(json.dumps(record) + "\n", encoding="utf-8")

            invalid = self.run_cli("validate", "--input", str(output))
            self.assertEqual(invalid.returncode, 1)
            self.assertIn("evidence id does not match", invalid.stderr)


if __name__ == "__main__":
    unittest.main()

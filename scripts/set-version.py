#!/usr/bin/env python3
import argparse
import json
import pathlib
import re
import sys

SEMVER = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
ROOT = pathlib.Path(__file__).resolve().parents[1]
PLUGIN = ROOT / ".claude-plugin" / "plugin.json"
MARKETPLACE = ROOT / ".claude-plugin" / "marketplace.json"


def load(path: pathlib.Path):
    return json.loads(path.read_text())


def write(path: pathlib.Path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update every Omni-Research manifest version before publishing a GitHub Release."
    )
    parser.add_argument("version", help="strict semantic version, e.g. 2.1.0")
    args = parser.parse_args()

    if not SEMVER.fullmatch(args.version):
        print(f"version must be strict X.Y.Z semver; got {args.version!r}", file=sys.stderr)
        return 2

    plugin = load(PLUGIN)
    marketplace = load(MARKETPLACE)

    plugin["version"] = args.version
    marketplace["metadata"]["version"] = args.version
    marketplace["plugins"][0]["version"] = args.version

    write(PLUGIN, plugin)
    write(MARKETPLACE, marketplace)

    print(f"updated Omni-Research version metadata to {args.version}")
    print(f"next: commit these files, merge to master, then publish GitHub Release v{args.version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

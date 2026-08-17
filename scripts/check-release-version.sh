#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:-${GITHUB_REF_NAME:-}}"

if [[ -z "$TAG" ]]; then
  echo "usage: $0 vX.Y.Z" >&2
  exit 2
fi

if [[ ! "$TAG" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "release tag must be strict semver in vX.Y.Z form; got '$TAG'" >&2
  exit 1
fi

VERSION="${TAG#v}"

readarray -t VERSIONS < <(python3 - "$REPO_ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
plugin = json.loads((root / ".claude-plugin" / "plugin.json").read_text())
marketplace = json.loads((root / ".claude-plugin" / "marketplace.json").read_text())

print(plugin["version"])
print(marketplace["metadata"]["version"])
print(marketplace["plugins"][0]["version"])
PY
)

PLUGIN_VERSION="${VERSIONS[0]}"
MARKETPLACE_META_VERSION="${VERSIONS[1]}"
MARKETPLACE_PLUGIN_VERSION="${VERSIONS[2]}"

FAIL=0

check_equal() {
  local label="$1"
  local actual="$2"
  if [[ "$actual" != "$VERSION" ]]; then
    echo "version mismatch: release=$VERSION, $label=$actual" >&2
    FAIL=1
  fi
}

check_equal "plugin.json" "$PLUGIN_VERSION"
check_equal "marketplace metadata" "$MARKETPLACE_META_VERSION"
check_equal "marketplace plugin" "$MARKETPLACE_PLUGIN_VERSION"

if [[ "$FAIL" -ne 0 ]]; then
  echo "update repository version metadata before publishing release $TAG" >&2
  exit 1
fi

echo "release version OK: $TAG"

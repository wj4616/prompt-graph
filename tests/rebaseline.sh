#!/usr/bin/env bash
# Per-minor-version baseline capture. Refuses to overwrite existing baselines —
# they are the invariant proof for their version and must be immutable.
#
# Usage:
#   ./rebaseline.sh v2.1
# Captures current static-mode output to tests/fixtures/regression/v2.1-full-output.txt
# with sha256 sidecar. Exits 1 if the file already exists.
#
# See docs/regression-policy.md for policy details.
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <version-tag, e.g. v2.1>"
  exit 2
fi
VERSION="$1"

# Validate version tag shape: v<major>.<minor> only (no patch — patches share baseline)
if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: version tag must be vMAJOR.MINOR (e.g. v2.1); got '$VERSION'"
  exit 2
fi

REGRESSION_DIR="$(dirname "$(realpath "$0")")/fixtures/regression"
mkdir -p "$REGRESSION_DIR"
TARGET="$REGRESSION_DIR/$VERSION-full-output.txt"
SHA="$REGRESSION_DIR/$VERSION-full-output.sha256"

if [ -e "$TARGET" ]; then
  echo "ERROR: baseline $TARGET already exists — refusing to overwrite."
  echo "Per docs/regression-policy.md, baselines are immutable once captured."
  echo "If you really need to re-capture (e.g., the original was corrupted),"
  echo "  manually delete the file first and re-run."
  exit 1
fi

SMOKE="$(dirname "$(realpath "$0")")/run-smoke-tests.sh"
if [ ! -x "$SMOKE" ]; then
  echo "ERROR: smoke runner $SMOKE not found or not executable"
  exit 1
fi

echo "Capturing $VERSION baseline to $TARGET"
"$SMOKE" --static > "$TARGET" 2>&1
sha256sum "$TARGET" > "$SHA"
echo "Baseline captured. SHA-256:"
cat "$SHA"

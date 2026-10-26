#!/usr/bin/env bash
# The 7.02 gate. Downports a scratch copy of src/ in build/702 and checks it
# with the v702 syntax - src/ itself is never rewritten.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
build="$root/build/702"

rm -rf "$build"
mkdir -p "$build"
cp -r "$root/src" "$build/src"
cp "$root/.github/abaplint/abap_702.jsonc" "$build/abaplint.jsonc"

cd "$build"
# --fix exits non-zero while findings remain; the check below decides
npx abaplint --fix abaplint.jsonc > /dev/null 2>&1 || true
npx abaplint abaplint.jsonc

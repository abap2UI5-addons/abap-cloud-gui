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
# what auto_downport publishes: `npm run syfixes` turns the downport's
# RAISE EXCEPTION TYPE cx_sy_itab_line_not_found into ASSERT 1 = 0. From
# abaplint 2.120.120 on the check reports that RAISE in a method with classic
# EXCEPTIONS (the stand-ins of z2ui5_cl_cgui_frontend and _html_viewer) - the
# published branch never has it, so the gate checks the same code
find src -type f -name '*.abap' -exec sed -i -e 's/ RAISE EXCEPTION TYPE cx_sy_itab_line_not_found/ ASSERT 1 = 0/g' {} +
npx abaplint abaplint.jsonc

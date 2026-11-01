// Every generated class must compile: the corpus is converted and linted in
// a scratch copy of this repository with its own abaplint configs, so that
// check_syntax resolves z2ui5_cl_cgui_report, the selection screen, the list
// and the ALV against the pinned abap2UI5 release.
//
// - v750 (abaplint.jsonc, every rule of the repository): no finding in a
//   generated class. The flight tables of the corpus exist on premise;
//   test/ddic has stubs.
// - ABAP Cloud (.github/abaplint/abap_cloud.jsonc): no finding in a class of
//   the test set src/03 (CLOUD_READY of corpus.mjs). The others read the
//   flight tables or call APIs ABAP Cloud lacks - the converter copies the
//   logic of a report as it is, that part is the user's.
//
// - v702 (.github/abaplint/abap_702.jsonc, the gate of check-702.sh): the
//   copy is downported with abaplint --fix, then checked with the 7.02 syntax
//   - no finding in a generated class.
// - the abap2UI5 linter (abap2ui5lint.jsonc, UI5 1.71) with --all-classes:
//   no finding in a generated class.
//
// Findings in src/ itself are the business of the repository's own gates
// (npm run check) - they are reported as a diagnostic, not as a failure, so
// that this test answers one question: do the generated classes compile
// against src/01 as it is.
//
// abaplint clones the dependencies of the configs, the 7.02 gate the popups
// (git, network).
import { test } from "node:test";
import assert from "node:assert/strict";
import { lint, lintUi5 } from "../lib/gate.mjs";
import { corpus, convertEntry, DDIC, inTestSet } from "./corpus.mjs";

const converted = corpus().map((e) => ({ e, ...convertEntry(e) })).filter((c) => c.result.ok);
const files = Object.assign({}, ...converted.map((c) => c.result.files));
const fmt = (list) => list.map((i) => `${i.file}:${i.row}:${i.col} [${i.key}] ${i.message}`).join("\n");

test("every report but the refused one converts", () => {
  assert.ok(converted.length >= 9, `${converted.length} converted`);
});

/** the findings of the repository's own sources - npm run check's business */
const repositoryFindings = (t, r) => {
  const outside = r.issues.filter((i) => !i.file.startsWith("src/r2c/"));
  if (outside.length) t.diagnostic(`${outside.length} finding(s) in the repository's own sources (npm run check), not in a generated class`);
};

test("abaplint v750 with the repository's rules: no finding in any generated class", { timeout: 300000 }, (t) => {
  const r = lint({ files, target: "v750", ddic: DDIC });
  repositoryFindings(t, r);
  assert.equal(r.generated.length, 0, fmt(r.generated));
});

test("abaplint ABAP Cloud: every class of the test set src/03 is clean", { timeout: 300000 }, (t) => {
  const r = lint({ files, target: "cloud" });
  repositoryFindings(t, r);
  for (const c of converted.filter(inTestSet)) {
    const mine = r.generated.filter((i) => i.file.startsWith(`src/r2c/${c.result.className}.`));
    assert.equal(mine.length, 0, `${c.e.name} is in the test set src/03 and must be clean on ABAP Cloud:\n${fmt(mine)}`);
  }
});

test("abaplint v702: every generated class downports and checks with the 7.02 syntax", { timeout: 600000 }, (t) => {
  const r = lint({ files, target: "v702", ddic: DDIC });
  repositoryFindings(t, r);
  assert.equal(r.generated.length, 0, fmt(r.generated));
});

test("abap2UI5 linter: no finding in any generated class", { timeout: 300000 }, () => {
  const r = lintUi5({ files });
  assert.ok(r.files >= converted.length, `${r.files} classes checked`);
  assert.equal(r.issues.length, 0, r.issues.map((i) => `${i.file}:${i.row}:${i.col} [${i.key}] ${i.message}`).join("\n"));
});

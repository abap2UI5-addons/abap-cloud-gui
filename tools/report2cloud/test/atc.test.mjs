// The ATC findings of the classic report in the migration report
// (lib/atc.mjs, --atc): the worklist ADT exports and a CSV read, each
// finding set against what the conversion did on its line.
import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { atcStates, parseAtc } from "../lib/atc.mjs";
import { CORPUS, HERE } from "./corpus.mjs";

const CLI = join(HERE, "..", "cli.mjs");

const finding = (row, title, prog = "zr2c_01_hello", col = 2) =>
  `<atcfinding:finding adtcore:uri="/sap/bc/adt/atc/findings/${row}" atcfinding:location="/sap/bc/adt/programs/programs/${prog}/source/main#start=${row},${col}" atcfinding:priority="1" atcfinding:checkId="CLOUD" atcfinding:checkTitle="Cloud readiness" atcfinding:messageId="M" atcfinding:messageTitle="${title}"/>`;
const worklist = (...findings) => `<?xml version="1.0" encoding="utf-8"?>
<atcworklist:worklist xmlns:atcworklist="http://www.sap.com/adt/atc/worklist" xmlns:atcobject="http://www.sap.com/adt/atc/object" xmlns:atcfinding="http://www.sap.com/adt/atc/finding" xmlns:adtcore="http://www.sap.com/adt/core" atcworklist:id="1">
 <atcworklist:objects>
  <atcobject:object adtcore:uri="/sap/bc/adt/programs/programs/zr2c_01_hello" adtcore:type="PROG/P" adtcore:name="ZR2C_01_HELLO">
   <atcobject:findings>${findings.join("")}</atcobject:findings>
  </atcobject:object>
 </atcworklist:objects>
</atcworklist:worklist>`;

test("the worklist of ADT: object, line and column of the location, priority, check, message", () => {
  const f = parseAtc(worklist(finding(12, "Statement WRITE is not permitted &amp; more")));
  assert.deepEqual(f, [{ object: "zr2c_01_hello", row: 12, col: 2, priority: 1, check: "Cloud readiness", message: "Statement WRITE is not permitted & more" }]);
});

test("a CSV with a header - semicolon or comma, the object column optional", () => {
  assert.deepEqual(parseAtc("Object;Line;Priority;Check;Message\nZR2C_01_HELLO;12;2;Cloud;WRITE not permitted\n"),
    [{ object: "zr2c_01_hello", row: 12, col: 0, priority: 2, check: "Cloud", message: "WRITE not permitted" }]);
  assert.equal(parseAtc("line,message\n8,PARAMETERS not permitted")[0].row, 8);
  assert.throws(() => parseAtc("a;b\n1;2"), /header/);
});

test("the state of a finding: the line converted, refused, a TODO, or over as it was", () => {
  const result = {
    programName: "zt",
    mapped: [{ row: 12, classic: "WRITE x", target: "write( x )" }],
    refusals: [{ row: 20, col: 1, message: "EXEC SQL - native SQL" }],
    todos: [{ row: 30, col: 1, message: "check the value" }],
    release: [{ name: "SFLIGHT", kind: "database table" }],
  };
  const states = atcStates([
    { row: 12, message: "WRITE" }, { row: 20, message: "EXEC SQL" }, { row: 30, message: "x" },
    { row: 40, message: "Access to SFLIGHT is not permitted" }, { row: 41, message: "something" },
    { object: "zt_top", row: 3, message: "in an include" },
  ], result);
  assert.deepEqual(states.map((s) => s.state), ["converted", "refused", "TODO", "to check", "to check", "to check"]);
  assert.match(states[3].detail, /database table SFLIGHT/);
  assert.match(states[5].detail, /zt_top, which the conversion did not inline/);
});

test("--atc: the migration report has the findings and what became of them", () => {
  const out = mkdtempSync(join(tmpdir(), "report2cloud-atc-"));
  try {
    const atc = join(out, "atc.xml");
    // line 12 a WRITE the conversion maps, line 4 a comment that went over as it was
    writeFileSync(atc, worklist(finding(12, "Statement WRITE is not permitted"), finding(4, "Comment", "zr2c_01_hello", 0)));
    const r = spawnSync(process.execPath, [CLI, join(CORPUS, "zr2c_01_hello.prog.abap"), "--out", out, "--atc", atc], { encoding: "utf8" });
    assert.equal(r.status, 0, r.stderr);
    const md = readFileSync(join(out, "zcl_r2c_01_hello.migration.md"), "utf8");
    assert.match(md, /\| ATC of the report \| 2 finding\(s\): 1 converted, 0 refused, 0 TODO, 1 to check \|/);
    assert.match(md, /## ATC findings of the report/);
    assert.match(md, /\| 12 \| 1 \| Cloud readiness \| Statement WRITE is not permitted \| \*\*converted\*\* - /);
    assert.match(md, /\| 4 \| 1 \| Cloud readiness \| Comment \| \*\*to check\*\* - the line went over as it was \|/);
  } finally {
    rmSync(out, { recursive: true, force: true });
  }
});

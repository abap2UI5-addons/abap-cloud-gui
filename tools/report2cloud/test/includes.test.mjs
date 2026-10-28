// lib/includes.mjs: the INCLUDE statements of a report inlined from the
// files beside it - the single statement and the chained one.
import { test } from "node:test";
import assert from "node:assert/strict";
import { inlineIncludes } from "../lib/includes.mjs";

const FILES = { ztop: "DATA gv TYPE i.", zf01: "FORM f.\nENDFORM." };
const read = (name) => FILES[name.toLowerCase()];

test("a chained INCLUDE over several lines inlines each include in its order", () => {
  const r = inlineIncludes("REPORT z.\nINCLUDE: ztop, \" the globals\n         zf01.\nWRITE gv.", { read });
  assert.deepEqual(r.included, ["ZTOP", "ZF01"]);
  assert.deepEqual(r.missing, []);
  assert.match(r.source, /DATA gv TYPE i\.[\s\S]*FORM f\./);
  assert.doesNotMatch(r.source, /^\s*INCLUDE/m);
  // each include remembers the line that names it
  const rows = r.source.split("\n");
  assert.deepEqual(r.origin(rows.findIndex((l) => l.includes("INCLUDE ZF01 - inlined")) + 1), { file: "zreport.prog.abap", row: 3 });
});

test("an include of a chain without its file stays a single INCLUDE the converter refuses", () => {
  const r = inlineIncludes("REPORT z.\nINCLUDE: ztop, znix, zgone IF FOUND.", { read });
  assert.deepEqual(r.included, ["ZTOP"]);
  assert.deepEqual(r.missing, ["ZNIX"]);
  assert.match(r.source, /^INCLUDE znix\.$/m);
  assert.match(r.source, /INCLUDE ZGONE IF FOUND - no such include, dropped/);
});

test("a chain that is not one of include names is left as it is", () => {
  const source = "REPORT z.\nINCLUDE: TYPE ty_s.\n";
  assert.equal(inlineIncludes(source, { read }).source, source);
});

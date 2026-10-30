// What the site hands the abap2UI5 playground beside a converted class
// (scripts/playground-runtime.mjs): only files it takes, the app's runtime
// whole, no data element left that it would not know.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { runtimeFiles } from "./playground-runtime.mjs";

const ROOT = join(fileURLToPath(import.meta.url), "..", "..");
const files = runtimeFiles(ROOT);
const names = files.map((f) => f.name);

test("every class and interface of src/01 goes, its unit tests do not", () => {
  const wanted = readdirSync(join(ROOT, "src", "01")).filter((f) => /^[a-z0-9_]+\.(clas|intf)\.abap$/.test(f));
  for (const f of wanted) assert.ok(names.includes(f), f);
  assert.ok(names.includes("z2ui5_cl_cgui_report.clas.abap"));
  assert.ok(!names.some((n) => n.includes("testclasses")));
});

test("only files the playground takes: classes, interfaces, tables", () => {
  for (const n of names) assert.match(n, /^[a-z0-9_]+\.(clas\.abap|intf\.abap|tabl\.xml)$/, n);
  assert.equal(new Set(names).size, names.length, "a file twice");
  for (const t of ["scarr", "spfli", "sflight", "snodetext"]) assert.ok(names.includes(`${t}.tabl.xml`), t);
});

test("no data element of the runtime is left - the playground has none", () => {
  const dtels = readdirSync(join(ROOT, "src", "01")).filter((f) => f.endsWith(".dtel.xml")).map((f) => f.replace(/\.dtel\.xml$/, ""));
  assert.ok(dtels.length > 0);
  for (const f of files) {
    for (const d of dtels) assert.doesNotMatch(f.source, new RegExp(`\\b${d}\\b(?!-)`, "i"), `${f.name} names ${d}`);
    assert.doesNotMatch(f.source, /^﻿/, `${f.name} starts with a BOM`);
  }
});

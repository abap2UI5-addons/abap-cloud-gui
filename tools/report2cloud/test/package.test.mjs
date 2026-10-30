// report2cloud package: a folder of reports in one run - the classes, the
// graph of SUBMIT and PERFORM ... IN PROGRAM, the order to migrate in.
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { callsOf, estateGraph, migrationOrder } from "../lib/estate.mjs";
import { packageRun } from "../package.mjs";
import { programs } from "../coverage.mjs";
import { includesFrom } from "../lib/includes-fs.mjs";

test("the calls of a report: SUBMIT, SUBMIT (dobj), PERFORM IN PROGRAM, PERFORM f(prog), CALL TRANSACTION - not in comments", () => {
  const calls = callsOf([
    "REPORT za.",
    "SUBMIT zb AND RETURN.",
    "SUBMIT (lv_prog) AND RETURN.",
    "PERFORM total IN PROGRAM zc IF FOUND.",
    "PERFORM other(zc).",
    "CALL TRANSACTION 'SE38'.",
    "* SUBMIT zcomment.",
    "WRITE 'x'. \" SUBMIT zquote",
  ].join("\n"));
  assert.deepEqual(calls.map((c) => `${c.kind} ${c.target}`), ["SUBMIT ZB", "SUBMIT ", "PERFORM ZC", "PERFORM ZC", "CALL TRANSACTION SE38"]);
});

test("the order to migrate in: the called report first, a cycle does not stop it", () => {
  const graph = estateGraph([
    { name: "ZA", calls: [{ kind: "SUBMIT", target: "ZB" }] },
    { name: "ZB", calls: [{ kind: "PERFORM", target: "ZC" }] },
    { name: "ZC", calls: [] },
    { name: "ZX", calls: [{ kind: "SUBMIT", target: "ZY" }] },
    { name: "ZY", calls: [{ kind: "SUBMIT", target: "ZX" }] },
  ]);
  const order = migrationOrder(graph);
  assert.ok(order.indexOf("ZC") < order.indexOf("ZB") && order.indexOf("ZB") < order.indexOf("ZA"));
  assert.equal(order.length, 5);
});

test("a package in one run: the classes written, estate.md with the order, the graph and what is outside", () => {
  const dir = mkdtempSync(join(tmpdir(), "r2c-pkg-"));
  const out = join(dir, "out");
  try {
    writeFileSync(join(dir, "zr2c_pa.prog.abap"), "REPORT zr2c_pa.\nPARAMETERS p TYPE i.\nSTART-OF-SELECTION.\n  SUBMIT zr2c_pb AND RETURN.\n  SUBMIT rsabaptest AND RETURN.\n  WRITE p.\n");
    writeFileSync(join(dir, "zr2c_pb.prog.abap"), "REPORT zr2c_pb.\nINCLUDE zr2c_pb_top.\nSTART-OF-SELECTION.\n  WRITE gv_text.\n");
    writeFileSync(join(dir, "zr2c_pb_top.prog.abap"), "DATA gv_text TYPE string VALUE `B`.\n");
    const files = programs(dir);
    const { graph, markdown } = packageRun(files, { read: includesFrom([dir]), out });

    assert.deepEqual(graph.nodes.map((n) => `${n.name} ${n.ok}`), ["ZR2C_PA true", "ZR2C_PB true"]);
    assert.ok(existsSync(join(out, "zcl_r2c_pa.clas.abap")) || existsSync(join(out, `${graph.nodes[0].class}.clas.abap`)));
    const md = readFileSync(join(out, "estate.md"), "utf8");
    assert.equal(md, markdown);
    // PB before PA: PA calls it
    assert.match(md, /\| 1 \| ZR2C_PB \|[\s\S]*\| 2 \| ZR2C_PA \|/);
    assert.match(md, /```mermaid\nflowchart LR/);
    assert.match(md, /ZR2C_PA: SUBMIT RSABAPTEST/);
    // the include is no report of the estate
    assert.ok(!graph.nodes.some((n) => n.name === "ZR2C_PB_TOP"));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

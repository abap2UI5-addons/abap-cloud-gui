// report2UI5 package: a folder of reports in one run - the classes and
// summary.md beside them.
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { packageRun } from "../package.mjs";
import { programs } from "../coverage.mjs";
import { includesFrom } from "../lib/includes-fs.mjs";

test("a package in one run: the classes written, summary.md beside them", () => {
  const dir = mkdtempSync(join(tmpdir(), "r2c-pkg-"));
  const out = join(dir, "out");
  try {
    writeFileSync(join(dir, "zr2c_pa.prog.abap"), "REPORT zr2c_pa.\nPARAMETERS p TYPE i.\nSTART-OF-SELECTION.\n  SUBMIT zr2c_pb AND RETURN.\n  WRITE p.\n");
    writeFileSync(join(dir, "zr2c_pb.prog.abap"), "REPORT zr2c_pb.\nINCLUDE zr2c_pb_top.\nSTART-OF-SELECTION.\n  WRITE gv_text.\n");
    writeFileSync(join(dir, "zr2c_pb_top.prog.abap"), "DATA gv_text TYPE string VALUE `B`.\n");
    writeFileSync(join(dir, "zr2c_pc.prog.abap"), "REPORT zr2c_pc.\nSTART-OF-SELECTION.\n  CALL SCREEN 100.\n");
    const files = programs(dir);
    const { rows, markdown } = packageRun(files, { read: includesFrom([dir]), out });

    assert.deepEqual(rows.map((r) => r.ok), [true, true, false]);
    assert.ok(existsSync(join(out, "zcl_r2c_pa.clas.abap")));
    assert.ok(existsSync(join(out, "zcl_r2c_pb.clas.abap")));
    assert.ok(!existsSync(join(out, "zcl_r2c_pc.clas.abap")), "no class of a refused report");
    const md = readFileSync(join(out, "summary.md"), "utf8");
    assert.equal(md, markdown);
    assert.match(md, /3 report\(s\) - 2 converted/);
    assert.match(md, /\[dynpro\]/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

// A whole package in memory (lib/package.mjs): the reports among the files
// converted with their includes and text pools, a SUBMIT of a report of the
// package starting its class, a summary, and every file to take along - and the zip reader of the site (site/unzip.mjs) reading what
// the zip writer wrote and what a deflating zip tool wrote.
import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { convertPackage, uniqueClassNames } from "../lib/package.mjs";
import { unzipTexts } from "../../../site/unzip.mjs";
import { zip } from "../../../site/zip.mjs";

const FILES = {
  "src/zpkg_top.prog.abap": "DATA gv_text TYPE string VALUE `Hello`.\n",
  "src/zpkg_a.prog.abap": "REPORT zpkg_a.\nINCLUDE zpkg_top.\nSTART-OF-SELECTION.\n  WRITE / gv_text.\n  SUBMIT zpkg_b AND RETURN.\n",
  "src/zpkg_b.prog.abap": "REPORT zpkg_b.\nPARAMETERS p_x TYPE i.\nSTART-OF-SELECTION.\n  WRITE / p_x.\n",
  "src/zpkg_b.prog.xml": `<?xml version="1.0" encoding="utf-8"?>
<abapGit version="v1.0.0" serializer="LCL_OBJECT_PROG" serializer_version="v1.0.0">
 <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
  <asx:values>
   <PROGDIR><NAME>ZPKG_B</NAME></PROGDIR>
   <TPOOL><item><ID>S</ID><KEY>P_X</KEY><ENTRY>        The number</ENTRY><LENGTH>18</LENGTH></item></TPOOL>
  </asx:values>
 </asx:abap>
</abapGit>
`,
  "src/zpkg_c.prog.abap": "REPORT zpkg_c.\nSTART-OF-SELECTION.\n  CALL SCREEN 100.\n",
  "README.md": "not abap",
};

test("the package: reports with their includes and text pools, the called report's class, the summary, the output files", () => {
  const { rows, summary, output } = convertPackage(FILES);
  assert.deepEqual(rows.map((r) => [r.name, r.ok]), [["ZPKG_A", true], ["ZPKG_B", true], ["ZPKG_C", false]]);
  // the include is no report of its own
  assert.ok(!rows.some((r) => r.name === "ZPKG_TOP"));
  const a = output["zcl_pkg_a.clas.abap"];
  assert.match(a, /gv_text TYPE string VALUE `Hello`/);
  // SUBMIT of a report of the package starts its class
  assert.match(a, /submit\( report = `ZCL_PKG_B`/i);
  // the text pool gives the parameter its label
  assert.match(output["zcl_pkg_b.clas.abap"], /text\s*=\s*`The number`/);
  assert.ok(Object.keys(output).includes("summary.md"));
  assert.ok(Object.keys(output).includes("zcl_pkg_a.migration.md"));
  assert.ok(Object.keys(output).includes("zcl_pkg_c.migration.md"), "the refused report has its migration report too");
  assert.ok(!Object.keys(output).includes("zcl_pkg_c.clas.abap"), "no class of a refused report");
  assert.match(summary, /3 report\(s\) - 2 converted/);
  assert.match(summary, /\[dynpro\]/);
  assert.match(rows[2].report, /CALL SCREEN/);
});

test("the zip reader: what the site's writer wrote, and a deflated zip of a zip tool", async () => {
  const stored = zip({ "src/a.prog.abap": "REPORT a.\n", "src/x.png": "\xff\xfe" });
  const texts = await unzipTexts(stored);
  assert.deepEqual(texts, { "src/a.prog.abap": "REPORT a.\n", "src/x.png": "\xff\xfe" });

  const dir = mkdtempSync(join(tmpdir(), "r2c-unzip-"));
  try {
    mkdirSync(join(dir, "src"));
    writeFileSync(join(dir, ".abapgit.xml"), "<x/>");
    // long enough to be deflated rather than stored
    writeFileSync(join(dir, "src", "zbig.prog.abap"), `REPORT zbig.\n${"  WRITE / 'a line of the report'.\n".repeat(200)}`);
    writeFileSync(join(dir, "src", "bin.bin"), Buffer.from([0, 255, 254, 1, 2, 3, 200]));
    execFileSync("zip", ["-q", "-r", "p.zip", ".abapgit.xml", "src"], { cwd: dir });
    const read = await unzipTexts(readFileSync(join(dir, "p.zip")));
    assert.deepEqual(Object.keys(read).sort(), [".abapgit.xml", "src/zbig.prog.abap"]);
    assert.match(read["src/zbig.prog.abap"], /^REPORT zbig\.\n {2}WRITE/);
    assert.equal(read["src/zbig.prog.abap"].split("\n").length, 202);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("two reports that would give the same class - ZREPORT and Z_REPORT, two long names cut alike - get a name each, SUBMIT starts the right one", () => {
  const report = (name, text, more = "") => `REPORT ${name}.\nSTART-OF-SELECTION.\n  WRITE / '${text}'.\n${more}`;
  const { rows, summary, output } = convertPackage({
    "src/zreport.prog.abap": report("zreport", "one", "  SUBMIT z_report AND RETURN.\n"),
    "src/z_report.prog.abap": report("z_report", "two", "  SUBMIT zreport AND RETURN.\n"),
    "src/zsales_order_overview_report_a.prog.abap": report("zsales_order_overview_report_a", "A"),
    "src/zsales_order_overview_report_b.prog.abap": report("zsales_order_overview_report_b", "B"),
  });
  assert.deepEqual(rows.map((r) => [r.name, r.className, r.ok]), [
    ["Z_REPORT", "zcl_report", true],
    ["ZREPORT", "zcl_report2", true],
    ["ZSALES_ORDER_OVERVIEW_REPORT_A", "zcl_sales_order_overview_repor", true],
    ["ZSALES_ORDER_OVERVIEW_REPORT_B", "zcl_sales_order_overview_repo2", true],
  ]);
  // a class and a migration report each - none written over another
  const classes = Object.keys(output).filter((f) => f.endsWith(".clas.abap"));
  assert.equal(classes.length, 4);
  assert.equal(Object.keys(output).filter((f) => f.endsWith(".migration.md")).length, 4);
  assert.match(output["zcl_report.clas.abap"], /write\( 'two' \)/);
  assert.match(output["zcl_report2.clas.abap"], /write\( 'one' \)/);
  assert.match(output["zcl_report2.clas.abap"], /^CLASS zcl_report2 DEFINITION/);
  assert.match(output["zcl_sales_order_overview_repo2.clas.abap"], /write\( 'B' \)/);
  // SUBMIT starts the class the report it names got
  assert.match(output["zcl_report2.clas.abap"], /submit\( report = `ZCL_REPORT`/i);
  assert.match(output["zcl_report.clas.abap"], /submit\( report = `ZCL_REPORT2`/i);
  assert.match(summary, /4 report\(s\) - 4 converted/);
  assert.match(summary, /ZREPORT -> zcl_report2 \(zcl_report is Z_REPORT's\)/);
});

test("uniqueClassNames: the first keeps its name, the next a number, never a name another report has", () => {
  assert.deepEqual(uniqueClassNames(["zcl_a", "zcl_a", "zcl_a2", "zcl_a"]), ["zcl_a", "zcl_a3", "zcl_a2", "zcl_a4"]);
  assert.deepEqual(uniqueClassNames(["z".repeat(30), "z".repeat(30)]), ["z".repeat(30), `${"z".repeat(29)}2`]);
});

test("a namespaced report of a package: its files named #abc#, no folder in the zip", () => {
  const { rows, output } = convertPackage({ "src/#abc#zrep.prog.abap": "REPORT /abc/zrep.\nSTART-OF-SELECTION.\n  WRITE / 'x'.\n" });
  assert.deepEqual(rows.map((r) => [r.name, r.className, r.ok]), [["/ABC/ZREP", "/abc/cl_zrep", true]]);
  assert.deepEqual(Object.keys(output).sort(), ["#abc#cl_zrep.clas.abap", "#abc#cl_zrep.clas.xml", "#abc#cl_zrep.migration.md", "summary.md"]);
});

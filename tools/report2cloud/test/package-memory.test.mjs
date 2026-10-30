// A whole package in memory (lib/package.mjs): the reports among the files
// converted with their includes and text pools, a SUBMIT of a report of the
// package starting its class, the order to migrate in, and every file to
// take along - and the zip reader of the site (site/unzip.mjs) reading what
// the zip writer wrote and what a deflating zip tool wrote.
import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { convertPackage } from "../lib/package.mjs";
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
  "src/zpkg_c.prog.abap": "REPORT zpkg_c.\nSTART-OF-SELECTION.\n  EXEC SQL.\n    COMMIT\n  ENDEXEC.\n",
  "README.md": "not abap",
};

test("the package: reports with their includes and text pools, the called report's class, the order, the output files", () => {
  const { rows, order, estate, output } = convertPackage(FILES);
  assert.deepEqual(rows.map((r) => [r.name, r.ok]), [["ZPKG_A", true], ["ZPKG_B", true], ["ZPKG_C", false]]);
  // the include is no report of its own
  assert.ok(!rows.some((r) => r.name === "ZPKG_TOP"));
  const a = output["zcl_pkg_a.clas.abap"];
  assert.match(a, /gv_text TYPE string VALUE `Hello`/);
  // SUBMIT of a report of the package starts its class
  assert.match(a, /submit\( report = `ZCL_PKG_B`/i);
  // the text pool gives the parameter its label
  assert.match(output["zcl_pkg_b.clas.abap"], /text\s*=\s*`The number`/);
  // b before a - a calls b
  assert.ok(order.indexOf("ZPKG_B") < order.indexOf("ZPKG_A"), order.join(","));
  assert.ok(Object.keys(output).includes("estate.md"));
  assert.ok(Object.keys(output).includes("zcl_pkg_a.migration.md"));
  assert.ok(Object.keys(output).includes("zcl_pkg_c.migration.md"), "the refused report has its migration report too");
  assert.ok(!Object.keys(output).includes("zcl_pkg_c.clas.abap"), "no class of a refused report");
  assert.match(estate, /3 report\(s\) - 2 converted/);
  assert.match(estate, /native-sql/);
  assert.match(rows[2].report, /EXEC SQL/);
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

// The zip writer of the site (site/zip.mjs): what it writes, a zip reader
// reads - the entries, their names and texts, the CRC - and the abapGit
// layout is .abapgit.xml at the root and the objects under src/.
import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { abapgitZip, zip } from "../../../site/zip.mjs";

function unzipped(bytes) {
  const dir = mkdtempSync(join(tmpdir(), "r2c-zip-"));
  try {
    writeFileSync(join(dir, "a.zip"), bytes);
    // unzip -t checks every CRC; -o extracts
    execFileSync("unzip", ["-t", "a.zip"], { cwd: dir, stdio: "pipe" });
    execFileSync("unzip", ["-o", "-q", "a.zip"], { cwd: dir, stdio: "pipe" });
    const list = execFileSync("unzip", ["-Z1", "a.zip"], { cwd: dir }).toString().trim().split("\n");
    const texts = Object.fromEntries(list.map((p) => [p, readFileSync(join(dir, p), "utf8")]));
    return { list, read: (p) => texts[p] };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("a zip of text files: the names, the texts, the CRCs", () => {
  const bytes = zip({ "a.txt": "hello", "dir/b.abap": "REPORT z.\n  WRITE 'ü'.\n" });
  const z = unzipped(bytes);
  assert.deepEqual(z.list, ["a.txt", "dir/b.abap"]);
  assert.equal(z.read("a.txt"), "hello");
  assert.equal(z.read("dir/b.abap"), "REPORT z.\n  WRITE 'ü'.\n");
});

test("the abapGit zip: .abapgit.xml at the root, the objects under src/", () => {
  const z = unzipped(abapgitZip({ "zcl_x.clas.abap": "CLASS zcl_x DEFINITION.", "zcl_x.clas.xml": "<x/>", "zcl_x.migration.md": "# r" }, "zcl_x"));
  assert.deepEqual(z.list, [".abapgit.xml", "src/zcl_x.clas.abap", "src/zcl_x.clas.xml", "src/zcl_x.migration.md"]);
  assert.match(z.read(".abapgit.xml"), /<NAME>zcl_x<\/NAME>[\s\S]*<STARTING_FOLDER>\/src\/<\/STARTING_FOLDER>[\s\S]*<FOLDER_LOGIC>PREFIX<\/FOLDER_LOGIC>/);
});

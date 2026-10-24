// The web corpus (web.mjs) without the web: a list file and a cache that
// holds the clones already - the reports are written here. A report takes
// its includes from its own repository, the classes are numbered across
// repositories, and the summary ranks the refusals.
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { markdown } from "../web.mjs";

const WEB = new URL("../web.mjs", import.meta.url).pathname;

function cacheWith(repos) {
  const cache = mkdtempSync(join(tmpdir(), "report2cloud-web-"));
  for (const [name, files] of Object.entries(repos)) {
    const dir = join(cache, name.replace("/", "__"));
    mkdirSync(join(dir, ".git"), { recursive: true });
    mkdirSync(join(dir, "src"), { recursive: true });
    for (const [file, text] of Object.entries(files)) writeFileSync(join(dir, "src", file), text);
  }
  return cache;
}

test("the reports of the listed repositories, each with the includes of its own repository", () => {
  const cache = cacheWith({
    "one/reports": {
      "zhello.prog.abap": "REPORT zhello.\nINCLUDE zhello_top.\nSTART-OF-SELECTION.\n  WRITE / gv_text.\n",
      "zhello_top.prog.abap": "DATA gv_text TYPE string VALUE `Hello`.\n",
    },
    "two/tools": {
      "zhello.prog.abap": "REPORT zhello.\nSTART-OF-SELECTION.\n  CALL SCREEN 100.\n",
      // the include of the other repository is not this one's
      "zother.prog.abap": "REPORT zother.\nINCLUDE zhello_top.\nSTART-OF-SELECTION.\n  WRITE / gv_text.\n",
    },
  });
  try {
    const list = join(cache, "list.json");
    writeFileSync(list, JSON.stringify(["one/reports", "two/tools", "not a name"]));
    const json = join(cache, "rows.jsonl");
    const run = spawnSync(process.execPath, [WEB, "--list", list, "--cache", cache, "--json", json], { encoding: "utf8" });
    assert.equal(run.status, 0, run.stderr);
    assert.match(run.stdout, /\*\*1 of 3 reports converted \(33 %\)\*\* - 2 refused, 0 crashed; 2 repositories\./);
    assert.match(run.stdout, /\| 1 \| 33 % \| .*\[dynpro\] \|/);
    assert.match(run.stdout, /\| 1 \| 33 % \| .*\[include-missing\] \|/);
    const rows = readFileSync(json, "utf8").trim().split("\n").map((l) => JSON.parse(l));
    assert.deepEqual(rows.map((r) => [r.file, r.ok]), [
      ["one__reports/src/zhello.prog.abap", true],
      ["two__tools/src/zhello.prog.abap", false],
      ["two__tools/src/zother.prog.abap", false],
    ]);
  } finally {
    rmSync(cache, { recursive: true, force: true });
  }
});

test("the summary: crashes listed, lint findings ranked by kind", () => {
  const md = markdown({
    rows: [{ file: "a", ok: true }, { file: "b", ok: false, refusals: ["X [x]"] }, { file: "c", crashed: "boom" }],
    repos: 1,
    failed: ["o/r"],
    findings: [{ key: "parser_error", message: "Statement does not exist" }, { key: "check_syntax", message: "\"zcl_dep\" not found" }],
  });
  assert.match(md, /\*\*1 of 3 reports converted \(33 %\)\*\* - 1 refused, 1 crashed; 1 repository, 1 not cloned\./);
  assert.match(md, /\| 1 \| 33 % \| X \[x\] \|/);
  assert.match(md, /2 finding\(s\), 1 parser error\(s\)/);
  assert.match(md, /- `c`: boom/);
});

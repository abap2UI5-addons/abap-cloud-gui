// report2cloud, the semantic test: the classic report and its class run
// against the same seeded rows, and their lists are compared.
//
// The report itself is transpiled as a program (backend.mjs, `programs`) and
// run in a process of its own (program.mjs); its selection screen is
// declared as data and filled where the run starts - the defaults, then
// INITIALIZATION, then the values of the user (program-source.mjs). The class runs in the backend as the runtime test runs it -
// started, its selection screen filled with the same values, Execute.
//
// The comparison is of the content, line by line: the transpiled WRITE
// leaves out the blank between two items and pads nothing, the list of the
// class joins its items by a blank - the blanks inside a line are dropped on
// both sides, and so is the separator between two digits, a date is
// YYYYMMDD (the format of the user), an ULINE is `---`, the empty lines at
// the end are dropped.
// What a line says, the order of the lines and where a line breaks must be
// the same.
//
//   npm run test:report2cloud:runtime   (beside runtime.test.mjs)
//
// Opt-in like the runtime test: without an mcp-server checkout it is skipped.
import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { corpus, convertEntry, DDIC } from "../corpus.mjs";
import { buildBackend, resolveMcpServer, startBackend } from "./backend.mjs";
import { createDriver } from "./driver.mjs";
import { asProgram, normalize } from "./program-source.mjs";
import { seedSql } from "./seed.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.REPORT2CLOUD_SEMANTIC_PORT || 4482);
const mcp = resolveMcpServer();
const skip = mcp.missing || false;

// the reports compared, the values of their selection screens - a report
// the transpiler does not take or run as a program is left out: a table
// with a header line (zr2c_14, zr2c_36), a FORM with TABLES (zr2c_03)
const CASES = [
  { name: "zr2c_01_hello", values: { P_NAME: "World", P_TIMES: 2 } },
  { name: "zr2c_09_localclass", values: { P_DEC: 0 } },
  { name: "zr2c_33_strings", values: {} },
  { name: "zr2c_34_controllevels", values: {} },
  { name: "zr2c_35_dates", values: {} },
  { name: "zr2c_37_expressions", values: { P_TEAM: "B" } },
];

let build;
let backend;
let d;

before(async () => {
  if (skip) return;
  const files = {};
  const entries = new Map(corpus().map((e) => [e.name, e]));
  for (const c of CASES) {
    const e = entries.get(c.name);
    assert.ok(e, c.name);
    const { result } = convertEntry(e);
    assert.ok(result.ok, `${c.name} converts`);
    Object.assign(files, result.files);
    files[`${c.name}.prog.abap`] = asProgram(e.source, c.values);
  }
  const log = [];
  build = await buildBackend({ files, ddic: DDIC, seed: seedSql(), onLine: (l) => log.push(l) });
  assert.ok(build.ok, `the backend did not build: ${build.reason}\n${log.slice(-30).join("\n")}`);
  backend = await startBackend({ build, port: PORT, freshStatics: "^CLAS-Z2UI5_CL_CGUI_R2C_\\d+-" });
  d = await createDriver({ mcp: mcp.dir, url: backend.url });
}, { timeout: 20 * 60_000 });

after(async () => {
  if (backend) await backend.stop();
  if (build?.dir && !process.env.REPORT2CLOUD_RUNTIME_KEEP) rmSync(build.dir, { recursive: true, force: true });
});

/** the list the classic report writes */
function programList(name) {
  const r = spawnSync(process.execPath, [join(HERE, "program.mjs"), build.apps, `${name}.prog.mjs`], { cwd: build.runtimeDir, encoding: "utf8", timeout: 120_000 });
  const out = JSON.parse(r.stdout || "{}");
  assert.ok(out.ok, `${name} as a program: ${out.error ?? r.stderr}`);
  return out.list.split("\n");
}

/** the list the class writes - Execute on its selection screen */
async function classList(c) {
  let s = await d.start(`z2ui5_cl_cgui_r2c_${c.name.slice(5, 7)}`);
  if (s.fields.length) s = await d.act(s.session, { values: c.values, event: "CGUI_EXECUTE" });
  return d.lines();
}

for (const c of CASES) {
  test(`${c.name}: the class writes the list the report writes`, { skip }, async () => {
    const classic = normalize(programList(c.name));
    const converted = normalize(await classList(c));
    assert.ok(classic.length > 0, "the report writes a list");
    assert.deepEqual(converted, classic);
  });
}

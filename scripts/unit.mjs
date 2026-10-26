#!/usr/bin/env node
// The ABAP Unit tests of src/ in the transpiled abap2UI5 backend - no SAP
// system. The classes, interfaces, tables and data elements of src/01 and
// src/02 are transpiled with their
// test includes against @abap2ui5/node-runtime at the release abaplint.jsonc
// pins; the tables are created in the runtime's SQLite before the tests
// start, so the RISK LEVEL DANGEROUS tests of the variant and layout stores
// run against them. The build is the one the runtime test of report2cloud
// uses (tools/report2cloud/test/runtime/backend.mjs), the runner and the
// report of its results are the abap2UI5 MCP server's (lib/runtime.mjs) - it
// needs an mcp-server checkout at MCP_SERVER_HOME or ../mcp-server. The MCP server's own unit action
// deploys classes and interfaces only, no tables - hence this script.
//
//   npm run unit
import { pathToFileURL } from "node:url";
import { join } from "node:path";
import { rmSync } from "node:fs";
import { buildBackend, resolveMcpServer } from "../tools/report2cloud/test/runtime/backend.mjs";

const onLine = (line) => console.log(line);

const mcp = resolveMcpServer();
if (mcp.missing) {
  console.error(`unit: ${mcp.missing}`);
  process.exit(2);
}

const build = await buildBackend({ sources: ["src/01", "src/02"], withTests: true, onLine });
if (!build.ok) {
  console.error(`unit: the build failed - ${build.reason}`);
  process.exit(2);
}

const { runUnitTests } = await import(pathToFileURL(join(mcp.dir, "lib", "runtime.mjs")).href);
let result;
try {
  result = await runUnitTests({ appsDir: build.apps, onLine: () => {} });
} finally {
  if (!process.env.UNIT_KEEP) rmSync(build.dir, { recursive: true, force: true });
}

const lines = [];
for (const t of result.tests) {
  lines.push(`${t.skipped ? "SKIP" : "ok  "}  ${t.object} ${t.localClass}->${t.method}${t.skipped ? ` (${t.skipped})` : ""}`);
}
if (result.failed) {
  const f = result.failed;
  lines.push("", `FAIL  ${f.object} ${f.localClass || ""}->${f.method}${f.fixture ? " (its fixture, before the test ran)" : ""}`, "", f.error || "");
} else if (!result.ok && result.error) {
  lines.push("", "FAIL", result.error);
}
const objects = new Set(result.tests.map((t) => t.object));
lines.push("", `${result.ran} test method(s) of ${objects.size} class(es) ran${result.skipped ? `, ${result.skipped} skipped` : ""} - ${result.ok ? "all green" : "a test failed"}`);
console.log(lines.join("\n"));
process.exit(result.ok && result.ran > 0 ? 0 : 1);

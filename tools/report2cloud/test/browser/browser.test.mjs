// report2cloud in the browser: every converted report of the corpus started
// as the real abap2UI5 app - the UI5 frontend in headless Chromium against
// the transpiled backend of the runtime test (lib/browser.mjs). UI5 boots,
// the first screen renders, Execute of a selection screen runs the report,
// and no page error, no error response of the backend and no error popup
// shows on the way. The runtime test drives the same reports through the
// JSON protocol and reads what they answer; this one sees what the browser
// makes of it.
//
//   npm run test:report2cloud:browser
//
// Opt-in like the runtime test: an mcp-server checkout beside this
// repository, the popups, the @openui5 packages (devDependencies) and a
// Chromium for Playwright (`npx playwright install chromium`, or
// REPORT2CLOUD_CHROMIUM). Without an mcp-server checkout it is skipped.
import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { rmSync } from "node:fs";
import { corpus, convertEntry, DDIC } from "../corpus.mjs";
import { buildBackend, resolveMcpServer, startBackend } from "../runtime/backend.mjs";
import { seedSql } from "../runtime/seed.mjs";
import { browserRun } from "../../lib/browser.mjs";

const PORT = Number(process.env.REPORT2CLOUD_BROWSER_PORT || 4482);
const mcp = resolveMcpServer();
const skip = mcp.missing || false;

let build;
let backend;
const classes = [];

before(async () => {
  if (skip) return;
  const files = {};
  for (const e of corpus()) {
    const { result } = convertEntry(e);
    if (!result.ok) continue;
    Object.assign(files, result.files);
    classes.push(result.className);
  }
  const log = [];
  build = await buildBackend({ files, ddic: DDIC, seed: seedSql(), onLine: (l) => log.push(l) });
  assert.ok(build.ok, `the backend did not build: ${build.reason}\n${log.slice(-30).join("\n")}`);
  // the CLASS-DATA of the local classes cleared before every request, as on a system
  backend = await startBackend({ build, port: PORT, freshStatics: "^CLAS-Z2UI5_CL_CGUI_R2C_\\d+-" });
}, { timeout: 20 * 60_000 });

after(async () => {
  if (backend) await backend.stop();
  if (build?.dir && !process.env.REPORT2CLOUD_RUNTIME_KEEP) rmSync(build.dir, { recursive: true, force: true });
});

test("every converted report of the corpus boots in the browser, renders and runs - no page error, no error of the backend", { skip, timeout: 60 * 60_000 }, async (t) => {
  const rows = await browserRun(classes, { url: backend.url, onLine: (l) => t.diagnostic(l) });
  const failed = rows.filter((r) => !r.ok);
  assert.deepEqual(failed.map((r) => `${r.cls}: ${r.errors.join("; ")}`), []);
  assert.ok(rows.filter((r) => r.executed).length >= 20, "the reports with a selection screen ran with Execute");
});

test("on a phone the selection screens fit the width - select-options, lines of fields and the list wrap instead of scrolling sideways", { skip, timeout: 30 * 60_000 }, async (t) => {
  // the selection screens of the corpus with select-options, a line of fields and pushbuttons
  const phone = classes.filter((c) => /_r2c_(01|02|06|10|12|14)$/.test(c));
  const rows = await browserRun(phone, { url: backend.url, execute: false, themes: true, viewport: { width: 390, height: 844 }, onLine: (l) => t.diagnostic(l) });
  assert.deepEqual(rows.filter((r) => !r.ok).map((r) => `${r.cls}: ${r.errors.join("; ")}`), []);
});

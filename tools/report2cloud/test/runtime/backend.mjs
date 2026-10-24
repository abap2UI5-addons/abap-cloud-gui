// The transpiled abap2UI5 backend for the runtime test of report2cloud: the
// generated classes, src/01, the popups they call and stubs of the flight
// tables, transpiled with @abaplint/transpiler against @abap2ui5/node-runtime
// and served on loopback - no SAP system.
//
// It reuses the abap2UI5 MCP server (abap2UI5/mcp-server) as a library, the
// way AGENTS.md "Verifying at runtime" describes: its npm backend installs the
// runtime package at the release this repository pins (abaplint.jsonc), with
// the transpiler the release names, and fetches open-abap-core at the
// release's commit (lib/npm-backend.mjs); its app client operates the apps
// over the real JSON protocol (lib/appclient.mjs). What it adds is what the
// MCP server's build leaves out on purpose - database tables: the tables of
// src/01 (the variant and layout stores) and the TABL stubs of test/ddic are
// transpiled with the classes, their CREATE TABLE statements
// are taken from the transpiler's own init.mjs, and the boot creates them and
// inserts the seed rows (seed.mjs) before the apps load.
//
// Where the MCP server is:   MCP_SERVER_HOME, else ../mcp-server beside this
//                            repository (a set variable is authoritative)
// Where the popups are:      POPUPS_HOME, else .deps/popups (unit.yaml clones
//                            it there), else ../popups - else cloned into
//                            build/popups
// Where the runtime goes:    A2UI5_MCP_WORKSPACE (the MCP server's own
//                            variable), default ~/.abap2ui5-mcp
import { spawn } from "node:child_process";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import { pathToFileURL, fileURLToPath } from "node:url";
import { parseJsonc, popupsDir, REPO } from "../../lib/gate.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));

/** the popups the report runtime calls - unit.yaml deploys the same set */
export const POPUP_FILES = [
  "src/00",
  "src/z2ui5_cl_popup_get_range.clas.abap",
  "src/z2ui5_cl_popup_to_confirm.clas.abap",
  "src/z2ui5_cl_popup_to_select.clas.abap",
  "src/z2ui5_cl_popup_input_val.clas.abap",
];

/** The mcp-server checkout: `{ dir }`, or `{ missing }` with the reason. */
export function resolveMcpServer(env = process.env) {
  const probe = (dir) => existsSync(join(dir, "lib", "appclient.mjs")) && existsSync(join(dir, "lib", "npm-backend.mjs"));
  if (env.MCP_SERVER_HOME) {
    const dir = resolve(env.MCP_SERVER_HOME);
    return probe(dir) ? { dir } : { missing: `MCP_SERVER_HOME=${env.MCP_SERVER_HOME} is no mcp-server checkout with lib/appclient.mjs (abap2UI5/mcp-server)` };
  }
  const sibling = resolve(REPO, "..", "mcp-server");
  if (probe(sibling)) return { dir: sibling };
  return { missing: `no mcp-server checkout at ${sibling} - clone abap2UI5/mcp-server beside this repository (with lib/appclient.mjs) or set MCP_SERVER_HOME` };
}

/** The abap2UI5 release abaplint.jsonc pins (the "branch" of the core). */
export function corePin() {
  const config = parseJsonc(readFileSync(join(REPO, "abaplint.jsonc"), "utf8"));
  const dep = (config.dependencies || []).find((d) => /abap2ui5\/abap2ui5/i.test(String(d.url || "")));
  return dep && /^\d+\.\d+\.\d+$/.test(String(dep.branch)) ? dep.branch : null;
}

const OBJECT = /^([a-z0-9_]+)\.(clas|intf|tabl|dtel|ttyp)(\.[a-z_]+)?\.(abap|xml)$/i;

function copyObjects(from, to, withTests = false) {
  if (!existsSync(from)) return;
  if (!from.endsWith(".abap") && !from.endsWith(".xml")) {
    for (const f of readdirSync(from)) copyObjects(join(from, f), to, withTests);
    return;
  }
  const name = basename(from);
  if (!OBJECT.exec(name)) return;
  // the test include of a class only for a unit run
  if (name.endsWith(".testclasses.abap") && !withTests) return;
  cpSync(from, join(to, name));
  // a class source brings its sidecar and includes along
  const m = /^(.*)\.clas\.abap$/.exec(name);
  if (m) {
    for (const f of readdirSync(dirname(from))) {
      if (f.startsWith(`${m[1]}.clas.`) && f !== name && (withTests || !f.endsWith(".testclasses.abap"))) cpSync(join(dirname(from), f), join(to, f));
    }
  }
}

/** The CREATE TABLE statements (SQLite) the transpiler wrote for `tables`
 *  into its init.mjs. */
export function tableSchema(initText, tables) {
  const out = [];
  for (const m of initText.matchAll(/^\s*sqlite\.push\(`(CREATE TABLE '([a-z0-9_/]+)'[^`]*)`\);$/gm)) {
    if (tables.includes(m[2].toLowerCase())) out.push(m[1]);
  }
  return out;
}

/** apps/init.mjs of this build: boot the runtime, create the dev tables and
 *  seed them, then load the dev modules. tolerant: a module that throws
 *  while it loads (a class constructor) is left out and named in
 *  failedModules - the measurement over many reports goes on without it. */
export function initSource({ modules, schema, seed, tolerant = false }) {
  return [
    "// Generated by tools/report2cloud/test/runtime/backend.mjs - the boot of the report2cloud runtime test.",
    'import * as runtime from "@abap2ui5/node-runtime";',
    "",
    "await runtime.initialize();",
    'const db = globalThis.abap.context.databaseConnections["DEFAULT"];',
    `await db.execute(${JSON.stringify([...schema, ...seed])});`,
    "",
    ...(tolerant
      ? ["export const failedModules = [];", ...modules.map((f) => `try { await import("./${f}"); } catch (e) { failedModules.push({ module: ${JSON.stringify(f)}, error: String(e && e.message || e) }); }`)]
      : modules.map((f) => `await import("./${f}");`)),
    "",
    `export const devModules = ${JSON.stringify(modules)};`,
    "export const accelerated = true;",
    "",
  ].join("\n");
}

/** the folders of the libraries a build transpiles against - the
 *  package's downport and open-abap-core - for a syntax check beforehand
 *  (lib/start.mjs). Resolves { downport, core } or { error }. */
export async function runtimeSources({ onLine = () => {} } = {}) {
  const mcp = resolveMcpServer();
  if (mcp.missing) return { error: mcp.missing };
  const pin = corePin();
  if (pin && !process.env.A2UI5_MCP_RUNTIME_VERSION) process.env.A2UI5_MCP_RUNTIME_VERSION = pin;
  const npm = await import(pathToFileURL(join(mcp.dir, "lib", "npm-backend.mjs")).href);
  const rt = await npm.prepareRuntime({ withLint: false, onLine });
  if (!rt.ok) return { error: `@abap2ui5/node-runtime: ${rt.reason}` };
  const core = npm.openAbapCoreOf(rt.meta, rt.version);
  const lib = await npm.ensureOpenAbapCore({ sha: core.sha, source: core.source, onLine });
  if (!lib.ok) return { error: `open-abap-core: ${lib.reason}` };
  return { downport: npm.downportDir(rt.dir), core: join(lib.dir, "src") };
}

/**
 * Transpile `files` (generated classes, { name: text }) together with the
 * packages `sources` (default src/01 - every class, interface, table and
 * data element), the popups and the DDIC stubs into a directory inside the
 * runtime's install (the modules resolve the package through its
 * node_modules). `withTests` takes the test includes along and keeps the
 * transpiler's unit-test runner (index.mjs) beside init.mjs - what
 * scripts/unit.mjs runs; the tables are created by init.mjs either way.
 * Resolves { ok, dir, apps, version, reason? }.
 */
export async function buildBackend({ files = {}, ddic, seed = [], sources = ["src/01"], withTests = false, tolerant = false, onLine = () => {} }) {
  const mcp = resolveMcpServer();
  if (mcp.missing) return { ok: false, reason: mcp.missing };
  const pin = corePin();
  if (pin && !process.env.A2UI5_MCP_RUNTIME_VERSION) process.env.A2UI5_MCP_RUNTIME_VERSION = pin;
  const npm = await import(pathToFileURL(join(mcp.dir, "lib", "npm-backend.mjs")).href);
  const { spawnWithTimeout } = await import(pathToFileURL(join(mcp.dir, "lib", "spawn.mjs")).href);

  const rt = await npm.prepareRuntime({ withLint: false, onLine });
  if (!rt.ok) return { ok: false, reason: `@abap2ui5/node-runtime: ${rt.reason}` };
  const core = npm.openAbapCoreOf(rt.meta, rt.version);
  const lib = await npm.ensureOpenAbapCore({ sha: core.sha, source: core.source, onLine });
  if (!lib.ok) return { ok: false, reason: `open-abap-core: ${lib.reason}` };

  const work = mkdtempSync(join(rt.dir, `.r2c-${process.pid}-`));
  const input = join(work, "input");
  const staging = join(work, "staging");
  const apps = join(work, "apps");
  mkdirSync(input);
  mkdirSync(staging);
  mkdirSync(apps);
  for (const source of sources) copyObjects(join(REPO, source), input, withTests);
  const popups = popupsDir();
  for (const p of POPUP_FILES) copyObjects(join(popups, p), input);
  for (const [name, text] of Object.entries(files)) writeFileSync(join(input, name), text);
  if (ddic) copyObjects(ddic, input);

  const config = npm.transpileConfig({
    inputDir: input,
    outputDir: staging,
    downportRel: relative(rt.dir, npm.downportDir(rt.dir)).split(sep).join("/"),
    coreRel: relative(rt.dir, lib.dir).split(sep).join("/"),
  });
  config.input_filter = ["[\\\\/][a-z0-9_]+\\.(clas|intf|tabl|dtel|ttyp)\\.[a-z_.]*(abap|xml)$"];
  config.write_unit_tests = withTests;
  writeFileSync(join(work, "abap_transpile.json"), JSON.stringify(config, null, 2));
  const transpiler = join(rt.dir, "node_modules", "@abaplint", "transpiler-cli", "abap_transpile");
  onLine(`transpile: ${readdirSync(input).length} files against @abap2ui5/node-runtime ${rt.version}`);
  const res = await spawnWithTimeout(process.execPath, [transpiler, join(work, "abap_transpile.json")], {
    cwd: rt.dir, timeoutMs: 15 * 60_000, onLine: (l) => { if (!/^\s*\d+% - /.test(l)) onLine(l); },
  });
  if (res.code !== 0) {
    const why = `${res.stdout}\n${res.stderr}`.split("\n").filter((l) => /error/i.test(l)).slice(0, 20).join("\n");
    return { ok: false, dir: work, reason: `the transpiler exited ${res.code}:\n${why}` };
  }

  const objects = [...new Set(readdirSync(input).map((f) => OBJECT.exec(f)).filter(Boolean).map((m) => `${m[1].toLowerCase()}.${m[2].toLowerCase()}`))].sort();
  // transpiler-cli 2.14 on writes the project's modules into staging/project/
  // and each library into a folder of its own, imported as ../<folder>/x.mjs:
  // the package's own-apps.mjs points those at its output/<folder>/. Before
  // 2.14 everything is flat and rewriteImports( ) does it
  const folders = npm.outputLayout(staging) === "folders";
  const moduleDir = folders ? join(staging, npm.PROJECT_DIR) : staging;
  const own = npm.devOutputFiles(readdirSync(moduleDir), objects);
  const local = new Set(own);
  const stray = [];
  let rewritten = new Map();
  if (folders) {
    const script = join(rt.dir, "node_modules", "@abap2ui5", "node-runtime", "setup", "own-apps.mjs");
    if (!existsSync(script)) return { ok: false, dir: work, reason: `@abap2ui5/node-runtime ${rt.version} writes its output in folders and has no setup/own-apps.mjs` };
    const { ownApps } = await import(pathToFileURL(script).href);
    const kept = join(work, "own-apps");
    try {
      ownApps({ output: staging, apps: kept });
    } catch (e) {
      return { ok: false, dir: work, reason: String(e.message || e) };
    }
    rewritten = new Map(own.map((f) => [f, readFileSync(join(kept, f), "utf8")]));
  }
  for (const f of own) {
    let text = rewritten.get(f) ?? readFileSync(join(moduleDir, f), "utf8");
    if (f.endsWith(".mjs") && !folders) {
      text = npm.rewriteImports(text, local);
      stray.push(...npm.strayImports(text, local).map((s) => `${f} -> ${s}`));
    }
    writeFileSync(join(apps, f), text);
  }
  if (stray.length) return { ok: false, dir: work, reason: `imports the build cannot point at the package: ${stray.slice(0, 5).join(", ")}` };
  const initText = readFileSync(join(staging, "init.mjs"), "utf8");
  // the transparent tables - a structure (INTTAB) has no table in the database
  const tables = objects.filter((o) => o.endsWith(".tabl")).map((o) => o.replace(/\.tabl$/, ""))
    .filter((t) => !/<TABCLASS>INTTAB<\/TABCLASS>/.test(readFileSync(join(input, `${t}.tabl.xml`), "utf8")));
  const schema = tableSchema(initText, tables);
  if (schema.length !== tables.length) return { ok: false, dir: work, reason: `CREATE TABLE for ${tables.join(", ")} not found in the transpiler's init.mjs` };
  const modules = npm.bootOrder(initText, objects.map((o) => `${o}.mjs`).filter((f) => local.has(f)));
  writeFileSync(join(apps, "init.mjs"), initSource({ modules, schema, seed, tolerant }));
  if (withTests) {
    if (!existsSync(join(staging, "index.mjs"))) return { ok: false, dir: work, reason: "the transpiler wrote no unit-test runner (index.mjs)" };
    // apps/ is flat: the runner imports the test modules beside it
    const runner = readFileSync(join(staging, "index.mjs"), "utf8");
    writeFileSync(join(apps, "index.mjs"), folders ? npm.flatRunner(runner) : runner);
  }
  rmSync(staging, { recursive: true, force: true });
  return { ok: true, dir: work, apps, runtimeDir: rt.dir, version: rt.version, modules, mcp: mcp.dir };
}

/** Serve a build on 127.0.0.1:`port` in a child process (host.mjs).
 *  Resolves { url, stop, log }. */
export function startBackend({ build, port }) {
  return new Promise((resolveStart, reject) => {
    const child = spawn(process.execPath, [join(HERE, "host.mjs"), build.runtimeDir, build.apps], {
      env: { ...process.env, PORT: String(port) },
      stdio: ["ignore", "pipe", "pipe"],
    });
    const log = [];
    let started = false;
    const onData = (d) => {
      for (const line of String(d).split("\n")) {
        if (!line) continue;
        log.push(line);
        if (!started && line.startsWith("Listening on")) {
          started = true;
          resolveStart({
            url: `http://127.0.0.1:${port}/`,
            log,
            stop: () => new Promise((done) => {
              if (child.exitCode !== null) return done();
              child.once("exit", () => done());
              child.kill();
            }),
          });
        }
      }
    };
    child.stdout.on("data", onData);
    child.stderr.on("data", onData);
    child.once("exit", (code) => {
      if (!started) reject(new Error(`the backend exited ${code} before it listened:\n${log.slice(-30).join("\n")}`));
    });
  });
}

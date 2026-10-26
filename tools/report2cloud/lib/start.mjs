// The share of the converted reports that starts in the transpiled runtime -
// a refusal-free conversion is a claim, a first screen is the proof.
//
// The converted classes of a corpus are checked, built and started together,
// the way the runtime test (test/runtime) runs the reports of its own corpus:
//
//   check  the syntax check of the transpile (abaplint, version open-abap,
//          check_syntax / unknown_types / structure / parser_error) over the
//          classes with src/01, the DDIC stubs, the package's
//          downport and open-abap-core - and the dependencies of each report
//          (lib/deps.mjs). A dependency with an error is left out and the
//          classes are checked again without it, to a fixed point: a report
//          of the web reads its repository's classes and the SAP DDIC, of
//          which a sandbox has what the clone holds and the stubs.
//   build  one transpile of what passed; an object the transpiler stops at is
//          left out with the reports that need it, and again. The boot loads
//          the modules tolerantly: a class constructor that throws takes its
//          own module out, not the backend.
//   start  every app started through the JSON protocol of the frontend (the
//          app client of the MCP server), its first screen within a time.
//   browser (with browser) every app that started, as the real app in
//          headless Chromium - UI5 boots, renders, Execute runs it, no page
//          error (lib/browser.mjs).
//
// Each report ends in one stage; the funnel and the first error of each are
// what web.mjs --start writes into the job summary.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { basename, join } from "node:path";
import abaplint from "@abaplint/core";
import { REPO } from "./gate.mjs";

const CHECK = ["check_syntax", "unknown_types", "structure", "parser_error"];

// what the transpiler cannot transpile and stops without naming a file for
const UNSUPPORTED = [
  [/^\s*raise\s+resumable\b/im, "RAISE RESUMABLE"],
  // REF #( ) is, REF type( ) with a type is not - "transpiler: REF # todo1"
  [/\bref\s+(?!#)[a-z_][\w/=>-]*\s*\(/i, "REF type( )"],
  // LET <fs> = ... - "LetTranspiler, Expected Field"
  [/\blet\s+<[\w]+>\s*=/i, "LET with a field symbol"],
  // VALUE t( ( LINES OF itab ) ) - "unknown ValueBodyLines"
  [/\(\s*lines\s+of\s/i, "( LINES OF ) in a VALUE body"],
];

const objectOf = (file) => file.split(".")[0];

function sources(dirs) {
  const out = [];
  const walk = (p) => {
    let st;
    try {
      st = statSync(p);
    } catch {
      return;
    }
    if (st.isDirectory()) {
      for (const e of readdirSync(p)) walk(join(p, e));
      return;
    }
    if (/\.(abap|xml)$/.test(p) && !/testclasses/.test(p)) out.push(new abaplint.MemoryFile(basename(p), readFileSync(p, "utf8")));
  };
  for (const d of dirs) walk(d);
  return out;
}

/** the classes of `classes` (object names) that pass the syntax check of the
 *  transpile with the files left - and those files. errors: class -> first error */
export function check(files, classes, { dirs }) {
  const base = sources(dirs);
  const errors = new Map();
  let left = { ...files };
  for (let round = 0; round < 10; round++) {
    const reg = new abaplint.Registry(new abaplint.Config(JSON.stringify({
      global: { files: "/**/*.*" },
      syntax: { version: "open-abap", errorNamespace: "." },
      rules: { check_syntax: true, unknown_types: true, structure: true },
    })));
    for (const f of base) reg.addFile(f);
    for (const [n, t] of Object.entries(left)) reg.addFile(new abaplint.MemoryFile(n, t));
    reg.parse();
    const bad = new Set();
    for (const name of new Set(Object.keys(left).map(objectOf))) {
      const obj = reg.getObject("CLAS", name.toUpperCase()) ?? reg.getObject("INTF", name.toUpperCase());
      if (!obj) continue;
      const issue = reg.findIssuesObject(obj).find((i) => CHECK.includes(i.getKey()));
      if (!issue) continue;
      bad.add(name);
      if (classes.has(name) && !errors.has(name)) errors.set(name, `${issue.getKey()}: ${issue.getMessage()}`);
    }
    if (!bad.size) break;
    left = Object.fromEntries(Object.entries(left).filter(([n]) => !bad.has(objectOf(n))));
  }
  const kept = new Set(Object.keys(left).map(objectOf));
  for (const c of classes) if (!kept.has(c) && !errors.has(c)) errors.set(c, "a dependency it needs does not pass the check");
  return { ok: [...classes].filter((c) => !errors.has(c)), errors, files: left };
}

/** what a first error is about, without the names of one report */
export const kindOf = (message) => String(message)
  .replace(/<[^>]+>|&nbsp;|&#39;/g, " ")
  .replace(/\s+at\s.*$/s, "")
  .replace(/"[^"]*"|'[^']*'/g, "…")
  .replace(/\b[zy]\w*_\w*\b/gi, "…")
  .replace(/\s+/g, " ")
  .trim()
  .slice(0, 110);

/**
 * Check, build and start the converted reports `rows` - each { file, files,
 * deps: { name: text } } - with the test backend (test/runtime/backend.mjs).
 * Resolves { stages: [{ file, cls, stage, ok, error? }], funnel } or { error }.
 */
export async function startAll(rows, { ddic, port = 4499, timeoutMs = 60_000, browser = false, onLine = () => {} } = {}) {
  const backend = await import("../test/runtime/backend.mjs");
  const dirs = await backend.runtimeSources();
  if (dirs.error) return { error: dirs.error };
  const classOf = (r) => objectOf(Object.keys(r.files).find((k) => k.endsWith(".clas.abap")));
  const files = {};
  const deps = {};
  for (const r of rows) {
    Object.assign(files, r.files);
    for (const [n, t] of Object.entries(r.deps ?? {})) if (!(n in files)) deps[n] = t;
  }
  const classes = new Set(rows.map(classOf));
  const stage = new Map();   // class -> { stage, ok, error }

  onLine(`start: the syntax check of ${classes.size} classes`);
  const checked = check({ ...deps, ...files }, classes, { dirs: [join(REPO, "src", "01"), ddic, dirs.downport, dirs.core] });
  for (const [c, e] of checked.errors) stage.set(c, { stage: "check", ok: false, error: e });

  // the classes that pass, the dependencies of their reports, nothing the
  // transpiler cannot take
  const build = {};
  const needs = new Map(rows.map((r) => [classOf(r), Object.keys(r.deps ?? {}).map(objectOf)]));
  for (const r of rows) {
    const c = classOf(r);
    if (stage.has(c)) continue;
    for (const [k, v] of Object.entries(r.files)) build[k] = v;
    for (const d of Object.keys(r.deps ?? {})) if (d in checked.files) build[d] = checked.files[d];
  }
  const drop = (obj, why) => {
    for (const f of Object.keys(build)) if (objectOf(f) === obj) delete build[f];
    for (const [c, ds] of needs) {
      if ((c === obj || ds.includes(obj)) && !stage.has(c)) {
        stage.set(c, { stage: "build", ok: false, error: c === obj ? why : `a dependency does not build: ${why}` });
        for (const f of Object.keys(build)) if (objectOf(f) === c) delete build[f];
      }
    }
  };
  for (const [k, v] of Object.entries(build)) {
    const hit = UNSUPPORTED.find(([re]) => re.test(v));
    if (hit) drop(objectOf(k), `${hit[1]} - the transpiler has no counterpart`);
  }

  let built;
  for (let round = 0; round < 15; round++) {
    const log = [];
    onLine(`start: build ${new Set(Object.keys(build).map(objectOf)).size} objects`);
    built = await backend.buildBackend({ files: build, ddic, tolerant: true, onLine: (l) => log.push(l) });
    if (built.ok) break;
    const text = `${built.reason}\n${log.join("\n")}`;
    const named = new Map();
    for (const m of text.matchAll(/^(?:Error: )?([^\n]*?), ([a-z0-9_#]+)\.(?:clas|intf)\.[a-z_.]*abap\b/gm)) named.set(m[2], m[1].trim());
    for (const m of text.matchAll(/Type of ([A-Z0-9_/]+)-\S+ is VoidType[^\n]*/g)) named.set(m[1].toLowerCase().replace(/\//g, "#"), m[0]);
    if (!named.size) break;
    for (const [obj, why] of named) drop(obj, `the transpiler: ${why}`);
  }
  const apps = [...classes].filter((c) => !stage.has(c));
  if (!built?.ok) {
    for (const c of apps) stage.set(c, { stage: "build", ok: false, error: `the build failed: ${built?.reason}` });
  } else {
    let be = await backend.startBackend({ build: built, port });
    const { createDriver } = await import("../test/runtime/driver.mjs");
    const driver = () => createDriver({ mcp: backend.resolveMcpServer().dir, url: be.url });
    let d = await driver();
    // an app that takes the backend down fails, the backend starts again
    // for the next one
    const revive = async () => {
      if (be.alive()) return undefined;
      const why = `the backend exited: ${be.log.slice(-3).join(" / ").slice(0, 200)}`;
      be = await backend.startBackend({ build: built, port });
      d = await driver();
      return why;
    };
    const within = (p) => Promise.race([p, new Promise((_, rej) => setTimeout(() => rej(new Error("no first screen within the time")), timeoutMs))]);
    onLine(`start: ${apps.length} apps`);
    for (const c of apps) {
      try {
        await within(d.start(c));
        stage.set(c, { stage: "start", ok: true });
      } catch (e) {
        stage.set(c, { stage: "start", ok: false, error: String(e?.message ?? e) });
      }
      const died = await revive();
      if (died) stage.set(c, { stage: "start", ok: false, error: died });
    }
    // the apps that started, in the browser: the UI5 frontend boots them,
    // renders and runs them (lib/browser.mjs)
    if (browser) {
      const { browserRun } = await import("./browser.mjs");
      const ran = apps.filter((c) => stage.get(c)?.ok);
      onLine(`start: ${ran.length} apps in the browser`);
      const after = async (row) => {
        const died = await revive();
        if (died) row.errors.unshift(died);
      };
      for (const r of await browserRun(ran, { url: be.url, after, onLine })) {
        if (!r.ok) stage.set(r.cls, { stage: "browser", ok: false, error: r.errors[0] });
      }
    }
    await be.stop();
    if (built.dir && !process.env.REPORT2CLOUD_RUNTIME_KEEP) {
      const { rmSync } = await import("node:fs");
      rmSync(built.dir, { recursive: true, force: true });
    }
  }
  const stages = rows.map((r) => ({ file: r.file, cls: classOf(r), ...stage.get(classOf(r)) }));
  const count = (s) => stages.filter((x) => x.stage === s && !x.ok).length;
  const started = stages.filter((x) => x.ok || x.stage === "browser").length;
  return {
    stages,
    funnel: {
      converted: rows.length,
      checked: rows.length - count("check"),
      built: rows.length - count("check") - count("build"),
      started,
      ...(browser ? { browser: stages.filter((x) => x.ok).length } : {}),
    },
  };
}

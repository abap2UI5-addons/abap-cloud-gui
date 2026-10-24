#!/usr/bin/env node
// report2cloud coverage - how much of a folder of classic reports converts.
//
//   node tools/report2cloud/coverage.mjs <dir> [<dir> ...] [--includes dir] [--json file]
//
// Converts every report under the folders (a .prog.abap with a REPORT or
// PROGRAM statement; the others are includes, inlined into the reports that
// name them) and answers the numbers that say where the converter stands on
// THAT code base rather than on its own corpus: how many convert, how many
// are refused and for which reasons, which objects the migration reports
// name as unreleased on ABAP Cloud, and what the TODOs are about - each
// ranked by the number of reports it touches, so the next construct to map
// is the top line. Nothing is written beside the optional --json file; the
// classes stay in memory. Exit code 0 whatever the numbers - a measurement,
// not a gate.
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { convert, defaultClassName } from "./lib/convert.mjs";
import { includesFrom, inlineIncludes } from "./lib/includes.mjs";
import { dependenciesOf } from "./lib/deps.mjs";
import { parseTextpool } from "./lib/textpool.mjs";
import { refusalOf } from "./lib/refusals.mjs";

const USAGE = `usage: node tools/report2cloud/coverage.mjs <dir> [<dir> ...] [--includes dir] [--json file]`;

function args(argv) {
  const opts = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--help" || a === "-h") opts.help = true;
    else if (a === "--includes" || a === "--json") {
      if (argv[i + 1] === undefined) throw new Error(`${a} needs a value`);
      opts[a.slice(2)] = argv[++i];
    } else if (a.startsWith("--")) throw new Error(`unknown option ${a}`);
    else opts._.push(a);
  }
  return opts;
}

/** every .prog.abap under dir, recursively */
export function programs(dir, out = []) {
  for (const name of readdirSync(dir).sort()) {
    if (name === ".git") continue;
    const path = join(dir, name);
    if (statSync(path).isDirectory()) programs(path, out);
    else if (name.endsWith(".prog.abap")) out.push(path);
  }
  return out;
}

export const isReport = (source) => /^\s*(REPORT|PROGRAM)\b/im.test(source);

// A refusal's reason without what is particular to one report - the name
// in quotes, a number - so the same reason counts as one line.
const reasonOf = (message) => message.split(" - ")[0].replace(/'[^']*'/g, "'…'").replace(/`[^`]*`/g, "`…`").replace(/\b\d+\b/g, "n").trim();
const todoOf = (message) => message.replace(/'[^']*'/g, "'…'").replace(/`[^`]*`/g, "`…`").replace(/\b[A-Z][A-Z0-9_/]{2,}\b/g, "…").replace(/(?:…, )+…/g, "…").replace(/\b\d+\b/g, "n").trim();

/** the coverage of the reports in `files`; read(name) answers an include,
 *  deps is the dependency index of their repository (lib/deps.mjs),
 *  className(file) names the class (default: zcl_ + the report name), and
 *  with keep the generated files of every converted report are in its row,
 *  and the files of the dependencies it reads (deps: { name: text }) */
export function coverage(files, { read, className, keep = false, deps } = {}) {
  const rows = [];
  for (const file of files) {
    const raw = readFileSync(file, "utf8");
    if (!isReport(raw)) continue;
    const dir = dirname(file);
    const includes = inlineIncludes(raw, { file, read: read ?? includesFrom([dir]) });
    const xml = file.replace(/\.abap$/i, ".xml");
    let textpool;
    try {
      textpool = parseTextpool(readFileSync(xml, "utf8"));
    } catch {
      textpool = undefined;
    }
    const m = /^(.+)\.prog\.abap$/i.exec(basename(file));
    let result;
    const needs = deps ? dependenciesOf(includes.source, deps) : undefined;
    try {
      const reader = read ?? includesFrom([dir]);
      result = convert(includes.source, {
        file, programName: m ? m[1].replace(/#/g, "/") : undefined, textpool, origin: includes.origin,
        className: className?.(file),
        deps: needs,
        classFor: (program) => (reader(program) !== undefined ? defaultClassName(program) : undefined),
      });
    } catch (e) {
      rows.push({ file, crashed: String(e?.message ?? e) });
      continue;
    }
    rows.push({
      file,
      ok: result.ok,
      // ranked by the entry of the catalogue - one line per kind of refusal,
      // with the reason of the first report that has it
      refusals: result.refusals.map((r) => {
        const e = refusalOf(r.message);
        return e ? `${e.title} [${e.id}]` : reasonOf(r.message);
      }),
      todos: result.todos.map((t) => todoOf(t.message)),
      release: result.release.map((r) => `${r.kind} ${r.name}`),
      mapped: result.mapped.length,
      includes: includes.included.length,
      missing: includes.missing,
      ...(keep && result.ok ? { files: result.files, deps: Object.fromEntries((needs ?? []).map((d) => [d.name, d.text])) } : {}),
    });
  }
  return rows;
}

/** the counts of `key` over the rows: how many reports carry it at least once */
export function ranked(rows, key) {
  const byReports = new Map();
  for (const row of rows) for (const k of new Set(row[key] ?? [])) byReports.set(k, (byReports.get(k) ?? 0) + 1);
  return [...byReports].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
}

const pct = (n, of) => (of ? `${Math.round((n / of) * 100)} %` : "-");

export function summary(rows) {
  const lines = [];
  const converted = rows.filter((r) => r.ok);
  const refused = rows.filter((r) => r.ok === false);
  const crashed = rows.filter((r) => r.crashed);
  lines.push(`report2cloud coverage: ${rows.length} report(s) - ${converted.length} converted (${pct(converted.length, rows.length)}), ` +
    `${refused.length} refused${crashed.length ? `, ${crashed.length} crashed the converter` : ""}`);
  const withIncludes = rows.filter((r) => r.includes > 0).length;
  const missing = ranked(rows, "missing");
  if (withIncludes || missing.length) {
    lines.push(`  includes: ${withIncludes} report(s) with includes inlined${missing.length ? `, ${missing.length} include(s) not found: ${missing.slice(0, 5).map(([n]) => n).join(", ")}${missing.length > 5 ? ", …" : ""}` : ""}`);
  }
  const table = (title, list, max = 15) => {
    if (!list.length) return;
    lines.push("", `${title} (reports affected)`);
    for (const [k, n] of list.slice(0, max)) lines.push(`  ${String(n).padStart(5)}  ${pct(n, rows.length).padStart(5)}  ${k}`);
    if (list.length > max) lines.push(`  … and ${list.length - max} more`);
  };
  table("Refused - the next constructs to map", ranked(refused, "refusals"));
  table("Objects to check for ABAP Cloud", ranked(converted, "release"));
  table("TODOs left in the classes", ranked(converted, "todos"), 10);
  for (const c of crashed) lines.push("", `crashed: ${c.file} - ${c.crashed}`);
  return lines.join("\n");
}

async function main() {
  let opts;
  try {
    opts = args(process.argv.slice(2));
  } catch (e) {
    console.error(`${e.message}\n\n${USAGE}`);
    return 1;
  }
  if (opts.help || opts._.length === 0) {
    console.log(USAGE);
    return opts.help ? 0 : 1;
  }
  const dirs = opts._.map((d) => resolve(d));
  const files = dirs.flatMap((d) => programs(d));
  const read = includesFrom([...dirs.flatMap((d) => programs(d)).map(dirname), ...(opts.includes ? [resolve(opts.includes)] : [])]);
  const rows = coverage(files, { read });
  console.log(summary(rows));
  if (opts.json) {
    writeFileSync(resolve(opts.json), `${rows.map((r) => JSON.stringify(r)).join("\n")}\n`);
    console.log(`\n${rows.length} line(s) written to ${resolve(opts.json)}`);
  }
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === new URL(import.meta.url).pathname) {
  process.exitCode = await main();
}

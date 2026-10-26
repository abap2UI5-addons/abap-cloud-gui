#!/usr/bin/env node
// report2cloud package - a whole package of classic reports in one run.
//
//   node tools/report2cloud/package.mjs <dir> [<dir> ...] --out <dir> [--includes dir] [--wrappers]
//
// Converts every report under the folders (as coverage.mjs: a .prog.abap
// with a REPORT or PROGRAM statement, the includes inlined), writes the
// classes of the converted ones into --out, and estate.md beside them: the
// reports in the order to migrate them - a report after the reports it
// calls with SUBMIT or PERFORM ... IN PROGRAM -, the calls as a graph, what
// the estate calls outside of it, and the refusals ranked across the
// estate. A SUBMIT of a report of the estate starts its class. Exit code 0
// whatever the numbers; 1: wrong call.
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { defaultClassName } from "./lib/convert.mjs";
import { includesFrom, inlineIncludes } from "./lib/includes.mjs";
import { callsOf, estateGraph, estateMarkdown } from "./lib/estate.mjs";
import { coverage, isReport, programs, summary } from "./coverage.mjs";

const USAGE = "usage: node tools/report2cloud/package.mjs <dir> [<dir> ...] --out <dir> [--includes dir] [--wrappers]";

function args(argv) {
  const opts = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--help" || a === "-h") opts.help = true;
    else if (a === "--wrappers") opts.wrappers = true;
    else if (a === "--out" || a === "--includes") {
      if (argv[i + 1] === undefined) throw new Error(`${a} needs a value`);
      opts[a.slice(2)] = argv[++i];
    } else if (a.startsWith("--")) throw new Error(`unknown option ${a}`);
    else opts._.push(a);
  }
  return opts;
}

const nameOf = (file) => (/^(.+)\.prog\.abap$/i.exec(basename(file))?.[1] ?? basename(file)).replace(/#/g, "/").toUpperCase();

/** the run over the files: { rows, graph, markdown } - and the classes in
 *  out, when it is given */
export function packageRun(files, { read, out, wrappers = false } = {}) {
  const reportFiles = files.filter((f) => isReport(readFileSync(f, "utf8")));
  const rows = coverage(reportFiles, { read, keep: true, wrappers });
  const reports = rows.map((row) => {
    const source = inlineIncludes(readFileSync(row.file, "utf8"), { file: row.file, read: read ?? includesFrom([dirname(row.file)]) }).source;
    const name = nameOf(row.file);
    return { name, class: defaultClassName(name.toLowerCase()), ok: row.ok === true, calls: callsOf(source), refusals: row.refusals ?? [] };
  });
  const graph = estateGraph(reports);
  const markdown = estateMarkdown(graph, { rows: reports, summary: summary(rows) });
  if (out) {
    mkdirSync(out, { recursive: true });
    for (const row of rows) for (const [name, text] of Object.entries(row.files ?? {})) writeFileSync(join(out, name), text);
    writeFileSync(join(out, "estate.md"), markdown);
  }
  return { rows, graph, markdown };
}

async function main() {
  let opts;
  try {
    opts = args(process.argv.slice(2));
  } catch (e) {
    console.error(`${e.message}\n\n${USAGE}`);
    return 1;
  }
  if (opts.help || opts._.length === 0 || !opts.out) {
    console.log(USAGE);
    return opts.help ? 0 : 1;
  }
  const dirs = opts._.map((d) => resolve(d));
  const files = dirs.flatMap((d) => programs(d));
  const read = includesFrom([...files.map(dirname), ...(opts.includes ? [resolve(opts.includes)] : [])]);
  const { graph } = packageRun(files, { read, out: resolve(opts.out), wrappers: opts.wrappers === true });
  const ok = graph.nodes.filter((n) => n.ok).length;
  console.log(`report2cloud package: ${graph.nodes.length} report(s), ${ok} converted - the classes and estate.md in ${resolve(opts.out)}`);
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === new URL(import.meta.url).pathname) {
  process.exitCode = await main();
}

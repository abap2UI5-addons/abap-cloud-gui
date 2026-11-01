#!/usr/bin/env node
// report2UI5 package - a whole package of classic reports in one run.
//
//   node tools/report2ui5/package.mjs <dir> [<dir> ...] --out <dir> [--includes dir]
//
// Converts every report under the folders (as coverage.mjs: a .prog.abap
// with a REPORT or PROGRAM statement, the includes inlined), writes the
// classes of the converted ones into --out, and summary.md beside them:
// how many converted, and the refusals ranked across the package. Exit code
// 0 whatever the numbers; 1: wrong call.
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { includesFrom } from "./lib/includes-fs.mjs";
import { coverage, isReport, programs, summary } from "./coverage.mjs";

const USAGE = "usage: node tools/report2ui5/package.mjs <dir> [<dir> ...] --out <dir> [--includes dir]";

function args(argv) {
  const opts = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--help" || a === "-h") opts.help = true;
    else if (a === "--out" || a === "--includes") {
      if (argv[i + 1] === undefined) throw new Error(`${a} needs a value`);
      opts[a.slice(2)] = argv[++i];
    } else if (a.startsWith("--")) throw new Error(`unknown option ${a}`);
    else opts._.push(a);
  }
  return opts;
}

/** the run over the files: { rows, markdown } - and the classes and
 *  summary.md in out, when it is given */
export function packageRun(files, { read, out } = {}) {
  const reportFiles = files.filter((f) => isReport(readFileSync(f, "utf8")));
  const rows = coverage(reportFiles, { read, keep: true });
  const markdown = ["# report2UI5 package", "", "```", summary(rows), "```", ""].join("\n");
  if (out) {
    mkdirSync(out, { recursive: true });
    for (const row of rows) for (const [name, text] of Object.entries(row.files ?? {})) writeFileSync(join(out, name), text);
    writeFileSync(join(out, "summary.md"), markdown);
  }
  return { rows, markdown };
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
  const { rows } = packageRun(files, { read, out: resolve(opts.out) });
  const ok = rows.filter((r) => r.ok).length;
  console.log(`report2UI5 package: ${rows.length} report(s), ${ok} converted - the classes and summary.md in ${resolve(opts.out)}`);
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === new URL(import.meta.url).pathname) {
  process.exitCode = await main();
}

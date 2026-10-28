#!/usr/bin/env node
// report2cloud - a classic ABAP report as an abap-cloud-gui report class.
//
//   node tools/report2cloud/cli.mjs zreport.prog.abap [--class zcl_name] [--out dir]
//        [--texts zreport.prog.xml] [--includes dir] [--check] [--ddic dir] [--partial] [--wrappers] [--successors]
//
// Writes <class>.clas.abap, <class>.clas.xml (abapGit format), the local
// types and classes of the report as .clas.locals_def/_imp.abap, and the
// migration report <class>.migration.md. The text pool is read from
// --texts, or from the .prog.xml beside the source when there is one.
//
// Exit code 0: converted. 2: refused - every statement that cannot be mapped
// is printed as file:row:col - reason, the migration report lists them, and
// no class is written (--partial writes the draft anyway, with the refused
// statements marked). 1: wrong call.
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { convert, defaultClassName } from "./lib/convert.mjs";
import { includesFrom, inlineIncludes } from "./lib/includes.mjs";
import { dependenciesOf, dependencyIndex } from "./lib/deps.mjs";
import { parseTextpool } from "./lib/textpool.mjs";
import { migrationReport } from "./lib/report.mjs";

const USAGE = `usage: node tools/report2cloud/cli.mjs <report.prog.abap> [options]

  --class <name>   name of the generated class (default: zcl_ + the report name)
  --out <dir>      output folder (default: the current folder)
  --texts <file>   the report's .prog.xml with its text pool (default: beside the source)
  --includes <dir> where the report's INCLUDEs are, as abapGit writes them: <include>.prog.abap
                   (default: beside the source; the includes are inlined before the conversion)
  --deps <dir>     the classes, interfaces and DDIC objects of the report's repository, as abapGit
                   writes them - they type what the report reads of them (default: the abapGit
                   repository the report is in, the folder above it with an .abapgit.xml)
  --report <file>  where to write the migration report (default: <out>/<class>.migration.md)
  --check          lint the class with abaplint - v750 and ABAP Cloud, in a scratch
                   copy of this repository (needs git and network for the dependencies)
  --ddic <dir>     abapGit DDIC objects to resolve on-premise tables during --check
  --atc <file>     the ATC findings of the report as the system found them (the worklist XML
                   ADT exports, or a CSV with line;priority;check;message): the migration
                   report says for each what the conversion did on its line
  --partial        write the class even when statements are refused
  --wrappers       a CALL FUNCTION the converter has no counterpart for calls a method of a
                   wrapper class, written beside the class: <class>_fmw, to type and release
  --successors     a SELECT of a table with a released successor whose columns map one to one
                   (the flight model, T001, T005T, MAKT) reads the successor, the columns under
                   their old names
  --help           this text`;

function args(argv) {
  const opts = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--help" || a === "-h") opts.help = true;
    else if (a === "--check") opts.check = true;
    else if (a === "--partial") opts.partial = true;
    else if (a === "--wrappers") opts.wrappers = true;
    else if (a === "--successors") opts.successors = true;
    else if (["--class", "--out", "--texts", "--includes", "--report", "--ddic", "--deps", "--atc"].includes(a)) {
      if (argv[i + 1] === undefined) throw new Error(`${a} needs a value`);
      opts[a.slice(2)] = argv[++i];
    } else if (a.startsWith("--")) throw new Error(`unknown option ${a}`);
    else opts._.push(a);
  }
  return opts;
}

/** the abapGit repository of a file - its starting folder (STARTING_FOLDER
 *  of .abapgit.xml), or the git repository it is in; undefined when it is
 *  in none */
function repositoryOf(file) {
  for (let dir = dirname(resolve(file)); ; dir = dirname(dir)) {
    const abapgit = join(dir, ".abapgit.xml");
    if (existsSync(abapgit)) {
      const start = /<STARTING_FOLDER>([^<]*)<\/STARTING_FOLDER>/.exec(readFileSync(abapgit, "utf8"))?.[1].replace(/^\/+|\/+$/g, "");
      return start ? join(dir, start) : dir;
    }
    if (existsSync(join(dir, ".git"))) return dir;
    if (dirname(dir) === dir) return undefined;
  }
}

async function main() {
  let opts;
  try {
    opts = args(process.argv.slice(2));
  } catch (e) {
    console.error(`${e.message}\n\n${USAGE}`);
    return 1;
  }
  if (opts.help) {
    console.log(USAGE);
    return 0;
  }
  if (opts._.length !== 1) {
    console.error(USAGE);
    return 1;
  }
  const file = opts._[0];
  if (!existsSync(file)) {
    console.error(`${file}: no such file`);
    return 1;
  }
  const dirs = [dirname(file), ...(opts.includes ? [resolve(opts.includes)] : [])];
  const read = includesFrom(dirs);
  const includes = inlineIncludes(readFileSync(file, "utf8"), { file, read });
  const source = includes.source;
  const sibling = file.replace(/\.abap$/i, ".xml");
  const texts = opts.texts ?? (sibling !== file && existsSync(sibling) ? sibling : undefined);
  const textpool = texts ? parseTextpool(readFileSync(texts, "utf8")) : undefined;
  const m = /^(.+)\.prog\.abap$/i.exec(basename(file));
  const depsDir = opts.deps ? resolve(opts.deps) : repositoryOf(file);
  const result = convert(source, {
    deps: depsDir ? dependenciesOf(source, dependencyIndex([depsDir])) : undefined,
    file,
    className: opts.class,
    programName: m ? m[1].replace(/#/g, "/") : undefined,
    textpool,
    origin: includes.origin,
    wrappers: opts.wrappers === true,
    successors: opts.successors === true,
    // a report beside the input (or under --includes) is one to convert as
    // well - a SUBMIT of it starts the class report2cloud names it
    classFor: (program) => (read(program) !== undefined ? defaultClassName(program) : undefined),
  });

  // a position in an include names the include's file, beside the report
  const where = (row, col) => {
    const o = includes.origin(row);
    return `${o.file === basename(file) ? file : join(dirname(file), o.file)}:${o.row}:${col}`;
  };
  for (const r of result.refusals) console.error(`${where(r.row, r.col)} - ${r.message}`);

  const out = resolve(opts.out ?? ".");
  mkdirSync(out, { recursive: true });
  const write = !result.ok && opts.partial ? result.draft : result.files;
  for (const [name, text] of Object.entries(write)) writeFileSync(join(out, name), text);

  let lint;
  if (opts.check && Object.keys(write).length) {
    const { lint: run } = await import("./lib/gate.mjs");
    const ddic = opts.ddic ? resolve(opts.ddic) : undefined;
    lint = {
      v750: run({ files: write, target: "v750", ddic, naming: false }).generated,
      cloud: run({ files: write, target: "cloud", naming: false }).generated,
    };
  }

  const reportFile = opts.report ? resolve(opts.report) : join(out, `${result.className}.migration.md`);
  mkdirSync(dirname(reportFile), { recursive: true });
  let atc;
  if (opts.atc) {
    const { parseAtc, atcStates } = await import("./lib/atc.mjs");
    atc = atcStates(parseAtc(readFileSync(resolve(opts.atc), "utf8")), result, { includes });
  }
  writeFileSync(reportFile, migrationReport(result, { source: file, texts, lint, atc, includes }));

  const written = Object.keys(write).sort();
  if (!result.ok) {
    console.error(`${result.className}: refused - ${result.refusals.length} statement(s) cannot be mapped` +
      `${opts.partial ? `, draft written to ${out}` : ", no class written"}; report: ${reportFile}`);
    return 2;
  }
  console.log(`${result.className}: ${result.mapped.length} constructs mapped, ${result.todos.length} TODO(s), ` +
    `${result.release.length} object(s) to check for ABAP Cloud` +
    `${includes.included.length ? `, ${includes.included.length} include(s) inlined` : ""}` +
    `${lint ? `, abaplint v750 ${lint.v750.length} / cloud ${lint.cloud.length} finding(s)` : ""}`);
  console.log(`  ${written.map((f) => join(out, f)).join("\n  ")}\n  ${reportFile}`);
  return 0;
}

process.exitCode = await main();

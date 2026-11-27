// A whole package in memory: the files of an abapGit package as { path:
// text } - what the site gets from a dropped zip, what a CLI reads from a
// folder - every report converted with its includes and its text pool,
// its migration report beside it, and a summary: how many converted, the
// refusals ranked. Nothing is
// read from disk or written to it here; package.mjs (the CLI) does that
// around coverage( ), this is the same run for a caller that has the texts.
import { classFileBase, convert, defaultClassName } from "./convert.mjs";
import { includeFileName, inlineIncludes } from "./includes.mjs";
import { migrationReport } from "./report.mjs";
import { parseTextpool } from "./textpool.mjs";
import { refusalOf } from "./refusals.mjs";

const base = (path) => path.split("/").pop();
const lc = (s) => String(s).toLowerCase();
const isReport = (source) => /^\s*(REPORT|PROGRAM)\b/im.test(source);
const programOf = (file) => (/^(.+)\.prog\.abap$/i.exec(base(file))?.[1] ?? base(file)).replace(/#/g, "/");

/**
 * The class names of a package, one per report, made unique: two reports
 * whose names give the same class - ZREPORT and Z_REPORT are both
 * zcl_report, two long names are cut at 30 characters alike - would write
 * the same files, the second over the first. The first keeps the name, the
 * next one gets a number at its end (zcl_report2), never a name another
 * report of the package has. wanted: the names, in the order of the
 * reports; answers the names in that order.
 */
export function uniqueClassNames(wanted) {
  const names = wanted.map((n) => String(n).toLowerCase());
  const all = new Set(names);
  const taken = new Set();
  return names.map((name) => {
    let to = name;
    for (let n = 2; taken.has(to); n++) {
      to = `${name.slice(0, 30 - String(n).length)}${n}`;
      if (all.has(to) && to !== name) to = name;
    }
    taken.add(to);
    return to;
  });
}

/** the counts summary( ) of coverage.mjs prints - without reading the rows
 *  from disk */
function summaryText(rows) {
  const converted = rows.filter((r) => r.ok).length;
  const refused = rows.filter((r) => !r.ok).length;
  const pct = rows.length ? `${Math.round((converted / rows.length) * 100)} %` : "-";
  const byKind = new Map();
  for (const r of rows) for (const k of new Set(r.refusalKinds)) byKind.set(k, (byKind.get(k) ?? 0) + 1);
  const lines = [`report2UI5 coverage: ${rows.length} report(s) - ${converted} converted (${pct}), ${refused} refused`];
  const ranked = [...byKind].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
  if (ranked.length) {
    lines.push("", "Refused for (reports affected)");
    for (const [k, n] of ranked.slice(0, 15)) lines.push(`  ${String(n).padStart(5)}  ${k}`);
  }
  const renamed = rows.filter((r) => r.renamedFrom);
  if (renamed.length) {
    lines.push("", "Class names taken by another report of the package - numbered");
    for (const r of renamed) lines.push(`  ${r.name} -> ${r.className} (${r.renamedFrom} is ${r.renamedFor}'s)`);
  }
  return lines.join("\n");
}

/**
 * Converts the reports among files - { path: text }; a .prog.abap with a
 * REPORT or PROGRAM statement is a report, the other .prog.abap files are
 * its includes, a .prog.xml beside a report its text pool. Answers
 *   rows    - one per report: { file, name, className, ok, refusals, todos,
 *             files, report (the migration report) }
 *   summary - the counts and the refusals ranked, as text
 *   output  - every file to take along: the classes, the migration
 *             reports, summary.md
 */
export function convertPackage(files, { className } = {}) {
  const byName = new Map(Object.entries(files).map(([path, text]) => [base(path).toLowerCase(), text]));
  const read = (name) => byName.get(includeFileName(name));
  const reports = Object.entries(files)
    .filter(([path, text]) => /\.prog\.abap$/i.test(path) && isReport(text))
    .sort(([a], [b]) => a.localeCompare(b));
  const wanted = reports.map(([path]) => lc(className?.(programOf(path)) ?? defaultClassName(programOf(path).toLowerCase())));
  const unique = uniqueClassNames(wanted);
  // a SUBMIT of a report of the package starts its class - the first
  // report of that name
  const names = new Map();
  reports.forEach(([path], i) => {
    if (!names.has(programOf(path).toUpperCase())) names.set(programOf(path).toUpperCase(), unique[i]);
  });
  const classFor = (program) => names.get(String(program).toUpperCase());
  const owner = (name) => programOf(reports[wanted.indexOf(name)][0]).toUpperCase();

  const rows = [];
  for (const [i, [path, raw]] of reports.entries()) {
    const file = base(path);
    const program = programOf(path);
    const cls = unique[i];
    const renamed = cls !== wanted[i] ? { renamedFrom: wanted[i], renamedFor: owner(wanted[i]) } : {};
    const includes = inlineIncludes(raw, { file, read });
    const xml = byName.get(file.replace(/\.abap$/i, ".xml").toLowerCase());
    let textpool;
    try {
      textpool = xml ? parseTextpool(xml) : undefined;
    } catch {
      textpool = undefined;
    }
    let result;
    try {
      result = convert(includes.source, { file, programName: program, textpool, origin: includes.origin, className: cls, classFor });
    } catch (e) {
      rows.push({ file, name: program.toUpperCase(), className: cls, ...renamed, ok: false, crashed: String(e?.message ?? e), refusals: [], refusalKinds: [], todos: [], files: {}, report: "" });
      continue;
    }
    const report = migrationReport(result, { source: file, texts: xml ? file.replace(/\.abap$/i, ".xml") : undefined, includes });
    rows.push({
      file,
      name: program.toUpperCase(),
      className: result.className,
      ...renamed,
      ok: result.ok,
      refusals: result.refusals,
      refusalKinds: result.refusals.map((r) => {
        const e = refusalOf(r.message);
        return e ? `${e.title} [${e.id}]` : r.message.split(" - ")[0];
      }),
      todos: result.todos,
      files: result.ok ? result.files : {},
      report,
    });
  }

  const summary = summaryText(rows);
  const output = { "summary.md": ["# report2UI5 package", "", "```", summary, "```", ""].join("\n") };
  for (const r of rows) {
    Object.assign(output, r.files);
    if (r.report) output[`${classFileBase(r.className)}.migration.md`] = r.report;
  }
  return { rows, summary, output };
}

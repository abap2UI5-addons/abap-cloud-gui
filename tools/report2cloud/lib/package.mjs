// A whole package in memory: the files of an abapGit package as { path:
// text } - what the site gets from a dropped zip, what a CLI reads from a
// folder - every report converted with its includes and its text pool,
// its migration report beside it, and the estate: the calls between the
// reports, the order to migrate them in, the refusals ranked. Nothing is
// read from disk or written to it here; package.mjs (the CLI) does that
// around coverage( ), this is the same run for a caller that has the texts.
import { convert, defaultClassName } from "./convert.mjs";
import { includeFileName, inlineIncludes } from "./includes.mjs";
import { callsOf, estateGraph, estateMarkdown, migrationOrder } from "./estate.mjs";
import { migrationReport } from "./report.mjs";
import { parseTextpool } from "./textpool.mjs";
import { refusalOf } from "./refusals.mjs";

const base = (path) => path.split("/").pop();
const isReport = (source) => /^\s*(REPORT|PROGRAM)\b/im.test(source);
const programOf = (file) => (/^(.+)\.prog\.abap$/i.exec(base(file))?.[1] ?? base(file)).replace(/#/g, "/");

/** the counts summary( ) of coverage.mjs prints, for the estate's header -
 *  without reading the rows from disk */
function summaryText(rows) {
  const converted = rows.filter((r) => r.ok).length;
  const refused = rows.filter((r) => !r.ok).length;
  const pct = rows.length ? `${Math.round((converted / rows.length) * 100)} %` : "-";
  const byKind = new Map();
  for (const r of rows) for (const k of new Set(r.refusalKinds)) byKind.set(k, (byKind.get(k) ?? 0) + 1);
  const lines = [`report2cloud coverage: ${rows.length} report(s) - ${converted} converted (${pct}), ${refused} refused`];
  const ranked = [...byKind].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
  if (ranked.length) {
    lines.push("", "Refused for (reports affected)");
    for (const [k, n] of ranked.slice(0, 15)) lines.push(`  ${String(n).padStart(5)}  ${k}`);
  }
  return lines.join("\n");
}

/**
 * Converts the reports among files - { path: text }; a .prog.abap with a
 * REPORT or PROGRAM statement is a report, the other .prog.abap files are
 * its includes, a .prog.xml beside a report its text pool. Answers
 *   rows    - one per report: { file, name, className, ok, refusals, todos,
 *             release, files, report (the migration report) }
 *   order   - the names of the reports in the order to migrate them in
 *   estate  - the estate as Markdown
 *   output  - every file to take along: the classes, the migration
 *             reports, estate.md
 */
export function convertPackage(files, { className } = {}) {
  const byName = new Map(Object.entries(files).map(([path, text]) => [base(path).toLowerCase(), text]));
  const read = (name) => byName.get(includeFileName(name));
  const reports = Object.entries(files)
    .filter(([path, text]) => /\.prog\.abap$/i.test(path) && isReport(text))
    .sort(([a], [b]) => a.localeCompare(b));
  const names = new Map(reports.map(([path]) => [programOf(path).toUpperCase(), className?.(programOf(path)) ?? defaultClassName(programOf(path).toLowerCase())]));
  const classFor = (program) => names.get(String(program).toUpperCase());

  const rows = [];
  for (const [path, raw] of reports) {
    const file = base(path);
    const program = programOf(path);
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
      result = convert(includes.source, { file, programName: program, textpool, origin: includes.origin, className: classFor(program), classFor });
    } catch (e) {
      rows.push({ file, name: program.toUpperCase(), className: classFor(program), ok: false, crashed: String(e?.message ?? e), refusals: [], refusalKinds: [], todos: [], release: [], files: {}, report: "", calls: callsOf(includes.source) });
      continue;
    }
    const report = migrationReport(result, { source: file, texts: xml ? file.replace(/\.abap$/i, ".xml") : undefined, includes });
    rows.push({
      file,
      name: program.toUpperCase(),
      className: result.className,
      ok: result.ok,
      refusals: result.refusals,
      refusalKinds: result.refusals.map((r) => {
        const e = refusalOf(r.message);
        return e ? `${e.title} [${e.id}]` : r.message.split(" - ")[0];
      }),
      todos: result.todos,
      release: result.release,
      files: result.ok ? result.files : {},
      report,
      calls: callsOf(includes.source),
    });
  }

  const graph = estateGraph(rows.map((r) => ({ name: r.name, class: r.className, ok: r.ok, calls: r.calls, refusals: r.refusalKinds })));
  const order = migrationOrder(graph);
  const estate = estateMarkdown(graph, { rows: rows.map((r) => ({ name: r.name, class: r.className, ok: r.ok, calls: r.calls, refusals: r.refusalKinds })), summary: summaryText(rows) });
  const output = { "estate.md": estate };
  for (const r of rows) {
    Object.assign(output, r.files);
    if (r.report) output[`${r.className}.migration.md`] = r.report;
  }
  return { rows, order, estate, output };
}

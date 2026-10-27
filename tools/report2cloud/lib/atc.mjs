// The ATC findings of the classic report - what the ABAP Test Cockpit of a
// system found in it (the check variant of the cloud readiness, say) - read
// from the worklist ADT exports, and set against what the conversion did on
// each line, for the migration report:
//
//   converted   the statement of the line is mapped - the finding is gone
//               with it, the class has the statement of the right
//   refused     the statement has no counterpart - rewrite it first
//   TODO        the class has it, with a TODO to do by hand
//   to check    the line went over as it was - the finding stands, unless
//               the object it names is in the table of the release state
//
// The worklist is the XML of ADT (atcworklist:worklist, its objects and their
// atcfinding:finding with location .../source/main#start=row,col); a CSV
// with a header (line;priority;check;message, comma or semicolon, an object
// column optional) is read too.

const ATTR = /([\w:-]+)\s*=\s*"([^"]*)"/g;
const local = (name) => name.replace(/^.*:/, "");
const unescape = (s) => s.replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");

function attrs(tag) {
  const out = {};
  for (const m of tag.matchAll(ATTR)) out[local(m[1])] = unescape(m[2]);
  return out;
}

/** the object a location names: the program, or an include of it */
function objectOf(uri) {
  const m = /\/programs\/(?:programs|includes)\/([^/#?]+)/i.exec(uri ?? "");
  return m ? decodeURIComponent(m[1]).toLowerCase() : undefined;
}

/** the findings of an export - [{ object, row, col, priority, check, message }] */
export function parseAtc(text) {
  const src = String(text).replace(/^﻿/, "");
  if (/<\s*[\w-]*:?worklist\b|<\s*[\w-]*:?finding\b/i.test(src)) {
    const findings = [];
    let object;
    for (const m of src.matchAll(/<\s*([\w-]+:)?(object|finding)\b([^>]*)>/gi)) {
      const a = attrs(m[3]);
      if (m[2].toLowerCase() === "object") {
        object = (a.name ?? objectOf(a.uri) ?? "").toLowerCase() || undefined;
        continue;
      }
      const where = a.location ?? a.uri ?? "";
      const pos = /#start=(\d+)(?:,(\d+))?/.exec(where);
      findings.push({
        object: objectOf(where) ?? object,
        row: pos ? Number(pos[1]) : undefined,
        col: pos ? Number(pos[2] ?? 0) : undefined,
        priority: a.priority ? Number(a.priority) : undefined,
        check: a.checkTitle ?? a.checkId ?? "",
        message: a.messageTitle ?? a.messageId ?? "",
      });
    }
    return findings;
  }
  // a CSV with a header line
  const rows = src.split(/\r?\n/).filter((l) => l.trim());
  if (!rows.length) return [];
  const sep = rows[0].includes(";") ? ";" : ",";
  const split = (l) => l.split(sep).map((c) => c.trim().replace(/^"(.*)"$/, "$1"));
  const head = split(rows[0]).map((h) => h.toLowerCase());
  const col = (...names) => head.findIndex((h) => names.some((n) => h.includes(n)));
  const at = { row: col("line", "row", "zeile"), priority: col("prio"), check: col("check", "prüfung"), message: col("message", "meldung", "text"), object: col("object", "objekt", "program") };
  if (at.row < 0 || at.message < 0) throw new Error("the ATC findings: no worklist XML, and a CSV needs a header with a line and a message column");
  return rows.slice(1).map((l) => {
    const c = split(l);
    return {
      object: at.object >= 0 ? c[at.object].toLowerCase() || undefined : undefined,
      row: Number(c[at.row]) || undefined,
      col: 0,
      priority: at.priority >= 0 ? Number(c[at.priority]) || undefined : undefined,
      check: at.check >= 0 ? c[at.check] : "",
      message: c[at.message],
    };
  });
}

/**
 * Each finding with what the conversion did on its line. program: the name
 * of the report (its findings are of its main source); includes: what
 * lib/includes.mjs inlined - a finding in an include goes to its row in the
 * inlined source. Resolves [{ ...finding, state, detail }].
 */
export function atcStates(findings, result, { program, includes } = {}) {
  const main = String(program ?? result.programName ?? "").toLowerCase();
  // the row of the inlined source of (include, row)
  const inlined = new Map();
  if (includes?.origin) {
    const last = Math.max(0, ...result.mapped.map((m) => m.row), ...result.refusals.map((r) => r.row ?? 0), ...result.todos.map((t) => t.row ?? 0));
    for (let r = 1; r <= last + 1000; r++) {
      const o = includes.origin(r);
      if (o) inlined.set(`${o.file.replace(/\.prog\.abap$/i, "").toLowerCase()}:${o.row}`, r);
    }
  }
  const byRow = (list) => {
    const m = new Map();
    for (const x of list) if (x.row && !m.has(x.row)) m.set(x.row, x);
    return m;
  };
  const refused = byRow(result.refusals);
  const todos = byRow(result.todos);
  const mapped = byRow(result.mapped);
  return findings.map((f) => {
    let row = f.row;
    if (f.object && f.object !== main && row) row = inlined.get(`${f.object}:${f.row}`);
    if (!row) return { ...f, state: "to check", detail: f.object && f.object !== main ? `in ${f.object}, which the conversion did not inline` : "no line" };
    if (refused.has(row)) return { ...f, state: "refused", detail: refused.get(row).message };
    if (todos.has(row)) return { ...f, state: "TODO", detail: todos.get(row).message };
    if (mapped.has(row)) return { ...f, state: "converted", detail: mapped.get(row).target };
    const named = result.release.find((r) => new RegExp(`\\b${r.name.replace(/[^\w/]/g, "")}\\b`, "i").test(f.message));
    if (named) return { ...f, state: "to check", detail: `${named.kind} ${named.name} - see the release state` };
    return { ...f, state: "to check", detail: "the line went over as it was" };
  });
}

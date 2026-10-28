// The estate of a package: the reports of a folder, how they call each
// other, and the order to migrate them in. A report calls another one with
// SUBMIT, with PERFORM ... IN PROGRAM (and its short form PERFORM f(prog))
// and with CALL TRANSACTION; INCLUDEs are inlined before, they are no edge.
// What a report calls that is not in the folder is named as outside - a
// report of SAP or of another package, to check by hand.

/** the calls of a report's source: [{ kind, target, row }], the target in
 *  upper case; a SUBMIT of a variable is { kind: "SUBMIT", target: "" } */
export function callsOf(source) {
  const out = [];
  const lines = source.replace(/\r\n?/g, "\n").split("\n");
  lines.forEach((raw, i) => {
    // a comment line, the comment after a quote
    if (/^\*/.test(raw)) return;
    const line = raw.replace(/"[^'`]*$/, "");
    let m;
    // SUBMIT name, or SUBMIT (dobj) - a name known at run time only
    const submit = /\bSUBMIT\s+(\()?\s*([\w/]+)/gi;
    while ((m = submit.exec(line))) out.push({ kind: "SUBMIT", target: m[1] ? "" : m[2].toUpperCase(), row: i + 1 });
    const inProgram = /\bPERFORM\s+[\w/]+\s+IN\s+PROGRAM\s+('?)([\w/]+)\1/gi;
    while ((m = inProgram.exec(line))) out.push({ kind: "PERFORM", target: m[2].toUpperCase(), row: i + 1 });
    const short = /\bPERFORM\s+[\w/]+\(\s*([\w/]+)\s*\)/gi;
    while ((m = short.exec(line))) out.push({ kind: "PERFORM", target: m[1].toUpperCase(), row: i + 1 });
    const tcode = /\bCALL\s+TRANSACTION\s+'([\w/]+)'/gi;
    while ((m = tcode.exec(line))) out.push({ kind: "CALL TRANSACTION", target: m[1].toUpperCase(), row: i + 1 });
  });
  return out;
}

/** the graph of the estate: nodes { name, class, ok }, edges { from, to,
 *  kind, inside } - inside: the target is a report of the estate */
export function estateGraph(reports) {
  const names = new Set(reports.map((r) => r.name));
  const edges = [];
  for (const r of reports) {
    for (const c of r.calls) {
      if (!c.target) continue;
      if (edges.some((e) => e.from === r.name && e.to === c.target && e.kind === c.kind)) continue;
      edges.push({ from: r.name, to: c.target, kind: c.kind, inside: c.kind !== "CALL TRANSACTION" && names.has(c.target) });
    }
  }
  return { nodes: reports.map((r) => ({ name: r.name, class: r.class, ok: r.ok })), edges };
}

/** the order to migrate in: a report after the reports of the estate it
 *  calls - the ones nothing depends on last; a cycle keeps the order of
 *  the names */
export function migrationOrder(graph) {
  const deps = new Map(graph.nodes.map((n) => [n.name, new Set()]));
  for (const e of graph.edges) if (e.inside && e.from !== e.to) deps.get(e.from).add(e.to);
  const done = [];
  const left = new Set(graph.nodes.map((n) => n.name).sort());
  while (left.size) {
    const next = [...left].filter((n) => [...deps.get(n)].every((d) => !left.has(d)));
    const take = next.length ? next : [[...left][0]];
    for (const n of take) {
      done.push(n);
      left.delete(n);
    }
  }
  return done;
}

const mermaidId = (name) => name.replace(/[^A-Za-z0-9_]/g, "_");

/** the estate as Markdown: the reports, the graph (Mermaid), the order, the
 *  calls out of the estate */
export function estateMarkdown(graph, { title = "report2cloud estate", rows = [], summary = "" } = {}) {
  const out = [`# ${title}`, ""];
  const ok = graph.nodes.filter((n) => n.ok).length;
  out.push(`${graph.nodes.length} report(s), ${ok} converted, ${graph.nodes.length - ok} refused. ` +
    `${graph.edges.filter((e) => e.inside).length} call(s) inside the estate, ${graph.edges.filter((e) => !e.inside).length} out of it.`, "");

  out.push("## The order to migrate in", "", "A report comes after the reports it calls - migrate and test from the top.", "");
  out.push("| # | Report | Class | Converted | Refusals | Calls |", "|---|---|---|---|---|---|");
  migrationOrder(graph).forEach((name, i) => {
    const n = graph.nodes.find((x) => x.name === name);
    const row = rows.find((r) => r.name === name) ?? {};
    const calls = graph.edges.filter((e) => e.from === name).map((e) => `${e.kind === "SUBMIT" ? "" : `${e.kind} `}${e.to}`);
    out.push(`| ${i + 1} | ${name} | ${n.class ?? ""} | ${n.ok ? "yes" : "no"} | ${row.refusals?.length ?? 0} | ${calls.join(", ")} |`);
  });

  if (graph.edges.length) {
    out.push("", "## The calls", "", "```mermaid", "flowchart LR");
    for (const n of graph.nodes) out.push(`  ${mermaidId(n.name)}["${n.name}"]${n.ok ? "" : ":::refused"}`);
    for (const e of graph.edges) {
      if (!e.inside) out.push(`  ${mermaidId(e.to)}(["${e.to}"]):::outside`);
      out.push(`  ${mermaidId(e.from)} -->|${e.kind}| ${mermaidId(e.to)}`);
    }
    out.push("  classDef refused stroke:#bb0000,stroke-width:2px", "  classDef outside stroke-dasharray: 4 4", "```");
  }

  const outside = graph.edges.filter((e) => !e.inside);
  if (outside.length) {
    out.push("", "## Out of the estate", "", "Reports and transactions the estate calls that are not in it - of SAP or of another package:", "");
    for (const e of outside) out.push(`- ${e.from}: ${e.kind} ${e.to}`);
  }
  if (summary) out.push("", "## Coverage", "", "```text", summary, "```");
  return `${out.join("\n")}\n`;
}

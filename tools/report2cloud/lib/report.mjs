// The migration report - what a conversion did and what is left, as
// markdown for the person (or the AI step) that takes the class from here:
// the refusals with file:row:col, the TODOs, the objects whose release state
// on ABAP Cloud has to be checked, the findings of abaplint when it ran, and
// every mapped construct with its line.
import { refusalLink, refusalOf } from "./refusals.mjs";

const cell = (s) => String(s).replace(/\|/g, "\\|").replace(/\n/g, " ");

/** the markdown report of a conversion result; lint: { v750, cloud } as
 *  lists of abaplint findings, when the gates ran; includes: what
 *  lib/includes.mjs inlined (`included`, `missing`) and its `origin( )`,
 *  so a position of a row from an include names the include */
export function migrationReport(result, { source, texts, lint, includes } = {}) {
  const cls = result.className;
  const files = Object.keys(result.draft).sort();
  const lines = [];
  const push = (...l) => lines.push(...l);
  const main = String(source).split("/").pop();
  const at = (file, row, col) => {
    if (!row) return file;
    const o = includes?.origin?.(row);
    if (o && o.file !== main) return `${o.file}:${o.row}:${col}`;
    return `${file}:${o?.row ?? row}:${col}`;
  };

  push(`# report2cloud: ${result.programName.toUpperCase()} → ${cls}`, "");
  push("| | |", "|---|---|");
  push(`| Source | \`${source}\` |`);
  push(`| Text pool | ${texts ? `\`${texts}\`` : "none - texts are placeholders, see the TODOs"} |`);
  if (includes?.included?.length) push(`| Includes | inlined: ${includes.included.map((i) => `\`${i}\``).join(", ")} |`);
  push(`| Result | ${result.ok ? `**converted** - ${files.map((f) => `\`${f}\``).join(", ")}` : `**refused** - ${result.refusals.length} statement(s) cannot be mapped, no class written`} |`);
  push(`| Mapped | ${result.mapped.length} construct(s) |`);
  push(`| TODO | ${result.todos.length} |`);
  push(`| Release state to check | ${result.release.length} object(s) |`);
  if (lint) push(`| abaplint | v750: ${lint.v750.length} finding(s), ABAP Cloud: ${lint.cloud.length} finding(s) |`);
  push("");

  if (result.refusals.length) {
    push("## Refused", "");
    push("These statements have no counterpart in an abap-cloud-gui report. Rewrite them in the report (or delete them) and convert again.", "");
    for (const r of result.refusals) {
      const entry = refusalOf(r.message);
      push(`- \`${at(source, r.row, r.col)}\` - ${r.message}${entry ? ` ([why, and the rewrite](${refusalLink(entry)}))` : ""}`);
    }
    push("");
  }

  if (result.todos.length) {
    push("## TODO", "");
    for (const t of result.todos) push(`- ${t.row ? `\`${at(source, t.row, t.col)}\` - ` : ""}${t.message}`);
    push("");
  }

  push("## Release state on ABAP Cloud", "");
  if (!result.release.length) {
    push("The class uses no database table, DDIC type, function module, class or message class outside of abap2UI5 and this addon.", "");
  } else {
    push("ABAP Cloud only allows released objects. Check each one; the successor is a hint, not a guarantee.", "");
    push("| Object | Kind | First use | Released successor (hint) |", "|---|---|---|---|");
    for (const r of result.release) {
      push(`| \`${r.name}\` | ${r.kind} | ${r.row ? `\`${r.file}:${r.row}:${r.col}\`` : "-"} | ${r.successor ? cell(r.successor) : "-"} |`);
    }
    push("");
  }

  if (lint) {
    push("## abaplint", "");
    for (const [title, list] of [["v750 (abaplint.jsonc)", lint.v750], ["ABAP Cloud (.github/abaplint/abap_cloud.jsonc)", lint.cloud]]) {
      push(`### ${title}`, "");
      if (!list.length) push("No findings.");
      for (const i of list) push(`- \`${i.file.replace(/^src\/r2c\//, "")}:${i.row}:${i.col}\` [${i.key}] ${i.message}`);
      push("");
    }
  }

  if (result.notes.length) {
    push("## Not carried over", "");
    push("Layout, formatting and behaviour of the classic report that the list, the ALV or the selection screen of abap-cloud-gui do not have:", "");
    for (const n of result.notes) push(`- ${n.text}${n.count > 1 ? ` (${n.count}×)` : ""}`);
    push("");
  }

  push("## Mapped", "");
  push("| Line | Classic | abap-cloud-gui |", "|---|---|---|");
  for (const m of result.mapped) {
    const o = includes?.origin?.(m.row);
    push(`| ${o && o.file !== main ? `${o.file}:${o.row}` : o?.row ?? m.row} | \`${cell(m.classic)}\` | ${cell(m.target)} |`);
  }
  push("");

  push("## Next steps", "");
  push("1. Work through the TODOs above; replace every object of the release table by its released successor.");
  push("2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.");
  push("3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=" + cls + "`.");
  push("4. Pin the behaviour with ABAP Unit tests before the next change.");
  push("");
  return lines.join("\n");
}

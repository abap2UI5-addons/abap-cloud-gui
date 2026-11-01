// The conversion report - what a conversion did to the user interface of
// the report and what is left, as markdown for the person who takes the
// class from here: the refusals with file:row:col, the TODOs, the findings
// of abaplint when it ran, and every mapped construct with its line. The
// logic of the report is copied as it is - whether its tables and APIs are
// available on the target system is the user's business, not this report's.
import { refusalLink, refusalOf } from "./refusals.mjs";

const cell = (s) => String(s).replace(/\|/g, "\\|").replace(/\n/g, " ");

/** the markdown report of a conversion result; lint: { v750 } as a list
 *  of abaplint findings, when the gate ran; includes: what
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

  push(`# report2UI5: ${result.programName.toUpperCase()} → ${cls}`, "");
  push("| | |", "|---|---|");
  push(`| Source | \`${source}\` |`);
  push(`| Text pool | ${texts ? `\`${texts}\`` : "none - texts are placeholders, see the TODOs"} |`);
  if (includes?.included?.length) push(`| Includes | inlined: ${includes.included.map((i) => `\`${i}\``).join(", ")} |`);
  push(`| Result | ${result.ok ? `**converted** - ${files.map((f) => `\`${f}\``).join(", ")}` : `**refused** - ${result.refusals.length} statement(s) cannot be mapped, no class written`} |`);
  push(`| Mapped | ${result.mapped.length} construct(s) |`);
  push(`| TODO | ${result.todos.length} |`);
  if (lint) push(`| abaplint | v750: ${lint.v750.length} finding(s) |`);
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

  if (lint) {
    push("## abaplint", "");
    push("v750, with the rules of abaplint.jsonc:", "");
    if (!lint.v750.length) push("No findings.");
    for (const i of lint.v750) push(`- \`${i.file.replace(/^src\/r2c\//, "")}:${i.row}:${i.col}\` [${i.key}] ${i.message}`);
    push("");
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

  if (result.ok) {
    // the tile of the Fiori launchpad: abap2UI5 starts the class with the
    // app_start parameter, the class is the semantic object of its intent
    const prog = result.programName.toUpperCase();
    const so = cls.toUpperCase();
    push("## Launchpad tile", "");
    push("The class runs as a tile of the Fiori launchpad with this target mapping (the frontend app `z2ui5` of abap2UI5):", "");
    push("| | |", "|---|---|");
    push(`| Semantic object | \`${so}\` |`);
    push("| Action | `display` |");
    push("| URL | `/sap/bc/ui5_ui5/sap/z2ui5` |");
    push("| ID | `z2ui5` |");
    push(`| Parameter | \`app_start\` = \`${so}\` |`);
    push("");
    push("Each field of its selection screen is a startup parameter of the same name (`P_CARRID=LH`, a select-option `S_DATE=20260101,20260131`), and so is `variant`. So that `CALL TRANSACTION` of another report navigates to the tile inside the launchpad, give the transaction its intent in the catalog of the installation (`set_catalog( )`):", "");
    push("```abap", `( code = \`${prog}\` report = \`${so}\` text = \`${prog}\` semantic_object = \`${so}\` action = \`display\` )`, "```", "");
  }

  push("## Next steps", "");
  push("1. Work through the TODOs above.");
  push("2. The logic of the report is copied as it is: its tables, function modules and classes are yours to check on the target system - on ABAP Cloud only released objects are allowed.");
  push("3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=" + cls + "`.");
  push("");
  return lines.join("\n");
}

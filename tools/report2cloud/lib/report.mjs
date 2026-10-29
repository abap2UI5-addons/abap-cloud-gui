// The migration report - what a conversion did and what is left, as
// markdown for the person (or the AI step) that takes the class from here:
// the refusals with file:row:col, the TODOs, the objects whose release state
// on ABAP Cloud has to be checked, the findings of abaplint when it ran, the
// ATC findings of the classic report with what the conversion did on their
// line (lib/atc.mjs), and every mapped construct with its line.
import { refusalLink, refusalOf } from "./refusals.mjs";

const cell = (s) => String(s).replace(/\|/g, "\\|").replace(/\n/g, " ");

/** the markdown report of a conversion result; lint: { v750, cloud } as
 *  lists of abaplint findings, when the gates ran; atc: the findings of
 *  atcStates( ) (lib/atc.mjs), when an ATC export was given; includes: what
 *  lib/includes.mjs inlined (`included`, `missing`) and its `origin( )`,
 *  so a position of a row from an include names the include */
export function migrationReport(result, { source, texts, lint, atc, includes } = {}) {
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
  if (atc) {
    const count = (state) => atc.filter((f) => f.state === state).length;
    push(`| ATC of the report | ${atc.length} finding(s): ${count("converted")} converted, ${count("refused")} refused, ${count("TODO")} TODO, ${count("to check")} to check |`);
  }
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

  if (atc) {
    push("## ATC findings of the report", "");
    push("What the ATC of the system found in the classic report, and what the conversion did on the line: **converted** - the statement is mapped, the class has the counterpart; **refused** - rewrite it first; **TODO** - the class has it, to finish by hand; **to check** - the line went over as it was, run the ATC on the class.", "");
    if (!atc.length) push("No findings.", "");
    else {
      push("| Line | Priority | Check | Finding | After the conversion |", "|---|---|---|---|---|");
      const order = { refused: 0, "to check": 1, TODO: 2, converted: 3 };
      for (const f of [...atc].sort((a, b) => order[a.state] - order[b.state] || (a.row ?? 0) - (b.row ?? 0))) {
        const where = f.object && f.object !== String(result.programName).toLowerCase() ? `${f.object}:${f.row ?? "-"}` : f.row ?? "-";
        push(`| ${where} | ${f.priority ?? "-"} | ${cell(f.check)} | ${cell(f.message)} | **${f.state}** - ${cell(f.detail)} |`);
      }
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
  push("1. Work through the TODOs above; replace every object of the release table by its released successor.");
  push("2. Lint the class against ABAP Cloud: `node tools/report2cloud/cli.mjs <report> --check` (or `npm run check:cloud` with the class in `src/`) until it is clean.");
  push("3. Check the views with the abap2UI5 linter (`npx abap2ui5lint`) and run the report: `?app_start=" + cls + "`.");
  push("4. Pin the behaviour with ABAP Unit tests before the next change.");
  push("");
  return lines.join("\n");
}

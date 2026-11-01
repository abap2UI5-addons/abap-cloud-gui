// The classic report as the transpiler runs it as a program - for the
// semantic test (semantic.test.mjs). The transpiler takes a part of the
// selection screen only (no OBLIGATORY, no LENGTH, no INITIALIZATION), so
// the screen is declared as data and filled where the run starts; what the
// report does stays as it is:
//
//   PARAMETERS p TYPE t ... DEFAULT v   DATA p TYPE t. - and p = v. first in the run
//   AS CHECKBOX / RADIOBUTTON GROUP     TYPE c LENGTH 1
//   INITIALIZATION.                     a START-OF-SELECTION block before the others
//   FORMAT ...                          dropped - it changes no text
//   WRITE /5 x                          WRITE / x - the transpiler misses the new
//                                       line of a position, blanks are not compared
//   the values of the user              set after the defaults and INITIALIZATION
//   the statements of an event block    a FORM the block PERFORMs - the transpiler
//                                       declares an inline DATA( ) in a FORM only;
//                                       a DATA of the block stays global
//
// A SELECT-OPTIONS stays - the transpiler takes it or the case is left out.
import * as abaplint from "@abaplint/core";

// the additions of PARAMETERS that end its type
const OPTIONS = new Set(["DEFAULT", "OBLIGATORY", "LOWER", "MATCHCODE", "MEMORY", "VALUE", "VISIBLE", "MODIF",
  "USER-COMMAND", "NO-DISPLAY", "AS", "RADIOBUTTON", "LIST", "FOR", "NO", "AND"]);

const literalOf = (value) => (typeof value === "number" ? String(value) : `'${String(value).replace(/'/g, "''")}'`);

/** the program text, with values { P_NAME: "World" } as the user fills them */
export function asProgram(source, values = {}) {
  const file = new abaplint.MemoryFile("zprog.prog.abap", source);
  const reg = new abaplint.Registry().addFile(file).parse();
  const statements = [...reg.getObjects()][0].getABAPFiles()[0].getStatements();
  const lines = source.split("\n");
  const drop = new Set();
  const data = [];
  const defaults = [];
  let initRow;
  for (const s of statements) {
    const type = s.get();
    const toks = s.getTokens();
    const rows = toks.map((t) => t.getRow() - 1);
    const span = () => { for (let r = Math.min(...rows); r <= Math.max(...rows); r++) drop.add(r); };
    if (type instanceof abaplint.Statements.Format) {
      span();
    } else if (type instanceof abaplint.Statements.Initialization) {
      initRow = rows[0];
    } else if (type instanceof abaplint.Statements.Parameter) {
      span();
      // the words after the name - the chain's PARAMETERS and colon left out
      const words = toks.map((t) => t.getStr()).filter((w) => w !== ":");
      const start = words.findIndex((w) => /^PARAMETERS?$/i.test(w)) + 1;
      let name = words[start];
      let typeSpec = [];
      const len = /^(\w+)\((\d+)\)$/.exec(name);
      if (len) {
        name = len[1];
        typeSpec = ["TYPE", "c", "LENGTH", len[2]];
      }
      const rest = words.slice(start + 1).filter((w) => w !== "." && w !== ",");
      const at = rest.findIndex((w) => /^(TYPE|LIKE)$/i.test(w));
      if (at >= 0) {
        typeSpec = [];
        for (let i = at; i < rest.length && (i === at || !OPTIONS.has(rest[i].toUpperCase())); i++) typeSpec.push(rest[i]);
      }
      if (!typeSpec.length) typeSpec = rest.some((w) => /^(CHECKBOX|RADIOBUTTON)$/i.test(w)) ? ["TYPE", "c", "LENGTH", "1"] : ["TYPE", "c", "LENGTH", "8"];
      data.push(`DATA ${name} ${typeSpec.join(" ")}.`);
      const def = rest.findIndex((w) => /^DEFAULT$/i.test(w));
      if (def >= 0) {
        const value = [];
        for (let i = def + 1; i < rest.length && !OPTIONS.has(rest[i].toUpperCase()); i++) value.push(rest[i]);
        defaults.push(`  ${name} = ${value.join(" ")}.`);
      }
    }
  }
  const set = Object.entries(values).map(([name, value]) => `  ${name.toLowerCase()} = ${literalOf(value)}.`);
  const sos = statements.filter((s) => s.get() instanceof abaplint.Statements.StartOfSelection).map((s) => s.getTokens()[0].getRow() - 1);
  if (!sos.length && (defaults.length || set.length)) throw new Error("the program has no START-OF-SELECTION to set its values in");

  const out = [];
  lines.forEach((line, row) => {
    if (row === initRow) {
      // the defaults first, then INITIALIZATION - as the classic runs it
      out.push("START-OF-SELECTION.", ...defaults);
      return;
    }
    if (drop.has(row)) {
      // the declarations of the screen where its first one was
      if (data.length) out.push(...data.splice(0));
      out.push(`* ${line}`);
      return;
    }
    out.push(line);
    if (row === sos[0]) {
      if (initRow === undefined) out.push(...defaults);
      out.push(...set);
    }
  });
  return blocksAsForms(out.join("\n").replace(/^(\s*WRITE\b[^.]*?)(^|[\s:,])\/\d+(\(\d+\))?/gim, "$1$2/"));
}

const EVENTS = ["StartOfSelection", "EndOfSelection"];
const ENDS = ["StartOfSelection", "EndOfSelection", "Initialization", "TopOfPage", "EndOfPage", "AtSelectionScreen",
  "AtLineSelection", "AtUserCommand", "Form", "ClassDefinition", "ClassImplementation", "Module", "Interface"];

/** the statements of START-OF-SELECTION and END-OF-SELECTION as FORMs */
function blocksAsForms(source) {
  const reg = new abaplint.Registry().addFile(new abaplint.MemoryFile("zprog.prog.abap", source)).parse();
  const statements = [...reg.getObjects()][0].getABAPFiles()[0].getStatements();
  const lines = source.split("\n");
  const name = (s) => s.get().constructor.name;
  const blocks = [];
  statements.forEach((s, i) => {
    if (!EVENTS.includes(name(s))) return;
    const from = s.getEnd().getRow();
    const next = statements.slice(i + 1).find((x) => ENDS.includes(name(x)));
    const to = next ? next.getStart().getRow() - 1 : lines.length;
    const global = statements.slice(i + 1).filter((x) => x.getStart().getRow() > from && x.getStart().getRow() <= to
      && ["Data", "DataBegin", "DataEnd", "Type", "TypeBegin", "TypeEnd", "Constant", "Tables"].includes(name(x)));
    blocks.push({ row: s.getStart().getRow() - 1, from, to, global });
  });
  if (!blocks.length) return source;
  const out = [...lines];
  const forms = [];
  // from the last block on, the rows of the earlier ones stay where they are
  for (const [n, b] of [...blocks.entries()].reverse()) {
    const keep = new Set();
    for (const g of b.global) for (let r = g.getStart().getRow() - 1; r < g.getEnd().getRow(); r++) keep.add(r);
    const body = [];
    const decl = [];
    for (let r = b.from; r < b.to; r++) (keep.has(r) ? decl : body).push(lines[r]);
    forms.unshift(`FORM r2c_block_${n + 1}.`, ...body, "ENDFORM.", "");
    out.splice(b.row, b.to - b.row, ...decl, lines[b.row], `  PERFORM r2c_block_${n + 1}.`);
  }
  return [...out, "", ...forms].join("\n");
}

/** a list as the comparison reads it */
export function normalize(lines) {
  // the format of the user: the transpiled runtime writes a decimal comma
  // and a date as YYYYMMDD, the list of the class a point and MM/DD/YYYY
  const out = lines.map((l) => (/^\s*-{3,}\s*$/.test(l) ? "---"
    : l.replace(/\b(\d{2})\/(\d{2})\/(\d{4})\b/g, "$3$1$2").replace(/\s+/g, "").replace(/(?<=\d)[.,](?=\d)/g, "")));
  while (out.length && out[out.length - 1] === "") out.pop();
  return out;
}

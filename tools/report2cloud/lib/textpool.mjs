// The text pool of a report, as abapGit serializes it into <name>.prog.xml:
// text symbols (ID I, TEXT-001), selection texts (ID S, keyed by the field
// name) and the title (ID R). The source alone does not carry them, so a
// report converted without its .prog.xml gets placeholder texts and a TODO
// for each one.
//
// A selection text is stored with an 8 character prefix: blanks, or "D" and
// blanks when the text is taken from the DDIC - then there is no text of its
// own, and the selection screen shows the DDIC label as well.

const decode = (s) => s
  .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"')
  .replace(/&apos;/g, "'").replace(/&amp;/g, "&");

const tag = (item, name) => {
  const m = new RegExp(`<${name}>([\\s\\S]*?)</${name}>`).exec(item);
  return m ? decode(m[1]) : "";
};

/** { title, symbols: Map("001" -> text), selection: Map("P_CARR" -> text | null), cua, dynpros }
 *  - null for a selection text taken from the DDIC; cua the GUI status and
 *  titles of the program (parseCua), undefined when the file has none;
 *  dynpros its screens (parseDynpros). */
export function parseTextpool(xml) {
  const pool = { title: "", symbols: new Map(), selection: new Map(), cua: parseCua(xml), dynpros: parseDynpros(xml) };
  if (!xml) return pool;
  const tpool = /<TPOOL>([\s\S]*?)<\/TPOOL>/.exec(xml);
  if (!tpool) return pool;
  for (const m of tpool[1].matchAll(/<item>([\s\S]*?)<\/item>/g)) {
    const id = tag(m[1], "ID");
    const key = tag(m[1], "KEY").trim().toUpperCase();
    const entry = tag(m[1], "ENTRY");
    if (id === "R") pool.title = entry.trim();
    else if (id === "I") pool.symbols.set(key, entry.replace(/\s+$/, ""));
    else if (id === "S") {
      const ddic = entry.startsWith("D") && entry.slice(8).trim() === ".";
      pool.selection.set(key, ddic ? null : entry.slice(8).trim() || null);
    }
  }
  return pool;
}

// ---------------------------------------------------------------- the CUA
//
// abapGit writes the GUI status of a program (the CUA) into the same
// .prog.xml, under <CUA>: one element per table of RS_CUA_INTERNAL_FETCH -
// STA (the statuses: CODE, PFKCODE, BUTCODE), FUN (the functions: CODE,
// TEXTNO, FUN_TEXT, TEXT_TYPE / TEXT_NAME for an icon, ICON_TEXT,
// INFO_TEXT), PFK (the function keys of a key setting: CODE, PFNO, FUNCODE,
// FUNNO), BUT (the application toolbar: PFK_CODE, CODE, NO, PFNO), SET (the
// functions active in a status: STATUS, FUNCTION) and TIT (the titles:
// CODE, TEXT). The rows are read whatever their element is called.

const rows = (cua, name) => {
  const m = new RegExp(`<${name}>([\\s\\S]*?)</${name}>`).exec(cua);
  if (!m) return [];
  return [...m[1].matchAll(/<([\w/]+)>([\s\S]*?)<\/\1>/g)].map((r) => r[2]);
};

// the functions of the SAP GUI frame - Back, Exit, Cancel, Choose, print and
// find, page up and down; the runtime has its own for them
export const STANDARD_FUNCTIONS = new Set(["BACK", "%EX", "RW", "PICK", "%PC", "%SC", "%SC+", "PRI", "%PRI",
  "P--", "P-", "P+", "P++", "%SL", "%ST", "&OUP", "&ODN"]);

/** the key a function key number stands for, as the frontend spells it -
 *  1..12 F1..F12, 13..24 Shift+F1.., 25..36 Ctrl+F1.., 37..48 Ctrl+Shift+F1.. */
export function functionKey(pfno) {
  const n = Number(pfno);
  if (!(n >= 1 && n <= 48)) return undefined;
  const mod = ["", "Shift+", "Ctrl+", "Ctrl+Shift+"][Math.floor((n - 1) / 12)];
  return `${mod}F${((n - 1) % 12) + 1}`;
}

/**
 * { statuses: Map(code -> { functions: [{ code, text, icon, tooltip, key }],
 *   shortcuts: [{ key, code }] }), titles: Map(code -> text) } - functions are
 * the buttons of the application toolbar in their order, shortcuts every
 * function key of the status; both without the standard functions and
 * limited to the functions the status activates.
 */
export function parseCua(xml) {
  const m = xml && /<CUA>([\s\S]*?)<\/CUA>/.exec(xml);
  if (!m) return undefined;
  const cua = m[1];
  const sta = rows(cua, "STA");
  const fun = rows(cua, "FUN");
  const pfk = rows(cua, "PFK");
  const but = rows(cua, "BUT");
  const set = rows(cua, "SET");
  const tit = rows(cua, "TIT");
  const up = (r, n) => tag(r, n).trim().toUpperCase();
  const fn = (code, textno) => {
    const all = fun.filter((r) => up(r, "CODE") === code);
    return all.find((r) => !textno || tag(r, "TEXTNO").trim() === textno) ?? all[0];
  };
  const statuses = new Map();
  for (const st of sta) {
    const code = up(st, "CODE");
    const pfkcode = tag(st, "PFKCODE").trim();
    const butcode = tag(st, "BUTCODE").trim();
    const active = new Set(set.filter((r) => up(r, "STATUS") === code).map((r) => up(r, "FUNCTION")));
    const usable = (f) => f && !STANDARD_FUNCTIONS.has(f) && (!active.size || active.has(f));
    const keys = pfk.filter((r) => tag(r, "CODE").trim() === pfkcode);
    const shortcuts = [];
    for (const k of keys) {
      const f = up(k, "FUNCODE");
      const key = functionKey(tag(k, "PFNO"));
      if (usable(f) && key && !shortcuts.some((x) => x.code === f)) shortcuts.push({ key, code: f });
    }
    const functions = [];
    const buttons = but.filter((r) => tag(r, "PFK_CODE").trim() === pfkcode && tag(r, "CODE").trim() === butcode)
      .sort((a, b) => Number(tag(a, "NO")) - Number(tag(b, "NO")));
    for (const bt of buttons) {
      const pfno = tag(bt, "PFNO").trim();
      const k = keys.find((r) => tag(r, "PFNO").trim() === pfno);
      const f = k ? up(k, "FUNCODE") : "";
      if (!usable(f) || functions.some((x) => x.code === f)) continue;
      const row = fn(f, tag(k, "FUNNO").trim());
      const iconName = row && up(row, "TEXT_TYPE") === "I" ? tag(row, "TEXT_NAME").trim() : "";
      const funText = row ? tag(row, "FUN_TEXT").trim() : "";
      const iconText = row ? tag(row, "ICON_TEXT").trim() : "";
      const info = row ? tag(row, "INFO_TEXT").trim() : "";
      functions.push({
        code: f,
        text: iconName ? iconText : funText || f,
        icon: iconName || undefined,
        // the function text says what an icon button does
        tooltip: info || (iconName && funText !== iconText ? funText : "") || undefined,
        key: functionKey(pfno),
      });
    }
    statuses.set(code, { functions, shortcuts });
  }
  const titles = new Map(tit.map((r) => [up(r, "CODE"), tag(r, "TEXT").replace(/\s+$/, "")]));
  return { statuses, titles };
}

// ---------------------------------------------------------------- dynpros
//
// abapGit writes the screens of a program into the same .prog.xml, under
// <DYNPROS>: per screen its HEADER (SCREEN, DESCRIPT, TYPE), the CONTAINERS
// (the screen itself, frames are fields; subscreens, table controls,
// tabstrips and custom controls are containers), the FIELDS (RPY_DYFATC:
// TYPE, NAME, TEXT, LINE, COLUMN, LENGTH, HEIGHT, INPUT_FLD, OUTPUT_FLD,
// REQU_ENTRY, GROUP1, PUSH_FCODE, INVISIBLE, ...) and the FLOW_LOGIC, one
// source line per RPY_DYFLOW.

const items = (xml, name) => [...xml.matchAll(new RegExp(`<${name}>([\\s\\S]*?)</${name}>`, "g"))].map((r) => r[1]);

/** [{ screen, description, type, containers: [{ type, name, parent }],
 *  fields: [{ cont, contName, type, name, text, line, column, length, height, input,
 *  output, required, group1, fcode, invisible, icon, ref }], flow: [line] }] -
 *  ref the subscreen area of a tab of a tabstrip (REF_FIELD);
 *  containers with their place as the fields have it; screen with its four digits, the texts as the screen painter has them
 *  (underscores of a template included) */
export function parseDynpros(xml) {
  const m = xml && /<DYNPROS>([\s\S]*?)<\/DYNPROS>/.exec(xml);
  if (!m) return [];
  const screens = [];
  for (const it of m[1].split(/<\/item>/).map((x) => x.replace(/^[\s\S]*?<item>/, "")).filter((x) => x.includes("<HEADER>"))) {
    const header = /<HEADER>([\s\S]*?)<\/HEADER>/.exec(it)[1];
    const up = (r, n) => tag(r, n).trim().toUpperCase();
    const flag = (r, n) => up(r, n) === "X";
    screens.push({
      screen: tag(header, "SCREEN").trim().padStart(4, "0"),
      description: tag(header, "DESCRIPT").trim(),
      type: up(header, "TYPE"),
      containers: items(it, "RPY_DYCATT").map((r) => ({
        type: up(r, "TYPE"), name: up(r, "NAME"), parent: up(r, "ELEMENT_OF"),
        line: Number(tag(r, "LINE")) || 0, column: Number(tag(r, "COLUMN")) || 0,
        length: Number(tag(r, "LENGTH")) || 0, height: Number(tag(r, "HEIGHT")) || 0,
      })),
      fields: items(it, "RPY_DYFATC").map((r) => ({
        cont: up(r, "CONT_TYPE"), contName: up(r, "CONT_NAME"), type: up(r, "TYPE"), name: up(r, "NAME"), text: tag(r, "TEXT").replace(/\s+$/, ""),
        line: Number(tag(r, "LINE")) || 0, column: Number(tag(r, "COLUMN")) || 0,
        length: Number(tag(r, "LENGTH")) || 0, height: Number(tag(r, "HEIGHT")) || 1,
        input: flag(r, "INPUT_FLD"), output: flag(r, "OUTPUT_FLD") || flag(r, "OUTPUTONLY"),
        required: ["O", "X"].includes(up(r, "REQU_ENTRY")), group1: up(r, "GROUP1"),
        fcode: up(r, "PUSH_FCODE"), invisible: flag(r, "INVISIBLE"), icon: up(r, "ICON_NAME"),
        ref: up(r, "REF_FIELD"),
      })),
      flow: items(it, "RPY_DYFLOW").map((r) => tag(r, "LINE")),
    });
  }
  return screens;
}
